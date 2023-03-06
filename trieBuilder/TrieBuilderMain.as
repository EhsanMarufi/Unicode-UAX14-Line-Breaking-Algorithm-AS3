// ×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××
// NOTICE (16 JULY 2018)
// The TrieBuilder is NOT working as expected and there surely are flaws that need to be addressed and
// resolved before being fully usable; This statement and the UNFINISHED work only applies to the 'TrieBuilder'
// (and not the 'Trie' and the 'LineBreakerTrieDataBase64' in the final 'LineBreaker' ported library; the
//  base64 data are proved to be valid and working.)
// This work has been started as a porting project from a JavaScript/TypeScript library obtained from GitHub
// (https://github.com/niklasvh/css-line-break); (while it could've been started from one of the standard libraries
//  of the ICU (i.e: the icu4c, or icu4j: http://userguide.icu-project.org/) that the selected library has also been
//  derived from!)
// So, the currently unnecessary and un-finished 'TrieBuilder' class, is postponed to another time.
// ×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××
package {

import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.text.TextField;

import mx.utils.StringUtil;
import mx.utils.StringUtil;
import mx.utils.StringUtil;

import nibblessoft.unicode.linebreak.LineBreaker;
import nibblessoft.unicode.linebreak.LineBreaker;
import nibblessoft.unicode.linebreak.LineBreaker;

public class TrieBuilderMain extends Sprite {
    public function TrieBuilderMain() {
        generateLineBreakTrieDataBase64();
    }

    public static function generateLineBreakTrieDataBase64():String {

        var testFile:File = File.applicationDirectory;
        testFile = testFile.resolvePath("LineBreak.txt");

        var fileStream:FileStream = new FileStream();
        fileStream.open(testFile, FileMode.READ);
        trace("file loaded: " + testFile.nativePath);
        var rawData:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();

        var builder:TrieBuilder = new TrieBuilder(LineBreaker.getBreakingClassCode("XX"));

        var rangeStart:Number = Number.NaN;
        var rangeEnd:Number = Number.NaN;
        var rangeType:Number = Number.NaN;

        rawData.split("\n").map(function (s:String, idx:int, array:Array):Array {
            var index:int = s.indexOf('#');
            var first:String = (index == -1 ? s : StringUtil.trim(s.substring(0, index)));
            return index == -1
                    ? [first]
                    : [first, StringUtil.trim(StringUtil.trim(s.substring(index + 1)).split(/\s+/)[0])];
        }).filter(function (item:Array, index:int, array:Array):Boolean {
            return item.length > 0 && item[0] != "";
        }).forEach(function (item:*, index:int, array:Array):void {
            var input_type:Array = item[0].split(';');
            var input:String = input_type[0];
            var _type:String = input_type[1];
            var start_end:Array = input.split("..");
            var start:String = start_end[0];
            var end:String = start_end.length > 1 ? start_end[1] : null;

            var category:String = item[1];
            var categoryType:int = ['Lu', 'Ll', 'Lt', 'Lm', 'Lo', 'Nd', 'Nl', 'No'].indexOf(category) != -1
                    ? LineBreaker.LETTER_NUMBER_MODIFIER
                    : 0;
            var classType:uint = LineBreaker.getBreakingClassCode(_type) + categoryType;
            if (!classType) {
                throw new Error("Invalid class type '" + _type + "' found.");
            }

            var startInt:int = parseInt(start, 16);
            var endInt:int = end ? parseInt(end, 16) : startInt;

            if (classType == rangeType && startInt - 1 == rangeEnd) {
                rangeEnd = endInt;
            } else {
                if (rangeType && !isNaN(rangeStart)) {
                    if (rangeStart != rangeEnd && !isNaN(rangeEnd)) {
                        builder.setRange(rangeStart, rangeEnd, rangeType, true);
                    } else {
                        builder.setCodepointValue(rangeStart, rangeType);
                    }
                }
                rangeType = classType;
                rangeStart = startInt;
                rangeEnd = endInt;
            }
        });

        var base64:String = TrieBuilder.serializeBase64(builder.freeze());
        trace("base64.length: " + base64.length + ", base64:");
        trace(base64);
        return base64;
    }
}
}
