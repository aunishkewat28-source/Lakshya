protocol AlarmRepository {
  func loadSnapshot() -> AlarmSnapshot
  func saveAlarms(_ alarms: [Alarm])
  func saveActiveTimer(_ timer: CountdownTimer?)
  func saveTimerConfiguration(_ configuration: TimerConfiguration)
}
