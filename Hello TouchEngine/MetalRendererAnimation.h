//
//  MetalRendererAnimation.h
//  Hello TouchEngine
//
//  Created by Derivative on 30/11/2022.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class MetalRenderer;

@interface MetalRendererAnimation : NSAnimation
- (instancetype)initForRenderer:(MetalRenderer *)renderer background:(NSColor *)bg foreground:(NSColor *)fg;
@property (readonly, strong) MetalRenderer *renderer;
@end

NS_ASSUME_NONNULL_END
