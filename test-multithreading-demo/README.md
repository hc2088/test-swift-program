# test-multithreading-demo

用于集中测试 iOS 多线程基础能力的 demo target。

- GCD：串行队列、并发队列、DispatchGroup、barrier、串行队列内同步派发死锁。
- Operation：OperationQueue 并发数、任务依赖、完成任务。
- NSThread：手动创建并启动 Thread，观察线程名和优先级。
- 锁：对比无锁、NSLock、DispatchSemaphore、串行队列保护临界区。
- 死锁测试：复现 `queue.async { queue.sync { print("deadlock") } }`，观察 `print` 不会执行。

运行 target 后点击页面按钮，日志会同时输出到页面和 Xcode 控制台。
