#import "ADUIKitCardView.h"
#import "ADFeedItem.h"
#import <QuartzCore/QuartzCore.h>

@interface ADUIKitCardView ()
@property (nonatomic, strong) UIView *cardContainerView;
@property (nonatomic, strong) UIView *heroView;
@property (nonatomic, strong) CAGradientLayer *heroGradientLayer;
@property (nonatomic, strong) UIView *avatarView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, strong) UIView *chartContainerView;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, copy) NSArray<UIView *> *barViews;
@property (nonatomic, copy) NSArray<UIView *> *dotViews;
@property (nonatomic, copy) NSArray<UIView *> *chipViews;
@property (nonatomic, copy) NSArray<UILabel *> *chipLabels;
@end

@implementation ADUIKitCardView

+ (NSArray<NSString *> *)chipTexts {
    return @[@"CALayer delegate", @"displayLayer:", @"background bitmap", @"main-thread contents"];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.opaque = NO;

        _cardContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _cardContainerView.backgroundColor = UIColor.whiteColor;
        _cardContainerView.layer.cornerRadius = 18.0;
        _cardContainerView.layer.masksToBounds = YES;
        [self addSubview:_cardContainerView];

        _heroView = [[UIView alloc] initWithFrame:CGRectZero];
        [_cardContainerView addSubview:_heroView];

        _heroGradientLayer = [CAGradientLayer layer];
        _heroGradientLayer.startPoint = CGPointMake(0.0, 0.0);
        _heroGradientLayer.endPoint = CGPointMake(1.0, 1.0);
        [_heroView.layer addSublayer:_heroGradientLayer];

        _avatarView = [[UIView alloc] initWithFrame:CGRectZero];
        _avatarView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.25];
        [_cardContainerView addSubview:_avatarView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.numberOfLines = 1;
        [_cardContainerView addSubview:_titleLabel];

        _badgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _badgeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium];
        _badgeLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.92];
        _badgeLabel.numberOfLines = 1;
        [_cardContainerView addSubview:_badgeLabel];

        _chartContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _chartContainerView.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];
        _chartContainerView.layer.cornerRadius = 12.0;
        _chartContainerView.layer.masksToBounds = YES;
        [_cardContainerView addSubview:_chartContainerView];

        _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subtitleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        _subtitleLabel.textColor = [UIColor colorWithRed:0.22 green:0.27 blue:0.34 alpha:1.0];
        _subtitleLabel.numberOfLines = 2;
        _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_cardContainerView addSubview:_subtitleLabel];

        NSMutableArray<UIView *> *barViews = [NSMutableArray array];
        for (NSInteger index = 0; index < 24; index++) {
            UIView *barView = [[UIView alloc] initWithFrame:CGRectZero];
            barView.layer.cornerRadius = 2.0;
            [_chartContainerView addSubview:barView];
            [barViews addObject:barView];
        }
        _barViews = barViews;

        NSMutableArray<UIView *> *dotViews = [NSMutableArray array];
        for (NSInteger index = 0; index < 26; index++) {
            UIView *dotView = [[UIView alloc] initWithFrame:CGRectZero];
            dotView.layer.cornerRadius = 2.0;
            dotView.layer.borderWidth = 1.0;
            dotView.backgroundColor = UIColor.clearColor;
            [_chartContainerView addSubview:dotView];
            [dotViews addObject:dotView];
        }
        _dotViews = dotViews;

        NSMutableArray<UIView *> *chipViews = [NSMutableArray array];
        NSMutableArray<UILabel *> *chipLabels = [NSMutableArray array];
        for (NSString *chipText in [ADUIKitCardView chipTexts]) {
            UIView *chipView = [[UIView alloc] initWithFrame:CGRectZero];
            chipView.layer.cornerRadius = 11.0;
            chipView.layer.masksToBounds = YES;
            [_cardContainerView addSubview:chipView];
            [chipViews addObject:chipView];

            UILabel *chipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            chipLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold];
            chipLabel.text = chipText;
            [chipView addSubview:chipLabel];
            [chipLabels addObject:chipLabel];
        }
        _chipViews = chipViews;
        _chipLabels = chipLabels;
    }
    return self;
}

- (void)setItem:(ADFeedItem *)item {
    _item = item;
    self.titleLabel.text = item.title ?: @"";
    self.badgeLabel.text = item.badge ?: @"";
    self.subtitleLabel.text = item.subtitle ?: @"";
    [self updateColors];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect cardRect = CGRectInset(self.bounds, 8.0, 8.0);
    self.cardContainerView.frame = cardRect;

    CGFloat cardWidth = CGRectGetWidth(cardRect);
    CGFloat cardHeight = CGRectGetHeight(cardRect);
    self.heroView.frame = CGRectMake(0.0, 0.0, cardWidth, 62.0);
    self.heroGradientLayer.frame = self.heroView.bounds;

    self.avatarView.frame = CGRectMake(16.0, 14.0, 34.0, 34.0);
    self.avatarView.layer.cornerRadius = 17.0;
    self.titleLabel.frame = CGRectMake(62.0, 14.0, MAX(cardWidth - 78.0, 0.0), 24.0);
    self.badgeLabel.frame = CGRectMake(62.0, 38.0, MAX(cardWidth - 78.0, 0.0), 16.0);

    self.chartContainerView.frame = CGRectMake(16.0, 74.0, MAX(cardWidth - 32.0, 0.0), 54.0);
    [self layoutChartViews];

    self.subtitleLabel.frame = CGRectMake(16.0, 138.0, MAX(cardWidth - 32.0, 0.0), 42.0);
    [self layoutChipViewsWithCardHeight:cardHeight];
}

- (void)layoutChartViews {
    CGRect chartBounds = self.chartContainerView.bounds;
    CGFloat barWidth = 4.0;
    CGFloat barGap = 4.2;
    CGFloat availableHeight = CGRectGetHeight(chartBounds) - 14.0;
    BOOL hasItem = self.item != nil;

    [self.barViews enumerateObjectsUsingBlock:^(UIView *barView, NSUInteger idx, BOOL *stop) {
        NSNumber *barValue = idx < self.item.bars.count ? self.item.bars[idx] : nil;
        if (!barValue) {
            barView.hidden = YES;
            return;
        }

        barView.hidden = NO;
        CGFloat normalized = barValue.doubleValue;
        CGFloat barHeight = normalized * availableHeight;
        CGFloat x = 10.0 + idx * (barWidth + barGap);
        CGFloat y = CGRectGetHeight(chartBounds) - 8.0 - barHeight;
        barView.frame = CGRectMake(x, y, barWidth, barHeight);
    }];

    CGFloat dotHue = fmod(self.item.hue + 0.15, 1.0);
    UIColor *dotColor = [UIColor colorWithHue:dotHue saturation:0.65 brightness:0.55 alpha:0.4];
    [self.dotViews enumerateObjectsUsingBlock:^(UIView *dotView, NSUInteger idx, BOOL *stop) {
        dotView.hidden = !hasItem;
        if (!hasItem) {
            return;
        }

        CGFloat phase = (CGFloat)idx / 25.0;
        CGFloat x = 10.0 + phase * (CGRectGetWidth(chartBounds) - 20.0);
        CGFloat y = CGRectGetMidY(chartBounds) + sin((phase * 8.0 + self.item.version) * M_PI) * 14.0;
        dotView.frame = CGRectMake(x - 2.0, y - 2.0, 4.0, 4.0);
        dotView.layer.borderColor = dotColor.CGColor;
    }];
}

- (void)layoutChipViewsWithCardHeight:(CGFloat)cardHeight {
    __block CGFloat chipX = 16.0;
    CGFloat chipY = cardHeight - 34.0;
    CGFloat cardMaxX = CGRectGetWidth(self.cardContainerView.bounds) - 12.0;

    [self.chipViews enumerateObjectsUsingBlock:^(UIView *chipView, NSUInteger idx, BOOL *stop) {
        UILabel *chipLabel = self.chipLabels[idx];
        CGSize labelSize = [chipLabel.text sizeWithAttributes:@{NSFontAttributeName : chipLabel.font}];
        CGRect chipFrame = CGRectMake(chipX, chipY, labelSize.width + 16.0, 22.0);
        chipX += labelSize.width + 24.0;

        BOOL shouldHide = self.item == nil || CGRectGetMaxX(chipFrame) > cardMaxX;
        chipView.hidden = shouldHide;
        if (shouldHide) {
            return;
        }

        chipView.frame = chipFrame;
        chipLabel.frame = CGRectMake(8.0, 4.0, labelSize.width, 14.0);
    }];
}

- (void)updateColors {
    UIColor *baseColor = [UIColor colorWithHue:self.item.hue saturation:0.68 brightness:0.92 alpha:1.0];
    UIColor *accentColor = [UIColor colorWithHue:fmod(self.item.hue + 0.08, 1.0) saturation:0.72 brightness:0.68 alpha:1.0];
    self.heroGradientLayer.colors = @[(__bridge id)baseColor.CGColor, (__bridge id)accentColor.CGColor];

    [self.barViews enumerateObjectsUsingBlock:^(UIView *barView, NSUInteger idx, BOOL *stop) {
        UIColor *barColor = [UIColor colorWithHue:fmod(self.item.hue + idx * 0.01, 1.0) saturation:0.72 brightness:0.86 alpha:1.0];
        barView.backgroundColor = barColor;
    }];

    UIColor *chipFillColor = [UIColor colorWithHue:self.item.hue saturation:0.18 brightness:0.96 alpha:1.0];
    UIColor *chipTextColor = [UIColor colorWithHue:self.item.hue saturation:0.55 brightness:0.54 alpha:1.0];
    [self.chipViews enumerateObjectsUsingBlock:^(UIView *chipView, NSUInteger idx, BOOL *stop) {
        chipView.backgroundColor = chipFillColor;
        self.chipLabels[idx].textColor = chipTextColor;
    }];
}

- (void)resetForReuse {
    self.item = nil;
}

@end
