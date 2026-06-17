import XCTest
@testable import Lakshya

@MainActor
final class AlarmDashboardViewModelTests: XCTestCase {
  func testStartTimerUsesSelectedPresetAndChallenge() {
    let repository = InMemoryAlarmRepository(
      snapshot: AlarmSnapshot(
        alarms: [],
        activeTimer: nil,
        timerConfiguration: TimerConfiguration(presetMinutes: 25, challenge: .math)
      )
    )
    let startDate = Self.makeDate(hour: 6, minute: 0)
    let viewModel = AlarmDashboardViewModel(
      repository: repository,
      dateProvider: FixedDateProvider(now: startDate),
      mathPromptGenerator: StubMathPromptGenerator(),
      calendar: Self.utcCalendar,
      startsTimerDriver: false
    )

    viewModel.startTimer()

    XCTAssertEqual(viewModel.activeTimer?.durationMinutes, 25)
    XCTAssertEqual(viewModel.activeTimer?.challenge, .math)
    XCTAssertEqual(viewModel.activeTimer?.endDate, startDate.addingTimeInterval(25 * 60))
    XCTAssertEqual(repository.snapshot.activeTimer, viewModel.activeTimer)
  }

  func testRefreshTriggersExpiredTimerAlert() {
    let now = Self.makeDate(hour: 8, minute: 0)
    let expiredTimer = CountdownTimer(durationMinutes: 5, challenge: .checklist, endDate: now.addingTimeInterval(-1))
    let repository = InMemoryAlarmRepository(
      snapshot: AlarmSnapshot(
        alarms: [],
        activeTimer: expiredTimer,
        timerConfiguration: .default
      )
    )
    let viewModel = AlarmDashboardViewModel(
      repository: repository,
      dateProvider: FixedDateProvider(now: now),
      mathPromptGenerator: StubMathPromptGenerator(),
      calendar: Self.utcCalendar,
      startsTimerDriver: false
    )

    viewModel.refresh(now: now)

    XCTAssertNil(viewModel.activeTimer)
    XCTAssertEqual(viewModel.activeAlert?.source, .timer)
    XCTAssertEqual(viewModel.activeAlert?.challenge, .checklist)
    XCTAssertNil(repository.snapshot.activeTimer)
  }

  func testAlarmTriggersOnlyOncePerMinuteAndCanTriggerNextDay() {
    let alarm = Alarm(title: "Study Sprint", hour: 7, minute: 30, challenge: .math)
    let firstTriggerTime = Self.makeDate(year: 2026, month: 6, day: 18, hour: 7, minute: 30)
    let repository = InMemoryAlarmRepository(
      snapshot: AlarmSnapshot(
        alarms: [alarm],
        activeTimer: nil,
        timerConfiguration: .default
      )
    )
    let viewModel = AlarmDashboardViewModel(
      repository: repository,
      dateProvider: FixedDateProvider(now: firstTriggerTime),
      mathPromptGenerator: StubMathPromptGenerator(prompt: MathPrompt(left: 10, right: 4)),
      calendar: Self.utcCalendar,
      startsTimerDriver: false
    )

    viewModel.refresh(now: firstTriggerTime)
    XCTAssertEqual(viewModel.activeAlert?.title, "Study Sprint")

    viewModel.updateAnswer("14")
    viewModel.finishActiveAlert()
    viewModel.refresh(now: firstTriggerTime.addingTimeInterval(20))
    XCTAssertNil(viewModel.activeAlert)

    let nextDay = Self.makeDate(year: 2026, month: 6, day: 19, hour: 7, minute: 30)
    viewModel.refresh(now: nextDay)
    XCTAssertEqual(viewModel.activeAlert?.title, "Study Sprint")
  }

  func testChecklistAlertNeedsAllTasksBeforeStopping() {
    let now = Self.makeDate(hour: 9, minute: 0)
    let expiredTimer = CountdownTimer(durationMinutes: 15, challenge: .checklist, endDate: now.addingTimeInterval(-5))
    let repository = InMemoryAlarmRepository(
      snapshot: AlarmSnapshot(
        alarms: [],
        activeTimer: expiredTimer,
        timerConfiguration: .default
      )
    )
    let viewModel = AlarmDashboardViewModel(
      repository: repository,
      dateProvider: FixedDateProvider(now: now),
      mathPromptGenerator: StubMathPromptGenerator(),
      calendar: Self.utcCalendar,
      startsTimerDriver: false
    )

    viewModel.refresh(now: now)
    viewModel.finishActiveAlert()
    XCTAssertNotNil(viewModel.activeAlert)

    let taskIDs = viewModel.activeAlert?.tasks.map(\.id) ?? []
    taskIDs.forEach { viewModel.toggleTask($0) }
    viewModel.finishActiveAlert()

    XCTAssertNil(viewModel.activeAlert)
  }

  private static let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
    return calendar
  }()

  private static func makeDate(
    year: Int = 2026,
    month: Int = 6,
    day: Int = 18,
    hour: Int,
    minute: Int
  ) -> Date {
    utcCalendar.date(from: DateComponents(
      calendar: utcCalendar,
      timeZone: utcCalendar.timeZone,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute
    )) ?? .now
  }
}

private final class InMemoryAlarmRepository: AlarmRepository {
  var snapshot: AlarmSnapshot

  init(snapshot: AlarmSnapshot) {
    self.snapshot = snapshot
  }

  func loadSnapshot() -> AlarmSnapshot {
    snapshot
  }

  func saveAlarms(_ alarms: [Alarm]) {
    snapshot.alarms = alarms
  }

  func saveActiveTimer(_ timer: CountdownTimer?) {
    snapshot.activeTimer = timer
  }

  func saveTimerConfiguration(_ configuration: TimerConfiguration) {
    snapshot.timerConfiguration = configuration
  }
}

private struct FixedDateProvider: DateProviding {
  var now: Date
}

private struct StubMathPromptGenerator: MathPromptGenerating {
  var prompt = MathPrompt(left: 8, right: 5)

  func makePrompt() -> MathPrompt {
    prompt
  }
}
