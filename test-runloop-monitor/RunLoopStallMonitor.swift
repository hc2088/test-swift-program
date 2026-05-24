//
//  RunLoopStallMonitor.swift
//  test-runloop-monitor
//
//  Created by Codex on 2026/5/23.
//

import Foundation

final class RunLoopStallMonitor {

    struct StallRecord {
        let activity: CFRunLoopActivity
        let duration: TimeInterval
        let reason: String
    }

    var onActivityChange: ((CFRunLoopActivity, String) -> Void)?
    var onStallRecord: ((StallRecord) -> Void)?
    var onLog: ((String) -> Void)?

    private let timeoutInterval: TimeInterval
    private let watchQueue = DispatchQueue(label: "com.huchu.runloop.monitor", qos: .userInitiated)
    private let semaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()

    private var observer: CFRunLoopObserver?
    private var isMonitoring = false
    private var lastActivity: CFRunLoopActivity = .entry
    private var lastActivityTime = CFAbsoluteTimeGetCurrent()
    private var suspiciousHitCount = 0
    private var lastLoggedIdleTimeoutTime: CFAbsoluteTime = 0

    init(timeoutInterval: TimeInterval = 0.08) {
        self.timeoutInterval = timeoutInterval
    }

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        lastActivity = .entry
        lastActivityTime = CFAbsoluteTimeGetCurrent()
        suspiciousHitCount = 0
        lastLoggedIdleTimeoutTime = 0

        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.allActivities.rawValue,
            true,
            0
        ) { [weak self] _, activity in
            self?.handle(activity: activity)
        }

        self.observer = observer
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)

        onLog?("monitor start, timeout = \(Int(timeoutInterval * 1000))ms")
        watchQueue.async { [weak self] in
            self?.watchLoop()
        }
    }

    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        semaphore.signal()

        if let observer {
            CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
        }
        observer = nil
        onLog?("monitor stopped")
    }

    deinit {
        stop()
    }

    private func handle(activity: CFRunLoopActivity) {
        // 这个回调运行在主线程，因为 observer 是加在主线程 RunLoop 上的。
        // 每次 RunLoop 进入新阶段时，我们都把“最近一次状态”和“状态发生时间”记下来，
        // 然后 signal 一下后台 watchdog，表示主线程还在继续往前推进。
        lock.lock()
        lastActivity = activity
        lastActivityTime = CFAbsoluteTimeGetCurrent()
        suspiciousHitCount = 0
        lock.unlock()

        let description = Self.activityDescription(activity)
        onActivityChange?(activity, description)

        if Self.isImportantActivity(activity) {
            onLog?("activity -> \(description)")
        }

        semaphore.signal()
    }

    private func watchLoop() {
        // 这个循环运行在后台串行队列里。
        // 它不是忙轮询，而是“等主线程报平安”：
        // 1. 主线程每次 activity 变化，都会 semaphore.signal()
        // 2. 如果在 timeoutInterval 内收到了 signal，就说明主线程还在流动，继续下一轮等待
        // 3. 如果等超时了，才去读取主线程最近一次状态快照，判断是不是卡住了
        while isMonitoring {
            let result = semaphore.wait(timeout: .now() + timeoutInterval)
            guard isMonitoring else { break }
            guard result == .timedOut else { continue }

            let snapshot = currentSnapshot()
            processTimeout(snapshot)
        }
    }

    private func currentSnapshot() -> (activity: CFRunLoopActivity, elapsed: TimeInterval) {
        // 这里取的是“主线程最近一次 RunLoop 状态”和“从那次状态到现在已经过了多久”。
        // 后台 watchdog 并不自己维护一套状态机，而是读取主线程 observer 留下来的快照。
        lock.lock()
        let activity = lastActivity
        let elapsed = CFAbsoluteTimeGetCurrent() - lastActivityTime
        lock.unlock()
        return (activity, elapsed)
    }

    private func processTimeout(_ snapshot: (activity: CFRunLoopActivity, elapsed: TimeInterval)) {
        // 如果超时发生在 AfterWaiting / BeforeSources，说明主线程刚醒来或刚要处理任务时，
        // 很长时间都没有继续推进，这正是最典型的卡顿可疑点。
        if snapshot.activity == .afterWaiting || snapshot.activity == .beforeSources {
            suspiciousHitCount += 1
            let reason: String
            if snapshot.activity == .afterWaiting {
                reason = "主线程刚被唤醒后迟迟没有离开事件处理入口，常见于事件回调/主队列任务/锁等待阻塞。"
            } else {
                reason = "主线程停留在 BeforeSources，说明 sources / 主线程任务 / 业务代码执行过久。"
            }

            let record = StallRecord(activity: snapshot.activity, duration: snapshot.elapsed, reason: reason)
            onStallRecord?(record)
            onLog?("stall suspected: \(Self.activityDescription(snapshot.activity)) \(Int(snapshot.elapsed * 1000))ms")
        } else if snapshot.activity == .beforeWaiting {
            // BeforeWaiting 往往意味着这一轮事情已经做完，RunLoop 正准备休眠。
            // 所以这里通常不把它判成卡顿，只记一条“当前更像空闲态”的提示日志。
            let now = CFAbsoluteTimeGetCurrent()
            if now - lastLoggedIdleTimeoutTime > 0.5 {
                lastLoggedIdleTimeoutTime = now
                onLog?("超时发生在 BeforeWaiting，通常说明主线程 RunLoop 更像是空闲待休眠，而不是发生了真正卡顿")
            }
        }
    }

    static func activityDescription(_ activity: CFRunLoopActivity) -> String {
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

    static func isImportantActivity(_ activity: CFRunLoopActivity) -> Bool {
        activity == .afterWaiting || activity == .beforeSources || activity == .beforeWaiting
    }
}
