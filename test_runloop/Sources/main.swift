import Foundation

final class SelectorReceiver: NSObject {
    let caseName: String
    private let lock = NSLock()
    private(set) var receivedMessages: [String] = []
    var shouldStopRunLoopAfterHandling = false
    var shouldKeepRunLoopAlive = true

    init(caseName: String) {
        self.caseName = caseName
    }

    @objc func receiveMessage(_ payload: Any?) {
        let message = payload as? String ?? "nil"
        lock.lock()
        receivedMessages.append(message)
        lock.unlock()

        print("[\(caseName)] selector executed on thread: \(Thread.current.name ?? "unnamed") payload: \(message)")

        if shouldStopRunLoopAfterHandling {
            shouldKeepRunLoopAlive = false
            print("[\(caseName)] stopping current run loop after handling selector")
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
}

final class Source0Box {
    let caseName: String
    let started = DispatchSemaphore(value: 0)
    let handled = DispatchSemaphore(value: 0)
    let finished = DispatchSemaphore(value: 0)

    private let lock = NSLock()
    private(set) var pendingMessages: [String] = []
    private(set) var handledMessages: [String] = []

    var runLoop: CFRunLoop?
    var source: CFRunLoopSource?
    var shouldStopAfterPerform = false
    var shouldKeepRunLoopAlive = true

    init(caseName: String) {
        self.caseName = caseName
    }

    func enqueue(_ message: String) {
        lock.lock()
        pendingMessages.append(message)
        lock.unlock()
    }

    func flushPendingMessages() -> [String] {
        lock.lock()
        let messages = pendingMessages
        pendingMessages.removeAll()
        handledMessages.append(contentsOf: messages)
        lock.unlock()
        return messages
    }

    func hasHandledMessages() -> Bool {
        lock.lock()
        let result = !handledMessages.isEmpty
        lock.unlock()
        return result
    }
}

enum RunLoopKeepAliveStrategy: String {
    case port = "Port"
    case timer = "Timer"
}

func threadName(_ thread: Thread) -> String {
    thread.name ?? "unnamed"
}

func separator(_ title: String) {
    print("")
    print("==================================================")
    print(title)
    print("==================================================")
}

// MARK: - Selector / performSelector(onThread:) demo

func scheduleSelector(
    receiver: SelectorReceiver,
    on thread: Thread,
    payload: String,
    caseName: String
) {
    print("[\(caseName)] main thread schedules selector onto \(threadName(thread))")
    receiver.perform(
        #selector(SelectorReceiver.receiveMessage(_:)),
        on: thread,
        with: payload,
        waitUntilDone: false
    )
}

func runCaseWithoutTouchingRunLoop() {
    let caseName = "Case 1: 子线程不取 RunLoop"
    separator(caseName)

    // 用信号量确保主线程知道：子线程已经真正启动。
    let started = DispatchSemaphore(value: 0)
    // 用信号量等待子线程自然结束，方便最后统一打印结果。
    let finished = DispatchSemaphore(value: 0)
    // receiver 是真正接收 selector 的对象。
    let receiver = SelectorReceiver(caseName: caseName)

    let workerThread = Thread {
        Thread.current.name = "worker.no.runloop"
        // 这个 case 的关键就是：线程虽然活着，但完全不碰 RunLoop。
        // 也就是说，这条线程不会进入 runloop.png 里的那套循环：
        // 不会 Entry -> BeforeTimers -> BeforeSources -> BeforeWaiting -> AfterWaiting。
        print("[\(caseName)] thread started, only sleep, never touches RunLoop")
        // 告诉主线程：子线程已经启动完成，可以往这条线程投递 selector 了。
        started.signal()
        // 子线程只是单纯 sleep，模拟“线程活着，但没有 RunLoop 事件循环”。
        Thread.sleep(forTimeInterval: 1.0)
        // 线程直接结束，从头到尾都没有进入 RunLoop。
        print("[\(caseName)] thread finished without ever running a RunLoop")
        finished.signal()
    }
    workerThread.name = "worker.no.runloop"
    workerThread.start()

    // 等子线程启动后，再往它上面 perform selector。
    started.wait()
    scheduleSelector(receiver: receiver, on: workerThread, payload: "task-no-runloop", caseName: caseName)

    // 主线程多等一会儿，给 selector 一个“理论上可能执行”的时间窗口。
    // 但因为目标线程没有 RunLoop，这个 selector 实际不会被处理。
    Thread.sleep(forTimeInterval: 1.2)
    finished.wait()
    // 结果为空，证明“线程活着”不等于“performSelector(onThread:) 可执行”。
    print("[\(caseName)] receivedMessages = \(receiver.receivedMessages)")
}

func runCaseOnlyCreatingRunLoopObject() {
    let caseName = "Case 2: 子线程取到 RunLoop 但不运行"
    separator(caseName)

    // started / finished 仍然只是用来协调主线程和子线程的实验时序。
    let started = DispatchSemaphore(value: 0)
    let finished = DispatchSemaphore(value: 0)
    let receiver = SelectorReceiver(caseName: caseName)

    let workerThread = Thread {
        Thread.current.name = "worker.runloop.created.only"
        // 这里故意只“拿到 RunLoop 对象”。
        // 这一步相当于知道这条线程可以拥有 RunLoop，但还没有真正把它 run 起来。
        let runLoop = RunLoop.current
        // 注意：拿到 RunLoop.current != 进入 RunLoop 循环。
        // 这时仍然没有真正进入 runloop.png 那张图里的各个状态流转。
        print("[\(caseName)] thread touched RunLoop.current = \(runLoop), but will not run it")
        started.signal()
        // 仍然只是 sleep，不调用 run() / run(mode:before:)。
        Thread.sleep(forTimeInterval: 1.0)
        // 所以虽然对象存在，但 RunLoop 从未真正开始处理 source / timer / selector。
        print("[\(caseName)] thread finished, RunLoop object existed but never entered run()")
        finished.signal()
    }
    workerThread.name = "worker.runloop.created.only"
    workerThread.start()

    // 等子线程准备好之后，尝试向它投递 selector。
    started.wait()
    scheduleSelector(receiver: receiver, on: workerThread, payload: "task-created-not-running", caseName: caseName)

    // 留出足够时间观察：仅仅拥有 RunLoop 对象，selector 仍然不会自动执行。
    Thread.sleep(forTimeInterval: 1.2)
    finished.wait()
    // 结果依旧为空，证明关键不是“有没有 RunLoop 对象”，而是“RunLoop 有没有真的 run”。
    print("[\(caseName)] receivedMessages = \(receiver.receivedMessages)")
}

func runCaseRunningRunLoop() {
    let caseName = "Case 3: 子线程运行 RunLoop"
    separator(caseName)

    let started = DispatchSemaphore(value: 0)
    let finished = DispatchSemaphore(value: 0)
    let receiver = SelectorReceiver(caseName: caseName)
    receiver.shouldStopRunLoopAfterHandling = true

    let workerThread = Thread {
        Thread.current.name = "worker.runloop.running"

        // 这里只是拿到当前线程对应的 RunLoop 对象。
        // 真正“把 RunLoop 跑起来”是在下面的 while + run(mode:before:)。
        let runLoop = RunLoop.current

        // 给 RunLoop 加一个 Port，用来提供一个可等待的 input source。
        // 如果什么 source / timer 都没有，run(mode:before:) 可能很快直接返回，
        // 就无法形成一个稳定的事件循环。
        runLoop.add(Port(), forMode: .default)
        print("[\(caseName)] thread prepared a RunLoop and entered run loop")
        started.signal()

        // 下面这个 while 可以把它理解成“线程常驻的消息循环外壳”。
        // 每次调用 run(mode:before:)，都会让当前线程的 RunLoop 在 default mode
        // 下跑完一轮或若干步，直到这次 mode run 结束后再返回到 while 判断。
        //
        // 对照 runloop.png，这里一轮 RunLoop 大致会经历：
        // 1. Entry：进入本轮循环
        // 2. BeforeTimers：准备检查 Timer
        // 3. BeforeSources：准备处理 Source0
        // 4. 处理可执行事件：
        //    - 如果当前轮有 performSelector(onThread:) 对应的任务到达，
        //      可以把它近似理解成“有事件要在这条线程上执行”
        // 5. BeforeWaiting：如果暂时没更多事可做，就准备休眠
        // 6. AfterWaiting：当新的事件把线程唤醒后，从这里继续
        // 7. 再次进入 BeforeTimers / BeforeSources，处理新到达的事件
        // 8. Exit：当 CFRunLoopStop 或当前 mode run 结束时，退出这次 run(...)
        //
        // 这里的 run(mode:before:) 不是“立刻执行完所有未来任务”，
        // 而是让当前线程真正进入一次完整的 RunLoop 工作流程。
        while receiver.shouldKeepRunLoopAlive &&
            runLoop.run(mode: .default, before: .distantFuture) {
            // 这次 run(mode:before:) 返回，说明当前这次 mode run 结束了。
            // 如果 shouldKeepRunLoopAlive 仍然为 true，while 会再次进入下一轮 RunLoop。
        }

        // 当 receiveMessage(_:) 里调用 CFRunLoopStop(CFRunLoopGetCurrent()) 后，
        // 当前这次 run(mode:before:) 会结束，while 也会因为 shouldKeepRunLoopAlive
        // 被置为 false 而退出，线程随之结束。
        print("[\(caseName)] run loop stopped and thread will exit")
        finished.signal()
    }
    workerThread.name = "worker.runloop.running"
    workerThread.start()

    started.wait()
    scheduleSelector(receiver: receiver, on: workerThread, payload: "task-runloop-running", caseName: caseName)

    finished.wait()
    print("[\(caseName)] receivedMessages = \(receiver.receivedMessages)")
}

func runCaseRunningRunLoopWithTimerKeepAlive() {
    let caseName = "Case 4: 子线程运行 RunLoop（用 Timer 保活）"
    separator(caseName)

    let started = DispatchSemaphore(value: 0)
    let finished = DispatchSemaphore(value: 0)
    let receiver = SelectorReceiver(caseName: caseName)
    receiver.shouldStopRunLoopAfterHandling = true

    let workerThread = Thread {
        Thread.current.name = "worker.runloop.running.timer"
        let runLoop = RunLoop.current

        // 这里不用 Port，而是放一个重复 Timer 作为保活手段。
        // 目的不是依赖 Timer 来执行 selector，而是证明：
        // “让 RunLoop 所在 mode 有东西可持续等待/处理”这件事，不只有 Port 一种实现。
        let keepAliveTimer = Timer(timeInterval: 10.0, repeats: true) { _ in
            print("[\(caseName)] keep-alive timer fired")
        }
        runLoop.add(keepAliveTimer, forMode: .default)

        print("[\(caseName)] thread prepared a RunLoop with a keep-alive timer and entered run loop")
        started.signal()

        while receiver.shouldKeepRunLoopAlive &&
            runLoop.run(mode: .default, before: .distantFuture) {
        }

        keepAliveTimer.invalidate()
        print("[\(caseName)] run loop stopped and thread will exit")
        finished.signal()
    }
    workerThread.name = "worker.runloop.running.timer"
    workerThread.start()

    started.wait()
    scheduleSelector(receiver: receiver, on: workerThread, payload: "task-runloop-running-timer", caseName: caseName)

    finished.wait()
    print("[\(caseName)] receivedMessages = \(receiver.receivedMessages)")
}

func runSelectorDemo() {
    separator("performSelector(onThread:) demo")
    print("main thread: \(Thread.current)")
    runCaseWithoutTouchingRunLoop()
    runCaseOnlyCreatingRunLoopObject()
    runCaseRunningRunLoop()
    runCaseRunningRunLoopWithTimerKeepAlive()

    separator("performSelector 结论")
    print("1. 子线程既不获取也不运行 RunLoop 时，performSelector(onThread:) 不会执行。")
    print("2. 仅仅取到 RunLoop.current 还不够；如果 RunLoop 没有真正 run 起来，selector 仍然不会执行。")
    print("3. 只有目标线程的 RunLoop 真正在跑，并且能处理对应 source 时，performSelector(onThread:) 才会执行。")
    print("4. 让 RunLoop 常驻的方式不只有 Port；重复 Timer 也可以让当前 mode 保持可运行。")
}

// MARK: - Source0 demo

private func source0ScheduleCallback(
    _ info: UnsafeMutableRawPointer?,
    _ runLoop: CFRunLoop?,
    _ mode: CFRunLoopMode?
) {
    guard let info else { return }
    let box = Unmanaged<Source0Box>.fromOpaque(info).takeUnretainedValue()
    let modeDescription = mode.map { String(describing: $0) } ?? "unknown"
    print("[\(box.caseName)] Source0 scheduled on run loop, mode = \(modeDescription)")
}

private func source0CancelCallback(
    _ info: UnsafeMutableRawPointer?,
    _ runLoop: CFRunLoop?,
    _ mode: CFRunLoopMode?
) {
    guard let info else { return }
    let box = Unmanaged<Source0Box>.fromOpaque(info).takeUnretainedValue()
    let modeDescription = mode.map { String(describing: $0) } ?? "unknown"
    print("[\(box.caseName)] Source0 canceled from run loop, mode = \(modeDescription)")
}

private func source0PerformCallback(_ info: UnsafeMutableRawPointer?) {
    guard let info else { return }
    let box = Unmanaged<Source0Box>.fromOpaque(info).takeUnretainedValue()
    let messages = box.flushPendingMessages()
    print("[\(box.caseName)] Source0 perform callback executed on thread: \(Thread.current.name ?? "unnamed")")
    print("[\(box.caseName)] handled messages = \(messages)")
    box.handled.signal()

    if box.shouldStopAfterPerform {
        box.shouldKeepRunLoopAlive = false
        if let runLoop = box.runLoop {
            print("[\(box.caseName)] stop run loop after Source0 perform")
            CFRunLoopStop(runLoop)
        }
    }
}

func makeSource0Thread(
    for box: Source0Box,
    threadName: String,
    keepAliveStrategy: RunLoopKeepAliveStrategy = .port
) -> Thread {
    let thread = Thread {
        Thread.current.name = threadName
        let runLoop = RunLoop.current
        box.runLoop = CFRunLoopGetCurrent()

        var context = CFRunLoopSourceContext(
            version: 0,
            info: Unmanaged.passUnretained(box).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil,
            equal: nil,
            hash: nil,
            schedule: source0ScheduleCallback,
            cancel: source0CancelCallback,
            perform: source0PerformCallback
        )

        let source = CFRunLoopSourceCreate(nil, 0, &context)!
        box.source = source
        CFRunLoopAddSource(box.runLoop, source, .defaultMode)

        var keepAliveTimer: Timer?
        switch keepAliveStrategy {
        case .port:
            // 最常见的常驻线程保活方式：放一个 Port 进当前 mode。
            runLoop.add(Port(), forMode: .default)
            print("[\(box.caseName)] worker thread created Source0 and uses Port to keep the run loop alive")
        case .timer:
            // 另一种保活方式：放一个重复 Timer 进当前 mode。
            // 这里同样不是靠 Timer 来执行 Source0，而是证明：
            // Port 不是唯一的“让这个 mode 保持活着”的选择。
            let timer = Timer(timeInterval: 10.0, repeats: true) { _ in
                print("[\(box.caseName)] keep-alive timer fired")
            }
            runLoop.add(timer, forMode: .default)
            keepAliveTimer = timer
            print("[\(box.caseName)] worker thread created Source0 and uses Timer to keep the run loop alive")
        }

        print("[\(box.caseName)] worker thread entered run loop")
        box.started.signal()

        while box.shouldKeepRunLoopAlive &&
            runLoop.run(mode: .default, before: .distantFuture) {
        }

        keepAliveTimer?.invalidate()
        if let runLoop = box.runLoop, let source = box.source {
            CFRunLoopRemoveSource(runLoop, source, .defaultMode)
        }
        print("[\(box.caseName)] worker thread exits")
        box.finished.signal()
    }
    thread.name = threadName
    return thread
}

func runSource0CaseWithoutWakeUp() {
    let caseName = "Source0 Case 1: signal 但不 wakeUp"
    separator(caseName)

    let box = Source0Box(caseName: caseName)
    box.shouldStopAfterPerform = true
    let workerThread = makeSource0Thread(for: box, threadName: "worker.source0.no.wakeup")
    workerThread.start()

    box.started.wait()
    guard let source = box.source, let runLoop = box.runLoop else { return }

    box.enqueue("message-needs-wakeup")
    print("[\(caseName)] main thread calls CFRunLoopSourceSignal(source)")
    CFRunLoopSourceSignal(source)

    Thread.sleep(forTimeInterval: 0.6)
    print("[\(caseName)] after 0.6s, hasHandledMessages = \(box.hasHandledMessages())")
    print("[\(caseName)] Source0 still pending because signal itself does not wake the sleeping run loop")

    print("[\(caseName)] now explicitly call CFRunLoopWakeUp(runLoop)")
    CFRunLoopWakeUp(runLoop)

    box.handled.wait()
    box.finished.wait()
}

func runSource0CaseWithWakeUp() {
    let caseName = "Source0 Case 2: signal + wakeUp"
    separator(caseName)

    let box = Source0Box(caseName: caseName)
    box.shouldStopAfterPerform = true
    let workerThread = makeSource0Thread(for: box, threadName: "worker.source0.with.wakeup")
    workerThread.start()

    box.started.wait()
    guard let source = box.source, let runLoop = box.runLoop else { return }

    box.enqueue("message-immediate-handle")
    print("[\(caseName)] main thread calls CFRunLoopSourceSignal(source)")
    CFRunLoopSourceSignal(source)
    print("[\(caseName)] immediately call CFRunLoopWakeUp(runLoop)")
    CFRunLoopWakeUp(runLoop)

    box.handled.wait()
    box.finished.wait()
}

func runSource0CaseWithWakeUpAndTimerKeepAlive() {
    let caseName = "Source0 Case 3: signal + wakeUp（用 Timer 保活）"
    separator(caseName)

    let box = Source0Box(caseName: caseName)
    box.shouldStopAfterPerform = true
    let workerThread = makeSource0Thread(
        for: box,
        threadName: "worker.source0.with.wakeup.timer",
        keepAliveStrategy: .timer
    )
    workerThread.start()

    box.started.wait()
    guard let source = box.source, let runLoop = box.runLoop else { return }

    box.enqueue("message-immediate-handle-timer")
    print("[\(caseName)] main thread calls CFRunLoopSourceSignal(source)")
    CFRunLoopSourceSignal(source)
    print("[\(caseName)] immediately call CFRunLoopWakeUp(runLoop)")
    CFRunLoopWakeUp(runLoop)

    box.handled.wait()
    box.finished.wait()
}

func runSource0Demo() {
    separator("Source0 demo")
    print("Source0 常见场景：")
    print("1. 自定义常驻线程通信，外部线程 signal 一个自定义 CFRunLoopSource。")
    print("2. Cocoa perform selector source 这类“下一个 RunLoop 周期处理”的任务模型。")
    print("3. 某些框架内部把待处理任务包装成 RunLoop source，再在合适时机统一执行。")

//    runSource0CaseWithoutWakeUp()
    runSource0CaseWithWakeUp()
    runSource0CaseWithWakeUpAndTimerKeepAlive()

    separator("Source0 结论")
    print("1. Source0 是非 port-based input source，自己不会把 RunLoop 从休眠中叫醒。")
    print("2. 仅仅 signal Source0 不够；如果 RunLoop 正在睡眠，通常还要配合 CFRunLoopWakeUp。")
    print("3. RunLoop 被唤醒后，才会在后续 Source0 处理阶段执行 perform callback。")
    print("4. Port 不是唯一保活手段；只要当前 mode 里有别的可等待 source / timer，也能让 RunLoop 常驻。")
}

// MARK: - Entry

func printUsage() {
    separator("test_runloop")
    print("用法：")
    print("swift run source0     -> 只跑 Source0 demo")
    print("swift run selector    -> 只跑 performSelector(onThread:) demo")
    print("swift run all         -> 两组 demo 都跑")
    print("不传参数默认跑 source0 demo")
}

let arguments = CommandLine.arguments
let mode = arguments.dropFirst().first ?? "selector"

switch mode {
case "source0":
    runSource0Demo()
case "selector":
    runSelectorDemo()
case "all":
    runSelectorDemo()
    runSource0Demo()
default:
    printUsage()
}
