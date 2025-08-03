Swift 并发（**Swift Concurrency**）是 Swift 5.5 引入的一整套原生异步编程模型，目的是让异步编程更**安全、清晰、可组合、可维护**。它的核心构成包括：

* * *

## ✅ Swift 并发大纲一览

### 1. **异步函数（`async` / `await`）**

-   `async`：声明一个异步函数（表示它可能挂起）
-   `await`：在调用异步函数时使用，表示等待结果

```
func fetchData() async -> String { ... }
let result = await fetchData()
```

* * *

### 2. **任务（`Task`）与任务组**

#### 2.1 `Task`：创建并发任务（子任务、后台任务等）

```
Task {
    let result = await fetchData()
}
```

#### 2.2 `TaskGroup`：并发地启动多个任务，并聚合结果

```
await withTaskGroup(of: String.self) { group in
    group.addTask { await fetchData1() }
    group.addTask { await fetchData2() }
    for await result in group {
        print(result)
    }
}
```

* * *

### 3. **结构化并发（Structured Concurrency）**

-   自动追踪任务生命周期（子任务随父任务销毁）
-   由 `async let`、`TaskGroup` 实现

```
async let a = fetchData1()
async let b = fetchData2()
let results = await (a, b)
```

* * *

### 4. **并发安全（Data Isolation）**

Swift 提供机制防止数据竞争。

#### 4.1 **`actor`：主力数据隔离工具**

```
actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func getValue() -> Int { value }
}
```

#### 4.2 MainActor：确保 UI 代码在主线程执行

```
@MainActor
class ViewModel {
    func updateUI() { ... }  // 自动切换回主线程
}
```

* * *

### 5. **取消（Task Cancellation）**

任务可被取消，任务内部需检查 `Task.isCancelled`。

```
Task {
    if Task.isCancelled { return }
}
```

* * *

### 6. **异步序列（`AsyncSequence` / `AsyncStream`）**

用于异步数据流（类似 Combine、RxSwift）

```
for await item in myAsyncStream {
    print(item)
}
```

* * *

### 7. **DetachedTask**（非结构化任务）

脱离结构化上下文执行的任务。

```
let task = Task.detached {
    await doSomething()
}
```

* * *

### 8. **Continuation（`CheckedContinuation` / `UnsafeContinuation`）**

桥接传统回调风格（Completion handler）与 `async/await`。

```
func legacyFunctionAsync() async -> String {
    await withCheckedContinuation { continuation in
        legacyFunction { result in
            continuation.resume(returning: result)
        }
    }
}
```

* * *

### 9. **并发属性（`@Sendable`, `@MainActor`, `@globalActor`）**

-   `@Sendable`: 标记闭包可以安全跨线程执行
-   `@MainActor`: 标记类/函数必须在主线程
-   `@globalActor`: 自定义全局 Actor

* * *

## 🧠 总结关键点

| 特性              | 功能          |
| --------------- | ----------- |
| `async/await`   | 异步函数调用      |
| `Task`          | 创建新的异步任务    |
| `TaskGroup`     | 并发任务组       |
| `actor`         | 数据隔离，线程安全   |
| `MainActor`     | UI 操作的主线程保护 |
| `AsyncSequence` | 异步数据流       |
| `Continuation`  | 兼容旧式回调      |
| `@Sendable`     | 闭包线程安全标记    |


