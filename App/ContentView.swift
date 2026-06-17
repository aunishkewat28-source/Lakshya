import SwiftUI

struct ContentView: View {
  @State private var store = AlarmStore()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          heroCard
          TimerPanelView(store: store)
          AlarmComposerView(store: store)
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
      ActiveAlertView(alert: alert, store: store)
        .interactiveDismissDisabled()
    }
    .sensoryFeedback(.warning, trigger: store.alertTriggerCount)
    .sensoryFeedback(.success, trigger: store.completedAlertCount)
  }

  private var heroCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Wake up with a mission")
        .font(.title.bold())
        .foregroundStyle(.white)

      Text("Timers and alarms stop only after a short checklist or math prompt, so you don’t swipe them away half-awake.")
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.82))

      HStack(spacing: 12) {
        Label(store.now.formatted(date: .omitted, time: .shortened), systemImage: "clock")
        Label("\(store.alarms.filter(\.isEnabled).count) active alarms", systemImage: "alarm")
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

      if store.alarms.isEmpty {
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
          ForEach(Array(store.alarms.enumerated()), id: \.element.id) { offset, alarm in
            AlarmRowView(alarm: alarm, store: store) {
              store.deleteAlarms(at: IndexSet(integer: offset))
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var activeAlertBinding: Binding<ActiveAlert?> {
    Binding(
      get: { store.activeAlert },
      set: { newValue in
        store.activeAlert = newValue
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
