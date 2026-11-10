abstract final class PointsCalculator {
  static int calculate({
    num wins = 0,
    num draws = 0,
    num saves = 0,
    num goals = 0,
    num fouls = 0,
  }) =>
      wins.toInt() * 3 +
      draws.toInt() +
      saves.toInt() +
      goals.toInt() * 2 -
      fouls.toInt() * 2;
}
