package nibblessoft.unicode.linebreak {
import nibblessoft.unicode.linebreak.options.LineBreakOptions;
import nibblessoft.unicode.linebreak.options.Options;
import nibblessoft.unicode.linebreak.options.WordBreakOptions;

public class LineBreaker {

    // -----------------------------------------------------------------
    //           Non-tailorable Line Breaking Classes
    // -----------------------------------------------------------------

    /** Mandatory Break: Cause a line break (after) */
    private static const BK:uint = 1;

    /** Carriage Return: Cause a line break (after), except between CR and LF */
    private static const CR:uint = 2;

    /** Line Feed: Cause a line break (after) */
    private static const LF:uint = 3;

    /** Combining Mark: Prohibit a line break between the character and the preceding character */
    private static const CM:uint = 4;

    /** Next Line: Cause a line break (after) */
    private static const NL:uint = 5;

    /** Surrogate: Do not occur in well-formed text */
    private static const SG:uint = 6;

    /** Word Joiner: Prohibit line breaks before and after */
    private static const WJ:uint = 7;

    /** Zero Width Space: Provide a break opportunity */
    private static const ZW:uint = 8;

    /** Quotation: Non-breaking ("Glue") */
    private static const GL:uint = 9;

    /** Space: Enable indirect line breaks */
    private static const SP:uint = 10;

    /** Zero Width Joiner: Prohibit line breaks within joiner sequences */
    private static const ZWJ:uint = 11;


    // -----------------------------------------------------------------
    //           Break Opportunities
    // -----------------------------------------------------------------

    /** Break Opportunity Before and After: Provide a line break opportunity before and after the character */
    private static const B2:uint = 12;

    /** Break After: Generally provide a line break opportunity after the character */
    private static const BA:uint = 13;

    /** Break Before: Generally provide a line break opportunity before the character */
    private static const BB:uint = 14;

    /** Hyphen: Provide a line break opportunity after the character, except in numeric context */
    private static const HY:uint = 15;

    /** Contingent Break Opportunity: Provide a line break opportunity contingent on additional information */
    private static const CB:uint = 16;


    // -----------------------------------------------------------------
    //           Characters Prohibiting Certain Breaks
    // -----------------------------------------------------------------

    /** Close Punctuation: prohibit line breaks before */
    private static const CL:uint = 17;

    /** Close Punctuation: prohibit line breaks before */
    private static const CP:uint = 18;

    /** Exclamation/Interrogation: Prohibit line breaks before */
    private static const EX:uint = 19;

    /** Inseparable: Allow only indirect line breaks between pairs */
    private static const IN:uint = 20;

    /** Nonstarter: Allow only indirect line breaks before */
    private static const NS:uint = 21;

    /** Open Punctuation: prohibit line breaks after */
    private static const OP:uint = 22;

    /** Quotation: Act like they are both opening and closing */
    private static const QU:uint = 23;


    // -----------------------------------------------------------------
    //           Numeric Context
    // -----------------------------------------------------------------

    /** Infix Numeric Separator: Prevent breaks after any and before numeric */
    private static const IS:uint = 24;

    /** Numeric: Form numeric expressions for line breaking purposes */
    private static const NU:uint = 25;

    /** Postfix Numeric: Do not break following a numeric expression */
    private static const PO:uint = 26;

    /** Prefix Numeric: Do not break in front of a numeric expression */
    private static const PR:uint = 27;

    /** Symbols Allowing Break After: Prevent a break before, and allow a break after */
    private static const SY:uint = 28;


    // -----------------------------------------------------------------
    //           Other Characters
    // -----------------------------------------------------------------

    /** Ambiguous (Alphabetic or Ideographic): Characters with Ambiguous East Asian Width, Act like AL when the
     resolved EAW is N; otherwise, act as ID */
    private static const AI:uint = 29;

    /** Alphabetic: Are alphabetic characters or symbols that are used with alphabetic characters */
    private static const AL:uint = 30;

    /** Conditional Japanese Starter: Treat as NS or ID for strict or normal breaking (e.g: Small kana) */
    private static const CJ:uint = 31;

    /** Emoji Base: Do not break from following Emoji Modifier */
    private static const EB:uint = 32;

    /** Emoji Modifier: Do not break from preceding Emoji Base */
    private static const EM:uint = 33;

    /** Hangul LV Syllable: (Hangul 2) Form Korean syllable blocks */
    private static const H2:uint = 34;

    /** Hangul LVT Syllable: (Hangul 3) Form Korean syllable blocks */
    private static const H3:uint = 35;

    /** Hebrew Letter: Do not break around a following hyphen; otherwise act as Alphabetic */
    private static const HL:uint = 36;

    /** Ideographic: Break before or after, except in some numeric context */
    private static const ID:uint = 37;

    /** Hangul L Jamo: (Conjoining jamo - Jamo Leading consonant) Form Korean syllable blocks */
    private static const JL:uint = 38;

    /** Hangul V Jamo: (Conjoining jamo - Jamo Vowel) Form Korean syllable blocks */
    private static const JV:uint = 39;

    /** Hangul T Jamo: (Conjoining jamo - Jamo Trailing consonant) Form Korean syllable blocks */
    private static const JT:uint = 40;

    /** Regional Indicator: Keep pairs together. For pairs, break before and after other classes
     (REGIONAL INDICATOR SYMBOL LETTER A .. Z)*/
    private static const RI:uint = 41;

    /** Complex Context Dependent (South East Asian: Thai, Lao, Khmer): Provide a line break opportunity
     contingent on additional, language-specific context analysis */
    private static const SA:uint = 42;

    /** Unknown: Have as yet unknown line breaking behavior or unassigned code positions */
    private static const XX:uint = 43;

    // -----------------------------------------------------------------
    // -----------------------------------------------------------------

    // Used to retrieve the numerical representations of the 'Line Breaking Classes' in the implementation
    private static const breakingClasses:Object = {
        // Non-tailorable Line Breaking Classes
        BK: BK,
        CR: CR,
        LF: LF,
        CM: CM,
        NL: NL,
        SG: SG,
        WJ: WJ,
        ZW: ZW,
        GL: GL,
        SP: SP,
        ZWJ: ZWJ,

        // Break Opportunities
        B2: B2,
        BA: BA,
        BB: BB,
        HY: HY,
        CB: CB,

        // Characters Prohibiting Certain Breaks
        CL: CL,
        CP: CP,
        EX: EX,
        IN: IN,
        NS: NS,
        OP: OP,
        QU: QU,

        // Numeric Context
        IS: IS,
        NU: NU,
        PO: PO,
        PR: PR,
        SY: SY,

        // Other Characters
        AI: AI,
        AL: AL,
        CJ: CJ,
        EB: EB,
        EM: EM,
        H2: H2,
        H3: H3,
        HL: HL,
        ID: ID,
        JL: JL,
        JV: JV,
        JT: JT,
        RI: RI,
        SA: SA,
        XX: XX
    };

    /**
     * Retrieves the numerical representation to the provided 'Line Breaking Class' through the <code>brClass</code> parameter.
     *
     * @param brClass The possible values correspond to the 'line breaking classes' defined in the
     * <a href="http://unicode.org/reports/tr14/#Table1">Unicode Line Breaking algorithm (UAX#14)</a>
     *
     * @return the implementation specific numerical representation of the provided 'line breaking class'. A special
     * value of <code>0</code> is returned if the provided string is not a valid 'Line Breaking Class'.
     */
    public static function getBreakingClassCode(brClass:String):uint {
        return breakingClasses.hasOwnProperty(brClass) ? breakingClasses[brClass] : 0;
    }

    /**
     * The Unicode 'Category' type assigned to the code-point is either a <ul>
     *   <li>letter (Lu: Letter uppercase, Ll: Letter lowercase, Lt: Letter title-case),</li>
     *   <li>or, a letter-modifier (Lm: Letter modifier),</li>
     *   <li>or, a Number (Nd: Number decimal, Nl: Number letter, No: Number other)</li>
     * </ul>
     */
    public static const LETTER_NUMBER_MODIFIER:uint = 50;

    public static const BREAK_MANDATORY:String = '!';
    public static const BREAK_NOT_ALLOWED:String = '×';
    public static const BREAK_ALLOWED:String = '÷';

    private static const unicodeLineBreakerTrie:Trie = Trie.createTrieFromBase64(LineBreakerTrieDataBase64.data);

    private static const ALPHABETICS:Array = [AL, HL];
    private static const HARD_LINE_BREAKS:Array = [BK, CR, LF, NL];
    private static const SPACE:Array = [SP, ZW];
    private static const PREFIX_POSTFIX:Array = [PR, PO];
    private static const LINE_BREAKS:Array = HARD_LINE_BREAKS.concat(SPACE);
    private static const KOREAN_SYLLABLE_BLOCK:Array = [JL, JV, JT, H2, H3];
    private static const HYPHEN:Array = [HY, BA];

    /**
     * // TODO: DOCUMENT!
     * // TODO: DISCOVER WHAT IS THE USE AND IMPORTANCE OF THE 'indices'?
     * The "Line Breaking Algorithm" takes as input only line break classes.
     * @param codePoints
     * @param lineBreakOption
     *
     * @return an <code>Object</code> with three fields:
     * <ul>
     *     <li><code>indices</code>: a <code>Vector.&lt;uint&gt;</code></li>
     *     <li><code>breakingClasses</code>: another <code>Vector.&lt;uint&gt;</code></li>
     *     <li><code>isLetterNumberModifier</code>: a <code>Vector.&lt;Boolean&gt;</code></li>
     * </ul>
     */
    public static function codePointsToCharacterClasses(
            codePoints:Vector.<uint>,
            lineBreakOption:String = LineBreakOptions.STRICT
    ):Object {
        var breakingClasses:Vector.<uint> = new Vector.<uint>();
        var indices:Vector.<uint> = new Vector.<uint>();
        var isLetterNumberModifier:Vector.<Boolean> = new Vector.<Boolean>();

        const CODEPOINTS_COUNT:uint = codePoints.length;
        for (var index:uint = 0; index < CODEPOINTS_COUNT; ++index) {
            var codePoint:uint = codePoints[index];
            var breakingClass:uint = unicodeLineBreakerTrie.get(codePoint);

            // In the implemented Trie, the Unicode 'Category' type assigned to every code-point, is amalgamated
            // together with the "line breaking class" for all the code-points.
            // The values chosen to be correspondent to the "line breaking class" for the code-points, have a value in
            // the range of: [1..43].
            // When the code-point is categorized as being a "Letter", or a "Number", or a "Letter, modifier"; then
            // a number of (e.g.) '50' gets added to the value to indicate that the character is either a "Number",
            // or a "Letter", or a "Letter modifier"; the "breakingClass" can then be easily extracted from the
            // amalgamated value by removing the added number of '50'.
            if (breakingClass > LETTER_NUMBER_MODIFIER) {
                isLetterNumberModifier.push(true);
                breakingClass -= LETTER_NUMBER_MODIFIER;
            } else {
                isLetterNumberModifier.push(false);
            }

            if ([LineBreakOptions.NORMAL, LineBreakOptions.AUTO, LineBreakOptions.LOOSE].indexOf(lineBreakOption) != -1) {
                // U+2010: HYPHEN (‐),
                // U+2013: EN DASH (–),
                // U+301C: WAVE DASH: CJK Symbol (〜),
                // U+30A0: KATAKANA-HIRAGANA DOUBLE HYPHEN (゠)
                if ([0x2010, 0x2013, 0x301c, 0x30a0].indexOf(codePoint) != -1) {
                    indices.push(index);
                    breakingClasses.push(CB);
                    continue;
                }
            }

            if (breakingClass == CM || breakingClass == ZWJ) {
                // LB10 Treat any remaining combining mark or ZWJ as AL.
                if (index == 0) {
                    indices.push(index);
                    breakingClasses.push(AL);
                    continue;
                }

                // LB9 Do not break a combining character sequence; treat it as if it has the line breaking class of
                // the base character in all of the following rules. Treat ZWJ as if it were CM.
                const prev:uint = breakingClasses[index - 1];
                if (LINE_BREAKS.indexOf(prev) == -1) {
                    indices.push(indices[index - 1]);
                    breakingClasses.push(prev);
                    continue;
                }

                indices.push(index);
                breakingClasses.push(AL);
                continue;
            }

            indices.push(index);

            if (breakingClass == CJ) {
                breakingClasses.push(lineBreakOption == LineBreakOptions.STRICT ? NS : ID);
                continue;
            }

            if (breakingClass == SA) {
                breakingClasses.push(AL);
                continue;
            }

            if (breakingClass == AI) {
                breakingClasses.push(AL);
                continue;
            }

            // For supplementary characters, a useful default is to treat characters in the range 10000..1FFFD as AL
            // and characters in the ranges 20000..2FFFD and 30000..3FFFD as ID, until the implementation can be revised
            // to take into account the actual line breaking properties for these characters.
            if (breakingClass == XX) {
                if (
                        (codePoint >= 0x20000 && codePoint <= 0x2FFFD) ||
                        (codePoint >= 0x30000 && codePoint <= 0x3FFFD)
                ) {
                    breakingClasses.push(ID);
                    continue;
                } else {
                    breakingClasses.push(AL);
                    continue;
                }
            }

            breakingClasses.push(breakingClass);
        }


        return {indices: indices, breakingClasses: breakingClasses, isLetterNumber: isLetterNumberModifier};
    }

    private static function isAdjacentWithSpaceIgnored(
            a:*, //Array<uint> | uint,
            b:uint,
            currentIndex:uint,
            breakingClasses:Vector.<uint>
    ):Boolean {
        var i:int, next:uint;
        var current:uint = breakingClasses[currentIndex];
        const LEN:uint = breakingClasses.length;

        if (a is Array ? a.indexOf(current) != -1 : a == current) {
            i = currentIndex;
            while (i <= LEN) {
                i++;
                next = breakingClasses[i];

                if (next == b) {
                    return true;
                }

                if (next != SP) {
                    break;
                }
            }
        }

        if (current == SP) {
            i = currentIndex;

            while (i > 0) {
                i--;
                const prev:uint = breakingClasses[i];

                if (a is Array ? a.indexOf(prev) != -1 : a == prev) {
                    var n:uint = currentIndex;
                    while (n <= LEN) {
                        n++;
                        next = breakingClasses[n];

                        if (next == b) {
                            return true;
                        }

                        if (next != SP) {
                            break;
                        }
                    }
                }

                if (prev != SP) {
                    break;
                }
            }
        }

        return false;
    }

    private static function previousNonSpaceClassType(currentIndex:uint, breakingClasses:Vector.<uint>):uint {
        var i:int = currentIndex;
        while (i >= 0) {
            var breakingClass:uint = breakingClasses[i];
            if (breakingClass == SP) {
                i--;
            } else {
                return breakingClass;
            }
        }
        return 0;
    }

    private static function _lineBreakAtIndex(
            codePoints:Vector.<uint>,
            breakingClasses:Vector.<uint>,
            indices:Vector.<uint>,
            index:uint,
            forbiddenBreaks:Vector.<Boolean> = null
    ):String {

        if (indices[index] == 0) {
            return BREAK_NOT_ALLOWED;
        }

        var currentIndex:int = index - 1;
        if (forbiddenBreaks is Vector.<Boolean> && forbiddenBreaks[currentIndex] == true) {
            return BREAK_NOT_ALLOWED;
        }

        var beforeIndex:int = currentIndex - 1;
        var afterIndex:int = currentIndex + 1;
        var current:int = breakingClasses[currentIndex];

        // LB4 Always break after hard line breaks.
        // LB5 Treat CR followed by LF, as well as CR, LF, and NL as hard line breaks.
        var before:int = beforeIndex >= 0 ? breakingClasses[beforeIndex] : 0;
        var next:int = breakingClasses[afterIndex];

        if (current == CR && next == LF) {
            return BREAK_NOT_ALLOWED;
        }

        if (HARD_LINE_BREAKS.indexOf(current) != -1) {
            return BREAK_MANDATORY;
        }

        // LB6 Do not break before hard line breaks.
        if (HARD_LINE_BREAKS.indexOf(next) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB7 Do not break before spaces or zero width space.
        if (SPACE.indexOf(next) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB8 Break before any character following a zero-width space, even if one or more spaces intervene.
        if (previousNonSpaceClassType(currentIndex, breakingClasses) == ZW) {
            return BREAK_ALLOWED;
        }

        // LB8a Do not break between a zero width joiner and an ideograph, emoji base or emoji modifier.
        if (
                unicodeLineBreakerTrie.get(codePoints[currentIndex]) == ZWJ &&
                (next == ID || next == EB || next == EM)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB11 Do not break before or after Word joiner and related characters.
        if (current == WJ || next == WJ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB12 Do not break after NBSP and related characters.
        if (current == GL) {
            return BREAK_NOT_ALLOWED;
        }

        // LB12a Do not break before NBSP and related characters, except after spaces and hyphens.
        if ([SP, BA, HY].indexOf(current) == -1 && next == GL) {
            return BREAK_NOT_ALLOWED;
        }

        // LB13 Do not break before ‘]’ or ‘!’ or ‘;’ or ‘/’, even after spaces.
        if ([CL, CP, EX, IS, SY].indexOf(next) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB14 Do not break after ‘[’, even after spaces.
        if (previousNonSpaceClassType(currentIndex, breakingClasses) == OP) {
            return BREAK_NOT_ALLOWED;
        }

        // LB15 Do not break within ‘”[’, even with intervening spaces.
        if (isAdjacentWithSpaceIgnored(QU, OP, currentIndex, breakingClasses)) {
            return BREAK_NOT_ALLOWED;
        }

        // LB16 Do not break between closing punctuation and a nonstarter (lb=NS), even with intervening spaces.
        if (isAdjacentWithSpaceIgnored([CL, CP], NS, currentIndex, breakingClasses)) {
            return BREAK_NOT_ALLOWED;
        }

        // LB17 Do not break within ‘——’, even with intervening spaces.
        if (isAdjacentWithSpaceIgnored(B2, B2, currentIndex, breakingClasses)) {
            return BREAK_NOT_ALLOWED;
        }

        // LB18 Break after spaces.
        if (current == SP) {
            return BREAK_ALLOWED;
        }

        // LB19 Do not break before or after quotation marks, such as ‘ ” ’.
        if (current == QU || next == QU) {
            return BREAK_NOT_ALLOWED;
        }

        // LB20 Break before and after unresolved CB.
        if (next == CB || current == CB) {
            return BREAK_ALLOWED;
        }

        // LB21 Do not break before hyphen-minus, other hyphens, fixed-width spaces, small kana, and other non-starters, or after acute accents.
        if ([BA, HY, NS].indexOf(next) != -1 || current == BB) {
            return BREAK_NOT_ALLOWED;
        }

        // LB21a Don't break after Hebrew + Hyphen.
        if (before == HL && HYPHEN.indexOf(current) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB21b Don’t break between Solidus and Hebrew letters.
        if (current == SY && next == HL) {
            return BREAK_NOT_ALLOWED;
        }

        // LB22 Do not break between two ellipses, or between letters, numbers or exclamations and ellipsis.
        if (next == IN && ALPHABETICS.concat(IN, EX, NU, ID, EB, EM).indexOf(current) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB23 Do not break between digits and letters.
        if (
                (ALPHABETICS.indexOf(next) != -1 && current == NU) ||
                (ALPHABETICS.indexOf(current) != -1 && next == NU)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB23a Do not break between numeric prefixes and ideographs, or between ideographs and numeric postfixes.
        if (
                (current == PR && [ID, EB, EM].indexOf(next) != -1) ||
                ([ID, EB, EM].indexOf(current) != -1 && next == PO)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB24 Do not break between numeric prefix/postfix and letters, or between letters and prefix/postfix.
        if (
                (ALPHABETICS.indexOf(current) != -1 && PREFIX_POSTFIX.indexOf(next) != -1) ||
                (PREFIX_POSTFIX.indexOf(current) != -1 && ALPHABETICS.indexOf(next) != -1)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB25 Do not break between the following pairs of classes relevant to numbers:
        if (
                // (PR | PO) × ( OP | HY )? NU
                ([PR, PO].indexOf(current) != -1 &&
                        (next == NU ||
                                ([OP, HY].indexOf(next) != -1 && (breakingClasses.length > (afterIndex + 1) && breakingClasses[afterIndex + 1] == NU)))) ||
                // ( OP | HY ) × NU
                ([OP, HY].indexOf(current) != -1 && next == NU) ||
                // NU ×	(NU | SY | IS)
                (current == NU && [NU, SY, IS].indexOf(next) != -1)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // NU (NU | SY | IS)* × (NU | SY | IS | CL | CP)
        if ([NU, SY, IS, CL, CP].indexOf(next) != -1) {
            var prevIndex1:int = currentIndex;
            while (prevIndex1 >= 0) {
                var prevBrType:uint = breakingClasses[prevIndex1];
                if (prevBrType == NU) {
                    return BREAK_NOT_ALLOWED;
                } else if ([SY, IS].indexOf(prevBrType) != -1) {
                    prevIndex1--;
                } else {
                    break;
                }
            }
        }

        // NU (NU | SY | IS)* (CL | CP)? × (PO | PR))
        if ([PR, PO].indexOf(next) != -1) {
            var prevIndex2:int = [CL, CP].indexOf(current) != -1 ? beforeIndex : currentIndex;
            while (prevIndex2 >= 0) {
                var prevBrType2:uint = breakingClasses[prevIndex2];
                if (prevBrType2 == NU) {
                    return BREAK_NOT_ALLOWED;
                } else if ([SY, IS].indexOf(prevBrType2) != -1) {
                    prevIndex2--;
                } else {
                    break;
                }
            }
        }

        // LB26 Do not break a Korean syllable.
        if (
                (JL === current && [JL, JV, H2, H3].indexOf(next) != -1) ||
                ([JV, H2].indexOf(current) != -1 && [JV, JT].indexOf(next) != -1) ||
                ([JT, H3].indexOf(current) != -1 && next == JT)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB27 Treat a Korean Syllable Block the same as ID.
        if (
                (KOREAN_SYLLABLE_BLOCK.indexOf(current) != -1 && [IN, PO].indexOf(next) != -1) ||
                (KOREAN_SYLLABLE_BLOCK.indexOf(next) != -1 && current == PR)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB28 Do not break between alphabetics (“at”).
        if (ALPHABETICS.indexOf(current) != -1 && ALPHABETICS.indexOf(next) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB29 Do not break between numeric punctuation and alphabetics (“e.g.”).
        if (current == IS && ALPHABETICS.indexOf(next) != -1) {
            return BREAK_NOT_ALLOWED;
        }

        // LB30 Do not break between letters, numbers, or ordinary symbols and opening or closing parentheses.
        if (
                (ALPHABETICS.concat(NU).indexOf(current) != -1 && next == OP) ||
                (ALPHABETICS.concat(NU).indexOf(next) != -1 && current == CP)
        ) {
            return BREAK_NOT_ALLOWED;
        }

        // LB30a Break between two regional indicator symbols if and only if there are an even number of regional
        // indicators preceding the position of the break.
        if (current == RI && next == RI) {
            var i:int = indices[currentIndex];
            var count:uint = 1;
            while (i > 0) {
                i--;
                if (breakingClasses[i] == RI) {
                    count++;
                } else {
                    break;
                }
            }
            if (count % 2 != 0) {
                return BREAK_NOT_ALLOWED;
            }
        }

        // LB30b Do not break between an emoji base and an emoji modifier.
        if (current == EB && next == EM) {
            return BREAK_NOT_ALLOWED;
        }

        return BREAK_ALLOWED;
    }

    public static function lineBreakAtIndex(codePoints:Vector.<uint>, index:uint):String {
        // LB2 Never break at the start of text.
        if (index == 0) {
            return BREAK_NOT_ALLOWED;
        }

        // LB3 Always break at the end of text.
        if (index >= codePoints.length) {
            return BREAK_MANDATORY;
        }

        var obj:Object = codePointsToCharacterClasses(codePoints);

        return _lineBreakAtIndex(codePoints, obj.breakingClasses, obj.indices, index);
    }

    /**
     *
     * @param codePoints
     * @param options
     * @return an <code>Object</code> with three fields:<ul>
     *     <li><code>indices</code>: a <code>Vector.&lt;uint&gt;</li>
     *     <li><code>breakingClasses</code>: another <code>Vector.&lt;uint&gt;</li>
     *     <li><code>forbiddenBreakpoints</code>: a <code>Vector.&lt;Boolean&gt;</li>
     * </ul>
     */
    public static function cssFormattedClasses(codePoints:Vector.<uint>, options:Options = null):Object {
        {
            if (!options) {
                options = new Options(LineBreakOptions.NORMAL, WordBreakOptions.NORMAL);
            }

            var obj:Object = codePointsToCharacterClasses(codePoints, options.lineBreak);
            var indices:Vector.<uint> = obj.indices;
            var breakingClasses:Vector.<uint> = obj.breakingClasses;
            var isLetterNumber:Vector.<Boolean> = obj.isLetterNumber;

            if (options.wordBreak == WordBreakOptions.BREAK_ALL || options.wordBreak == WordBreakOptions.BREAK_WORD) {
                // change any of [NU or AL or SA] to ID
                const CLASSTYPES_COUNT:uint = breakingClasses.length;
                for (var i:uint = 0; i < CLASSTYPES_COUNT; ++i) {
                    var brType:uint = breakingClasses[i];
                    switch (brType) {
                        case NU:
                        case AL:
                        case SA:
                            breakingClasses[i] = ID;
                            break;
                    }
                }
            }
        }

        var forbiddenBreakpoints:Vector.<Boolean> = null;
        if (options.wordBreak == WordBreakOptions.KEEP_ALL) {
            // if its a 'Letter Number Modifier' and the code-point is within the range of "CJK Unified Ideographs"
            // (i.e, the range of: [0x4E00, 0x9FFF]), then it's forbidden!
            const C:uint = isLetterNumber.length;
            forbiddenBreakpoints = new Vector.<Boolean>(C);
            var codePoint:uint;
            for (var j:uint = 0; j < C; ++j) {
                codePoint = codePoints[j];
                forbiddenBreakpoints[j] = isLetterNumber[j] && codePoint >= 0x4E00 && codePoint <= 0x9FFF;
            }
        }

        return {indices: indices, breakingClasses: breakingClasses, forbiddenBreakpoints: forbiddenBreakpoints};
    }

    /**
     * Inserts the "line breaking" symbols between the characters of the input string, primarily for debugging purposes.
     * The "line breaking" symbols have one of the following notations:
     * <ul>
     * <li> A symbol of '×' indicates a "Prohibited Break": No line break opportunity exists between two characters of the
     *      given line breaking classes, even if they are separated by one or more space characters.</li>
     * <li> A symbol of '÷' indicates a "Break Opportunity": where a "direct break" can be applied.</li>
     * <li> A symbol of '!' indicates "Mandatory Break" after which a line 'must' break.</li>
     * </ul>
     * The aforementioned line breaking symbols will be incorporated between the adjacent characters inside of the
     * input string.
     * @param str
     * @param options
     * @return
     */
    public static function inlineBreakOpportunities(str:String, options:Options = null):String {
        var codePoints:Vector.<uint> = Utils.toCodePoints(str);
        var output:String = BREAK_NOT_ALLOWED;

        var obj:Object = cssFormattedClasses(codePoints, options);

        const CODEPOINTS_COUNT:uint = codePoints.length;
        for (var i:uint = 0; i < CODEPOINTS_COUNT; ++i) {
            var codePoint:uint = codePoints[i];

            output += String.fromCharCode(codePoint) +
                    (i >= codePoints.length - 1
                                    ? BREAK_MANDATORY
                                    : _lineBreakAtIndex(codePoints, obj.breakingClasses, obj.indices, i + 1, obj.forbiddenBreakpoints)
                    );
        }

        return output;
    }


    /**
     * The lineBreaker creates an iterator that returns Breaks for a given text.
     * @param str
     * @param options
     * @return an <code>Object</code> with a <code>next()</code> function, indicating whether or not it's <code>done</code>,
     * when it's not <code>done</code>, the field of <code>breakOpportunity</code> references the available "break opportunity".
     */
    public static function lineBreaker(str:String, options:Options = null):Object {
        var codePoints:Vector.<uint> = Utils.toCodePoints(str);
        var obj:Object = cssFormattedClasses(codePoints, options);

        const LEN:uint = codePoints.length;
        var lastEnd:uint = 0;
        var nextIndex:uint = 1;

        return {
            next: function ():Object {
                if (nextIndex >= LEN) {
                    return {done: true};
                }
                var lineBreak:String;
                while ((nextIndex < LEN)
                        &&
                        ((lineBreak = _lineBreakAtIndex(
                                codePoints,
                                obj.breakingClasses,
                                obj.indices,
                                nextIndex++,
                                obj.forbiddenBreakpoints
                        )) == BREAK_NOT_ALLOWED)
                        ) {
                }

                if (lineBreak != BREAK_NOT_ALLOWED || nextIndex == LEN) {
                    var endIndex:uint = nextIndex + (nextIndex == LEN ? 0 : -1);
                    var breakOpportunity:BreakOpportunity = new BreakOpportunity(codePoints, lineBreak, lastEnd, endIndex);
                    lastEnd = endIndex;
                    return {breakOpportunity: breakOpportunity, done: false};
                }

                return {done: true};
            }
        }
    }

}
}
