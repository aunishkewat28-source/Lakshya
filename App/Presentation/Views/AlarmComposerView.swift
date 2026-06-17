import SwiftUI

struct AlarmComposerView: View {
  @Bindable var viewModel: AlarmDashboardViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("New Alarm")
        .font(.title3.weight(.semibold))

      TextField("Alarm name", text: $viewModel.draftAlarmTitle)
        .textInputAutocapitalization(.words)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.white.opacity(0.9))
        )
        .accessibilityIdentifier(AccessibilityID.addAlarmNameField)

      DatePicker("Time", selection: $viewModel.draftAlarmTime, displayedComponents: .hourAndMinute)
        .datePickerStyle(.compact)

      Picker("Stop Mode", selection: Binding(
        get: { viewModel.draftAlarmChallenge },
        set: { viewModel.updateDraftChallenge($0) }
      )) {
        ForEach(StopChallenge.allCases) { challenge in
          Text(challenge.title).tag(challenge)
        }
      }
      .pickerStyle(.menu)
      .buttonStyle(.bordered)

      Button("Add Alarm", systemImage: "plus") {
        viewModel.addAlarm()
      }
      .buttonStyle(.borderedProminent)
      .tint(Color.accentColor)
      .accessibilityIdentifier(AccessibilityID.addAlarmButton)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(.white.opacity(0.78))
    )
  }
}
