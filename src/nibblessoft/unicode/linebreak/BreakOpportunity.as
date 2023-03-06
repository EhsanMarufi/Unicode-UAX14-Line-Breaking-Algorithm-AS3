package nibblessoft.unicode.linebreak {
public class BreakOpportunity {
    private var _codePoints:Vector.<uint>;
    private var _slicedCodePoints:Vector.<uint>;
    private var _required:Boolean;
    private var _startIndex:uint;
    private var _endIndex:uint;

    public function BreakOpportunity(codePoints:Vector.<uint>, lineBreak:String, startIndex:uint, endIndex:uint) {
        _codePoints = codePoints;
        _required = lineBreak == LineBreaker.BREAK_MANDATORY;
        _startIndex = startIndex;
        _endIndex = endIndex;
        _slicedCodePoints = _codePoints.slice(_startIndex, _endIndex);
    }

    /** A sub-string corresponding the code-points returned by the <code>slicedCodePoints</code> property.*/
    public function slice():String {
        return Utils.fromCodePoints(_slicedCodePoints);
    }

    /** The truncated list of code-points from the start to the end of the <code>fullCodePoints</code>.*/
    public function get slicedCodePoints():Vector.<uint> {
        return _slicedCodePoints;
    }

    public function get fullCodePoints():Vector.<uint> {
        return _codePoints;
    }

    /** Indicates whether or not the "break" is a <code>LineBreaker.BREAK_MANDATORY</code>.*/
    public function get required():Boolean {
        return _required;
    }

    /** The startIndex of this "break" relative to the <code>fullCodePoints</code>.*/
    public function get startIndex():uint {
        return _startIndex;
    }

    /** The endIndex of this "break" relative to the <code>fullCodePoints</code>.*/
    public function get endIndex():uint {
        return _endIndex;
    }
}
}
