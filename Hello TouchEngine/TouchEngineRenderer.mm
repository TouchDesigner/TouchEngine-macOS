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

#import "TouchEngineRenderer.h"
#import "TCHSharedTexture.h"
#import "TCHResourceCache.h"
#import "TCH_TouchEngine.h"
#import <simd/simd.h>
#include <vector>
#include <TouchEngine/TouchEngine.h>
#include <TouchEngine/TEMetal.h>
#include <TouchEngine/TouchObject.h>
#include "Geometry.h"
#include "Color.h"

NSErrorDomain const TouchEngineRenderErrorDomain = @"ca.derivative.touchengine.metalexample";

@interface TouchEngineRenderer () {
	double _progress;
	BOOL _pendingProgress;
}
+ (NSError *)errorForTEResult:(TEResult)result;
- (void)addLink:(NSString *)identifier;
- (void)loadCompleted:(NSError *)error;
- (void)valueChange:(NSString *)identifier;
- (void)configureCompleted:(NSError *)error;
- (void)engineError:(NSError *)error;
@property (readwrite, strong) NSString *firstTexInput;
@property (readwrite, strong) NSString *firstGeometryInput;
@property (readwrite, strong) NSString *firstTexOutput;
@property (readwrite, strong) NSString *progressInput;
@property (readwrite, strong) NSTimer *timer;
@property (readwrite) BOOL inFrame;
@property (readwrite) BOOL supportsMetalSharedTextures;
@property (readwrite) BOOL pendingGeometry;
@end

static void EventCallback(TEInstance *instance,
						  TEEvent event,
						  TEResult result,
						  int64_t start_time_value,
						  int32_t start_time_scale,
						  int64_t end_time_value,
						  int32_t end_time_scale,
						  void * TE_NULLABLE info)
{
	TouchEngineRenderer *renderer = (__bridge TouchEngineRenderer *)info;
	NSError *error = [TouchEngineRenderer errorForTEResult:result];
	
	switch (event) {
		case TEEventGeneral:
			[renderer engineError:error];
			break;
		case TEEventInstanceReady:
			[renderer configureCompleted:error];
			break;
		case TEEventInstanceDidLoad:
			[renderer loadCompleted:error];
			break;
		case TEEventInstanceDidUnload:
			break;
		case TEEventFrameDidFinish:
			renderer.inFrame = NO;
			break;
		default:
			break;
	}
}

static void LinkCallback(TEInstance *instance, TELinkEvent event, const char *identifier, void *info)
{
	TouchEngineRenderer *renderer = (__bridge TouchEngineRenderer *)info;
	switch (event) {
		case TELinkEventAdded:
			[renderer addLink:[NSString stringWithUTF8String:identifier]];
			break;
		case TELinkEventMoved:
			break;
		case TELinkEventModified:
			break;
		case TELinkEventChildChange:
			break;
		case TELinkEventRemoved:
			break;
		case TELinkEventStateChange:
			break;
		case TELinkEventValueChange:
			[renderer valueChange:[NSString stringWithUTF8String:identifier]];
			break;
	}
}

@implementation TouchEngineRenderer {
	id<MTLDevice> _device;
	TouchObject<TEInstance> _instance;
	TCHSharedTexture *_inputTexture;
	NSTimeInterval _startTime;
}

+ (NSError *)errorForTEResult:(TEResult)result
{
	if (result != TEResultSuccess)
	{
		const char *str = TEResultGetDescription(result);
		NSString *description = [NSString stringWithUTF8String:str];
		return [NSError errorWithDomain:TouchEngineRenderErrorDomain code:result userInfo:@{NSLocalizedDescriptionKey: description}];
	}
	return nil;
}

- (instancetype)initForDevice:(id<MTLDevice>)device error:(NSError **)error
{
	self = [super init];
	if (self)
	{
		_device = device;
		_startTime = -1;
		_progress = 0.0;
		_pendingGeometry = YES;
		_pendingProgress = YES;
		
		// Create an instance
		TEResult result = TEInstanceCreate(EventCallback, LinkCallback, (__bridge void *)self, _instance.take());
		
		// Create a context for the MTLDevice and associate it with the instance
		TouchObject<TEMetalContext> context;
		if (result == TEResultSuccess)
		{
			result = TEMetalContextCreate(_device, context.take());
		}
		if (result == TEResultSuccess)
		{
			result = TEInstanceAssociateGraphicsContext(_instance, context);
		}
		
		// Configuring the instance now without a path allows it to begin some preliminary setup immediately
		result = TEInstanceConfigure(_instance, nullptr, TETimeExternal, TEUINone);
		
		if (TEResultGetSeverity(result) == TESeverityError)
		{
			self = nil;
		}
	}
	return self;
}

- (void)engineError:(NSError *)error
{
	[self.delegate engineError:error];
}

- (void)addLink:(NSString *)identifier
{
	TouchObject<TELinkInfo> link;
	if (TEInstanceLinkGetInfo(_instance, identifier.UTF8String, link.take()) == TEResultSuccess)
	{
		// Disable events for links we aren't going to use
		TELinkInterest interest = TELinkInterestNone;
		
		if (link->type == TELinkTypeTexture)
		{
			if (link->scope == TEScopeInput)
			{
				if (!self.firstTexInput)
				{
					self.firstTexInput = identifier;
					interest = TELinkInterestNoValues;
				}
			}
			else
			{
				if (!self.firstTexOutput)
				{
					self.firstTexOutput = identifier;
					interest = TELinkInterestAll;
				}
			}
		}
		else if (link->type == TELinkTypeGeometry && link->scope == TEScopeInput)
		{
			if (!self.firstGeometryInput)
			{
				self.firstGeometryInput = identifier;
				interest = TELinkInterestNoValues;
			}
		}
		else if (link->type == TELinkTypeDouble && link->count == 1)
		{
			if (link->name && strcmp(link->name, "Progress") == 0)
			{
				self.progressInput = identifier;
				interest = TELinkInterestNoValues;
			}
		}
		TEInstanceLinkSetInterest(_instance, identifier.UTF8String, interest);
	}
}

- (void)valueChange:(NSString *)identifier
{
	if (_firstTexOutput && [identifier isEqualToString:_firstTexOutput])
	{
		TouchObject<TETexture> texture;
		uint64_t waitValue = 0;
		TouchObject<TESemaphore> semaphore;
		if (TEInstanceLinkGetTextureValue(_instance, identifier.UTF8String, TELinkValueCurrent, texture.take()) == TEResultSuccess)
		{
			if (texture && TEInstanceHasResourceTransfer(_instance, texture))
			{
				TEInstanceGetResourceTransfer(_instance, texture, semaphore.take(), &waitValue);
			}
			
			TCHResourceCache *cache = [TCHResourceCache resourceCacheForDevice:_device];
			
			
			TCHTexture *instantiated = [cache textureForTETexture:texture];
			
			TCHSharedEvent *event = nil;
			
			if (semaphore)
			{
				event = [cache sharedEventForTESemaphore:semaphore];
			}
			
			TCHSharedTexture *output = [[TCHSharedTexture alloc] initWithTexture:instantiated waitEvent:event waitValue:waitValue];
			
			TCHSharedTexture *previous = [_delegate engineOutputDidChange:output];
			
			if (previous.waitEvent && TEInstanceDoesResourceOwnershipTransfer(_instance))
			{
				TEInstanceAddResourceTransfer(_instance,
											  previous.texture.engineTexture,
											  previous.waitEvent.engineSemaphore,
											  previous.waitValue);
			}
			
			// Let the instance know we won't get this value again until it changes
			TEInstanceLinkSetInterest(_instance, identifier.UTF8String, TELinkInterestSubsequentValues);
		}
	}
}

- (BOOL)loadComponent:(NSURL *)url error:(NSError **)error
{
	TEResult result = TEInstanceConfigure(_instance, url.path.UTF8String, TETimeExternal, TEUINone);
	
	if (result == TEResultSuccess)
	{
		result = TEInstanceLoad(_instance);
	}
	
	if (error)
	{
		*error = [[self class] errorForTEResult:result];
	}
	return TEResultGetSeverity(result) == TESeverityError ? NO : YES;
}

- (BOOL)resume:(NSError *__autoreleasing  _Nullable *)error
{
	TEResult result = TEInstanceResume(_instance);
	
	
	self.timer = [NSTimer timerWithTimeInterval:1/60.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
		[self startFrame];
	}];
	
	[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	
	if (error)
	{
		*error = [[self class] errorForTEResult:result];
	}
	return TEResultGetSeverity(result) == TESeverityError ? NO : YES;
}

- (BOOL)pause:(NSError *__autoreleasing  _Nullable *)error
{
	TEResult result = TEInstanceSuspend(_instance);
	if (error)
	{
		*error = [[self class] errorForTEResult:result];
	}
	return TEResultGetSeverity(result) == TESeverityError ? NO : YES;
}

- (void)loadCompleted:(NSError *)error
{
	[self.delegate engineLoadDidComplete:error];
}

- (void)configureCompleted:(NSError *)error
{
	if ([error.domain isEqualToString:TouchEngineRenderErrorDomain] && error.code == TEResultCancelled)
	{
		/*
		 We ignore cancelled configurations - this happens because we call TEInstanceConfigure() at init
		 with no path to let it do some preliminary setup, which may not have completed before we call it
		 again with a path
		 */
		return;
	}
	if (!error || ([error.domain isEqualToString:TouchEngineRenderErrorDomain] && TEResultGetSeverity((TEResult)error.code) != TESeverityError))
	{
		/*
		 If the user has an older TouchDesigner version (2021 or earlier), it will only support TETextureTypeIOSurface
		 - here we check for support for Metal textures
		 */
		std::vector<TETextureType> textureTypes;
		int32_t count = 2;
		do {
			textureTypes.resize(count);
		} while (TEInstanceGetSupportedTextureTypes(_instance, textureTypes.data(), &count) == TEResultInsufficientMemory);
		for (int i = 0; i < count; i++)
		{
			if (textureTypes[i] == TETextureTypeMetal)
			{
				self.supportsMetalSharedTextures = YES;
			}
		}
	}
	[self.delegate engineConfigureDidComplete:error];
}

- (void)startFrame
{
	if (!self.inFrame)
	{
		TEResult result = TEResultSuccess;
		
		self.inFrame = YES;
		
		TCHSharedTexture *input = nil;
		double progress;
		BOOL pendingProgress;
		@synchronized (self) {
			input = _inputTexture;
			_inputTexture = nil;
			pendingProgress = _pendingProgress;
			_pendingProgress = NO;
			progress = _progress;
		}
		
		if (input.texture && self.firstTexInput.length > 0)
		{
			result = TEInstanceLinkSetTextureValue(_instance, self.firstTexInput.UTF8String, input.texture.engineTexture, nullptr);
			
			/*
			 A texture transfer is required to synchronize texture usage between the host and TouchEngine
			 */
			if (result == TEResultSuccess && input.waitEvent && TEInstanceDoesResourceOwnershipTransfer(_instance))
			{
				result = TEInstanceAddResourceTransfer(_instance, input.texture.engineTexture, input.waitEvent.engineSemaphore, input.waitValue);
			}
		}
		if (self.pendingGeometry && self.firstGeometryInput.length > 0)
		{
			self.pendingGeometry = NO;

			static constexpr uint32_t kNumDivisions = 16;
			
			Geometry::BufferProvider bufferProvider;
			TouchObject<TEGeometry> geometry = Geometry::getCircleGeometry(1.0, kNumDivisions, Palette::LightPink, Palette::BrightGray, bufferProvider);
						
			result = TEInstanceLinkSetGeometryValue(_instance, self.firstGeometryInput.UTF8String, geometry);
		}
		if (pendingProgress && self.progressInput.length > 0)
		{
			TEInstanceLinkSetDoubleValue(_instance, self.progressInput.UTF8String, &progress, 1);
		}
		if (result == TEResultSuccess)
		{
			NSTimeInterval time;
			if (_startTime == -1)
			{
				_startTime = [NSDate timeIntervalSinceReferenceDate];
				time = 0.0;
			}
			else
			{
				time = [NSDate timeIntervalSinceReferenceDate] - _startTime;
			}
			
			result = TEInstanceStartFrameAtTime(_instance, time * 10000, 10000, false);
		}
		
		if (result != TEResultSuccess)
		{
			self.inFrame = NO;
		}
	}
}

- (TCHSharedTexture *)inputTexture
{
	@synchronized (self) {
		return _inputTexture;
	}
}

- (void)setInputTexture:(TCHSharedTexture *)inputTexture
{
	@synchronized (self) {
		_inputTexture = inputTexture;
	}
}

- (double)progress
{
	@synchronized (self)
	{
		return _progress;
	}
}

- (void)setProgress:(double)progress
{
	@synchronized (self) {
		_progress = progress;
		_pendingProgress = YES;
	}
}

@end
