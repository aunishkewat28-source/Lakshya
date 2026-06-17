protocol MathPromptGenerating {
  func makePrompt() -> MathPrompt
}

struct RandomMathPromptGenerator: MathPromptGenerating {
  func makePrompt() -> MathPrompt {
    MathPrompt(left: Int.random(in: 7...19), right: Int.random(in: 3...14))
  }
}
