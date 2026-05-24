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
        while isMonitoring {
            let result = semaphore.wait(timeout: .now() + timeoutInterval)
            guard isMonitoring else { break }
            guard result == .timedOut else { continue }

            let snapshot = currentSnapshot()
            processTimeout(snapshot)
        }
    }

    private func currentSnapshot() -> (activity: CFRunLoopActivity, elapsed: TimeInterval) {
        lock.lock()
        let activity = lastActivity
        let elapsed = CFAbsoluteTimeGetCurrent() - lastActivityTime
        lock.unlock()
        return (activity, elapsed)
    }

    private func processTimeout(_ snapshot: (activity: CFRunLoopActivity, elapsed: TimeInterval)) {
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
            let now = CFAbsoluteTimeGetCurrent()
            if now - lastLoggedIdleTimeoutTime > 0.5 {
                lastLoggedIdleTimeoutTime = now
                onLog?("timeout while activity = BeforeWaiting, usually means main run loop is idle instead of stuck")
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
