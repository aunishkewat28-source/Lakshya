import Foundation
import Observation

@MainActor
@Observable
final class AlarmDashboardViewModel {
  private let repository: AlarmRepository
  private let dateProvider: DateProviding
  private let mathPromptGenerator: MathPromptGenerating
  private let calendar: Calendar
  private var timerDriver: TimerDriver?
  private var lastTriggeredMinuteByAlarmID: [UUID: String] = [:]

  var alarms: [Alarm]
  var now: Date
  var timerConfiguration: TimerConfiguration
  var activeTimer: CountdownTimer?
  var activeAlert: ActiveAlert?
  var draftAlarmTitle = ""
  var draftAlarmTime: Date
  var draftAlarmChallenge: StopChallenge = .checklist
  var alertTriggerCount = 0
  var completedAlertCount = 0

  init(
    repository: AlarmRepository = UserDefaultsAlarmRepository(),
    dateProvider: DateProviding = SystemDateProvider(),
    mathPromptGenerator: MathPromptGenerating = RandomMathPromptGenerator(),
    calendar: Calendar = .autoupdatingCurrent,
    startsTimerDriver: Bool = true
  ) {
    self.repository = repository
    self.dateProvider = dateProvider
    self.mathPromptGenerator = mathPromptGenerator
    self.calendar = calendar

    let snapshot = repository.loadSnapshot()
    let seededAlarms = snapshot.alarms.isEmpty ? Self.defaultAlarms() : snapshot.alarms
    alarms = seededAlarms.sorted(by: Self.sortPredicate(_:_:))
    now = dateProvider.now
    timerConfiguration = snapshot.timerConfiguration
    activeTimer = snapshot.activeTimer
    draftAlarmTime = Self.defaultDraftAlarmTime(calendar: calendar)

    if snapshot.alarms.isEmpty {
      repository.saveAlarms(alarms)
    }

    if startsTimerDriver {
      timerDriver = TimerDriver { [weak self] in
        self?.refresh()
      }
    }

    refresh(now: now)
  }

  var enabledAlarmCount: Int {
    alarms.filter(\.isEnabled).count
  }

  var hasActiveTimer: Bool {
    activeTimer != nil
  }

  var timerRemaining: TimeInterval? {
    guard let activeTimer else {
      return nil
    }

    return max(0, activeTimer.endDate.timeIntervalSince(now))
  }

  func refresh(now newNow: Date? = nil) {
    now = newNow ?? dateProvider.now
    triggerTimerIfNeeded()
    triggerAlarmIfNeeded()
  }

  func startTimer() {
    let minutes = max(1, timerConfiguration.presetMinutes)
    activeTimer = CountdownTimer(
      durationMinutes: minutes,
      challenge: timerConfiguration.challenge,
      endDate: now.addingTimeInterval(Double(minutes) * 60)
    )
    repository.saveActiveTimer(activeTimer)
  }

  func cancelTimer() {
    activeTimer = nil
    repository.saveActiveTimer(nil)
  }

  func addAlarm() {
    let components = calendar.dateComponents([.hour, .minute], from: draftAlarmTime)
    let trimmedTitle = draftAlarmTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = trimmedTitle.isEmpty ? "Focus Alarm" : trimmedTitle
    let alarm = Alarm(
      title: title,
      hour: components.hour ?? 7,
      minute: components.minute ?? 0,
      challenge: draftAlarmChallenge
    )

    alarms.append(alarm)
    alarms.sort(by: Self.sortPredicate(_:_:))
    repository.saveAlarms(alarms)
    draftAlarmTitle = ""
    draftAlarmTime = nextSuggestedAlarmTime(from: draftAlarmTime)
    draftAlarmChallenge = .checklist
  }

  func deleteAlarm(_ id: UUID) {
    alarms.removeAll(where: { $0.id == id })
    repository.saveAlarms(alarms)
  }

  func setAlarmEnabled(_ id: UUID, isEnabled: Bool) {
    guard let index = alarms.firstIndex(where: { $0.id == id }) else {
      return
    }

    alarms[index].isEnabled = isEnabled
    repository.saveAlarms(alarms)
  }

  func updateTimerPreset(_ minutes: Int) {
    timerConfiguration.presetMinutes = minutes
    repository.saveTimerConfiguration(timerConfiguration)
  }

  func updateTimerChallenge(_ challenge: StopChallenge) {
    timerConfiguration.challenge = challenge
    repository.saveTimerConfiguration(timerConfiguration)
  }

  func updateDraftChallenge(_ challenge: StopChallenge) {
    draftAlarmChallenge = challenge
  }

  func toggleTask(_ id: UUID) {
    guard var activeAlert else {
      return
    }

    activeAlert.toggleTask(id)
    self.activeAlert = activeAlert
  }

  func updateAnswer(_ value: String) {
    guard var activeAlert else {
      return
    }

    activeAlert.updateAnswer(value)
    self.activeAlert = activeAlert
  }

  func finishActiveAlert() {
    guard let activeAlert, activeAlert.isResolved else {
      return
    }

    completedAlertCount += 1
    self.activeAlert = nil
  }

  func formattedTime(for alarm: Alarm) -> String {
    var components = DateComponents()
    components.hour = alarm.hour
    components.minute = alarm.minute
    let date = calendar.date(from: components) ?? now
    return date.formatted(date: .omitted, time: .shortened)
  }

  func formattedRemainingTime() -> String {
    guard let timerRemaining else {
      return "No timer running"
    }

    let totalSeconds = Int(timerRemaining.rounded(.up))
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d left", minutes, seconds)
  }

  private func triggerTimerIfNeeded() {
    guard let activeTimer else {
      return
    }

    guard now >= activeTimer.endDate else {
      return
    }

    self.activeTimer = nil
    repository.saveActiveTimer(nil)

    guard activeAlert == nil else {
      return
    }

    activeAlert = makeAlert(
      title: "Timer Complete",
      detail: "\(activeTimer.durationMinutes)-minute focus block is over.",
      challenge: activeTimer.challenge,
      source: .timer
    )
    alertTriggerCount += 1
  }

  private func triggerAlarmIfNeeded() {
    guard activeAlert == nil else {
      return
    }

    let hour = calendar.component(.hour, from: now)
    let minute = calendar.component(.minute, from: now)
    let stamp = minuteStamp(for: now)

    for alarm in alarms where alarm.isEnabled {
      guard alarm.hour == hour, alarm.minute == minute else {
        continue
      }

      guard lastTriggeredMinuteByAlarmID[alarm.id] != stamp else {
        continue
      }

      lastTriggeredMinuteByAlarmID[alarm.id] = stamp
      activeAlert = makeAlert(
        title: alarm.title,
        detail: "Scheduled for \(formattedTime(for: alarm))",
        challenge: alarm.challenge,
        source: .alarm(alarm.id)
      )
      alertTriggerCount += 1
      break
    }
  }

  private func makeAlert(
    title: String,
    detail: String,
    challenge: StopChallenge,
    source: ActiveAlert.Source
  ) -> ActiveAlert {
    switch challenge {
    case .checklist:
      ActiveAlert(
        source: source,
        title: title,
        detail: detail,
        challenge: challenge,
        tasks: Self.checklistTasks(),
        mathPrompt: nil,
        enteredAnswer: ""
      )
    case .math:
      ActiveAlert(
        source: source,
        title: title,
        detail: detail,
        challenge: challenge,
        tasks: [],
        mathPrompt: mathPromptGenerator.makePrompt(),
        enteredAnswer: ""
      )
    }
  }

  private func minuteStamp(for date: Date) -> String {
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let year = components.year ?? 0
    let month = components.month ?? 0
    let day = components.day ?? 0
    let hour = components.hour ?? 0
    let minute = components.minute ?? 0
    return "\(year)-\(month)-\(day)-\(hour)-\(minute)"
  }

  private func nextSuggestedAlarmTime(from date: Date) -> Date {
    calendar.date(byAdding: .hour, value: 1, to: date) ?? date
  }

  private static func defaultDraftAlarmTime(calendar: Calendar) -> Date {
    let rounded = calendar.date(bySetting: .minute, value: 0, of: .now) ?? .now
    return calendar.date(byAdding: .hour, value: 1, to: rounded) ?? .now
  }

  private static func defaultAlarms() -> [Alarm] {
    [
      Alarm(title: "Morning Reset", hour: 7, minute: 0, challenge: .checklist),
      Alarm(title: "Deep Work Start", hour: 9, minute: 30, challenge: .math)
    ]
  }

  private static func checklistTasks() -> [StopTask] {
    [
      StopTask(title: "Sit up and put your feet on the floor"),
      StopTask(title: "Take three steady breaths"),
      StopTask(title: "Name the first thing you need to do today")
    ]
  }

  private static func sortPredicate(_ lhs: Alarm, _ rhs: Alarm) -> Bool {
    if lhs.hour == rhs.hour {
      return lhs.minute < rhs.minute
    }

    return lhs.hour < rhs.hour
  }
}
