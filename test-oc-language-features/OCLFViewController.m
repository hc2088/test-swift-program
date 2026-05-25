#import "OCLFViewController.h"
#import "OCLFCopyExperiment.h"
#import "OCLFKVOExperiment.h"

@interface OCLFViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@property (nonatomic, strong) UILabel *memorySemanticsSummaryLabel;
@property (nonatomic, strong) UILabel *kvoSummaryLabel;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) OCLFCopyExperiment *experimentRunner;
@property (nonatomic, strong) OCLFKVOExperiment *kvoRunner;

@end

@implementation OCLFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"OC Features Lab";
    self.view.backgroundColor = [UIColor colorWithRed:0.96 green:0.97 blue:0.99 alpha:1.0];
    self.experimentRunner = [[OCLFCopyExperiment alloc] init];
    self.kvoRunner = [[OCLFKVOExperiment alloc] init];

    [self setupView];
    [self runCopyExperiment];
    [self runKVOExperiment];
}

- (void)setupView {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 18.0;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:20.0],
        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.leadingAnchor constant:20.0],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.trailingAnchor constant:-20.0],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-24.0]
    ]];

    NSArray<UIView *> *cards = @[
        [self makeIntroCard],
        [self makeRoadmapCard],
        [self makeCopyCard],
        [self makeKVOCard],
        [self makeLogCard]
    ];

    for (UIView *card in cards) {
        [self.contentStack addArrangedSubview:card];
    }
}

- (UIView *)makeIntroCard {
    UILabel *titleLabel = [self makeTitleLabel:@"Objective-C 语言特性实验台"];
    UILabel *introLabel = [self makeBodyLabel:@"这个 target 会专门放 OC 语言特性的测试代码。当前先做两组最容易在面试里问到、也最容易讲混的内容：copy / mutableCopy，以及 KVO 里的 willChangeValueForKey: / didChangeValueForKey:。"];
    UILabel *tipLabel = [self makeHintLabel:@"这页当前最重要的区分是：\n1. 单体对象 vs 容器对象 copy\n2. 普通 copy 方法 vs property(copy) setter\n3. KVO 自动通知 vs 手动通知\n4. willChange / didChange 各自承担什么职责"];
    return [self makeCardWithViews:@[titleLabel, introLabel, tipLabel]];
}

- (UIView *)makeRoadmapCard {
    UILabel *titleLabel = [self makeTitleLabel:@"后续预留实验主题"];
    UILabel *bodyLabel = [self makeBodyLabel:@"- 分类\n- 扩展（类扩展）\n- KVO\n- KVC\n- 通知\n- 代理\n- Runtime\n\n这一页先把 copy/mutableCopy 跑通，后面这些内容就继续往这个 target 里加。"];
    return [self makeCardWithViews:@[titleLabel, bodyLabel]];
}

- (UIView *)makeCopyCard {
    UILabel *titleLabel = [self makeTitleLabel:@"当前实验：copy / mutableCopy"];
    self.memorySemanticsSummaryLabel = [self makeBodyLabel:@"等待运行实验..."];
    self.memorySemanticsSummaryLabel.textColor = [UIColor colorWithRed:0.67 green:0.22 blue:0.17 alpha:1.0];

    UIStackView *buttonsRow = [[UIStackView alloc] init];
    buttonsRow.axis = UILayoutConstraintAxisHorizontal;
    buttonsRow.spacing = 10.0;
    buttonsRow.distribution = UIStackViewDistributionFillEqually;

    [buttonsRow addArrangedSubview:[self makeButtonWithTitle:@"运行 copy 实验" action:@selector(runCopyExperiment)]];
    [buttonsRow addArrangedSubview:[self makeButtonWithTitle:@"清空日志" action:@selector(clearLog)]];

    UILabel *tipLabel = [self makeHintLabel:@"如何判断深拷贝还是浅拷贝：\n1. 先看容器地址是不是变了\n2. 再看元素地址是不是也变了\n3. 最后分别修改源容器和共享元素，看 copy 后的对象是否一起变动"];
    return [self makeCardWithViews:@[titleLabel, self.memorySemanticsSummaryLabel, buttonsRow, tipLabel]];
}

- (UIView *)makeKVOCard {
    UILabel *titleLabel = [self makeTitleLabel:@"当前实验：KVO 手动通知"];
    self.kvoSummaryLabel = [self makeBodyLabel:@"等待运行实验..."];
    self.kvoSummaryLabel.textColor = [UIColor colorWithRed:0.33 green:0.25 blue:0.65 alpha:1.0];

    UIStackView *buttonsRow = [[UIStackView alloc] init];
    buttonsRow.axis = UILayoutConstraintAxisHorizontal;
    buttonsRow.spacing = 10.0;
    buttonsRow.distribution = UIStackViewDistributionFillEqually;

    [buttonsRow addArrangedSubview:[self makeButtonWithTitle:@"运行 KVO 实验" action:@selector(runKVOExperiment)]];

    UILabel *tipLabel = [self makeHintLabel:@"这组实验重点看三件事：\n1. 自动 KVO 下，setter 为什么能直接触发回调\n2. 手动 KVO 下，为什么一定是 willChange -> 改 ivar -> didChange\n3. didChange 真正做的不是改值，而是驱动 observer 收到 change 字典"];
    return [self makeCardWithViews:@[titleLabel, self.kvoSummaryLabel, buttonsRow, tipLabel]];
}

- (UIView *)makeLogCard {
    UILabel *titleLabel = [self makeTitleLabel:@"实验日志"];

    self.logTextView = [[UITextView alloc] init];
    self.logTextView.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:1.0 alpha:1.0];
    self.logTextView.textColor = [UIColor colorWithRed:0.20 green:0.22 blue:0.27 alpha:1.0];
    self.logTextView.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightRegular];
    self.logTextView.editable = NO;
    // 日志很多时，允许在日志卡片内部单独滚动，避免固定高度截断内容。
    self.logTextView.scrollEnabled = YES;
    self.logTextView.alwaysBounceVertical = YES;
    self.logTextView.showsVerticalScrollIndicator = YES;
    self.logTextView.layer.cornerRadius = 14.0;
    self.logTextView.textContainerInset = UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0);
    self.logTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [[self.logTextView.heightAnchor constraintEqualToConstant:520.0] setActive:YES];

    return [self makeCardWithViews:@[titleLabel, self.logTextView]];
}

- (UIView *)makeCardWithViews:(NSArray<UIView *> *)views {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 20.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [UIColor colorWithRed:0.88 green:0.90 blue:0.95 alpha:1.0].CGColor;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:views];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;

    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:18.0],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18.0],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18.0],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18.0]
    ]];

    return card;
}

- (UILabel *)makeTitleLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBold];
    label.textColor = [UIColor colorWithRed:0.16 green:0.19 blue:0.24 alpha:1.0];
    label.numberOfLines = 0;
    label.text = text;
    return label;
}

- (UILabel *)makeBodyLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    label.textColor = [UIColor colorWithRed:0.33 green:0.38 blue:0.47 alpha:1.0];
    label.numberOfLines = 0;
    label.text = text;
    return label;
}

- (UILabel *)makeHintLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    label.textColor = [UIColor colorWithRed:0.50 green:0.54 blue:0.62 alpha:1.0];
    label.numberOfLines = 0;
    label.text = text;
    return label;
}

- (UIButton *)makeButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.baseBackgroundColor = [UIColor colorWithRed:0.22 green:0.46 blue:0.92 alpha:1.0];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleLarge;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(14.0, 12.0, 14.0, 12.0);

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.configuration = configuration;
    button.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)runCopyExperiment {
    OCLFCopyExperimentOutcome *outcome = [self.experimentRunner runExperiment];
    self.memorySemanticsSummaryLabel.text = [NSString stringWithFormat:@"当前结论：%@", outcome.summary];

    [self appendLog:@"=================================================="];
    [self appendLog:@"重新运行 copy / mutableCopy 实验"];
    [self appendLog:@"=================================================="];

    for (NSString *line in outcome.lines) {
        [self appendLog:line];
    }
}

- (void)runKVOExperiment {
    OCLFKVOExperimentOutcome *outcome = [self.kvoRunner runExperiment];
    self.kvoSummaryLabel.text = [NSString stringWithFormat:@"当前结论：%@", outcome.summary];

    [self appendLog:@"=================================================="];
    [self appendLog:@"重新运行 KVO willChange / didChange 实验"];
    [self appendLog:@"=================================================="];

    for (NSString *line in outcome.lines) {
        [self appendLog:line];
    }
}

- (void)clearLog {
    self.logTextView.text = @"";
    [self appendLog:@"日志已清空"];
}

- (void)appendLog:(NSString *)text {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss.SSS";
    NSString *line = [NSString stringWithFormat:@"[%@] %@", [formatter stringFromDate:[NSDate date]], text];

    if (self.logTextView.text.length == 0) {
        self.logTextView.text = line;
    } else {
        self.logTextView.text = [self.logTextView.text stringByAppendingFormat:@"\n%@", line];
    }

    NSRange bottom = NSMakeRange(MAX((NSInteger)self.logTextView.text.length - 1, 0), 1);
    [self.logTextView scrollRangeToVisible:bottom];
}

@end
