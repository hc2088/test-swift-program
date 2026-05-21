#import "ADSyncCardView.h"
#import "ADCardRenderer.h"
#import "ADFeedItem.h"

@interface ADSyncCardView ()
@property (nonatomic, assign) CGSize lastRenderedSize;
@end

@implementation ADSyncCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = YES;
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)setItem:(ADFeedItem *)item {
    _item = item;
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.lastRenderedSize, self.bounds.size)) {
        self.lastRenderedSize = self.bounds.size;
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (!self.item) {
        [[UIColor clearColor] setFill];
        UIRectFill(rect);
        return;
    }

    // This is the default UIKit path: the expensive raster work runs on the main thread.
    [ADCardRenderer drawItem:self.item inRect:self.bounds cancelled:nil];
}

- (void)resetForReuse {
    self.item = nil;
}

@end
