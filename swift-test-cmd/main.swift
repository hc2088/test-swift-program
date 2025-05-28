//
//  main.swift
//  swift-test-cmd
//
//  Created by v-huchu on 2025/4/28.
//

import Foundation
//import YYModel
//import YYModel

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









@objcMembers class MIWTeamEntranceConfigResponse: NSObject {
    var entranceList: [MIWEntranceListItem]?
    var discoveryTeamList: [MIWEntranceListItem]?
    var url: String?
}



@objcMembers class MIWEntranceListItem: NSObject{
    
}
let result: MIWTeamEntranceConfigResponse = MIWTeamEntranceConfigResponse()
//nil!=true是true nil空的 !=true成立
//true!=true是false 没有内容!=true不成立
//result.entranceList=[]
//result.entranceList=nil
result.entranceList=[MIWEntranceListItem()]
//if result.entranceList?.isEmpty != true {
//    print("空的")
//}

//if result.entranceList?.isEmpty == true {
//    print("空的")
//}

let hasEntrance = !(result.entranceList?.isEmpty ?? true)
//let hasDiscovery = !(discoveryTeamList?.isEmpty ?? true)
if !hasEntrance {
    print("空的")
}else{
    print("非空")
}


enum MIWRouterPage: String {
    
    //跑团详情
    //https://region.hlth.io.mi.com/applinks/page/groupInfo?id=
    case groupInfo
    
    //web页面（可复用）
    //https://region.hlth.io.mi.com/applinks/page/gotoWeb?web_url=
    case gotoWeb
}

let aMIWRouterPage = MIWRouterPage.init(rawValue: "groupInfo")

let a2MIWRouterPage = MIWRouterPage.groupInfo
print(aMIWRouterPage?.rawValue)

print(a2MIWRouterPage.rawValue)


func unescapeAndParseJSONString(_ input: String) -> Any? {
    // 第一步：解析外层 JSON 字符串
    guard let data = input.data(using: .utf8),
          let outerJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let innerJSONString = outerJSON["value"] as? String else {
        return nil
    }
    
    print(outerJSON)
    // 第二步：解析内层的 JSON 字符串
    guard let innerData = innerJSONString.data(using: .utf8),
          let innerJSON = try? JSONSerialization.jsonObject(with: innerData, options: []) else {
        return nil
    }
    return String.init(data: innerData, encoding: .utf8)
    
    //    return innerJSON
}

//let jsonString = "{\"value\":\"{\\\"a\\\":\\\"asd\\\"}\"}"
//if let result = unescapeAndParseJSONString(jsonString) {
//    print(result)  // 输出 ["a": "asd"]
//}

let dataStr = "%7B%5C%22category%5C%22%3A%5C%22walking%5C%22%2C%5C%22update_time%5C%22%3A1745803536%2C%5C%22time%5C%22%3A1745801182%2C%5C%22watermark%5C%22%3A124697010241576%2C%5C%22zone_offset%5C%22%3A28800%2C%5C%22sid%5C%22%3A%5C%22xiaomiwear_app%5C%22%2C%5C%22key%5C%22%3A%5C%22outdoor_walking%5C%22%2C%5C%22value%5C%22%3A%5C%22%7B%5C%5C%5C%22max_height%5C%5C%5C%22%3A0%2C%5C%5C%5C%22min_pace%5C%5C%5C%22%3A2073%2C%5C%5C%5C%22time%5C%5C%5C%22%3A1745801182%2C%5C%5C%5C%22did%5C%5C%5C%22%3A%5C%5C%5C%22xiaomiwear_app%5C%5C%5C%22%2C%5C%5C%5C%22avg_touchdown_air_ratio%5C%5C%5C%22%3A0%2C%5C%5C%5C%22duration%5C%5C%5C%22%3A605%2C%5C%5C%5C%22sport_type%5C%5C%5C%22%3A2%2C%5C%5C%5C%22calories%5C%5C%5C%22%3A26%2C%5C%5C%5C%22min_height%5C%5C%5C%22%3A0%2C%5C%5C%5C%22cloud_course_source%5C%5C%5C%22%3A0%2C%5C%5C%5C%22version%5C%5C%5C%22%3A9%2C%5C%5C%5C%22avg_height%5C%5C%5C%22%3A0%2C%5C%5C%5C%22max_pace%5C%5C%5C%22%3A471%2C%5C%5C%5C%22min_touchdown_air_ratio%5C%5C%5C%22%3A0%2C%5C%5C%5C%22proto_type%5C%5C%5C%22%3A22%2C%5C%5C%5C%22timezone%5C%5C%5C%22%3A32%2C%5C%5C%5C%22distance%5C%5C%5C%22%3A856%2C%5C%5C%5C%22start_time%5C%5C%5C%22%3A1745801182%2C%5C%5C%5C%22end_time%5C%5C%5C%22%3A1745801786%2C%5C%5C%5C%22target_value%5C%5C%5C%22%3A%7B%7D%2C%5C%5C%5C%22max_speed%5C%5C%5C%22%3A7.6433119773864746%2C%5C%5C%5C%22steps%5C%5C%5C%22%3A0%7D%5C%22%7D"

let bStr = dataStr.removingPercentEncoding ?? ""
print(bStr)

let unescapedString = bStr.replacingOccurrences(of: "\\\"", with: "\"")
    .replacingOccurrences(of: "\\\\", with: "\\")

print(unescapedString)

class UrlUtils {
    
    
    static func urlDecode(_ encodedString: String) -> String {
        let replacedString = encodedString.replacingOccurrences(of: "+", with: " ")
        return replacedString.removingPercentEncoding ?? encodedString
    }
    
}


@objcMembers class MIWServerSportDataModel: NSObject {
    var sid: String = ""// 数据源ID
    var key: String = ""// 运动记录类型
    var time: Int = 0// 归属时间戳，精确到秒
    var category: String = ""// 运动大类
    var value: String = ""// 运动记录明细数据，json字符串格式，参考运动健康数据定义
    var zone_offset: Int = 0// 相对于零时区的时区偏移量，以秒为单位，例如北京时区，值为28800，默认值为28800
    var zone_name: String = ""// IANA时区标识符，如北京时区：Asia/Shanghai
    var deleted: Bool = false// 是否删除，增量同步时才返回（上报和删除不需要上传）
    
    
}

public class MIWReportBase: Codable {
    /// 具有实际意义的运动课程ID
    private enum CloudCourseId: Int{
        case Gym = 251   //健身房训练
        case AiDong = 252  ///爱动课程
        case TV = 253  ///电视课程
        case APP = 255 /// 运动健康APP课程
    }
    
    /// 数据源id
    public var did: String?
    
    /// 运动报告上报的时间
    public var time: Int?
    
    /// 运动报告上报的时区
    public var timezone: Int?
    
    /// 协议版本号，给@objc 客户端构建文件名
    public var version: Int?
}



if let data = unescapedString.data(using: .utf8) {
    print(bStr)
    
    let outerJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    print(outerJSON)
    
    
    
    
    
}


//
//let decodeString = UrlUtils.urlDecode(data)
//
//let unescapedString = decodeString.replacingOccurrences(of: "\\\"", with: "\"")
//                              .replacingOccurrences(of: "\\\\", with: "\\")
//
//if let sportData: MIWServerSportDataModel = MIWServerSportDataModel.yy_model(withJSON: unescapedString)  {
//
//    var result:MIWReportBase?
//    if let valueData = sportData.value.data(using: .utf8) {
//        let jsonDecoder = JSONDecoder()
//        result = try? jsonDecoder.decode(MIWReportBase.self, from: valueData)
//        result?.did = sportData.sid
//        result?.timezone = sportData.zone_offset / (15 * 60)
//    }
//
//
//
//
//
//}

var avatar11:String? = nil
var avatar22:String? = ""

let url11 = URL.init(string: avatar11 ?? "")
let url22 = URL.init(string: avatar22 ?? "")

print(url11)
print(url22)


//let url = URL(string: "myapp://host?a=1&b=2")! //queryItems正确解析
//let url = URL(string: "host?a=1&b=2")! //queryItems正确解析
//let url = URL(string: "myapp://?a=1&b=2")! //queryItems正确解析
//let url = URL(string: "?a=1&b=2")! //queryItems正确解析


//let url = URL(string: "a=1&b=2")! //url有值，queryItems为空
//let url = URL(string: "myapp://a=1&b=2")! //url有值，queryItems为空
[
    "myapp://host?a=1&b=2",
    "myapp://host/path?a=1&b=2",
    "myapp://?a=1&b=2",

    
    "host?a=1&b=2",
    "host/path?a=1&b=2",
    "//host/path?a=1&b=2",
    "://host/path?a=1&b=2",
    
    "?a=1&b=2",
    "a=1&b=2",
    "myapp://a=1&b=2",
    
    "https://region.hlth.io.mi.com/applinks/page/ADCoursePage?id="
    
].forEach {  url1 in
    let url = URL(string: url1) //queryItems正确解析
    if url == nil  {
        print("----》为空： \(url1)")
    } else {
        print("----》正常： \(url1),  \(String(describing: url))")
        
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        print(url1, url!, components?.queryItems,separator: "  , ")
    }
 

}

//必须参数默认值，如果传，就要传非空，如果不传，就取默认值，意思是如果传参数那就必须传递非空参数
func openPage(appName: String,
              pageName: String,
              pageParams: [String: Any] = [:]){
    print(appName,pageName,pageParams)
}

//可选参数默认值，意思是，传了就用传的，如果传了nil就是nil，如果有值就是有值，如果没传，就用默认值，非nil
func openPage2(appName: String,
               pageName: String,
               pageParams: [String: Any]? = [:]){
    print(appName,pageName,pageParams ?? [:])
}

openPage(appName: "123", pageName: "123123")
var mapDa = ["key":["s":"fasd"]]
var data = mapDa["key"]
var data2 = mapDa["key1"]

openPage(appName: "123", pageName: "123123",pageParams: data!)
openPage2(appName: "123", pageName: "123123",pageParams: data2)
openPage2(appName: "123", pageName: "123123")

class MIWApi {
    static func getSportHomeData(completion: @escaping (String) -> Void) {
        
    }
}

class YRNSportDataHelper {
    
    
    func loadSportHomeDataFromDB() {
        
        MIWApi.getSportHomeData { [weak self]  result in
            guard let self = self else { return }
            
            
            getCourseDetail(result) { [weak self] course in
                guard let self = self else { return }
                let _ =  sportName()
                
            }
            
            
        }
    }
    
    private func getCourseDetail(_ report: String, completion: @escaping (String) -> Void) {
        
    }
    
    private func sportName(  ) -> String {
        return ""
    }
    
    
}




//public enum MIWPhysicalFitnessStatusType: Int, CaseIterable {
//    ///1：体能丧失
//    case lose = 1
//    /// 2：维持体能"
//    case keep = 2
//    /// 3：有效训练
//    case effective = 3
//    /// 4：过度训练
//    case over = 4
//
//    var color: UIColor {
//        switch self {
//        case .lose:
//            return UIColor.mwDynamicColor(0x45B4FF, 0x2598E5)
//        case .keep:
//            return UIColor.mwDynamicColor(0x00D6BA, 0x4EC708)
//        case .effective:
//            return UIColor.mwDynamicColor(0xA3E509, 0x8FCC00)
//        case .over:
//            return UIColor.mwDynamicColor(0xFFBB00, 0xF0AB00)
//        }
//    }
//
//}

//let allColors = MIWPhysicalFitnessStatusType.allCases.map { $0.color }
//print(allColors)







//[
//
//
//    "",
//    "123",
//    "asdfa"
//
//].forEach {  str in
//    let uid = Int64(str) //queryItems正确解析
//
//    print(uid)
//}

let babitDayPlan : String = ""

var babitDayPlanDict: [String: Any]?
if let data = babitDayPlan.data(using: .utf8) {
    do {
        babitDayPlanDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if babitDayPlanDict == nil {
            print("babitDayPlanDict is nil")
        }
    } catch {
        print(error)
    }
    print(babitDayPlanDict)
}

class QueryParameters {
    
}
//public enum MIWPhysicalFitnessStatusType: Int, CaseIterable {
//    ///1：体能丧失
//    case lose = 1
//    /// 2：维持体能"
//    case keep = 2
//    /// 3：有效训练
//    case effective = 3
//    /// 4：过度训练
//    case over = 4
//
//    var color: UIColor {
//        switch self {
//        case .lose:
//            return UIColor.mwDynamicColor(0x45B4FF, 0x2598E5)
//        case .keep:
//            return UIColor.mwDynamicColor(0x00D6BA, 0x4EC708)
//        case .effective:
//            return UIColor.mwDynamicColor(0xA3E509, 0x8FCC00)
//        case .over:
//            return UIColor.mwDynamicColor(0xFFBB00, 0xF0AB00)
//        }
//    }
//
//}

//let allColors = MIWPhysicalFitnessStatusType.allCases.map { $0.color }
//print(allColors)



