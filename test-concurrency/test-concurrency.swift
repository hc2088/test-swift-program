//
//  test-concurrency.swift
//  test-concurrency
//
//  Created by huchu on 2025/8/3.
//


//Swift Concurrency：Swift 并发
//
//Structured Concurrency：结构化并发
//
//Actor-based Concurrency：基于 Actor 的并发模型

import Foundation

//actor 是 Swift 5.5 引入的一种引用类型，它专门设计用来解决并发环境下的数据竞争问题（data race）。
//它本质上是“带有内置同步机制的类”，能自动保证其内部状态的访问是线程安全的。


//编译层面：你可以用 Xcode 13+（内置 Swift 5.5）写 actor 代码，理论上在任何 iOS 版本下编译通过。
//
//运行层面：actor 依赖 Swift 并发运行时库，这部分只在 iOS 15+ 系统中内置和支持。
//
//向下兼容：
//
//Swift 官方提供了并发的向后部署支持（back-deployment），通过运行时库动态支持低版本系统，但 actor 和完整的并发功能目前只对 iOS 15+ 正式支持稳定。
//
//在 iOS 13/14 等较低版本上使用并发特性（特别是 actor）可能会出现不兼容或异常。
//实际项目中，使用 actor 时建议将 iOS Deployment Target 设置为 iOS 15 或更高。
//如果需要支持更低版本，必须避免使用 actor，或者使用第三方库模拟同步和线程安全。



//actor和class都是定义类的
//1. 相同点
//都是 引用类型，通过引用传递实例。
//
//都可以有属性、方法、初始化器。
//
//都支持封装逻辑、状态管理。
//
//都不能被值类型（struct）自动继承，必须显式继承（actor 不支持继承，但普通 class 支持）。
//
//都可以实现协议。
//
//2. 不同点（除了同步机制以外）
//| 特性                | `class`              | `actor`                         |
//| ----------------- | -------------------- | ------------------------------- |
//| **线程安全**          | 无内置保护，需手动管理（锁等）      | 内置串行访问队列，保证状态安全访问               |
//| **继承支持**          | 支持                   | 不支持继承                           |
//| **隔离（Isolation）** | 无                    | 其内部状态默认是隔离的，外部访问需异步 `await`     |
//| **方法调用方式**        | 同步调用                 | 对 `actor` 实例调用异步方法需要用 `await`   |
//| **性能开销**          | 轻量                   | 由于异步调度和任务排队，稍有额外开销              |
//| **修饰符支持**         | 支持 `final`, `open` 等 | 只支持 `final`（不支持继承）              |
//| **非隔离成员**         | 无                    | 支持用 `nonisolated` 修饰某些成员，使其同步访问 |
//3. 总结
//| 方面   | 说明                                  |
//| ---- | ----------------------------------- |
//| 核心区别 | `actor` 带有并发隔离和同步机制，保证内部状态线程安全      |
//| 其他区别 | `actor` 不支持继承，调用需要异步，性能稍逊于普通类       |
//| 使用场景 | `actor` 适合多线程共享状态，普通类适合单线程或自行管理线程安全 |



//actor 与 GCD 并发的本质区别
//1. actor 提供 顺序访问保证（data race protection）
//actor 内部的状态是被“隔离”的，Swift 编译器和运行时会保证对 actor 成员的访问是串行的。
//
//所有访问 actor 实例的 async 方法都会被“排队执行”（在内部的队列中），即使是并发调用。
//
//actor 不允许非 async 的外部访问直接操作内部状态。
//
//2. DispatchGroup 是传统的并发机制，不具备访问隔离机制
//如果你用 DispatchGroup 开多个 DispatchQueue.global() 的任务去调用 actor 的方法，会违反 actor 的访问序列保证，Swift 编译器会报错。
//
//更重要的是，如果你试图用 GCD 访问 actor 的非异步方法（或内部变量），会导致数据竞争（data race），甚至崩溃。


//actor 的本质是：
//它内部有一个队列来顺序处理来自外部的请求（类似串行队列，但管理由 Swift 运行时负责）。
//
//每一个 await 的方法调用都会变成一个异步任务，排队进入 actor 的执行队列，一次只处理一个方法调用。
actor BankAccount {
    private var balance: Int = 0
//    balance 是 actor 的私有变量。
//
//    所有通过 await 调用的 deposit 都会被 串行调度执行。
//
//    所以，哪怕 3 个并发任务同时调用 deposit(100)，也会依次执行，结果是 300 ✅
    func deposit(amount: Int) {
        usleep(10_000)
        balance += amount
//        print("Deposited \(amount), current balance: \(balance)")
    }
    
//    func withdraw(amount: Int) -> Bool {
//        usleep(10_000)
//        if amount > balance {
//            print("Withdrawal of \(amount) failed, current balance: \(balance)")
//            return false
//        }
//        balance -= amount
//        print("Withdrew \(amount), current balance: \(balance)")
//        return true
//    }
    
    func getBalance() -> Int {
        return balance
    }
}
class BankAccount1 {
    private var balance: Int = 0
    
    func deposit(amount: Int) {
        usleep(10_000)
        balance += amount
//        print("Deposited \(amount), current balance: \(balance)")
    }
    
//    func withdraw(amount: Int) -> Bool {
//        usleep(10_000)
//        if amount > balance {
//            print("Withdrawal of \(amount) failed, current balance: \(balance)")
//            return false
//        }
//        balance -= amount
//        print("Withdrew \(amount), current balance: \(balance)")
//        return true
//    }
    
    func getBalance() -> Int {
        return balance
    }
}

//@main 用于标记程序的入口（即程序从哪里开始运行），
//@main
//struct Main {
//    //Main.main() 入口函
//    static func main() async {
//        let account = BankAccount()
//        
//        // 多个任务并发操作账户
//        await withTaskGroup(of: Void.self) { group in
//            for _ in 1...3 {
//                group.addTask {
//                    await account.deposit(amount: 100)
//                }
//                group.addTask {
//                    _ = await account.withdraw(amount: 50)
//                }
//            }
//        }
//        
//        let finalBalance = await account.getBalance()
//        print("Final balance: \(finalBalance)")
//    }
//}
func testBankAccountConcurrency(name: String) async {
    let account = BankAccount()

    await withTaskGroup(of: Void.self) { group in
        for _ in 1...3 {
            group.addTask {
                await account.deposit(amount: 100)
            }
//            group.addTask {
//                _ = await account.withdraw(amount: 50)
//            }
        }
    }

    let finalBalance = await account.getBalance()
    print("\(name)-Final balance: \(finalBalance)")
}


//正确做法：使用 Task、async let 或 withTaskGroup
//Swift Concurrency 是推荐的 actor 搭配机制，它支持：
//
//自动管理任务生命周期；
//
//保证访问 actor 成员是有序的；
//
//避免 GCD 中容易出现的泄漏、死锁、竞争等问题。
func testBankAccountConcurrency2(name: String) async {
    let account = BankAccount()

    async let t1: () = account.deposit(amount: 100)
//    async let t2 = account.withdraw(amount: 50)
    async let t3: () = account.deposit(amount: 100)
//    async let t4 = account.withdraw(amount: 50)
    async let t5: () = account.deposit(amount: 100)
//    async let t6 = account.withdraw(amount: 50)

//    _ = await [t1, t2, t3, t4, t5, t6]
    _ = await [t1,   t3,   t5 ]

    let finalBalance = await account.getBalance()
    print("\(name)-Final balance: \(finalBalance)")
}

//这段代码在表面上看起来“能用”，但它：
//
//✅ 确实是通过 Task { await ... } 来访问 actor，所以访问是合法的。
//
//❌ 但你失去了结构化并发的管理能力（也就是 Swift Concurrency 的优势）。
//
//❌ 如果你在 Task 外部访问 actor 的成员，就会 编译报错 或引发未定义行为。

//实际运行结果：没问题 满足预期，加了3次都是300，没有错误

func testError(name: String) {
    
//    如果去掉 actor 的话呢？
//    比如将 BankAccount 改成普通的 class，并用 DispatchQueue.global().async 并发执行 account.balance += 100，马上就会出现数据竞争问题，结果可能不是 300，甚至崩溃。
    //    let account = BankAccount()
    let account = BankAccount1()
    let group = DispatchGroup()

    for _ in 1...3 {
        group.enter()
        DispatchQueue.global().async {//并发提交
            Task {//提交了多个task
                
                //调用 await account.deposit(...) 的时候，Swift 会挂起当前任务，并进入该 actor 的隔离域。
                //actor 的本质就是为了让并发环境下的状态访问变得安全可控，哪怕调用者是并发任务，也会被序列化处理。
                await account.deposit(amount: 100)
                group.leave()
            }//马上完成，会有多个task同时执行 await account.deposit，虽然用了actor有序访问，但是没有用asyc let或者withTaskGroup，仍然失去并发管理能力
        }

//        group.enter()
//        DispatchQueue.global().async {
//            Task {
//                _ = await account.withdraw(amount: 50)
//                group.leave()
//            }
//        }
    }

    group.notify(queue: .main) {
        Task {
            let finalBalance = await account.getBalance()
            
 
            print("\(name)-Final balance: \(finalBalance)")
        }
    }
}



//普通 class + GCD
class SafeBankAccount {
    private var balance: Int = 0
    private let queue = DispatchQueue(label: "bank.serial.queue")

    func deposit(amount: Int) {
        queue.sync {
            let current = balance
            usleep(10_000)
            balance = current + amount
        }
    }

//    func withdraw(amount: Int) -> Bool {
//        return queue.sync {
//            let current = balance
//            usleep(10_000)
//            if current >= amount {
//                balance = current - amount
//                return true
//            } else {
//                return false
//            }
//        }
//    }

    func getBalance() -> Int {
        return queue.sync {
            balance
        }
    }
}


func testSafeBankAccountConcurrency(name: String) {
    let account = SafeBankAccount()
    let group = DispatchGroup()

    for _ in 1...3 {
        group.enter()
        DispatchQueue.global().async {
            account.deposit(amount: 100)
            group.leave()
        }
//
//        group.enter()
//        DispatchQueue.global().async {
//            _ = account.withdraw(amount: 50)
//            group.leave()
//        }
    }

    group.wait()

    print("\(name)-Final balance (Safe): \(account.getBalance())")
}

class MyTask {
    // 这里的 Task 是 MyTask.Task，不是全局的 Task
    class Task {
        
    }
    
}

//
//Task 是 Swift 并发库提供的类型，定义在 Swift 标准库（Swift Concurrency Runtime）中，具体是一个 struct，用于创建和管理异步任务。
//
//它提供了像 Task { ... } 这样的尾随闭包构造器，是通过定义了初始化器，支持尾随闭包语法。
//public struct Task<Success, Failure> where Failure : Error {
//    public init(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success)
//}
//Task { ... } 其实是调用了这个 struct 的初始化器，利用尾随闭包语法，所以你写的代码是合法的。


//不是编译器内建语法
//Task 不是语言内建的关键字（不像 if、for、func 等）。
//
//它是普通的类型，只是配合 async/await 和编译器的支持，才能实现并发模型。
//
//编译器会识别 Task { ... } 这种语法调用这个结构体的构造函数。
