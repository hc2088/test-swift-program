//
//  ThreadingDemoLab.swift
//  test-multithreading-demo
//
//  Created by Codex on 2026/5/29.
//

import Foundation

final class ThreadingDemoLab {

    typealias LogHandler = (String) -> Void

    private let logHandler: LogHandler

    init(logHandler: @escaping LogHandler) {
        self.logHandler = logHandler
    }

    func runAllDemos() {
        runGCDDemo()
        runOperationDemo()
        runNSThreadDemo()
        runLockDemo()
    }

    func runGCDDemo() {
        logDivider("GCD")

        let serialQueue = DispatchQueue(label: "com.huchu.threading-demo.gcd.serial", qos: .userInitiated)
        let concurrentQueue = DispatchQueue(
            label: "com.huchu.threading-demo.gcd.concurrent",
            qos: .userInitiated,
            attributes: .concurrent
        )
        let group = DispatchGroup()

        for index in 1...3 {
            group.enter()
            serialQueue.async { [weak self] in
                self?.log("串行队列 async 任务 \(index) 开始")
                Thread.sleep(forTimeInterval: 0.12)
                self?.log("串行队列 async 任务 \(index) 结束")
                group.leave()
            }
        }

        for index in 1...4 {
            group.enter()
            concurrentQueue.async { [weak self] in
                self?.log("并发队列 async 任务 \(index) 开始")
                Thread.sleep(forTimeInterval: 0.08)
                self?.log("并发队列 async 任务 \(index) 结束")
                group.leave()
            }
        }

        concurrentQueue.async(flags: .barrier) { [weak self] in
            self?.log("barrier 任务独占当前并发队列")
        }

        group.notify(queue: .main) { [weak self] in
            self?.log("DispatchGroup notify：GCD 基础任务完成")
        }
    }

    func runSerialQueueDeadlockDemo() {
        logDivider("串行队列 sync 死锁")
        log("准备复现：在 demo.serial 的 async 任务内部，再对同一个串行队列调用 sync")

        let queue = DispatchQueue(label: "demo.serial")

        queue.async { [weak self] in
            self?.log("进入 demo.serial async 任务")
            self?.log("下一行开始调用 queue.sync，同一个串行队列会等待自己执行完，所以会卡住")

            queue.sync {
                print("deadlock")
                self?.log("deadlock：这行不会执行")
            }

            self?.log("queue.sync 之后的代码也不会执行")
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.log("1 秒后仍然没有看到 deadlock 输出，说明 demo.serial 已经发生死锁；主线程没被阻塞，所以页面还能继续响应")
        }
    }

    func runOperationDemo() {
        logDivider("Operation")

        let queue = OperationQueue()
        queue.name = "com.huchu.threading-demo.operation"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 2

        let fetchOperation = BlockOperation { [weak self] in
            self?.log("Operation A：模拟请求数据")
            Thread.sleep(forTimeInterval: 0.15)
        }

        let parseOperation = BlockOperation { [weak self] in
            self?.log("Operation B：依赖 A，解析数据")
            Thread.sleep(forTimeInterval: 0.1)
        }
        parseOperation.addDependency(fetchOperation)

        let renderOperation = BlockOperation { [weak self] in
            self?.log("Operation C：依赖 B，准备 UI 数据")
            Thread.sleep(forTimeInterval: 0.08)
        }
        renderOperation.addDependency(parseOperation)

        let independentOperation = BlockOperation { [weak self] in
            self?.log("Operation D：独立任务，可以和 A 并发")
            Thread.sleep(forTimeInterval: 0.12)
        }

        let finishOperation = BlockOperation { [weak self] in
            self?.log("Operation finish：依赖链全部完成")
        }
        finishOperation.addDependency(renderOperation)
        finishOperation.addDependency(independentOperation)

        queue.addOperations(
            [fetchOperation, parseOperation, renderOperation, independentOperation, finishOperation],
            waitUntilFinished: false
        )
    }

    func runNSThreadDemo() {
        logDivider("NSThread")

        let manualThread = Thread { [weak self] in
            Thread.current.name = "NSThread.manual"
            self?.log("手动 start 的 Thread 开始")
            Thread.sleep(forTimeInterval: 0.18)
            self?.log("手动 start 的 Thread 结束")
        }
        manualThread.name = "NSThread.manual"
        manualThread.start()

        let secondThread = Thread { [weak self] in
            Thread.current.name = "NSThread.second"
            self?.log("第二个 Thread 开始")
            Thread.sleep(forTimeInterval: 0.1)
            self?.log("第二个 Thread 结束")
        }
        secondThread.name = "NSThread.second"
        secondThread.threadPriority = 0.4
        secondThread.start()
    }

    func runLockDemo() {
        logDivider("Locks")

        runCounterCase(title: "无锁计数", workerCount: 8, iterations: 2_000) { body in
            body()
        }

        let nsLock = NSLock()
        runCounterCase(title: "NSLock 计数", workerCount: 8, iterations: 2_000) { body in
            nsLock.lock()
            body()
            nsLock.unlock()
        }

        let semaphore = DispatchSemaphore(value: 1)
        runCounterCase(title: "DispatchSemaphore 计数", workerCount: 8, iterations: 2_000) { body in
            semaphore.wait()
            body()
            semaphore.signal()
        }

        let serialQueue = DispatchQueue(label: "com.huchu.threading-demo.lock.serial")
        runCounterCase(title: "串行队列保护计数", workerCount: 8, iterations: 2_000) { body in
            serialQueue.sync {
                body()
            }
        }
    }

    private func runCounterCase(
        title: String,
        workerCount: Int,
        iterations: Int,
        protect: @escaping (@escaping () -> Void) -> Void
    ) {
        let queue = DispatchQueue.global(qos: .userInitiated)
        let group = DispatchGroup()
        var counter = 0

        for _ in 0..<workerCount {
            group.enter()
            queue.async {
                for _ in 0..<iterations {
                    protect {
                        counter += 1
                    }
                }
                group.leave()
            }
        }

        let expected = workerCount * iterations
        group.notify(queue: .main) { [weak self] in
            self?.log("\(title)：counter = \(counter)，expected = \(expected)")
        }
    }

    private func logDivider(_ title: String) {
        log("---- \(title) demo ----")
    }

    private func log(_ message: String) {
        let threadName: String
        if Thread.isMainThread {
            threadName = "main"
        } else if let name = Thread.current.name, !name.isEmpty {
            threadName = name
        } else {
            threadName = "background"
        }

        logHandler("[\(threadName)] \(message)")
    }
}
