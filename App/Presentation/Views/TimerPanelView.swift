import SwiftUI

struct TimerPanelView: View {
  @Bindable var viewModel: AlarmDashboardViewModel

  private let presets = [5, 15, 25, 45]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Focus Timer")
          .font(.title3.weight(.semibold))

        Spacer()

        if viewModel.hasActiveTimer {
          Text(viewModel.formattedRemainingTime())
            .font(.footnote.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }

      HStack(spacing: 10) {
        ForEach(presets, id: \.self) { preset in
          Button {
            viewModel.updateTimerPreset(preset)
          } label: {
            Text("\(preset)m")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(viewModel.timerConfiguration.presetMinutes == preset ? Color.white : Color.primary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .fill(viewModel.timerConfiguration.presetMinutes == preset ? Color.accentColor : Color.white.opacity(0.72))
              )
          }
          .buttonStyle(.plain)
        }
      }

      Picker("Stop Mode", selection: Binding(
        get: { viewModel.timerConfiguration.challenge },
        set: { viewModel.updateTimerChallenge($0) }
      )) {
        ForEach(StopChallenge.allCases) { challenge in
          Text(challenge.title).tag(challenge)
        }
      }
      .pickerStyle(.menu)
      .buttonStyle(.bordered)

      HStack(spacing: 12) {
        Button(viewModel.hasActiveTimer ? "Restart Timer" : "Start Timer", systemImage: "play.fill") {
          viewModel.startTimer()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)
        .accessibilityIdentifier(AccessibilityID.timerStartButton)

        if viewModel.hasActiveTimer {
          Button("Cancel", systemImage: "xmark") {
            viewModel.cancelTimer()
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.white.opacity(0.78))
    )
    .accessibilityIdentifier(AccessibilityID.focusTimerCard)
  }
}
