#import "ADSizingCardView.h"

@interface ADSizingBaseCardView ()
+ (void)drawContent:(ADSizingCardContent *)content inRect:(CGRect)rect;
@end

static CGFloat const kADCardHorizontalPadding = 18.0;
static CGFloat const kADCardVerticalPadding = 18.0;
static CGFloat const kADCardTitleBodySpacing = 10.0;
static CGFloat const kADCardImageSpacing = 12.0;
static CGFloat const kADCardFooterHeight = 24.0;
static CGFloat const kADCardMinWidth = 120.0;

@implementation ADSizingCardContent

+ (NSArray<ADSizingCardContent *> *)demoContents {
    NSArray<NSString *> *bodies = @[
        @"普通 View 场景：外部约束先决定宽度，自定义 view 根据这个宽度计算 intrinsicContentSize 的高度。drawRect 只负责在最终 bounds 里画。",
        @"UIScrollView 场景：没有自动内容高度，通常由你调用 sizeThatFits 计算子 view frame，再手动设置 scrollView.contentSize。",
        @"UITableViewCell 场景：cell 的宽度来自 tableView，内容高度来自自绘 view 的文本测量。这里用 Auto Layout 自适应 cell 高度。"
    ];
    NSArray<NSString *> *titles = @[
        @"Auto Layout: intrinsic height",
        @"Frame Layout: sizeThatFits",
        @"Table Cell: self sizing"
    ];
    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.10 green:0.44 blue:0.92 alpha:1.0],
        [UIColor colorWithRed:0.10 green:0.58 blue:0.42 alpha:1.0],
        [UIColor colorWithRed:0.73 green:0.25 blue:0.36 alpha:1.0]
    ];

    NSMutableArray<ADSizingCardContent *> *items = [NSMutableArray arrayWithCapacity:bodies.count];
    for (NSUInteger index = 0; index < bodies.count; index++) {
        ADSizingCardContent *content = [[ADSizingCardContent alloc] init];
        content.title = titles[index];
        content.body = bodies[index];
        content.imageCaption = index == 1 ? @"manual frame + contentSize" : @"text + image measured together";
        content.tintColor = colors[index];
        content.showsImage = index != 2;
        [items addObject:content];
    }
    return items;
}

@end

@implementation ADSizingBaseCardView {
    CGFloat _lastKnownWidth;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;
        self.contentMode = UIViewContentModeRedraw;
        self.layer.contentsScale = UIScreen.mainScreen.scale;
    }
    return self;
}

- (void)setContent:(ADSizingCardContent *)content {
    _content = content;

    // 内容变了，文字测量结果可能变，view 对 Auto Layout 声明的 intrinsicContentSize 也可能变。
    // 这里只是标记“固有尺寸失效”，真正重新计算会发生在下一次布局求解阶段。
    [self invalidateIntrinsicContentSize];

    // 内容变了，原来的 backing store 已经过期。setNeedsDisplay 只标记需要重绘，
    // 系统会在后续绘制阶段回调 drawRect: 或 displayLayer:。
    [self setNeedsDisplay];
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    if (fabs(_preferredMaxLayoutWidth - preferredMaxLayoutWidth) < 0.5) {
        return;
    }

    _preferredMaxLayoutWidth = preferredMaxLayoutWidth;

    // 自绘文本的高度依赖“可换行宽度”。宽度变了，高度也要重新向 Auto Layout 报告。
    [self invalidateIntrinsicContentSize];

    // 画布宽度变了，已有绘制内容也不再匹配新的 bounds，需要重绘。
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // layoutSubviews 执行时，Auto Layout 或手动 frame 布局已经给当前 view 设置好了 bounds。
    // 这里读取到的 self.bounds.size 是布局结果，不是在这个方法里计算出来的。
    CGFloat width = CGRectGetWidth(self.bounds);
    if (width > 0.0 && fabs(_lastKnownWidth - width) >= 0.5) {
        _lastKnownWidth = width;
        if (self.preferredMaxLayoutWidth <= 0.0 || fabs(self.preferredMaxLayoutWidth - width) >= 0.5) {
            _preferredMaxLayoutWidth = width;

            // 如果外部没有提前提供 preferredMaxLayoutWidth，就用最终 bounds.width 作为文本测量宽度。
            // 这会让下一次 Auto Layout 查询 intrinsicContentSize 时得到正确高度。
            [self invalidateIntrinsicContentSize];
        }

        // bounds 变了，绘制使用的画布尺寸也变了，同步/异步绘制都需要重新生成内容。
        [self setNeedsDisplay];
    }
}

- (CGSize)intrinsicContentSize {
    // Auto Layout 在缺少明确高度约束时，会询问 view 的 intrinsicContentSize。
    // 这个 demo 中：宽度由父视图/约束决定，所以宽度返回 UIViewNoIntrinsicMetric；
    // 高度由文本、图片和 padding 按“当前可用宽度”计算出来。
    if (!self.content) {
        return CGSizeMake(UIViewNoIntrinsicMetric, 0.0);
    }

    CGFloat width = self.preferredMaxLayoutWidth;
    if (width <= 0.0) {
        width = CGRectGetWidth(self.bounds);
    }
    if (width <= 0.0) {
        return CGSizeMake(UIViewNoIntrinsicMetric, 1.0);
    }

    return CGSizeMake(UIViewNoIntrinsicMetric, [self.class heightForContent:self.content width:width]);
}

- (CGSize)sizeThatFits:(CGSize)size {
    // sizeThatFits 用在手动 frame 布局场景：外部给一个可用宽度，
    // view 返回“在这个宽度下我希望的尺寸”。它不会自动修改 frame。
    CGFloat width = size.width > 0.0 ? size.width : self.preferredMaxLayoutWidth;
    if (width <= 0.0) {
        width = kADCardMinWidth;
    }

    if (!self.content) {
        return CGSizeMake(width, 0.0);
    }

    return [self.class sizeForContent:self.content fittingWidth:width];
}

+ (CGSize)sizeForContent:(ADSizingCardContent *)content fittingWidth:(CGFloat)width {
    width = MAX(ceil(width), kADCardMinWidth);
    return CGSizeMake(width, [self heightForContent:content width:width]);
}

+ (CGFloat)heightForContent:(ADSizingCardContent *)content width:(CGFloat)width {
    width = MAX(width, kADCardMinWidth);
    CGFloat textWidth = MAX(1.0, width - kADCardHorizontalPadding * 2.0);
    CGFloat titleHeight = ceil([content.title boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:[self titleAttributes]
                                                           context:nil].size.height);
    CGFloat bodyHeight = ceil([content.body boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:[self bodyAttributes]
                                                         context:nil].size.height);
    CGFloat imageHeight = content.showsImage ? MIN(148.0, MAX(92.0, width * 0.34)) : 0.0;
    CGFloat imageBlockHeight = content.showsImage ? kADCardImageSpacing + imageHeight : 0.0;

    return ceil(kADCardVerticalPadding
                + titleHeight
                + kADCardTitleBodySpacing
                + bodyHeight
                + imageBlockHeight
                + 14.0
                + kADCardFooterHeight
                + kADCardVerticalPadding);
}

+ (NSDictionary<NSAttributedStringKey, id> *)titleAttributes {
    return @{
        NSFontAttributeName: [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.10 green:0.15 blue:0.24 alpha:1.0]
    };
}

+ (NSDictionary<NSAttributedStringKey, id> *)bodyAttributes {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 3.0;
    return @{
        NSFontAttributeName: [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.30 green:0.35 blue:0.44 alpha:1.0],
        NSParagraphStyleAttributeName: style
    };
}

- (void)drawCardInRect:(CGRect)rect {
    ADSizingCardContent *content = self.content;
    [self.class drawContent:content inRect:rect];
}

+ (void)drawContent:(ADSizingCardContent *)content inRect:(CGRect)rect {
    if (!content || CGRectGetWidth(rect) < 1.0 || CGRectGetHeight(rect) < 1.0) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    CGRect cardRect = CGRectInset(rect, 1.0, 1.0);
    UIBezierPath *cardPath = [UIBezierPath bezierPathWithRoundedRect:cardRect cornerRadius:12.0];
    CGContextSetShadowWithColor(context, CGSizeMake(0.0, 3.0), 10.0, [UIColor colorWithWhite:0.0 alpha:0.10].CGColor);
    [[UIColor whiteColor] setFill];
    [cardPath fill];
    CGContextSetShadowWithColor(context, CGSizeZero, 0.0, NULL);

    CGRect accentRect = CGRectMake(CGRectGetMinX(cardRect), CGRectGetMinY(cardRect), 5.0, CGRectGetHeight(cardRect));
    UIBezierPath *accentPath = [UIBezierPath bezierPathWithRoundedRect:accentRect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft cornerRadii:CGSizeMake(12.0, 12.0)];
    [content.tintColor setFill];
    [accentPath fill];

    CGFloat x = CGRectGetMinX(cardRect) + kADCardHorizontalPadding;
    CGFloat y = CGRectGetMinY(cardRect) + kADCardVerticalPadding;
    CGFloat textWidth = CGRectGetWidth(cardRect) - kADCardHorizontalPadding * 2.0;

    CGSize titleSize = [content.title boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:[self titleAttributes]
                                                   context:nil].size;
    [content.title drawWithRect:CGRectMake(x, y, textWidth, ceil(titleSize.height))
                       options:NSStringDrawingUsesLineFragmentOrigin
                    attributes:[self titleAttributes]
                       context:nil];
    y += ceil(titleSize.height) + kADCardTitleBodySpacing;

    CGSize bodySize = [content.body boundingRectWithSize:CGSizeMake(textWidth, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:[self bodyAttributes]
                                                 context:nil].size;
    [content.body drawWithRect:CGRectMake(x, y, textWidth, ceil(bodySize.height))
                       options:NSStringDrawingUsesLineFragmentOrigin
                    attributes:[self bodyAttributes]
                       context:nil];
    y += ceil(bodySize.height);

    if (content.showsImage) {
        y += kADCardImageSpacing;
        CGFloat imageHeight = MIN(148.0, MAX(92.0, CGRectGetWidth(cardRect) * 0.34));
        CGRect imageRect = CGRectMake(x, y, textWidth, imageHeight);
        UIBezierPath *imagePath = [UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:10.0];
        [[content.tintColor colorWithAlphaComponent:0.12] setFill];
        [imagePath fill];

        CGContextSaveGState(context);
        [imagePath addClip];
        for (NSInteger index = 0; index < 9; index++) {
            CGFloat stripeX = CGRectGetMinX(imageRect) + index * CGRectGetWidth(imageRect) / 8.0;
            UIColor *stripeColor = [content.tintColor colorWithAlphaComponent:0.08 + index * 0.015];
            [stripeColor setFill];
            CGContextFillRect(context, CGRectMake(stripeX, CGRectGetMinY(imageRect), CGRectGetWidth(imageRect) / 5.0, CGRectGetHeight(imageRect)));
        }
        CGContextRestoreGState(context);

        NSDictionary *captionAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: [content.tintColor colorWithAlphaComponent:0.9]
        };
        [content.imageCaption drawWithRect:CGRectInset(imageRect, 12.0, 10.0)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:captionAttributes
                                   context:nil];
        y += imageHeight;
    }

    y += 14.0;
    CGRect footerRect = CGRectMake(x, y, textWidth, kADCardFooterHeight);
    UIBezierPath *footerPath = [UIBezierPath bezierPathWithRoundedRect:footerRect cornerRadius:12.0];
    [[content.tintColor colorWithAlphaComponent:0.10] setFill];
    [footerPath fill];

    NSString *footer = [NSString stringWithFormat:@"bounds: %.0f x %.0f, height comes before drawing", CGRectGetWidth(rect), CGRectGetHeight(rect)];
    [footer drawWithRect:CGRectInset(footerRect, 10.0, 4.0)
                 options:NSStringDrawingTruncatesLastVisibleLine
              attributes:@{
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightMedium],
        NSForegroundColorAttributeName: [content.tintColor colorWithAlphaComponent:0.9]
    }
                 context:nil];
}

@end

@implementation ADSizingSyncCardView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    // 同步绘制路径：系统已经决定好 bounds，并准备好当前 CGContext/backing store。
    // drawRect: 只负责在 self.bounds 这张画布里画，不能在这里决定 view 的大小。
    [self drawCardInRect:self.bounds];
}

@end

@implementation ADSizingAsyncCardView {
    NSInteger _sentinel;
    CGSize _lastRenderedSize;
}

- (void)setContent:(ADSizingCardContent *)content {
    [super setContent:content];
    [self resetAsyncDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // 异步绘制同样依赖布局结果。bounds.size 变了，后台生成的 bitmap 尺寸也必须跟着变。
    if (!CGSizeEqualToSize(_lastRenderedSize, self.bounds.size)) {
        _lastRenderedSize = self.bounds.size;
        [self resetAsyncDisplay];
    }
}

- (void)displayLayer:(CALayer *)layer {
    // 异步 displayLayer: 路径：Core Animation 要求 layer 显示内容时回调到这里。
    // 此时 layer.bounds.size 已经由布局阶段确定，我们用这个 size 在后台创建 bitmap。
    ADSizingCardContent *content = self.content;
    CGSize size = layer.bounds.size;
    if (!content || size.width < 1.0 || size.height < 1.0) {
        layer.contents = nil;
        return;
    }

    NSInteger token = _sentinel;
    CGFloat scale = UIScreen.mainScreen.scale;

    dispatch_async([self.class renderQueue], ^{
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
        [ADSizingBaseCardView drawContent:content inRect:(CGRect){CGPointZero, size}];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        dispatch_async(dispatch_get_main_queue(), ^{
            if (token != self->_sentinel) {
                return;
            }
            layer.contentsScale = scale;
            layer.contents = (__bridge id)image.CGImage;
        });
    });
}

- (void)resetAsyncDisplay {
    _sentinel += 1;
    self.layer.contents = nil;

    // layer 的内容失效后，标记需要 display。后续系统会回调 displayLayer:，
    // 我们再把真正耗时的 bitmap 绘制派发到后台队列。
    [self.layer setNeedsDisplay];
}

+ (dispatch_queue_t)renderQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.huchu.layout-sizing.async-render", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

@end
