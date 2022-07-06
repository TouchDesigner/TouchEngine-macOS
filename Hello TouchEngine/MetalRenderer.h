//
//  Renderer.h
//  TouchEngineTest
//
//  Created by Derivative on 06/07/2022.
//

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
@property (readonly) id<MTLDevice> device;
@property (readonly, strong) TCHSharedTexture *inputTexture;
/*
 Returns the previous output, if any, updated with a shared event for the last render pass which used it
 */
- (nullable TCHSharedTexture *)setOutputTexture:(TCHSharedTexture *)output;
@end

NS_ASSUME_NONNULL_END
