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

#import "Animation.h"
#import "ViewController.h"
#import <simd/simd.h>

@interface Animation ()
@property (readonly, strong) NSColor *backgroundStart;
@property (readonly, strong) NSColor *backgroundEnd;
@property (readonly, strong) NSColor *foregroundStart;
@property (readonly, strong) NSColor *foregroundEnd;
@property (readonly) double progressStart;
@property (readonly) double progressEnd;
@end

@implementation Animation

- (instancetype)initForController:(ViewController *)controller background:(NSColor *)bg foreground:(NSColor *)fg progress:(double)pr
{
	self = [super init];
	if (self)
	{
		self.animationBlockingMode = NSAnimationNonblocking;
		self.animationCurve = NSAnimationEaseIn;
		self.duration = 5.0;
		
		_backgroundStart = controller.backgroundColor;
		_backgroundEnd = bg;
		_foregroundStart = controller.foregroundColor;
		_foregroundEnd = fg;
		_progressStart = controller.progress;
		_progressEnd = pr;
		_controller = controller;
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
	self.controller.foregroundColor = [[self class] mixedColorForStart:self.foregroundStart end:self.foregroundEnd progress:currentProgress];
	self.controller.backgroundColor = [[self class] mixedColorForStart:self.backgroundStart end:self.backgroundEnd progress:currentProgress];
	self.controller.progress = simd_mix(self.progressStart, self.progressEnd, (double)currentProgress);
}

@end
