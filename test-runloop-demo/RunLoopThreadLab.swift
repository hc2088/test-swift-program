//
//  RunLoopThreadLab.swift
//  test-runloop-demo
//
//  Created by Codex on 2026/5/24.
//

import Foundation

private func source0PerformCallback(_ info: UnsafeMutableRawPointer?) {
    guard let info else { return }
    let lab = Unmanaged<RunLoopThreadLab>.fromOpaque(info).takeUnretainedValue()
    lab.performSource0Messages()
}

final class RunLoopThreadLab: NSObject, PortDelegate {

    struct StateRecord {
        let activity: CFRunLoopActivity
        let description: String
    }

    var onLog: ((String) -> Void)?
    var onStateChange: ((StateRecord) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let lock = NSLock()

    private var workerThread: Thread?
    private var workerRunLoop: CFRunLoop?
    private var workerSource0: CFRunLoopSource?
    private var workerObserver: CFRunLoopObserver?
    private var workerPort: Port?
    private var shouldKeepRunLoopAlive = false
    private var pendingSource0Messages: [String] = []
    private var timerSerial = 0

    deinit {
        stop()
    }

    func startIfNeeded() {
        lock.lock()
        if workerThread != nil {
            lock.unlock()
            emitLog("worker RunLoop 已经启动，无需重复 start")
            return
        }
        shouldKeepRunLoopAlive = true
        lock.unlock()

        let started = DispatchSemaphore(value: 0)
        let thread = Thread { [weak self] in
            self?.runWorkerThread(started: started)
        }
        thread.name = "worker.runloop.demo"

        lock.lock()
        workerThread = thread
        lock.unlock()

        thread.start()
        started.wait()
    }

    func stop() {
        lock.lock()
        let runLoop = workerRunLoop
        let hasThread = workerThread != nil
        shouldKeepRunLoopAlive = false
        lock.unlock()

        guard hasThread, let runLoop else { return }

        emitLog("主线程请求停止 worker RunLoop")
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
            guard let self else { return }
            self.emitLog("worker 线程收到 stop 请求，准备调用 CFRunLoopStop")
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        CFRunLoopWakeUp(runLoop)
    }

    func triggerSource0(signalOnly: Bool) {
        lock.lock()
        let runLoop = workerRunLoop
        let source = workerSource0
        let message = "source0-message-\(timestamp())"
        pendingSource0Messages.append(message)
        lock.unlock()

        guard let runLoop, let source else {
            emitLog("Source0 还没准备好，请先启动 worker RunLoop")
            return
        }

        emitLog("主线程调用 CFRunLoopSourceSignal，压入消息：\(message)")
        CFRunLoopSourceSignal(source)

        if signalOnly {
            emitLog("这里只 signal，不 wakeUp。若 worker 线程已经休眠，消息不会马上执行。")
        } else {
            emitLog("signal 完成立刻调用 CFRunLoopWakeUp，让 worker 从休眠中醒来。")
            CFRunLoopWakeUp(runLoop)
        }
    }

    func sendPortMessage() {
        lock.lock()
        let port = workerPort
        lock.unlock()

        guard let port else {
            emitLog("Port(Source1) 还没准备好，请先启动 worker RunLoop")
            return
        }

        let payload = "port-message-\(timestamp())"
        let components = NSMutableArray(object: Data(payload.utf8))
        let success = port.send(
            before: Date().addingTimeInterval(1.0),
            msgid: 1001,
            components: components,
            from: nil,
            reserved: 0
        )
        emitLog("主线程发送 Port 消息(Source1)，success = \(success)")
    }

    func scheduleWorkerTimer() {
        lock.lock()
        let runLoop = workerRunLoop
        timerSerial += 1
        let serial = timerSerial
        lock.unlock()

        guard let runLoop else {
            emitLog("worker RunLoop 还没准备好，请先启动")
            return
        }

        emitLog("主线程通过 CFRunLoopPerformBlock 安排一个 1.5s 后触发的 Timer #\(serial)")
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
            guard let self else { return }

            // 这里的 Timer 由 worker 线程创建并加到它自己的 RunLoop 上，
            // 所以真正的回调也会发生在 worker 线程。
            let timer = Timer(timeInterval: 1.5, repeats: false) { [weak self] _ in
                self?.emitLog("worker Timer #\(serial) fired，说明 BeforeTimers -> Timer 回调这条链路跑通了")
            }
            RunLoop.current.add(timer, forMode: .default)
            self.emitLog("worker 线程已把 Timer #\(serial) 加入 RunLoop.default")
        }
        CFRunLoopWakeUp(runLoop)
    }

    func scheduleRunLoopBlock() {
        lock.lock()
        let runLoop = workerRunLoop
        lock.unlock()

        guard let runLoop else {
            emitLog("worker RunLoop 还没准备好，请先启动")
            return
        }

        emitLog("主线程调用 CFRunLoopPerformBlock，向 worker RunLoop 投递一个 block")
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
            self?.emitLog("worker RunLoop 执行了一个 block。这里的 block 指的是 CFRunLoopPerformBlock 投递的任务。")
        }
        CFRunLoopWakeUp(runLoop)
    }

    private func runWorkerThread(started: DispatchSemaphore) {
        Thread.current.name = "worker.runloop.demo"

        let runLoop = RunLoop.current
        guard let cfRunLoop = CFRunLoopGetCurrent() else {
            emitStatus("worker RunLoop 创建失败")
            emitLog("CFRunLoopGetCurrent() 返回 nil，线程直接退出")
            started.signal()
            return
        }

        lock.lock()
        workerRunLoop = cfRunLoop
        lock.unlock()

        installObserver(on: cfRunLoop)
        installSource0(on: cfRunLoop)
        installPort(on: runLoop)

        emitStatus("worker RunLoop 已启动：使用 Port 保活，Source0/Source1/Timer/block 都可投递")
        emitLog("worker 线程开始进入 run(mode:before:) 循环")
        started.signal()

        // 这里就是整个 demo 最关键的一行：
        // 线程真正进入 RunLoop 工作循环，开始经历 Entry / BeforeTimers /
        // BeforeSources / BeforeWaiting / AfterWaiting / Exit 这些状态。
        while shouldContinueRunning() &&
            runLoop.run(mode: .default, before: .distantFuture) {
            emitLog("一次 run(mode:before:) 返回；如果 shouldKeepRunLoopAlive 仍为 true，就继续下一轮")
        }

        cleanupWorkerRunLoop(runLoop: runLoop, cfRunLoop: cfRunLoop)
        emitStatus("worker RunLoop 已停止")
        emitLog("worker 线程退出")
    }

    private func installObserver(on runLoop: CFRunLoop) {
        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            CFRunLoopActivity.allActivities.rawValue,
            true,
            0
        ) { [weak self] _, activity in
            guard let self else { return }
            let description = Self.activityDescription(activity)
            self.emitStateChange(StateRecord(activity: activity, description: description))
            self.emitLog("状态变化 -> \(description)")
        }

        workerObserver = observer
        CFRunLoopAddObserver(runLoop, observer, .defaultMode)
    }

    private func installSource0(on runLoop: CFRunLoop) {
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
            perform: source0PerformCallback
        )

        let source = CFRunLoopSourceCreate(nil, 0, &context)
        workerSource0 = source
        if let source {
            CFRunLoopAddSource(runLoop, source, .defaultMode)
            emitLog("已把自定义 Source0 加入 worker RunLoop.default")
        }
    }

    private func installPort(on runLoop: RunLoop) {
        // Port 既有两个作用：
        // 1. 作为 port-based input source，帮助保活当前 mode
        // 2. 作为 Source1 示例，主线程可以主动发消息进来
        let port = Port()
        port.setDelegate(self)
        runLoop.add(port, forMode: .default)

        lock.lock()
        workerPort = port
        lock.unlock()

        emitLog("已把 Port(Source1) 加入 worker RunLoop.default，后续可接收 Port 消息")
    }

    fileprivate func performSource0Messages() {
        lock.lock()
        let messages = pendingSource0Messages
        pendingSource0Messages.removeAll()
        lock.unlock()

        emitLog("worker Source0 perform callback 执行，拿到消息：\(messages)")
    }

    private func cleanupWorkerRunLoop(runLoop: RunLoop, cfRunLoop: CFRunLoop) {
        if let observer = workerObserver {
            CFRunLoopRemoveObserver(cfRunLoop, observer, .defaultMode)
        }

        if let source = workerSource0 {
            CFRunLoopRemoveSource(cfRunLoop, source, .defaultMode)
        }

        if let port = workerPort {
            port.remove(from: runLoop, forMode: .default)
            port.invalidate()
        }

        lock.lock()
        workerObserver = nil
        workerSource0 = nil
        workerPort = nil
        workerRunLoop = nil
        workerThread = nil
        pendingSource0Messages.removeAll()
        lock.unlock()
    }

    private func shouldContinueRunning() -> Bool {
        lock.lock()
        let result = shouldKeepRunLoopAlive
        lock.unlock()
        return result
    }

    // NSPortDelegate 是 Objective-C optional 协议方法。
    // 这里直接按 selector 名实现 handlePortMessage:，参数用 Any 接住，
    // 这样能稳定收到回调，同时避免 Swift 对 NSPortMessage 类型导出不完整的问题。
    @objc(handlePortMessage:)
    func handlePortMessageSelector(_ message: Any) {
        let object = message as AnyObject
        let payloadData = object.value(forKey: "components").flatMap { ($0 as? [Any])?.first as? Data }
        let payload = payloadData.flatMap { String(data: $0, encoding: .utf8) } ?? "nil"
        let msgid = object.value(forKey: "msgid") as? NSNumber
        emitLog("worker 收到 Port 消息(Source1)，msgid = \(msgid?.intValue ?? -1)，payload = \(payload)")
    }

    private func emitLog(_ text: String) {
        let line = "[\(timestamp())] \(text)"
        DispatchQueue.main.async { [weak self] in
            self?.onLog?(line)
        }
    }

    private func emitStatus(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChange?(text)
        }
    }

    private func emitStateChange(_ record: StateRecord) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(record)
        }
    }

    static func activityDescription(_ activity: CFRunLoopActivity) -> String {
        switch activity {
        case .entry:
            return "Entry：进入本轮 RunLoop"
        case .beforeTimers:
            return "BeforeTimers：准备检查 Timer"
        case .beforeSources:
            return "BeforeSources：准备处理 Source0 / block"
        case .beforeWaiting:
            return "BeforeWaiting：本轮暂时没事，准备休眠"
        case .afterWaiting:
            return "AfterWaiting：线程刚从休眠中醒来"
        case .exit:
            return "Exit：当前这次 RunLoop 退出"
        default:
            return "Unknown(\(activity.rawValue))"
        }
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
