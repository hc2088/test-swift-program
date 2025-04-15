//
//  main.swift
//  test-swift-program
//
//  Created by MI on 2025/4/10.
//

import Foundation

print("Hello, World!")




var someArr =  [Int](repeating: 1, count: 2)


for   i in someArr {
    print("\(i)")
}

//该循环方式在 Swift 3 中已经弃用。
//  1 C-style for statement has been removed in Swift 3
//
//for var index = 0; index <  2; ++index {
//    print("\(index)")
//}

var index = someArr.count
print("index=\(index)")

while index > 0
{
    index = index - 1;
    print("\(someArr[index])")
}



var intsB = [Int](repeating: 3, count: 3);

var result = intsB + someArr

for item in result {
    print("item=\(item)")
}




var someDict = [Int:String]()
someDict.updateValue("value", forKey: 1)

someDict[2] = "value2"

for (key,value) in someDict {
    print("key=\(key),value=\(value)")
}




//字典的索引及 (key, value) 对，实例如下:
for (key,value) in someDict.enumerated() {
    //22->>> key=0,value=(key: 1, value: "value")
    //22->>> key=1,value=(key: 2, value: "value2")
    print("22->>> key=\(key),value=\(value)")
}

for (key) in someDict.keys {
    print("\(key)")
}



for (key) in someDict.values {
    print("\(key)")
}



func funcname(site:String) -> String {
    return site
}
func funcname2(site:String, params2:Int) -> String {
    return site
}

var result2 = funcname(site: "helloworold")


print("result2=\(result2)")

funcname2(site: "asdf", params2: 1212)




func sitename() -> String {
    return "菜鸟教程"
}
print(sitename())



func minMax(array: [Int]) -> (min: Int, max: Int) {
    var currentMin = array[0]
    var currentMax = array[0]
    
    
    //运行时报错[-1..<array.count]，[0...array.count]
    //从下标1开始，因为上面代码中已经从0开始了 不需要再从0的位置比较了
    for value in array[1...array.count-1] {
        print("遍历value=\(value)")
        if value < currentMin {
            currentMin = value
        } else if value > currentMax {
            currentMax = value
        }
    }
    
    //元组
    return (currentMin, currentMax)
}





let bounds = minMax(array: [8,-6,1,2])


print("最小值=\(bounds.min),最大值=\(bounds.max)")



var someStrs = [String]()

someStrs.append("Apple")
someStrs.append("Amazon")
someStrs.append("Runoob")
someStrs += ["Google"]


//索引，index
//内容 item
for (index, item) in someStrs.enumerated() {
    print("在 index = \(index) 位置上的值为 \(item)")
}


func pow(qugemingzi1 a: Int, qugemingzi2 b: Int) -> Int {
    var res = a
    //从1到9遍历
    for i in 1..<b {
        print("i=\(i)")
        res = res * a
    }
    print(res)
    return res
}
let a =  pow(qugemingzi1: 3, qugemingzi2: 3)
print("a=\(a)");


//范型T 类型T，
//参数的个数 ... 任意多个
func vari<T>(members: T...){
    // 用in来迭代memebers
    for i in members {
        print(i)
    }
}
vari(members: 4,3,5)
vari(members: 4.5, 3.1, 5.6)
vari(members: "Google", "Baidu", "Runoob")



//用_去掉名字

//inout:传递引用
//func swapTwoInts(_ a: inout Int, _ b: inout Int) {
//    let temporaryA = a
//    a = b
//    b = temporaryA
//}


var x = 1
var y = 5

////没有默认的名字
//swapTwoInts(&x, &y)
//print("x 现在的值 \(x), y 现在的值 \(y)")


func aa(a:Int, b:Int){
    print("a=\(a),b=\(b)")
}

aa(a: 1, b: 2);

////默认是有名字的
//func swapTwoInts2(a: inout Int, b: inout Int, c: Int) {
//    let temporaryA = a
//    a = b
//    b = temporaryA
//}
//var x2 = 1
//var y2 = 5
//
//
//swapTwoInts2(a: &x2,b: &y2,c: 3)
//
//print("x2 现在的值 \(x2), y2 现在的值 \(y2)")
//




//
//
//func swapTwoInts3(_ a:   Int, _ b:   Int) {
//    let temporaryA = a
//
//    //Cannot assign to value: 'a' is a 'let' constant
//    a = b
//    //Cannot assign to value: 'b' is a 'let' constant
//    b = temporaryA
//}
//
//
//var x3 = 1
//var y3 = 5
//
//
//
//swapTwoInts3(x3, y3)
//print("x3 现在的值 \(x3), y3 现在的值 \(y3)")

func inputs(no1: Int, no2: Int) -> Int {
    return no1/no2
}
print(inputs(no1: 20, no2: 10))
print(inputs(no1: 36, no2: 6))

//Function types cannot have argument labels; use '_' before 'a'
//var addition: ( a:Int,  b:Int) -> Int = sum


var addition: (_ a:Int, _ b:Int) -> Int = sum


var addition2: (Int,  Int) -> Int = sum



//定义函数，有函数名字、参数、返回值、实现体
func sum(a: Int, b: Int) -> Int {
    return a + b
}
sum(a: 1, b: 3)

//addition(a:1,b:3)
addition(1,3)
addition2(1,3)
//addition3(1,3)




let names = ["AT", "AE", "D", "S", "BE"]

// 使用普通函数(或内嵌函数)提供排序功能,闭包函数类型需为(String, String) -> Bool。
func backwards(s1: String, s2: String) -> Bool {
    return s1 > s2
}


var reversed = names.sorted(by: backwards)

// {}可以代替函数类型的变量
var reversed2 = names.sorted(by: {
    //函数参数类型参数列表、返回类型、in 实现体 返回值
    (s1: String, s2: String) -> Bool in
    return s1 >  s2
})

print(reversed2)

var reversed3 = names.sorted(by: {
    //参数没有了，in也不需要、也不用return 直接
    $0 >  $1
})

print(reversed3)


//尾随闭包
//by这个名字都不要了， 在结尾直接加上花括号：参数省略了，in省略了，return省略了
var reversed4 = names.sorted() {$0 > $1}
print(reversed4)


//闭包可以在其定义的上下文中捕获常量或变量。

//返回的是一个闭包： () -> Int
func makeIncrementor(forIncrement amount: Int) -> () -> Int {
    var runningTotal = 0
    //incrementor没有声明任何的参数
    func incrementor() -> Int {
        //捕获参数runningTotal
        //捕获参数amount
        runningTotal += amount
        return runningTotal
    }
    return incrementor
}

let incrementByTen = makeIncrementor(forIncrement: 10)
let incrementByTen1 = makeIncrementor(forIncrement: 10)

// 返回的值为10
print(incrementByTen())
print(incrementByTen1())

// 返回的值为20
print(incrementByTen())
print(incrementByTen1())

// 返回的值为30
print(incrementByTen())
print(incrementByTen1())


//incrementByTen 不会拷贝的，是引用类型
let alsoIncrementByTen = incrementByTen

// 返回的值也为50
print(alsoIncrementByTen())




// 定义枚举
//枚举类型
enum DaysofaWeek {
    // 枚举定义放在这里
    //成员值 ,定义个枚举 需要加上case，不需要类型
    case Sunday
    case Monday
    case TUESDAY
    case WEDNESDAY
    case THURSDAY
    case FRIDAY
    case Saturday
    case asdfas
}

//先推断类型
var weekDay = DaysofaWeek.asdfas
//现在可以省去DaysofaWeek 名字了
weekDay = .asdfas

//这里明确写上类型，那么也是可以直接省去名字的，直接.赋值
//.Sunday成员值
var weekDay2:DaysofaWeek = .Sunday

switch weekDay2
{
case .Sunday:
    print("星期天：\(DaysofaWeek.Sunday)")
case .Monday:
    print("星期一")
case .TUESDAY:
    print("星期二")
case .WEDNESDAY:
    print("星期三")
case .THURSDAY:
    print("星期四")
case .FRIDAY:
    print("星期五")
case .Saturday:
    print("星期六")
default:
    print("星期100")
}



enum Student{
    //成员值 // 需要类型
    case Name(String)
    
    //
    case Mark(Int,Int,Int)
}



var studDetails = Student.Name("Runoob")
var studMarks = Student.Mark(98,97,95)
var studMarks3 = Student.Mark(100,2,3)

// 这就是类型的case, 对类型 进行switch - case
switch studDetails {
    
    // 小括号里面还要加上let， 不可以修改
case .Name(let studName):
    print("学生的名字是: \(studName)。")
    
    
    // 小括号里面加上let， 加上变量名字， 这用用来取值
case .Mark(let Mark1, let Mark2, let Mark3):
    print("学生的成绩是: \(Mark1),\(Mark2),\(Mark3)。")
}







enum Month: Int {
    //字符串，字符，或者任何整型值或浮点型值
    case January = 1, February, March, April, May, June, July, August, September, October, November, December
    
    //不能定义多个case了，因为上面的case设置原始值了
    //    case Day1 = 1, Day2, Day3
}

let yearMonth = Month.May.rawValue
print("数字月份为: \(yearMonth)。")



enum Month2: String {
    //字符串，字符，或者任何整型值或浮点型值
    case January = "1", February, March, April, May, June, July, August, September, October, November, December
    //不能定义多个case了，因为上面的case设置原始值了
    //case Day1="1", Day2="2"
}


//默认字符串就是名字May
let yearMonth2 = Month2.May.rawValue

//数字月份为: May。
print("数字月份为: \(yearMonth2)。")



//封装少量相关简单数据值。
//会被拷贝而不是被引用。
//实例是通过值传递而不是通过引用传递。
//不需要去继承

struct markStruct{
    var mark1: Int
    var mark2: Int
    var mark3: Int
    
    
    //名字init
    init(mark1: Int, mark2: Int, mark3: Int){
        self.mark1 = mark1
        self.mark2 = mark2
        self.mark3 = mark3
    }
}

print("优异成绩:")

//markStruct 构造方法
var marks = markStruct(mark1: 98, mark2: 96, mark3:100)
print(marks.mark1)
print(marks.mark2)
print(marks.mark3)

print("糟糕成绩:")
var fail = markStruct(mark1: 34, mark2: 42, mark3: 13)
print(fail.mark1)
print(fail.mark2)
print(fail.mark3)



class markClass : Equatable {
    var mark1: Int
    var mark2: Int
    var mark3: Int
    
    
    //名字init
    init(mark1: Int, mark2: Int, mark3: Int){
        self.mark1 = mark1
        self.mark2 = mark2
        self.mark3 = mark3
    }
    
    //
    //    //在类里面定义 需要添加static
    //    static func ==(left:markClass, right:markClass) -> Bool {
    //
    //        return left.mark1==right.mark1
    //               // && left.mark2==right.mark2
    //    }
    
}


func ==(left:markClass, right:markClass) -> Bool {
    
    return left.mark1==right.mark1
    // && left.mark2==right.mark2
}


var fail2 = markClass(mark1: 12313, mark2: 42, mark3: 13)
print(fail2.mark1)
print(fail2.mark2)
print(fail2.mark3)








var fail3 = markClass(mark1: 12313, mark2: 4212, mark3: 13)


if fail2 == fail3 {
    print("相等的")
}else{
    print("不等")
}

//引用同一个类实例则返回 true
if fail2 === fail3 {
    print("相等的")
}else{
    print("不等")
}



struct Number
{
    var digits: Int
    
    //定义存储属性的时候指定默认值
    let pi = 3.1415
    
    var aa: Int //默认构造函数 需要传递
    
    let aaa : Int = 23
    
    //延迟存储属性
    //当访问的时候才调用
    lazy var bb:markClass = markClass(mark1: 1, mark2: 2, mark3: 3)
    
    //构造时候就调用
    var cc:markClass = markClass(mark1: 1, mark2: 2, mark3: 3)
    
    static var quanjuValue = ""
    static var jisuanValue:Int {
        return 1
    }
    static var jisuanValu2:Int {
        set{
            
        }
        get{
            return 12123123;
        }
    }
    
    static var jisuanValu3 : Int  {
        return 12123123;
    }
    
    static var jisuanValu31 : Int  {
        set{
            
        }
        get{
            return 12123123;
        }
    }
    //    static var jisuanValu32 : Int  {
    ////        //有setter必须要有getter
    ////        set{
    ////
    ////        }
    //
    //    }
}

var n = Number(digits: 12345,aa: 12) //构造时候就调用 cc的赋值
n.digits = 67
//n.jis
Number.jisuanValu2

print("\(n.digits)")
print("\(n.pi)")
print("\(n.aa)")
print("\(n.aaa)")
print("\(n.bb)") //访问的时候才调用

//是一个常量，你不能修改它。
//n.aaa = 12


class sample {
    
    //一、存储属性
    var no1 = 0.0, no2 = 0.0
    var length = 300.0, breadth = 150.0
    
    
    //class和static作用一样的 ，定义类属性
    
    
    class var no4:Int {
        return 1231
    }
    
    
    static var no41:Int {
        return 1231
    }
    
    
    
    
    //二、计算属性
    var middle: (Double, Double) {
        //1、能够直接访问其他成员
        //2、能够对其他成员进行修改
        //3、当调用的时候才执行、构造的时候不执行
        
        
        //4、不能在get方法里面同时添加willset方法
        // willSet(newValue){
        //   print("将要被修改了,新的值=\(newValue), 老的值=\(no3)");
        // }
        
        // 读
        get{
            return (length / 2, breadth / 2)
        }
        //写
        set(axis){
            no1 = axis.0 - (length / 2)
            no2 = axis.1 - (breadth / 2)
        }
    }
    //三、属性观察器
    var no3 : Int = 1 {
        
        //new11是常量 不能修改
        willSet(new11){
            print("将要被修改了,新的值=\(new11), 老的值=\(no3)");
            
        }
        
        
        didSet{
            print("修改完了,  新的值=\(no3)");
            if (no3 > oldValue){
                print("增加了");
            }
            
        }
    }
    
    
    var ss:(Double){
        
        get {
            return no1;
        }
        
        set {
            no1 = newValue;
        }
    }
    
    // 参数 : (type)
    var metaInfo:( [String:String] ) {
        
        get   {
            return [
                "head": "123131",
                "duration":"123"
            ]
        }
        
    }
    
    //只读属性
    // 省略括号
    // : type
    var metInfo2:[String:String] {
        // 省略get
        return [
            "head": "123131",
            "duration":"123"
        ]
    }
}

var result3 = sample() //这里构造对象的时候不会调用计算属性
print(result3.middle)
result3.middle = (0.0, 10.0)


sample.no4

result3.no3 = 123123
for   a in  result3.metaInfo {
    print(a)
}
// (a,b)元组
for   (a,b) in  result3.metaInfo.enumerated() {
    // 索引，下标
    print(a)
    //字典， key，value
    print(b)
    print(b.key)
    print(b.value)
}
//只读属性没办法修改
//result3.metaInfo=["adfs":"asdfas"]

// (a,b)元组
for   (a,b) in  result3.metInfo2.enumerated() {
    // 索引，下标
    print(a)
    //字典， key，value
    print(b)
    print(b.key)
    print(b.value)
}
print(result3.no1)
print(result3.no2)



result3.ss = 123;
print(result3.no1)
print(result3.ss)


//花括号 里面定义函数，函数不需要名字： 只有参数、返回值类型、实现
var addition31 =
// 花括号 表示里面是函数
{
    // 有参数，有返回值
    (a:Int, b:Int) -> Int
    //有in
    in
    //有返回值
    return a+b;
}

var reversed31 = names.sorted(
    by:
        
        {
            //参数没有了，in也不需要、也不用return 直接
            $0 >  $1
        }
    
)

print(reversed31)


//尾随闭包

var reversed41 = names.sorted() {
    //by这个名字都不要了，
    //在结尾直接加上花括号：1、参数省略了，2、in省略了，return省略了
    $0 > $1
}
print(reversed41)

class film {
    var head = ""
    var duration = 0.0
    var a:Int = 1;
    
    deinit{
        print("film释放了")
    }
    //计算属性 类变量
    static var calValue:Int{
        //类变量 也可以用计算属性
        get{
            //
            return classdvalue;
        }
        set{
            //在这里修改值，也能触发观察对象
            classdvalue = newValue;
        }
    }
    
    //类变量也可以添加观察
    static var classdvalue:Int = 1 {
        willSet{
            print("新的值：\(newValue), 旧的值=\(classdvalue)")
        }
        didSet{
            print("设置完了，新的值是：\(classdvalue)")
        }
        
    }
    
    lazy var a2:Int = 1 {
        willSet(newValue){
            print("新的值：\(newValue), 旧的值=\(a2)")
        }
        didSet{
            print("设置完了，新的值是：\(a2)")
        }
    };
    
    
    //可以为除了延迟存储属性之外的其他存储属性添加属性观察器，也可以通过重载属性的方式为继承的属性（包括存储属性和计算属性）添加属性观察器。
    //1、延迟存储属性 不能添加属性观察期
    //2、有getter的时候不能添加观察期，不是继承的，当前的计算属性不能添加观察器
    //3、继承的 计算属性、存储属性 都可以添加观察期
    var someValue2:Int{
        get{
            return 1;
        }
        set(value){
            a = value;
        }
        //        willSet(newTotal){
        //            print("计数器: \(newTotal)")
        //        }
        //        didSet{
        //            if someValue2 > oldValue {
        //                print("新增数 \(counter - oldValue)")
        //            }
        //        }
    }
    //不是方法， 也不是尾随闭包
    //尾随闭包有in
    //这是一个计算属性，只有get方法
    var metaInfo: [String:String]
    {
        //可以省去get方法
        get{
            //这是计算属性，不是存储变量，不是懒加载
            //计算属性每次调用都会执行
            return [
                "head": self.head,
                "duration":"\(self.duration)"
            ]
        }
    }
    
    var count:Int = 0
    func incrementBy(no1:Int, no2:Int, waibuming no3:Int){
        count = no1/no2
        count = count + no3
        print(count)
    }
    
    
    func incrementBy2(_ no1:Int, no2:Int, waibuming no3:Int){
        count = no1/no2
        count = count + no3
        print(count)
    }
}

var movie:film? = film()
movie?.head = "Swift 属性"
movie?.duration = 3.09

print(movie?.metaInfo["head"]!)
print(movie?.metaInfo["duration"]!)

movie?.a2=1000;
film.classdvalue = 109;
film.calValue = 1000;

movie?.incrementBy(no1: 34, no2: 1,waibuming: 123)
movie?.incrementBy2(3, no2: 12,waibuming: 33)

movie = nil;


struct Map{
    var  lat:Double;
    var longt:Double;
    // Cannot assign to property: 'self' is immutable
    //    func configLat(lat:Double, longt:Double) {
    //        self.lat = lat;
    //        self.longt = longt;
    //    }
    
    mutating func configLat2(lat:Double, longt:Double) {
        self.lat = lat;
        self.longt = longt;
    }
    
    func log(){
        print("lat=\(lat),longt=\(longt)")
    }
    
    //结构体用static，类用class 定义类属性
    static func abs(number: Int) -> Int
    {
        if number < 0
        {
            return (-number)
        }
        else
        {
            return number
        }
    }
    
    
    //    class func abs2(number: Int) -> Int
    //     {
    //         if number < 0
    //         {
    //             return (-number)
    //         }
    //         else
    //         {
    //             return number
    //         }
    //     }
}

var item2:Map  = Map(lat: 1, longt: 2)
item2.log()

item2.configLat2(lat: 12, longt: 22)
item2.log()


class Math
{
    class func abs(number: Int) -> Int
    {
        if number < 0
        {
            return (-number)
        }
        else
        {
            return number
        }
    }
    static func abs2(number: Int) -> Int
    {
        if number < 0
        {
            return (-number)
        }
        else
        {
            return number
        }
    }
    
    //subscript使用subscript关键字，提供下标访问
    subscript(index:Int)->Int{
        return index+100;
    }
    
    //1、下标脚本允许任意数量的入参索引，并且每个入参类型也没有限制。
    
    //2、下标脚本的返回值也可以是任何类型。
    
    //3、下标脚本可以使用变量参数和可变参数。
    subscript(index:String)->String{
        return "\(index)+\(100)";
    }
    
    
    subscript(index:String, index2:Int, index3:Double)->String{
        return "\(index)+\(100)+\(index2)+\(index3)";
    }
}

class Math2:Math {
    func abs(number: Int) -> Int
    {
        if number < 0
        {
            return (-number)
        }
        else
        {
            return number
        }
    }
    
    func abs2(number: Int) -> Int
    {
        if number < 0
        {
            return (-number)
        }
        else
        {
            return number
        }
    }
}
let math2:Math = Math()
let a13 = Math.abs(number: -12)
let a14 = Math.abs2(number: -12)
let a12 = Math2.abs(number: -12)
let a15 = Math2.abs2(number: -12)
print("a12=\(a12),a13=\(a13),a14=\(a14),a15=\(a15)")
print("math2[1]=\(math2[1]),math2[2]=\(math2[2]) ")
let a16 = math2["1231"]
print("\(a16)")

let a17 = math2["1231",1,1.2121]
print("\(a17)")




class StudDetails
{
    
    //存储属性不能重写啊？？
    final var mark1: Int;
    
    
    var mark2: Int;
    var mark3: Int = 12;
    var mark4: Int;
    lazy var mark5: Int = 44;
    
    //计算属性可以重写
    final var mark6:Int{
        return mark1;
    }
    var mark7:Int{
        return mark1;
    }
    
    
    init(stm1:Int, results stm2:Int, mark44:Int,mark55:Int)
    {
        mark1 = stm1;
        mark2 = stm2;
        mark4 = mark44;
        mark5 = mark55;
    }
    
    func show()
    {
        print("Mark1:\(self.mark1), Mark2:\(self.mark2)")
    }
}

//继承父类，StudDetails： 超类、父类
class Tom : StudDetails
{
    //使用override 重写属性
    //Cannot override with a stored property 'mark1'
    //    override var mark1: Int {
    //        return super.mark1
    //    }
    
    //Property overrides a 'final' property
    //final属性不能重写
    //    override var mark6:  Int{
    //        return super.mark1
    //    }
    
    override var mark7:    Int{
        return super.mark1
    }
    
    
    init()
    {
        super.init(stm1: 93, results: 89,mark44: 12,mark55: 12313)
    }
    //使用 override 重写方法
    override func show() {
        print("Tom Mark1:\(self.mark1), Mark2:\(self.mark2)")
    }
}

let tom = Tom()
tom.show()

print("mark5=\(tom.mark5)")


struct Rectangle {
    
    
    //下面这几个属性 必须要在构造方法中初始化
    
    var length: Double
    var breadth: Double
    var area: Double
    
    let area2:Double
    
    //Return from initializer without initializing all stored properties
    //var area2: Double
    
    
    //可选属性类型, 不需要初始化
    var aa:Double?
    
    
    //构造方法1
    init(fromLength length: Double, fromBreadth breadth: Double) {
        self.length = length
        self.breadth = breadth
        area = length * breadth
        
        
        self.length =  1231+length;
        
        
        //在构造过程中，修改let 常量值
        self.area2 = 1231.1
    }
    
    //构造方法2
    init(fromLeng leng: Double, fromBread bread: Double) {
        self.length = leng
        self.breadth = bread
        area = leng * bread
        
        //Return from initializer without initializing all stored properties
        //在构造过程中，修改let 常量值
        self.area2 = 1231.1
        
        
    }
}

let ar = Rectangle(fromLength: 6, fromBreadth: 12)
print("面积为: \(ar.area)")

let are = Rectangle(fromLeng: 36, fromBread: 12)
print("面积为: \(are.area)")



class ShoppingListItem {
    
    //可选属性
    var name: String?
    var quantity = 111
    var purchased = false
    
    //默认构造器
    
    
    //构造
    init(name: String? = nil, quantity: Int = 1, purchased: Bool = false) {
        self.name = name
        self.quantity = quantity
        self.purchased = purchased
    }
    
    
    //手动重写默认构造器
    init(){
        
    }
    
    //构造，不要外部参数名字
    init(_ name: String? = nil, _ quantity: Int = 1, _ purchased: Bool = false) {
        self.name = name
        self.quantity = quantity
        self.purchased = purchased
    }
    
    
    
}
var item111 = ShoppingListItem()//默认构造器，没有参数



print("名字为: \(item111.name)")
print("数理为: \(item111.quantity)")
print("是否付款: \(item111.purchased)")


var item112 = ShoppingListItem(name:"1231",quantity:1,purchased:true)
print("名字为: \(item112.name)")
print("数理为: \(item112.quantity)")
print("是否付款: \(item112.purchased)")



var item113 = ShoppingListItem( "12312313", 1, true)
print("名字为: \(item113.name)")
print("数理为: \(item113.quantity)")
print("是否付款: \(item113.purchased)")


struct Size {
    var width = 0.0, height = 0.0
    init(width: Double = 0.0, height: Double = 0.0) {
        self.width = width
        self.height = height
    }
}


struct Point {
    var x = 0.0, y = 0.0
}

struct Rect {
    var origin = Point()
    var size = Size()
    
    //构造器
    init() {}
    
    //构造器，
    init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
    
    //构造器
    init(center: Point, size: Size) {
        let originX = center.x - (size.width / 2)
        let originY = center.y - (size.height / 2)
        
        //访问其他构造器
        self.init(origin: Point(x: originX, y: originY), size: size)
    }
}


// origin和size属性都使用定义时的默认值Point(x: 0.0, y: 0.0)和Size(width: 0.0, height: 0.0)：
let basicRect = Rect()
// Extra argument in call

print("Size 结构体初始值: \(basicRect.size.width),\(basicRect.size.height)")
print("Rect 结构体初始值: \(basicRect.origin.x),\(basicRect.origin.y)")

// 将origin和size的参数值赋给对应的存储型属性
let originRect = Rect(origin: Point(x: 2.0, y: 2.0),
                      size: Size(width: 5.0, height: 5.0))

print("Size 结构体初始值: \(originRect.size.width), \(originRect.size.height) ")
print("Rect 结构体初始值: \(originRect.origin.x), \(originRect.origin.y) ")


//先通过center和size的值计算出origin的坐标。
//然后再调用（或代理给）init(origin:size:)构造器来将新的origin和size值赋值到对应的属性中
let centerRect = Rect(center: Point(x: 4.0, y: 4.0),
                      size: Size(width: 3.0, height: 3.0))

print("Size 结构体初始值: \(centerRect.size.width), \(centerRect.size.height) ")
print("Rect 结构体初始值: \(centerRect.origin.x), \(centerRect.origin.y) ")

struct mainStruct{
    var name:String
    init(name: String) {
        self.name = name
    }
    //结构体 可以直接调用其他的构造器，
    //这叫做 ：构造器代理
    init(name:String,name2:String){
        self.init(name: name)
    }
}
class MainClass{
    var name:String
    
    
    
    init(name: String) {
        self.name = name
    }
    
    
    //    init(){
    //        self.init(name: "123123132")
    //    }
    
    //类，不能直接调用其他构造器，不支持构造器代理，需要添加关键字convenience，才可以调用其他构造器
    convenience init(name:String, name2:String){
        self.init(name: name);
        name2;
    }
    
}
class subMainClass:MainClass {
    deinit{
        print("析构")
    }
    var old:String
    init(old: String) {
        self.old = old
        super.init(name: old)
    }
    //convenience只有便利构造器才可以访问其他构造器，否则编译报错
    convenience init(old:String, aa:String){
        self.init(old: old)
    }
    
    
    // Designated initializer for 'subMainClass' cannot delegate (with 'self.init');
    //did you mean this to be a convenience initializer?
    //      init(old:String, aa:String,bb:String){
    //        self.init(old: old)
    //    }
    
    //添加问号，可失败构造器
    init?(name: String,name3:String?)  {
        if(name3 != nil) {
            //这里不需要return语句
            self.old = name3!;
            super.init(name: name3!)
        }else{
            //可失败构造器，返回nil
            return nil;
        }
    }
    override init(name: String) {
        
        self.old = name;
        super.init(name: name)
        
        //Property 'self.old' not initialized at super.init call
        //没有初始化还不能调用父类
        //self.old = name
    }
}

let main2 = MainClass(name: "123123");
print("main.name = \(main2.name)")

let main33 = subMainClass(name: "12313", name3: nil);
print("main33=\(main33)")


let struct1=mainStruct(name: "132123123")
let struct2=mainStruct(name: "1321",name2: "123123131")



enum EnumType{
    case Kvale,Cell,World
    
    
    //用感叹号和问号 都可以定义可失败构造器
    init?(symbol:Character,name:String,value:String,value2:String){
        //self.init(symbol: symbol, name: name, value: value)
        self.init(aa: symbol, b: 1)
    }
    init(aa:Character, b:Int){
        switch aa{
        case "K":
            self = .Kvale
        case "C":
            self = .Cell
        case "W":
            self = .World
        default:
            self = .Kvale
        }
    }
    // 非可失败构造器覆盖一个可失败构造器
    init(symbol:Character,name:String,value:String){
        // Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value
        //运行时错误
        self.init(symbol: symbol, name: name)
    }
    init!(symbol:Character,name:String){
        self.init(symbol: symbol)
    }
    init?(symbol:Character){
        switch symbol{
        case "K":
            self = .Kvale
        case "C":
            self = .Cell
        case "W":
            self = .World
        default:
            return nil;
        }
    }
    //Deinitializer cannot be declared in enum 'EnumType' that conforms to 'Copyable'
    //    deinit{
    //
    //    }
}

let aEnumType:EnumType?  = EnumType(symbol:"E",name: "12313",value: "D",value2: "13123")
print("\(aEnumType)")


if let a = EnumType(symbol: "K") {
    print("构造成功:\(a)")
}
if let a = EnumType(symbol: "A") {
    print("构造成功:\(a)")
}else{
    print("构造失败:\(a)")
}


var axigou:subMainClass? = subMainClass(name: "adsafs")
axigou=nil;


class Person {
    var residence: Residence? = Residence()
}

class Residence {
    //var numberOfRooms = 1
    //    init(numberOfRooms: Int = 1) {
    //        self.numberOfRooms = numberOfRooms
    //    }
    //
    
    var rooms = [Room]()
    
    var numberOfRooms:Int{
        return rooms.count
    }
    
    
    //下标访问1
    subscript(aa:Int) -> Room {
        //Fatal error: Index out of range
        return rooms[aa]
    }
    
    
    //下标访问2
    subscript(aa:Int,buildName:String,index:Int?) -> Room {
        return rooms[aa]
    }
    
    var address:Address?
    
    
    
}

class Room{
    let name:String
    init(name: String) {
        self.name = name
    }
}
class Address{
    var buildingName:String?
    var buildNumber:String?
    func buildIdentifer()->String?{
        if (buildNumber != nil) {
            return buildNumber
        } else if (buildingName != nil) {
            return buildingName
        } else {
            return nil;
        }
    }
    
}

let john = Person()


// 链接可选residence?属性，如果residence存在则取回numberOfRooms的值
if let roomCount = john.residence?.numberOfRooms {
    print("John 的房间号为 \(roomCount)。")
} else {
    print("不能查看房间号")
}
john.residence = nil;



if let roomCount = john.residence?.numberOfRooms {
    print("John 的房间号为 \(roomCount)。")
} else {
    print("不能查看房间号")
}



//Fatal error: Unexpectedly found nil while unwrapping an Optional value
//将导致运行时错误
//let roomCount = john.residence!.numberOfRooms


let aaA = Residence()
aaA.rooms = [Room(name: "1231")]
aaA.rooms.append(Room(name: "123asdfasfadsf"))



print("numberOfRooms=\(aaA.numberOfRooms)")


//下标访问
let aRoom:Room = aaA[1]
print("aroom.name=\(aRoom.name)")

//下标访问
let aRoom2:Room = aaA[0,"asdfa",nil]

print("aRoom2.name=\(aRoom2.name)")

john.residence = Residence()
john.residence?.rooms = [Room(name: "asdf")]

//Fatal error: Index out of range

//使用可选链调用下标
print("\(john.residence?[0].name)")


print("buildNumber=\(john.residence?.address?.buildNumber)")
let addr = Address()
addr.buildNumber = "1231"
john.residence?.address = addr
print("--->buildNumber=\(john.residence?.address?.buildNumber)")


var testScores = ["Dave": [86, 82, 84], "Bev": [79, 94, 81]]
testScores["Dave"]?[0] = 91
testScores["Bev"]?[0]+=1

//这里的调用会忽略掉，因为key Brian不存在
testScores["Brian"]?[0] = 72



if var  a = testScores["Dave"] {
    a[1] = 1888
    
    //常量数组，超过范围了
    //Fatal error: Index out of range
    //a[3] = 1888
    print(a)
} else {
    print("忽略了")
}






class Person1 {
    let name: String
    init(name: String) {
        self.name = name
        print("\(name) 开始初始化")
    }
    
    var appartment:Appartment?
    deinit {
        print("\(name) 被析构")
    }
}

class Appartment{
    let name:Int
    init(name: Int,tenant2:Person1) {
        self.name = name
        self.tenant = tenant2
        self.tenant2 = tenant2
    }
    
    //使用弱引用 解决循环引用导致内存不能释放的问题
    //weak  var  tenant:Person1?
    
    //使用无主引用
    unowned  var  tenant:Person1?
    
    //weak只用在可选变量， 所无主引用 适合不能非可选属性
    //String interpolation produces a debug description for an optional value;
    //did you mean to make this explicit?
    
    unowned var tenant2:Person1
    
    
    deinit{
        print("Appartment释放了")
    }
}

// 值会被自动初始化为nil，目前还不会引用到Person类的实例
var reference1: Person1?
var reference2: Person1?
var reference3: Person1?

// 创建Person类的新实例
reference1 = Person1(name: "Runoob")


//赋值给其他两个变量，该实例又会多出两个强引用
reference2 = reference1
reference3 = reference1

//断开第一个强引用
reference1 = nil
//断开第二个强引用
reference2 = nil
//断开第三个强引用，并调用析构函数
reference3 = nil





var person2:Person1?;
person2 = Person1(name: "nameapp")


var  appartment:Appartment?
appartment = Appartment(name: 1 ,tenant2: person2!)
//appartment?.tenant = person2


person2?.appartment = appartment


person2 = nil
appartment = nil



class HTMLElement {
    
    let name: String
    let text: String?
    
    
    // () -> String 闭包类型的变量asHtml
    lazy var asHTML: () -> String =
    
    {
        //[unowned self] in
        [weak self] in
        if let text = self?.text {
            return "<\(self?.name)>\(text)</\(self?.name)>"
        } else {
            return "<\(self?.name) />"
        }
    }
    
    init(name: String, text: String? = nil) {
        self.name = name
        self.text = text
        print("构造了：HTMLElement, \(self.name)")
    }
    
    deinit {
        print("\(name) is being deinitialized")
    }
    
}

// 创建实例并打印信息
var paragraph: HTMLElement? = HTMLElement(name: "p", text: "hello, world")
print(paragraph!.asHTML())
paragraph = nil





class Subjects {
    var physics: String
    init(physics: String) {
        self.physics = physics
    }
}

class Chemistry: Subjects {
    var equations: String
    convenience init(physics: String, equations: String, aa:String) {
        self.init(physics: physics, equations: equations)
    }
    
    init(physics: String, equations: String) {
        self.equations = equations
        super.init(physics: physics)
    }
}

class Maths: Subjects {
    var formulae: String
    init(physics: String, formulae: String) {
        self.formulae = formulae
        super.init(physics: physics)
    }
}

class Maths2 :Subjects {
    var formulae: String
    init(physics: String, formulae: String) {
        self.formulae = formulae
        super.init(physics: physics)
    }
}

// Heterogeneous collection literal could only be inferred to '[Any]';
//add explicit type annotation if this is intentional

let sa = [
    Chemistry(physics: "固体物理", equations: "赫兹"),
    Chemistry(physics: "热物理学", equations: "分贝"),
    
    
    Maths(physics: "流体动力学", formulae: "千兆赫"),
    Maths(physics: "天体物理学", formulae: "兆赫"),
    Maths(physics: "微分方程", formulae: "余弦级数"),
    
    Maths2(physics: "fasf", formulae: "asdfasfafd")
    
]



var chemCount = 0
var mathsCount = 0
var allCount = 0;
for item in sa {
    // 如果是一个 Chemistry 类型的实例，返回 true，相反返回 false。
    
    //操作符 is 来检查一个实例是否属于特定子类型。
    //若实例属于那个子类型，类型检查操作符返回 true，否则返回 false。
    if item is Subjects {
        allCount += 1
    }
    if item is Chemistry {
        chemCount += 1
    } else if item is Maths {
        mathsCount += 1
    }
}


print("化学科目包含 \(chemCount) 个主题，数学包含 \(mathsCount) 个主题")
print("所有科目包含 \(allCount) 个主题")




for item in sa {
    //Conditional cast from 'Subjects' to 'Subjects' always succeeds
    if let show = item as? Subjects {
        print("aalll主题是: '\(show.physics)' ")
        // 强制形式
    }
    // as? 可以是空，所以用if判断
    //如果是as! ，将触发运行时错误
    // 类型转换的条件形式
    if let show = item as? Chemistry {
        print("化学主题是: '\(show.physics)', \(show.equations)")
        // 强制形式
    } else if let example = item as? Maths {
        print("数学主题是: '\(example.physics)',  \(example.formulae)")
    }
    
    if item is Chemistry {
        //Could not cast value of type 'test_swift_program.Maths' (0x10002e4e0) to 'test_swift_program.Chemistry' (0x10002e400)
        //当你试图向下转型为一个不正确的类型时，强制形式的类型转换会触发一个运行时错误。
        let show = item as! Chemistry
        print("=------->化学主题是: '\(show.physics)', \(show.equations)")
    }
}


print("\n\n\n")

// 可以存储Any类型的数组 exampleany
var exampleany = [Any]()

exampleany.append(12)
exampleany.append(3.14159)
exampleany.append("Any 实例")
exampleany.append(Chemistry(physics: "固体物理", equations: "兆赫"))
let aData:Int? = exampleany[0] as? Int
//'Any' is not convertible to 'Int',编译报错
//let aData2:Int = exampleany[0] as Int
let aData3:Int = exampleany[0] as! Int






print("\(aData),\(aData3)")


for item2 in exampleany {
    switch item2 {
        
        // 在一个switch语句的case中使用强制形式的类型转换操作符（as, 而不是 as?）
        //来检查和转换到一个明确的类型。
        //as? , as!, as ????
    case var someInt as Int:
        someInt = 1000
        print("整型值为 \(someInt)")
        //where someDouble > 0:
    case let someDouble as Double where someDouble > 0:
        print("Pi 值为 \(someDouble)")
    case let someString as String:
        print("字符串： \(someString)")
    case let phy as Chemistry:
        print("主题 '\(phy.physics)', \(phy.equations)")
    default:
        print("None")
    }
}

print("---------")
for item in exampleany{
    print(item)
}



extension Int {
    var add: Int { return self + 100 }
    var sub: Int { return self - 10 }
    var mul: Int { return self * 10 }
    
    
    
    var div: Int { return self / 5 }
    
    var div1: Int {
        //计算型属性， 省略return
        self / 5 }
    
    
    
    
}

let addition1 = 3.add
print("加法运算后的值：\(addition1)")

let subtraction = 120.sub
print("减法运算后的值：\(subtraction)")

let multiplication = 39.mul
print("乘法运算后的值：\(multiplication)")

let division = 55.div
print("除法运算后的值: \(division)")

let division2 = 55.div1
print("除法运算后的值: \(division2)")

let mix = 30.add + 34.sub
print("混合运算结果：\(mix)")



class Person3{
    var name:String
    init(name: String) {
        self.name = name
    }
}

extension Person3 {
    convenience init(name:String, name2:String ) {
        self.init(name: name)
        print("name2=\(name2) convenience");
    }
    //不能向类中添加新的指定构造器或析构函数 deinit()
    //Deinitializers may only be declared within a class, actor, or noncopyable type
    //deinit{}
}

let aPerson3 = Person3(name: "123", name2: "hello");
print(aPerson3.name)



extension Int {
    func topics(summation: () -> ()) {
        for _ in 0..<self {
            summation()
        }
    }
    
    func topics2(summation: () -> (),data:Int) {
        for _ in 0..<self {
            summation()
        }
    }
}

4.topics(summation:   {
    print("扩展模块内")
})

3.topics(summation:  {
    print("内型转换模块内")
})
3.topics(){print("尾随闭包内型转换模块内")}


3.topics2(summation:  {
    print("尾随闭包内型转换模块内123123")
},
          data:12312);



extension Int {
    
    
    //添加新的类型
    enum calc
    {
        case add
        case sub
        case mult
        case div
        case anything
    }
    
    //添加新的计算属性
    var print: calc {
        switch self
        {
        case 0:
            return .add
        case 1:
            return .sub
        case 2:
            return .mult
        case 3:
            return .div
        default:
            return .anything
        }
    }
    
    //添加下标方法
    subscript(multtable: Int) -> Int {
        var powerOf10 = 1
        var index = multtable
        while index > 0 {
            powerOf10 *= 10
            index -= 1
        }
        return (self / powerOf10) % 10
    }
    
    //添加下标方法
    subscript(multtable1: String) -> Int {
        
        if let a =  Int(multtable1) {
            return a;
        } else {
            return 0;
        }
    }
}

print(12[0])     // 输出：2
print(7869[1])   // 输出：6
print(786543[2]) // 输出：5



print(786543["2"]) // 输出：2
print(786543["2asdfasdf"]) // 输出：0



func result(numb: [Int]) {
    for i in numb {
        switch i.print {
        case .add:
            print(" 10 ")
        case .sub:
            print(" 20 ")
        case .mult:
            print(" 30 ")
        case .div:
            print(" 40 ")
        default:
            print(" 50 ")
            
        }
    }
}

result(numb:[0, 1, 2, 3, 4, 7])

protocol Daysofaweek {
    mutating func show2()
    
    init(name:String);
}




enum Days :Daysofaweek{
    case sun, mon, tue, wed, thurs, fri, sat
    
    
    mutating func show2() {
        show()
    }
    
    init(name: String) {
        self = .sun
    }
    
    //值类型， 如果要修改值，需要用mutating 来修改
    //普通方法修改成员变量
    mutating func show() {
        switch self {
        case .sun:
            self = .sun
            print("Sunday")
        case .mon:
            self = .mon
            print("Monday")
        case .tue:
            self = .tue
            print("Tuesday")
        case .wed:
            self = .wed
            print("Wednesday")
        case .thurs:
            self = .thurs
            print("Thursday")
        case .fri:
            self = .fri
            print("Friday")
        case .sat:
            self = .sat
            print("Saturday")
        }
    }
}

var res = Days.wed
res.show()
res.show2()


class SomClass{
    var data:String
    
    let data2:String
    
    init(data: String) {
        self.data = data
        self.data2 = data
    }
    //mutating在类里面用不到 包错
    //    mutating  func modifyData22(name:String ){
    //        data = name
    //    }
    
    func modifyData(name:String ){
        data = name
    }
    
    //    //常量只能在构造方法中修改，   在普通方法中不能修改,也不能在便利构造方法中修改
    //      func modifyData2(name:String ){
    //        data = name
    //        data2 = name
    //    }
    //
    
    
    
    convenience init(data2:String){
        
        self.init(data: data2)
        //Cannot assign to value: 'data2' is a 'let' constant
        
        //也不能在便利构造方法中修改
        //data2="afsfdaf"
    }
    
}

let somDaat = SomClass(data: "1231")
somDaat.modifyData(name: "helloo")
print(somDaat.data)



protocol TcpProtocol {
    init(name:String)
    func   someMethod();
}

class TcpClass:TcpProtocol{
    var name:String
    //标示required ,是协议里面的方法,如果没有required，编译报错：
    // Initializer requirement 'init(name:)' can only be satisfied by a 'required' initializer in non-final class 'TcpClass'
    required init(name: String) {
        self.name = name
        print("TcpClass init")
    }
    
    //    //convenience只能用在init名字的方法上
    //convenience' may only be used on 'init' declarations
    //    convenience init2(name:String){
    //        self.init(name: name)
    //    }
    
    
    //实现协议里面的方法
    func someMethod() {
        print("someMethod TcpClass")
    }
    
}


class SubTcpClass:TcpClass{
    //override多余的
    required  override init(name: String) {
        super.init(name: name)
        print("SubTcpClass init")
    }
    //override需要添加，重写父类的方法
    override func someMethod() {
        print("someMethod SubTcpClass")
    }
}
let aasub = SubTcpClass(name: "asdfasdfaf")
aasub.someMethod()


print("\n\n\n\n")

// 使用数组的迭代器
var items = [10, 20, 30].makeIterator()

//IndexingIterator<Array<Element>>
while let x = items.next() {
    print(x)
}

// 使用 `map` 函数
for list in [1, 2, 3].map(
    //闭包类型
    { //花括号里面是闭包：
        // 参数，i
        // in 关键字
        i in
        //执行体
        i * 5
        
    }
    
) {
    // 这里是for 循环 的花括号
    print(list)
}

// 直接打印数组
print([100, 200, 300])
print([1, 2, 3].map({ i in i * 10 }))



//class表示这个协议只能是类用，结构体不能用
protocol AgeClassificationProtocol :class {
    
    var age: Int { get }
    var age4: Int { get }
    var age5: Int { get }
    var age6: Int { get }
    
    
    //计算属性？
    var age2: Int {
        get
        set
    }
    
    //Property in protocol must have explicit { get } or { get set } specifier,编译报错
    //协议不能添加存储属性吗？
    //var age3: Int?
    
    
    func agetype() -> String
    
    
    init(name:String)
    
    
    
}
protocol AgeClassificationProtocol2 {
    
    var age: Int { get }
    var age4: Int { get }
    var age5: Int { get }
    var age6: Int { get }
    
    
    //计算属性？
    var age2: Int {
        get
        set
    }
    
    //Property in protocol must have explicit { get } or { get set } specifier,编译报错
    //协议不能添加存储属性吗？
    //var age3: Int?
    
    
    func agetype() -> String
    
    
    init(name:String)
    
    
    
}

// Non-class type 'somAgeStruct' cannot conform to class protocol 'AgeClassificationProtocol'

struct somAgeStruct:AgeClassificationProtocol2 {
    var age: Int
    
    var age4: Int
    
    var age5: Int
    
    var age6: Int
    
    var age2: Int
    
    func agetype() -> String {
        return "asdfadf"
    }
    
    init(name: String) {
        age=1;
        age4=123;
        age5=4;
        age6=213
        age2=321432
    }
    
    
}
class somAgeClass:AgeClassificationProtocol {
    var age5: Int
    
    var age: Int
    
    func agetype() -> String {
        return "fasdfasdfadf"
    }
    
    var age2: Int
    
    var name :String
    
    required init(name: String) {
        self.name = name
        age = 123
        age2 = 12313
        age5 = 123131
    }
    
    var age4:Int{
        return 1212
    }
    
    var age6:Int{
        get{
            return 1212
        }
        set{
            age2 = 1231
        }
        
    }
    
}

//和类一样
//is操作符用来检查实例是否遵循了某个协议。
//as?返回一个可选值，当实例遵循协议时，返回该协议类型;否则返回nil。
//as用以强制向下转型，如果强转失败，会引起运行时错误。
protocol HasArea {
    var area: Double { get }
}

// 定义了Circle类，都遵循了HasArea协议
class Circle: HasArea {
    let pi = 3.1415927
    var radius: Double
    var area: Double { return pi * radius * radius }
    init(radius: Double) { self.radius = radius }
}

// 定义了Country类，都遵循了HasArea协议
class Country: HasArea {
    var area: Double
    init(area: Double) { self.area = area }
}

// Animal是一个没有实现HasArea协议的类
class Animal {
    var legs: Int
    init(legs: Int) { self.legs = legs }
}

let objects: [AnyObject] = [
    Circle(radius: 2.0),
    Country(area: 243_610),
    Animal(legs: 4),
    Math()
]

for object in objects {
    // 对迭代出的每一个元素进行检查，看它是否遵循了HasArea协议
    
    //这里用 as?
    if let objectWithArea = object as? HasArea {
        print("面积为 \(objectWithArea.area)")
    } else {
        print("没有面积")
    }
}


print("\n\n\n\n\n\n")
for object in objects {
    
    switch object {
        
        //在swich-case 中用as
    case let objectWithArea as HasArea:
        print("面积为 \(objectWithArea.area)")
        
        
    default: print("没有面积")
    }
}


print("\n\n\n\n\n\n")
let a99:[Any] = ["asdfads",123,123.123,someDict,PersonNameComponents()]
for a in a99 {
    print(a)
}


func swapTwoInts(_ a: inout Int, _ b: inout Int) {
    let temporaryA = a
    a = b
    b = temporaryA
}
// //Int 值类型
//var numb1:Int = 100
//var numb2 = 200
//
//print("交换前数据: \(numb1) 和 \(numb2)")
//swapTwoInts(&numb1, &numb2)
//print("交换后数据: \(numb1) 和 \(numb2)")



// 定义一个交换两个变量的函数
func swapTwoValues<T>(_ a: inout T, _ b: inout T) {
    let temporaryA = a
    a = b
    b = temporaryA
}

var numb1 = 100
var numb2 = 200

print("交换前数据:  \(numb1) 和 \(numb2)")
swapTwoValues(&numb1, &numb2)
print("交换后数据: \(numb1) 和 \(numb2)")

var str1 = "A"
var str2 = "B"

print("交换前数据:  \(str1) 和 \(str2)")
swapTwoValues(&str1, &str2)
print("交换后数据: \(str1) 和 \(str2)")


print("\n\n\n\n\n\n")
struct Stack<Element> {
    var items = [Element]()
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    //Deinitializer cannot be declared in generic struct 'Stack' that conforms to 'Copyable'
    //结构体不需要析构
    //    deinit{
    //
    //    }
}


class StackClass<Element> {
    var items = [Element]()
    func push(_ item: Element) {
        items.append(item)
    }
    func pop() -> Element {
        return items.removeLast()
    }
    deinit{
        print("StackClass释放了")
    }
}


var stackOfStrings = Stack<String>()
print("字符串元素入栈: ")
stackOfStrings.push("google")
stackOfStrings.push("runoob")
print(stackOfStrings.items);

let deletetos = stackOfStrings.pop()
print("出栈元素: " + deletetos)

var stackOfInts:StackClass? = StackClass<Int>()
print("整数元素入栈: ")
stackOfInts?.push(1)
stackOfInts?.push(2)
print(stackOfInts?.items);
stackOfInts=nil


// 非泛型函数，查找指定字符串在数组中的索引
func findIndex(ofString valueToFind: String, in array: [String]) -> Int? {
    
    //enumerated方法可以获取下标
    for (index, value) in array.enumerated() {
        
        //如果内容为查找的内容，返回当前下标
        if value == valueToFind {
            // 找到返回索引值
            return index
        }
    }
    //下标是空
    
    return nil
}


let strings = ["google", "weibo", "taobao", "runoob", "facebook"]


if let foundIndex = findIndex(ofString: "runoob", in: strings) {
    print("runoob 的索引为 \(foundIndex)")
}


//协议

protocol Container {
    //关联类型 ItemType。
    //协议里面 范型名字， 下面所有需要用到类型的用这个名字替代,如果没有这个，协议里面这个怎么写呢
    associatedtype ItemType11
    
    
    // 添加一个新元素到容器里
    mutating func append(_ item: ItemType11)
    
    
    // 获取容器中元素的数
    var count: Int { get }
    
    
    // 通过索引值类型为 Int 的下标检索到容器中的每一个元素
    subscript(i: Int) -> ItemType11 { get }
}

// Stack 结构体遵从 Container 协议
struct Stack2<Element>: Container {
    
    var items = [Element]()
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    // Container 协议的实现部分
    mutating func append(_ item: Element) {
        self.push(item)
    }
    var count: Int {
        return items.count
    }
    
    
    subscript(i: Int) -> Element {
        return items[i]
    }
}



//用继承
class Container11<T> {
    
    
    
    // 添加一个新元素到容器里
    func append(_ item: T){}
    
    
    // 获取容器中元素的数
    var count: Int { get{return 1} }
    
    
    // 通过索引值类型为 Int 的下标检索到容器中的每一个元素
    subscript(i: Int) -> T?{
        return nil
    }
}
class Stack2Class22<T>  : Container11<T>  {
    
    var items = [T]()
    func push(_ item: T) {
        items.append(item)
    }
    func pop() -> T {
        return items.removeLast()
    }
    // Container 协议的实现部分
    override func append(_ item: T) {
        self.push(item)
    }
    override var count: Int {
        return items.count
    }
    
    override  subscript(i: Int) -> T? {
        return items[i]
    }
}

//extension Stack2Class22:Container{}


var tos = Stack2Class22<String>()
tos.push("google")
tos.push("runoob")
tos.push("taobao")
// 元素列表
print(tos.items)
// 元素个数
print( tos.count)









// Container 协议
protocol Container13 {
    associatedtype ItemType
    // 添加一个新元素到容器里
    mutating func append(_ item: ItemType)
    // 获取容器中元素的数
    var count: Int { get }
    // 通过索引值类型为 Int 的下标检索到容器中的每一个元素
    subscript(i: Int) -> ItemType { get }
}

// // 遵循Container协议的泛型TOS类型
struct Stack13<Element>: Container13 {
    // Stack<Element> 的原始实现部分
    var items = [Element]()
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
    // Container 协议的实现部分
    mutating func append(_ item: Element) {
        self.push(item)
    }
    var count: Int {
        return items.count
    }
    subscript(i: Int) -> Element {
        return items[i]
    }
}



// 扩展，将 Array 当作 Container 来使用
extension Array: Container13 {}
//extension Dictionary: Container13 {}

func allItemsMatch<C1: Container13, C2: Container13>
(_ someContainer: C1, _ anotherContainer: C2) -> Bool

//对范型进行约束

// 放在类型参数列表后面， 参数、返回值。类型
where

//第一个条件
C1.ItemType == C2.ItemType,

//第二个条件
C1.ItemType: Equatable

{
    
    // 检查两个容器含有相同数量的元素
    if someContainer.count != anotherContainer.count {
        return false
    }
    
    // 检查每一对元素是否相等
    for i in 0..<someContainer.count {
        if someContainer[i] != anotherContainer[i] {
            return false
        }
    }
    
    // 所有元素都匹配，返回 true
    return true
}
var tos13 = Stack13<String>()
tos13.push("google")
tos13.push("runoob")
tos13.push("taobao")

var aos13 = ["google", "runoob", "taobao"]
var aos14 =  Array<String>();
aos14.append("asdfasf")
aos14[0]
//associatedtype ItemType
//// 添加一个新元素到容器里
//mutating func append(_ item: ItemType)
//// 获取容器中元素的数
//var count: Int { get }
//// 通过索引值类型为 Int 的下标检索到容器中的每一个元素
//subscript(i: Int) -> ItemType { get }
aos14.count;


//var tos14 = Stack2Class22<String>()
//tos14.push("google")
//tos14.push("runoob")
//tos14.push("taobao")
//
//if allItemsMatch(tos13, tos14) {
//    print("匹配所有元素")
//} else {
//    print("元素不匹配")
//}



if allItemsMatch(tos13, aos14) {
    print("匹配所有元素")
} else {
    print("元素不匹配")
}



AClass(name: "12313")
AClass2(name: "sadfasf")

//文件内私有，只能在当前源文件中使用。
//AClass3(name: "sadfasf")






protocol HasArea1 {
    var area: Double { get }
}

// 定义了Circle类，都遵循了HasArea协议
class Circle1: HasArea1 {
    let pi = 3.1415927
    var radius: Double
    var area: Double { return pi * radius * radius }
    init(radius: Double) { self.radius = radius }
}

// 定义了Country类，都遵循了HasArea协议
class Country1: HasArea1 {
    var area: Double
    init(area: Double) { self.area = area }
}

// Animal是一个没有实现HasArea协议的类
class Animal1 {
    var legs: Int
    init(legs: Int) { self.legs = legs }
    
    subscript(index:Int)-> Int?{
        if(index > 0){
            return 1;
        } else {
            return nil;
        }
        
    }
}

let objects1: [AnyObject] = [
    Circle1(radius: 2.0),
    Country1(area: 243_610),
    Animal1(legs: 4)
]

let cc = Animal1(legs: -1)
if let  c = cc[1] {
    print("c=\(c)")
} else {
    print("nil")
    
}

if let  c = cc[-100] {
    print("c=\(c)")
} else {
    print("nil")
}
//Variable 'c' was never mutated; consider changing to 'let' constant
if var  c = cc[122] {
    c=199
    print("c=\(c)")
} else {
    print("nil")
}


var testScores1 = ["Dave": [86, 82, 84], "Bev": [79, 94, 81]]
testScores1["Dave"]?[0] = 91
testScores1["Bev"]?[0]+=1

//这里的调用会忽略掉，因为key Brian不存在
testScores1["Brian"]?[0] = 72
//Cannot assign through subscript: 'a' is a 'let' constant
if let  a = testScores1["Brian"] {
    //a[0] = 12
} else {
    print("忽略了")
}





for object in objects {
    // 对迭代出的每一个元素进行检查，看它是否遵循了HasArea协议
    //Variable 'objectWithArea' was never mutated; consider changing to 'let' constant
    //if语句后面可以let 也可以var，如果是var则可以修改值，如果是let是常量不能再修改
    //switch-case中的case 也是一样，可以let 也可以是 var
    //case var someInt as Int:
    if var objectWithArea = object as? HasArea {
        print("面积为 \(objectWithArea.area)")
    } else {
        print("没有面积")
    }
}




func dowork(task:()->(), task2:()->(),task3:@escaping()->()) -> Void{
    task();
    task2();
    DispatchQueue.main.asyncAfter(deadline:DispatchTime.now()+1.0, execute: {
        
        task3();
    })

}

dowork(task: {
    print("dowork1")
}, task2:{
    print("dowork2")
},task3: {
    print("dowork3")
})

dowork (task: {
    print("dowork111")
}, task2:{
    print("dowork222")
}) {
    print("dowork333")
}




 
class Cell {
    lazy var xxview:String = {
        //懒加载存储属性， 只调用一次初始化
        print("懒加载")
        return "12313"
    }()
    //懒加载不能用计算属性
    //'lazy' cannot be used on a computed property
//    lazy var xxview2:String {
//        get{
//            print("懒加载 计算属性")
//            return "12313"
//        }
//        set{
//            
//        }
//    }
    
    var xxview34:String{
        get{
            //计算属性，每次都执行get
            print("懒加载 计算属性")
            return xxview
        }
        set{
            xxview = newValue
        }
    }
}



let acell = Cell()
print("\(acell.xxview)")
print("\(acell.xxview)")
print("\(acell.xxview)")
acell.xxview = "hellowooo";
print("\(acell.xxview)")
print("\(acell.xxview34)")
print("\(acell.xxview34)")


//或括号表示是一个闭包函数
let afunc = {
    print("111111")
    print("222222")
}
let afunc11 = {
    (  x : String, y:Int ) in
    print("111111")
    print("222222")
    print("333333--->\(x)")
    print("44444--->\(y)")
}

let afunc2:()->() = afunc;
afunc2();

let afunc3:(String,Int)->() = afunc11;
afunc3("hellooooo",12);

//Constant 'afunc33' inferred to have type '()', which may be unexpected
let afunc33 = {
    print("111111")
    print("222222")
    print("123123123123")
//    return "9999"
}()
//afunc33


let afun44 = {
    print("111111")
    print("222222")
    print("123123123123")
    return "9999"
}()//表示立即调用
 print("\(afun44)")

//'lazy' cannot be used on an already-lazy global
//懒加载属性不能用在全局，只能在类、结构体中用

//枚举里不能用懒加载，因为枚举中 存储属性都不用了
//lazy var afun445 = {
//    print("111111")
//    print("222222")
//    print("123123123123")
//    return "9999"
//}()//表示立即调用
// print("\(afun445)")

enum aaEnum{
    case first,second
    
    
//    //枚举不能用存储属性
//    lazy var ss:String = {
//        return "asdfasdf"
//    }()
//    
}

let aaenumobj = aaEnum.first;
switch aaenumobj{
case .first:
    print("firset")
case .second:
    print("asdfasdfasdf second")
}

struct aaenumstru{
 
    //结构体中可以用懒加载属性
    lazy var ss:String = {
        print("懒加载")
        return "asdfasdf9999"
    }()
    
}
 
var ccstr = aaenumstru()
print("\(ccstr.ss)")
print("\(ccstr.ss)")
print("\(ccstr.ss)")


 
func test11() -> Void {
    //1、guard必须要使用在函数内部
    //2、guard必须有else
    //满足条件的后面语句，不满足条件在else中
    guard testScores1["Brian"] != nil else {
        //else闭包中必须跟一个中断往后执行的关键字或者方法等，如return、continue、break、fatalError、throw等，
        
        //不要在else放入复杂代码，不要多过2-3行
        return
    }
    //这里不需要或括号
    print("guard")

}
test11()


func testReturn()->Bool {
    print("123131211111111")
    return true;
}
//使用_接受返回值，去掉编译器警告
_ =  testReturn()
//Result of call to 'testReturn()' is unused
testReturn()

class SectionsClassA{
    var sections:[Int]?
}

class SectionsClass {
    var data:SectionsClassA?
    var sections:[Int]? = [Int](){
        //属性观察器监控和响应属性值的变化，每次属性被设置值的时候都会调用属性观察器
        //不仅是赋值，操作也能监听
        didSet{
            print(sections)
            if  data?.sections != sections {
                print("set")
            }else{
                print("not set")
            }
        }
    }
}
var obj99:SectionsClass = SectionsClass()
obj99.sections?.append(1);
obj99.sections?.append(2);
obj99.sections = [12,22]



class xxVc{
    var xxViewObj:xxView = xxView()
    //修改vc的sections， 自动修改view的sections
    
    var sections:[Int] = [Int]() {
        didSet{
            print("1111")
            xxViewObj.sections=sections

        }
    }
}
class xxView{
    
    var aa:SectionsClass = SectionsClass()
    
    
    //修改view的sections，将会去修改某个model的sections
    var sections:[Int] = [Int]() {
        didSet{
            print("2222")
            aa.sections = sections

        }
    }
    
    func configXX() -> Void {
        //成员方法中修改属性，也会触发属性观察器的方法被调用
        dd = 111;
    }
    
    var dd:Int = 1 {
        didSet {
            print("方法内修改dd 出发didset")
        }
    }
}

var xxVcObj = xxVc()
xxVcObj.sections=[1]
xxVcObj.xxViewObj.configXX()
