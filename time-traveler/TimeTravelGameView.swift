import Observation
import SwiftUI

struct TimeTravelGameView: View {
    @State private var model = TimeTravelViewModel()

    var body: some View {
        @Bindable var model = model

        ZStack {
            TimeTunnelBackground()

            ScrollView {
                VStack(spacing: 16) {
                    header
                    DurationInputPanel(model: model)
                    TravelStatusPanel(model: model)
                    StartTravelButton(isEnabled: model.canStart, isTraveling: model.isTraveling) {
                        model.startTravel()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .alert("穿越完成", isPresented: $model.showCompletionAlert) {
            Button("收到", role: .cancel) { }
        } message: {
            Text(model.completionMessage)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 30, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.cyan)

                Text("时空穿越器")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text("Time-space transit console")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.top, 10)
    }
}

private struct DurationInputPanel: View {
    @Bindable var model: TimeTravelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("穿越时长", systemImage: "timer")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField("0", text: $model.durationText)
                    .keyboardType(.decimalPad)
                    .textInputAutocapitalization(.never)
                    .disabled(model.isTraveling)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(model.isTraveling ? 0.07 : 0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )

                Text(model.selectedUnit.rawValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.mint)
                    .frame(minWidth: 48, alignment: .leading)
            }

            UnitSelector(model: model)

            if let error = model.inputError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(18)
        .glassPanel()
    }
}

private struct UnitSelector: View {
    @Bindable var model: TimeTravelViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 78), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(TravelUnit.allCases) { unit in
                Button {
                    model.selectedUnit = unit
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: model.selectedUnit == unit ? "record.circle.fill" : "circle")
                            .font(.system(size: 15, weight: .semibold))
                        Text(unit.rawValue)
                            .font(.system(.callout, design: .rounded, weight: .bold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .foregroundStyle(model.selectedUnit == unit ? .black : .white.opacity(0.82))
                    .background(unitBackground(for: unit), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(model.selectedUnit == unit ? 0 : 0.14), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(model.isTraveling)
            }
        }
    }

    private func unitBackground(for unit: TravelUnit) -> LinearGradient {
        if model.selectedUnit == unit {
            return LinearGradient(
                colors: [Color.mint, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.08), Color.white.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct TravelStatusPanel: View {
    let model: TimeTravelViewModel

    var body: some View {
        TimelineView(.periodic(from: model.travelStartedAt ?? Date(), by: 1.0 / 60.0)) { timeline in
            let progress = model.progress(at: timeline.date)

            VStack(spacing: 16) {
                HStack {
                    Label("倒计时", systemImage: "hourglass")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.cyan)
                }

                Text(model.countdownText(at: timeline.date))
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                WarpProgressBar(progress: progress)

                Text(model.statusText(at: timeline.date))
                    .font(.system(.callout, design: .rounded, weight: .semibold))
                    .foregroundStyle(model.isTraveling ? .mint : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .glassPanel()
    }
}

private struct StartTravelButton: View {
    let isEnabled: Bool
    let isTraveling: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "arrowtriangle.forward.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("开始穿越")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .foregroundStyle(isEnabled ? .black : .white.opacity(0.65))
            .background(buttonBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(isEnabled ? 0 : 0.12), lineWidth: 1)
            )
            .shadow(color: isEnabled ? .cyan.opacity(0.34) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isTraveling)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isTraveling)
    }

    private var buttonBackground: LinearGradient {
        if isEnabled {
            return LinearGradient(
                colors: [Color(red: 0.95, green: 0.82, blue: 0.36), Color.mint, Color.cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [Color.gray.opacity(0.48), Color.gray.opacity(0.28)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct WarpProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.mint, Color.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(10, proxy.size.width * progress))
                    .shadow(color: .cyan.opacity(0.42), radius: 10, y: 2)

                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .offset(x: max(1, proxy.size.width * progress - 8))
                    .shadow(color: .yellow.opacity(0.8), radius: 8)
            }
        }
        .frame(height: 14)
    }
}

private struct TimeTunnelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.08),
                    Color(red: 0.02, green: 0.15, blue: 0.14),
                    Color(red: 0.19, green: 0.09, blue: 0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                TimelineView(.animation) { timeline in
                    let drift = timeline.date.timeIntervalSinceReferenceDate
                    let size = proxy.size

                    ZStack {
                        ForEach(0..<56, id: \.self) { index in
                            Circle()
                                .fill(.white.opacity(starOpacity(index: index, drift: drift)))
                                .frame(width: starSize(index), height: starSize(index))
                                .position(starPosition(index, drift: drift, in: size))
                        }

                        ForEach(0..<12, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(streakColor(index))
                                .frame(width: streakWidth(index, in: size), height: 1.2)
                                .rotationEffect(.degrees(streakAngle(index)))
                                .position(streakPosition(index, drift: drift, in: size))
                                .opacity(0.36)
                        }
                    }
                }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func starSize(_ index: Int) -> CGFloat {
        CGFloat(1 + (index % 3))
    }

    private func starOpacity(index: Int, drift: TimeInterval) -> Double {
        0.25 + 0.45 * abs(sin(Double(index) * 0.83 + drift * 0.75))
    }

    private func starPosition(_ index: Int, drift: TimeInterval, in size: CGSize) -> CGPoint {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let xSeed = abs(sin(Double(index) * 12.9898)) * width
        let ySeed = abs(cos(Double(index) * 78.233)) * height
        let y = (ySeed + drift * Double(8 + index % 5)).truncatingRemainder(dividingBy: height + 40)
        return CGPoint(x: xSeed, y: y)
    }

    private func streakColor(_ index: Int) -> Color {
        index.isMultiple(of: 2) ? .cyan : .yellow
    }

    private func streakWidth(_ index: Int, in size: CGSize) -> CGFloat {
        min(size.width * 0.32, CGFloat(44 + index * 9))
    }

    private func streakAngle(_ index: Int) -> Double {
        -18 + Double(index % 5) * 9
    }

    private func streakPosition(_ index: Int, drift: TimeInterval, in size: CGSize) -> CGPoint {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let x = (Double(index * 47) + drift * Double(18 + index)).truncatingRemainder(dividingBy: width + 80)
        let y = 60 + abs(sin(Double(index) * 2.1)) * max(height - 120, 1)
        return CGPoint(x: x, y: y)
    }
}

private extension View {
    func glassPanel() -> some View {
        background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
    }
}
