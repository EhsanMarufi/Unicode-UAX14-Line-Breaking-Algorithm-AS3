package nibblessoft.unicode.linebreak.options {
public class Options {
    private var _lineBreak:String;
    private var _wordBreak:String;

    public function get lineBreak():String { return _lineBreak; }
    public function get wordBreak():String { return _wordBreak; }

    public function set lineBreak(value:String):void {
        _lineBreak = LineBreakOptions.isValidOption(value) ? value : LineBreakOptions.NORMAL;
    }

    public function set wordBreak(value:String):void {
        _wordBreak = WordBreakOptions.isValidOption(value) ? value : WordBreakOptions.NORMAL;
    }

    public function Options(lineBreak:String = LineBreakOptions.NORMAL, wordBreak:String = WordBreakOptions.NORMAL) {
        this.lineBreak = lineBreak;
        this.wordBreak = wordBreak;
    }
}
}
