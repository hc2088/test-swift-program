//
//  ViewController.swift
//  test-gcd
//
//  Created by huchu on 2025/5/19.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // 启动测试
        runAllTests()
//
//        // 保证 Playground 或命令行能看到异步输出
//        RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))

    }


}

 
 

func log(_ label: String) {
    print("[\(label)] current thread: \(Thread.current)")
}

func testGCDBehaviors(context: String) {
    print("\n==== Begin GCD Test in \(context) ====， current thread: \(Thread.current)\n")
    
    let serialQueue = DispatchQueue(label: "com.example.serialQueue")
    serialQueue.async {
        log("\(context) - ① Serial + Async")
    }

    let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue", attributes: .concurrent)
    concurrentQueue.async {
        log("\(context) - ② Concurrent + Async")
    }

    let serialQueueSync = DispatchQueue(label: "com.example.serialQueueSync")
    serialQueueSync.sync {
        log("\(context) - ③ Serial + Sync")
    }

    let concurrentQueueSync = DispatchQueue(label: "com.example.concurrentQueueSync", attributes: .concurrent)
    concurrentQueueSync.sync {
        log("\(context) - ④ Concurrent + Sync")
    }

    print("\n==== End GCD Test in \(context) ====\n")
}

func runAllTests() {
    // 1️⃣ 主线程中调用
//    testGCDBehaviors(context: "Main Thread")

//    // 2️⃣ 在串行队列中调用
//    let outerSerialQueue = DispatchQueue(label: "com.example.outerSerialQueue")
//    outerSerialQueue.async {
//        testGCDBehaviors(context: "Serial Queue")
//    }
//
    // 3️⃣ 在并发队列中调用
    let outerConcurrentQueue = DispatchQueue(label: "com.example.outerConcurrentQueue", attributes: .concurrent)
    outerConcurrentQueue.async {
        testGCDBehaviors(context: "Concurrent Queue")
    }
}

//结论：无论当前所属什么样的线程还是目标队列是什么队列
//同步提交 不切换线程 
//异步提交，切换线程。
