import SwiftUI

struct AlarmRowView: View {
  var alarm: Alarm
  @Bindable var viewModel: AlarmDashboardViewModel
  var onDelete: () -> Void

  var body: some View {
    HStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 6) {
        Text(viewModel.formattedTime(for: alarm))
          .font(.title2.monospacedDigit().weight(.bold))

        Text(alarm.title)
          .font(.headline)

        Label(alarm.challenge.title, systemImage: alarm.challenge.symbol)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Toggle(
        alarm.isEnabled ? "On" : "Off",
        isOn: Binding(
          get: { alarm.isEnabled },
          set: { viewModel.setAlarmEnabled(alarm.id, isEnabled: $0) }
        )
      )
      .labelsHidden()
      .tint(Color.accentColor)

      Button("Delete", systemImage: "trash") {
        onDelete()
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.plain)
      .foregroundStyle(.secondary)
    }
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(.white.opacity(0.78))
    )
  }
}
