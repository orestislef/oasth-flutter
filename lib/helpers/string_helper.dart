class StringHelper {
  static String formatSeconds(int seconds) {
    if (seconds < 60) {
      return '${seconds % 60} second${seconds % 60 != 1 ? 's' : ''}';
    }

    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    String formattedTime = '$minutes minute${minutes != 1 ? 's' : ''}';
    if (remainingSeconds > 0) {
      formattedTime +=
          ' and $remainingSeconds second${remainingSeconds != 1 ? 's' : ''}';
    }
    return formattedTime;
  }
}
