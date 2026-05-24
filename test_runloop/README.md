# test_runloop

这个 demo 现在包含两组 RunLoop 相关实验：

1. `performSelector:onThread:` 如果目标是子线程，而子线程没有把 RunLoop 跑起来，selector 到底会不会执行？
2. 自定义 `Source0` 被 `signal` 之后，为什么还需要 `CFRunLoopWakeUp`？
3. `Port` 是不是让 RunLoop 常驻的唯一方式？

## 运行方式

```bash
cd /Users/huchu/Desktop/test-swift-program/test_runloop
swift run source0
```

也可以运行：

```bash
swift run selector
swift run all
```

## Demo 1：performSelector(onThread:)

这个 demo 分成 4 个 case：

1. 子线程完全不碰 `RunLoop`
2. 子线程只取到 `RunLoop.current`，但不调用 `run()`
3. 子线程取到 `RunLoop.current`，添加一个 `Port`，并真正把 RunLoop 跑起来
4. 子线程取到 `RunLoop.current`，添加一个重复 `Timer`，并真正把 RunLoop 跑起来

### 预期结果

- Case 1：selector 不执行
- Case 2：selector 仍然不执行
- Case 3：selector 执行
- Case 4：selector 也会执行

### 结论

面试里最稳的说法是：

> `performSelector:onThread:` 依赖目标线程的 RunLoop 来处理这个 selector source。子线程如果没有运行 RunLoop，那么即使线程活着，selector 也通常不会执行。只是在代码里访问 `RunLoop.current` 也不够，关键是目标线程的 RunLoop 要真正 run 起来。为了让这个 RunLoop 所在的 mode 稳定地活着，可以加 `Port`，也可以加 `Timer` 这类别的 source/timer，`Port` 不是唯一方案。

## Demo 2：Source0

这个 demo 分成 3 个 case：

1. `signal` 了 Source0，但不 `wakeUp`
2. `signal + wakeUp`
3. `signal + wakeUp`，但这次不是用 `Port` 保活，而是用重复 `Timer` 保活

### 预期结果

- Case 1：0.6 秒后仍未处理，直到手动 `CFRunLoopWakeUp`
- Case 2：被唤醒后很快进入 Source0 的 `perform` 回调
- Case 3：同样会很快进入 `perform` 回调，说明 `Port` 不是唯一保活方式

### 结论

面试里最稳的说法是：

> Source0 是非 port-based input source。它可以被 signal，但不会像 Source1 那样靠端口消息主动把 RunLoop 从休眠中叫醒。所以如果目标 RunLoop 已经睡着了，通常还需要配合 `CFRunLoopWakeUp`，RunLoop 醒来后才会在后续的 Source0 处理阶段执行对应回调。为了让这个 RunLoop 所在的 mode 常驻，常见做法是加 `Port`，但并不是必须是 `Port`；重复 `Timer` 或别的可等待 source/timer 也可以。
