//
//  ViewController.h
//  TouchEngineTest
//
//  Created by Derivative on 21/04/2022.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "TouchEngineRenderer.h"
#import "MetalRenderer.h"

@interface ViewController : NSViewController <TouchEngineRenderDelegate, MetalRendererDelegate>
@property (nonatomic, weak) IBOutlet MTKView *MTKView;
@end

