//
//  TouchEngineRenderer.h
//  TouchEngineTest
//
//  Created by Derivative on 08/07/2022.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

/*
 An extremely simple renderer which exposes the first texture input and output on a TouchDesigner component.
 */

extern NSErrorDomain const TouchEngineRenderErrorDomain;

@class TCHSharedTexture;

@protocol TouchEngineRenderDelegate <NSObject>
- (void)engineConfigureDidComplete:(nullable NSError *)error;
- (void)engineLoadDidComplete:(nullable NSError *)error;
- (void)engineError:(NSError *)error;
/*
 Delegate provides the previous output with an updated TCHSharedEvent (or nil if none). TouchEngine will wait for
 the shared event before re-using the texture.
 */
- (TCHSharedTexture *)engineOutputDidChange:(TCHSharedTexture *)texture;
@end

@interface TouchEngineRenderer : NSObject
- (instancetype)initForDevice:(id<MTLDevice>)device error:(NSError **)error;
- (BOOL)loadComponent:(NSURL *)url error:(NSError **)error;
- (BOOL)resume:(NSError **)error;
- (BOOL)pause:(NSError **)error;
@property (readwrite, weak) id<TouchEngineRenderDelegate> delegate;
@property (readwrite, strong) TCHSharedTexture *inputTexture;

/*
 IOSurface-backed textures are always supported, if this returns true, Metal shared textures are supported too
 */
@property (readonly) BOOL supportsMetalSharedTextures;

@end

NS_ASSUME_NONNULL_END
