#import "OCLFResolveMethodExperiment.h"
#import <objc/message.h>
#import <objc/runtime.h>

static NSMutableArray<NSString *> *OCLFResolveTraceLines;
static NSUInteger OCLFResolveRunCounter = 0;

static void OCLFResolveAppend(NSString *line) {
    [OCLFResolveTraceLines addObject:line];
    NSLog(@"%@", line);
}

static BOOL OCLFSelectorHasPrefix(SEL selector, NSString *prefix) {
    return [NSStringFromSelector(selector) hasPrefix:prefix];
}

static void OCLFDynamicGreetingIMP(id self, SEL _cmd) {
    OCLFResolveAppend([NSString stringWithFormat:@"动态 IMP 执行：receiver=%@ selector=%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]);
}

static void OCLFSendVoidMessage(id target, SEL selector) {
    ((void (*)(id, SEL))(void *)objc_msgSend)(target, selector);
}

@interface OCLFResolveTarget : NSObject
@end

@implementation OCLFResolveTarget

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    BOOL isMissingCase = OCLFSelectorHasPrefix(sel, @"oclf_missingButResolveReturnsYES_");
    BOOL isDynamicCase = OCLFSelectorHasPrefix(sel, @"oclf_dynamicGreeting_");
    if (!isMissingCase && !isDynamicCase) {
        return [super resolveInstanceMethod:sel];
    }

    NSString *selectorName = NSStringFromSelector(sel);
    OCLFResolveAppend([NSString stringWithFormat:@"+resolveInstanceMethod: 被调用，selector=%@", selectorName]);

    if (isMissingCase) {
        OCLFResolveAppend(@"这里故意不调用 class_addMethod，只 return YES。");
        OCLFResolveAppend(@"结论预期：Runtime 会重走一次普通查找；仍然找不到后进入消息转发，不会无限递归。");
        return YES;
    }

    if (isDynamicCase) {
        BOOL added = class_addMethod(self, sel, (IMP)OCLFDynamicGreetingIMP, "v@:");
        OCLFResolveAppend([NSString stringWithFormat:@"调用 class_addMethod 添加实例方法，added=%@", added ? @"YES" : @"NO"]);
        OCLFResolveAppend(@"添加成功后 return YES，Runtime 会重试普通方法查找。");
        return YES;
    }

    return [super resolveInstanceMethod:sel];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (OCLFSelectorHasPrefix(aSelector, @"oclf_missingButResolveReturnsYES_")) {
        OCLFResolveAppend([NSString stringWithFormat:@"进入 forwardingTargetForSelector:，selector=%@，这里返回 nil 继续走完整转发。", NSStringFromSelector(aSelector)]);
        return nil;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (OCLFSelectorHasPrefix(aSelector, @"oclf_missingButResolveReturnsYES_")) {
        OCLFResolveAppend([NSString stringWithFormat:@"进入 methodSignatureForSelector:，selector=%@，返回 v@: 签名避免崩溃。", NSStringFromSelector(aSelector)]);
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = anInvocation.selector;
    if (OCLFSelectorHasPrefix(selector, @"oclf_missingButResolveReturnsYES_")) {
        OCLFResolveAppend([NSString stringWithFormat:@"进入 forwardInvocation:，selector=%@。说明已经从动态方法解析落到了完整消息转发。", NSStringFromSelector(selector)]);
        return;
    }
    [super forwardInvocation:anInvocation];
}

@end

@implementation OCLFResolveMethodExperimentOutcome
@end

@implementation OCLFResolveMethodExperiment

- (OCLFResolveMethodExperimentOutcome *)runExperiment {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    OCLFResolveTraceLines = lines;

    NSUInteger runID = ++OCLFResolveRunCounter;
    SEL missingSelector = NSSelectorFromString([NSString stringWithFormat:@"oclf_missingButResolveReturnsYES_%lu", (unsigned long)runID]);
    SEL dynamicSelector = NSSelectorFromString([NSString stringWithFormat:@"oclf_dynamicGreeting_%lu", (unsigned long)runID]);

    [lines addObject:@"目标：验证 +resolveInstanceMethod: 的两个分支。"];
    [lines addObject:@"Case 1：只 return YES，但不添加方法。"];
    [lines addObject:@"Case 2：class_addMethod 添加方法，并 return YES。"];
    [lines addObject:@""];

//    [self appendMissingMethodCaseWithSelector:missingSelector lines:lines];
    [self appendDynamicMethodCaseWithSelector:dynamicSelector lines:lines];

    OCLFResolveMethodExperimentOutcome *outcome = [[OCLFResolveMethodExperimentOutcome alloc] init];
    outcome.summary = @"只 return YES 不加方法不会死循环，会重试查找后进入消息转发；class_addMethod 是把方法加到类的方法列表，随后重试普通查找，第一次通常从方法列表找到并填充 cache，后续再发同一消息才命中 cache。";
    outcome.lines = lines;

    OCLFResolveTraceLines = nil;
    return outcome;
}

- (void)appendMissingMethodCaseWithSelector:(SEL)selector lines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 1：resolve 里不添加方法，只 return YES ================"];

    OCLFResolveTarget *target = [[OCLFResolveTarget alloc] init];
    OCLFResolveAppend([NSString stringWithFormat:@"发送未知消息：%@", NSStringFromSelector(selector)]);
    OCLFSendVoidMessage(target, selector);
    [lines addObject:@"发送完成：没有死循环。本 demo 在完整消息转发里接住了它；如果不实现 methodSignature/forwardInvocation，最终会 doesNotRecognizeSelector 崩溃。"];
    [lines addObject:@""];
}

- (void)appendDynamicMethodCaseWithSelector:(SEL)selector lines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 2：resolve 里 class_addMethod 后 return YES ================"];

    OCLFResolveTarget *target = [[OCLFResolveTarget alloc] init];
    OCLFResolveAppend([NSString stringWithFormat:@"第一次发送未知消息：%@", NSStringFromSelector(selector)]);
    OCLFSendVoidMessage(target, selector);

    Method method = class_getInstanceMethod([OCLFResolveTarget class], selector);
    IMP methodIMP = method ? method_getImplementation(method) : NULL;
    [lines addObject:[NSString stringWithFormat:@"第一次发送后，class_getInstanceMethod 是否能拿到方法：%@", method ? @"YES" : @"NO"]];
    [lines addObject:[NSString stringWithFormat:@"方法列表里的 IMP 是否等于动态添加的 IMP：%@", methodIMP == (IMP)OCLFDynamicGreetingIMP ? @"YES" : @"NO"]];

    OCLFResolveAppend([NSString stringWithFormat:@"第二次发送同一个消息：%@", NSStringFromSelector(selector)]);
    OCLFSendVoidMessage(target, selector);
    [lines addObject:@"第二次发送没有再次进入 +resolveInstanceMethod:，说明方法已经被类结构接受；Runtime 私有 cache 是否命中无法用公开 API 直接打印，但正常路径会在第一次查到 IMP 后填充 cache，后续优先走 cache。"];
    [lines addObject:@""];
}

@end
