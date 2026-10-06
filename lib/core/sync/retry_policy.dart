import 'dart:math';

class RetryPolicy {
  RetryPolicy({Random? random}) : _random = random ?? Random();

  static const _delays = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
  ];

  final Random _random;

  Duration delayForAttempt(int attemptCount, {Duration? retryAfter}) {
    if (retryAfter != null && !retryAfter.isNegative) {
      return retryAfter;
    }

    final index = (attemptCount - 1).clamp(0, _delays.length - 1);
    final base = _delays[index];
    final jitter = _random.nextInt(31);
    return base + Duration(seconds: jitter);
  }

  Duration projectDelayForAttempt(int attemptCount, {Duration? retryAfter}) {
    if (retryAfter != null && !retryAfter.isNegative) return retryAfter;
    const delays = [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
    ];
    final index = (attemptCount - 1).clamp(0, delays.length - 1);
    final base = delays[index];
    final jitterCeiling = max(1, min(30, base.inSeconds ~/ 5));
    return base + Duration(seconds: _random.nextInt(jitterCeiling));
  }
}
