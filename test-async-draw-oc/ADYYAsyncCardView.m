#import "ADYYAsyncCardView.h"
#import "ADCardRenderer.h"
#import "ADFeedItem.h"
#import "YYAsyncLayer.h"

@interface ADYYAsyncCardView () <YYAsyncLayerDelegate>
@property (nonatomic, assign) CGSize lastRenderedSize;
@end

@implementation ADYYAsyncCardView

+ (Class)layerClass {
    return YYAsyncLayer.class;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = YES;
        ((YYAsyncLayer *)self.layer).displaysAsynchronously = YES;
    }
    return self;
}

- (void)setItem:(ADFeedItem *)item {
    _item = item;
    [self.layer setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.lastRenderedSize, self.bounds.size)) {
        self.lastRenderedSize = self.bounds.size;
        [self.layer setNeedsDisplay];
    }
}

- (YYAsyncLayerDisplayTask *)newAsyncDisplayTask {
    ADFeedItem *item = self.item;
    YYAsyncLayerDisplayTask *task = [YYAsyncLayerDisplayTask new];

    if (!item) {
        return task;
    }

    task.display = ^(CGContextRef context, CGSize size, BOOL (^isCancelled)(void)) {
        if (!context || size.width < 1.0 || size.height < 1.0) {
            return;
        }
        [ADCardRenderer drawItem:item
                          inRect:(CGRect){CGPointZero, size}
                       cancelled:isCancelled];
    };
    return task;
}

- (void)resetForReuse {
    self.item = nil;
    self.layer.contents = nil;
    [self.layer setNeedsDisplay];
}

@end
