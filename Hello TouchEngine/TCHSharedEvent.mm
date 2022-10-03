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

#import "TCHSharedEvent.h"
#import "TCH_TouchEngine.h"
#import <TouchEngine/TouchObject.h>
#import <TouchEngine/TEMetal.h>

@implementation TCHSharedEvent {
	TouchObject<TEMetalSemaphore> _engineSemaphore;
}

- (instancetype)initWithSharedEvent:(id<MTLSharedEvent>)event
{
	TouchObject<TEMetalSemaphore> semaphore = TouchObject<TEMetalSemaphore>::make_take(TEMetalSemaphoreCreate([event newSharedEventHandle], nullptr, nullptr));
	return [self initWithMTLSharedEvent:event forTESemaphore:semaphore];
}

- (instancetype)initWithMTLSharedEvent:(id<MTLSharedEvent>)event forTESemaphore:(TEMetalSemaphore *)semaphore
{
	self = [super init];
	if (self)
	{
		_engineSemaphore.set(semaphore);
		_sharedEvent = event;
	}
	return self;
}

- (TEMetalSemaphore *)engineSemaphore
{
	return _engineSemaphore;
}

@end
