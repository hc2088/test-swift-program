#import "OCLFCopyExperiment.h"

@interface OCLFCopyPropertyHolder : NSObject

@property (nonatomic, strong) NSString *strongString;
@property (nonatomic, copy) NSString *copiedString;
@property (nonatomic, strong) NSArray *strongArray;
@property (nonatomic, copy) NSArray *copiedArray;

// 这个属性是故意保留下来的“危险写法”示例：
// 语法能写，但 setter 内部会调用 copy，最终塞进来的对象往往已经变成不可变对象。
@property (nonatomic, copy) NSMutableString *copiedMutableString;

@end

@implementation OCLFCopyPropertyHolder
@end

@implementation OCLFCopyExperimentOutcome
@end

static NSString *OCLFPointerString(id object) {
    return [NSString stringWithFormat:@"%p", object];
}

@implementation OCLFCopyExperiment

- (OCLFCopyExperimentOutcome *)runExperiment {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];

    [lines addObject:@"目标：把 copy.png 里的结论拆开验证。"];
    [lines addObject:@"重点不是只看“地址变没变”，而是同时看："];
    [lines addObject:@"1. 是不是新对象 / 新容器"];
    [lines addObject:@"2. 返回对象是否变成不可变类型"];
    [lines addObject:@"3. 容器元素有没有被递归复制"];
    [lines addObject:@""];

    [self appendMutableStringCaseToLines:lines];
    [self appendMutableArrayCaseToLines:lines];
    [self appendPropertyStringCaseToLines:lines];
    [self appendPropertyArrayCaseToLines:lines];
    [self appendDangerPropertyCaseToLines:lines];

    OCLFCopyExperimentOutcome *outcome = [[OCLFCopyExperimentOutcome alloc] init];
    outcome.summary = @"普通 [obj copy] 和 property(copy) 本质上都会走 copy；对 NSMutableString 这类单体对象看起来像“深拷贝”，但对 NSMutableArray 这类容器默认只是复制第一层容器，元素对象仍然共享，所以不能笼统说“可变对象 copy 一定是递归深拷贝”。";
    outcome.lines = lines;
    return outcome;
}

- (void)appendMutableStringCaseToLines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 1：NSMutableString 直接调 copy / mutableCopy ================"];

    NSMutableString *source = [NSMutableString stringWithString:@"alpha"];
    NSString *copied = [source copy];
    NSMutableString *mutableCopied = [source mutableCopy];

    [lines addObject:[NSString stringWithFormat:@"source 地址=%@ class=%@", OCLFPointerString(source), NSStringFromClass(source.class)]];
    [lines addObject:[NSString stringWithFormat:@"copied 地址=%@ class=%@", OCLFPointerString(copied), NSStringFromClass(copied.class)]];
    [lines addObject:[NSString stringWithFormat:@"mutableCopied 地址=%@ class=%@", OCLFPointerString(mutableCopied), NSStringFromClass(mutableCopied.class)]];

    [source appendString:@"-mutated"];

    [lines addObject:[NSString stringWithFormat:@"修改 source 后：source=%@ | copied=%@ | mutableCopied=%@", source, copied, mutableCopied]];
    [lines addObject:@"结论：对 NSMutableString 这种单体可变对象，copy / mutableCopy 都会拿到与源对象独立的新对象；其中 copy 返回不可变对象，mutableCopy 返回可变对象。"];
    [lines addObject:@""];
}

- (void)appendMutableArrayCaseToLines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 2：NSMutableArray 直接调 copy / mutableCopy ================"];

    NSMutableString *sharedItem = [NSMutableString stringWithString:@"item"];
    NSMutableArray *source = [NSMutableArray arrayWithObject:sharedItem];
    NSArray *copied = [source copy];
    NSMutableArray *mutableCopied = [source mutableCopy];

    [lines addObject:[NSString stringWithFormat:@"source 容器地址=%@ class=%@", OCLFPointerString(source), NSStringFromClass(source.class)]];
    [lines addObject:[NSString stringWithFormat:@"copied 容器地址=%@ class=%@", OCLFPointerString(copied), NSStringFromClass(copied.class)]];
    [lines addObject:[NSString stringWithFormat:@"mutableCopied 容器地址=%@ class=%@", OCLFPointerString(mutableCopied), NSStringFromClass(mutableCopied.class)]];
    [lines addObject:[NSString stringWithFormat:@"三个容器里的第一个元素地址：source[0]=%@ | copied[0]=%@ | mutableCopied[0]=%@", OCLFPointerString(source.firstObject), OCLFPointerString(copied.firstObject), OCLFPointerString(mutableCopied.firstObject)]];

    [source addObject:@"tail"];
    [sharedItem appendString:@"-mutated"];

    [lines addObject:[NSString stringWithFormat:@"修改 source 容器后：source.count=%lu | copied.count=%lu | mutableCopied.count=%lu", (unsigned long)source.count, (unsigned long)copied.count, (unsigned long)mutableCopied.count]];
    [lines addObject:[NSString stringWithFormat:@"修改共享元素后：source[0]=%@ | copied[0]=%@ | mutableCopied[0]=%@", source.firstObject, copied.firstObject, mutableCopied.firstObject]];
    [lines addObject:@"结论：copy / mutableCopy 确实会得到新容器，但默认不会递归复制容器里的元素；元素对象仍然共享，所以这不能算“严格意义上的深拷贝”。"];
    [lines addObject:@""];
}

- (void)appendPropertyStringCaseToLines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 3：property(copy) 和 property(strong) 的字符串对比 ================"];

    OCLFCopyPropertyHolder *holder = [[OCLFCopyPropertyHolder alloc] init];
    NSMutableString *source = [NSMutableString stringWithString:@"origin"];
    holder.strongString = source;
    holder.copiedString = source;

    [lines addObject:[NSString stringWithFormat:@"source 地址=%@ class=%@", OCLFPointerString(source), NSStringFromClass(source.class)]];
    [lines addObject:[NSString stringWithFormat:@"strongString 地址=%@ class=%@", OCLFPointerString(holder.strongString), NSStringFromClass(holder.strongString.class)]];
    [lines addObject:[NSString stringWithFormat:@"copiedString 地址=%@ class=%@", OCLFPointerString(holder.copiedString), NSStringFromClass(holder.copiedString.class)]];

    [source appendString:@"-mutated"];

    [lines addObject:[NSString stringWithFormat:@"修改 source 后：source=%@ | strongString=%@ | copiedString=%@", source, holder.strongString, holder.copiedString]];
    [lines addObject:@"结论：property(copy) 的本质就是 setter 里调用 copy；所以它不是另一套神秘规则，和你手写 [obj copy] 走的是同一个方向。"];
    [lines addObject:@""];
}

- (void)appendPropertyArrayCaseToLines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 4：property(copy) 和 property(strong) 的数组对比 ================"];

    OCLFCopyPropertyHolder *holder = [[OCLFCopyPropertyHolder alloc] init];
    NSMutableString *sharedItem = [NSMutableString stringWithString:@"node"];
    NSMutableArray *source = [NSMutableArray arrayWithObject:sharedItem];
    holder.strongArray = source;
    holder.copiedArray = source;

    [lines addObject:[NSString stringWithFormat:@"source 容器地址=%@ | strongArray 地址=%@ | copiedArray 地址=%@", OCLFPointerString(source), OCLFPointerString(holder.strongArray), OCLFPointerString(holder.copiedArray)]];
    [lines addObject:[NSString stringWithFormat:@"source[0]=%@ | strongArray[0]=%@ | copiedArray[0]=%@", OCLFPointerString(source.firstObject), OCLFPointerString(holder.strongArray.firstObject), OCLFPointerString(holder.copiedArray.firstObject)]];

    [source addObject:@"tail"];
    [sharedItem appendString:@"-mutated"];

    [lines addObject:[NSString stringWithFormat:@"修改 source 容器后：source.count=%lu | strongArray.count=%lu | copiedArray.count=%lu", (unsigned long)source.count, (unsigned long)holder.strongArray.count, (unsigned long)holder.copiedArray.count]];
    [lines addObject:[NSString stringWithFormat:@"修改共享元素后：source[0]=%@ | strongArray[0]=%@ | copiedArray[0]=%@", source.firstObject, holder.strongArray.firstObject, holder.copiedArray.firstObject]];
    [lines addObject:@"结论：property(copy) 复制的是第一层容器，不会自动深拷贝数组元素。"];
    [lines addObject:@""];
}

- (void)appendDangerPropertyCaseToLines:(NSMutableArray<NSString *> *)lines {
    [lines addObject:@"================ Case 5：为什么不要写 @property(copy) NSMutableString * ================"];

    OCLFCopyPropertyHolder *holder = [[OCLFCopyPropertyHolder alloc] init];
    NSMutableString *source = [NSMutableString stringWithString:@"danger"];
    holder.copiedMutableString = source;

    BOOL respondsToAppend = [holder.copiedMutableString respondsToSelector:@selector(appendString:)];
    BOOL isMutableClass = [holder.copiedMutableString isKindOfClass:[NSMutableString class]];

    [lines addObject:[NSString stringWithFormat:@"声明类型是 NSMutableString *，但真正存进去的对象 class=%@", NSStringFromClass(holder.copiedMutableString.class)]];
    [lines addObject:[NSString stringWithFormat:@"isKindOfClass:[NSMutableString class] = %@", isMutableClass ? @"YES" : @"NO"]];
    [lines addObject:[NSString stringWithFormat:@"respondsToSelector:@selector(appendString:) = %@", respondsToAppend ? @"YES" : @"NO"]];
    [lines addObject:@"结论：语法上能写 @property(copy) NSMutableString *，但 setter 内部会把它 copy 成不可变对象；后面如果你当成可变对象去 append，很容易直接崩。"];
    [lines addObject:@""];
}

@end
