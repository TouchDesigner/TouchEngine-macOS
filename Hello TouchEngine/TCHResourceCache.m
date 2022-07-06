//
//  TCHResourceCache.m
//  TouchEngineTest
//
//  Created by Derivative on 11/07/2022.
//

#import "TCHResourceCache.h"
#import "TCH_TouchEngine.h"
#import "TCH_TouchEngine.h"

@interface TCHResourceCache ()
- (void)endIOSurface:(IOSurfaceRef)surface;
- (void)endMetalSharedEventHandle:(MTLSharedEventHandle *)handle;
@end

static void IOSurfaceTextureCallback(IOSurfaceRef surface, TEObjectEvent event, void *info)
{
	if (event == TEObjectEventRelease)
	{
		TCHResourceCache *cache = (__bridge TCHResourceCache *)info;
		[cache endIOSurface:surface];
	}
}

static void MetalSharedEventCallback(MTLSharedEventHandle *handle, TEObjectEvent event, void *info)
{
	if (event == TEObjectEventRelease)
	{
		TCHResourceCache *cache = (__bridge TCHResourceCache *)info;
		[cache endMetalSharedEventHandle:handle];
	}
}

@implementation TCHResourceCache {
	NSMutableSet<id<MTLTexture>> *_surfaceTextures;
	NSMapTable<MTLSharedEventHandle *, id<MTLSharedEvent>> *_sharedEvents;
}

+ (TCHResourceCache *)resourceCacheForDevice:(id<MTLDevice>)device
{
	@synchronized (self) {
		static NSMutableSet<TCHResourceCache *> *theCaches = nil;
		for (TCHResourceCache *cache in theCaches) {
			if ([cache.device isEqual:device])
			{
				return cache;
			}
		}
		if (!theCaches)
		{
			theCaches = [[NSMutableSet alloc] initWithCapacity:1];
		}
		TCHResourceCache *cache = [[TCHResourceCache alloc] initWithDevice:device];
		if (cache)
		{
			[theCaches addObject:cache];
		}
		return cache;
	}
}

- (instancetype)initWithDevice:(id<MTLDevice>)device
{
	self = [super init];
	if (self)
	{
		_device = device;
	}
	return self;
}

- (TCHTexture *)textureForTETexture:(TETexture *)texture
{
	id<MTLTexture> tex = nil;
	if (texture && TETextureGetType(texture) == TETextureTypeMetal)
	{
		tex = TEMetalTextureGetTexture((TEMetalTexture *)texture);
	}
	else if (texture && TETextureGetType(texture) == TETextureTypeIOSurface)
	{
		@synchronized (self) {
			IOSurfaceRef surface = TEIOSurfaceTextureGetSurface((TEIOSurfaceTexture *)texture);
			for (id<MTLTexture> candidate in _surfaceTextures) {
				if (candidate.iosurface == surface)
				{
					tex = candidate;
				}
			}
			
			if (!tex)
			{
				TETextureFormat format = TEIOSurfaceTextureGetFormat((TEIOSurfaceTexture *)texture);
				TETextureComponentMap map = TETextureGetComponentMap(texture);
				MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:[TCHTexture metalPixelFormatForFormat:format map:map]
																									  width:IOSurfaceGetWidth(surface)
																									 height:IOSurfaceGetHeight(surface)
																								  mipmapped:NO];
				tex = [self.device newTextureWithDescriptor:descriptor iosurface:surface plane:0];
				if (tex)
				{
					if (!_surfaceTextures)
					{
						_surfaceTextures = [[NSMutableSet alloc] initWithCapacity:1];
					}
					[_surfaceTextures addObject:tex];
					// Set our callback so we can dispose of our instantiated MTLTexture when the TEIOSurfaceTexture is destroyed
					TEIOSurfaceTextureSetCallback((TEIOSurfaceTexture *)texture, IOSurfaceTextureCallback, (__bridge void *)self);
				}
			}
		}
	}
	if (tex)
	{
		return [[TCHTexture alloc] initWithMTLTexture:tex forTETexture:texture];
	}
	return nil;
}

- (void)endIOSurface:(IOSurfaceRef)surface
{
	@synchronized (self) {
		NSSet<id<MTLTexture>> *matches = [_surfaceTextures objectsPassingTest:^BOOL(id<MTLTexture>  _Nonnull obj, BOOL * _Nonnull stop) {
			return obj.iosurface == surface;
		}];
		[_surfaceTextures minusSet:matches];
	}
}

- (TCHSharedEvent *)sharedEventForTESemaphore:(TESemaphore *)semaphore
{
	if (semaphore && TESemaphoreGetType(semaphore) == TESemaphoreTypeMetal)
	{
		MTLSharedEventHandle *handle = TEMetalSemaphoreGetSharedEventHandle((TEMetalSemaphore *)semaphore);
		if (handle)
		{
			id<MTLSharedEvent> event = nil;
			@synchronized (self) {
				event = [_sharedEvents objectForKey:handle];
				if (!event)
				{
					event = [self.device newSharedEventWithHandle:handle];
					if (event)
					{
						if (!_sharedEvents)
						{
							_sharedEvents = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
						}
						[_sharedEvents setObject:event forKey:handle];
						// Set our callback so we can dispose of our instantiated MTLSharedEvent when the TEMetalSemaphore is destroyed
						TEMetalSemaphoreSetCallback((TEMetalSemaphore *)semaphore, MetalSharedEventCallback, (__bridge void *)self);
					}
				}
			}
			if (event)
			{
                return [[TCHSharedEvent alloc] initWithMTLSharedEvent:event forTESemaphore:semaphore];
			}
		}
	}
	return nil;
}

- (void)endMetalSharedEventHandle:(MTLSharedEventHandle *)handle
{
	@synchronized (self) {
		[_sharedEvents removeObjectForKey:handle];
	}
}

@end
