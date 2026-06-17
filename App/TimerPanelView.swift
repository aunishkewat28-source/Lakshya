import SwiftUI

struct TimerPanelView: View {
  @Bindable var store: AlarmStore

  private let presets = [5, 15, 25, 45]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Focus Timer")
          .font(.title3.weight(.semibold))

        Spacer()

        if store.hasActiveTimer {
          Text(store.formattedRemainingTime())
            .font(.footnote.monospacedDigit().weight(.semibold))
            .foregroundStyle(.secondary)
        }
      }

      HStack(spacing: 10) {
        ForEach(presets, id: \.self) { preset in
          Button {
            store.updateTimerPreset(preset)
          } label: {
            Text("\(preset)m")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(store.timerPresetMinutes == preset ? Color.white : Color.primary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .fill(store.timerPresetMinutes == preset ? Color.accentColor : Color.white.opacity(0.72))
              )
          }
          .buttonStyle(.plain)
        }
      }

      Picker("Stop Mode", selection: Binding(
        get: { store.timerChallenge },
        set: { store.updateTimerChallenge($0) }
      )) {
        ForEach(StopChallenge.allCases) { challenge in
          Text(challenge.title).tag(challenge)
        }
      }
      .pickerStyle(.menu)
      .buttonStyle(.bordered)

      HStack(spacing: 12) {
        Button(store.hasActiveTimer ? "Restart Timer" : "Start Timer", systemImage: "play.fill") {
          store.startTimer()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accentColor)

        if store.hasActiveTimer {
          Button("Cancel", systemImage: "xmark") {
            store.cancelTimer()
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
  }
}
