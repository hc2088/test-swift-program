#import "ADCardRenderer.h"
#import "ADFeedItem.h"

@implementation ADCardRenderer

+ (dispatch_queue_t)renderQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.huchu.async-display.delegate-render", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (UIImage *)imageForItem:(ADFeedItem *)item size:(CGSize)size scale:(CGFloat)scale cancelled:(BOOL (^)(void))cancelled {
    if (size.width < 1.0 || size.height < 1.0) {
        return nil;
    }

    if (cancelled && cancelled()) {
        return nil;
    }

    UIGraphicsBeginImageContextWithOptions(size, YES, scale);
    [self drawItem:item inRect:(CGRect){CGPointZero, size} cancelled:cancelled];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (cancelled && cancelled()) {
        return nil;
    }

    return image;
}

+ (void)drawItem:(ADFeedItem *)item inRect:(CGRect)rect cancelled:(BOOL (^)(void))cancelled {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    UIColor *pageColor = [UIColor colorWithRed:0.95 green:0.96 blue:0.98 alpha:1.0];
    CGContextSetFillColorWithColor(context, pageColor.CGColor);
    CGContextFillRect(context, rect);

    CGRect cardRect = CGRectInset(rect, 8.0, 8.0);
    UIBezierPath *cardPath = [UIBezierPath bezierPathWithRoundedRect:cardRect cornerRadius:18.0];
    CGContextSaveGState(context);
    [cardPath addClip];

    UIColor *baseColor = [UIColor colorWithHue:item.hue saturation:0.68 brightness:0.92 alpha:1.0];
    UIColor *accentColor = [UIColor colorWithHue:fmod(item.hue + 0.08, 1.0) saturation:0.72 brightness:0.68 alpha:1.0];
    NSArray *colors = @[(__bridge id)baseColor.CGColor, (__bridge id)accentColor.CGColor];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMinX(cardRect), CGRectGetMinY(cardRect)), CGPointMake(CGRectGetMaxX(cardRect), CGRectGetMaxY(cardRect)), 0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.88].CGColor);
    CGContextFillRect(context, CGRectMake(CGRectGetMinX(cardRect), CGRectGetMinY(cardRect) + 62.0, CGRectGetWidth(cardRect), CGRectGetHeight(cardRect) - 62.0));

    CGRect avatarRect = CGRectMake(CGRectGetMinX(cardRect) + 16.0, CGRectGetMinY(cardRect) + 14.0, 34.0, 34.0);
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.25].CGColor);
    CGContextFillEllipseInRect(context, avatarRect);

    NSDictionary *titleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: UIColor.whiteColor
    };
    [item.title drawWithRect:CGRectMake(CGRectGetMinX(cardRect) + 62.0, CGRectGetMinY(cardRect) + 14.0, CGRectGetWidth(cardRect) - 78.0, 24.0)
                    options:NSStringDrawingTruncatesLastVisibleLine
                 attributes:titleAttributes
                    context:nil];

    NSDictionary *badgeAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.92]
    };
    [item.badge drawWithRect:CGRectMake(CGRectGetMinX(cardRect) + 62.0, CGRectGetMinY(cardRect) + 38.0, CGRectGetWidth(cardRect) - 78.0, 16.0)
                    options:NSStringDrawingTruncatesLastVisibleLine
                 attributes:badgeAttributes
                    context:nil];

    if (cancelled && cancelled()) {
        CGContextRestoreGState(context);
        return;
    }

    CGRect chartRect = CGRectMake(CGRectGetMinX(cardRect) + 16.0, CGRectGetMinY(cardRect) + 74.0, CGRectGetWidth(cardRect) - 32.0, 54.0);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0].CGColor);
    UIBezierPath *chartPath = [UIBezierPath bezierPathWithRoundedRect:chartRect cornerRadius:12.0];
    [chartPath fill];

    CGFloat barWidth = 4.0;
    CGFloat barGap = 4.2;
    [item.bars enumerateObjectsUsingBlock:^(NSNumber *barValue, NSUInteger idx, BOOL *stop) {
        if (cancelled && cancelled()) {
            *stop = YES;
            return;
        }

        CGFloat normalized = barValue.doubleValue;
        CGFloat barHeight = normalized * (CGRectGetHeight(chartRect) - 14.0);
        CGFloat x = CGRectGetMinX(chartRect) + 10.0 + idx * (barWidth + barGap);
        CGFloat y = CGRectGetMaxY(chartRect) - 8.0 - barHeight;
        CGRect barRect = CGRectMake(x, y, barWidth, barHeight);
        UIColor *barColor = [UIColor colorWithHue:fmod(item.hue + idx * 0.01, 1.0) saturation:0.72 brightness:0.86 alpha:1.0];
        UIBezierPath *barPath = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:2.0];
        [barColor setFill];
        [barPath fill];
    }];

    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHue:fmod(item.hue + 0.15, 1.0) saturation:0.65 brightness:0.55 alpha:0.4].CGColor);
    CGContextSetLineWidth(context, 1.0);
    for (NSInteger dotIndex = 0; dotIndex < 26; dotIndex++) {
        if (cancelled && cancelled()) {
            CGContextRestoreGState(context);
            return;
        }

        CGFloat phase = (CGFloat)dotIndex / 25.0;
        CGFloat x = CGRectGetMinX(chartRect) + 10.0 + phase * (CGRectGetWidth(chartRect) - 20.0);
        CGFloat y = CGRectGetMidY(chartRect) + sin((phase * 8.0 + item.version) * M_PI) * 14.0;
        CGRect dotRect = CGRectMake(x - 2.0, y - 2.0, 4.0, 4.0);
        CGContextStrokeEllipseInRect(context, dotRect);
    }

    NSDictionary *subtitleAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.22 green:0.27 blue:0.34 alpha:1.0]
    };
    [item.subtitle drawWithRect:CGRectMake(CGRectGetMinX(cardRect) + 16.0, CGRectGetMinY(cardRect) + 138.0, CGRectGetWidth(cardRect) - 32.0, 42.0)
                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                    attributes:subtitleAttributes
                       context:nil];

    NSArray<NSString *> *chips = @[@"CALayer delegate", @"displayLayer:", @"background bitmap", @"main-thread contents"];
    CGFloat chipX = CGRectGetMinX(cardRect) + 16.0;
    CGFloat chipY = CGRectGetMaxY(cardRect) - 34.0;
    for (NSString *chip in chips) {
        if (cancelled && cancelled()) {
            CGContextRestoreGState(context);
            return;
        }

        CGSize chipSize = [chip sizeWithAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold]}];
        CGRect chipRect = CGRectMake(chipX, chipY, chipSize.width + 16.0, 22.0);
        chipX += chipSize.width + 24.0;
        if (CGRectGetMaxX(chipRect) > CGRectGetMaxX(cardRect) - 12.0) {
            break;
        }

        UIBezierPath *chipPath = [UIBezierPath bezierPathWithRoundedRect:chipRect cornerRadius:11.0];
        [[UIColor colorWithHue:item.hue saturation:0.18 brightness:0.96 alpha:1.0] setFill];
        [chipPath fill];
        [chip drawWithRect:CGRectInset(chipRect, 8.0, 4.0)
                   options:NSStringDrawingTruncatesLastVisibleLine
                attributes:@{
                    NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold],
                    NSForegroundColorAttributeName: [UIColor colorWithHue:item.hue saturation:0.55 brightness:0.54 alpha:1.0]
                }
                   context:nil];
    }

    CGContextRestoreGState(context);
}

@end
