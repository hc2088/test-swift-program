#import "ADFPSLabel.h"

@interface ADFPSLabel ()
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger tickCount;
@end

@implementation ADFPSLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont monospacedDigitSystemFontOfSize:15.0 weight:UIFontWeightSemibold];
        self.textColor = [UIColor colorWithRed:0.11 green:0.19 blue:0.30 alpha:1.0];
        self.numberOfLines = 1;
        self.textAlignment = NSTextAlignmentRight;
        self.text = @"FPS --";
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window && !self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step:)];
        [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    } else if (!self.window) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)step:(CADisplayLink *)link {
    if (self.lastTime == 0) {
        self.lastTime = link.timestamp;
        return;
    }

    self.tickCount += 1;
    NSTimeInterval delta = link.timestamp - self.lastTime;
    if (delta < 1.0) {
        return;
    }

    CGFloat fps = self.tickCount / delta;
    self.lastTime = link.timestamp;
    self.tickCount = 0;
    self.text = [NSString stringWithFormat:@"FPS %.0f", round(fps)];
    self.textColor = fps > 55 ? [UIColor colorWithRed:0.11 green:0.52 blue:0.29 alpha:1.0] : (fps > 45 ? [UIColor colorWithRed:0.82 green:0.56 blue:0.13 alpha:1.0] : [UIColor colorWithRed:0.76 green:0.17 blue:0.15 alpha:1.0]);
}

@end
