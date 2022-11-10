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

+ (TETextureComponentMap)mapForMetalSwizzle:(MTLTextureSwizzleChannels)swizzle
{
    auto swizzleChannel = [](MTLTextureSwizzle s) constexpr {
        switch (s)
        {
            case MTLTextureSwizzleOne:
                return TETextureComponentSourceOne;
            case MTLTextureSwizzleZero:
                return TETextureComponentSourceZero;
            case MTLTextureSwizzleRed:
                return TETextureComponentSourceRed;
            case MTLTextureSwizzleGreen:
                return TETextureComponentSourceGreen;
            case MTLTextureSwizzleBlue:
                return TETextureComponentSourceBlue;
            case MTLTextureSwizzleAlpha:
                return TETextureComponentSourceAlpha;
        }
    };
    TETextureComponentMap map;
    map.r = swizzleChannel(swizzle.red);
    map.g = swizzleChannel(swizzle.green);
    map.b = swizzleChannel(swizzle.blue);
    map.a = swizzleChannel(swizzle.alpha);
    return map;
}

+ (MTLTextureSwizzleChannels)metalSwizzleForMap:(TETextureComponentMap)map
{
    auto swizzleChannel = [](TETextureComponentSource s) constexpr {
        switch (s)
        {
            case TETextureComponentSourceOne:
                return MTLTextureSwizzleOne;
            case TETextureComponentSourceZero:
                return MTLTextureSwizzleZero;
            case TETextureComponentSourceRed:
                return MTLTextureSwizzleRed;
            case TETextureComponentSourceGreen:
                return MTLTextureSwizzleGreen;
            case TETextureComponentSourceBlue:
                return MTLTextureSwizzleBlue;
            case TETextureComponentSourceAlpha:
                return MTLTextureSwizzleAlpha;
        }
    };
    MTLTextureSwizzleChannels channels;
    channels.red = swizzleChannel(map.r);
    channels.green = swizzleChannel(map.g);
    channels.blue = swizzleChannel(map.b);
    channels.alpha = swizzleChannel(map.a);
    return channels;
}

+ (TETextureFormat)formatForMetalPixelFormat:(MTLPixelFormat)format
{
	switch (format)
	{
		case MTLPixelFormatR8Unorm:
			return TETextureFormatR8Unorm;
		case MTLPixelFormatR16Unorm:
			return TETextureFormatR16Unorm;
		case MTLPixelFormatR16Float:
			return TETextureFormatR16F;
		case MTLPixelFormatR32Float:
			return TETextureFormatR32F;
		case MTLPixelFormatRG8Unorm:
			return TETextureFormatRG8Unorm;
		case MTLPixelFormatRG16Unorm:
			return TETextureFormatRG16Unorm;
		case MTLPixelFormatRG16Float:
			return TETextureFormatRG16F;
		case MTLPixelFormatRG32Float:
			return TETextureFormatRG32F;
		case MTLPixelFormatRGB10A2Unorm:
			return TETextureFormatRGB10_A2Unorm;
        case MTLPixelFormatBGR10A2Unorm:
            return TETextureFormatBGR10_A2Unorm;
        case MTLPixelFormatRG11B10Float:
            return TETextureFormatRG11B10F;
		case MTLPixelFormatRGBA8Unorm:
            return TETextureFormatRGBA8Unorm;
		case MTLPixelFormatBGRA8Unorm:
            return TETextureFormatBGRA8Unorm;
		case MTLPixelFormatRGBA8Unorm_sRGB:
            return TETextureFormatSRGBA8Unorm;
		case MTLPixelFormatBGRA8Unorm_sRGB:
			return TETextureFormatSBGRA8Unorm;
		case MTLPixelFormatRGBA16Unorm:
			return TETextureFormatRGBA16Unorm;
		case MTLPixelFormatRGBA16Float:
			return TETextureFormatRGBA16F;
		case MTLPixelFormatRGBA32Float:
			return TETextureFormatRGBA32F;
		default:
			return TETextureFormatInvalid;
	}
}

+ (MTLPixelFormat)metalPixelFormatForFormat:(TETextureFormat)format
{
	switch (format)
	{
		case TETextureFormatR8Unorm:
			return MTLPixelFormatR8Unorm;
		case TETextureFormatR16Unorm:
			return MTLPixelFormatR16Unorm;
		case TETextureFormatR16F:
			return MTLPixelFormatR16Float;
		case TETextureFormatR32F:
			return MTLPixelFormatR32Float;
		case TETextureFormatRG8Unorm:
			return MTLPixelFormatRG8Unorm;
		case TETextureFormatRG16Unorm:
			return MTLPixelFormatRG16Unorm;
		case TETextureFormatRG16F:
			return MTLPixelFormatRG16Float;
		case TETextureFormatRG32F:
			return MTLPixelFormatRG32Float;
		case TETextureFormatRGB10_A2Unorm:
			return MTLPixelFormatRGB10A2Unorm;
        case TETextureFormatBGR10_A2Unorm:
            return MTLPixelFormatBGR10A2Unorm;
        case TETextureFormatRG11B10F:
            return MTLPixelFormatRG11B10Float;
		case TETextureFormatRGBA8Unorm:
            return MTLPixelFormatRGBA8Unorm;
        case TETextureFormatBGRA8Unorm:
            return MTLPixelFormatBGRA8Unorm;
		case TETextureFormatSRGBA8Unorm:
            return MTLPixelFormatRGBA8Unorm_sRGB;
        case TETextureFormatSBGRA8Unorm:
            return MTLPixelFormatBGRA8Unorm_sRGB;
		case TETextureFormatRGBA16Unorm:
			return MTLPixelFormatRGBA16Unorm;
		case TETextureFormatRGBA16F:
			return MTLPixelFormatRGBA16Float;
		case TETextureFormatRGBA32F:
			return MTLPixelFormatRGBA32Float;
        case TETextureFormatInvalid:
			break;
	}
	return MTLPixelFormatInvalid;
}

- (instancetype)initWithTexture:(id<MTLTexture>)texture
{
	TouchObject<TETexture> engine;
	if (texture.isShareable)
	{
		engine.take(TEMetalTextureCreate(texture, TETextureOriginTopLeft,
                                         [TCHTexture mapForMetalSwizzle:texture.swizzle],
                                         nullptr, nullptr));
	}
	else if (texture.iosurface)
	{
		TETextureFormat format = [TCHTexture formatForMetalPixelFormat:texture.pixelFormat];
        TETextureComponentMap map = [TCHTexture mapForMetalSwizzle:texture.swizzle];
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
