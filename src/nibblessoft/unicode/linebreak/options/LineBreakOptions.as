package nibblessoft.unicode.linebreak.options {
public class LineBreakOptions {
    public static const AUTO:String = "auto";
    public static const NORMAL:String = "normal";
    public static const STRICT:String = "strict";
    public static const LOOSE:String = "loose";

    internal static function isValidOption(str:String):Boolean {
        return [AUTO, NORMAL, STRICT, LOOSE].indexOf(str) != -1;
    }
}
}
