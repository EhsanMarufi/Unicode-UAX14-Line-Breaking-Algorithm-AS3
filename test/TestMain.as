package {

import flash.display.Sprite;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

import mx.utils.StringUtil;

import nibblessoft.unicode.linebreak.LineBreaker;
import nibblessoft.unicode.linebreak.Utils;
import nibblessoft.unicode.linebreak.options.LineBreakOptions;
import nibblessoft.unicode.linebreak.options.Options;
import nibblessoft.unicode.linebreak.options.WordBreakOptions;

public class TestMain extends Sprite {
    private static const ERROR_MSG:String = "ERROR! The implementation did NOT have produced the expected results!";

    public function TestMain() {
        trace("===================================");
        trace("Line Breaker Tests\n");
        lineBreakerTest();

        trace("===================================");
        trace("Validating the implementation against the Unicode Line Break Test file (LineBreakTest.txt)\n");

        trace("===================================");
    }

    private static function lineBreakerTest():void {
        function areArraysIdentical(a:Array, b:Array):Boolean {
            var LEN:uint = a.length;
            if (LEN != b.length) return false;
            for (var i:uint = 0; i < LEN; ++i)
                if (a[i] != b[i])
                    return false;
            return true;
        }

        function doLineBreaking(str:String, options:Options = null):Array {
            var breaker:Object = LineBreaker.lineBreaker(str, options);

            var words:Array = [];
            var bk:Object;

            while (!(bk = breaker.next()).done) {
                words.push(bk.value.slice());
            }

            return words;
        }

        function testLineBreakingResults(input:String, expectedResult:Array, options:Options = null):void {
            var resultedOutput:Array = doLineBreaking(input, options);
            trace("----------------");
            trace("input text: " + input);
            trace("   expected result: [" + expectedResult.join(", ") + "]");
            trace("   resulted output: [" + resultedOutput.join(", ") + "]");
            if (areArraysIdentical(resultedOutput, expectedResult)) {
                trace("   [OK] The expected result is identical to the resulted output.");
            }
            else {
                trace("   [ERROR]");
                throw new Error(ERROR_MSG);
            }
        }

        testLineBreakingResults(
                "Lorem ipsum lol.",
                ["Lorem ", "ipsum ", "lol."],
                null // options
        );
        // TODO: THE 3RD ITEM IS ALWAYS WRONG, FIGURE OUT WHY (AT INDEX: 2; THE IMPLEMENTATION SEPARATES THEM)
        testLineBreakingResults(
                "次の単語グレートブリテンおよび北アイルランド連合王国で本当に大きな言葉",
                [
                    "次の", "単語グ", "レー", "ト", "ブ", "リ", "テ", "ン",
                    "お", "よ", "び", "北ア", "イ", "ル", "ラ", "ン", "ド",
                    "連合王国で", "本当に", "大き", "な", "言葉"
                ],
                new Options(LineBreakOptions.NORMAL, WordBreakOptions.KEEP_ALL)
        );
        testLineBreakingResults(
                "این عبارت‌ها، برای سنجش صحت عملکرد این پیاده‌سازی است.",
                [
                    "این ", "عبارت‌ها، ", "برای ", "سنجش ", "صحت ",
                    "عملکرد ", "این ", "پیاده‌سازی ", "است."
                ],
                null
        );
    }

    /**
     * Tests the implementation against the Unicode Line Break Test file (LineBreakTest.txt)
     */
    public static function unicodeLineBreakingAlgorithmTests():void {
        var testFile:File = File.applicationDirectory;
        testFile = testFile.resolvePath("LineBreakTest.txt");

        var fileStream:FileStream = new FileStream();
        fileStream.open(testFile, FileMode.READ);
        trace("test file loaded: " + testFile.nativePath);
        var fileContents:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();


        fileContents.split("\n").filter(function (item:*, index:int, array:Array):Boolean {
            return item.length > 0 && // ignore empty lines
                    item.charAt(0) != "#"; // ignore comment lines
        }).forEach(function (item:String, index:int, array:Array):void {
            var splitted:Array = item.split('#');
            var input:String = StringUtil.trim(splitted[0]);
            var comment:String = splitted.length ? StringUtil.trim(splitted[1]) : '';

            var inputs:Array = input.split(/\s+/g);
            var codePoints:Vector.<uint> = new Vector.<uint>();
            var codePointsHex:Vector.<String> = new Vector.<String>();
            var breaks:Vector.<String> = new Vector.<String>();

            inputs.forEach(function (strItem:String, index:int, array:Array):void {
                if ([LineBreaker.BREAK_ALLOWED, LineBreaker.BREAK_MANDATORY, LineBreaker.BREAK_NOT_ALLOWED].indexOf(strItem) != -1) {
                    breaks.push(strItem);
                } else {
                    codePointsHex.push("0x" + strItem);
                    codePoints.push(parseInt(strItem, 16));
                }
            });


            function test(codePoints:Vector.<uint>, expectedBreaks:Vector.<String>):void {
                var EXPECTED_BREAKS_COUNT:uint = expectedBreaks.length;
                for (var i:uint = 0; i < EXPECTED_BREAKS_COUNT; ++i) {
                    var expectedBreak:String = expectedBreaks[i];
                    var br:String = LineBreaker.lineBreakAtIndex(codePoints, i);

                    // In the Unicode Line Break test file, No 'MANDATORY' break is implemented; thus to meet the
                    // conformance requirements, all of the 'BREAK_MANDATORY' will be replaced with 'BREAK_ALLOWED'
                    const replaceMandatoryBreaksWithAllowedBreaks:Boolean = true;
                    if (replaceMandatoryBreaksWithAllowedBreaks)
                        br = br.replace(LineBreaker.BREAK_MANDATORY, LineBreaker.BREAK_ALLOWED);


                    var status:String = br == expectedBreak ? "[OK]" : "[ERROR]";
                    trace("index: " + i + ", status: " + status + ", expected break: '" + expectedBreak + "', generated break: '" + br + "'");
                    if (br != expectedBreak)
                        throw new Error(ERROR_MSG);
                }
            }

            trace("------");
            trace("#" + index + ": " + comment + "\n" +
                    "codepoints: [" + codePointsHex.join(", ") + "], breaks: [" + breaks.join(", ") + "]"
            );
            test(codePoints, breaks);
        });
    }

    public static function inlinelineBreakTests():void {
        var breakTypesCodePoints:Vector.<uint> = new Vector.<uint>();
        ([LineBreaker.BREAK_MANDATORY, LineBreaker.BREAK_NOT_ALLOWED, LineBreaker.BREAK_ALLOWED]).forEach(
                function (item:String, index:int, array:Array):void {
                    breakTypesCodePoints.push(item.charCodeAt(0));
                }
        );

        function test(description:String, input:String, options:Options = null):void {
            // The input string is amalgamated with the "line breaking" symbols, after removing those symbol a "pure"
            // list of code-points will remain.
            var pureCodePoints:Vector.<uint> = new Vector.<uint>();

            Utils.toCodePoints(input).forEach( function (codePoint:uint, index:int, array:Vector.<uint>):void {
                if (breakTypesCodePoints.indexOf(codePoint) == -1) {
                    pureCodePoints.push(codePoint);
                }
            });

            var result:String = LineBreaker.inlineBreakOpportunities(Utils.fromCodePoints(pureCodePoints), options);

            trace("---------------------");
            trace(description);
            trace("   expected result: " + input);
            trace("   resulted output: " + result);

            if (input == result) {
                trace("   [OK] The expected result is identical to the resulted output.");
            }
            else {
                trace("   [ERROR]");
                throw new Error(ERROR_MSG);
            }
        }


        var options1:Options = new Options(LineBreakOptions.STRICT, WordBreakOptions.NORMAL);
        trace("******************");
        trace("line break: strict");

        trace("\nline-break-strict-011.xht");
        test("Japanese small kana: HIRAGANA LETTER SMALL A", '×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ぁ÷サ÷ン÷プ÷ル÷文!', options1);
        test("Japanese small kana: HIRAGANA LETTER SMALL I", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ぃ÷サ÷ン÷プ÷ル÷文!", options1);
        test("Japanese small kana: HIRAGANA LETTER SMALL U", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ぅ÷サ÷ン÷プ÷ル÷文!", options1);
        test("Japanese small kana: HIRAGANA LETTER SMALL E", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ぇ÷サ÷ン÷プ÷ル÷文!", options1);
        test("Japanese small kana: HIRAGANA LETTER SMALL O", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ぉ÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-012.xht");
        test("Katakana-Hiragana prolonged sound mark - fullwidth", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ー÷サ÷ン÷プ÷ル÷文!", options1);
        test("Katakana-Hiragana prolonged sound mark - halfwidth", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ｰ÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-013.xht");
        test("HYPHEN (U+2010)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‐÷サ÷ン÷プ÷ル÷文!", options1);
        test("ENDASH (U+2013)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×–÷サ÷ン÷プ÷ル÷文!", options1);
        test("〜", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×〜÷サ÷ン÷プ÷ル÷文!", options1);
        test("゠", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×゠÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-014.xht");
        test("IDEOGRAPHIC ITERATION MARK (U+3005)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×々÷サ÷ン÷プ÷ル÷文!", options1);
        test("VERTICAL IDEOGRAPHIC ITERATION MARK (U+3B)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×〻÷サ÷ン÷プ÷ル÷文!", options1);
        test("ゝ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ゝ÷サ÷ン÷プ÷ル÷文!", options1);
        test("ゞ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ゞ÷サ÷ン÷プ÷ル÷文!", options1);
        test("ヽ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ヽ÷サ÷ン÷プ÷ル÷文!", options1);
        test("ヾ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ヾ÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-015.xht");
        test("inseparable characters TWO DOT LEADER", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‥÷サ÷ン÷プ÷ル÷文!", options1);
        test("inseparable characters HORIZONTAL ELLIPSIS", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×…÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-016.xht");
        test("centered punctuation marks COLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×:÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks SEMICOLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×;÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks KATAKANA MIDDLE DOT", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×・÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks FULLWIDTH COLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×：÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks FULLWIDTH SEMICOLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×；÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks HALFWIDTH KATAKANA MIDDLE DOT", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×･÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×?÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks DOUBLE EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‼÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks DOUBLE QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁇÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks QUESTION EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁈÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks EXCLAMATION QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁉÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks FULLWIDTH EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×！÷サ÷ン÷プ÷ル÷文!", options1);
        test("centered punctuation marks FULLWIDTH QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×？÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-017.xht");
        test("postfixes PERCENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×%÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes CENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×¢÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes DEGREE SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×°÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes PER MILLE SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‰÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes PRIME", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×′÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes DOUBLE PRIME", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×″÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes DEGREE CELSIUS", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×℃÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes FULLWIDTH PERCENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×％÷サ÷ン÷プ÷ル÷文!", options1);
        test("postfixes FULLWIDTH CENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×￠÷サ÷ン÷プ÷ル÷文!", options1);

        trace("\nline-break-strict-018.xht");
        test("prefixes DOLLAR SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷$×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes POUND SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷£×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes YEN SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷¥×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes EURO SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷€×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes NUMERO SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷№×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes FULLWIDTH DOLLAR SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷＄×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes FULLWIDTH POUND SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷￡×サ÷ン÷プ÷ル÷文!", options1);
        test("prefixes FULLWIDTH YEN SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷￥×サ÷ン÷プ÷ル÷文!", options1);


        var options2:Options = new Options(LineBreakOptions.NORMAL, WordBreakOptions.NORMAL);
        trace("\n\n******************");
        trace("line break: normal");

        trace("\nbreaks before hyphens");
        test("HYPHEN (U+2010)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷‐÷サ÷ン÷プ÷ル÷文!", options2);
        test("ENDASH (U+2013)", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷–÷サ÷ン÷プ÷ル÷文!", options2);
        test("〜", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷〜÷サ÷ン÷プ÷ル÷文!", options2);
        test("゠", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷゠÷サ÷ン÷プ÷ル÷文!", options2);

        trace("\nline-break-normal-021.xht");
        test("々", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×々÷サ÷ン÷プ÷ル÷文!", options2);
        test("〻", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×〻÷サ÷ン÷プ÷ル÷文!", options2);
        test("ゝ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ゝ÷サ÷ン÷プ÷ル÷文!", options2);
        test("ゞ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ゞ÷サ÷ン÷プ÷ル÷文!", options2);
        test("ヽ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ヽ÷サ÷ン÷プ÷ル÷文!", options2);
        test("ヾ", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×ヾ÷サ÷ン÷プ÷ル÷文!", options2);

        trace("\nline-break-normal-022.xht");
        test("inseparable characters TWO DOT LEADER", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‥÷サ÷ン÷プ÷ル÷文!", options2);
        test("inseparable characters HORIZONTAL ELLIPSIS", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×…÷サ÷ン÷プ÷ル÷文!", options2);

        trace("\nline-break-normal-023.xht");
        test("centered punctuation marks COLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×:÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks SEMICOLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×;÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks KATAKANA MIDDLE DOT", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×・÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks FULLWIDTH COLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×：÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks FULLWIDTH SEMICOLON", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×；÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks HALFWIDTH KATAKANA MIDDLE DOT", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×･÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×?÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks DOUBLE EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‼÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks DOUBLE QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁇÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks QUESTION EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁈÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks EXCLAMATION QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×⁉÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks FULLWIDTH EXCLAMATION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×！÷サ÷ン÷プ÷ル÷文!", options2);
        test("centered punctuation marks FULLWIDTH QUESTION MARK", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×？÷サ÷ン÷プ÷ル÷文!", options2);

        trace("\nline-break-normal-024.xht");
        test("postfixes PERCENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×%÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes CENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×¢÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes DEGREE SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×°÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes PER MILLE SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×‰÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes PRIME", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×′÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes DOUBLE PRIME", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×″÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes DEGREE CELSIUS", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×℃÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes FULLWIDTH PERCENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×％÷サ÷ン÷プ÷ル÷文!", options2);
        test("postfixes FULLWIDTH CENT SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文×￠÷サ÷ン÷プ÷ル÷文!", options2);

        trace("\nline-break-normal-025.xht");
        test("prefixes DOLLAR SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷$×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes POUND SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷£×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes YEN SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷¥×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes EURO SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷€×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes NUMERO SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷№×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes FULLWIDTH DOLLAR SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷＄×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes FULLWIDTH POUND SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷￡×サ÷ン÷プ÷ル÷文!", options2);
        test("prefixes FULLWIDTH YEN SIGN", "×サ÷ン÷プ÷ル÷文÷サ÷ン÷プ÷ル÷文÷￥×サ÷ン÷プ÷ル÷文!", options2);


        var options3:Options = new Options(LineBreakOptions.NORMAL, WordBreakOptions.NORMAL);
        trace("\n\n******************");
        trace("word-break: normal");

        trace("\nword-break-break-all-000.html");
        test("0", "×l×a×t×i×n×l×a×t×i×n×l×a×t×i×n×​÷l×a×t×i×n!", options3);

        trace("\nword-break-normal-002.xht");
        test("1", "×F×i×l×l×e×r× ÷T×e×x×t× ÷F×i×l×l×e×r× ÷T×e×x×t× ÷F×i×l×l×e×r× ÷T×e×x×t!", options3);
        test("2", "×満÷た÷す÷た÷め÷の÷文÷字× ÷F×i×l×l×e×r× ÷T×e×x×t!", options3);
        test("3", "×満÷た÷す÷た÷め÷の÷文÷字÷満÷た÷す÷た÷め÷の÷文÷字!", options3);

        trace("\n");
        test("sample", "×这÷是÷一÷些÷汉÷字×,× ÷a×n×d× ÷s×o×m×e× ÷L×a×t×i×n×,× ÷و× ÷ک×م×ی× ÷ن×و×ش×ت×ن× ÷ع×ر×ب×ی×,×แ×ล×ะ×ต×ั×ว×อ×ย×่×า×ง×ก×า×ร×เ×ข×ี×ย×น×ภ×า×ษ×า×ไ×ท×ย×.!", options3);


        var options4:Options = new Options(LineBreakOptions.NORMAL, WordBreakOptions.BREAK_ALL);
        trace("\n\n******************");
        trace("word-break: break-all");

        trace("\nword-break-break-all-000.html");
        test("0", "×日÷本÷語÷日÷本÷語÷日÷本÷語!", options4);
        test("1", "×L÷a÷t÷i÷n× ÷l÷a÷t÷i÷n× ÷l÷a÷t÷i÷n× ÷l÷a÷t÷i÷n!", options4);
        test("2", "×한÷글÷이× ÷한÷글÷이× ÷한÷글÷이!", options4);
        test("3", "×ภ÷า÷ษ÷า÷ไ÷ท÷ย÷ภ÷า÷ษ÷า÷ไ÷ท÷ย!", options4);
        test("4", "×这÷是÷一÷些÷汉÷字×,× ÷a÷n÷d× ÷s÷o÷m÷e× ÷L÷a÷t÷i÷n×,× ÷و× ÷ک÷م÷ی× ÷ن÷و÷ش÷ت÷ن× ÷ع÷ر÷ب÷ی×,× ÷แ÷ล÷ะ÷ต÷ั÷ว÷อ÷ย÷่÷า÷ง÷ก÷า÷ร÷เ÷ข÷ี÷ย÷น÷ภ÷า÷ษ÷า÷ไ÷ท÷ย×.!", options4);

        var options5:Options = new Options(LineBreakOptions.NORMAL, WordBreakOptions.KEEP_ALL);
        trace("\n\n******************");
        trace("word-break: keep-all");
        test("0", "×这×是×一×些×汉×字×,× ÷a×n×d× ÷s×o×m×e× ÷L×a×t×i×n×,× ÷و× ÷ک×م×ی× ÷ن×و×ش×ت×ن× ÷ع×ر×ب×ی×,×แ×ล×ะ×ต×ั×ว×อ×ย×่×า×ง×ก×า×ร×เ×ข×ี×ย×น×ภ×า×ษ×า×ไ×ท×ย×.!", options5);
    }
}
}
