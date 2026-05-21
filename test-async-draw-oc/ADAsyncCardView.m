#import "ADAsyncCardView.h"
#import "ADCardRenderer.h"
#import "ADFeedItem.h"

@interface ADAsyncCardView ()
@property (atomic, assign) NSInteger sentinel;
@property (nonatomic, assign) CGSize lastRenderedSize;
@end

@implementation ADAsyncCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = YES;
        self.layer.contentsScale = UIScreen.mainScreen.scale;
    }
    return self;
}

- (void)setItem:(ADFeedItem *)item {
    _item = item;
    [self invalidateAsyncDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.lastRenderedSize, self.bounds.size)) {
        self.lastRenderedSize = self.bounds.size;
        [self invalidateAsyncDisplay];
    }
}

- (void)displayLayer:(CALayer *)layer {
    ADFeedItem *item = self.item;
    CGSize size = layer.bounds.size;

    if (!item || size.width < 1.0 || size.height < 1.0) {
        layer.contents = nil;
        return;
    }

    NSInteger currentSentinel = self.sentinel;
    CGFloat scale = UIScreen.mainScreen.scale;

    // Core Animation still calls displayLayer: on the main thread.
    // We only schedule work here, then do the heavy bitmap drawing off-main.
    dispatch_async([ADCardRenderer renderQueue], ^{
        @autoreleasepool {
            UIImage *image = [ADCardRenderer imageForItem:item
                                                     size:size
                                                    scale:scale
                                                cancelled:^BOOL{
                return currentSentinel != self.sentinel;
            }];

            if (!image) {
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                if (currentSentinel != self.sentinel) {
                    return;
                }

                // The final UI-facing mutation stays tiny: just swap layer.contents on main.
                layer.contentsScale = scale;
                layer.contents = (__bridge id)image.CGImage;
            });
        }
    });
}

- (void)resetForReuse {
    self.sentinel += 1;
    self.item = nil;
    self.layer.contents = nil;
}

- (void)invalidateAsyncDisplay {
    // Bump the sentinel so in-flight background renders can notice they are stale.
    self.sentinel += 1;
    [self.layer setNeedsDisplay];
}

@end
