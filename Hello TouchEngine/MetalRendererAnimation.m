//
//  MetalRendererAnimation.m
//  Hello TouchEngine
//
//  Created by Derivative on 30/11/2022.
//

#import "MetalRendererAnimation.h"
#import "MetalRenderer.h"
#import <simd/simd.h>

@interface MetalRendererAnimation ()
@property (readonly, strong) NSColor *backgroundStart;
@property (readonly, strong) NSColor *backgroundEnd;
@property (readonly, strong) NSColor *foregroundStart;
@property (readonly, strong) NSColor *foregroundEnd;
@end

@implementation MetalRendererAnimation

- (instancetype)initForRenderer:(MetalRenderer *)renderer background:(NSColor *)bg foreground:(NSColor *)fg
{
	self = [super init];
	if (self)
	{
		self.animationBlockingMode = NSAnimationNonblocking;
		self.animationCurve = NSAnimationEaseIn;
		self.duration = 5.0;
		
		_backgroundStart = renderer.backgroundColor;
		_backgroundEnd = bg;
		_foregroundStart = renderer.foregroundColor;
		_foregroundEnd = fg;
		_renderer = renderer;
	}
	return self;
}

+ (NSColor *)mixedColorForStart:(NSColor *)start end:(NSColor *)end progress:(NSAnimationProgress)progress
{
	double red = simd_mix(start.redComponent, end.redComponent, (double)progress);
	double green = simd_mix(start.greenComponent, end.greenComponent, (double)progress);
	double blue = simd_mix(start.blueComponent, end.blueComponent, (double)progress);
	double alpha = simd_mix(start.alphaComponent, end.alphaComponent, (double)progress);
	
	return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)setCurrentProgress:(NSAnimationProgress)currentProgress
{
	self.renderer.foregroundColor = [[self class] mixedColorForStart:self.foregroundStart end:self.foregroundEnd progress:currentProgress];
	self.renderer.backgroundColor = [[self class] mixedColorForStart:self.backgroundStart end:self.backgroundEnd progress:currentProgress];
}

@end
