import Foundation
import Observation

@MainActor
@Observable
final class AlarmStore {
  private enum StorageKey {
    static let alarms = "rise-ritual.alarms"
    static let activeTimer = "rise-ritual.activeTimer"
    static let timerPresetMinutes = "rise-ritual.timerPresetMinutes"
    static let timerChallenge = "rise-ritual.timerChallenge"
  }

  private let calendar = Calendar.current
  private let defaults = UserDefaults.standard
  private var ticker: Timer?
  private var lastTriggeredMinuteByAlarmID: [UUID: String] = [:]

  var alarms: [AlarmItem] = []
  var now = Date.now
  var timerPresetMinutes = 15
  var timerChallenge: StopChallenge = .checklist
  var activeTimer: CountdownTimer?
  var activeAlert: ActiveAlert?
  var draftAlarmTitle = ""
  var draftAlarmTime = AlarmStore.defaultDraftAlarmTime()
  var draftAlarmChallenge: StopChallenge = .checklist
  var alertTriggerCount = 0
  var completedAlertCount = 0

  init() {
    load()
    startTicker()
    tick()
  }

  var timerRemaining: TimeInterval? {
    guard let activeTimer else {
      return nil
    }

    return max(0, activeTimer.endDate.timeIntervalSince(now))
  }

  var hasActiveTimer: Bool {
    activeTimer != nil
  }

  func startTimer() {
    let minutes = max(1, timerPresetMinutes)
    activeTimer = CountdownTimer(
      durationMinutes: minutes,
      challenge: timerChallenge,
      endDate: now.addingTimeInterval(Double(minutes) * 60)
    )
    saveTimer()
  }

  func cancelTimer() {
    activeTimer = nil
    saveTimer()
  }

  func addAlarm() {
    let components = calendar.dateComponents([.hour, .minute], from: draftAlarmTime)
    let trimmedTitle = draftAlarmTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    let title = trimmedTitle.isEmpty ? "Focus Alarm" : trimmedTitle
    let alarm = AlarmItem(
      title: title,
      hour: components.hour ?? 7,
      minute: components.minute ?? 0,
      challenge: draftAlarmChallenge
    )

    alarms.append(alarm)
    alarms.sort(by: sortPredicate(_:_:))
    persistAlarms()
    draftAlarmTitle = ""
    draftAlarmTime = nextSuggestedAlarmTime(from: draftAlarmTime)
    draftAlarmChallenge = .checklist
  }

  func deleteAlarms(at offsets: IndexSet) {
    for offset in offsets.sorted(by: >) {
      alarms.remove(at: offset)
    }
    persistAlarms()
  }

  func setAlarmEnabled(_ id: UUID, isEnabled: Bool) {
    guard let index = alarms.firstIndex(where: { $0.id == id }) else {
      return
    }

    alarms[index].isEnabled = isEnabled
    persistAlarms()
  }

  func updateTimerPreset(_ minutes: Int) {
    timerPresetMinutes = minutes
    defaults.set(minutes, forKey: StorageKey.timerPresetMinutes)
  }

  func updateTimerChallenge(_ challenge: StopChallenge) {
    timerChallenge = challenge
    defaults.set(challenge.rawValue, forKey: StorageKey.timerChallenge)
  }

  func updateDraftChallenge(_ challenge: StopChallenge) {
    draftAlarmChallenge = challenge
  }

  func toggleTask(_ id: UUID) {
    guard var activeAlert else {
      return
    }

    guard let index = activeAlert.tasks.firstIndex(where: { $0.id == id }) else {
      return
    }

    activeAlert.tasks[index].isDone.toggle()
    self.activeAlert = activeAlert
  }

  func updateAnswer(_ value: String) {
    guard var activeAlert else {
      return
    }

    activeAlert.enteredAnswer = value.filter(\.isNumber)
    self.activeAlert = activeAlert
  }

  func finishActiveAlert() {
    guard let activeAlert, activeAlert.isResolved else {
      return
    }

    completedAlertCount += 1
    self.activeAlert = nil
  }

  func formattedTime(for alarm: AlarmItem) -> String {
    var components = DateComponents()
    components.hour = alarm.hour
    components.minute = alarm.minute
    let date = calendar.date(from: components) ?? Date.now
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

  private func load() {
    if let data = defaults.data(forKey: StorageKey.alarms),
       let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data) {
      alarms = decoded.sorted(by: sortPredicate(_:_:))
    } else {
      alarms = [
        AlarmItem(title: "Morning Reset", hour: 7, minute: 0, challenge: .checklist),
        AlarmItem(title: "Deep Work Start", hour: 9, minute: 30, challenge: .math)
      ]
    }

    let preset = defaults.integer(forKey: StorageKey.timerPresetMinutes)
    if preset > 0 {
      timerPresetMinutes = preset
    }

    if let rawValue = defaults.string(forKey: StorageKey.timerChallenge),
       let challenge = StopChallenge(rawValue: rawValue) {
      timerChallenge = challenge
    }

    if let timerData = defaults.data(forKey: StorageKey.activeTimer),
       let decodedTimer = try? JSONDecoder().decode(CountdownTimer.self, from: timerData) {
      activeTimer = decodedTimer
    }
  }

  private func persistAlarms() {
    if let data = try? JSONEncoder().encode(alarms) {
      defaults.set(data, forKey: StorageKey.alarms)
    }
  }

  private func saveTimer() {
    guard let activeTimer else {
      defaults.removeObject(forKey: StorageKey.activeTimer)
      return
    }

    if let data = try? JSONEncoder().encode(activeTimer) {
      defaults.set(data, forKey: StorageKey.activeTimer)
    }
  }

  private func startTicker() {
    ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.tick()
      }
    }
    ticker?.tolerance = 0.2
  }

  private func tick() {
    now = Date.now
    triggerTimerIfNeeded()
    triggerAlarmIfNeeded()
  }

  private func triggerTimerIfNeeded() {
    guard let activeTimer else {
      return
    }

    guard now >= activeTimer.endDate else {
      return
    }

    self.activeTimer = nil
    saveTimer()

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
        tasks: makeChecklistTasks(),
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
        mathPrompt: makeMathPrompt(),
        enteredAnswer: ""
      )
    }
  }

  private func makeChecklistTasks() -> [StopTask] {
    [
      StopTask(title: "Sit up and put your feet on the floor"),
      StopTask(title: "Take three steady breaths"),
      StopTask(title: "Name the first thing you need to do today")
    ]
  }

  private func makeMathPrompt() -> MathPrompt {
    let left = Int.random(in: 7...19)
    let right = Int.random(in: 3...14)
    return MathPrompt(left: left, right: right)
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

  private func sortPredicate(_ lhs: AlarmItem, _ rhs: AlarmItem) -> Bool {
    if lhs.hour == rhs.hour {
      return lhs.minute < rhs.minute
    }

    return lhs.hour < rhs.hour
  }

  private static func defaultDraftAlarmTime() -> Date {
    let calendar = Calendar.current
    let rounded = calendar.date(bySetting: .minute, value: 0, of: .now) ?? .now
    return calendar.date(byAdding: .hour, value: 1, to: rounded) ?? .now
  }

  private func nextSuggestedAlarmTime(from date: Date) -> Date {
    calendar.date(byAdding: .hour, value: 1, to: date) ?? date
  }
}
