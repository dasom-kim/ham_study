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

  String get imagePath {
    return switch (this) {
      PauseReason.coffee => 'assets/images/ham_coffee.png',
      PauseReason.restroom => 'assets/images/ham_toilet.png',
      PauseReason.distraction => 'assets/images/ham_phone.png',
      PauseReason.rest => 'assets/images/ham_sleep.png',
    };
  }
}
