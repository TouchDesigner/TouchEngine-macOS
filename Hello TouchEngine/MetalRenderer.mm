/* Shared Use License: This file is owned by Derivative Inc. (Derivative)
* and can only be used, and/or modified for use, in conjunction with
* Derivative's TouchDesigner software, and only if you are a licensee who has
* accepted Derivative's TouchDesigner license or assignment agreement
* (which also govern the use of this file). You may share or redistribute
* a modified version of this file provided the following conditions are met:
*
* 1. The shared file or redistribution must retain the information set out
* above and this list of conditions.
* 2. Derivative's name (Derivative Inc.) or its trademarks may not be used
* to endorse or promote products derived from this file without specific
* prior written permission from Derivative.
*/

#import "MetalRenderer.h"
#import "ShaderTypes.h"
#import "TCHSharedTexture.h"
#import "TCHSharedEvent.h"
#import "TCHTexture.h"
#import "TCHTexturePool.h"

@interface MetalRenderer ()
@property (readwrite, strong) TCHSharedTexture *inputTexture;
@end

@implementation MetalRenderer {
	id<MTLCommandQueue> _commandQueue;
	id<MTLRenderPipelineState> _texFillPipeline;
	id<MTLRenderPipelineState> _drawPipeline;
	vector_uint2 _viewportSize;
	id<MTLBuffer> _drawVertices;
	NSUInteger _drawVertexCount;
	uint64_t _waitValue;
	TCHSharedEvent *_waitEvent;
	TCHSharedTexture *_outputTexture;
    TCHTexturePool *_pool;
}

- (instancetype)initWithView:(MTKView *)mtkView
{
	self = [super init];
	if (self)
	{
		_device = mtkView.device;
		_commandQueue = [_device newCommandQueue];
		
		id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
		
		id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"fillVertexShader"];
		id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fillFragmentShader"];
		
		MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
		pipelineStateDescriptor.label = @"Texture Fill Pipeline";
		pipelineStateDescriptor.vertexFunction = vertexFunction;
		pipelineStateDescriptor.fragmentFunction = fragmentFunction;
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
		
		NSError *error = nil;
		_texFillPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
																   error:&error];
		if (!_texFillPipeline)
		{
			self = nil;
			return self;
		}
		
		vertexFunction = [defaultLibrary newFunctionWithName:@"drawVertexShader"];
		fragmentFunction = [defaultLibrary newFunctionWithName:@"drawSamplingShader"];
		
		pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
		pipelineStateDescriptor.label = @"Draw Pipeline";
		pipelineStateDescriptor.vertexFunction = vertexFunction;
		pipelineStateDescriptor.fragmentFunction = fragmentFunction;
		pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
		
		_drawPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
																error:&error];
		if (!_drawPipeline)
		{
			self = nil;
			return self;
		}
        
        _backgroundColor = [NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
        _foregroundColor = [NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
	}
	return self;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
	[self fillTexture];
	
	MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
	if (renderPassDescriptor == nil)
	{
		return;
	}
	
	id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
	
	TCHSharedTexture *shared = nil;
	@synchronized (self) {
		shared = _outputTexture;
	}
	
	if (!shared)
	{
		shared = self.inputTexture;
	}
	
	if (shared.waitEvent)
	{
		[commandBuffer encodeWaitForEvent:shared.waitEvent.sharedEvent value:shared.waitValue];
	}
	
	id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
	
	[commandEncoder setRenderPipelineState:_drawPipeline];
	
	[commandEncoder setViewport:(MTLViewport){0.0, 0.0, (double)_viewportSize.x, (double)_viewportSize.y, -1.0, 1.0 }];
	
	if (shared.texture)
	{
		[commandEncoder setVertexBuffer:_drawVertices
								 offset:0
								atIndex:VertexInputIndexVertices];
		
		[commandEncoder setVertexBytes:&_viewportSize
								length:sizeof(_viewportSize)
							   atIndex:VertexInputIndexViewportSize];
		
		[commandEncoder setFragmentTexture:shared.texture.texture
								   atIndex:TextureIndexBaseColor];
		
		[commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle
						  vertexStart:0
						  vertexCount:_drawVertexCount];
	
	}
	[commandEncoder endEncoding];
	
	id<MTLDrawable> drawable = view.currentDrawable;
	
	[commandBuffer presentDrawable:drawable];
	
	TCHSharedEvent *event = nil;
	uint64_t value;
	@synchronized (self) {
		if (_waitValue == UINT64_MAX)
		{
			_waitEvent = nil;
			_waitValue = 0;
		}
		if (!_waitEvent)
		{
			id<MTLSharedEvent> event = [self.device newSharedEvent];
			_waitEvent = [[TCHSharedEvent alloc] initWithSharedEvent:event];
		}
		event = _waitEvent;
		value = ++_waitValue;
	}
	
	[commandBuffer encodeSignalEvent:event.sharedEvent value:value];
	
	[commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
	_viewportSize.x = size.width;
	_viewportSize.y = size.height;
	
	float halfw = _viewportSize.x / 2.0;
	float halfh = _viewportSize.y / 2.0;
	
	const DrawVertex quadVertices[] =
	{
		// Pixel position       Texture coordinate
		{ {  halfw,  -halfh },  { 1.f, 1.f } },
		{ { -halfw,  -halfh },  { 0.f, 1.f } },
		{ { -halfw,   halfh },  { 0.f, 0.f } },
		
		{ {  halfw,  -halfh },  { 1.f, 1.f } },
		{ { -halfw,   halfh },  { 0.f, 0.f } },
		{ {  halfw,   halfh },  { 1.f, 0.f } },
	};
	
	_drawVertices = [_device newBufferWithBytes:quadVertices
										 length:sizeof(quadVertices)
										options:MTLResourceStorageModeShared];
	
	_drawVertexCount = sizeof(quadVertices) / sizeof(DrawVertex);
	
	[self fillTexture];
}

- (void)fillTexture
{
	if (_viewportSize.x == 0 || _viewportSize.y == 0)
	{
		self.inputTexture = nil;
		return;
	}
	
	MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
																						  width:_viewportSize.x height:_viewportSize.y mipmapped:NO];
	descriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    TCHTextureShareMode mode = self.useMetalSharedTextures ? TCHTextureShareModeMetalShareable : TCHTextureShareModeIOSurface;
    
    if (!_pool || _pool.descriptor.width != descriptor.width || _pool.descriptor.height != descriptor.height || _pool.shareMode != mode)
    {
        _pool = [[TCHTexturePool alloc] initForDevice:_device descriptor:descriptor shareMode:mode];
    }
	
	TCHTexture *texture = nil;
	TCHSharedEvent *event = self.inputTexture.waitEvent;
	uint64_t waitValue = self.inputTexture.waitValue;
	if (waitValue == UINT64_MAX)
	{
		event = nil;
		waitValue = 0;
	}
	
	if (!event)
	{
		id<MTLSharedEvent> mtlEvent = [_device newSharedEvent];
		event = [[TCHSharedEvent alloc] initWithSharedEvent:mtlEvent];
	}
	
    texture = [_pool newTexture];
	
	id<MTLCommandBuffer> setupCmdBuf = [_commandQueue commandBuffer];
	MTLRenderPassDescriptor *renderPassDesc = [MTLRenderPassDescriptor renderPassDescriptor];
	
	if (renderPassDesc)
	{
		renderPassDesc.colorAttachments[0].texture = texture.texture;
		renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionDontCare;
		id<MTLRenderCommandEncoder> encoder = [setupCmdBuf renderCommandEncoderWithDescriptor:renderPassDesc];
		
		[encoder setRenderPipelineState:_texFillPipeline];
		
		[encoder setViewport:(MTLViewport){0.0, 0.0, (double)_viewportSize.x, (double)_viewportSize.y, 0.0, 1.0}];
		
		float halfw = _viewportSize.x / 2.0;
		float halfh = _viewportSize.y / 2.0;
		const TextureFillVertex quadVertices[] =
		{
			// Pixel positions, Texture coordinates
			{ {  halfw,  -halfh } },
			{ { -halfw,  -halfh } },
			{ { -halfw,   halfh } },
			
			{ {  halfw,  -halfh } },
			{ { -halfw,   halfh } },
			{ {  halfw,   halfh } },
		};
		
		const float point = ((0.8 - 0.6) * sin([NSDate timeIntervalSinceReferenceDate]) + 0.8 + 0.6) / 2.;
		
        const TextureFillFragmentArguments arguments = {{halfw, halfh},
            point,
            {static_cast<float>(self.backgroundColor.redComponent), static_cast<float>(self.foregroundColor.redComponent)},
            {static_cast<float>(self.backgroundColor.greenComponent), static_cast<float>(self.foregroundColor.greenComponent)},
            {static_cast<float>(self.backgroundColor.blueComponent), static_cast<float>(self.foregroundColor.blueComponent)}};
		
		[encoder setVertexBytes:quadVertices
						 length:sizeof(quadVertices)
						atIndex:VertexInputIndexVertices];
		
		[encoder setVertexBytes:&_viewportSize
						 length:sizeof(_viewportSize)
						atIndex:VertexInputIndexViewportSize];
		
		[encoder setFragmentBytes:&arguments
						   length:sizeof(arguments)
						  atIndex:FragmentInputIndexArguments];
				
		[encoder drawPrimitives:MTLPrimitiveTypeTriangle
					vertexStart:0
					vertexCount:6];
		
		[encoder endEncoding];
	}
	
	[setupCmdBuf encodeSignalEvent:event.sharedEvent value:++waitValue];
	
	[setupCmdBuf commit];
	
	self.inputTexture = [[TCHSharedTexture alloc] initWithTexture:texture waitEvent:event waitValue:waitValue];
    
    [self.delegate inputTextureDidChange];
}

- (TCHSharedTexture *)setOutputTexture:(TCHSharedTexture *)output
{
	@synchronized (self) {
		TCHSharedTexture *previous = nil;
		if (_outputTexture)
		{
			previous = [[TCHSharedTexture alloc] initWithTexture:_outputTexture.texture waitEvent:_waitEvent waitValue:_waitValue];
		}
		_outputTexture = output;
		return previous;
	}
}
@end
