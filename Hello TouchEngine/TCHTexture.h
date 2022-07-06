//
//  TCHTexture.h
//  TouchEngineTest
//
//  Created by Derivative on 20/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/// TCHTexture pairs a MTLTexture and TETexture
@interface TCHTexture : NSObject
- (instancetype)initWithTexture:(id<MTLTexture>)texture;
@property (readonly, strong, nonatomic) id<MTLTexture> texture;
/*
 See TCH_TouchEngine.h for features related to TouchEngine types
 */
@end

NS_ASSUME_NONNULL_END
