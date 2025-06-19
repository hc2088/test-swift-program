//
//  ViewController-test-async.swift
//  test-ui
//
//  Created by v-huchu on 2025/6/19.
//

import Foundation


extension ViewController {
    
    
    func fetchUserInfo() async -> String {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络延迟
        return "👤 用户信息"
    }
    
    
    
    func fetchOrderInfo() async -> String {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 模拟网络延迟
        return "🧾 订单信息"
    }

    func loadAllData() async {
        // 并发请求
        async let user = fetchUserInfo() //创建async let变量
        async let order = fetchOrderInfo()

        // 等两个都完成后执行
        let (userInfo, orderInfo) = await (user, order) // await 等待async let变量

        print("✅ 两个接口都返回后执行")
        print("用户信息：\(userInfo)")
        print("订单信息：\(orderInfo)")
    }

    
    func loadAllDataWithTaskGroup() async {
        var userInfo: String = ""
        var orderInfo: String = ""

        await withTaskGroup(of: (String, String).self) {[weak self] group in
            guard let self = self else { return }
            group.addTask {
                let result = await self.fetchUserInfo()//await async函数
                return (result, "user")
            }

            group.addTask {
                let result = await self.fetchOrderInfo() //await async函数
                return (result, "order")
            }

            for await (result, type) in group { //await group 等待group
                if type == "user" {
                    userInfo = result
                } else if type == "order" {
                    orderInfo = result
                }
            }
        }

        print("✅ 两个接口都完成")
        print("用户信息：\(userInfo)")
        print("订单信息：\(orderInfo)")
    }

 
    
}
