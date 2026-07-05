import Foundation
import Observation

enum TravelUnit: String, CaseIterable, Identifiable, Sendable {
    case seconds = "秒"
    case minutes = "分"
    case hours = "小时"
    case days = "天"
    case years = "年"

    var id: String { rawValue }

    var secondsMultiplier: Double {
        switch self {
        case .seconds:
            return 1
        case .minutes:
            return 60
        case .hours:
            return 60 * 60
        case .days:
            return 24 * 60 * 60
        case .years:
            return 365 * 24 * 60 * 60
        }
    }
}

struct TimeTravelSnapshot: Sendable {
    let remainingSeconds: Double
    let progress: Double

    var isFinished: Bool {
        remainingSeconds <= 0
    }
}

actor TimeTravelCountdownEngine {
    func snapshots(totalSeconds: Double, startedAt: Date) -> AsyncStream<TimeTravelSnapshot> {
        AsyncStream { continuation in
            let task = Task {
                let arrivalDate = startedAt.addingTimeInterval(totalSeconds)

                while !Task.isCancelled {
                    let now = Date()
                    let remaining = max(0, arrivalDate.timeIntervalSince(now))
                    let elapsed = min(totalSeconds, max(0, now.timeIntervalSince(startedAt)))
                    let progress = totalSeconds > 0 ? min(1, max(0, elapsed / totalSeconds)) : 1

                    continuation.yield(TimeTravelSnapshot(remainingSeconds: remaining, progress: progress))

                    guard remaining > 0 else {
                        break
                    }

                    let nextTick = min(1, remaining)
                    let nanoseconds = UInt64(nextTick * 1_000_000_000)
                    do {
                        try await Task.sleep(nanoseconds: nanoseconds)
                    } catch {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

@MainActor
@Observable
final class TimeTravelViewModel {
    var durationText = "10"
    var selectedUnit: TravelUnit = .seconds
    var isTraveling = false
    var progress = 0.0
    var remainingSeconds = 0.0
    var travelStartedAt: Date?
    var travelTotalSeconds = 0.0
    var showCompletionAlert = false
    var completionMessage = ""
    var inputError: String?

    @ObservationIgnored private let engine = TimeTravelCountdownEngine()
    @ObservationIgnored private var travelTask: Task<Void, Never>?

    var canStart: Bool {
        parsedDurationSeconds != nil && !isTraveling
    }

    var countdownText: String {
        countdownText(at: Date())
    }

    var statusText: String {
        statusText(at: Date())
    }

    var destinationLabel: String {
        guard let amount = parsedAmount else {
            return durationText.trimmingCharacters(in: .whitespacesAndNewlines) + selectedUnit.rawValue
        }

        return "\(formattedAmount(amount))\(selectedUnit.rawValue)"
    }

    func startTravel() {
        guard !isTraveling else {
            return
        }

        guard let totalSeconds = parsedDurationSeconds else {
            inputError = "请输入大于 0 的穿越时长"
            return
        }

        let destination = destinationLabel
        let startedAt = Date()
        inputError = nil
        showCompletionAlert = false
        completionMessage = ""
        isTraveling = true
        progress = 0
        remainingSeconds = totalSeconds
        travelStartedAt = startedAt
        travelTotalSeconds = totalSeconds

        travelTask?.cancel()
        travelTask = Task { [engine] in
            let stream = await engine.snapshots(totalSeconds: totalSeconds, startedAt: startedAt)
            for await snapshot in stream {
                remainingSeconds = snapshot.remainingSeconds
                progress = snapshot.progress

                if snapshot.isFinished {
                    break
                }
            }

            guard !Task.isCancelled else {
                return
            }

            remainingSeconds = 0
            progress = 1
            isTraveling = false
            travelStartedAt = nil
            travelTotalSeconds = 0
            completionMessage = "恭喜！您已成功穿越到\(destination)后！"
            showCompletionAlert = true
        }
    }

    func progress(at date: Date) -> Double {
        guard isTraveling, let travelStartedAt, travelTotalSeconds > 0 else {
            return progress
        }

        let elapsed = max(0, date.timeIntervalSince(travelStartedAt))
        return min(1, elapsed / travelTotalSeconds)
    }

    func remainingSeconds(at date: Date) -> Double {
        guard isTraveling, let travelStartedAt, travelTotalSeconds > 0 else {
            return remainingSeconds
        }

        let arrivalDate = travelStartedAt.addingTimeInterval(travelTotalSeconds)
        return max(0, arrivalDate.timeIntervalSince(date))
    }

    func countdownText(at date: Date) -> String {
        guard isTraveling else {
            return "等待时空坐标校准"
        }

        return "\(Int(ceil(remainingSeconds(at: date)))) 秒"
    }

    func statusText(at date: Date) -> String {
        guard isTraveling else {
            return "输入穿越时长，选择单位后即可启动"
        }

        return "正在穿越中，预计还需要\(Int(ceil(remainingSeconds(at: date))))秒"
    }

    private var parsedDurationSeconds: Double? {
        guard let amount = parsedAmount else {
            return nil
        }

        let seconds = amount * selectedUnit.secondsMultiplier
        return seconds.isFinite && seconds > 0 ? seconds : nil
    }

    private var parsedAmount: Double? {
        let normalized = durationText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "，", with: ".")
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Double(normalized), amount > 0 else {
            return nil
        }

        return amount
    }

    private func formattedAmount(_ amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }

        return String(format: "%.2f", amount)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
