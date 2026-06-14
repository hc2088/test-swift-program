# Swift 中级、高级、资深面试题与答案

本文档用于系统准备 Swift 面试，覆盖 Swift 语言基础、类型系统、协议与泛型、ARC、闭包、并发、性能、工程架构、Swift 6 迁移和资深级设计判断。

建议学习方式：

1. 先按级别通读，不会的题先标记。
2. 第二遍只看题目，自己口述 1 到 3 分钟答案。
3. 第三遍专攻高级和资深题，重点练“机制、取舍、落地方案”。
4. 每个大题都可以按这个公式回答：结论、原理、代码例子、坑点、项目经验。

适用范围：

- 中级：能写稳定业务代码，理解 Swift 常用语言特性和 ARC。
- 高级：能解释底层机制、并发模型、性能和泛型协议设计。
- 资深：能做架构取舍、迁移方案、公共库设计、性能治理和团队规范。

---

## 一、中级 Swift 面试题

### 1. `let` 和 `var` 的区别是什么

**答案：**

`let` 声明常量，绑定之后不能重新赋值；`var` 声明变量，可以重新赋值。

需要注意的是，对引用类型来说：

```swift
final class User {
    var name: String
    init(name: String) { self.name = name }
}

let user = User(name: "A")
user.name = "B"       // 可以，因为 user 指向的对象内部可变
// user = User(name: "C") // 不可以，因为 let 绑定不能改
```

面试里要说清楚：`let` 限制的是“变量绑定”本身，不一定限制对象内部状态。

### 2. Swift 为什么强调类型安全

**答案：**

Swift 是静态、强类型语言，编译期会尽量发现类型错误，减少运行时崩溃。比如 `String` 不能直接赋值给 `Int`，非 Optional 类型不能为 `nil`。

类型安全的好处：

- 减少空指针、类型转换错误。
- 提升可读性和重构安全性。
- 编译器可以做更多优化。

### 3. Optional 的本质是什么

**答案：**

`Optional` 本质是一个泛型枚举：

```swift
enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}
```

`String?` 等价于 `Optional<String>`。它表示一个值可能存在，也可能不存在。

常见解包方式：

- `if let`
- `guard let`
- `??`
- optional chaining，如 `user?.name`
- 强制解包 `!`，业务代码里应谨慎使用

### 4. `if let` 和 `guard let` 怎么选

**答案：**

`if let` 适合局部范围内使用解包值；`guard let` 适合提前退出，让主流程保持扁平。

```swift
func update(name: String?) {
    guard let name else { return }
    print(name)
}
```

面试回答重点：`guard` 解包后的变量在后续作用域可用，常用于参数校验、提前失败、减少嵌套。

### 5. `??` 空合并运算符有什么特点

**答案：**

`a ?? b` 表示如果 `a` 有值就返回 `a`，否则返回默认值 `b`。

```swift
let title = model.title ?? "Untitled"
```

右侧表达式是延迟求值的，只有左侧为 `nil` 时才会执行。

### 6. `struct` 和 `class` 的核心区别是什么

**答案：**

`struct` 是值类型，赋值和传参通常体现为值语义；`class` 是引用类型，赋值和传参传递引用。

区别：

| 对比点 | `struct` | `class` |
| --- | --- | --- |
| 语义 | 值语义 | 引用语义 |
| 继承 | 不支持 | 支持 |
| ARC | 通常不参与引用计数 | 参与 ARC |
| `deinit` | 不支持 | 支持 |
| 恒等判断 | 不支持 `===` | 支持 `===` |
| 线程安全倾向 | 更容易隔离状态 | 共享状态更需同步 |

选择建议：模型数据、不可变状态优先 `struct`；需要共享身份、继承、生命周期管理时用 `class`。

### 7. 值类型一定在栈上，引用类型一定在堆上吗

**答案：**

不能这么绝对。

值类型和引用类型描述的是语义，不是固定内存位置。编译器可能把值类型放在栈上，也可能因为逃逸、泛型、闭包捕获、装箱等放到堆上。类实例通常在堆上，但引用变量本身可能在栈上。

面试里要答：Swift 的 `struct` 是值语义，不等于一定栈分配。

### 8. 什么是值语义

**答案：**

值语义指一个变量的修改不会影响另一个变量。

```swift
var a = [1, 2]
var b = a
b.append(3)
print(a) // [1, 2]
print(b) // [1, 2, 3]
```

Swift 标准库的 `Array`、`Dictionary`、`Set` 是值类型，并通过 Copy-on-Write 优化避免不必要复制。

### 9. `enum` 的关联值和原始值有什么区别

**答案：**

原始值是每个 case 固定绑定一个字面量值：

```swift
enum Status: Int {
    case ok = 200
    case notFound = 404
}
```

关联值是每次创建 case 时携带不同数据：

```swift
enum ResultState {
    case success(Data)
    case failure(Error)
}
```

一句话：原始值适合固定映射，关联值适合表达状态和数据的组合。

### 10. `String` 为什么不能直接用整数下标

**答案：**

Swift 的 `String` 基于 Unicode，字符可能由多个 Unicode scalar 组成，一个用户看到的字符不一定等于一个字节或一个固定长度单元。

因此 Swift 使用 `String.Index`：

```swift
let text = "Swift"
let first = text[text.startIndex]
```

这样可以保证按字符边界访问，不破坏 Unicode 正确性。

### 11. `Array`、`Set`、`Dictionary` 的使用场景分别是什么

**答案：**

- `Array`：有序集合，需要按顺序访问、下标访问。
- `Set`：无序不重复集合，关注是否包含某元素。
- `Dictionary`：键值映射，通过 key 快速查 value。

常见复杂度：

- `Array` 下标访问通常是 O(1)，中间插入和删除通常是 O(n)。
- `Set` 和 `Dictionary` 平均查找、插入、删除通常是 O(1)，依赖哈希质量。

### 12. `map`、`filter`、`reduce`、`compactMap`、`flatMap` 区别是什么

**答案：**

- `map`：逐个转换。
- `filter`：按条件过滤。
- `reduce`：把序列聚合成一个结果。
- `compactMap`：转换并过滤掉 `nil`。
- `flatMap`：把嵌套序列拍平，或组合转换结果。

```swift
let numbers = [1, 2, 3]
let squares = numbers.map { $0 * $0 }
let even = numbers.filter { $0 % 2 == 0 }
let sum = numbers.reduce(0, +)
let values = ["1", "x", "2"].compactMap(Int.init)
```

### 13. 闭包是什么

**答案：**

闭包是可以捕获上下文的函数值。它可以赋值给变量、作为参数传递、作为返回值返回。

```swift
let add: (Int, Int) -> Int = { a, b in
    a + b
}
```

闭包会捕获它使用到的外部变量，捕获可能导致引用循环，需要注意 `[weak self]`。

### 14. `@escaping` 是什么

**答案：**

默认情况下，函数参数里的闭包是非逃逸的，即闭包只在函数调用期间执行。`@escaping` 表示闭包可能在函数返回后才执行，比如异步回调、存储到属性中。

```swift
func load(completion: @escaping (String) -> Void) {
    DispatchQueue.global().async {
        completion("done")
    }
}
```

逃逸闭包捕获 `self` 时更容易产生引用循环。

### 15. `@autoclosure` 是什么

**答案：**

`@autoclosure` 会把传入表达式自动包装成闭包，常用于延迟求值，让调用点更简洁。

```swift
func logIfNeeded(_ message: @autoclosure () -> String, enabled: Bool) {
    if enabled {
        print(message())
    }
}

logIfNeeded("expensive message", enabled: false)
```

常见例子是 `assert`、`??` 这类需要延迟计算的场景。

### 16. Swift 的访问控制有哪些

**答案：**

从严格到宽松大致是：

- `private`：当前声明作用域内可见。
- `fileprivate`：当前文件内可见。
- `internal`：当前模块内可见，默认级别。
- `public`：模块外可访问，但类不能被外部继承，方法不能被外部重写。
- `open`：模块外可访问、可继承、可重写，主要用于框架设计。

面试重点：`public` 和 `open` 的差异只对类和可重写成员特别关键。

### 17. `static` 和 `class` 修饰方法有什么区别

**答案：**

`static` 表示类型方法，不能被子类重写；`class` 也表示类型方法，但在类中可以被子类重写。

```swift
class A {
    static func foo() {}
    class func bar() {}
}

class B: A {
    override class func bar() {}
}
```

在 `struct` 和 `enum` 中只能使用 `static`。

### 18. `final` 有什么作用

**答案：**

`final` 可以修饰类、方法、属性，表示不能被继承或重写。

好处：

- 表达设计意图，防止误继承。
- 编译器可以做静态派发和内联优化。
- 减少动态派发成本。

业务代码里，如果类不需要继承，建议标记为 `final`。

### 19. 计算属性和存储属性有什么区别

**答案：**

存储属性保存实际值；计算属性不存储值，而是通过 getter 和可选 setter 计算。

```swift
struct Rect {
    var width: Double
    var height: Double
    var area: Double {
        width * height
    }
}
```

计算属性每次访问都会执行计算逻辑，如果复杂度不是 O(1)，设计 API 时最好明确说明。

### 20. 属性观察器 `willSet` 和 `didSet` 什么时候触发

**答案：**

属性观察器在属性被赋新值时触发：

- `willSet`：新值设置前触发，默认参数是 `newValue`。
- `didSet`：新值设置后触发，默认参数是 `oldValue`。

初始化期间给属性赋值不会触发观察器。观察器适合做轻量同步，不适合放复杂副作用。

### 21. `lazy` 属性有什么特点

**答案：**

`lazy` 属性第一次访问时才初始化，必须用 `var`，因为初次访问会改变对象状态。

```swift
final class Store {
    lazy var cache = [String: Data]()
}
```

注意：普通 `lazy` 不是天然线程安全的，多线程首次访问可能产生竞态，需要自行同步。

### 22. `mutating` 关键字的作用是什么

**答案：**

`struct` 和 `enum` 的实例方法默认不能修改 `self` 或属性。需要修改时必须加 `mutating`。

```swift
struct Counter {
    var value = 0

    mutating func increase() {
        value += 1
    }
}
```

它体现了值类型修改自身时需要显式声明。

### 23. Swift 初始化器有什么规则

**答案：**

初始化器要确保实例在使用前所有存储属性都有值。

类的初始化还涉及：

- designated initializer：指定初始化器。
- convenience initializer：便利初始化器。
- 两阶段初始化：先初始化本类属性，再调用父类初始化，之后才能使用 `self`。

`struct` 如果没有自定义初始化器，编译器会生成 memberwise initializer。

### 24. `deinit` 什么时候调用

**答案：**

类实例引用计数归零时调用 `deinit`。值类型没有 `deinit`。

常用于：

- 释放资源。
- 移除通知。
- 关闭文件句柄。
- 打印生命周期日志。

如果 `deinit` 没有调用，通常说明对象还被强引用，可能有内存泄漏。

### 25. ARC 是什么

**答案：**

ARC 是 Automatic Reference Counting，自动引用计数。编译器在合适位置插入 retain/release 逻辑，运行时根据引用计数管理类实例生命周期。

特点：

- 只管理引用类型实例，值类型通常不由 ARC 管。
- 不能自动解决强引用循环。
- `weak` 和 `unowned` 用于打破循环。

### 26. `weak` 和 `unowned` 有什么区别

**答案：**

`weak` 不增加引用计数，引用对象释放后会自动变成 `nil`，因此必须是 Optional。

`unowned` 不增加引用计数，释放后不会自动置空。如果对象已经释放再访问，会运行时崩溃。

选择：

- 生命周期不确定，用 `weak`。
- 被引用对象生命周期一定长于当前对象，用 `unowned`。

实际业务里，默认优先 `weak`，只有能严格证明生命周期关系时才用 `unowned`。

### 27. 闭包为什么容易造成循环引用

**答案：**

类强引用闭包，闭包又强捕获 `self`，就会形成循环：

```swift
final class ViewModel {
    var onChange: (() -> Void)?

    func bind() {
        onChange = {
            self.refresh()
        }
    }

    func refresh() {}
}
```

修复：

```swift
onChange = { [weak self] in
    self?.refresh()
}
```

面试要说明：不是所有闭包都要写 `[weak self]`，关键看闭包是否被 `self` 或长生命周期对象持有。

### 28. `defer` 的作用是什么

**答案：**

`defer` 会在当前作用域退出时执行，常用于资源清理、解锁、恢复状态。

```swift
lock.lock()
defer { lock.unlock() }

// critical section
```

多个 `defer` 按后进先出的顺序执行。

### 29. Swift 的错误处理方式有哪些

**答案：**

主要有：

- `throws` / `try` / `do-catch`：适合可恢复错误。
- `Result<Success, Failure>`：适合把结果作为值传递。
- Optional：适合只关心成功或失败，不关心原因。
- `fatalError` / `precondition`：适合不可恢复的编程错误。

```swift
func load() throws -> Data
```

面试重点：错误处理方案取决于调用方是否需要知道错误原因、是否要组合异步流程。

### 30. `try?` 和 `try!` 区别是什么

**答案：**

`try?` 把错误转换成 Optional，失败返回 `nil`。

`try!` 表示确信不会抛错，如果真的抛错会崩溃。

业务代码中应少用 `try!`，除非是本地静态资源、测试代码或逻辑上能严格保证不失败。

### 31. `Codable` 常见使用和坑点是什么

**答案：**

`Codable` 是 `Encodable & Decodable`，用于编码和解码。

常见坑：

- JSON key 和属性名不一致，需要 `CodingKeys`。
- 日期格式需要配置 `dateDecodingStrategy`。
- 数字和字符串类型不一致会解码失败。
- 字段缺失时，非 Optional 属性会失败。
- 复杂多态数据需要自定义 `init(from:)`。

### 32. `Any`、`AnyObject`、`any Protocol` 区别是什么

**答案：**

- `Any`：任意类型，包括值类型和引用类型。
- `AnyObject`：任意类实例。
- `any Protocol`：协议存在类型，表示一个符合协议的具体值被装进协议容器。

Swift 5.7 后推荐显式写 `any Protocol`，让“存在类型”语义更清楚。

### 33. `some Protocol` 是什么

**答案：**

`some Protocol` 是不透明类型。调用方只知道它符合某协议，但具体类型由实现方决定，并且同一个返回位置的具体类型必须一致。

```swift
func makeView() -> some Sequence {
    [1, 2, 3]
}
```

它通常比 `any Protocol` 更利于编译器优化，也保留了具体类型信息。

### 34. 协议和扩展有什么关系

**答案：**

协议定义能力，扩展可以给协议或具体类型添加默认实现。

```swift
protocol IdentifiableName {
    var name: String { get }
}

extension IdentifiableName {
    var displayName: String { name.uppercased() }
}
```

协议扩展是 Swift 面向协议编程的核心，但要注意协议扩展方法的派发规则，尤其是非协议要求的方法。

### 35. `Equatable`、`Hashable`、`Comparable` 分别有什么用

**答案：**

- `Equatable`：支持 `==`。
- `Hashable`：支持哈希，可作为 `Set` 元素和 `Dictionary` key。
- `Comparable`：支持排序比较，如 `<`。

Swift 可以为很多简单结构体自动合成这些协议实现。

### 36. `Result` 适合什么场景

**答案：**

`Result<Success, Failure>` 把成功和失败作为一个值返回，适合异步回调、状态存储、组合流程。

```swift
func load(completion: (Result<Data, Error>) -> Void)
```

如果是同步流程，`throws` 通常更自然；如果要把结果保存起来或传给另一个模块，`Result` 更方便。

### 37. `typealias` 有什么用

**答案：**

`typealias` 给已有类型起别名，提升可读性。

```swift
typealias Completion = (Result<Data, Error>) -> Void
```

它不会创建新类型，只是类型别名。公共 API 中使用时要避免隐藏过多真实语义。

### 38. `where` 可以用在哪些地方

**答案：**

`where` 用于增加约束，常见在泛型、协议扩展、switch、for 循环中。

```swift
extension Array where Element: Hashable {
    func containsDuplicate() -> Bool {
        Set(self).count != count
    }
}
```

这里要用 `Hashable`，因为 `Set` 依赖哈希；如果只要求 `Equatable`，就需要用 O(n²) 的遍历比较方案。

### 39. Swift 中 `switch` 有什么特点

**答案：**

Swift 的 `switch` 必须穷尽所有情况，不会默认贯穿到下一个 case。可以配合枚举、区间、元组、`where`、模式匹配。

```swift
switch point {
case (0, 0):
    print("origin")
case let (x, y) where x == y:
    print("diagonal")
default:
    break
}
```

### 40. Swift 的函数参数标签有什么作用

**答案：**

参数标签提升调用点可读性。默认情况下，第一个参数没有外部标签，后续参数有外部标签。

```swift
func move(from start: Point, to end: Point)
```

面试可补充：Swift API 设计强调调用点清晰，命名要让代码读起来接近自然语言。

### 41. `inout` 是什么

**答案：**

`inout` 允许函数修改传入变量。

```swift
func increment(_ value: inout Int) {
    value += 1
}

var count = 0
increment(&count)
```

它不是简单传指针语义，Swift 有独占访问检查，避免同一变量被同时读写造成内存安全问题。

### 42. `@objc` 和 `dynamic` 的作用是什么

**答案：**

`@objc` 暴露 Swift 声明给 Objective-C Runtime，常用于 selector、KVO、老 API 回调。

`dynamic` 强制使用动态派发，避免编译器静态化或内联，常用于需要运行时替换、KVO、动态行为的场景。

```swift
@objc dynamic var title: String = ""
```

### 43. Swift 和 Objective-C 混编时要注意什么

**答案：**

常见注意点：

- Swift 调 Objective-C 通过 bridging header。
- Objective-C 调 Swift 通过 `ProjectName-Swift.h`。
- 只有能暴露给 Objective-C 的 Swift 类型才能被 ObjC 使用，如继承 `NSObject` 的类、`@objc` 成员。
- Swift 的泛型、结构体、枚举关联值、部分协议特性不能直接暴露给 ObjC。
- Optional 会桥接成 nullable 语义，但要注意空值约定。

### 44. `guard` 为什么常用于提前返回

**答案：**

`guard` 强制失败路径退出当前作用域，成功路径继续向下执行，让主逻辑更清晰。

```swift
guard user.isLoggedIn else {
    showLogin()
    return
}

showHome()
```

它特别适合参数校验、权限校验、状态校验。

### 45. 中级面试中如何回答“Swift 的优点”

**答案：**

可以从五点回答：

1. 类型安全和 Optional 降低空值风险。
2. 值类型、枚举、模式匹配让状态建模更清晰。
3. 协议和泛型支持抽象复用。
4. ARC 自动管理引用类型生命周期。
5. async/await 和 actor 提供现代并发模型。

不要只说“语法简单”，要结合安全性、表达力、性能和工程可维护性。

---

## 二、高级 Swift 面试题

### 46. Swift 方法派发有哪些方式

**答案：**

常见派发方式：

- 静态派发：编译期确定调用目标，如 `final`、`struct`、`enum`、private 方法、泛型特化后调用。
- 虚表派发：类方法重写时通过 vtable 查找。
- witness table 派发：泛型约束调用协议要求时使用协议见证表。
- Objective-C 消息派发：`@objc dynamic`、继承 `NSObject`、selector 相关场景通过 ObjC Runtime。

面试追问：`final` 可以减少动态派发，有利于优化；协议扩展方法是否动态派发取决于它是不是协议 requirement。

### 47. 协议扩展里的方法为什么有时“不走多态”

**答案：**

如果方法是协议 requirement，并且类型实现了它，通过协议类型调用时会走 witness table，表现为动态派发。

如果方法只定义在协议扩展里，不是协议 requirement，通过协议存在类型调用时可能静态绑定到扩展默认实现。

```swift
protocol Animal {
    func speak()
}

extension Animal {
    func speak() { print("default") }
    func run() { print("default run") }
}

struct Dog: Animal {
    func speak() { print("dog") }
    func run() { print("dog run") }
}

let animal: any Animal = Dog()
animal.speak() // dog
animal.run()   // default run
```

面试重点：希望多态的方法必须放进协议定义里。

### 48. `any Protocol` 和泛型 `<T: Protocol>` 怎么选

**答案：**

`any Protocol` 是存在类型，适合异构集合、运行时存储不同具体类型。

泛型 `<T: Protocol>` 保留具体类型，适合同一种具体类型的强约束和性能优化。

```swift
func render<T: ViewModel>(_ model: T) {}
func store(_ model: any ViewModel) {}
```

选择：

- 需要保留类型关系和性能，用泛型。
- 需要隐藏具体类型或存储多种类型，用 `any`。

### 49. `some Protocol` 和 `any Protocol` 的核心区别是什么

**答案：**

`some Protocol` 是不透明类型，具体类型由实现方隐藏，但编译期仍知道它是某一个固定具体类型。

`any Protocol` 是存在类型，运行时可以装任意符合协议的值，可能有装箱和动态派发成本。

```swift
func makeNumbers() -> some Sequence<Int> {
    [1, 2, 3]
}

let value: any Sequence<Int> = [1, 2, 3]
```

一句话：`some` 隐藏类型但保留静态类型能力；`any` 擦除类型以换取灵活性。

### 50. 什么是协议的 associated type

**答案：**

`associatedtype` 是协议里的占位类型，由遵循协议的具体类型决定。

```swift
protocol Repository {
    associatedtype Entity
    func get(id: String) -> Entity?
}
```

它适合表达“协议能力中存在某个相关类型”。带有关联类型的协议不能像普通具体类型那样随意使用，需要用泛型、`some`、`any` 或类型擦除处理。

### 51. 什么是类型擦除

**答案：**

类型擦除是隐藏泛型或关联类型的具体类型，对外暴露统一包装类型。

典型例子：

- `AnySequence`
- `AnyPublisher`
- 自定义 `AnyRepository`

用途：

- 把带 associated type 的协议作为属性保存。
- 降低泛型向上传播。
- 隐藏实现细节。

代价是增加一层间接调用和包装复杂度。

### 52. Copy-on-Write 是什么

**答案：**

Copy-on-Write，简称 COW，表示多个值共享同一份底层存储，只有发生修改且存储不唯一时才复制。

Swift 的 `Array`、`Dictionary`、`Set`、`String` 都使用类似策略。

自定义 COW 常用 `isKnownUniquelyReferenced`：

```swift
final class Storage {
    var values: [Int]
    init(_ values: [Int]) { self.values = values }
}

struct Buffer {
    private var storage: Storage

    init(_ values: [Int]) {
        storage = Storage(values)
    }

    var values: [Int] {
        storage.values
    }

    mutating func append(_ value: Int) {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(storage.values)
        }
        storage.values.append(value)
    }
}
```

### 53. `isKnownUniquelyReferenced` 有什么注意点

**答案：**

它用于判断某个 class 实例是否只有唯一强引用，常用于实现 COW。

注意：

- 参数必须是 `inout`。
- 只能用于 class 引用。
- 多线程同时访问时不能单靠它保证线程安全。
- weak/unowned 引用不算强引用，但并发访问仍需要同步。

### 54. Swift 的内存独占访问规则是什么

**答案：**

Swift 要求对同一变量的修改访问具有独占性，避免同一内存位置同时读写或写写冲突。

```swift
func modify(_ x: inout Int, _ y: inout Int) {
    x += y
}

var value = 1
// modify(&value, &value) // 会触发独占访问问题
```

这属于 Swift 内存安全的一部分，可以在编译期或运行时检查。

### 55. Swift 的 ARC 和 Objective-C ARC 有什么关系

**答案：**

Swift 和 Objective-C 都使用 ARC 管理引用类型生命周期。Swift 类实例、闭包等会参与引用计数；值类型通常不参与。

混编场景中 Swift 对象和 Objective-C 对象可以桥接，引用计数需要遵守 ARC 规则。Core Foundation 仍可能涉及手动所有权约定，需要用桥接转换管理。

### 56. `weak` 引用为什么会自动置 nil

**答案：**

`weak` 是 zeroing weak reference，也就是清零弱引用。运行时会维护弱引用表，当对象释放时，把指向它的弱引用自动清空为 `nil`，避免悬垂指针。

代价是 weak 引用访问和维护比普通强引用更复杂，不适合在极高频路径滥用。

### 57. 闭包捕获列表的执行时机是什么

**答案：**

捕获列表在闭包创建时执行，捕获的是当时的值或引用。

```swift
var value = 1
let closure = { [value] in
    print(value)
}
value = 2
closure() // 1
```

如果捕获引用类型，捕获的是引用本身；对象内部状态仍可能变化。

### 58. `[weak self]` 和 `[unowned self]` 怎么选

**答案：**

`[weak self]` 捕获 Optional self，对象释放后为 `nil`，安全但需要解包。

`[unowned self]` 捕获非拥有引用，对象释放后访问会崩溃。

选择：

- UI 回调、网络回调、异步任务一般用 `[weak self]`。
- 闭包生命周期严格短于 self，且能证明 self 一定存在，可用 `[unowned self]`。

资深回答要补充：过度使用 weak 也可能让关键逻辑静默丢失，需要根据业务语义决定。

### 59. `lazy var` 捕获 `self` 会有什么问题

**答案：**

`lazy var` 初始化闭包在第一次访问时执行，可以访问 `self`。如果 `lazy` 属性本身存储一个闭包，并且闭包强捕获 `self`，会造成循环引用。

```swift
final class Controller {
    lazy var handler: () -> Void = {
        self.reload()
    }

    func reload() {}
}
```

修复方式是捕获列表或改成方法引用外部注入。

### 60. Swift 的泛型有什么性能优势

**答案：**

泛型让代码在保持类型安全的同时复用逻辑。编译器可以对泛型做特化，把泛型代码针对具体类型生成优化版本，减少动态派发和装箱成本。

但泛型过度使用也会带来：

- 编译时间变长。
- 错误信息复杂。
- 二进制体积可能增大。
- API 可读性下降。

### 61. 泛型约束有哪些常见写法

**答案：**

常见约束：

```swift
func maxValue<T: Comparable>(_ a: T, _ b: T) -> T {
    a > b ? a : b
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        Array(Set(self))
    }
}
```

也可以约束 associated type：

```swift
func consume<S: Sequence>(_ sequence: S) where S.Element == Int {}
```

### 62. ABI Stability 和 Module Stability 是什么

**答案：**

ABI Stability 指 Swift 编译产物的二进制接口稳定，使不同编译器版本构建的二进制在运行时能兼容。

Module Stability 指模块接口稳定，允许使用不同 Swift 编译器版本导入预编译框架，通常依赖 `.swiftinterface`。

iOS App 面试里可答：

- ABI 稳定降低系统运行时依赖问题。
- Module Stability 对二进制 SDK、闭源 framework 分发更关键。

### 63. `@inlinable` 是什么

**答案：**

`@inlinable` 允许跨模块暴露函数实现，给调用方编译器做内联和优化。

适合公共库中性能敏感的小函数，但要谨慎，因为函数实现会成为模块 ABI/API 承诺的一部分，后续修改自由度降低。

### 64. `@usableFromInline` 是什么

**答案：**

`@usableFromInline` 让 `internal` 声明可以被 `@inlinable` 的公开实现引用。

它常用于库设计：外部不能直接调用该声明，但跨模块优化时可以看到。

### 65. `throws`、`rethrows` 和 typed throws 的区别是什么

**答案：**

`throws` 表示函数可能抛错。

`rethrows` 表示函数本身不主动抛错，只在传入闭包抛错时才抛错。

Swift 6 引入 typed throws，可以指定错误类型：

```swift
enum ParseError: Error {
    case invalid
}

func parse(_ text: String) throws(ParseError) -> Int {
    guard let value = Int(text) else { throw .invalid }
    return value
}
```

typed throws 让错误类型更精确，适合泛型库、资源受限环境、需要强建模的领域错误。

### 66. Swift 并发里的 `async` 和 `await` 是什么

**答案：**

`async` 标记函数可能异步挂起，`await` 标记调用点可能发生挂起。

```swift
func loadUser() async throws -> User {
    try await api.fetchUser()
}
```

`await` 不是阻塞线程，而是允许当前任务挂起，让执行器调度其他任务。

### 67. 结构化并发是什么

**答案：**

结构化并发要求子任务生命周期受父任务管理，任务树有明确作用域。`async let` 和 `TaskGroup` 是典型工具。

好处：

- 生命周期清晰。
- 错误和取消可传播。
- 避免随意创建无人管理的后台任务。

### 68. `async let` 和 `TaskGroup` 怎么选

**答案：**

`async let` 适合固定数量、静态已知的并发任务：

```swift
async let user = loadUser()
async let orders = loadOrders()
let result = try await (user, orders)
```

`TaskGroup` 适合动态数量任务：

```swift
try await withThrowingTaskGroup(of: Image.self) { group in
    for url in urls {
        group.addTask { try await download(url) }
    }
    for try await image in group {
        handle(image)
    }
}
```

### 69. `Task` 和 `Task.detached` 有什么区别

**答案：**

`Task {}` 创建非结构化任务，但通常会继承当前上下文的一些信息，如优先级、actor 上下文。

`Task.detached {}` 创建脱离当前上下文的任务，不继承 actor 隔离，适合真正独立后台工作。

默认应少用 `detached`，因为它更容易破坏结构化并发、取消传播和隔离语义。

### 70. Swift 任务取消是怎么工作的

**答案：**

Swift 任务取消是协作式的。调用 `cancel()` 只是标记任务已取消，任务内部需要检查取消状态并主动退出。

常见方式：

```swift
try Task.checkCancellation()

if Task.isCancelled {
    return
}
```

网络、循环、图片处理等长任务要在关键节点检查取消。

### 71. `actor` 解决了什么问题

**答案：**

`actor` 用于保护可变共享状态，同一时间只允许一个任务访问 actor 隔离的可变状态，从语言层面降低数据竞争风险。

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func get() -> Int {
        value
    }
}
```

外部访问 actor 隔离成员通常需要 `await`。

### 72. actor reentrancy 是什么

**答案：**

actor 方法执行到 `await` 时可能挂起，actor 可以处理其他排队任务。原方法恢复时，actor 状态可能已经被其他任务修改，这就是 actor reentrancy。

```swift
actor Bank {
    var balance = 100

    func withdraw(_ amount: Int) async -> Bool {
        guard balance >= amount else { return false }
        await audit()
        balance -= amount
        return true
    }
}
```

上面代码在 `await audit()` 后应重新检查余额。资深面试里这是高频坑点。

### 73. `@MainActor` 是什么

**答案：**

`@MainActor` 是全局 actor，表示相关代码在主 actor 上执行，常用于 UI 更新。

```swift
@MainActor
final class ProfileViewModel {
    var name = ""

    func update(name: String) {
        self.name = name
    }
}
```

它不是简单等同于主线程 API，但在 Apple 平台上 UI 主 actor 通常对应主线程执行。

### 74. `Sendable` 是什么

**答案：**

`Sendable` 表示一个类型的值可以安全地跨并发边界传递。值类型且内部成员都是 `Sendable` 时通常容易满足；含有可变共享状态的 class 通常需要谨慎。

```swift
struct User: Sendable {
    let id: String
    let name: String
}
```

Swift 6 语言模式中，数据竞争安全检查更严格，`Sendable` 是并发迁移的核心概念。

### 75. `@unchecked Sendable` 什么时候使用

**答案：**

当编译器无法证明一个类型是线程安全的，但开发者能通过锁、队列、不可变设计等方式保证安全时，可以使用 `@unchecked Sendable`。

```swift
final class SafeBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
}
```

这是一种承诺，不能当作消除编译错误的快捷方式。需要代码审查和测试支撑。

### 76. `nonisolated` 有什么作用

**答案：**

`nonisolated` 让 actor 或全局 actor 类型中的成员不受该 actor 隔离，外部访问不需要 `await`。

适合：

- 不访问隔离可变状态的计算。
- 协议要求的同步属性。
- 常量元数据。

```swift
actor Worker {
    nonisolated var description: String {
        "Worker"
    }
}
```

### 77. continuation 是什么

**答案：**

continuation 用来把回调式 API 桥接成 async/await。

```swift
func load() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        legacyLoad { result in
            continuation.resume(with: result)
        }
    }
}
```

注意：checked continuation 必须且只能 resume 一次，否则会触发运行时检查或造成挂起。

### 78. `AsyncSequence` 适合什么场景

**答案：**

`AsyncSequence` 表示异步产生的一串值，适合事件流、分页、消息流、文件读取、通知流。

```swift
for await value in stream {
    print(value)
}
```

它比单次 async 返回更适合持续输出。面试可结合 Combine、Notification、网络长连接讲。

### 79. Swift 6 数据竞争安全检查是什么

**答案：**

Swift 6 语言模式把并发数据竞争检查推进到更严格的编译期诊断，目标是阻止非安全共享可变状态跨并发边界传递。

常见影响：

- 闭包需要 `@Sendable`。
- 跨 actor 访问需要 `await`。
- 非 Sendable 类型跨任务传递会警告或报错。
- 全局可变状态会被重点检查。

迁移思路：先打开 strict concurrency warning，分模块修复，再切 Swift 6 语言模式。

### 80. `@Sendable` 闭包是什么

**答案：**

`@Sendable` 表示闭包可以安全地跨并发边界执行。它会限制闭包捕获不安全的可变状态。

```swift
let work: @Sendable () async -> Void = {
    await service.load()
}
```

在 `Task`、并发回调、actor 边界中经常出现。

### 81. `DispatchQueue` 和 Swift Concurrency 怎么取舍

**答案：**

新代码优先使用 Swift Concurrency，因为 async/await、TaskGroup、actor 能表达结构化并发和隔离。

仍可能使用 GCD 的场景：

- 老代码维护。
- 与 C/ObjC API 兼容。
- 特定队列、barrier、低层同步需求。

迁移时不要机械替换，要保持取消、优先级、线程安全和生命周期语义。

### 82. `OperationQueue` 还有价值吗

**答案：**

有。`OperationQueue` 适合依赖图、暂停恢复、最大并发数、取消一组任务、与老项目集成。

Swift Concurrency 更适合语言级异步流程。复杂任务编排如果已有 Operation 抽象，不一定要立即重写。

### 83. Swift 的宏是什么

**答案：**

Swift 宏是编译期代码生成能力，可以减少样板代码。常见包括表达式宏、附加宏等。

例子：

```swift
#expect(value == 1)
```

宏适合生成重复、机械、可静态检查的代码。不适合隐藏复杂业务逻辑，否则会降低可读性和调试体验。

### 84. 属性包装器 Property Wrapper 的原理是什么

**答案：**

属性包装器把属性访问转发到包装类型的 `wrappedValue`，可选提供 `projectedValue`。

```swift
@propertyWrapper
struct Clamped {
    private var value: Int
    let range: ClosedRange<Int>

    var wrappedValue: Int {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }

    init(wrappedValue: Int, _ range: ClosedRange<Int>) {
        self.range = range
        self.value = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}
```

常见于 SwiftUI、依赖注入、UserDefaults、线程安全包装等。

### 85. KeyPath 有什么用

**答案：**

KeyPath 是属性路径的类型安全引用，可以把“访问某属性”作为值传递。

```swift
let names = users.map(\.name)
```

常用于排序、映射、绑定、通用配置、SwiftUI 数据流。

### 86. `Mirror` 反射适合做什么

**答案：**

`Mirror` 可以在运行时查看对象结构，适合调试、日志、简单序列化辅助。

不适合：

- 性能敏感路径。
- 依赖稳定字段顺序。
- 替代正式编码协议。

Swift 反射能力比 Objective-C Runtime 更受限。

### 87. Swift 中如何做线程安全

**答案：**

常见方案：

- 值语义和不可变数据，减少共享。
- actor 隔离可变状态。
- 串行队列或 barrier。
- `NSLock`、`os_unfair_lock`、Mutex。
- 原子类型或 Synchronization 库。

选择要看读写频率、临界区大小、是否需要 async、是否跨模块。

### 88. `NSLock`、串行队列、actor 怎么取舍

**答案：**

- `NSLock`：低层同步，适合小临界区，同步代码。
- 串行队列：适合老 GCD 模型、顺序化任务。
- actor：适合 Swift Concurrency 下保护异步可变状态。

不要在 actor 内长时间阻塞线程，也不要在锁里调用未知闭包或异步等待。

### 89. Swift 性能优化常见方向有哪些

**答案：**

常见方向：

- 避免不必要的类和动态派发。
- 合理使用 `final`、值类型和泛型。
- 减少中间数组，如链式 `map/filter` 在大数据上可能产生临时集合。
- 注意 `String` Unicode 操作成本。
- 避免主线程重活。
- 使用 Instruments 定位，不凭感觉优化。
- 对热点路径关注 ARC retain/release、桥接、锁竞争。

### 90. Swift 和 Objective-C 的方法动态性有什么差异

**答案：**

Objective-C 默认依赖消息发送和 Runtime，动态性强。Swift 默认更偏静态，很多调用在编译期决定，性能更好但动态替换能力弱。

Swift 要参与 ObjC Runtime 需要显式 `@objc`、继承 `NSObject` 或使用 `dynamic`。这也是 Swift 中 hook、KVO、selector 行为和 ObjC 不完全一样的原因。

---

## 三、资深 Swift 面试题

### 91. 资深工程师如何判断一个模型该用 `struct` 还是 `class`

**答案：**

判断维度：

- 是否需要身份：需要共享同一个实体身份，用 `class`。
- 是否需要继承：需要继承和重写，用 `class`。
- 是否表达不可变数据：优先 `struct`。
- 是否会跨线程共享：值类型更容易安全传递。
- 是否对象很大且频繁复制：考虑 COW 或引用存储。

项目建议：业务 DTO、状态快照、配置用 `struct`；服务对象、控制器、缓存、连接、生命周期实体用 `class`。

### 92. 如何设计一个 Swift 公共 SDK 的 API

**答案：**

重点：

- 调用点清晰，参数标签表达语义。
- public API 尽量稳定，避免暴露内部类型。
- 能用值类型表达结果就少暴露可变引用。
- 错误类型要稳定且可扩展。
- 异步 API 优先 async/await，同时视需要兼容回调。
- 二进制分发关注 Module Stability。
- 对性能敏感 API 谨慎使用 `@inlinable`。

资深回答要体现：API 一旦发布就是长期契约，少泄漏实现细节。

### 93. 大型项目如何做 Swift 模块化

**答案：**

常见方案：

- 按业务域拆 Feature 模块。
- 按基础能力拆 Core、Network、Storage、UIFoundation。
- 使用 SPM、framework 或 workspace 管理依赖。
- 通过协议或接口模块降低反向依赖。
- 避免公共模块变成杂物间。
- 控制模块数量，防止编译和依赖治理成本失控。

模块边界应围绕业务能力和所有权，而不是机械按文件夹拆。

### 94. 如何制定 Swift 6 并发迁移方案

**答案：**

可分阶段：

1. 升级工具链，保持 Swift 5 语言模式，打开 strict concurrency warning。
2. 先处理公共模型和基础库的 `Sendable`。
3. 标注 UI 层 `@MainActor`。
4. 梳理全局变量、单例、缓存、可变共享状态。
5. 用 actor 或锁封装并发敏感资源。
6. 将回调 API 逐步桥接到 async/await。
7. 分模块切到 Swift 6 语言模式。

关键不是“消警告”，而是建立并发边界和状态所有权。

### 95. 项目里如何避免 actor reentrancy 造成业务 bug

**答案：**

策略：

- `await` 前后不要默认状态不变。
- 在 `await` 后重新验证关键条件。
- 把状态修改放在没有挂起点的同步段里。
- 使用请求 id、版本号、状态机防止过期结果覆盖新状态。
- 对金融、库存、支付等强一致逻辑，谨慎拆分 actor 方法。

回答时最好举例：余额扣减、登录态刷新、图片请求返回覆盖 cell。

### 96. 如何设计一个线程安全缓存

**答案：**

先明确需求：

- 内存缓存还是磁盘缓存。
- 是否需要 LRU。
- value 是否 Sendable。
- 读多写少还是写多。
- 是否需要异步加载合并请求。

可选实现：

- 简单同步缓存：`NSCache` 或 lock。
- Swift Concurrency 项目：用 actor 管理字典和淘汰策略。
- 高性能读多写少：读写锁或分片锁。

actor 示例：

```swift
actor MemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    func value(for key: Key) -> Value? {
        storage[key]
    }

    func set(_ value: Value, for key: Key) {
        storage[key] = value
    }
}
```

资深点：缓存还要考虑容量、过期、内存警告、并发击穿、取消和指标监控。

### 97. 如何设计网络层的错误模型

**答案：**

错误模型应分层：

- 传输错误：无网络、超时、TLS。
- HTTP 错误：状态码、响应头。
- 业务错误：服务端 code/message。
- 解析错误：JSON 格式、字段缺失。
- 取消错误：用户主动取消或任务取消。

可以定义领域错误：

```swift
enum APIError: Error {
    case transport(Error)
    case invalidStatus(Int)
    case business(code: Int, message: String)
    case decoding(Error)
    case cancelled
}
```

资深回答要强调：错误既要方便 UI 展示，也要保留调试上下文和可观测性。

### 98. 如何选择 `throws`、`Result`、回调和 async/await

**答案：**

选择原则：

- 同步可失败操作：`throws`。
- 现代异步操作：`async throws`。
- 需要把结果作为值存储或传递：`Result`。
- 兼容老接口或 ObjC：回调。

公共 API 可以提供 async/await 主接口，再用兼容层包装回调。

### 99. 如何设计 Swift 中的依赖注入

**答案：**

常见方式：

- 初始化器注入：最清晰，适合必需依赖。
- 属性注入：适合可选依赖，但生命周期更松散。
- 协议抽象：方便测试替换。
- 环境对象或容器：适合大型应用，但要避免隐藏依赖。

资深建议：默认使用初始化器注入，不要一上来就全局 Service Locator。

### 100. 如何处理大型 Swift 项目的编译慢

**答案：**

排查方向：

- 使用编译耗时诊断，找慢表达式和慢函数类型检查。
- 拆分复杂泛型表达式，增加中间类型标注。
- 减少巨型 Swift 文件和巨型模块。
- 控制协议泛型嵌套和 SwiftUI 超长 View body。
- 合理模块化，提高增量编译命中。
- 减少不必要的跨模块依赖。

Swift 编译慢很多时候不是机器问题，而是类型推断和模块依赖复杂度问题。

### 101. 如何定位 Swift 内存泄漏

**答案：**

流程：

1. 复现路径，确认对象 `deinit` 不调用。
2. 用 Xcode Memory Graph 找引用链。
3. 用 Instruments Leaks/Allocations 看增长。
4. 检查闭包、Timer、Notification、KVO、delegate、Task、单例缓存。
5. 修复后重复进入退出页面验证。

高频泄漏点：

- 闭包强捕获 self。
- `Timer` 强持有 target。
- `NotificationCenter` 老 API 未移除。
- Task 长生命周期捕获对象。
- 缓存没有淘汰。

### 102. Swift Concurrency 下 Task 会不会导致泄漏

**答案：**

可能。`Task` 闭包会捕获对象，如果任务生命周期长于对象，就可能延长对象生命周期。

```swift
task = Task { [weak self] in
    guard let self else { return }
    await self.load()
}
```

还要在合适时机取消：

```swift
deinit {
    task?.cancel()
}
```

资深点：不是所有 Task 都要 weak，关键看任务所有权。如果 ViewModel 拥有任务，任务代表 ViewModel 的工作，强捕获可能合理，但要有取消策略。

### 103. 如何设计一个状态机

**答案：**

Swift 里适合用 enum 表达状态：

```swift
enum LoginState {
    case loggedOut
    case loggingIn
    case loggedIn(User)
    case failed(APIError)
}
```

好处：

- 状态和数据绑定。
- switch 穷尽检查。
- 避免多个 Bool 组合出非法状态。

资深设计要加入状态转移规则，不允许任意地方直接改状态。

### 104. 如何设计可测试的 Swift 代码

**答案：**

原则：

- 业务逻辑从 UI 和系统 API 中分离。
- 依赖通过协议注入。
- 时间、随机数、网络、存储都可替换。
- async 代码提供可等待的接口。
- 避免隐藏全局状态。

Swift 6 以后可以关注 Swift Testing，使用 `@Test`、`#expect` 等表达测试意图；已有项目仍可继续使用 XCTest。

### 105. 如何设计 Swift 错误的本地化展示

**答案：**

不要让底层错误直接决定 UI 文案。建议分层：

- 底层错误保留技术原因。
- 领域层转换为用户可理解的失败原因。
- UI 层根据场景展示文案和操作。

```swift
protocol UserDisplayableError {
    var message: String { get }
    var recoveryActionTitle: String? { get }
}
```

还要考虑埋点 code、重试策略和多语言。

### 106. 如何处理 Codable 模型版本兼容

**答案：**

策略：

- 新字段尽量用 Optional 或提供默认值。
- 用自定义 `init(from:)` 处理历史格式。
- 服务端字段变更时做兼容映射。
- 对枚举未知 case 做兜底。
- 本地持久化模型要有 schema version。

示例：

```swift
enum Status: Decodable {
    case active
    case disabled
    case unknown(String)
}
```

### 107. 如何设计一个可维护的协议体系

**答案：**

原则：

- 协议要小而具体，表达稳定能力。
- 不要为了 mock 强行抽象所有东西。
- associated type 会提高表达力，也会增加使用复杂度。
- 协议扩展默认实现不要隐藏重要业务行为。
- 公共协议要谨慎增加 requirement，因为会影响所有实现方。

资深点：协议是架构边界，不是为了“看起来面向协议”。

### 108. 什么时候不应该使用泛型

**答案：**

不适合泛型的场景：

- 只有一个具体类型使用。
- 泛型约束复杂到影响可读性。
- 错误信息和编译时间明显恶化。
- 运行时本来就需要异构集合，用 `any` 更自然。
- API 使用方不需要知道类型关系。

资深回答：泛型是表达类型关系的工具，不是消除重复的唯一工具。

### 109. Swift 中如何做性能基准测试

**答案：**

方法：

- 用 XCTest measure 或 Swift Testing 相关能力做微基准。
- 用 Instruments 做真实场景 profiling。
- Release 配置测试，不要只看 Debug。
- 关注时间、内存、分配次数、锁竞争、主线程占用。
- 每次只改一个变量，避免误判。

不要凭“值类型一定快”“泛型一定快”做结论。

### 110. 如何减少 ARC 开销

**答案：**

方向：

- 热路径优先使用值类型或避免不必要对象分配。
- 给不需要继承的类加 `final`。
- 避免闭包和对象在循环中频繁创建。
- 减少 Swift 与 ObjC 频繁桥接。
- 注意集合中存储大量 class 实例带来的 retain/release。
- 使用 Instruments 看 retain/release 热点。

不要为了减少 ARC 牺牲清晰所有权，除非有数据证明。

### 111. 如何理解 Swift 的所有权和非复制类型

**答案：**

Swift 正在增强所有权系统，`~Copyable` 非复制类型可以表达某些资源只能被消费或移动，避免隐式复制。它适合文件句柄、底层资源、嵌入式、高性能场景。

常见关键字包括 `borrowing`、`consuming` 等所有权相关语义。

面试回答可以说：普通 App 业务里暂时不一定高频手写，但资深工程师需要理解它代表 Swift 正在向更明确的资源生命周期和性能控制演进。

### 112. 如何看待 Swift 宏在团队中的使用

**答案：**

适合：

- 消除重复样板代码。
- 生成可预测、可静态检查的代码。
- 测试断言、路由注册、序列化辅助、依赖声明等。

不适合：

- 隐藏复杂业务逻辑。
- 生成难以调试的大段代码。
- 让团队成员无法通过源码理解行为。

团队应建立宏使用规范和 code review 标准。

### 113. 如何设计 Swift 与 Objective-C 混编迁移

**答案：**

策略：

- 新业务优先 Swift，稳定老模块不强行重写。
- 先从边界清晰的工具、模型、服务层迁移。
- 保持 ObjC 暴露 API 简单，减少 Swift 特性泄漏到 ObjC。
- 对动态特性、KVO、method swizzling 保持谨慎。
- 建立 nullability、泛型轻量标注，改善 Swift 调用体验。

迁移目标不是“全部 Swift”，而是降低维护成本和风险。

### 114. 如何设计一个异步图片加载器

**答案：**

核心点：

- 内存缓存和磁盘缓存。
- URL 去重，合并相同请求。
- cell 复用时取消旧任务。
- 限制并发数。
- 解码和缩放放后台。
- 回主 actor 更新 UI。
- 处理失败重试和占位图。

Swift Concurrency 设计可用 actor 管理缓存和进行中的任务：

```swift
actor ImagePipeline {
    private var running: [URL: Task<Image, Error>] = [:]
}
```

资深回答要覆盖取消、缓存淘汰、内存压力和指标。

### 115. 如何设计一个可取消、可重试的异步请求

**答案：**

重点：

- 使用 `async throws` 暴露接口。
- 在重试循环中检查 `Task.checkCancellation()`。
- 区分可重试错误和不可重试错误。
- 使用指数退避和最大重试次数。
- 取消时不要继续重试。

```swift
func retry<T>(
    times: Int,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    for _ in 0..<times {
        try Task.checkCancellation()
        do {
            return try await operation()
        } catch let error as CancellationError {
            throw error
        } catch {
            lastError = error
        }
    }
    throw lastError ?? CancellationError()
}
```

这里单独捕获取消错误，是为了避免用户取消后又继续重试。

### 116. 如何处理主线程卡顿中的 Swift 问题

**答案：**

排查：

- 主线程同步 IO、JSON 解析、图片解码。
- 大量 Swift 对象创建和 ARC 抖动。
- SwiftUI 或 UIKit 布局计算过重。
- 主 actor 上执行了不该执行的后台任务。
- 锁竞争导致主线程等待。

治理：

- Time Profiler 找热点。
- 把 CPU 重活移到后台任务。
- UI 更新最小化。
- 缓存计算结果。
- 控制主 actor 隔离范围，不要把整个服务层标成 `@MainActor`。

### 117. 如何在 Swift 中设计日志和埋点

**答案：**

建议：

- 日志分级：debug、info、warning、error。
- 结构化字段：模块、事件、trace id、user id 脱敏。
- 埋点和业务逻辑解耦。
- 异步写入，避免阻塞主线程。
- 统一错误上下文。

Swift 上可封装协议：

```swift
protocol Logger: Sendable {
    func log(_ level: LogLevel, _ message: String, metadata: [String: String])
}
```

资深点：日志系统也是并发共享资源，需要线程安全和性能控制。

### 118. 如何设计 Swift 团队代码规范

**答案：**

规范应覆盖：

- 命名和 API Design Guidelines。
- Optional 解包策略。
- `final` 使用建议。
- 并发边界和 `Sendable` 规则。
- 错误处理约定。
- 模块依赖方向。
- SwiftLint 或格式化工具。
- 公共 API 文档要求。

规范不能只写文档，要配合 lint、模板、code review 和示例代码落地。

### 119. 如何回答“你对 Swift 未来演进的理解”

**答案：**

可以从几个方向回答：

- 并发安全：Swift 6 强化编译期数据竞争检查。
- 所有权：非复制类型和 borrowing/consuming 增强性能与资源管理能力。
- 跨平台：Foundation Swift 实现、Linux/Windows 支持增强。
- 宏和工具链：提高表达力和测试体验。
- C++ 互操作和嵌入式：拓展 Swift 使用场景。

回答要落回项目：这些演进会影响并发迁移、SDK 设计、性能优化和团队规范。

### 120. 资深 Swift 面试最看重什么

**答案：**

通常不是背 API，而是看：

- 能否解释机制和边界。
- 能否做取舍，而不是绝对化。
- 是否有复杂项目经验。
- 是否理解并发、内存、性能和架构。
- 是否能把语言特性转化为团队可维护代码。

回答时尽量结合真实场景：某个泄漏怎么查、某个并发 bug 怎么修、某个模块怎么拆。

---

## 四、代码输出题与手写题

### 121. 下面代码输出什么

```swift
var a = [1, 2, 3]
var b = a
b.append(4)
print(a)
print(b)
```

**答案：**

输出：

```swift
[1, 2, 3]
[1, 2, 3, 4]
```

原因：`Array` 是值类型，并使用 COW。修改 `b` 时会保证 `a` 不受影响。

### 122. 下面代码输出什么

```swift
final class Box {
    var value = 1
}

let a = Box()
let b = a
b.value = 2
print(a.value)
```

**答案：**

输出 `2`。`Box` 是 class，`a` 和 `b` 指向同一个实例。

### 123. 下面代码输出什么

```swift
var value = 1
let closure = { [value] in
    print(value)
}
value = 2
closure()
```

**答案：**

输出 `1`。捕获列表在闭包创建时捕获当时的值。

### 124. 下面代码有什么问题

```swift
final class TimerOwner {
    var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.tick()
        }
    }

    func tick() {}
}
```

**答案：**

可能循环引用：`TimerOwner -> timer -> closure -> self`。

修复：

```swift
timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    self?.tick()
}
```

还应在合适时机 `invalidate()`。

### 125. 实现一个数组去重函数

**答案：**

不保序：

```swift
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        Array(Set(self))
    }
}
```

保序：

```swift
extension Array where Element: Hashable {
    func uniquedKeepingOrder() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
```

面试要问清楚是否需要保持原顺序。

### 126. 实现一个简单 LRU Cache 的思路

**答案：**

核心数据结构：

- `Dictionary<Key, Node>` 用于 O(1) 查找。
- 双向链表维护最近使用顺序。
- get 时移动节点到头部。
- set 时新增或更新，超过容量删除尾部。

Swift 实现时，链表节点通常用 class，因为需要共享节点身份和前后指针。

### 127. 用 Swift 写一个线程安全计数器

**答案 1，actor：**

```swift
actor Counter {
    private var value = 0

    func increment() {
        value += 1
    }

    func current() -> Int {
        value
    }
}
```

**答案 2，锁：**

```swift
final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        value += 1
    }

    func current() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
```

选择取决于代码是否处在 Swift Concurrency 体系内，以及是否需要同步接口。

### 128. 把回调 API 改成 async/await

**题目：**

```swift
func request(completion: @escaping (Result<Data, Error>) -> Void)
```

改造成：

```swift
func request() async throws -> Data
```

**答案：**

```swift
func request() async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        request { result in
            continuation.resume(with: result)
        }
    }
}
```

注意 continuation 必须且只能 resume 一次。

### 129. 实现一个超时包装函数

**答案：**

```swift
enum TimeoutError: Error {
    case timeout
}

func withTimeout<T: Sendable>(
    seconds: UInt64,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            throw TimeoutError.timeout
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

实际项目还要处理 `seconds` 溢出、取消传播、错误分类。

### 130. 下面代码有什么并发问题

```swift
final class Store {
    var values: [String] = []

    func append(_ value: String) {
        values.append(value)
    }
}

let store = Store()
Task { store.append("A") }
Task { store.append("B") }
```

**答案：**

多个任务并发修改同一个 class 的可变数组，有数据竞争风险。Swift 6 严格并发检查下也可能产生诊断。

修复：

- 改成 actor。
- 用锁保护。
- 避免共享可变状态。

```swift
actor Store {
    private var values: [String] = []

    func append(_ value: String) {
        values.append(value)
    }
}
```

---

## 五、高频追问速答

### Swift 中 `private` 和 `fileprivate` 区别

`private` 限制在当前声明作用域及其扩展的特定可见范围内；`fileprivate` 限制在当前文件内。大多数情况下优先 `private`，需要同文件多个类型互访时用 `fileprivate`。

### `open` 和 `public` 区别

`public` 可以跨模块访问，但外部不能继承 public class，也不能重写 public 方法。`open` 允许跨模块继承和重写。

### `Self` 和 `self` 区别

`self` 指当前实例；`Self` 指当前类型，常用于协议、返回当前具体类型、静态成员。

### `==` 和 `===` 区别

`==` 判断值相等，来自 `Equatable`；`===` 判断两个 class 引用是否指向同一个实例。

### `nil` 是对象吗

在 Swift 中 `nil` 表示 Optional 的 `.none`，不是一个对象。

### `Array` 是线程安全的吗

不是。多个线程或任务同时读写同一个数组会有数据竞争。不同变量持有各自值语义副本时通常更安全，但共享底层存储的并发修改仍要谨慎。

### Swift 中 `String` 的 `count` 一定是 O(1) 吗

不能简单认为总是 O(1)。由于 Unicode 字符边界和不同编码视图，字符串操作可能有额外成本。性能敏感场景应避免重复全量遍历。

### 为什么 Swift 不推荐滥用隐式解包 Optional

`T!` 使用方便，但失败会运行时崩溃。它适合生命周期由框架保证的场景，如 IBOutlet，普通业务模型里应优先显式 Optional。

### `Dictionary` 的 key 为什么要 `Hashable`

字典通过 key 的 hash 快速定位桶，再用相等性判断确认 key，因此 key 必须可哈希且相等性稳定。

### `Hashable` 要注意什么

如果两个值 `==`，它们的 hash 必须一致。作为字典 key 或 set 元素期间，不应修改影响 hash 的字段。

### Swift 中 delegate 为什么通常用 `weak`

delegate 往往形成双向关系，如 controller 持有 view，view 持有 delegate。如果 delegate 强引用，容易循环引用，所以通常声明为 `weak var delegate: SomeDelegate?`。协议要加 `AnyObject` 约束才能 weak。

### `unowned optional` 存在吗

存在，`unowned var owner: Owner?` 可以是 Optional，但不会自动置 nil。对象释放后访问仍可能崩溃。业务中很少需要。

### `Task.sleep` 会阻塞线程吗

不会像 `Thread.sleep` 那样阻塞当前线程，它会挂起当前任务，到时间后恢复。

### actor 能保证所有逻辑都线程安全吗

actor 能保护它隔离的可变状态，但不能自动保证业务逻辑正确。`await` 带来的 reentrancy、actor 外部共享资源、非 Sendable 对象仍需设计。

### `@MainActor` 标了整个 ViewModel 是否一定好

不一定。UI 状态适合主 actor，但网络、解析、图片处理等重活不应因为整个类型标注而跑到主 actor。可以把 UI 更新和后台工作拆开。

---

## 六、面试复习路线

### 第 1 阶段：中级基础

重点背熟：

- Optional、闭包、ARC。
- struct/class、enum、protocol。
- Codable、错误处理、访问控制。
- 常见集合和 COW。

目标：所有中级题能 30 秒说出结论，1 分钟举出例子。

### 第 2 阶段：高级机制

重点攻克：

- 方法派发。
- 协议扩展派发陷阱。
- 泛型、associatedtype、type erasure。
- Swift Concurrency、actor、Sendable。
- 性能和内存排查。

目标：能解释“为什么”，不是只会说“怎么用”。

### 第 3 阶段：资深工程能力

重点准备：

- Swift 6 迁移方案。
- 大型项目模块化。
- 公共 SDK API 设计。
- 并发架构和状态管理。
- 编译速度、性能、内存治理。

目标：能结合项目讲取舍、风险和落地过程。

---

## 七、推荐背诵模板

### 语言特性题模板

这个特性解决什么问题；它的基本用法是什么；底层或编译器层面大概怎么实现；实际项目中有什么坑；我会如何选择。

### 并发题模板

先说明状态所有权；再说明是否存在共享可变状态；然后选择 actor、锁、队列或值语义；最后补充取消、优先级、reentrancy 和 Sendable。

### 性能题模板

先说不凭感觉优化；用 Instruments 或编译诊断定位；再根据热点选择减少分配、减少动态派发、减少桥接、后台化 CPU 工作或优化数据结构；最后用数据验证。

### 架构题模板

先明确业务边界和变化方向；再拆模块和依赖方向；用协议或泛型表达稳定抽象；控制公共 API；最后说明测试、迁移和团队规范。

---

## 八、参考资料

- [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Announcing Swift 6](https://www.swift.org/blog/announcing-swift-6/)
- [Swift 6 Concurrency Migration Guide](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
- [Swift Evolution](https://github.com/swiftlang/swift-evolution)
