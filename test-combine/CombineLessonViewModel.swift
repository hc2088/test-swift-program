//
//  CombineLessonViewModel.swift
//  test-combine
//
//  Created by Codex on 2026/5/13.
//

import Foundation
import Combine

final class CombineLessonViewModel {

    let usernameInput = CurrentValueSubject<String, Never>("")
    let agreementInput = CurrentValueSubject<Bool, Never>(false)
    let searchTapped = PassthroughSubject<Void, Never>()

    @Published private(set) var characterCountText = "字符数：0"
    @Published private(set) var validationText = "校验结果：至少输入 2 个非空字符"
    @Published private(set) var stableInputText = "稳定输入：停止输入 0.35 秒后这里才会更新"
    @Published private(set) var tapCountText = "按钮点击次数（scan）：0"
    @Published private(set) var isSearchButtonEnabled = false
    @Published private(set) var resultText = "结果会显示在这里。\n试试输入 combine、swift，或者输入 error 看失败分支。"
    @Published private(set) var eventLogText = "日志会显示在这里。"

    private var cancellables = Set<AnyCancellable>()
    private var logLines: [String] = []

    init() {
        setupBindings()
    }

    private func setupBindings() {
        usernameInput
            .map { "字符数：\($0.count)" }
            .assign(to: &$characterCountText)

        let stableInputPublisher = usernameInput
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)

        stableInputPublisher
            .map { text in
                text.isEmpty ? "稳定输入：当前还是空字符串" : "稳定输入：\(text)"
            }
            .assign(to: &$stableInputText)

        stableInputPublisher
            .map { text in
                text.count >= 2
                    ? "校验结果：输入合法，可以开始搜索"
                    : "校验结果：至少输入 2 个非空字符"
            }
            .assign(to: &$validationText)

        stableInputPublisher
            .sink { [weak self] text in
                self?.appendLog("debounce 后拿到稳定输入 -> \(text.isEmpty ? "空" : text)")
            }
            .store(in: &cancellables)

        agreementInput
            .removeDuplicates()
            .sink { [weak self] isOn in
                self?.appendLog("开关状态变化 -> \(isOn ? "已勾选" : "未勾选")")
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(
            stableInputPublisher.map { $0.count >= 2 },
            agreementInput.removeDuplicates()
        )
        .map { isInputValid, didAgree in
            isInputValid && didAgree
        }
        .sink { [weak self] isEnabled in
            self?.isSearchButtonEnabled = isEnabled
        }
        .store(in: &cancellables)

        searchTapped
            .scan(0) { count, _ in
                count + 1
            }
            .map { "按钮点击次数（scan）：\($0)" }
            .assign(to: &$tapCountText)

        searchTapped
            .map { [usernameInput, agreementInput] in
                (
                    query: usernameInput.value.trimmingCharacters(in: .whitespacesAndNewlines),
                    didAgree: agreementInput.value
                )
            }
            .handleEvents(receiveOutput: { [weak self] request in
                self?.appendLog("收到按钮点击 -> query=\(request.query), agree=\(request.didAgree)")
            })
            .filter { [weak self] request in
                let isValid = request.didAgree && request.query.count >= 2
                if !isValid {
                    self?.appendLog("filter 丢弃了这次点击，因为输入或开关状态不满足要求")
                }
                return isValid
            }
            .map(\.query)
            .flatMap { [weak self] query in
                self?.resultText = "正在搜索：\(query)\n这里是 flatMap 展开的异步任务。"
                self?.appendLog("flatMap 开始异步请求 -> \(query)")

                return Self.mockSearch(query: query)
                    .catch { [weak self] error -> Just<[String]> in
                        self?.appendLog("请求失败 -> \(error.localizedDescription)")
                        return Just(["搜索失败：\(error.localizedDescription)"])
                    }
                    .eraseToAnyPublisher()
            }
            .map { items in
                items.enumerated()
                    .map { index, item in "\(index + 1). \(item)" }
                    .joined(separator: "\n")
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.resultText = text
            }
            .store(in: &cancellables)
    }

    private func appendLog(_ message: String) {
        let update = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"

            let line = "[\(formatter.string(from: Date()))] \(message)"
            self.logLines.append(line)
            self.logLines = Array(self.logLines.suffix(10))
            self.eventLogText = self.logLines.joined(separator: "\n")
        }

        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async(execute: update)
        }
    }

    private static func mockSearch(query: String) -> AnyPublisher<[String], Error> {
        Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                if query.lowercased() == "error" {
                    promise(.failure(MockSearchError.demoFailure))
                    return
                }

                promise(.success([
                    "\(query) - Publisher 是数据源",
                    "\(query) - Subscriber 是接收者",
                    "\(query) - operator 负责中间加工",
                    "\(query) - AnyCancellable 负责持有订阅"
                ]))
            }
        }
        .eraseToAnyPublisher()
    }
}

private enum MockSearchError: LocalizedError {
    case demoFailure

    var errorDescription: String? {
        "这是故意制造的错误，用来观察 catch 如何兜底。"
    }
}
