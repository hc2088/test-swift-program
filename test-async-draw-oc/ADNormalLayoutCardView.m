#import "ADNormalLayoutCardView.h"
#import "ADSizingCardView.h"

@interface ADNormalLayoutCardView ()
@property (nonatomic, strong) UIView *accentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIView *imageBoxView;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UILabel *footerLabel;
@end

@implementation ADNormalLayoutCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 12.0;
        self.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.10].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
        self.layer.shadowOpacity = 1.0;
        self.layer.shadowRadius = 10.0;

        _accentView = [[UIView alloc] init];
        _accentView.translatesAutoresizingMaskIntoConstraints = NO;
        _accentView.backgroundColor = [UIColor colorWithRed:0.36 green:0.31 blue:0.80 alpha:1.0];
        [self addSubview:_accentView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [UIColor colorWithRed:0.10 green:0.15 blue:0.24 alpha:1.0];

        _bodyLabel = [[UILabel alloc] init];
        _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        _bodyLabel.textColor = [UIColor colorWithRed:0.30 green:0.35 blue:0.44 alpha:1.0];

        _imageBoxView = [[UIView alloc] init];
        _imageBoxView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageBoxView.backgroundColor = [[UIColor colorWithRed:0.36 green:0.31 blue:0.80 alpha:1.0] colorWithAlphaComponent:0.12];
        _imageBoxView.layer.cornerRadius = 10.0;

        _captionLabel = [[UILabel alloc] init];
        _captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _captionLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        _captionLabel.textColor = [UIColor colorWithRed:0.36 green:0.31 blue:0.80 alpha:1.0];
        _captionLabel.text = @"UIKit subviews + constraints";
        [_imageBoxView addSubview:_captionLabel];

        _footerLabel = [[UILabel alloc] init];
        _footerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _footerLabel.numberOfLines = 1;
        _footerLabel.font = [UIFont monospacedSystemFontOfSize:11.0 weight:UIFontWeightMedium];
        _footerLabel.textColor = [UIColor colorWithRed:0.36 green:0.31 blue:0.80 alpha:1.0];
        _footerLabel.backgroundColor = [[UIColor colorWithRed:0.36 green:0.31 blue:0.80 alpha:1.0] colorWithAlphaComponent:0.10];
        _footerLabel.layer.cornerRadius = 12.0;
        _footerLabel.layer.masksToBounds = YES;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
            _titleLabel,
            _bodyLabel,
            _imageBoxView,
            _footerLabel
        ]];
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        stack.axis = UILayoutConstraintAxisVertical;
        stack.spacing = 10.0;
        stack.alignment = UIStackViewAlignmentFill;
        [self addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
            [_accentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_accentView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_accentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_accentView.widthAnchor constraintEqualToConstant:5.0],

            [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:18.0],
            [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-18.0],
            [stack.topAnchor constraintEqualToAnchor:self.topAnchor constant:18.0],
            [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-18.0],

            [_imageBoxView.heightAnchor constraintEqualToConstant:110.0],
            [_captionLabel.leadingAnchor constraintEqualToAnchor:_imageBoxView.leadingAnchor constant:12.0],
            [_captionLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_imageBoxView.trailingAnchor constant:-12.0],
            [_captionLabel.centerYAnchor constraintEqualToAnchor:_imageBoxView.centerYAnchor],

            [_footerLabel.heightAnchor constraintEqualToConstant:24.0]
        ]];
    }
    return self;
}

- (void)setContent:(ADSizingCardContent *)content {
    _content = content;
    self.titleLabel.text = @"Normal UIKit: labels decide height";
    self.bodyLabel.text = @"这个卡片没有重写 drawRect/displayLayer，也不需要 setNeedsDisplay。宽度变化时，Auto Layout 会重新计算 UILabel 的换行和整体高度。";
    self.captionLabel.text = content.imageCaption.length > 0 ? content.imageCaption : @"UIKit subviews + constraints";
    self.footerLabel.text = @"  no custom drawing, no manual bitmap";
}

@end
