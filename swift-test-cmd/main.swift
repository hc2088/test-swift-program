//
//  main.swift
//  swift-test-cmd
//
//  Created by v-huchu on 2025/4/28.
//

import Foundation

print("Hello, World!")


class ClusterAnnotation : NSObject  {
    
    
    var id:String
    
    init(id: String) {
        self.id = id
    }
    override var hash: Int{
        return self.id.hash
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ClusterAnnotation else { return false }
        return self.hash == other.hash
    }
    override var description: String{
        return self.id
    }
}

var annotations = [ClusterAnnotation]()
for marker in ["1","2","3","4","5"] {
    let clusterAnnotation = ClusterAnnotation(id: marker)
    annotations.append(clusterAnnotation)
}
let before = Set(annotations.compactMap { annotation -> ClusterAnnotation? in
    return annotation
})

var annotations2 = [ClusterAnnotation]()
for marker in ["3","4","5","6","7"] {
    let clusterAnnotation = ClusterAnnotation(id: marker)
    annotations2.append(clusterAnnotation)
}


var after = Set(annotations2)

// 保留仍然位于屏幕内的annotation
var toKeep = before
toKeep  = toKeep.intersection(after)

// 需要添加的annotation
var toAdd = after
toAdd.subtract(toKeep)

// 删除位于屏幕外的annotation
var toRemove = before
toRemove.subtract(after)

print("")








// Swift 的 Array
let swiftArray: [String] = ["apple", "banana", "cherry"]

// 转成 NSArray
let nsArray: NSArray = swiftArray as NSArray

// 取值
print("Swift Array first element:", swiftArray[0]) // apple
print("NSArray first element:", nsArray[0])         // apple

// 追加元素（测试可变性）
var newSwiftArray = swiftArray
newSwiftArray.append("date")
print("New Swift Array:", newSwiftArray)

// 试图修改 NSArray
// nsArray.add("date") // ❌ 错误！NSArray是不可变的，不能直接add元素
// 如果想修改，应该用 NSMutableArray
let mutableArray = NSMutableArray(array: swiftArray)
mutableArray.add("date")
print("NSMutableArray after add:", mutableArray)

// 类型安全测试
if let firstItem = swiftArray.first {
    print("Swift Array item is a String:", type(of: firstItem)) // String
}

let nsFirstItem = nsArray[0]
print("NSArray item is Any:", type(of: nsFirstItem)) // __NSCFString (桥接层，不是Swift的String！)





class AClass : NSObject {
    
    
    var uiSettings: NSDictionary? {
        didSet{
            applyUISettings()
        }
    }
    func applyUISettings(){
        let  show = uiSettings?["isShow"]
        print(show)
        
    }
}


let a = AClass()




class YRNAMapView: NSObject {
    override init() {
        super.init()
    }
    
    init(uiSettings:NSDictionary?){
        super.init()
        //在构造方法里面无论调用多少次设置属性的方法，都不会触发uiSettings观察器
        self.uiSettings = uiSettings
        self.uiSettings = uiSettings
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc var uiSettings: NSDictionary? {
        //'didSet' cannot be provided together with a setter
        //'didSet' cannot be provided together with a getter
        didSet {
            self.applyUISettings()
        }
        //        set {
        //            uiSettings = newValue
        //        }
        //        get {
        //            return uiSettings
        //        }
    }
    
    private func applyUISettings() {
        print("applyUISettings")
    }
}

let view = YRNAMapView(uiSettings: NSDictionary.init())
print("123123")
view.uiSettings=NSDictionary.init()









class BubbleContainer  {
 
    var data1:Int? {
        didSet{
            print("data1修改了")
            data2 = 100
        }
    }
    var data2:Int?{
        didSet{
            print("data2修改了")
        }
    }
    init(data1: Int? = nil, data2: Int? = nil) {
 
        self.data1 = data1
        self.data2 = data2
        
 
        self.data1 = data1
        self.data1 = data1
        self.data1 = data1
        self.data1 = data1
        self.data1 = data1
        self.data1 = data1
    }
    func aa(){
        data1=100
    }
}
let bbb909=BubbleContainer(data1: 1,data2: 2)
//bbb909.data1=2



let response = "123"
//do {
//    let data = try JSONSerialization.data(withJSONObject: response, options: [])
//    if let jsonString = String(data: data, encoding: .utf8) {
//        print(jsonString)
//    }
//} catch {
//    print("序列化失败：\(error.localizedDescription)")
//}


//do {
//    // 检查是否为合法的 JSON 对象（Dictionary 或 Array）
//    
////    Showing Recent Errors Only
////    /Users/mi/Desktop/test-swift-program/swift-test-cmd/main.swift:223:63: Cannot convert value of type '[Any]?' to expected argument type '[String : Any]'
//
//
//    if let validJSON = response as? [String: Any] ?? response as? [Any] {
//        let data = try JSONSerialization.data(withJSONObject: validJSON, options: [])
//        if let jsonString = String(data: data, encoding: .utf8) {
//            print(jsonString)
//        }
//    } else {
//        print("Invalid response format: Expected Dictionary or Array.")
//    }
//} catch {
//    print("序列化失败：\(error.localizedDescription)")
//}


func safeJSONSerialization(response: Any) {
    do {
        // 根据 response 类型判断
        if let validJSON = response as? [String: Any] {
            try serializeAndPrint(validJSON)
        } else if let validJSONArray = response as? [Any] {
            try serializeAndPrint(validJSONArray)
        } else {
            print("Invalid response format: Expected Dictionary or Array.")
        }
    } catch {
        print("序列化失败：\(error.localizedDescription)")
    }
}

func serializeAndPrint(_ object: Any) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [])
    if let jsonString = String(data: data, encoding: .utf8) {
        print(jsonString)
    }
}
 
safeJSONSerialization(response:response)
print("结束")







struct JSONUtil {
    static func encode<T: Codable>(_ object: T) -> String? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(object)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to encode object: \(error)")
            return nil
        }
    }
    
    static func decode<T: Codable>(_ type: T.Type, from jsonString: String) -> T? {
        let decoder = JSONDecoder()
        do {
            guard let jsonData = jsonString.data(using: .utf8) else {
                return nil
            }
            return try decoder.decode(type, from: jsonData)
        } catch {
            print("Failed to decode JSON string: \(error)")
            return nil
        }
    }
}
//let ret = "{\n\t\"da\": \"adsf\"\n}"
let ret = ["asd":"213412"]
let str = JSONUtil.encode(ret)!
print(str)






//struct Pet: Codable {
//    let type: String
//    let name: String
//}
//
//struct User: Codable {
//    let id: Int
//    let name: String
//    let age: Int
//    let pets: [Pet]
//}
//



// 解析代码
//do {
//    
//    let yourJsonData = "123123123"
//    let jsonData = yourJsonData.data(using: .utf8)!// 假设这是 Data
//    let user = try JSONDecoder().decode(User.self, from: jsonData)
//    print(user.name) // Tom
//} catch {
//    print("解析失败: \(error)")
//}
//
//




struct User2: Codable {
    var name: String
    var age: Int
    
    // 自定义解码
    enum CodingKeys: String, CodingKey {
        case name = "full_name"
        case age = "user_age"
    }
    
    // 自定义编码和解码方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        age = try container.decode(Int.self, forKey: .age)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
    }
}


do {
    
    let yourJsonData = "123123123"
    let jsonData = yourJsonData.data(using: .utf8)!// 假设这是 Data
    let user = try JSONDecoder().decode(User2.self, from: jsonData)
    print(user.name) // Tom
} catch {
    print("解析失败: \(error)")
}







