//
//  SourceOnlyLoggerLab.swift
//  test-runloop-demo
//
//  Created by Codex on 2026/6/1.
//

import Foundation

private func sourceOnlyLoggerPerformCallback(_ info: UnsafeMutableRawPointer?) {
    guard let info else { return }
    let lab = Unmanaged<SourceOnlyLoggerLab>.fromOpaque(info).takeUnretainedValue()
    lab.performPendingLogFlush()
}

final class SourceOnlyLoggerLab {

    var onLog: ((String) -> Void)?
    var onStatusChange: ((String) -> Void)?

    private let lock = NSLock()
    private var workerThread: Thread?
    private var workerRunLoop: CFRunLoop?
    private var workerSource: CFRunLoopSource?
    private var workerObserver: CFRunLoopObserver?
    private var shouldKeepRunning = false
    private var pendingEvents: [String] = []
    private var eventSerial = 0
    private var flushedEventCount = 0
    private var logFileURL: URL?

    deinit {
        stop()
    }

    func startIfNeeded() {
        lock.lock()
        if workerThread != nil {
            lock.unlock()
            emitLog("source-only logger 已经启动，无需重复 start")
            return
        }
        shouldKeepRunning = true
        lock.unlock()

        let started = DispatchSemaphore(value: 0)
        let thread = Thread { [weak self] in
            self?.runWorkerThread(started: started)
        }
        thread.name = "source.only.logger.worker"

        lock.lock()
        workerThread = thread
        lock.unlock()

        thread.start()
        started.wait()
    }

    func stop() {
        lock.lock()
        let runLoop = workerRunLoop
        let source = workerSource
        let hasThread = workerThread != nil
        shouldKeepRunning = false
        lock.unlock()

        guard hasThread, let runLoop, let source else {
            emitLog("source-only logger 还没启动")
            return
        }

        emitLog("主线程请求停止 source-only logger：signal Source0 + wakeUp")
        CFRunLoopSourceSignal(source)
        CFRunLoopWakeUp(runLoop)
    }

    func enqueueDemoEvents(count: Int, wakeUp: Bool) {
        lock.lock()
        let runLoop = workerRunLoop
        let source = workerSource
        guard runLoop != nil, source != nil else {
            lock.unlock()
            emitLog("source-only logger 还没准备好，请先启动")
            return
        }

        let newEvents = makeEvents(count: count)
        pendingEvents.append(contentsOf: newEvents)
        let pendingCount = pendingEvents.count
        lock.unlock()

        emitLog("主线程收集 \(newEvents.count) 条业务日志，压入待写队列；pending = \(pendingCount)")
        CFRunLoopSourceSignal(source)

        if wakeUp, let runLoop {
            emitLog("已 signal Source0，并调用 CFRunLoopWakeUp：worker 会尽快批量落盘")
            CFRunLoopWakeUp(runLoop)
        } else {
            emitLog("这里只 signal Source0，不 wakeUp：如果 worker 正在休眠，日志会先堆在队列里")
        }
    }

    func currentLogFilePath() -> String {
        lock.lock()
        let path = logFileURL?.path ?? "nil"
        lock.unlock()
        return path
    }

    fileprivate func performPendingLogFlush() {
        lock.lock()
        let events = pendingEvents
        pendingEvents.removeAll()
        let shouldStop = !shouldKeepRunning
        let fileURL = logFileURL
        lock.unlock()

        if events.isEmpty {
            emitLog("worker Source0 callback 执行：没有待写日志")
        } else if let fileURL {
            append(events: events, to: fileURL)
            lock.lock()
            flushedEventCount += events.count
            let total = flushedEventCount
            lock.unlock()
            emitLog("worker 批量写入 \(events.count) 条日志，总计 \(total) 条，文件：\(fileURL.lastPathComponent)")
        }

        if shouldStop {
            emitLog("source-only worker 收到停止请求，调用 CFRunLoopStop")
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }

    private func runWorkerThread(started: DispatchSemaphore) {
        Thread.current.name = "source.only.logger.worker"

        guard let runLoop = CFRunLoopGetCurrent() else {
            emitStatus("启动失败：CFRunLoopGetCurrent() 返回 nil")
            emitLog("source-only worker 无法获取当前线程 RunLoop，线程退出")
            started.signal()
            return
        }
        prepareLogFile()
        installObserver(on: runLoop)
        installSource(on: runLoop)

        lock.lock()
        workerRunLoop = runLoop
        lock.unlock()

        emitStatus("已启动：只添加自定义 Source0，不添加 Port")
        emitLog("source-only worker 进入 while + run(mode:before:)；线程会睡眠等待 Source0 被 signal+wake")
        started.signal()

        while shouldContinueRunning() &&
            RunLoop.current.run(mode: .default, before: .distantFuture) {
            emitLog("source-only worker 本次 run 返回；如果还没 stop，就继续下一次 run")
        }

        cleanup(runLoop: runLoop)
        emitStatus("已停止")
        emitLog("source-only worker 线程退出")
    }

    private func installSource(on runLoop: CFRunLoop) {
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
            perform: sourceOnlyLoggerPerformCallback
        )

        let source = CFRunLoopSourceCreate(nil, 0, &context)
        workerSource = source
        if let source {
            CFRunLoopAddSource(runLoop, source, .defaultMode)
            emitLog("已把自定义 Source0 加入 worker RunLoop.default；没有添加 Port")
        }
    }

    private func installObserver(on runLoop: CFRunLoop) {
        let activities = CFRunLoopActivity.beforeSources.rawValue |
            CFRunLoopActivity.beforeWaiting.rawValue |
            CFRunLoopActivity.afterWaiting.rawValue |
            CFRunLoopActivity.exit.rawValue

        let observer = CFRunLoopObserverCreateWithHandler(
            kCFAllocatorDefault,
            activities,
            true,
            0
        ) { [weak self] _, activity in
            guard let self else { return }
            switch activity {
            case .beforeSources:
                self.emitLog("source-only 状态：BeforeSources，准备处理 Source0 callback")
            case .beforeWaiting:
                self.emitLog("source-only 状态：BeforeWaiting，线程准备休眠")
            case .afterWaiting:
                self.emitLog("source-only 状态：AfterWaiting，线程被唤醒")
            case .exit:
                self.emitLog("source-only 状态：Exit")
            default:
                break
            }
        }

        workerObserver = observer
        if let observer {
            CFRunLoopAddObserver(runLoop, observer, .defaultMode)
        }
    }

    private func prepareLogFile() {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ??
            URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let directory = baseURL.appendingPathComponent("RunLoopSourceOnlyLogger", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory.appendingPathComponent("source-only-worker.log")
        let header = "\n--- source-only logger start \(timestamp()) ---\n"
        if let data = header.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                append(data: data, to: fileURL)
            } else {
                try? data.write(to: fileURL)
            }
        }

        lock.lock()
        logFileURL = fileURL
        lock.unlock()
        emitLog("日志文件准备完成：\(fileURL.path)")
    }

    private func append(events: [String], to fileURL: URL) {
        let text = events.map { "\($0)\n" }.joined()
        guard let data = text.data(using: .utf8) else { return }
        append(data: data, to: fileURL)
    }

    private func append(data: Data, to fileURL: URL) {
        if FileManager.default.fileExists(atPath: fileURL.path),
           let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            try? data.write(to: fileURL)
        }
    }

    private func makeEvents(count: Int) -> [String] {
        (0..<count).map { index in
            eventSerial += 1
            return "[\(timestamp())] event_id=\(eventSerial) page=RunLoopDemo action=tap index=\(index)"
        }
    }

    private func cleanup(runLoop: CFRunLoop) {
        if let observer = workerObserver {
            CFRunLoopRemoveObserver(runLoop, observer, .defaultMode)
        }

        if let source = workerSource {
            CFRunLoopRemoveSource(runLoop, source, .defaultMode)
            CFRunLoopSourceInvalidate(source)
        }

        lock.lock()
        workerObserver = nil
        workerSource = nil
        workerRunLoop = nil
        workerThread = nil
        pendingEvents.removeAll()
        lock.unlock()
    }

    private func shouldContinueRunning() -> Bool {
        lock.lock()
        let result = shouldKeepRunning
        lock.unlock()
        return result
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

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
