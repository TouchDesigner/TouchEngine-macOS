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
