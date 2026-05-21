# Combine 学习导读

这个目录现在已经被改造成一个最小可运行的 Combine 学习 demo。建议你不要先背定义，而是先跑起来，再对着代码理解每一段数据流。

## 先看哪里

1. [ViewController.swift](/Users/huchu/Desktop/test-swift-program/test-combine/ViewController.swift)
2. [CombineLessonViewModel.swift](/Users/huchu/Desktop/test-swift-program/test-combine/CombineLessonViewModel.swift)

阅读顺序建议：

1. 先看 `ViewController`
2. 再看 `CombineLessonViewModel`
3. 最后回到界面上重复操作，验证自己对每个 operator 的理解

## 这个 demo 在演示什么

### 1. `CurrentValueSubject`

`usernameInput` 和 `agreementInput` 都是 `CurrentValueSubject`。

你可以先把它理解成：

- 它既能发值
- 又会“记住当前最新值”
- 所以按钮点击时，我们可以直接拿到 `usernameInput.value`

适合场景：

- 表单输入
- 开关状态
- 当前选中的筛选条件

### 2. `PassthroughSubject`

`searchTapped` 是 `PassthroughSubject<Void, Never>`。

你可以先把它理解成：

- 它只负责转发事件
- 它不保存“上一次按钮点击”
- 很适合按钮点击、通知事件、一次性触发动作

适合场景：

- 点击按钮
- 刷新列表
- 主动触发某个流程

### 3. `map`

```swift
usernameInput
    .map { "字符数：\($0.count)" }
```

`map` 的核心作用就是“变形”。

面试里你可以这样回答：

- 输入是 `String`
- 输出可以变成 `Int`
- 也可以变成 `Bool`
- 也可以变成 View 要显示的文案

### 4. `debounce`

```swift
.debounce(for: .milliseconds(350), scheduler: RunLoop.main)
```

它的作用是“等你停一会儿再处理”。

典型使用场景：

- 搜索框联想
- 文本输入校验
- 避免每敲一个字符就请求一次网络

### 5. `removeDuplicates`

```swift
.removeDuplicates()
```

如果前后两次值一样，就不继续往下走。

典型场景：

- 用户输入回到同一个值
- 某个状态被重复设置成一样的内容

### 6. `CombineLatest`

```swift
Publishers.CombineLatest(
    stableInputPublisher.map { $0.count >= 2 },
    agreementInput.removeDuplicates()
)
```

这个 demo 里，按钮是否可点击由两个条件共同决定：

- 输入是否有效
- 开关是否已勾选

也就是说：

- 一个 Publisher 不够
- 两个状态要合并起来判断

这就是 `CombineLatest` 最常见的用途。

### 7. `scan`

```swift
searchTapped
    .scan(0) { count, _ in count + 1 }
```

它很像“流式 reduce”，但不是等所有事件结束才给结果，而是每来一次事件就累加一次状态。

在这个 demo 里用它统计按钮点击次数。

典型场景：

- 点击计数
- 表单步骤进度
- 聊天未读数累加

### 8. `flatMap`

```swift
.flatMap { query in
    Self.mockSearch(query: query)
}
```

这里最关键的理解是：

- 外层流发出来的是一次“点击”
- 内层流变成了一次“异步请求”
- `flatMap` 负责把“事件”展开成“新的 Publisher”

你可以把它先记成：

- 普通 `map` 是把值变成另一个值
- `flatMap` 是把值变成另一个 Publisher

### 9. `sink`

`sink` 是订阅的落点，也就是“最终怎么消费结果”。

比如：

- 更新按钮状态
- 更新结果文本
- 更新日志区域

如果没有订阅，前面的数据流通常不会真正执行。

### 10. `AnyCancellable`

所有订阅最后都要：

```swift
.store(in: &cancellables)
```

你可以先粗暴理解成：

- 不存起来，订阅很可能马上释放
- 一释放，后续事件就收不到了

## 你现在就可以做的练习

1. 把输入合法条件从“至少 2 个字符”改成“至少 4 个字符”
2. 把 `debounce` 的 `350ms` 改成 `1000ms`，重新体验界面变化
3. 把 `mockSearch` 的结果数组改成你自己的业务文案
4. 快速连续点击按钮，观察 `flatMap` 会不会并发触发多个异步任务
5. 试着把 `flatMap` 换成“只保留最后一次请求结果”的写法

## 面试时可以先这样说 Combine

如果面试官让你简单介绍 Combine，你可以先用这版：

> Combine 是 Apple 提供的响应式编程框架。它把异步事件统一抽象成数据流，核心是 Publisher、Subscriber 和 Operator。常见场景包括表单联动、事件响应、网络请求链路、状态组合和线程切换。

再往下展开：

- `Publisher` 负责产生值
- `Subscriber` 负责消费值
- `Operator` 负责处理中间过程
- `Subject` 既能主动发值，又能被订阅
- `AnyCancellable` 负责订阅生命周期

## 下一步建议

等你把这个 demo 看顺以后，下一轮我们可以继续做这三种训练中的任意一种：

1. 用 Combine 写一个登录表单校验
2. 用 Combine 写一个搜索防抖 + 列表刷新
3. 对比 `NotificationCenter`、`delegate`、`callback` 和 Combine 的区别
