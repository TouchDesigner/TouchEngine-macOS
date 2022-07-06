//
//  SharedTexture.m
//  TouchEngineTest
//
//  Created by Derivative on 11/07/2022.
//

#import "TCHSharedTexture.h"

@implementation TCHSharedTexture
- (instancetype)initWithTexture:(TCHTexture *)texture waitEvent:(TCHSharedEvent *)event waitValue:(uint64_t)value
{
	self = [super init];
	if (self)
	{
		_texture = texture;
		_waitEvent = event;
		_waitValue = value;
	}
	return self;
}
@end
