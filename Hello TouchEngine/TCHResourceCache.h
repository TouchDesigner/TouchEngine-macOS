//
//  TCHResourceCache.h
//  TouchEngineTest
//
//  Created by Derivative on 11/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <TouchEngine/TouchEngine.h>
#include <TouchEngine/TEMetal.h>

NS_ASSUME_NONNULL_BEGIN

@class TCHTexture;
@class TCHSharedEvent;


/// Manages instantiated resources from any TETexture and TESemaphore received from TouchEngine
/// TEObjectEvents received from TouchEngine are monitored and resources discarded when
/// they are discared by TouchEngine.
@interface TCHResourceCache : NSObject
+ (TCHResourceCache *)resourceCacheForDevice:(id<MTLDevice>)device;
@property (readonly, strong, nonatomic) id<MTLDevice> device;
- (TCHTexture * _Nullable)textureForTETexture:(TETexture *)texture;
- (TCHSharedEvent * _Nullable)sharedEventForTESemaphore:(TESemaphore *)semaphore;
@end

NS_ASSUME_NONNULL_END
