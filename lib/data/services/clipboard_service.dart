/// Abstraction over the platform clipboard. Allows the calculator to copy
/// and paste text without depending directly on Flutter's `Clipboard` class
/// (and to be mocked in tests).
abstract class ClipboardService {
  /// Writes [text] to the system clipboard.
  Future<void> copyText(String text);

  /// Reads text from the system clipboard. Returns null when the clipboard
  /// is empty or contains non-text data.
  Future<String?> readText();
}
