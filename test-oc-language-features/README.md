# test-oc-language-features

这是一个专门放 Objective-C 语言特性实验代码的 iOS demo target。

当前已经落地的第一块实验是：

- `copy / mutableCopy`
- `KVO：willChangeValueForKey: / didChangeValueForKey:`
- `Runtime：resolveInstanceMethod: 动态方法解析`

目标是拆开验证这些经常被混在一起的说法：

1. `property(copy)` 和直接写 `[obj copy]` 是不是一回事
2. “可变对象的 copy 是深拷贝”到底是在说单体对象，还是在说容器对象
3. `copy` 返回不可变对象这件事，会不会影响 `NSMutableString *` 这类属性声明
4. `resolveInstanceMethod:` 里只 `return YES` 但不加方法，会不会死循环
5. `class_addMethod` 添加的方法是先进方法列表，还是直接进入 cache

## 当前结论

- `property(copy)` 的本质就是 setter 里调用 `copy`
- 对 `NSMutableString` 这种单体可变对象，`copy / mutableCopy` 看起来像独立新对象
- 对 `NSMutableArray` 这类容器，默认只复制第一层容器，元素对象通常仍然共享
- 所以不能笼统地说“可变对象的 copy 一定是递归深拷贝”
- `copy` 通常返回不可变对象，因此 `@property(nonatomic, copy) NSMutableString *` 是危险写法
- KVO 自动模式下，系统会在合适的 setter 路径上帮你包 `willChangeValueForKey:` / `didChangeValueForKey:`
- 如果关闭了自动通知，或者你绕开了默认 setter，就要自己写成：`willChange -> 改 ivar -> didChange`
- `willChangeValueForKey:` 的核心职责更像“标记变化开始并保存旧值语境”，`didChangeValueForKey:` 更像“变化结束后组装 change 并通知 observer”
- `resolveInstanceMethod:` 只 `return YES` 但不添加方法，不会死循环；Runtime 会重试普通查找，仍然找不到后进入消息转发链
- `class_addMethod` 是把方法添加到类的方法列表；return YES 后 Runtime 重试普通查找，第一次通常从方法列表找到并填充 cache，后续同一消息才优先命中 cache

## 如何判断深拷贝还是浅拷贝

不要只看“外层对象地址变了没有”，更要分层观察：

1. 先看外层对象 / 容器地址是不是新地址
2. 再看容器内部元素地址是不是也都变成了新地址
3. 然后分别修改源对象、源容器、共享元素，观察 copy 后的对象会不会一起变化

如果只是外层容器变了，但里面元素还是同一批对象，那通常只能说是“第一层复制”，不能算严格意义上的递归深拷贝。

## 后续计划

后面会继续把这些内容放进来：

- 分类
- 类扩展
- KVO
- KVC
- 通知
- 代理
