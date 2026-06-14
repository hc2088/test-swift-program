//
//  RunLoopExitConditionLab.swift
//  test-runloop-demo
//
//  Created by Codex on 2026/6/1.
//

import Foundation

private func runLoopExitSourceCallback(_ info: UnsafeMutableRawPointer?) {
    guard let info else { return }
    let lab = Unmanaged<RunLoopExitConditionLab>.fromOpaque(info).takeUnretainedValue()
    lab.performSourceCallback()
}

final class RunLoopExitConditionLab {

    var onLog: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let queue = DispatchQueue(label: "runloop.exit.condition.lab")
    private let lock = NSLock()
    private var isRunning = false

    // RunLoop 退出条件实验的预期结果：
    // 1. 空 RunLoop：直接返回，因为当前 mode 下没有 Source/Timer。
    // 2. 只加 Observer：直接返回，因为 Observer 只是观察状态，不是可等待输入源。
    // 3. 只加 Source0，不 signal：不会直接返回；如果 before 是有限时间，会一直等到 before 时间。
    //    如果 before 是 .distantFuture，就会一直睡眠等待，直到外部 signal + wakeUp、stop 或线程被结束。
    // 4. Source0 signal + wakeUp：RunLoop 被唤醒，处理 Source0 callback 后返回。
    // 5. 只加 Timer：RunLoop 等到 Timer 触发，执行 Timer callback 后返回。
    // 所以线程保活不必须添加 Port；Port 只是 Source1 的常见做法，Source0/Timer 也能让 RunLoop 有可等待对象。
    func runAllCases() {
        lock.lock()
        if isRunning {
            lock.unlock()
            emitLog("RunLoop 退出条件实验正在运行，请等本轮结束")
            return
        }
        isRunning = true
        lock.unlock()

        emitStatus("运行中")
        queue.async { [weak self] in
            guard let self else { return }

            self.emitLog("====== RunLoop 退出条件实验开始 ======")
//            self.runEmptyRunLoopCase()
//            self.runObserverOnlyCase()
//            self.runSourceOnlyTimeoutCase()
            self.runSourceSignalWakeUpCase()
//            self.runTimerOnlyCase()
            self.emitLog("====== RunLoop 退出条件实验结束 ======")

            self.lock.lock()
            self.isRunning = false
            self.lock.unlock()
            self.emitStatus("已完成")
        }
    }

    fileprivate func performSourceCallback() {
        emitLog("Source0 callback 执行：说明 RunLoop 已经进入 BeforeSources 并处理 Source0")
    }

    private func runEmptyRunLoopCase() {
        runCase("空 RunLoop：不加 Source/Timer/Observer", timeout: 1.0) { _ in
            nil
        }
    }

    private func runObserverOnlyCase() {
        runCase("只加 Observer：观察者不提供任务", timeout: 1.0) { [weak self] runLoop in
            let observer = CFRunLoopObserverCreateWithHandler(
                kCFAllocatorDefault,
                CFRunLoopActivity.allActivities.rawValue,
                true,
                0
            ) { _, activity in
                self?.emitLog("observer-only 观察到：\(Self.activityDescription(activity))")
            }

            if let observer {
                CFRunLoopAddObserver(runLoop, observer, .defaultMode)
            }

            return {
                if let observer {
                    CFRunLoopRemoveObserver(runLoop, observer, .defaultMode)
                }
            }
        }
    }

    private func runSourceOnlyTimeoutCase() {
        runCase("只加 Source0：不 signal、不 wakeUp", timeout: 1.0) { [weak self] runLoop in
            guard let self, let source = self.makeSource() else { return nil }
            CFRunLoopAddSource(runLoop, source, .defaultMode)
            self.emitLog("只加 Source0：Source0 已加入 default mode，但本轮不发信号")

            return {
                CFRunLoopRemoveSource(runLoop, source, .defaultMode)
                CFRunLoopSourceInvalidate(source)
            }
        }
    }

    private func runSourceSignalWakeUpCase() {
        runCase("Source0：延迟 0.25s 后 signal + wakeUp", timeout: 1.0) { [weak self] runLoop in
            guard let self, let source = self.makeSource() else { return nil }
            CFRunLoopAddSource(runLoop, source, .defaultMode)
            self.emitLog("Source0 已加入 default mode；外部队列稍后 signal + wakeUp")

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 10) { [weak self] in
                self?.emitLog("外部线程调用 CFRunLoopSourceSignal + CFRunLoopWakeUp")
                CFRunLoopSourceSignal(source)
                CFRunLoopWakeUp(runLoop)
            }

            return {
                CFRunLoopRemoveSource(runLoop, source, .defaultMode)
                CFRunLoopSourceInvalidate(source)
            }
        }
    }

    private func runTimerOnlyCase() {
        runCase("只加 Timer：0.25s 后触发", timeout: 1.0) { [weak self] runLoop in
            let fireDate = CFAbsoluteTimeGetCurrent() + 10
            let timer = CFRunLoopTimerCreateWithHandler(
                kCFAllocatorDefault,
                fireDate,
                0,
                0,
                0
            ) { _ in
                self?.emitLog("Timer callback 执行：说明 Timer 可以让 RunLoop 等待并按时唤醒")
            }

            if let timer {
                CFRunLoopAddTimer(runLoop, timer, .defaultMode)
            }

            return {
                if let timer {
                    CFRunLoopRemoveTimer(runLoop, timer, .defaultMode)
                    CFRunLoopTimerInvalidate(timer)
                }
            }
        }
    }

    private func runCase(
        _ title: String,
        timeout: TimeInterval,
        setup: @escaping (CFRunLoop) -> (() -> Void)?
    ) {
        emitLog("")
        emitLog("开始：\(title)")

        let finished = DispatchSemaphore(value: 0)
        let thread = Thread { [weak self] in
            guard let self else {
                finished.signal()
                return
            }

            Thread.current.name = "runloop.exit.condition.case"
            guard let runLoop = CFRunLoopGetCurrent() else {
                self.emitLog("无法获取当前线程 RunLoop，本 case 结束")
                finished.signal()
                return
            }

            let cleanup = setup(runLoop)
            let start = CFAbsoluteTimeGetCurrent()
            self.emitLog("调用 run(mode:.default, before:+\(self.format(timeout))s)")
            // 如果使用 Date(timeIntervalSinceNow: timeout)，只加 Source0 不 signal 的 case 会等到 timeout 后返回。
            // 如果使用 .distantFuture，则这个 case 会长期等待，不会靠自己直接返回。
//            let result = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: timeout))
            let result = RunLoop.current.run(mode: .default, before: .distantFuture)
            let cost = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            cleanup?()
            self.emitLog("返回：result=\(result), elapsed=\(self.format(cost))ms")
            self.emitConclusion(title: title, result: result, elapsedMilliseconds: cost, timeout: timeout)
            finished.signal()
        }

        thread.start()
        finished.wait()
        Thread.sleep(forTimeInterval: 0.15)
    }

    private func makeSource() -> CFRunLoopSource? {
        var context = CFRunLoopSourceContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil,
            equal: nil,
            hash: nil,
            schedule: nil,
            cancel: nil,
            perform: runLoopExitSourceCallback
        )

        return CFRunLoopSourceCreate(nil, 0, &context)
    }

    private func emitConclusion(
        title: String,
        result: Bool,
        elapsedMilliseconds: Double,
        timeout: TimeInterval
    ) {
        let timeoutMilliseconds = timeout * 1000.0
        if elapsedMilliseconds < 50 {
            emitLog("结论：\(title) 几乎立即返回，说明当前 mode 没有可等待对象可以让 RunLoop 睡眠保活")
        } else if elapsedMilliseconds >= timeoutMilliseconds * 0.85 {
            emitLog("结论：\(title) 等到 before 日期附近才返回，说明当前 mode 有可等待对象，但本轮没有事件被处理")
        } else {
            emitLog("结论：\(title) 在 timeout 前返回，通常是 Source/Timer 已经被处理")
        }

        if !result {
            emitLog("补充：result=false 通常表示这次 run 没有真正处理到输入源或 timer")
        }
    }

    private func emitLog(_ text: String) {
        let line = text.isEmpty ? "" : "[\(timestamp())] \(text)"
        DispatchQueue.main.async { [weak self] in
            self?.onLog?(line)
        }
    }

    private func emitStatus(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChange?(text)
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    private static func activityDescription(_ activity: CFRunLoopActivity) -> String {
        switch activity {
        case .entry:
            return "Entry"
        case .beforeTimers:
            return "BeforeTimers"
        case .beforeSources:
            return "BeforeSources"
        case .beforeWaiting:
            return "BeforeWaiting"
        case .afterWaiting:
            return "AfterWaiting"
        case .exit:
            return "Exit"
        default:
            return "Unknown(\(activity.rawValue))"
        }
    }
}
