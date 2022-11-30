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
#import <MetalKit/MetalKit.h>
#import <TouchEngine/TouchEngine.h>
#import <TouchEngine/TEMetal.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MetalRendererDelegate <NSObject>

- (void)inputTextureDidChange;

@end

@class TCHSharedTexture;

@interface MetalRenderer : NSObject<MTKViewDelegate>
- (instancetype)initWithView:(nonnull MTKView *)mtkView;
@property (readwrite) BOOL useMetalSharedTextures;
@property (readwrite, weak) id<MetalRendererDelegate> delegate;
@property (readwrite, strong) NSColor *backgroundColor;
@property (readwrite, strong) NSColor *foregroundColor;
@property (readonly) id<MTLDevice> device;
@property (readonly, strong) TCHSharedTexture *inputTexture;
/*
 Returns the previous output, if any, updated with a shared event for the last render pass which used it
 */
- (nullable TCHSharedTexture *)setOutputTexture:(TCHSharedTexture *)output;
@end

NS_ASSUME_NONNULL_END
