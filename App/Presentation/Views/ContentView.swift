import SwiftUI

struct ContentView: View {
  @State private var viewModel = AlarmDashboardViewModel()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          heroCard
          TimerPanelView(viewModel: viewModel)
          AlarmComposerView(viewModel: viewModel)
          alarmsSection
        }
        .padding(20)
        .frame(maxWidth: .infinity)
      }
      .scrollIndicators(.hidden)
      .background(backgroundGradient)
      .navigationTitle("Lakshya")
    }
    .fullScreenCover(item: activeAlertBinding) { alert in
      ActiveAlertView(alert: alert, viewModel: viewModel)
        .interactiveDismissDisabled()
    }
    .sensoryFeedback(.warning, trigger: viewModel.alertTriggerCount)
    .sensoryFeedback(.success, trigger: viewModel.completedAlertCount)
  }

  private var heroCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Wake up with a mission")
        .font(.title.bold())
        .foregroundStyle(.white)
        .accessibilityIdentifier(AccessibilityID.heroTitle)

      Text("Timers and alarms stop only after a short checklist or math prompt, so you don’t swipe them away half-awake.")
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.82))

      HStack(spacing: 12) {
        Label(viewModel.now.formatted(date: .omitted, time: .shortened), systemImage: "clock")
        Label("\(viewModel.enabledAlarmCount) active alarms", systemImage: "alarm")
      }
      .font(.footnote.weight(.semibold))
      .foregroundStyle(.white.opacity(0.88))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(22)
    .background(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(red: 0.96, green: 0.43, blue: 0.19), Color(red: 0.72, green: 0.16, blue: 0.11)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
    )
  }

  private var alarmsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Alarm Board")
        .font(.title3.weight(.semibold))
        .accessibilityIdentifier(AccessibilityID.alarmBoard)

      if viewModel.alarms.isEmpty {
        Text("Add your first alarm to start building a stop ritual.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(18)
          .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .fill(.white.opacity(0.72))
          )
      } else {
        VStack(spacing: 12) {
          ForEach(viewModel.alarms) { alarm in
            AlarmRowView(alarm: alarm, viewModel: viewModel) {
              viewModel.deleteAlarm(alarm.id)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var activeAlertBinding: Binding<ActiveAlert?> {
    Binding(
      get: { viewModel.activeAlert },
      set: { newValue in
        viewModel.activeAlert = newValue
      }
    )
  }

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [
        Color(red: 0.98, green: 0.95, blue: 0.90),
        Color(red: 0.97, green: 0.92, blue: 0.88),
        Color(red: 0.92, green: 0.90, blue: 0.95)
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}
