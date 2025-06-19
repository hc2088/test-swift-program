//
//  ViewController-actor.swift
//  test-ui
//
//  Created by v-huchu on 2025/6/19.
//

import Foundation
import UIKit


extension ViewController{
    
    
    func testActor() {
        
        
//        let counter = Counter()
//
//        Task {
//            
//            //actor 的方法访问是异步的
//            await counter.increment()
//            //actor 的方法访问是异步的，即使只是读取属性，也需要：
//            let v = await counter.getValue()
//            print("当前值：\(v)")
//        }
//
//        
//        
//        
//        let cache = ImageCache()
//
//        Task {
//            if let cached = await cache.image(for: "url") {
//                print("已缓存")
//            } else {
////                let image = downloadImage()
////                await cache.setImage(image, for: "url")
//            }
//        }
        
        Task {
            await testActorConcurrency()
        }
    
        Task {
            await testActorConcurrency2()
        }
        
        
        Task {
            await testActorConcurrency3()
        }
        
        
    }
    
    
    func testActorConcurrency() async {
        let counter = Counter()
        let taskCount = 1000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await counter.increment()
                }
            }
        }

        let final = await counter.getValue()
        print("✅ 最终计数值应为 \(taskCount)，实际为 \(final)")
    }
    
    func testActorConcurrency2() async {
        let counter = Counter2()
        let taskCount = 1000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await counter.increment()
                }
            }
        }

        let final = await counter.getValue()
        print("✅ 最终计数值应为 \(taskCount)，实际为 \(final)")
    }
    
    func testActorConcurrency3() async {
        let counter = TestClass.Counter()
        let taskCount = 1000

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await counter.increment()
                }
            }
        }

        let final = await counter.getValue()
        print("✅ 最终计数值应为 \(taskCount)，实际为 \(final)")
    }


    
    
}
class Counter2 {
    
     
    private var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        return value
    }
}

actor Counter {
    
     
    private var value = 0

    func increment() {
        value += 1
    }

    func getValue() -> Int {
        return value
    }
}



enum TestClass {
    //传统做法
    class Counter {
        private var value = 0
        
        //默认串行线程
        private let queue = DispatchQueue(label: "counter")
        
        func increment() {
            //同步串行
            queue.sync {
                value += 1
            }
        }
        
        func getValue() -> Int {
            //同步串行
            return queue.sync {
                value
            }
        }
    }
    
}

actor UserManager {
    var users: [String] = []

    func add(user: String) {
        users.append(user) // OK
    }

    func userCount() -> Int {
        return users.count // OK
    }

    static func printInfo() {
        // ❌ 静态方法不能访问实例属性
    }
}



actor ImageCache {
    private var cache: [String: UIImage] = [:]

    func image(for url: String) -> UIImage? {
        return cache[url]
    }

    func setImage(_ image: UIImage, for url: String) {
        cache[url] = image
    }
}
