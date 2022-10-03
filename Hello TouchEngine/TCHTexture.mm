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

#import "TCHTexture.h"
#import "TCH_TouchEngine.h"
#import <TouchEngine/TouchObject.h>

@implementation TCHTexture {
	TouchObject<TETexture> _engineTexture;
}


+ (TETextureComponentMap)componentMapForMetalPixelFormat:(MTLPixelFormat)format
{
	switch (format)
	{
		case MTLPixelFormatBGRA8Unorm:
		case MTLPixelFormatBGRA8Unorm_sRGB:
			return TETextureComponentMap{TETextureComponentSourceBlue, TETextureComponentSourceGreen, TETextureComponentSourceRed, TETextureComponentSourceAlpha};
		case MTLPixelFormatA8Unorm:
			return TETextureComponentMap{TETextureComponentSourceZero, TETextureComponentSourceZero, TETextureComponentSourceZero, TETextureComponentSourceRed};
		default:
			return kTETextureComponentMapIdentity;
	}
}

+ (TETextureFormat)formatForMetalPixelFormat:(MTLPixelFormat)format
{
	switch (format)
	{
		case MTLPixelFormatR8Unorm:
		case MTLPixelFormatA8Unorm:
			return TETextureFormatR8;
		case MTLPixelFormatR16Unorm:
			return TETextureFormatR16;
		case MTLPixelFormatR16Float:
			return TETextureFormatR16F;
		case MTLPixelFormatR32Uint:
			return TETextureFormatR32;
		case MTLPixelFormatR32Float:
			return TETextureFormatR32F;
		case MTLPixelFormatRG8Unorm:
			return TETextureFormatRG8;
		case MTLPixelFormatRG16Unorm:
			return TETextureFormatRG16;
		case MTLPixelFormatRG16Float:
			return TETextureFormatRG16F;
		case MTLPixelFormatRG32Uint:
			return TETextureFormatRG32;
		case MTLPixelFormatRG32Float:
			return TETextureFormatRG32F;
		case MTLPixelFormatRGB10A2Unorm:
			return TETextureFormatRGB10_A2;
        case MTLPixelFormatRG11B10Float:
            return TETextureFormatRGB11F;
		case MTLPixelFormatRGBA8Unorm:
		case MTLPixelFormatBGRA8Unorm:
			return TETextureFormatRGBA8;
		case MTLPixelFormatRGBA8Unorm_sRGB:
		case MTLPixelFormatBGRA8Unorm_sRGB:
			return TETextureFormatSRGBA8;
		case MTLPixelFormatRGBA16Unorm:
			return TETextureFormatRGBA16;
		case MTLPixelFormatRGBA16Float:
			return TETextureFormatRGBA16F;
		case MTLPixelFormatRGBA32Uint:
			return TETextureFormatRGBA32;
		case MTLPixelFormatRGBA32Float:
			return TETextureFormatRGBA32F;
		default:
			return TETextureFormatInvalid;
	}
}

#define IS_IDENTITY(x) (x.r == TETextureComponentSourceRed && x.g == TETextureComponentSourceGreen && x.b == TETextureComponentSourceBlue && x.a == TETextureComponentSourceAlpha)
#define IS_BGRA(x) (x.r == TETextureComponentSourceBlue && x.g == TETextureComponentSourceGreen && x.b == TETextureComponentSourceRed && x.a == TETextureComponentSourceAlpha)

+ (MTLPixelFormat)metalPixelFormatForFormat:(TETextureFormat)format map:(TETextureComponentMap)map
{
	switch (format)
	{
		case TETextureFormatR8:
			if (map.a == TETextureComponentSourceRed)
				return MTLPixelFormatA8Unorm;
			return MTLPixelFormatR8Unorm;
		case TETextureFormatR16:
			return MTLPixelFormatR16Unorm;
		case TETextureFormatR16F:
			return MTLPixelFormatR16Float;
		case TETextureFormatR32:
			return MTLPixelFormatR32Uint;
		case TETextureFormatR32F:
			return MTLPixelFormatR32Float;
		case TETextureFormatRG8:
			return MTLPixelFormatRG8Unorm;
		case TETextureFormatRG16:
			return MTLPixelFormatRG16Unorm;
		case TETextureFormatRG16F:
			return MTLPixelFormatRG16Float;
		case TETextureFormatRG32:
			return MTLPixelFormatRG32Uint;
		case TETextureFormatRG32F:
			return MTLPixelFormatRG32Float;
		case TETextureFormatRGB10_A2:
			return MTLPixelFormatRGB10A2Unorm;
        case TETextureFormatRGB11F:
            return MTLPixelFormatRG11B10Float;
		case TETextureFormatRGBA8:
			if (IS_IDENTITY(map))
				return MTLPixelFormatRGBA8Unorm;
			else if (IS_BGRA(map))
				return MTLPixelFormatBGRA8Unorm;
			break;
		case TETextureFormatSRGBA8:
			if (IS_IDENTITY(map))
				return MTLPixelFormatRGBA8Unorm_sRGB;
			else if (IS_BGRA(map))
				return MTLPixelFormatBGRA8Unorm_sRGB;
			break;
		case TETextureFormatRGBA16:
			return MTLPixelFormatRGBA16Unorm;
		case TETextureFormatRGBA16F:
			return MTLPixelFormatRGBA16Float;
		case TETextureFormatRGBA32:
			return MTLPixelFormatRGBA32Uint;
		case TETextureFormatRGBA32F:
			return MTLPixelFormatRGBA32Float;
		case TETextureFormatRGB8:
		case TETextureFormatSRGB8:
		case TETextureFormatRGB16:
		case TETextureFormatRGB16F:
		case TETextureFormatRGB32:
		case TETextureFormatRGB32F:
		default:
			break;
	}
	return MTLPixelFormatInvalid;
}

- (instancetype)initWithTexture:(id<MTLTexture>)texture
{
	TouchObject<TETexture> engine;
	if (texture.isShareable)
	{
		engine.take(TEMetalTextureCreate(texture, TETextureOriginTopLeft, kTETextureComponentMapIdentity, nullptr, nullptr));
	}
	else if (texture.iosurface)
	{
		TETextureFormat format = [TCHTexture formatForMetalPixelFormat:texture.pixelFormat];
		TETextureComponentMap map = [TCHTexture componentMapForMetalPixelFormat:texture.pixelFormat];
		if (format != TETextureFormatInvalid)
		{
			engine.take(TEIOSurfaceTextureCreate(texture.iosurface,
												 format,
												 0,
												 TETextureOriginTopLeft,
												 map, nullptr, nullptr));
		}
	}
	return [self initWithMTLTexture:texture forTETexture:engine];
}

- (instancetype)initWithMTLTexture:(id<MTLTexture>)metal forTETexture:(TETexture *)texture
{
	self = [super init];
	if (self)
	{
		_texture = metal;
		_engineTexture.set(texture);
	}
	return self;
}

- (TETexture *)engineTexture
{
	return _engineTexture;
}

@end
