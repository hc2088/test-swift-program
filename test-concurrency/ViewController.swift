//
//  ViewController.swift
//  test-concurrency
//
//  Created by huchu on 2025/8/3.
//
import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建按钮
        let testButton = UIButton(type: .system)
        testButton.setTitle("测试 Actor", for: .normal)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testButton)
        
        // 约束按钮居中显示
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            testButton.widthAnchor.constraint(equalToConstant: 120),
            testButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // 按钮点击事件
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
        
        
        
        testTask()
        
    }
    
    func testTask() {
        
        func sayHelloAsync() async -> String {
            //async 方法不能被普通方式（同步方式）直接调用，必须在异步上下文中，并且加上 await 来调用。
            return "Hello from async"
        }

        // 调用处必须用 await 等待结果
        Task {
            let message = await sayHelloAsync()
            print(message)
        }
        //Users/huchu/Desktop/test-swift-program/test-concurrency/ViewController.swift:44:9 'async'
        //call in a function that does not support concurrency
        //sayHelloAsync()
        
        
        // 一个异步函数，模拟网络请求或耗时操作
        func fetchData() async -> String {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 模拟延时1秒
            return "Hello from async!"
        }

        // 使用 Task 创建并启动异步任务
        func exampleTaskUsage() {
            
            
            //1、创建任务并保存：
            //创建一个任务 taskA
            let task = Task<String, Never> {
                //显式创建一个结构化并发的任务对象，类型是 Task<String, Never>
                
                //String: 表示这个任务返回的是一个 String 类型的值。
                //Never: 表示这个任务永远不会抛出错误。
                await fetchData()
            }

            
            //2、异步环境获取值：    创建异步作用域，才能使用 await
            // 创建另一个任务 taskB，用来获取 taskA 的结果
            Task {
                let result = await task.value//
                print("Result from task: \(result)")
            }
            
            
            //3、快速执行 async 操作
            // 创建第三个任务 taskC，直接执行 async 函数
            Task {
                let result = await fetchData()//async函数
                print("Result from task: \(result)")
            }
        }

        exampleTaskUsage()
 

        
    }
    
    @objc private func testButtonTapped() {
        
        for i in 1...100 {
            
//            Task {
//                await testBankAccountConcurrency(name: "withTaskGroup-\(i)")
//            }
//            
//            
//            Task {
//                await testBankAccountConcurrency2(name: "async let-\(i)")
//            }
//            
            DispatchQueue.global().async {
              
                testError(name:"gcd-\(i)")
            }
            
//            DispatchQueue.global().async {
//                testSafeBankAccountConcurrency(name: "普通 class + GCD-\(i)")
//            }
//            
            
        }
    }
    
}
