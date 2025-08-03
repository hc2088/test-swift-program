

以下是 Swift 并发（Swift Concurrency）系统的**完整大纲**，并包含了每个特性的 **iOS 支持最低版本**（即在哪个 iOS 系统版本中开始可用）：

* * *

## 🧵 一、基本构建块（基础并发）

| 特性                              | 简介                    | 支持版本                          |
| ------------------------------- | --------------------- | ----------------------------- |
| `async` / `await`               | 标记异步函数和等待异步结果         | ✅ iOS 13+（编译器要求 iOS 15+ 默认启用） |
| `Task`                          | 用于创建并执行结构化并发的异步任务     | ✅ iOS 15+                     |
| `Task.sleep`                    | 异步睡眠，不阻塞线程            | ✅ iOS 15+                     |
| `TaskGroup`                     | 结构化并发下的并行任务组          | ✅ iOS 15+                     |
| `async let`                     | 并发启动多个异步任务（语法糖）       | ✅ iOS 15+                     |
| `try await`                     | 异步错误处理语法              | ✅ iOS 15+                     |
| `await withCheckedContinuation` | 将传统回调封装为 `async` 异步调用 | ✅ iOS 13+（可选使用），推荐 iOS 15+    |
| `DetachedTask`                  | 启动脱离当前上下文的独立任务        | ✅ iOS 15+                     |

* * *

## 📍 二、主线程调度和隔离

| 特性                     | 简介               | 支持版本      |
| ---------------------- | ---------------- | --------- |
| `@MainActor`           | 保证函数或类属性在主线程上执行  | ✅ iOS 15+ |
| `MainActor.run`        | 在主线程中执行异步代码块     | ✅ iOS 15+ |
| `@MainActor` + `await` | 后台线程调用时会自动调度回主线程 | ✅ iOS 15+ |

* * *

## 🧩 三、Actors（并发对象模型）

| 特性                 | 简介                  | 支持版本      |
| ------------------ | ------------------- | --------- |
| `actor`            | 类似类，但保证内部状态的线程安全性   | ✅ iOS 15+ |
| `nonisolated`      | 用于标记不参与 actor 隔离的成员 | ✅ iOS 15+ |
| `@MainActor actor` | 指定该 actor 绑定主线程执行   | ✅ iOS 15+ |

* * *

## 📦 四、高级功能

| 特性                  | 简介               | 支持版本      |
| ------------------- | ---------------- | --------- |
| `Sendable`          | 类型安全特性，用于跨线程发送数据 | ✅ iOS 15+ |
| `@Sendable` closure | 明确声明闭包是线程安全的     | ✅ iOS 15+ |
| `@preconcurrency`   | 向后兼容旧的非并发 API 调用 | ✅ iOS 15+ |
| `UnstructuredTask`  | 不受父任务控制的异步任务     | ✅ iOS 15+ |

* * *

## 🧪 五、测试和调试工具

| 工具/概念                              | 简介                      |
| ---------------------------------- | ----------------------- |
| Xcode Concurrency Debugger         | 可视化查看任务执行、actor 使用等并发信息 |
| Instruments with Swift Concurrency | 分析异步任务行为与线程调度           |

* * *

## 📅 支持版本汇总（系统要求）

| 特性                      | iOS 支持版本                    |
| ----------------------- | --------------------------- |
| Swift Concurrency 最核心特性 | iOS 13+（部分依赖后备 polyfill 支持） |
| 全量支持（推荐）                | ✅ iOS 15+                   |
| Xcode 13+ + Swift 5.5+  | 并发语法正式启用                    |

> ⚠️ 注意：虽然 `async/await` 在 iOS 13+ 可运行（通过 back-deployment），但你需要使用 Xcode 13+ 并明确在构建设置中启用支持（Deployment Target ≥ iOS 13，勾选 “Enable Back Deployment of Concurrency”）。
