//
//  TCHSharedEvent.h
//  TouchEngineTest
//
//  Created by Derivative on 20/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// TCHSharedEvent pairs a MTLSharedEvent and TESemaphore
@interface TCHSharedEvent : NSObject
- (instancetype)initWithSharedEvent:(id<MTLSharedEvent>)event;
@property (readonly, strong, nonatomic) id<MTLSharedEvent> sharedEvent;
/*
 See TCH_TouchEngine.h for methods related to TouchEngine types
 */
@end

NS_ASSUME_NONNULL_END
