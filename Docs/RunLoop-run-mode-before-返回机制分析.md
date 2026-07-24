# RunLoop.run(mode:before:) 返回机制分析

本文分析的是 [RunLoopThreadLab.swift](../test-runloop-demo/RunLoopThreadLab.swift) 里的这段代码：

```swift
while shouldContinueRunning() &&
    runLoop.run(mode: .default, before: .distantFuture) {
    emitLog("一次 run(mode:before:) 返回；如果 shouldKeepRunLoopAlive 仍为 true，就继续下一轮")
}
```

对照图是 [runloop.png](./runloop.png)。

## 先说结论

`runLoop.run(mode: .default, before: .distantFuture)` 返回时，表示**当前这一次 run 调用结束了**，也可以理解为“当前这次 RunLoop 运行过程退出到了调用点”。

但这不等于：

- 当前线程的 `RunLoop` 对象被销毁了
- 当前线程马上退出了
- 下次调用会创建一个全新的 `RunLoop`

更准确的说法是：

> 每条线程有自己的 RunLoop。`RunLoop.current` 拿到的是当前线程绑定的那个 RunLoop 对象。`run(mode:before:)` 只是让这个已有的 RunLoop 在指定 mode 下跑起来。它返回后，如果外层 `while` 继续成立，再次调用 `run(mode:before:)`，是重新进入**同一个线程、同一个 RunLoop、同一个 default mode**，不是创建一个新的 RunLoop。

所以你的理解可以微调成：

> `runLoop.run(...)` 返回了，说明“这一次让 RunLoop 跑起来的调用”结束了；如果 `shouldContinueRunning()` 还是 `true`，外层 `while` 会再次调用 `runLoop.run(...)`，让同一个 RunLoop 再次进入运行流程。

## 外层 while 和内层 RunLoop 不是同一层循环

这段代码里有两层概念：

| 层级 | 代码/图示 | 含义 |
| --- | --- | --- |
| 外层循环 | `while shouldContinueRunning() && runLoop.run(...)` | worker 线程自己的保活逻辑，决定 `run(mode:before:)` 返回后要不要再次进入 RunLoop |
| 内层流程 | `runloop.png` 里的 Entry / BeforeTimers / BeforeSources / BeforeWaiting / AfterWaiting / Exit | 一次 `run(mode:before:)` 调用进入 CoreFoundation RunLoop 后经历的状态 |

`runloop.png` 画的是**一次 `run(mode:before:)` 调用内部的状态流转**。

外层 `while` 解决的是另一个问题：如果这次 `run(mode:before:)` 因为处理了 Source、Timer、被 stop、或者没有可等待对象而返回了，线程入口函数接下来要不要继续调用它。

## 和 runloop.png 的状态怎么对应

这段代码和图中的状态可以这样对应：

| 代码位置 / 行为 | 对应图中状态 | 说明 |
| --- | --- | --- |
| 执行到 `runLoop.run(mode: .default, before: .distantFuture)` | 即将进入 RunLoop / Entry | 当前 worker 线程开始进入这一次 RunLoop 运行 |
| `CFRunLoopObserver` 收到 `.entry` | 即将进入 RunLoop | demo 日志会打印 `Entry：进入本轮 RunLoop` |
| RunLoop 检查 Timer | 将要处理 Timer | 对应 observer 的 `.beforeTimers` |
| RunLoop 检查 Source0 / RunLoop block | 将要处理 Source0 事件 | 对应 observer 的 `.beforeSources`；`CFRunLoopPerformBlock` 投递的 block 也常在这个阶段附近被执行 |
| `Source0` 已经被 signal | 处理 Source0 事件 | `performSource0Messages()` 会被调用 |
| Port 收到消息 | 如果有 Source1 要处理 / 处理唤醒时收到的消息 | `Port` 加入 RunLoop 后表现为 port-based input source，也就是常说的 Source1 |
| 没有马上要处理的事件 | 线程将要休眠 / BeforeWaiting | RunLoop 准备让线程睡眠等待 |
| 线程睡眠中 | 休眠，等待唤醒 | 等待 Source1、Timer 到点、`CFRunLoopWakeUp`、`CFRunLoopStop` 等 |
| 被事件或手动 wakeUp 唤醒 | 线程刚被唤醒 / AfterWaiting | demo 日志会打印 `AfterWaiting：线程刚从休眠中醒来` |
| 处理唤醒原因 | 处理唤醒时收到的消息 | 可能是 Port 消息、Timer、Source0 signal 后配合 wakeUp、RunLoop block 等 |
| 这一次 `run(mode:before:)` 要结束 | Exit | demo 日志会打印 `Exit：当前这次 RunLoop 退出` |
| `run(mode:before:)` 返回到 Swift while | 图外层：回到调用点 | 进入 `while` body，打印“一次 run(mode:before:) 返回...” |
| 下一轮 `while` 条件仍成立 | 再次进入 Entry | 重新调用同一个 `runLoop.run(...)`，同一个 RunLoop 再次进入运行状态 |

关键点：图里的 `Exit` 指的是**当前这次 RunLoop 运行过程的 Exit**，不必然表示线程死亡，也不必然表示 RunLoop 对象销毁。

## 一次返回后为什么还要 while 再跑

`RunLoop.run(mode:before:)` 不是一个“永远不返回”的 API。它可能因为这些原因返回：

| 返回原因 | 在这个 demo 里的例子 | 返回后外层 while 的作用 |
| --- | --- | --- |
| 处理了某个输入源或 Timer | Source0 被 signal + wakeUp、Port 收到消息、Timer fired | 如果还要保持 worker 线程可用，就再调用一次 `run(...)` 继续等后续事件 |
| `before` 时间到了 | 如果 `before` 不是 `.distantFuture`，而是 1 秒后的 Date | 超时后可以选择继续跑，也可以退出 |
| 当前 mode 没有 Source/Timer | 空 RunLoop、只加 Observer | `run(...)` 很快返回；如果一直 while，可能形成空转，所以一般必须保证当前 mode 有 source/timer |
| 调用了 `CFRunLoopStop` | `stop()` 里投递 block，然后在 worker 线程调用 `CFRunLoopStop` | `shouldKeepRunLoopAlive` 已经被置为 `false`，下一次 while 条件失败，线程清理并退出 |

这个 demo 里使用 `.distantFuture`，所以正常情况下它不是靠时间到期返回，而是主要靠事件、Source、Timer 或 `CFRunLoopStop` 返回。

## stop 时发生了什么

`stop()` 的关键逻辑是：

```swift
shouldKeepRunLoopAlive = false

CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) {
    CFRunLoopStop(CFRunLoopGetCurrent())
}
CFRunLoopWakeUp(runLoop)
```

它做了三件事：

1. 先把 `shouldKeepRunLoopAlive` 设为 `false`。
2. 向 worker RunLoop 投递一个 block，让 `CFRunLoopStop` 在 worker 线程自己的 RunLoop 里执行。
3. 调用 `CFRunLoopWakeUp`，避免 worker 正在睡眠时收不到停止请求。

worker 线程醒来后，会执行投递进去的 block，并调用 `CFRunLoopStop`。这会让当前正在执行的 `runLoop.run(mode:before:)` 返回。

返回后，外层 `while` 下一次检查 `shouldContinueRunning()` 时会拿到 `false`，于是不会再进入 `runLoop.run(...)`，随后执行：

```swift
cleanupWorkerRunLoop(runLoop: runLoop, cfRunLoop: cfRunLoop)
emitStatus("worker RunLoop 已停止")
emitLog("worker 线程退出")
```

这时才是 worker 线程真正开始走清理和退出。

## 可以怎么记

可以把这段代码理解成下面这个结构：

```text
worker 线程启动
  -> 创建/获取当前线程的 RunLoop
  -> 添加 Observer / Source0 / Port
  -> while shouldKeepRunLoopAlive:
       -> 让同一个 RunLoop 进入 default mode 运行
       -> 经历 Entry / BeforeTimers / BeforeSources / BeforeWaiting / AfterWaiting / Exit
       -> 这次 run 返回
       -> 如果还要保活，就再次进入同一个 RunLoop
  -> 移除 Observer / Source0 / Port
  -> worker 线程退出
```

一句话：

> `run(mode:before:)` 返回，退出的是“这一次 run 调用”；`while` 再次调用它，重新进入的是“同一个 RunLoop 的下一次运行”，不是创建新的 RunLoop。

