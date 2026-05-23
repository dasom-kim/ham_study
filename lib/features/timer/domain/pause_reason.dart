enum PauseReason {
  coffee,
  restroom,
  distraction,
  rest,
}

extension PauseReasonLabel on PauseReason {
  String get label {
    return switch (this) {
      PauseReason.coffee => '커피 타임',
      PauseReason.restroom => '화장실',
      PauseReason.distraction => '딴짓',
      PauseReason.rest => '기타 휴식',
    };
  }

  String get icon {
    return switch (this) {
      PauseReason.coffee => '☕',
      PauseReason.restroom => '🧻',
      PauseReason.distraction => '📱',
      PauseReason.rest => '💤',
    };
  }
}
