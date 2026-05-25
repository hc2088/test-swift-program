#import "OCLFKVOExperiment.h"

@interface OCLFKVOObservedModel : NSObject

@property (nonatomic, copy) NSString *autoName;
@property (nonatomic, assign) NSInteger manualScore;
@property (nonatomic, copy) NSString *manualTag;

- (void)updateManualScore:(NSInteger)newScore;
- (void)updateManualTag:(NSString *)newTag trace:(NSMutableArray<NSString *> *)trace;

@end

@implementation OCLFKVOObservedModel

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    // 这里故意关闭两个 key 的自动通知，方便演示 willChange/didChange 的手动写法。
    if ([key isEqualToString:@"manualScore"] || [key isEqualToString:@"manualTag"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)updateManualScore:(NSInteger)newScore {
    // 这就是最常见的手动 KVO 模板：
    // 1. 先 willChange，告诉系统“这个 key 要变了”
    // 2. 再直接改 backing ivar
    // 3. 最后 didChange，系统会在这里组装 change 并通知 observer
    [self willChangeValueForKey:@"manualScore"];
    _manualScore = newScore;
    [self didChangeValueForKey:@"manualScore"];
}

- (void)updateManualTag:(NSString *)newTag trace:(NSMutableArray<NSString *> *)trace {
    NSString *oldTag = _manualTag ?: @"(nil)";

    [trace addObject:@"模拟 willChangeValueForKey: 的思路：先记住旧值，并把当前 key 标记为“即将变化”。"];
    [trace addObject:[NSString stringWithFormat:@"此时旧值 oldValue = %@", oldTag]];

    [self willChangeValueForKey:@"manualTag"];

    [trace addObject:@"中间步骤：真正去改 ivar / backing store。"];
    _manualTag = [newTag copy];
    [trace addObject:[NSString stringWithFormat:@"ivar 已改成 newValue = %@", _manualTag]];

    [trace addObject:@"模拟 didChangeValueForKey: 的思路：变化结束后，让 KVO 框架根据 old/new/kind 去回调观察者。"];
    [self didChangeValueForKey:@"manualTag"];
}

@end

@interface OCLFKVORecorder : NSObject

@property (nonatomic, strong) NSMutableArray<NSString *> *records;

@end

@implementation OCLFKVORecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        _records = [NSMutableArray array];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    NSString *oldValue = [self stringFromChangeValue:change[NSKeyValueChangeOldKey]];
    NSString *newValue = [self stringFromChangeValue:change[NSKeyValueChangeNewKey]];
    NSString *kind = [self stringFromChangeKind:change[NSKeyValueChangeKindKey]];

    [self.records addObject:[NSString stringWithFormat:@"observer 收到回调 -> keyPath=%@ | kind=%@ | old=%@ | new=%@", keyPath, kind, oldValue, newValue]];
}

- (NSString *)stringFromChangeValue:(id)value {
    if (!value) {
        return @"(nil)";
    }
    if (value == [NSNull null]) {
        return @"<NSNull>";
    }
    return [value description];
}

- (NSString *)stringFromChangeKind:(NSNumber *)kindNumber {
    switch (kindNumber.integerValue) {
        case NSKeyValueChangeSetting:
            return @"Setting";
        case NSKeyValueChangeInsertion:
            return @"Insertion";
        case NSKeyValueChangeRemoval:
            return @"Removal";
        case NSKeyValueChangeReplacement:
            return @"Replacement";
        default:
            return @"Unknown";
    }
}

@end

@implementation OCLFKVOExperimentOutcome
@end

@implementation OCLFKVOExperiment

- (OCLFKVOExperimentOutcome *)runExperiment {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];

    [lines addObject:@"目标：验证 willChangeValueForKey: / didChangeValueForKey: 在 KVO 里的作用。"];
    [lines addObject:@"这次实验分成三层："];
    [lines addObject:@"1. 系统自动 KVO：普通 setter 改值就触发"];
    [lines addObject:@"2. 手动 KVO：关闭自动通知后，自己在改 ivar 前后包 willChange/didChange"];
    [lines addObject:@"3. 模拟实现：把 will/did 两步拆开，看它们大致承担什么职责"];
    [lines addObject:@""];

    OCLFKVOObservedModel *model = [[OCLFKVOObservedModel alloc] init];
    OCLFKVORecorder *recorder = [[OCLFKVORecorder alloc] init];

    [model addObserver:recorder forKeyPath:@"autoName" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [model addObserver:recorder forKeyPath:@"manualScore" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [model addObserver:recorder forKeyPath:@"manualTag" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];

    @try {
        [self appendAutomaticCaseToLines:lines model:model recorder:recorder];
        [self appendManualCaseToLines:lines model:model recorder:recorder];
        [self appendSimulatedCaseToLines:lines model:model recorder:recorder];
    } @finally {
        [model removeObserver:recorder forKeyPath:@"autoName"];
        [model removeObserver:recorder forKeyPath:@"manualScore"];
        [model removeObserver:recorder forKeyPath:@"manualTag"];
    }

    OCLFKVOExperimentOutcome *outcome = [[OCLFKVOExperimentOutcome alloc] init];
    outcome.summary = @"KVO 可以理解成“值变化通知协议”：自动模式下系统在 setter 周围帮你包 willChange/didChange；手动模式下你自己在改 ivar 前后调用这两个方法。它们的核心职责不是改值，而是记录变化边界并驱动 observer 回调。";
    outcome.lines = lines;
    return outcome;
}

- (void)appendAutomaticCaseToLines:(NSMutableArray<NSString *> *)lines
                             model:(OCLFKVOObservedModel *)model
                          recorder:(OCLFKVORecorder *)recorder {
    [lines addObject:@"================ Case 1：系统自动 KVO（普通 setter） ================"];
    model.autoName = @"before-auto";
    [recorder.records removeAllObjects];

    [lines addObject:@"直接写 model.autoName = @\"after-auto\"；这里不需要你手动调 will/did。"];
    model.autoName = @"after-auto";

    [lines addObjectsFromArray:recorder.records];
    [lines addObject:@"结论：默认情况下，KVO 会在合适的 setter 路径里替你包好变化通知。"];
    [lines addObject:@""];
}

- (void)appendManualCaseToLines:(NSMutableArray<NSString *> *)lines
                          model:(OCLFKVOObservedModel *)model
                       recorder:(OCLFKVORecorder *)recorder {
    [lines addObject:@"================ Case 2：手动 KVO（关闭自动通知） ================"];
    model.manualScore = 3;
    [recorder.records removeAllObjects];

    [lines addObject:@"manualScore 关闭了自动 KVO，所以不能只改 ivar；要用 [self willChangeValueForKey:] + 改 ivar + [self didChangeValueForKey:]。"];
    [model updateManualScore:9];

    [lines addObjectsFromArray:recorder.records];
    [lines addObject:@"结论：手动 KVO 最典型的用途，就是你不想走默认 setter，或者你要自己控制变化边界。"];
    [lines addObject:@""];
}

- (void)appendSimulatedCaseToLines:(NSMutableArray<NSString *> *)lines
                             model:(OCLFKVOObservedModel *)model
                          recorder:(OCLFKVORecorder *)recorder {
    [lines addObject:@"================ Case 3：模拟 willChange / didChange 的职责 ================"];
    model.manualTag = @"old-tag";
    [recorder.records removeAllObjects];

    [model updateManualTag:@"new-tag" trace:lines];
    [lines addObjectsFromArray:recorder.records];
    [lines addObject:@"把它抽象成一句话："];
    [lines addObject:@"willChangeValueForKey: 更像“变化开始，先记现场”；didChangeValueForKey: 更像“变化结束，把 old/new/kind 打包后通知观察者”。"];
    [lines addObject:@""];
}

@end
