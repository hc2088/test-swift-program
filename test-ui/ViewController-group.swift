//
//  ViewController-test-async.swift
//  test-ui
//
//  Created by v-huchu on 2025/6/19.
//

import Foundation


extension ViewController {



    
    //@escaping
    func fetchUserInfo(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            //这里的 completion 会在函数返回后执行，所以需要 @escaping。
            completion("👤 用户信息")
        }
        //函数返回了。
    }

    func fetchOrderInfo(completion: @escaping (String) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            completion("🧾 订单信息")
        }
    }

    
    // 用传统的 DispatchGroup 实现并发请求两个网络接口，并在两个接口返回后执行后续任务
    //（Swift 5 及更早兼容）
    func loadAllDataWithDispatchGroup() {
        let group = DispatchGroup()

        var userInfo: String?//var
        var orderInfo: String?

        group.enter()
        fetchUserInfo { result in
            //变量并不是作为参数传进函数，只是在闭包作用域中被访问，所以 不需要 inout。
            
            // 按值捕获值类型
            //但变量是可变的时（用 var 声明），并且闭包是 @escaping 时，会自动在堆上创建一个 “可变盒子” （Box）来包裹这个变量；
            userInfo = result
            group.leave()
        }

        group.enter()
        fetchOrderInfo { result in
            orderInfo = result
            group.leave()
        }

        group.notify(queue: .main) {
            print("✅ 两个接口都返回后执行")
            print("用户信息：\(userInfo ?? "")")
            print("订单信息：\(orderInfo ?? "")")
        }
    }
    
    
    
 
    
}
