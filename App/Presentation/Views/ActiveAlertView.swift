import SwiftUI

struct ActiveAlertView: View {
  var alert: ActiveAlert
  @Bindable var viewModel: AlarmDashboardViewModel
  @FocusState private var answerIsFocused: Bool

  private var currentAlert: ActiveAlert {
    viewModel.activeAlert ?? alert
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.25, green: 0.09, blue: 0.07), Color(red: 0.73, green: 0.20, blue: 0.10)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 22) {
        Spacer(minLength: 0)

        Label("Stop Mission", systemImage: "bell.badge.fill")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.white.opacity(0.84))

        Text(currentAlert.title)
          .font(.system(size: 34, weight: .bold, design: .rounded))
          .foregroundStyle(.white)

        Text(currentAlert.detail)
          .font(.title3)
          .foregroundStyle(.white.opacity(0.84))

        challengeCard

        Button("Stop Alert", systemImage: "checkmark.circle.fill") {
          viewModel.finishActiveAlert()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!currentAlert.isResolved)
        .tint(.white)
        .foregroundStyle(Color(red: 0.68, green: 0.18, blue: 0.10))
        .accessibilityIdentifier(AccessibilityID.stopAlertButton)

        Spacer()
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .onAppear {
      answerIsFocused = currentAlert.challenge == .math
    }
  }

  @ViewBuilder
  private var challengeCard: some View {
    switch currentAlert.challenge {
    case .checklist:
      VStack(alignment: .leading, spacing: 14) {
        Text(currentAlert.challenge.subtitle)
          .font(.headline)

        ForEach(currentAlert.tasks) { task in
          Button {
            viewModel.toggleTask(task.id)
          } label: {
            HStack(spacing: 12) {
              Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .font(.title3)

              Text(task.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
              RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(task.isDone ? Color.accentColor.opacity(0.16) : Color.black.opacity(0.04))
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .fill(.white)
      )

    case .math:
      VStack(alignment: .leading, spacing: 14) {
        Text(currentAlert.challenge.subtitle)
          .font(.headline)

        if let prompt = currentAlert.mathPrompt {
          Text("\(prompt.left) + \(prompt.right) = ?")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .monospacedDigit()
        }

        TextField("Answer", text: Binding(
          get: { currentAlert.enteredAnswer },
          set: { viewModel.updateAnswer($0) }
        ))
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
        .focused($answerIsFocused)
      }
      .padding(20)
      .background(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .fill(.white)
      )
    }
  }
}
