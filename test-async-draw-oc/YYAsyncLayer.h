//
//  YYAsyncLayer.h
//  Extracted and trimmed from YYKit for standalone demo usage.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YYAsyncLayerDisplayTask;

@interface YYAsyncLayer : CALayer

@property (nonatomic, assign) BOOL displaysAsynchronously;

@end

@protocol YYAsyncLayerDelegate <NSObject>

@required
- (YYAsyncLayerDisplayTask *)newAsyncDisplayTask;

@end

@interface YYAsyncLayerDisplayTask : NSObject

@property (nullable, nonatomic, copy) void (^willDisplay)(CALayer *layer);
@property (nullable, nonatomic, copy) void (^display)(CGContextRef context, CGSize size, BOOL(^isCancelled)(void));
@property (nullable, nonatomic, copy) void (^didDisplay)(CALayer *layer, BOOL finished);

@end

NS_ASSUME_NONNULL_END
