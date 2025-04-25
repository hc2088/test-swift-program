//
//  main.swift
//  hook-swift
//
//  Created by v-huchu on 2025/4/29.
//

import Foundation
import ObjectiveC
//print("Hello, World!")
//
//
//func scanVtableForMethod(of object: AnyObject, targetMethod: String) -> Int? {
//    let table = vtable(of: object)
//    let vtablePtr = table.pointee
//
//    // 遍历方法表
//    var index = 0
//    while true {
//        let methodPtr = vtablePtr.advanced(by: index).pointee
//        if methodPtr == nil {
//            // 如果方法指针为 nil，说明已经遍历完所有方法
//            break
//        }
//
//        // 尝试通过 methodPtr 查找方法名称
//        if let methodName = getMethodName(from: methodPtr) {
//            if methodName == targetMethod {
//                return index
//            }
//        }
//        index += 1
//    }
//
//    return nil
//}
//
//func getMethodName(from methodPtr: UnsafeMutableRawPointer) -> String? {
//    // 通过 methodPtr 获取对应的符号名称
//    let symbol = UnsafeRawPointer(methodPtr).assumingMemoryBound(to: UnsafePointer<CChar>.self)
//    return String(cString: symbol.pointee)
//}
//
//
//
//func hookMethodAutomatically(object: AnyObject, targetMethod: String, newImpl: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
//    // 扫描并找到方法 index
//    guard let methodIndex = scanVtableForMethod(of: object, targetMethod: targetMethod) else {
//        print("未找到方法：\(targetMethod)")
//        return nil
//    }
//
//    // Hook 替换方法
//    return hookMethod(object: object, methodIndex: methodIndex, newImpl: newImpl)
//}
//
//
//
//class PureSwiftClass {
//    func sayHello() {
//        print("Original Hello")
//    }
//
//    func greet() {
//        print("Hello from greet!")
//    }
//}
//
//// 创建实例
//let obj = PureSwiftClass()
//
//// 打印原始调用
//obj.sayHello()   // Original Hello
//obj.greet()      // Hello from greet!
//
//// 定义一个新的实现
//typealias SayHelloType = @convention(c) (AnyObject) -> Void
//let newImpl: @convention(c) (AnyObject) -> Void = { obj in
//    print("🛠 Hooked Hello")
//}

//// 自动 Hook 方法
//if let originalImpl = hookMethodAutomatically(object: obj, targetMethod: "sayHello", newImpl: unsafeBitCast(newImpl, to: UnsafeMutableRawPointer.self)) {
//    // 调用 Hook 后的 sayHello
//    obj.sayHello() // 🛠 Hooked Hello
//
//    // 你也可以手动调用原始方法
//    let originalSayHello = unsafeBitCast(originalImpl, to: SayHelloType.self)
//    print("调用被保存的原方法：")
//    originalSayHello(obj)  // Original Hello
//}
//
//


import ObjectiveC

extension NSObject {

    // Perform Method Swizzling
    class func swizzleMethod(originalSelector: Selector, swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)

        // Ensure both methods are found
        guard let originalMethod = originalMethod, let swizzledMethod = swizzledMethod else {
            return
        }

        // Add the swizzled method if not already present
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

class MyClass: NSObject {
    @objc func sayHello() {
        print("Original Hello")
    }
    
    @objc func swizzledSayHello() {
        print("Swizzled Hello!")
    }
}

// Usage
MyClass.swizzleMethod(originalSelector: #selector(MyClass.sayHello), swizzledSelector: #selector(MyClass.swizzledSayHello))

let myObject = MyClass()
myObject.sayHello()



