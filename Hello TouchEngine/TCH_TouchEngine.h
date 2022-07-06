//
//  TCH_TouchEngine.h
//  Hello TouchEngine
//
//  Created by Derivative on 30/09/2022.
//

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
