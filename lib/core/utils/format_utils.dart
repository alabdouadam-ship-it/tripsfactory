class FormatUtils {
  /// Formats a [Duration] or seconds [int] into a string like "mm:ss".
  static String formatDuration(dynamic duration) {
    Duration d;
    if (duration is Duration) {
      d = duration;
    } else if (duration is int) {
      d = Duration(seconds: duration);
    } else {
      return "00:00";
    }

    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
