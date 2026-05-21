//
//  YYAsyncLayer.m
//  Extracted and trimmed from YYKit for standalone demo usage.
//

#import "YYAsyncLayer.h"
#import "YYSentinel.h"
#import <stdatomic.h>

static dispatch_queue_t YYAsyncLayerGetDisplayQueue(void) {
#define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static atomic_int_least32_t counter;
    dispatch_once(&onceToken, ^{
        atomic_init(&counter, 0);
        queueCount = (int)NSProcessInfo.processInfo.activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        for (NSUInteger idx = 0; idx < (NSUInteger)queueCount; idx++) {
            dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
            queues[idx] = dispatch_queue_create("com.huchu.demo.yyasync.render", attr);
        }
    });
    uint32_t current = (uint32_t)(atomic_fetch_add_explicit(&counter, 1, memory_order_relaxed) + 1);
    return queues[current % queueCount];
#undef MAX_QUEUE_COUNT
}

static dispatch_queue_t YYAsyncLayerGetReleaseQueue(void) {
    return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0);
}

@implementation YYAsyncLayerDisplayTask
@end

@implementation YYAsyncLayer {
    YYSentinel *_sentinel;
}

+ (id)defaultValueForKey:(NSString *)key {
    if ([key isEqualToString:@"displaysAsynchronously"]) {
        return @(YES);
    }
    return [super defaultValueForKey:key];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.contentsScale = UIScreen.mainScreen.scale;
        _sentinel = [YYSentinel new];
        _displaysAsynchronously = YES;
    }
    return self;
}

- (void)dealloc {
    [_sentinel increase];
}

- (void)setNeedsDisplay {
    [self cancelAsyncDisplay];
    [super setNeedsDisplay];
}

- (void)display {
    super.contents = super.contents;
    [self displayAsync:self.displaysAsynchronously];
}

- (void)displayAsync:(BOOL)async {
    id<YYAsyncLayerDelegate> delegate = (id)self.delegate;
    YYAsyncLayerDisplayTask *task = [delegate newAsyncDisplayTask];
    if (!task.display) {
        if (task.willDisplay) {
            task.willDisplay(self);
        }
        self.contents = nil;
        if (task.didDisplay) {
            task.didDisplay(self, YES);
        }
        return;
    }

    if (!async) {
        [_sentinel increase];
        if (task.willDisplay) {
            task.willDisplay(self);
        }
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        task.display(context, self.bounds.size, ^BOOL{
            return NO;
        });
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contents = (__bridge id)image.CGImage;
        if (task.didDisplay) {
            task.didDisplay(self, YES);
        }
        return;
    }

    if (task.willDisplay) {
        task.willDisplay(self);
    }

    YYSentinel *sentinel = _sentinel;
    int32_t value = sentinel.value;
    BOOL (^isCancelled)(void) = ^BOOL{
        return value != sentinel.value;
    };

    CGSize size = self.bounds.size;
    BOOL opaque = self.opaque;
    CGFloat scale = self.contentsScale;
    CGColorRef backgroundColor = (opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;

    if (size.width < 1.0 || size.height < 1.0) {
        CGImageRef currentImage = (__bridge_retained CGImageRef)self.contents;
        self.contents = nil;
        if (currentImage) {
            dispatch_async(YYAsyncLayerGetReleaseQueue(), ^{
                CFRelease(currentImage);
            });
        }
        if (backgroundColor) {
            CGColorRelease(backgroundColor);
        }
        if (task.didDisplay) {
            task.didDisplay(self, YES);
        }
        return;
    }

    dispatch_async(YYAsyncLayerGetDisplayQueue(), ^{
        if (isCancelled()) {
            if (backgroundColor) {
                CGColorRelease(backgroundColor);
            }
            return;
        }

        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (opaque && context) {
            CGContextSaveGState(context);
            if (!backgroundColor || CGColorGetAlpha(backgroundColor) < 1.0) {
                CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
                CGContextFillRect(context, (CGRect){CGPointZero, size});
            }
            if (backgroundColor) {
                CGContextSetFillColorWithColor(context, backgroundColor);
                CGContextFillRect(context, (CGRect){CGPointZero, size});
            }
            CGContextRestoreGState(context);
        }
        if (backgroundColor) {
            CGColorRelease(backgroundColor);
        }

        task.display(context, size, isCancelled);
        if (isCancelled()) {
            UIGraphicsEndImageContext();
            dispatch_async(dispatch_get_main_queue(), ^{
                if (task.didDisplay) {
                    task.didDisplay(self, NO);
                }
            });
            return;
        }

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        if (isCancelled()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (task.didDisplay) {
                    task.didDisplay(self, NO);
                }
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (isCancelled()) {
                if (task.didDisplay) {
                    task.didDisplay(self, NO);
                }
                return;
            }
            self.contents = (__bridge id)image.CGImage;
            if (task.didDisplay) {
                task.didDisplay(self, YES);
            }
        });
    });
}

- (void)cancelAsyncDisplay {
    [_sentinel increase];
}

@end
