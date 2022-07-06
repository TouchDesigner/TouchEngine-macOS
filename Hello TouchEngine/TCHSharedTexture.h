//
//  SharedTexture.h
//  TouchEngineTest
//
//  Created by Derivative on 11/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@class TCHTexture;
@class TCHSharedEvent;

/// TCHSharedTexture combines a texture and the state required to synchronize usage with TouchEngine
/// waitEvent and waitValue are used to achieve the GPU wait required prior to accessing the texture.
@interface TCHSharedTexture : NSObject
- (instancetype)initWithTexture:(TCHTexture *)texture waitEvent:(nullable TCHSharedEvent *)event waitValue:(uint64_t)value;
@property (readonly, strong, nonatomic) TCHTexture *texture;
@property (readonly, strong, nullable, nonatomic) TCHSharedEvent *waitEvent;
@property (readonly, nonatomic) uint64_t waitValue;
@end

NS_ASSUME_NONNULL_END
