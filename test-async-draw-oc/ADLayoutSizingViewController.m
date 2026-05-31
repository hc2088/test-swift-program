#import "ADLayoutSizingViewController.h"
#import "ADNormalLayoutCardView.h"
#import "ADSizingCardView.h"
#import "ADSizingTableCell.h"

@interface ADLayoutSizingViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) ADNormalLayoutCardView *normalLayoutCardView;
@property (nonatomic, strong) ADSizingSyncCardView *autoLayoutCardView;
@property (nonatomic, strong) ADSizingAsyncCardView *asyncCardView;
@property (nonatomic, strong) UIScrollView *frameScrollView;
@property (nonatomic, strong) NSArray<ADSizingSyncCardView *> *frameCardViews;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSLayoutConstraint *tableHeightConstraint;
@property (nonatomic, copy) NSArray<ADSizingCardContent *> *contents;

@end

@implementation ADLayoutSizingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Layout vs Draw";
    self.view.backgroundColor = [UIColor colorWithRed:0.94 green:0.96 blue:0.98 alpha:1.0];
    self.contents = [ADSizingCardContent demoContents];

    [self buildViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateMeasuredWidths];
    [self layoutFrameScrollContent];
    [self updateTableHeight];
}

- (void)buildViews {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:self.scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:contentView];

    self.contentStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 18.0;
    [contentView addSubview:self.contentStack];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [contentView.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],

        [self.contentStack.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:18.0],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:16.0],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-16.0],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-24.0]
    ]];

    [self addIntroSection];
    [self addNormalUIKitSection];
    [self addAutoLayoutSection];
    [self addFrameScrollSection];
    [self addTableSection];
}

- (void)addIntroSection {
    UILabel *label = [self makeLabelWithText:@"布局先决定 size/bounds，绘制再拿这个 bounds 画。文本和图片导致高度变化时，高度应该在 sizeThatFits、intrinsicContentSize、Auto Layout fitting 或 tableView 高度计算阶段确定，而不是在 drawRect 里临时决定。"
                                        font:[UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold]
                                       color:[UIColor colorWithRed:0.12 green:0.17 blue:0.26 alpha:1.0]];
    [self.contentStack addArrangedSubview:label];
}

- (void)addNormalUIKitSection {
    [self.contentStack addArrangedSubview:[self makeSectionTitle:@"0. 普通 View：UIKit 子控件 + Auto Layout"]];
    [self.contentStack addArrangedSubview:[self makeBodyText:@"这个卡片不重写 drawRect/displayLayer。宽度变化时，Auto Layout 会重新 layout 子控件，UILabel 自己根据宽度换行；不需要 updateMeasuredWidths，也不需要 setNeedsDisplay。"]];

    self.normalLayoutCardView = [[ADNormalLayoutCardView alloc] initWithFrame:CGRectZero];
    self.normalLayoutCardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.normalLayoutCardView.content = self.contents.firstObject;
    [self.contentStack addArrangedSubview:self.normalLayoutCardView];
}

- (void)addAutoLayoutSection {
    [self.contentStack addArrangedSubview:[self makeSectionTitle:@"1. 普通 View：Auto Layout + intrinsicContentSize"]];
    [self.contentStack addArrangedSubview:[self makeBodyText:@"外部只给 leading/trailing/top。自绘 view 根据已知宽度计算 intrinsic height；drawRect/displayLayer 只按照最终 bounds 绘制。"]];

    self.autoLayoutCardView = [[ADSizingSyncCardView alloc] initWithFrame:CGRectZero];
    self.autoLayoutCardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.autoLayoutCardView.content = self.contents.firstObject;
    [self.contentStack addArrangedSubview:self.autoLayoutCardView];

    self.asyncCardView = [[ADSizingAsyncCardView alloc] initWithFrame:CGRectZero];
    self.asyncCardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.asyncCardView.content = self.contents.firstObject;
    [self.contentStack addArrangedSubview:[self makeBodyText:@"同一套 size 计算也可以给异步 displayLayer 使用。异步只是改变绘制发生在哪个线程，不改变布局阶段该算出的大小。"]];
    [self.contentStack addArrangedSubview:self.asyncCardView];
}

- (void)addFrameScrollSection {
    [self.contentStack addArrangedSubview:[self makeSectionTitle:@"2. UIScrollView：frame layout + contentSize"]];
    [self.contentStack addArrangedSubview:[self makeBodyText:@"ScrollView 不会自动知道内容高度。这里用 sizeThatFits 算每张卡片 frame，再把最后一张的 maxY 写回 contentSize。"]];

    self.frameScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.frameScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.frameScrollView.backgroundColor = [UIColor colorWithRed:0.89 green:0.92 blue:0.96 alpha:1.0];
    self.frameScrollView.layer.cornerRadius = 10.0;
    self.frameScrollView.alwaysBounceVertical = YES;
    [self.contentStack addArrangedSubview:self.frameScrollView];
    [self.frameScrollView.heightAnchor constraintEqualToConstant:270.0].active = YES;

    NSMutableArray<ADSizingSyncCardView *> *views = [NSMutableArray arrayWithCapacity:self.contents.count];
    for (ADSizingCardContent *content in self.contents) {
        ADSizingSyncCardView *cardView = [[ADSizingSyncCardView alloc] initWithFrame:CGRectZero];
        cardView.content = content;
        [self.frameScrollView addSubview:cardView];
        [views addObject:cardView];
    }
    self.frameCardViews = views;
}

- (void)addTableSection {
    [self.contentStack addArrangedSubview:[self makeSectionTitle:@"3. UITableViewCell：cell 自适应高度"]];
    [self.contentStack addArrangedSubview:[self makeBodyText:@"TableView 先确定 cell 宽度，cell 内部约束把自绘 view 铺满 contentView。自绘 view 的 intrinsic height 参与 Auto Layout fitting，最终得到 row height。"]];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.scrollEnabled = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 180.0;
    [self.tableView registerClass:[ADSizingTableCell class] forCellReuseIdentifier:[ADSizingTableCell reuseIdentifier]];
    [self.contentStack addArrangedSubview:self.tableView];
    self.tableHeightConstraint = [self.tableView.heightAnchor constraintEqualToConstant:1.0];
    self.tableHeightConstraint.active = YES;
}

- (void)updateMeasuredWidths {
    // 普通 Auto Layout 场景：stackView 的宽度由父约束决定。
    // 自绘 view 再用这个宽度计算 intrinsic height，形成“父给宽度，子报高度”的关系。
    // 注意：普通 UIKit 子控件布局的 normalLayoutCardView 不需要走这里；
    // UILabel/UIImageView/UIView 会在 Auto Layout 中靠自身 intrinsic size 和约束完成布局，不需要手动 setNeedsDisplay。
    CGFloat width = CGRectGetWidth(self.contentStack.bounds);
    if (width <= 0.0) {
        return;
    }

    self.autoLayoutCardView.preferredMaxLayoutWidth = width;
    self.asyncCardView.preferredMaxLayoutWidth = width;
}

- (void)layoutFrameScrollContent {
    // 手动 frame 场景：scrollView 不会根据子 view 自动推出 contentSize。
    // 控制器先给每个自绘 view 一个宽度，再调用 sizeThatFits: 拿到高度，最后设置 frame/contentSize。
    CGFloat width = CGRectGetWidth(self.frameScrollView.bounds);
    if (width <= 0.0) {
        return;
    }

    CGFloat cardWidth = width - 24.0;
    CGFloat y = 12.0;
    for (ADSizingSyncCardView *cardView in self.frameCardViews) {
        CGSize size = [cardView sizeThatFits:CGSizeMake(cardWidth, CGFLOAT_MAX)];
        cardView.frame = CGRectMake(12.0, y, cardWidth, size.height);
        y = CGRectGetMaxY(cardView.frame) + 12.0;
    }

    self.frameScrollView.contentSize = CGSizeMake(width, y);
}

- (void)updateTableHeight {
    // 这里的 tableView 嵌在外层 scrollView 中并禁用了自身滚动。
    // 让 tableView 完成 self-sizing cell 布局后，把 contentSize.height 写回高度约束。
    [self.tableView layoutIfNeeded];
    CGFloat height = self.tableView.contentSize.height;
    if (height > 0.0 && fabs(self.tableHeightConstraint.constant - height) >= 0.5) {
        self.tableHeightConstraint.constant = height;
    }
}

- (UILabel *)makeSectionTitle:(NSString *)text {
    return [self makeLabelWithText:text
                              font:[UIFont systemFontOfSize:17.0 weight:UIFontWeightBold]
                             color:[UIColor colorWithRed:0.10 green:0.15 blue:0.24 alpha:1.0]];
}

- (UILabel *)makeBodyText:(NSString *)text {
    return [self makeLabelWithText:text
                              font:[UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular]
                             color:[UIColor colorWithRed:0.34 green:0.40 blue:0.48 alpha:1.0]];
}

- (UILabel *)makeLabelWithText:(NSString *)text font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = font;
    label.textColor = color;
    label.text = text;
    return label;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ADSizingTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[ADSizingTableCell reuseIdentifier] forIndexPath:indexPath];
    [cell configureWithContent:self.contents[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateTableHeight];
}

@end
