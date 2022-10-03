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

#ifndef TCH_TouchEngine_h
#define TCH_TouchEngine_h

#import "TCHTexture.h"
#import "TCHSharedEvent.h"
#import <TouchEngine/TEMetal.h>

@interface TCHTexture (TouchEngine)
+ (MTLPixelFormat)metalPixelFormatForFormat:(TETextureFormat)format map:(TETextureComponentMap)map;
+ (TETextureFormat)formatForMetalPixelFormat:(MTLPixelFormat)format;
+ (TETextureComponentMap)componentMapForMetalPixelFormat:(MTLPixelFormat)format;
- (instancetype)initWithMTLTexture:(id<MTLTexture>)metal forTETexture:(TETexture *)texture;
@property (readonly) TETexture *engineTexture;
@end

@interface TCHSharedEvent (TouchEngine)
- (instancetype)initWithMTLSharedEvent:(id<MTLSharedEvent>)event forTESemaphore:(TEMetalSemaphore *)semaphore;
@property (readonly) TEMetalSemaphore *engineSemaphore;
@end

#endif /* TCH_TouchEngine_h */
