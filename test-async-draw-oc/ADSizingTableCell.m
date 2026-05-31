#import "ADSizingTableCell.h"
#import "ADSizingCardView.h"

@interface ADSizingTableCell ()
@property (nonatomic, strong) ADSizingSyncCardView *cardView;
@end

@implementation ADSizingTableCell

+ (NSString *)reuseIdentifier {
    return @"ADSizingTableCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor colorWithRed:0.94 green:0.96 blue:0.98 alpha:1.0];
        self.contentView.backgroundColor = self.backgroundColor;

        _cardView = [[ADSizingSyncCardView alloc] initWithFrame:CGRectZero];
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0]
        ]];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    // tableView 已经给 cell/contentView 算好了宽度，cell 内部再把可用宽度传给自绘 view。
    // 自绘 view 的文本高度依赖这个宽度，所以这里更新 preferredMaxLayoutWidth。
    CGFloat fittingWidth = CGRectGetWidth(self.contentView.bounds) - 32.0;
    if (fittingWidth > 0.0) {
        self.cardView.preferredMaxLayoutWidth = fittingWidth;
    }
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
        withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority
              verticalFittingPriority:(UILayoutPriority)verticalFittingPriority {
    // UITableViewAutomaticDimension 会让 tableView 询问 cell：
    // “在 targetSize.width 这个宽度下，你通过 Auto Layout 需要多高？”
    // 所以必须先把宽度同步给自绘 view，再交给 super 让约束系统计算最终 cell 高度。
    CGFloat fittingWidth = targetSize.width > 0.0 ? targetSize.width - 32.0 : CGRectGetWidth(UIScreen.mainScreen.bounds) - 32.0;
    self.cardView.preferredMaxLayoutWidth = MAX(120.0, fittingWidth);
    return [super systemLayoutSizeFittingSize:targetSize
                withHorizontalFittingPriority:horizontalFittingPriority
                      verticalFittingPriority:verticalFittingPriority];
}

- (void)configureWithContent:(ADSizingCardContent *)content {
    self.cardView.content = content;
}

@end
