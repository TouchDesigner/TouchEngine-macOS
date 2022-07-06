//
//  TCHTexturePool.h
//  Hello TouchEngine
//
//  Created by Derivative on 25/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class TCHTexture;

typedef enum : NSUInteger {
	TCHTextureShareModeIOSurface,
	TCHTextureShareModeMetalShareable,
} TCHTextureShareMode;

/// TCHTexturePool manages a pool of MTLTextures with a corresponding TETexture
/// Tying the TETexture lifetime to the corresponding resource helps TouchEngine manage resources for best performance
/// Textures are removed if unused for 1 second - you may wish to modify this behaviour
@interface TCHTexturePool : NSObject
- (instancetype)initForDevice:(id<MTLDevice>)device descriptor:(MTLTextureDescriptor *)descriptor shareMode:(TCHTextureShareMode)mode;
@property (readonly, strong, nonatomic) id<MTLDevice> device;
@property (readonly, strong, nonatomic) MTLTextureDescriptor *descriptor;
@property (readonly, nonatomic) TCHTextureShareMode shareMode;
- (nullable TCHTexture *)newTexture;
@end

NS_ASSUME_NONNULL_END
