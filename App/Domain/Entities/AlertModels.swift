import Foundation

enum StopChallenge: String, Codable, CaseIterable, Identifiable {
  case checklist
  case math

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .checklist:
      "Checklist Stop"
    case .math:
      "Math Stop"
    }
  }

  var subtitle: String {
    switch self {
    case .checklist:
      "Finish a few wake-up tasks before the alert stops."
    case .math:
      "Solve a quick problem before the alert stops."
    }
  }

  var symbol: String {
    switch self {
    case .checklist:
      "checklist"
    case .math:
      "sum"
    }
  }
}

struct StopTask: Identifiable, Equatable {
  var id: UUID
  var title: String
  var isDone: Bool

  init(id: UUID = UUID(), title: String, isDone: Bool = false) {
    self.id = id
    self.title = title
    self.isDone = isDone
  }
}

struct MathPrompt: Equatable {
  var left: Int
  var right: Int

  var answer: Int {
    left + right
  }
}

struct ActiveAlert: Identifiable, Equatable {
  enum Source: Equatable {
    case alarm(UUID)
    case timer

    var identity: String {
      switch self {
      case .alarm(let id):
        "alarm-\(id.uuidString)"
      case .timer:
        "timer"
      }
    }
  }

  var source: Source
  var title: String
  var detail: String
  var challenge: StopChallenge
  var tasks: [StopTask]
  var mathPrompt: MathPrompt?
  var enteredAnswer: String

  var id: String {
    source.identity
  }

  var isResolved: Bool {
    switch challenge {
    case .checklist:
      tasks.allSatisfy(\.isDone)
    case .math:
      Int(enteredAnswer) == mathPrompt?.answer
    }
  }

  mutating func toggleTask(_ id: UUID) {
    guard let index = tasks.firstIndex(where: { $0.id == id }) else {
      return
    }

    tasks[index].isDone.toggle()
  }

  mutating func updateAnswer(_ value: String) {
    enteredAnswer = value.filter(\.isNumber)
  }
}

struct CountdownTimer: Codable, Equatable {
  var durationMinutes: Int
  var challenge: StopChallenge
  var endDate: Date
}

struct TimerConfiguration: Codable, Equatable {
  var presetMinutes: Int
  var challenge: StopChallenge

  static let `default` = TimerConfiguration(presetMinutes: 15, challenge: .checklist)
}

struct AlarmSnapshot: Equatable {
  var alarms: [Alarm]
  var activeTimer: CountdownTimer?
  var timerConfiguration: TimerConfiguration
}
