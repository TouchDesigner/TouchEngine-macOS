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
#import "MetalRendererAnimation.h"

@interface ViewController ()
@property (readwrite, strong) NSAnimation *animation;
@end

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

- (void)setBackground:(NSColor *)bg foreground:(NSColor *)fg
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.animation = [[MetalRendererAnimation alloc] initForRenderer:self->_renderer background:bg foreground:fg];
        self.animation.delegate = self;
        [self.animation startAnimation];
    }];
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
    else
    {
        [self setBackground:[NSColor colorWithRed:0.8 green:0.8 blue:0.9 alpha:1.0]
                 foreground:[NSColor colorWithRed:1.0 green:0.8 blue:0.8 alpha:1.0]];
    }
}

- (void)animationDidEnd:(NSAnimation *)animation
{
    if ([animation isEqual:self.animation])
    {
        self.animation = nil;
    }
}

- (void)engineError:(NSError *)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self presentError:error modalForWindow:self.view.window delegate:nil didPresentSelector:nil contextInfo:nil];
    }];
    [self setBackground:[NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0] foreground:[NSColor colorWithRed:0.8 green:0.4 blue:0.4 alpha:1.0]];
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
