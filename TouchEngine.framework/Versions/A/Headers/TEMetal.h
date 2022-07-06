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

#ifndef TEMetal_h
#define TEMetal_h

#include <TouchEngine/TEObject.h>
#include <TouchEngine/TESemaphore.h>
#include <TouchEngine/TETexture.h>
#include <TouchEngine/TEResult.h>
#include <TouchEngine/TEGraphicsContext.h>

#import <Metal/Metal.h>

#ifdef __cplusplus
extern "C" {
#endif

TE_ASSUME_NONNULL_BEGIN

typedef struct TEMetalSemaphore_ TEMetalSemaphore;

typedef void (*TEMetalSemaphoreCallback)(MTLSharedEventHandle *handle, TEObjectEvent event, void *info) API_AVAILABLE(macos(10.14));

/*
 Create a semaphore from a MTLSharedEventHandle
 'handle' is retained for the TEMetalSemaphore's lifetime
 'callback' will be invoked for object use and lifetime events - see TEObjectEvent in TEObject.h
 'info' will be passed as an argument when 'callback' is invoked
 The caller is responsible for releasing the returned TEMetalSemaphore using TERelease()
 */
TE_EXPORT API_AVAILABLE(macos(10.14))
TEMetalSemaphore *TEMetalSemaphoreCreate(MTLSharedEventHandle *handle, TEMetalSemaphoreCallback TE_NULLABLE callback, void * TE_NULLABLE info);

/*
 Returns the MTLSharedEventHandle associated with the semaphore
 */
TE_EXPORT API_AVAILABLE(macos(10.14))
MTLSharedEventHandle *TEMetalSemaphoreGetSharedEventHandle(TEMetalSemaphore *semaphore);

/*
 Sets 'callback' to be invoked for object use and lifetime events - see TEObjectEvent in TEObject.h.
 This replaces (or cancels) any callback previously set on the TEMetalSemaphore
 */
TE_EXPORT API_AVAILABLE(macos(10.14))
TEResult TEMetalSemaphoreSetCallback(TEMetalSemaphore *semaphore, TEMetalSemaphoreCallback TE_NULLABLE callback, void * TE_NULLABLE info);


/*
 Metal Textures - see TETexture.h for functions common to all textures
 */
typedef struct TEMetalTexture_ TEMetalTexture;

typedef void (*TEMetalTextureCallback)(id<MTLTexture> texture, TEObjectEvent event, void * TE_NULLABLE info);

/*
 Creates a texture from a Metal texture
 'texture' is the Metal texture, and will be retained for the lifetime of the TEMetalTexture
 'callback' will be called with the values passed to 'texture' and 'info'
 'origin' is the position in 2D space of the 0th texel of the texture
 'map' describes how components are to be mapped when the texture is read. If components are not swizzled, you
	can pass kTETextureComponentMapIdentity
 The caller is responsible for releasing the returned TEMetalTexture using TERelease()
 */
TE_EXPORT
TEMetalTexture *TEMetalTextureCreate(id<MTLTexture> texture,
										TETextureOrigin origin,
										TETextureComponentMap map,
										TEMetalTextureCallback TE_NULLABLE callback, void * TE_NULLABLE info);

/*
 Returns the MTLTexture associated with the TEMetalTexture
 */
TE_EXPORT
id<MTLTexture> TEMetalTextureGetTexture(const TEMetalTexture *texture);

/*
 Sets 'callback' to be invoked for object use and lifetime events - see TEObjectEvent in TEObject.h.
 This replaces (or cancels) any callback previously set on the TEMetalTexture.
 */
TE_EXPORT
TEResult TEMetalTextureSetCallback(TEMetalTexture *texture, TEMetalTextureCallback TE_NULLABLE callback, void * TE_NULLABLE info);

/*
 Metal Graphics Contexts - see TEGraphicsContext.h for functions common to all graphics contexts.
 */

typedef struct TEMetalContext_ TEMetalContext;

/*
 Creates a TEMetalContext for a Metal device
 
 'device' is the MTLDevice to target.
 'context' will be set to a TEMetalContext on return, or NULL if the context could not be created.
    The caller is responsible for releasing the returned TEMetalContext using TERelease()
 Returns TEResultSucccess or an error
 */
TE_EXPORT TEResult TEMetalContextCreate(id<MTLDevice> device, TEMetalContext * TE_NULLABLE * TE_NONNULL context);

TE_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif

#endif // TEMetal_h
