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

#import "ViewController.h"
#import <MetalKit/MetalKit.h>
#import "TCHSharedTexture.h"

@implementation ViewController {
	MetalRenderer *_renderer;
	TouchEngineRenderer *_engine;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	    
	MTKView *view = (MTKView *)self.MTKView;
		
	view.device = MTLCreateSystemDefaultDevice();
    	
	_renderer = [[MetalRenderer alloc] initWithView:view];
	
	[_renderer mtkView:view drawableSizeWillChange:view.drawableSize];
	
	_renderer.delegate = self;
	
	view.delegate = _renderer;
	
    
	NSError *error = nil;
	_engine = [[TouchEngineRenderer alloc] initForDevice:_renderer.device error:&error];
	
	if (_engine)
	{
		_engine.delegate = self;
		
		NSURL *component = [[NSBundle mainBundle] URLForResource:@"displace" withExtension:@"tox"];
		if (component)
		{
			[_engine loadComponent:component error:&error];
		}
	}
	
	if (error)
	{
        [self engineError:error];
	}
}

- (void)viewDidAppear
{
    [super viewDidAppear];
}

- (void)setRepresentedObject:(id)representedObject {
	[super setRepresentedObject:representedObject];

}

- (void)engineConfigureDidComplete:(NSError *)error
{
	_renderer.useMetalSharedTextures = _engine.supportsMetalSharedTextures;
	if (error)
    {
        [self engineError:error];
    }
}

- (void)engineLoadDidComplete:(NSError *)error
{
	if (!error)
	{
		[_engine setInputTexture:_renderer.inputTexture];
		[_engine resume:&error];
	}
    
    if (error)
    {
        [self engineError:error];
    }
}

- (void)engineError:(NSError *)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
    }];
}

- (TCHSharedTexture *)engineOutputDidChange:(TCHSharedTexture *)texture
{
	// MetalRenderer returns an updated TCHSharedTexture with its a shared event for the last render
	TCHSharedTexture *previous = [_renderer setOutputTexture:texture];
	
	return previous;
}

- (void)inputTextureDidChange
{
	[_engine setInputTexture:_renderer.inputTexture];
}

@end
