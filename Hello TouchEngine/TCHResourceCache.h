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
