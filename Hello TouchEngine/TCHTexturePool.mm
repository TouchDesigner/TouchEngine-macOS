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

#import "TCHTexturePool.h"
#import "TCH_TouchEngine.h"
#import <TouchEngine/TouchEngine.h>
#import <TouchEngine/TEMetal.h>
#import <TouchEngine/TouchObject.h>
#import <CoreVideo/CoreVideo.h>

static constexpr double kTCHTexturePoolExpireSeconds = 1.0;

@interface TCHTexturePoolItem : NSObject
- (instancetype)initWithTexture:(id<MTLTexture>)mtl pool:(TCHTexturePool *)pool;
- (instancetype)initWithTexture:(id<MTLTexture>)mtl surface:(IOSurfaceRef)surface pool:(TCHTexturePool *)pool;
@property (readonly, nonatomic) id<MTLTexture> texture;
@property (readonly, nonatomic) TETexture *engineTexture;
@property (readonly, weak, nonatomic) TCHTexturePool *pool;
@property (readwrite, nonatomic) uint64_t lastUse;
- (void)beginUser;
- (void)endUser;
@end

@interface TCHTexturePoolTexture : TCHTexture
- (instancetype)initWithItem:(TCHTexturePoolItem *)item;
@property (readonly, strong, nonatomic) TCHTexturePoolItem *item;
@end

@interface TCHTexturePool ()
- (void)returnItem:(TCHTexturePoolItem *)item;
@end

static void TextureCallback(id<MTLTexture> texture, TEObjectEvent event, void * TE_NULLABLE info)
{
    switch (event) {
        case TEObjectEventBeginUse:
        {
            /*
             There will be an objective-C reference to the TCHTexturePoolItem when this is invoked
             but it may not last for as long as TouchEngine is using the texture, so retain it now
             */
            TCHTexturePoolItem *item = (__bridge TCHTexturePoolItem *)info;
            CFBridgingRetain(item);
            [item beginUser];
            break;
        }
        case TEObjectEventEndUse:
        {
            /*
             Balance our retain with a release at this point
             -endUser will then return it to the pool if it isn't in use elsewhere
             */
            TCHTexturePoolItem *item = (TCHTexturePoolItem *)CFBridgingRelease(info);
            [item endUser];
            break;
        }
        default:
            break;
    }
}

static void SurfaceCallback(IOSurfaceRef surface, TEObjectEvent event, void * TE_NULLABLE info)
{
    return TextureCallback(nil, event, info);
}

// Utility for allocating IOSurfaces
static size_t bytesPerElementForPixelFormat(MTLPixelFormat format)
{
	switch (format) {
		case MTLPixelFormatA8Unorm:
		case MTLPixelFormatR8Unorm:
		case MTLPixelFormatR8Unorm_sRGB:
		case MTLPixelFormatR8Snorm:
		case MTLPixelFormatR8Uint:
		case MTLPixelFormatR8Sint:
			return 1;
		case MTLPixelFormatR16Unorm:
		case MTLPixelFormatR16Snorm:
		case MTLPixelFormatR16Uint:
		case MTLPixelFormatR16Sint:
		case MTLPixelFormatR16Float:
		case MTLPixelFormatRG8Unorm:
		case MTLPixelFormatRG8Unorm_sRGB:
		case MTLPixelFormatRG8Snorm:
		case MTLPixelFormatRG8Uint:
		case MTLPixelFormatRG8Sint:
		case MTLPixelFormatB5G6R5Unorm:
		case MTLPixelFormatA1BGR5Unorm:
		case MTLPixelFormatABGR4Unorm:
		case MTLPixelFormatBGR5A1Unorm:
			return 2;
		case MTLPixelFormatR32Uint:
		case MTLPixelFormatR32Sint:
		case MTLPixelFormatR32Float:
		case MTLPixelFormatRG16Unorm:
		case MTLPixelFormatRG16Snorm:
		case MTLPixelFormatRG16Uint:
		case MTLPixelFormatRG16Sint:
		case MTLPixelFormatRG16Float:
		case MTLPixelFormatRGBA8Unorm:
		case MTLPixelFormatRGBA8Unorm_sRGB:
		case MTLPixelFormatRGBA8Snorm:
		case MTLPixelFormatRGBA8Uint:
		case MTLPixelFormatRGBA8Sint:
		case MTLPixelFormatBGRA8Unorm:
		case MTLPixelFormatBGRA8Unorm_sRGB:
		case MTLPixelFormatRGB10A2Unorm:
		case MTLPixelFormatRGB10A2Uint:
		case MTLPixelFormatRG11B10Float:
		case MTLPixelFormatRGB9E5Float:
		case MTLPixelFormatBGR10A2Unorm:
		case MTLPixelFormatBGR10_XR:
		case MTLPixelFormatBGR10_XR_sRGB:
			return 4;
		case MTLPixelFormatRG32Uint:
		case MTLPixelFormatRG32Sint:
		case MTLPixelFormatRG32Float:
		case MTLPixelFormatRGBA16Unorm:
		case MTLPixelFormatRGBA16Snorm:
		case MTLPixelFormatRGBA16Uint:
		case MTLPixelFormatRGBA16Sint:
		case MTLPixelFormatRGBA16Float:
		case MTLPixelFormatBGRA10_XR:
		case MTLPixelFormatBGRA10_XR_sRGB:
			return 8;
		case MTLPixelFormatRGBA32Uint:
		case MTLPixelFormatRGBA32Sint:
		case MTLPixelFormatRGBA32Float:
			return 16;
		case MTLPixelFormatBC1_RGBA:
		case MTLPixelFormatBC1_RGBA_sRGB:
			return 8;
		case MTLPixelFormatBC2_RGBA:
		case MTLPixelFormatBC2_RGBA_sRGB:
		case MTLPixelFormatBC3_RGBA:
		case MTLPixelFormatBC3_RGBA_sRGB:
			return 16;
		case MTLPixelFormatBC4_RUnorm:
		case MTLPixelFormatBC4_RSnorm:
			return 8;
		case MTLPixelFormatBC5_RGUnorm:
		case MTLPixelFormatBC5_RGSnorm:
		case MTLPixelFormatBC6H_RGBFloat:
		case MTLPixelFormatBC6H_RGBUfloat:
		case MTLPixelFormatBC7_RGBAUnorm:
		case MTLPixelFormatBC7_RGBAUnorm_sRGB:
			return 16;
		case MTLPixelFormatPVRTC_RGB_2BPP:
		case MTLPixelFormatPVRTC_RGB_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGB_4BPP:
		case MTLPixelFormatPVRTC_RGB_4BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_2BPP:
		case MTLPixelFormatPVRTC_RGBA_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_4BPP:
		case MTLPixelFormatPVRTC_RGBA_4BPP_sRGB:
			return 8;
		case MTLPixelFormatEAC_R11Unorm:
		case MTLPixelFormatEAC_R11Snorm:
			return 8;
		case MTLPixelFormatEAC_RG11Unorm:
		case MTLPixelFormatEAC_RG11Snorm:
		case MTLPixelFormatEAC_RGBA8:
		case MTLPixelFormatEAC_RGBA8_sRGB:
			return 16;
		case MTLPixelFormatETC2_RGB8:
		case MTLPixelFormatETC2_RGB8_sRGB:
		case MTLPixelFormatETC2_RGB8A1:
		case MTLPixelFormatETC2_RGB8A1_sRGB:
			return 8;
		case MTLPixelFormatASTC_4x4_sRGB:
		case MTLPixelFormatASTC_5x4_sRGB:
		case MTLPixelFormatASTC_5x5_sRGB:
		case MTLPixelFormatASTC_6x5_sRGB:
		case MTLPixelFormatASTC_6x6_sRGB:
		case MTLPixelFormatASTC_8x5_sRGB:
		case MTLPixelFormatASTC_8x6_sRGB:
		case MTLPixelFormatASTC_8x8_sRGB:
		case MTLPixelFormatASTC_10x5_sRGB:
		case MTLPixelFormatASTC_10x6_sRGB:
		case MTLPixelFormatASTC_10x8_sRGB:
		case MTLPixelFormatASTC_10x10_sRGB:
		case MTLPixelFormatASTC_12x10_sRGB:
		case MTLPixelFormatASTC_12x12_sRGB:
		case MTLPixelFormatASTC_4x4_LDR:
		case MTLPixelFormatASTC_5x4_LDR:
		case MTLPixelFormatASTC_5x5_LDR:
		case MTLPixelFormatASTC_6x5_LDR:
		case MTLPixelFormatASTC_6x6_LDR:
		case MTLPixelFormatASTC_8x5_LDR:
		case MTLPixelFormatASTC_8x6_LDR:
		case MTLPixelFormatASTC_8x8_LDR:
		case MTLPixelFormatASTC_10x5_LDR:
		case MTLPixelFormatASTC_10x6_LDR:
		case MTLPixelFormatASTC_10x8_LDR:
		case MTLPixelFormatASTC_10x10_LDR:
		case MTLPixelFormatASTC_12x10_LDR:
		case MTLPixelFormatASTC_12x12_LDR:
		case MTLPixelFormatASTC_4x4_HDR:
		case MTLPixelFormatASTC_5x4_HDR:
		case MTLPixelFormatASTC_5x5_HDR:
		case MTLPixelFormatASTC_6x5_HDR:
		case MTLPixelFormatASTC_6x6_HDR:
		case MTLPixelFormatASTC_8x5_HDR:
		case MTLPixelFormatASTC_8x6_HDR:
		case MTLPixelFormatASTC_8x8_HDR:
		case MTLPixelFormatASTC_10x5_HDR:
		case MTLPixelFormatASTC_10x6_HDR:
		case MTLPixelFormatASTC_10x8_HDR:
		case MTLPixelFormatASTC_10x10_HDR:
		case MTLPixelFormatASTC_12x10_HDR:
		case MTLPixelFormatASTC_12x12_HDR:
			return 16;
		case MTLPixelFormatGBGR422:
		case MTLPixelFormatBGRG422:
			return 4;
		case MTLPixelFormatDepth16Unorm:
			return 2;
		case MTLPixelFormatDepth32Float:
			return 4;
		case MTLPixelFormatStencil8:
			return 1;
		case MTLPixelFormatDepth24Unorm_Stencil8:
		case MTLPixelFormatX24_Stencil8:
			return 4;
		case MTLPixelFormatDepth32Float_Stencil8:
		case MTLPixelFormatX32_Stencil8:
			return 5;
		case MTLPixelFormatInvalid:
			break;
	}
	return 0;
}

// Utility for allocating IOSurfaces
static int blockHeightForPixelFormat(MTLPixelFormat format)
{
	switch (format) {
		case MTLPixelFormatA8Unorm:
		case MTLPixelFormatR8Unorm:
		case MTLPixelFormatR8Unorm_sRGB:
		case MTLPixelFormatR8Snorm:
		case MTLPixelFormatR8Uint:
		case MTLPixelFormatR8Sint:
		case MTLPixelFormatR16Unorm:
		case MTLPixelFormatR16Snorm:
		case MTLPixelFormatR16Uint:
		case MTLPixelFormatR16Sint:
		case MTLPixelFormatR16Float:
		case MTLPixelFormatRG8Unorm:
		case MTLPixelFormatRG8Unorm_sRGB:
		case MTLPixelFormatRG8Snorm:
		case MTLPixelFormatRG8Uint:
		case MTLPixelFormatRG8Sint:
		case MTLPixelFormatB5G6R5Unorm:
		case MTLPixelFormatA1BGR5Unorm:
		case MTLPixelFormatABGR4Unorm:
		case MTLPixelFormatBGR5A1Unorm:
		case MTLPixelFormatR32Uint:
		case MTLPixelFormatR32Sint:
		case MTLPixelFormatR32Float:
		case MTLPixelFormatRG16Unorm:
		case MTLPixelFormatRG16Snorm:
		case MTLPixelFormatRG16Uint:
		case MTLPixelFormatRG16Sint:
		case MTLPixelFormatRG16Float:
		case MTLPixelFormatRGBA8Unorm:
		case MTLPixelFormatRGBA8Unorm_sRGB:
		case MTLPixelFormatRGBA8Snorm:
		case MTLPixelFormatRGBA8Uint:
		case MTLPixelFormatRGBA8Sint:
		case MTLPixelFormatBGRA8Unorm:
		case MTLPixelFormatBGRA8Unorm_sRGB:
		case MTLPixelFormatRGB10A2Unorm:
		case MTLPixelFormatRGB10A2Uint:
		case MTLPixelFormatRG11B10Float:
		case MTLPixelFormatRGB9E5Float:
		case MTLPixelFormatBGR10A2Unorm:
		case MTLPixelFormatBGR10_XR:
		case MTLPixelFormatBGR10_XR_sRGB:
		case MTLPixelFormatRG32Uint:
		case MTLPixelFormatRG32Sint:
		case MTLPixelFormatRG32Float:
		case MTLPixelFormatRGBA16Unorm:
		case MTLPixelFormatRGBA16Snorm:
		case MTLPixelFormatRGBA16Uint:
		case MTLPixelFormatRGBA16Sint:
		case MTLPixelFormatRGBA16Float:
		case MTLPixelFormatBGRA10_XR:
		case MTLPixelFormatBGRA10_XR_sRGB:
		case MTLPixelFormatRGBA32Uint:
		case MTLPixelFormatRGBA32Sint:
		case MTLPixelFormatRGBA32Float:
			return 1;
		case MTLPixelFormatBC1_RGBA:
		case MTLPixelFormatBC1_RGBA_sRGB:
		case MTLPixelFormatBC2_RGBA:
		case MTLPixelFormatBC2_RGBA_sRGB:
		case MTLPixelFormatBC3_RGBA:
		case MTLPixelFormatBC3_RGBA_sRGB:
		case MTLPixelFormatBC4_RUnorm:
		case MTLPixelFormatBC4_RSnorm:
		case MTLPixelFormatBC5_RGUnorm:
		case MTLPixelFormatBC5_RGSnorm:
		case MTLPixelFormatBC6H_RGBFloat:
		case MTLPixelFormatBC6H_RGBUfloat:
		case MTLPixelFormatBC7_RGBAUnorm:
		case MTLPixelFormatBC7_RGBAUnorm_sRGB:
		case MTLPixelFormatPVRTC_RGB_2BPP:
		case MTLPixelFormatPVRTC_RGB_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGB_4BPP:
		case MTLPixelFormatPVRTC_RGB_4BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_2BPP:
		case MTLPixelFormatPVRTC_RGBA_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_4BPP:
		case MTLPixelFormatPVRTC_RGBA_4BPP_sRGB:
		case MTLPixelFormatEAC_R11Unorm:
		case MTLPixelFormatEAC_R11Snorm:
		case MTLPixelFormatEAC_RG11Unorm:
		case MTLPixelFormatEAC_RG11Snorm:
		case MTLPixelFormatEAC_RGBA8:
		case MTLPixelFormatEAC_RGBA8_sRGB:
		case MTLPixelFormatETC2_RGB8:
		case MTLPixelFormatETC2_RGB8_sRGB:
		case MTLPixelFormatETC2_RGB8A1:
		case MTLPixelFormatETC2_RGB8A1_sRGB:
		case MTLPixelFormatASTC_4x4_sRGB:
		case MTLPixelFormatASTC_5x4_sRGB:
		case MTLPixelFormatASTC_4x4_LDR:
		case MTLPixelFormatASTC_5x4_LDR:
		case MTLPixelFormatASTC_4x4_HDR:
		case MTLPixelFormatASTC_5x4_HDR:
			return 4;
		case MTLPixelFormatASTC_5x5_sRGB:
		case MTLPixelFormatASTC_6x5_sRGB:
		case MTLPixelFormatASTC_8x5_sRGB:
		case MTLPixelFormatASTC_10x5_sRGB:
		case MTLPixelFormatASTC_5x5_LDR:
		case MTLPixelFormatASTC_6x5_LDR:
		case MTLPixelFormatASTC_8x5_LDR:
		case MTLPixelFormatASTC_10x5_LDR:
		case MTLPixelFormatASTC_5x5_HDR:
		case MTLPixelFormatASTC_6x5_HDR:
		case MTLPixelFormatASTC_8x5_HDR:
		case MTLPixelFormatASTC_10x5_HDR:
			return 5;
		case MTLPixelFormatASTC_6x6_sRGB:
		case MTLPixelFormatASTC_8x6_sRGB:
		case MTLPixelFormatASTC_10x6_sRGB:
		case MTLPixelFormatASTC_6x6_LDR:
		case MTLPixelFormatASTC_8x6_LDR:
		case MTLPixelFormatASTC_10x6_LDR:
		case MTLPixelFormatASTC_6x6_HDR:
		case MTLPixelFormatASTC_8x6_HDR:
		case MTLPixelFormatASTC_10x6_HDR:
			return 6;
		case MTLPixelFormatASTC_8x8_sRGB:
		case MTLPixelFormatASTC_10x8_sRGB:
		case MTLPixelFormatASTC_8x8_LDR:
		case MTLPixelFormatASTC_10x8_LDR:
		case MTLPixelFormatASTC_8x8_HDR:
		case MTLPixelFormatASTC_10x8_HDR:
			return 8;
		case MTLPixelFormatASTC_10x10_sRGB:
		case MTLPixelFormatASTC_12x10_sRGB:
		case MTLPixelFormatASTC_10x10_LDR:
		case MTLPixelFormatASTC_12x10_LDR:
		case MTLPixelFormatASTC_10x10_HDR:
		case MTLPixelFormatASTC_12x10_HDR:
			return 10;
		case MTLPixelFormatASTC_12x12_sRGB:
		case MTLPixelFormatASTC_12x12_LDR:
		case MTLPixelFormatASTC_12x12_HDR:
			return 12;
		case MTLPixelFormatGBGR422:
		case MTLPixelFormatBGRG422:
		case MTLPixelFormatDepth16Unorm:
		case MTLPixelFormatDepth32Float:
		case MTLPixelFormatStencil8:
		case MTLPixelFormatDepth24Unorm_Stencil8:
		case MTLPixelFormatX24_Stencil8:
		case MTLPixelFormatDepth32Float_Stencil8:
		case MTLPixelFormatX32_Stencil8:
			return 1;
		case MTLPixelFormatInvalid:
			break;
	}
	return 0;
}

// Utility for allocating IOSurfaces
static int blockWidthForPixelFormat(MTLPixelFormat format)
{
	switch (format) {
		// Non-square block sizes:
		case MTLPixelFormatPVRTC_RGB_2BPP:
		case MTLPixelFormatPVRTC_RGB_2BPP_sRGB:
		case MTLPixelFormatPVRTC_RGBA_2BPP:
		case MTLPixelFormatPVRTC_RGBA_2BPP_sRGB:
		case MTLPixelFormatASTC_8x5_sRGB:
		case MTLPixelFormatASTC_8x6_sRGB:
		case MTLPixelFormatASTC_8x5_LDR:
		case MTLPixelFormatASTC_8x6_LDR:
		case MTLPixelFormatASTC_8x5_HDR:
		case MTLPixelFormatASTC_8x6_HDR:
			return 8;
		case MTLPixelFormatASTC_5x4_sRGB:
		case MTLPixelFormatASTC_5x4_LDR:
		case MTLPixelFormatASTC_5x4_HDR:
			return 5;
		case MTLPixelFormatASTC_6x5_sRGB:
		case MTLPixelFormatASTC_6x5_LDR:
		case MTLPixelFormatASTC_6x5_HDR:
			return 6;
		case MTLPixelFormatASTC_10x5_sRGB:
		case MTLPixelFormatASTC_10x6_sRGB:
		case MTLPixelFormatASTC_10x8_sRGB:
		case MTLPixelFormatASTC_10x5_LDR:
		case MTLPixelFormatASTC_10x6_LDR:
		case MTLPixelFormatASTC_10x8_LDR:
		case MTLPixelFormatASTC_10x5_HDR:
		case MTLPixelFormatASTC_10x6_HDR:
		case MTLPixelFormatASTC_10x8_HDR:
			return 10;
		case MTLPixelFormatASTC_12x10_sRGB:
		case MTLPixelFormatASTC_12x10_LDR:
		case MTLPixelFormatASTC_12x10_HDR:
			return 12;
		case MTLPixelFormatGBGR422:
		case MTLPixelFormatBGRG422:
			return 2;
		default:
			// Square block sizes:
			return blockHeightForPixelFormat(format);
	}
}

@implementation TCHTexturePoolTexture

- (instancetype)initWithItem:(TCHTexturePoolItem *)item
{
	self = [super initWithMTLTexture:item.texture forTETexture:item.engineTexture];
	if (self)
	{
        [item beginUser];
        _item = item;
	}
	return self;
}

- (void)dealloc
{
    [self.item endUser];
}
@end

@implementation TCHTexturePool {
	NSMutableSet<TCHTexturePoolItem *> *_items;
    dispatch_source_t _timer;
}
- (instancetype)initForDevice:(id<MTLDevice>)device descriptor:(MTLTextureDescriptor *)descriptor shareMode:(TCHTextureShareMode)mode
{
	self = [super init];
	if (self)
	{
		_device = device;
		// Force the required mode for IOSurface or shareable textures
		if (mode == TCHTextureShareModeIOSurface)
		{
			descriptor.storageMode = MTLStorageModeManaged;
		}
		else
		{
			descriptor.storageMode = MTLStorageModePrivate;
		}
		_descriptor = descriptor;
		_shareMode = mode;
		_items = [[NSMutableSet alloc] initWithCapacity:4];
        if (kTCHTexturePoolExpireSeconds > 0.0)
        {
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0));
            uint64_t interval = NSEC_PER_SEC * kTCHTexturePoolExpireSeconds;
            dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, interval, interval);
            
            // Do not retain self in this block, or we will never be released
            NSMutableSet<TCHTexturePoolItem *> *itemsForBlock = _items;
            dispatch_source_set_event_handler(_timer, ^{
                @autoreleasepool {
                    uint64_t now = CVGetCurrentHostTime();
                    double freq = CVGetHostClockFrequency();
                    uint64_t expire = now - (freq * kTCHTexturePoolExpireSeconds);
                    NSMutableSet *discard = [NSMutableSet set];
                    @synchronized (itemsForBlock) {
                        for (TCHTexturePoolItem *it : itemsForBlock)
                        {
                            if (it.lastUse < expire)
                            {
                                [discard addObject:it];
                            }
                        }
                        [itemsForBlock minusSet:discard];
                    }
                    // Do any actual resource deletion outside the @synchronized section
                    [discard removeAllObjects];
                }
            });
            dispatch_resume(_timer);
        }
	}
	return self;
}

- (void)dealloc
{
    dispatch_source_cancel(_timer);
}

- (TCHTexture *)newTexture
{
    TCHTexturePoolItem *item = nil;
	@synchronized (_items) {
        item = [_items anyObject];
		if (item)
		{
            [_items removeObject:item];
		}
	}
    
    if (!item)
    {
        id<MTLTexture> mtl = nil;
        if (self.shareMode == TCHTextureShareModeIOSurface)
        {
            int blockW = blockWidthForPixelFormat(self.descriptor.pixelFormat);
            int blockH = blockHeightForPixelFormat(self.descriptor.pixelFormat);
            size_t bpe = bytesPerElementForPixelFormat(self.descriptor.pixelFormat);
            
            if (blockW != 0 && blockH != 0 && bpe != 0)
            {
                NSDictionary<NSString *, id<NSObject>> *properties = @{
                    (id)kIOSurfaceWidth: @(self.descriptor.width),
                    (id)kIOSurfaceHeight: @(self.descriptor.height),
                    (id)kIOSurfaceBytesPerElement: @(bpe),
                    (id)kIOSurfaceElementWidth: @(blockW),
                    (id)kIOSurfaceElementHeight: @(blockH),
                };
                
                IOSurfaceRef surface = IOSurfaceCreate((CFDictionaryRef)properties);
                
                mtl = [_device newTextureWithDescriptor:self.descriptor iosurface:surface plane:0];
                
                item = [[TCHTexturePoolItem alloc] initWithTexture:mtl surface:surface pool:self];
                
                CFRelease(surface);
            }
        }
        else
        {
            mtl = [self.device newSharedTextureWithDescriptor:self.descriptor];
            item = [[TCHTexturePoolItem alloc] initWithTexture:mtl pool:self];
        }
    }
	
    if (item)
    {
        return [[TCHTexturePoolTexture alloc] initWithItem:item];
    }
	return nil;
}

- (void)returnItem:(TCHTexturePoolItem *)item
{
    item.lastUse = CVGetCurrentHostTime();
	@synchronized (_items) {
        [_items addObject:item];
	}
}

@end

@implementation TCHTexturePoolItem {
    TouchObject<TETexture> _object;
    int _users;
}

- (instancetype)initWithTexture:(id<MTLTexture>)mtl pool:(TCHTexturePool *)pool
{
    return [self initWithTexture:mtl surface:nil pool:pool];
}

- (instancetype)initWithTexture:(id<MTLTexture>)mtl surface:(IOSurfaceRef)surface pool:(TCHTexturePool *)pool
{
    self = [super init];
    if (self)
    {
        if (surface)
        {
            _object.take(TEIOSurfaceTextureCreate(surface,
                                                  [TCHTexture formatForMetalPixelFormat:mtl.pixelFormat],
                                                  0,
                                                  TETextureOriginTopLeft,
                                                  [TCHTexture mapForMetalSwizzle:mtl.swizzle],
                                                  SurfaceCallback, (__bridge  void *)self));
        }
        else
        {
            _object.take(TEMetalTextureCreate(mtl,
                                              TETextureOriginTopLeft,
                                              [TCHTexture mapForMetalSwizzle:mtl.swizzle],
                                              TextureCallback, (__bridge void *)self));
        }
        _texture = mtl;
        _pool = pool;
    }
    return self;
}

- (TETexture *)engineTexture
{
    return _object.get();
}

- (void)beginUser
{
    @synchronized (self) {
        _users++;
    }
}

- (void)endUser
{
    @synchronized (self) {
        if (--_users == 0)
        {
            [self.pool returnItem:self];
        }
    }
}

@end
