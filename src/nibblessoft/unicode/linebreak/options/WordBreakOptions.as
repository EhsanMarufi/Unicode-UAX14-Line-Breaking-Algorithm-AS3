package nibblessoft.unicode.linebreak.options {
public class WordBreakOptions {
    public static const NORMAL:String = "normal";
    public static const BREAK_ALL:String = "break-all";
    public static const BREAK_WORD:String = "break-word";
    public static const KEEP_ALL:String = "keep-all";

    internal static function isValidOption(str:String):Boolean {
        return [NORMAL, BREAK_ALL, BREAK_WORD, KEEP_ALL].indexOf(str) != -1;
    }
}
}
