//
//  TCHSharedEvent.m
//  TouchEngineTest
//
//  Created by Derivative on 20/07/2022.
//

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
