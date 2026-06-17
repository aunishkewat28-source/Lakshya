import Foundation

struct AlarmItem: Identifiable, Codable, Equatable {
  var id: UUID
  var title: String
  var hour: Int
  var minute: Int
  var isEnabled: Bool
  var challenge: StopChallenge
  var repeatsDaily: Bool

  init(
    id: UUID = UUID(),
    title: String,
    hour: Int,
    minute: Int,
    isEnabled: Bool = true,
    challenge: StopChallenge,
    repeatsDaily: Bool = true
  ) {
    self.id = id
    self.title = title
    self.hour = hour
    self.minute = minute
    self.isEnabled = isEnabled
    self.challenge = challenge
    self.repeatsDaily = repeatsDaily
  }
}
