#import "ADViewController.h"
#import "ADDemoCell.h"
#import "ADFPSLabel.h"
#import "ADFeedItem.h"

static NSString * const kSyncCellIdentifier = @"SyncCell";
static NSString * const kUIKitCellIdentifier = @"UIKitCell";
static NSString * const kAsyncCellIdentifier = @"AsyncCell";
static NSString * const kLayerClassCellIdentifier = @"LayerClassAsyncCell";

typedef NS_ENUM(NSInteger, ADRenderMode) {
    ADRenderModeSync = 0,
    ADRenderModeUIKit = 1,
    ADRenderModeDisplayLayer = 2,
    ADRenderModeLayerClass = 3,
};

@interface ADViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISegmentedControl *modeControl;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, strong) UIButton *burstButton;
@property (nonatomic, strong) ADFPSLabel *fpsLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *tableHeaderContainerView;
@property (nonatomic, strong) NSLayoutConstraint *tableHeaderWidthConstraint;
@property (nonatomic, copy) NSArray<ADFeedItem *> *items;
@property (nonatomic, assign) NSUInteger version;
@property (nonatomic, assign) ADRenderMode renderMode;

@end

@implementation ADViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Render Modes Lab";
    self.view.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.97 alpha:1.0];
    self.renderMode = ADRenderModeSync;
    self.version = 1;

    [self buildViews];
    [self reloadItems];
    [self updateCopy];
}

- (void)buildViews {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = self.view.backgroundColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 196.0;
    self.tableView.showsVerticalScrollIndicator = YES;
    [self.tableView registerClass:[ADDemoCell class] forCellReuseIdentifier:kSyncCellIdentifier];
    [self.tableView registerClass:[ADDemoCell class] forCellReuseIdentifier:kUIKitCellIdentifier];
    [self.tableView registerClass:[ADDemoCell class] forCellReuseIdentifier:kAsyncCellIdentifier];
    [self.tableView registerClass:[ADDemoCell class] forCellReuseIdentifier:kLayerClassCellIdentifier];
    [self.view addSubview:self.tableView];

    CGFloat initialHeaderWidth = UIScreen.mainScreen.bounds.size.width;
    self.tableHeaderContainerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, initialHeaderWidth, 1.0)];
    self.tableHeaderContainerView.backgroundColor = UIColor.clearColor;
    self.tableHeaderContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableHeaderWidthConstraint = [self.tableHeaderContainerView.widthAnchor constraintEqualToConstant:initialHeaderWidth];
    self.tableHeaderWidthConstraint.active = YES;

    UIView *panel = [[UIView alloc] init];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    panel.backgroundColor = UIColor.whiteColor;
    panel.layer.cornerRadius = 18.0;

    self.modeControl = [[UISegmentedControl alloc] initWithItems:@[@"drawRect", @"UIKit", @"delegate", @"YYLayer"]];
    self.modeControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.modeControl.selectedSegmentIndex = 0;
    self.modeControl.backgroundColor = [UIColor colorWithRed:0.92 green:0.95 blue:0.99 alpha:1.0];
    self.modeControl.selectedSegmentTintColor = [UIColor colorWithRed:0.13 green:0.42 blue:0.95 alpha:1.0];
    self.modeControl.layer.cornerRadius = 10.0;
    self.modeControl.layer.masksToBounds = YES;
    self.modeControl.layer.borderWidth = 1.0;
    self.modeControl.layer.borderColor = [UIColor colorWithRed:0.76 green:0.83 blue:0.93 alpha:1.0].CGColor;
    [self.modeControl setTitleTextAttributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.20 green:0.28 blue:0.38 alpha:1.0]
    } forState:UIControlStateNormal];
    [self.modeControl setTitleTextAttributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold],
        NSForegroundColorAttributeName: UIColor.whiteColor
    } forState:UIControlStateSelected];
    [self.modeControl addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];

    self.fpsLabel = [[ADFPSLabel alloc] init];
    self.fpsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.fpsLabel];

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    self.summaryLabel.textColor = [UIColor colorWithRed:0.13 green:0.19 blue:0.30 alpha:1.0];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.hintLabel.numberOfLines = 0;
    self.hintLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.hintLabel.textColor = [UIColor colorWithRed:0.34 green:0.40 blue:0.48 alpha:1.0];
    self.hintLabel.text = @"观察点：1) drawRect 把位图栅格化压在主线程 2) UIKit 模式改成 UILabel/UIView/CAGradientLayer 等系统组件 3) delegate 异步把 bitmap 生成挪到后台 4) YYLayer 把异步调度下沉到自定义 layer。";

    self.resultLabel = [[UILabel alloc] init];
    self.resultLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.resultLabel.numberOfLines = 0;
    self.resultLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightRegular];
    self.resultLabel.textColor = [UIColor colorWithRed:0.27 green:0.33 blue:0.42 alpha:1.0];
    self.resultLabel.text = @"本机实测：连点 burst 时，drawRect 最低约 48 FPS，UIKit 最低约 54 FPS，两种异步模式都能稳在 60 FPS。原因是 burst 会让 180 条数据同时重绘，drawRect 的位图栅格化完全压在主线程；UIKit 虽然也是主线程更新，但更多是系统组件的布局、文本测量和 layer 属性赋值，成本比手写 CGContext 低；异步模式把 bitmap 生成放到后台，主线程只负责触发和提交 contents，所以掉帧最少。\n\n快速上下滑动时，四种模式都接近 60 FPS。原因是纯滚动主要消耗在 UITableView 复用、布局和 Core Animation 合成，当前 demo 的 cell 高度固定、结构稳定，滚动本身并不会像 burst 那样强迫每张卡重新栅格化，因此差异被明显缩小。想把滚动差异继续拉开，需要边滚边频繁改内容，或者进一步提高单卡绘制复杂度。";

    self.burstButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.burstButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.burstButton setTitle:@"批量重绘 180 条数据" forState:UIControlStateNormal];
    self.burstButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    self.burstButton.backgroundColor = [UIColor colorWithRed:0.13 green:0.42 blue:0.95 alpha:1.0];
    [self.burstButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.burstButton.layer.cornerRadius = 12.0;
    [self.burstButton addTarget:self action:@selector(burstUpdateTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.tableHeaderContainerView addSubview:panel];
    self.tableView.tableHeaderView = self.tableHeaderContainerView;

    [panel addSubview:self.modeControl];
    [panel addSubview:self.summaryLabel];
    [panel addSubview:self.hintLabel];
    [panel addSubview:self.resultLabel];
    [panel addSubview:self.burstButton];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.fpsLabel.topAnchor constraintEqualToAnchor:guide.topAnchor constant:10.0],
        [self.fpsLabel.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-12.0],
        [self.fpsLabel.widthAnchor constraintEqualToConstant:82.0],

        [panel.topAnchor constraintEqualToAnchor:self.tableHeaderContainerView.topAnchor constant:12.0],
        [panel.leadingAnchor constraintEqualToAnchor:self.tableHeaderContainerView.leadingAnchor constant:16.0],
        [panel.trailingAnchor constraintEqualToAnchor:self.tableHeaderContainerView.trailingAnchor constant:-16.0],

        [self.modeControl.topAnchor constraintEqualToAnchor:panel.topAnchor constant:16.0],
        [self.modeControl.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16.0],
        [self.modeControl.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16.0],

        [self.summaryLabel.topAnchor constraintEqualToAnchor:self.modeControl.bottomAnchor constant:14.0],
        [self.summaryLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16.0],
        [self.summaryLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16.0],

        [self.hintLabel.topAnchor constraintEqualToAnchor:self.summaryLabel.bottomAnchor constant:12.0],
        [self.hintLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16.0],
        [self.hintLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16.0],

        [self.resultLabel.topAnchor constraintEqualToAnchor:self.hintLabel.bottomAnchor constant:12.0],
        [self.resultLabel.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16.0],
        [self.resultLabel.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16.0],

        [self.burstButton.topAnchor constraintEqualToAnchor:self.resultLabel.bottomAnchor constant:14.0],
        [self.burstButton.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16.0],
        [self.burstButton.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16.0],
        [self.burstButton.heightAnchor constraintEqualToConstant:44.0],
        [self.burstButton.bottomAnchor constraintEqualToAnchor:panel.bottomAnchor constant:-16.0],
        [panel.bottomAnchor constraintEqualToAnchor:self.tableHeaderContainerView.bottomAnchor constant:-12.0]
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateTableHeaderLayoutIfNeeded];
}

- (void)updateTableHeaderLayoutIfNeeded {
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (width <= 0.0) {
        return;
    }

    CGRect currentFrame = self.tableHeaderContainerView.frame;
    if (fabs(currentFrame.size.width - width) >= 0.5) {
        currentFrame.size.width = width;
        self.tableHeaderContainerView.frame = currentFrame;
    }

    self.tableHeaderWidthConstraint.constant = width;
    [self.tableHeaderContainerView setNeedsLayout];
    [self.tableHeaderContainerView layoutIfNeeded];

    CGSize fittingSize = [self.tableHeaderContainerView systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                                                       withHorizontalFittingPriority:UILayoutPriorityRequired
                                                             verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    CGFloat targetHeight = ceil(fittingSize.height);

    if (fabs(currentFrame.size.width - width) < 0.5 && fabs(currentFrame.size.height - targetHeight) < 0.5) {
        return;
    }

    currentFrame.size.width = width;
    currentFrame.size.height = targetHeight;
    self.tableHeaderContainerView.frame = currentFrame;
    self.tableView.tableHeaderView = self.tableHeaderContainerView;
}

- (void)modeChanged:(UISegmentedControl *)sender {
    self.renderMode = (ADRenderMode)sender.selectedSegmentIndex;
    [self updateCopy];
    [self.tableView reloadData];
}

- (void)burstUpdateTapped {
    self.version += 1;
    [self reloadItems];
}

- (void)reloadItems {
    self.items = [ADFeedItem demoItemsWithCount:180 version:self.version];
    [self.tableView reloadData];
}

- (void)updateCopy {
    switch (self.renderMode) {
        case ADRenderModeUIKit:
            self.summaryLabel.text = @"UIKit 组件模式：不用 CGContext 手动画，而是用 UILabel、UIView、小条形子视图和渐变 layer 组合出近似 UI，主线程主要承担子视图布局、文本测量和属性赋值。";
            break;
        case ADRenderModeDisplayLayer:
            self.summaryLabel.text = @"delegate 异步：UIView 仍是默认 CALayer，系统在主线程回调 displayLayer:，我们只借这个时机派发后台渲染任务。";
            break;
        case ADRenderModeLayerClass:
            self.summaryLabel.text = @"layerClass 异步：UIView 的 backing layer 换成 YYAsyncLayer，由 layer 重写 display 并统一拉取 YYAsyncLayerDisplayTask。";
            break;
        case ADRenderModeSync:
        default:
            self.summaryLabel.text = @"同步模式：走系统默认绘制路径，setNeedsDisplay 后会在主线程进入 drawRect，重绘压力直接压在主线程上。";
            break;
    }
    [self updateTableHeaderLayoutIfNeeded];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = kSyncCellIdentifier;
    if (self.renderMode == ADRenderModeUIKit) {
        identifier = kUIKitCellIdentifier;
    } else if (self.renderMode == ADRenderModeDisplayLayer) {
        identifier = kAsyncCellIdentifier;
    } else if (self.renderMode == ADRenderModeLayerClass) {
        identifier = kLayerClassCellIdentifier;
    }
    ADDemoCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell configureWithItem:self.items[indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return tableView.rowHeight;
}

@end
