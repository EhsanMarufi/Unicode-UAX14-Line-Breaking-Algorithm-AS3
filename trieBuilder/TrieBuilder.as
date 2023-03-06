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
import nibblessoft.unicode.linebreak.Trie;
import nibblessoft.unicode.linebreak.Utils;

public class TrieBuilder {

    private static const UTRIE2_SHIFT_2:uint = Trie.UTRIE2_SHIFT_2;
    private static const UTRIE2_INDEX_SHIFT:uint = Trie.UTRIE2_INDEX_SHIFT;
    private static const UTRIE2_LSCP_INDEX_2_OFFSET:uint = Trie.UTRIE2_LSCP_INDEX_2_OFFSET;
    private static const UTRIE2_DATA_BLOCK_LENGTH:uint = Trie.UTRIE2_DATA_BLOCK_LENGTH;
    private static const UTRIE2_DATA_MASK:uint = Trie.UTRIE2_DATA_MASK;
    private static const UTRIE2_SHIFT_1:uint = Trie.UTRIE2_SHIFT_1;
    private static const UTRIE2_INDEX_1_OFFSET:uint = Trie.UTRIE2_INDEX_1_OFFSET;
    private static const UTRIE2_UTF8_2B_INDEX_2_LENGTH:uint = Trie.UTRIE2_UTF8_2B_INDEX_2_LENGTH;
    private static const UTRIE2_OMITTED_BMP_INDEX_1_LENGTH:uint = Trie.UTRIE2_OMITTED_BMP_INDEX_1_LENGTH;
    private static const UTRIE2_INDEX_2_BMP_LENGTH:uint = Trie.UTRIE2_INDEX_2_BMP_LENGTH;
    private static const UTRIE2_LSCP_INDEX_2_LENGTH:uint = Trie.UTRIE2_LSCP_INDEX_2_LENGTH;
    private static const UTRIE2_INDEX_2_BLOCK_LENGTH:uint = Trie.UTRIE2_INDEX_2_BLOCK_LENGTH;
    private static const UTRIE2_INDEX_2_MASK:uint = Trie.UTRIE2_INDEX_2_MASK;
    private static const UTRIE2_SHIFT_1_2:uint = Trie.UTRIE2_SHIFT_1_2;
    /**
     * Trie2 constants, defining shift widths, index array lengths, etc.
     *
     * These are needed for the runtime macros but users can treat these as
     * implementation details and skip to the actual public API further below.
     */
    private static const UTRIE2_OPTIONS_VALUE_BITS_MASK:uint = 0x000f;

    /** Number of code points per index-1 table entry. 2048=0x800 */
    private static const UTRIE2_CP_PER_INDEX_1_ENTRY:uint = 1 << UTRIE2_SHIFT_1;

    /** The alignment size of a data block. Also the granularity for compaction. */
    private static const UTRIE2_DATA_GRANULARITY:uint = 1 << UTRIE2_INDEX_SHIFT;
    /* Fixed layout of the first part of the index array. ------------------- */
    /**
     * The BMP part of the index-2 table is fixed and linear and starts at offset 0.
     * Length=2048=0x800=0x10000>>UTRIE2_SHIFT_2.
     */
    private static const UTRIE2_INDEX_2_OFFSET:uint = 0;

    private static const UTRIE2_MAX_INDEX_1_LENGTH:uint = 0x100000 >> UTRIE2_SHIFT_1;
    /*
     * Fixed layout of the first part of the data array. -----------------------
     * Starts with 4 blocks (128=0x80 entries) for ASCII.
     */
    /**
     * The illegal-UTF-8 data block follows the ASCII block, at offset 128=0x80.
     * Used with linear access for single bytes 0..0xbf for simple error handling.
     * Length 64=0x40, not UTRIE2_DATA_BLOCK_LENGTH.
     */
    private static const UTRIE2_BAD_UTF8_DATA_OFFSET:uint = 0x80;
    /** The start of non-linear-ASCII data blocks, at offset 192=0xc0. */
    private static const UTRIE2_DATA_START_OFFSET:uint = 0xc0;
    /* Building a Trie2 ---------------------------------------------------------- */
    /*
     * These definitions are mostly needed by utrie2_builder.c, but also by
     * utrie2_get32() and utrie2_enum().
     */
    /*
     * At build time, leave a gap in the index-2 table,
     * at least as long as the maximum lengths of the 2-byte UTF-8 index-2 table
     * and the supplementary index-1 table.
     * Round up to UTRIE2_INDEX_2_BLOCK_LENGTH for proper compacting.
     */
    private static const UNEWTRIE2_INDEX_GAP_OFFSET:uint = UTRIE2_INDEX_2_BMP_LENGTH;
    private static const UNEWTRIE2_INDEX_GAP_LENGTH:uint =
            (UTRIE2_UTF8_2B_INDEX_2_LENGTH + UTRIE2_MAX_INDEX_1_LENGTH + UTRIE2_INDEX_2_MASK) &
            ~UTRIE2_INDEX_2_MASK;
    /**
     * Maximum length of the build-time index-2 array.
     * Maximum number of Unicode code points (0x110000) shifted right by UTRIE2_SHIFT_2,
     * plus the part of the index-2 table for lead surrogate code points,
     * plus the build-time index gap,
     * plus the null index-2 block.
     */
    private static const UNEWTRIE2_MAX_INDEX_2_LENGTH:uint =
            (0x110000 >> UTRIE2_SHIFT_2) +
            UTRIE2_LSCP_INDEX_2_LENGTH +
            UNEWTRIE2_INDEX_GAP_LENGTH +
            UTRIE2_INDEX_2_BLOCK_LENGTH;

    private static const UNEWTRIE2_INDEX_1_LENGTH:uint = 0x110000 >> UTRIE2_SHIFT_1;
    /**
     * Maximum length of the build-time data array.
     * One entry per 0x110000 code points, plus the illegal-UTF-8 block and the null block,
     * plus values for the 0x400 surrogate code units.
     */
    private static const UNEWTRIE2_MAX_DATA_LENGTH:uint = 0x110000 + 0x40 + 0x40 + 0x400;

    /** Start with allocation of 16k data entries. */
    private static const UNEWTRIE2_INITIAL_DATA_LENGTH:uint = 1 << 14;

    /** Grow about 8x each time. */
    private static const UNEWTRIE2_MEDIUM_DATA_LENGTH:uint = 1 << 17;

    /** The null index-2 block, following the gap in the index-2 table. */
    private static const UNEWTRIE2_INDEX_2_NULL_OFFSET:uint = UNEWTRIE2_INDEX_GAP_OFFSET + UNEWTRIE2_INDEX_GAP_LENGTH;
    /** The start of allocated index-2 blocks. */
    private static const UNEWTRIE2_INDEX_2_START_OFFSET:uint = UNEWTRIE2_INDEX_2_NULL_OFFSET + UTRIE2_INDEX_2_BLOCK_LENGTH;
    /**
     * The null data block.
     * Length 64=0x40 even if UTRIE2_DATA_BLOCK_LENGTH is smaller,
     * to work with 6-bit trail bytes from 2-byte UTF-8.
     */
    private static const UNEWTRIE2_DATA_NULL_OFFSET:uint = UTRIE2_DATA_START_OFFSET;
    /** The start of allocated data blocks. */
    private static const UNEWTRIE2_DATA_START_OFFSET:uint = UNEWTRIE2_DATA_NULL_OFFSET + 0x40;
    /**
     * The start of data blocks for U+0800 and above.
     * Below, compaction uses a block length of 64 for 2-byte UTF-8.
     * From here on, compaction uses UTRIE2_DATA_BLOCK_LENGTH.
     * Data values for 0x780 code points beyond ASCII.
     */
    private static const UNEWTRIE2_DATA_0800_OFFSET:uint = UNEWTRIE2_DATA_START_OFFSET + 0x780;

    /**
     * Maximum length of the runtime index array.
     * Limited by its own 16-bit index values, and by uint16_t UTrie2Header.indexLength.
     * (The actual maximum length is lower,
     * (0x110000>>UTRIE2_SHIFT_2)+UTRIE2_UTF8_2B_INDEX_2_LENGTH+UTRIE2_MAX_INDEX_1_LENGTH.)
     */
    private static const UTRIE2_MAX_INDEX_LENGTH:uint = 0xffff;
    /**
     * Maximum length of the runtime data array.
     * Limited by 16-bit index values that are left-shifted by UTRIE2_INDEX_SHIFT,
     * and by uint16_t UTrie2Header.shiftedDataLength.
     */
    private static const UTRIE2_MAX_DATA_LENGTH:uint = 0xffff << UTRIE2_INDEX_SHIFT;

    /**
     * Characters outside the BMP (Basic Multilingual Plane) can ONLY be encoded in UTF-16 using two 16-bit
     * "code units." They are called "surrogate pairs". A surrogate pair only represents a single character.
     * The first "code unit" of a surrogate pair is always in the range from '0xD800' to '0xDBFF', and is
     * called a high surrogate or a lead surrogate.
     * The second "code unit" of a surrogate pair is always in the range from '0xDC00' to '0xDFFF', and is
     * called a low surrogate or a trail surrogate.
     * more info: https://en.wikipedia.org/wiki/UTF-16
     */
    private static function isHighSurrogate(c:int):Boolean {
        return c >= 0xD800 && c <= 0xDBFF
    }

    /**
     * Checks whether or not the two same-sized sub-arrays have identical list of values.
     * @param a The main array to check against
     * @param s The start index of the first sub-array
     * @param t The start index of the second sub-array
     * @param length The length of the sub-array to check for
     * @return 'true' when the two same-sized sub-arrays have identical list of values; 'false' otherwise
     */
    private static function equal_int(a:Vector.<uint>, s:int, t:int, length:int):Boolean {
        for (var i:int = 0; i < length; ++i) {
            if (a[s + i] != a[t + i]) {
                return false;
            }
        }
        return true;
    }


    // ------------------------------------------
    // Object specific fields

    private var _index1:Vector.<uint>;
    private var _index2:Vector.<uint>;

    /**
     * Multi-purpose per-data-block table.
     *
     * Before compacting:
     * Per-data-block reference counters/free-block list.
     *  0: unused
     * >0: reference counter (number of index-2 entries pointing here)
     * <0: next free data block in free-block list
     *
     * While compacting:
     * Map of adjusted indexes, used in compactData() and compactIndex2().
     * Maps from original indexes to new ones.
     */
    private var _map:Vector.<uint>;

    private var _data:Vector.<uint>;
    private var _dataCapacity:int;
    private var _initialValue:int;
    private var _errorValue:int;
    private var _highStart:int;
    private var _dataNullOffset:int;
    private var _dataLength:int;
    private var _index2NullOffset:int;
    private var _index2Length:int;
    private var _firstFreeBlock:int;
    private var _isCompacted:Boolean;

    public function TrieBuilder(initialValue:int = 0, errorValue:int = 0) {
        _initialValue = initialValue;
        _errorValue = errorValue;
        _highStart = 0x110000;
        _data = new Vector.<uint>(UNEWTRIE2_INITIAL_DATA_LENGTH);
        _dataCapacity = UNEWTRIE2_INITIAL_DATA_LENGTH;

        /* no free block in the list */
        _firstFreeBlock = 0;

        _isCompacted = false;

        _index1 = new Vector.<uint>(UNEWTRIE2_INDEX_1_LENGTH);
        _index2 = new Vector.<uint>(UNEWTRIE2_MAX_INDEX_2_LENGTH);


        _map = new Vector.<uint>(UNEWTRIE2_MAX_DATA_LENGTH >> UTRIE2_SHIFT_2);

        /* preallocate and reset
         * - ASCII
         * - the bad-UTF-8-data block
         * - the null data block
         */
        var i:int, j:int;
        for (i = 0; i < 0x80; ++i) {
            _data[i] = initialValue;
        }
        for (; i < 0xc0; ++i) {
            _data[i] = errorValue;
        }
        for (i = UNEWTRIE2_DATA_NULL_OFFSET; i < UNEWTRIE2_DATA_START_OFFSET; ++i) {
            _data[i] = initialValue;
        }
        _dataNullOffset = UNEWTRIE2_DATA_NULL_OFFSET;
        _dataLength = UNEWTRIE2_DATA_START_OFFSET;

        // set the index-2 indexes for the 2=0x80>>UTRIE2_SHIFT_2 ASCII data blocks
        for (i = 0, j = 0; j < 0x80; ++i, j += UTRIE2_DATA_BLOCK_LENGTH) {
            _index2[i] = j;
            _map[i] = 1;
        }

        // reference counts for the bad-UTF-8-data block
        for (; j < 0xc0; ++i, j += UTRIE2_DATA_BLOCK_LENGTH) {
            _map[i] = 0;
        }

        /* Reference counts for the null data block: all blocks except for the ASCII blocks.
         * Plus 1 so that we don't drop this block during compaction.
         * Plus as many as needed for lead surrogate code points.
         */
        /* i==newTrie->dataNullOffset */
        _map[i++] =
                (0x110000 >> UTRIE2_SHIFT_2) -
                (0x80 >> UTRIE2_SHIFT_2) +
                1 +
                UTRIE2_LSCP_INDEX_2_LENGTH;
        j += UTRIE2_DATA_BLOCK_LENGTH;
        for (; j < UNEWTRIE2_DATA_START_OFFSET; ++i, j += UTRIE2_DATA_BLOCK_LENGTH) {
            _map[i] = 0;
        }

        // set the remaining indexes in the BMP index-2 block, to the null data block
        for (i = 0x80 >> UTRIE2_SHIFT_2; i < UTRIE2_INDEX_2_BMP_LENGTH; ++i) {
            _index2[i] = UNEWTRIE2_DATA_NULL_OFFSET;
        }

        // Fill the index gap with impossible values so that compaction
        // does not overlap other index-2 blocks with the gap.
        for (i = 0; i < UNEWTRIE2_INDEX_GAP_LENGTH; ++i) {
            _index2[UNEWTRIE2_INDEX_GAP_OFFSET + i] = -1;
        }

        // set the indexes in the null index-2 block
        for (i = 0; i < UTRIE2_INDEX_2_BLOCK_LENGTH; ++i) {
            _index2[UNEWTRIE2_INDEX_2_NULL_OFFSET + i] = UNEWTRIE2_DATA_NULL_OFFSET;
        }

        _index2NullOffset = UNEWTRIE2_INDEX_2_NULL_OFFSET;
        _index2Length = UNEWTRIE2_INDEX_2_START_OFFSET;

        // set the index-1 indexes for the linear index-2 block
        for (
                i = 0, j = 0;
                i < UTRIE2_OMITTED_BMP_INDEX_1_LENGTH;
                ++i, j += UTRIE2_INDEX_2_BLOCK_LENGTH
        ) {
            _index1[i] = j;
        }

        // set the remaining index-1 indexes to the null index-2 block
        for (; i < UNEWTRIE2_INDEX_1_LENGTH; ++i) {
            _index1[i] = UNEWTRIE2_INDEX_2_NULL_OFFSET;
        }

        // Preallocate and reset data for U+0080..U+07FF, for 2-byte UTF-8 which will be compacted in 64-blocks;
        // even if UTRIE2_DATA_BLOCK_LENGTH is smaller.
        for (i = 0x80; i < 0x800; i += UTRIE2_DATA_BLOCK_LENGTH) {
            setCodepointValue(i, initialValue);
        }
    }

    /**
     * Set a value for a code point.
     *
     * @param codePoint the code point
     * @param value the value
     */
    public function setCodepointValue(codePoint:int, value:int):TrieBuilder {
        if (codePoint < 0 || codePoint > 0x10ffff) {
            throw new Error('Invalid code point.');
        }

        _setCodepointValue(codePoint, true, value);
        return this;
    }

    /**
     * Set a value in a range of code points [start..end].
     * All code points c with start<=c<=end will get the value if
     * overwrite is TRUE or if the old value is the initial value.
     *
     * @param start the first code point to get the value
     * @param end the last code point to get the value (inclusive)
     * @param value the value
     * @param overwrite flag for whether old non-initial values are to be overwritten
     */
    public function setRange(start:int, end:int, value:int, overwrite:Boolean):TrieBuilder {
        /*
         * repeat value in [start..end]
         * mark index values for repeat-data blocks by setting bit 31 of the index values
         * fill around existing values if any, if(overwrite)
         */
        var block:int, rest:int, repeatBlock:int;
        if (start > 0x10FFFF || start < 0 || end > 0x10FFFF || end < 0 || start > end) {
            throw new Error('Invalid code point range.');
        }

        if (!overwrite && value == _initialValue) {
            // nothing to do
            return this;
        }

        if (_isCompacted) {
            throw new Error('Trie was already compacted');
        }

        var limit:int = end + 1;
        if ((start & UTRIE2_DATA_MASK) != 0) {
            // set partial block at [start..following block boundary[
            block = getDataBlock(start, true);
            var nextStart:int = (start + UTRIE2_DATA_BLOCK_LENGTH) & ~UTRIE2_DATA_MASK;
            if (nextStart <= limit) {
                fillBlock(
                        block,
                        start & UTRIE2_DATA_MASK,
                        UTRIE2_DATA_BLOCK_LENGTH,
                        value,
                        _initialValue,
                        overwrite
                );
                start = nextStart;
            } else {
                fillBlock(
                        block,
                        start & UTRIE2_DATA_MASK,
                        limit & UTRIE2_DATA_MASK,
                        value,
                        _initialValue,
                        overwrite
                );
                return this;
            }
        }

        // number of positions in the last, partial block
        rest = limit & UTRIE2_DATA_MASK;

        // round down limit to a block boundary
        limit &= ~UTRIE2_DATA_MASK;

        // iterate over all-value blocks
        if (value == _initialValue) {
            repeatBlock = _dataNullOffset;
        } else {
            repeatBlock = -1;
        }

        while (start < limit) {
            var i2:int;
            var setRepeatBlock:Boolean = false;

            if (value == _initialValue && isInNullBlock(start, true)) {
                start += UTRIE2_DATA_BLOCK_LENGTH;
                // nothing to do
                continue;
            }

            // get index value
            i2 = this.getIndex2Block(start, true);
            i2 += (start >> UTRIE2_SHIFT_2) & UTRIE2_INDEX_2_MASK;
            block = _index2[i2];

            if (this.isWritableBlock(block)) {
                // already allocated
                if (overwrite && block >= UNEWTRIE2_DATA_0800_OFFSET) {
                    // We overwrite all values, and it's not a protected (ASCII-linear or 2-byte UTF-8) block:
                    // replace with the repeatBlock.
                    setRepeatBlock = true;
                } else {
                    // !overwrite, or protected block: just write the values into this block
                    this.fillBlock(
                            block,
                            0,
                            UTRIE2_DATA_BLOCK_LENGTH,
                            value,
                            _initialValue,
                            overwrite
                    );
                }
            } else if (_data[block] != value && (overwrite || block == _dataNullOffset)) {
                /*
                 * Set the repeatBlock instead of the null block or previous repeat block:
                 *
                 * If !isWritableBlock() then all entries in the block have the same value
                 * because it's the null block or a range block (the repeatBlock from a previous
                 * call to utrie2_setRange32()).
                 * No other blocks are used multiple times before compacting.
                 *
                 * The null block is the only non-writable block with the initialValue because
                 * of the repeatBlock initialization above. (If value==initialValue, then
                 * the repeatBlock will be the null data block.)
                 *
                 * We set our repeatBlock if the desired value differs from the block's value,
                 * and if we overwrite any data or if the data is all initial values
                 * (which is the same as the block being the null block, see above).
                 */
                setRepeatBlock = true;
            }

            if (setRepeatBlock) {
                if (repeatBlock >= 0) {
                    setIndex2Entry(i2, repeatBlock);
                } else {
                    // create and set and fill the repeatBlock
                    repeatBlock = getDataBlock(start, true);
                    writeBlock(repeatBlock, value);
                }
            }

            start += UTRIE2_DATA_BLOCK_LENGTH;
        }

        if (rest > 0) {
            // set partial block at [last block boundary..limit[
            block = getDataBlock(start, true);
            fillBlock(block, 0, rest, value, _initialValue, overwrite);
        }

        return this;
    }

    /**
     * Get the value for a code point as stored in the Trie2.
     *
     * @param codePoint the code point
     * @return the value
     */
    public function getCodepointValue(codePoint:int):int {
        if (codePoint < 0 || codePoint > 0x10FFFF) {
            return _errorValue;
        } else {
            return _getCodepointValue(codePoint, true);
        }
    }

    /**
     * Get the value for a code point as stored in the Trie2.
     * @param codePoint
     * @param fromLSCP from "Lead Surrogate Code-Point"
     * @return
     */
    private function _getCodepointValue(codePoint:int, fromLSCP:Boolean):int {
        var i2:int;

        if (codePoint >= _highStart && (!(codePoint >= 0xD800 && codePoint < 0xDC00) || fromLSCP)) {
            return _data[_dataLength - UTRIE2_DATA_GRANULARITY];
        }

        if (codePoint >= 0xD800 && codePoint < 0xDC00 && fromLSCP) {
            i2 = UTRIE2_LSCP_INDEX_2_OFFSET - (0xD800 >> UTRIE2_SHIFT_2) + (codePoint >> UTRIE2_SHIFT_2);
        } else {
            i2 = _index1[codePoint >> UTRIE2_SHIFT_1] + ((codePoint >> UTRIE2_SHIFT_2) & UTRIE2_INDEX_2_MASK);
        }

        const block:int = _index2[i2];
        return _data[block + (codePoint & UTRIE2_DATA_MASK)];
    }

    /**
     * The <code>freeze()</code> method will not only make the set immutable
     * @return
     */
    public function freeze():Trie {
        var i:int;
        var allIndexesLength:int;

        // >0 if the data is moved to the end of the index array
        var dataMove:int = 0;

        // compact if necessary
        if (!_isCompacted) {
            compactTrie();
        }

        if (_highStart <= 0x10000) {
            allIndexesLength = UTRIE2_INDEX_1_OFFSET;
        } else {
            allIndexesLength = _index2Length;
        }

        // are the indexLength and dataLength within limits?
        if (
                // for unshifted indexLength
                allIndexesLength > UTRIE2_MAX_INDEX_LENGTH ||
                // for unshifted dataNullOffset
                dataMove + _dataNullOffset > 0xffff ||
                // for unshifted 2-byte UTF-8 index-2 values
                dataMove + UNEWTRIE2_DATA_0800_OFFSET > 0xffff ||
                // for shiftedDataLength
                dataMove + _dataLength > UTRIE2_MAX_DATA_LENGTH
        ) {
            throw new Error('Trie data is too large.');
        }

        var index:Vector.<uint> = new Vector.<uint>(allIndexesLength);

        // write the index-2 array values shifted right by UTRIE2_INDEX_SHIFT, after adding dataMove
        var destIdx:int = 0;
        for (i = 0; i < UTRIE2_INDEX_2_BMP_LENGTH; i++) {
            index[destIdx++] = (_index2[i] + dataMove) >> UTRIE2_INDEX_SHIFT;
        }

        // write UTF-8 2-byte index-2 values, not right-shifted
        for (i = 0; i < 0xC2 - 0xC0; ++i) {
            // C0..C1
            index[destIdx++] = dataMove + UTRIE2_BAD_UTF8_DATA_OFFSET;
        }
        for (; i < 0xe0 - 0xc0; ++i) {
            // C2..DF
            index[destIdx++] = dataMove + _index2[i << (6 - UTRIE2_SHIFT_2)];
        }

        if (_highStart > 0x10000) {
            var index1Length:int = (_highStart - 0x10000) >> UTRIE2_SHIFT_1;
            var index2Offset:int =
                    UTRIE2_INDEX_2_BMP_LENGTH + UTRIE2_UTF8_2B_INDEX_2_LENGTH + index1Length;

            // write 16-bit index-1 values for supplementary code points
            //p=(uint32_t *)newTrie->index1+UTRIE2_OMITTED_BMP_INDEX_1_LENGTH;
            for (i = 0; i < index1Length; i++) {
                //*dest16++=(uint16_t)(UTRIE2_INDEX_2_OFFSET + *p++);
                index[destIdx++] =
                        UTRIE2_INDEX_2_OFFSET + _index1[i + UTRIE2_OMITTED_BMP_INDEX_1_LENGTH];
            }

            // write the index-2 array values for supplementary code points, shifted right by UTRIE2_INDEX_SHIFT,
            // after adding dataMove
            for (i = 0; i < _index2Length - index2Offset; i++) {
                index[destIdx++] = (dataMove + _index2[index2Offset + i]) >> UTRIE2_INDEX_SHIFT;
            }
        }

        // write 32-bit data values
        var data:Vector.<uint> = new Vector.<uint>(_dataLength);
        for (i = 0; i < _dataLength; i++) {
            data[i] = _data[i];
        }
        return new Trie(
                _initialValue,
                _errorValue,
                _highStart,
                dataMove + _dataLength - UTRIE2_DATA_GRANULARITY,
                index,
                data
        );
    }

    /**
     * Find the start of the last range in the trie by enumerating backward.
     * Indexes for supplementary code points higher than this will be omitted.
     */
    public function findHighStart(highValue:int):int {
        var value:int;
        var i2:int, j:int, i2Block:int, prevI2Block:int, block:int, prevBlock:int;

        // set variables for previous range
        if (highValue == _initialValue) {
            prevI2Block = _index2NullOffset;
            prevBlock = _dataNullOffset;
        } else {
            prevI2Block = -1;
            prevBlock = -1;
        }
        var prev:int = 0x110000;

        // enumerate index-2 blocks
        var i1:int = UNEWTRIE2_INDEX_1_LENGTH;
        var c:int = prev;
        while (c > 0) {
            i2Block = _index1[--i1];
            if (i2Block == prevI2Block) {
                // the index-2 block is the same as the previous one, and filled with highValue
                c -= UTRIE2_CP_PER_INDEX_1_ENTRY;
                continue;
            }
            prevI2Block = i2Block;
            if (i2Block == _index2NullOffset) {
                // this is the null index-2 block
                if (highValue !== _initialValue) {
                    return c;
                }
                c -= UTRIE2_CP_PER_INDEX_1_ENTRY;
            } else {
                // enumerate data blocks for one index-2 block
                for (i2 = UTRIE2_INDEX_2_BLOCK_LENGTH; i2 > 0;) {
                    block = _index2[i2Block + --i2];
                    if (block === prevBlock) {
                        // the block is the same as the previous one, and filled with highValue
                        c -= UTRIE2_DATA_BLOCK_LENGTH;
                        continue;
                    }
                    prevBlock = block;
                    if (block == _dataNullOffset) {
                        // this is the null data block
                        if (highValue != _initialValue) {
                            return c;
                        }
                        c -= UTRIE2_DATA_BLOCK_LENGTH;
                    } else {
                        for (j = UTRIE2_DATA_BLOCK_LENGTH; j > 0;) {
                            value = _data[block + --j];
                            if (value != highValue) {
                                return c;
                            }
                            --c;
                        }
                    }
                }
            }
        }

        // deliver last range
        return 0;
    }

    /**
     * Compact a build-time trie.
     *
     * The compaction
     * - removes blocks that are identical with earlier ones
     * - overlaps adjacent blocks as much as possible (if overlap==TRUE)
     * - moves blocks in steps of the data granularity
     * - moves and overlaps blocks that overlap with multiple values in the overlap region
     *
     * It does not
     * - try to move and overlap blocks that are not already adjacent
     */
    private function compactData():void {
        var start:int, movedStart:int;
        var blockLength:int, overlap:int;
        var i:int, mapIndex:int, blockCount:int;

        // do not compact linear-ASCII data
        var newStart:int = UTRIE2_DATA_START_OFFSET;
        for (start = 0, i = 0; start < newStart; start += UTRIE2_DATA_BLOCK_LENGTH, ++i) {
            _map[i] = start;
        }

        // Start with a block length of 64 for 2-byte UTF-8, then switch to UTRIE2_DATA_BLOCK_LENGTH.
        blockLength = 64;
        blockCount = blockLength >> UTRIE2_SHIFT_2;
        for (start = newStart; start < _dataLength;) {
            // start: index of first entry of current block
            // newStart: index where the current block is to be moved
            //          (right after current end of already-compacted data)
            if (start == UNEWTRIE2_DATA_0800_OFFSET) {
                blockLength = UTRIE2_DATA_BLOCK_LENGTH;
                blockCount = 1;
            }

            // skip blocks that are not used
            if (_map[start >> UTRIE2_SHIFT_2] <= 0) {
                // advance start to the next block
                start += blockLength;
                // leave newStart with the previous block!
                continue;
            }

            // search for an identical block
            movedStart = this.findSameDataBlock(newStart, start, blockLength);
            if (movedStart >= 0) {
                // found an identical block, set the other block's index value for the current block
                for (i = blockCount, mapIndex = start >> UTRIE2_SHIFT_2; i > 0; --i) {
                    _map[mapIndex++] = movedStart;
                    movedStart += UTRIE2_DATA_BLOCK_LENGTH;
                }

                // advance start to the next block
                start += blockLength;
                // leave newStart with the previous block!
                continue;
            }

            // see if the beginning of this block can be overlapped with the end of the previous block
            // look for maximum overlap (modulo granularity) with the previous, adjacent block
            for (
                    overlap = blockLength - UTRIE2_DATA_GRANULARITY;
                    overlap > 0 && !equal_int(_data, newStart - overlap, start, overlap);
                    overlap -= UTRIE2_DATA_GRANULARITY
            ) {
            }

            if (overlap > 0 || newStart < start) {
                // some overlap, or just move the whole block
                movedStart = newStart - overlap;
                for (i = blockCount, mapIndex = start >> UTRIE2_SHIFT_2; i > 0; --i) {
                    _map[mapIndex++] = movedStart;
                    movedStart += UTRIE2_DATA_BLOCK_LENGTH;
                }
                // move the non-overlapping indexes to their new positions
                start += overlap;
                for (i = blockLength - overlap; i > 0; --i) {
                    _data[newStart++] = _data[start++];
                }
            } else {
                // no overlap && newStart==start
                for (
                        i = blockCount, mapIndex = start >> UTRIE2_SHIFT_2;
                        i > 0;
                        --i
                ) {
                    _map[mapIndex++] = start;
                    start += UTRIE2_DATA_BLOCK_LENGTH;
                }
                newStart = start;
            }
        }

        // now adjust the index-2 table
        for (i = 0; i < _index2Length; ++i) {
            if (i == UNEWTRIE2_INDEX_GAP_OFFSET) {
                // Gap indexes are invalid (-1). Skip over the gap.
                i += UNEWTRIE2_INDEX_GAP_LENGTH;
            }
            _index2[i] = _map[_index2[i] >> UTRIE2_SHIFT_2];
        }
        _dataNullOffset = _map[_dataNullOffset >> UTRIE2_SHIFT_2];
        // ensure dataLength alignment
        while ((newStart & (UTRIE2_DATA_GRANULARITY - 1)) !== 0) {
            _data[newStart++] = _initialValue;
        }

        _dataLength = newStart;
    }

    private function findSameDataBlock(dataLength:int, otherBlock:int, blockLength:int):int {
        var block:int = 0;
        // ensure that we do not even partially get past dataLength
        dataLength -= blockLength;
        for (; block <= dataLength; block += UTRIE2_DATA_GRANULARITY) {
            if (equal_int(_data, block, otherBlock, blockLength)) {
                return block;
            }
        }
        return -1;
    }

    private function compactTrie():void {
        var highValue:int = getCodepointValue(0x10FFFF);

        // find highStart and round it up
        var localHighStart:int = findHighStart(highValue);
        localHighStart =
                (localHighStart + (UTRIE2_CP_PER_INDEX_1_ENTRY - 1)) &
                ~(UTRIE2_CP_PER_INDEX_1_ENTRY - 1);
        if (localHighStart == 0x110000) {
            highValue = _errorValue;
        }

        // Set trie->highStart only after utrie2_get32(trie, highStart).
        // Otherwise utrie2_get32(trie, highStart) would try to read the highValue.
        _highStart = localHighStart;

        if (_highStart < 0x110000) {
            // Blank out [highStart..10FFFF] to release associated data blocks.
            const suppHighStart:int = _highStart <= 0x10000 ? 0x10000 : _highStart;
            setRange(suppHighStart, 0x10FFFF, _initialValue, true);
        }

        compactData();
        if (_highStart > 0x10000) {
            compactIndex2();
        }

        // Store the highValue in the data array and round up the dataLength.
        // Must be done after compactData() because that assumes that dataLength is a multiple of UTRIE2_DATA_BLOCK_LENGTH.
        _data[_dataLength++] = highValue;
        while ((_dataLength & (UTRIE2_DATA_GRANULARITY - 1)) !== 0) {
            _data[_dataLength++] = _initialValue;
        }
        _isCompacted = true;
    }

    private function compactIndex2():void {
        var i:int, start:int, movedStart:int, overlap:int;

        // do not compact linear-BMP index-2 blocks
        var newStart:int = UTRIE2_INDEX_2_BMP_LENGTH;
        for (start = 0, i = 0; start < newStart; start += UTRIE2_INDEX_2_BLOCK_LENGTH, ++i) {
            _map[i] = start;
        }

        // Reduce the index table gap to what will be needed at runtime.
        newStart += UTRIE2_UTF8_2B_INDEX_2_LENGTH + ((_highStart - 0x10000) >> UTRIE2_SHIFT_1);
        for (start = UNEWTRIE2_INDEX_2_NULL_OFFSET; start < _index2Length;) {
            /*
             * start: index of first entry of current block
             * newStart: index where the current block is to be moved
             *           (right after current end of already-compacted data)
             */
            // search for an identical block
            if ((movedStart = findSameIndex2Block(newStart, start)) >= 0) {
                // found an identical block, set the other block's index value for the current block
                _map[start >> UTRIE2_SHIFT_1_2] = movedStart;

                // advance start to the next block
                start += UTRIE2_INDEX_2_BLOCK_LENGTH;

                // leave newStart with the previous block!
                continue;
            }

            // see if the beginning of this block can be overlapped with the end of the previous block
            // look for maximum overlap with the previous, adjacent block
            for (
                    overlap = UTRIE2_INDEX_2_BLOCK_LENGTH - 1;
                    overlap > 0 && !equal_int(_index2, newStart - overlap, start, overlap);
                    --overlap
            ) {
            }

            if (overlap > 0 || newStart < start) {
                // some overlap, or just move the whole block
                _map[start >> UTRIE2_SHIFT_1_2] = newStart - overlap;
                // move the non-overlapping indexes to their new positions
                start += overlap;
                for (i = UTRIE2_INDEX_2_BLOCK_LENGTH - overlap; i > 0; --i) {
                    _index2[newStart++] = _index2[start++];
                }
            } else {
                // no overlap && newStart==start
                _map[start >> UTRIE2_SHIFT_1_2] = start;
                start += UTRIE2_INDEX_2_BLOCK_LENGTH;
                newStart = start;
            }
        }

        // now adjust the index-1 table
        for (i = 0; i < UNEWTRIE2_INDEX_1_LENGTH; ++i) {
            _index1[i] = _map[_index1[i] >> UTRIE2_SHIFT_1_2];
        }
        _index2NullOffset = _map[_index2NullOffset >> UTRIE2_SHIFT_1_2];
        /*
         * Ensure data table alignment:
         * Needs to be granularity-aligned for 16-bit trie
         * (so that dataMove will be down-shiftable),
         * and 2-aligned for uint32_t data.
         */
        while ((newStart & ((UTRIE2_DATA_GRANULARITY - 1) | 1)) !== 0) {
            // Arbitrary value: 0x3fffc not possible for real data.
            _index2[newStart++] = 0x0000ffff << UTRIE2_INDEX_SHIFT;
        }

        _index2Length = newStart;
    }

    private function findSameIndex2Block(index2Length:int, otherBlock:int):int {
        // ensure that we do not even partially get past index2Length
        index2Length -= UTRIE2_INDEX_2_BLOCK_LENGTH;
        for (var block:int = 0; block <= index2Length; ++block) {
            if (equal_int(_index2, block, otherBlock, UTRIE2_INDEX_2_BLOCK_LENGTH)) {
                return block;
            }
        }
        return -1;
    }

    private function _setCodepointValue(codePoint:int, forLSCP:Boolean, value:int):TrieBuilder {
        if (_isCompacted) {
            throw new Error('Trie was already compacted');
        }
        const block:int = getDataBlock(codePoint, forLSCP);
        _data[block + (codePoint & UTRIE2_DATA_MASK)] = value;
        return this;
    }

    private function writeBlock(block:int, value:int):void {
        const limit:int = block + UTRIE2_DATA_BLOCK_LENGTH;
        while (block < limit) {
            _data[block++] = value;
        }
    }

    private function isInNullBlock(codePoint:int, forLSCP:Boolean):Boolean {
        const i2:int =
                isHighSurrogate(codePoint) && forLSCP
                        ? UTRIE2_LSCP_INDEX_2_OFFSET - (0xD800 >> UTRIE2_SHIFT_2) + (codePoint >> UTRIE2_SHIFT_2)
                        : _index1[codePoint >> UTRIE2_SHIFT_1] + ((codePoint >> UTRIE2_SHIFT_2) & UTRIE2_INDEX_2_MASK);
        const block:int = _index2[i2];
        return block == _dataNullOffset;
    }

    public function fillBlock(
            block:int,
            start:int,
            limit:int,
            value:int,
            initialValue:int,
            overwrite:Boolean
    ):void {
        var i:int;
        const pLimit:int = block + limit;
        if (overwrite) {
            for (i = block + start; i < pLimit; i++) {
                _data[i] = value;
            }
        } else {
            for (i = block + start; i < pLimit; i++) {
                if (_data[i] === initialValue) {
                    _data[i] = value;
                }
            }
        }
    }

    private function setIndex2Entry(i2:int, block:int):void {
        ++_map[block >> UTRIE2_SHIFT_2];

        // increment first, in case block==oldBlock!
        const oldBlock:int = _index2[i2];
        if (0 == --_map[oldBlock >> UTRIE2_SHIFT_2]) {
            this.releaseDataBlock(oldBlock);
        }
        _index2[i2] = block;
    }

    private function releaseDataBlock(block:int):void {
        // put this block at the front of the free-block chain
        _map[block >> UTRIE2_SHIFT_2] = -_firstFreeBlock;
        _firstFreeBlock = block;
    }

    private function getDataBlock(codePoint:int, forLSCP:Boolean):int {
        var i2:int = this.getIndex2Block(codePoint, forLSCP);

        i2 += (codePoint >> UTRIE2_SHIFT_2) & UTRIE2_INDEX_2_MASK;
        const oldBlock:int = _index2[i2];
        if (isWritableBlock(oldBlock)) {
            return oldBlock;
        }

        // allocate a new data block
        const newBlock:int = allocDataBlock(oldBlock);
        setIndex2Entry(i2, newBlock);

        return newBlock;
    }

    private function isWritableBlock(block:int):Boolean {
        return block != _dataNullOffset && 1 == _map[block >> UTRIE2_SHIFT_2];
    }

    private function getIndex2Block(codePoint:int, forLSCP:Boolean):int {
        if (codePoint >= 0xD800 && codePoint < 0xDC00 && forLSCP) {
            return UTRIE2_LSCP_INDEX_2_OFFSET;
        }
        const i1:int = codePoint >> UTRIE2_SHIFT_1;
        var i2:int = _index1[i1];
        if (i2 === _index2NullOffset) {
            i2 = this.allocIndex2Block();
            _index1[i1] = i2;
        }
        return i2;
    }

    private function allocDataBlock(copyBlock:int):int {
        var newBlock:int;

        if (_firstFreeBlock !== 0) {
            // get the first free block
            newBlock = _firstFreeBlock;
            _firstFreeBlock = -_map[newBlock >> UTRIE2_SHIFT_2];
        } else {
            // get a new block from the high end
            newBlock = _dataLength;
            const newTop:int = newBlock + UTRIE2_DATA_BLOCK_LENGTH;
            if (newTop > _dataCapacity) {
                var capacity:int;
                // out of memory in the data array
                if (_dataCapacity < UNEWTRIE2_MEDIUM_DATA_LENGTH) {
                    capacity = UNEWTRIE2_MEDIUM_DATA_LENGTH;
                } else if (_dataCapacity < UNEWTRIE2_MAX_DATA_LENGTH) {
                    capacity = UNEWTRIE2_MAX_DATA_LENGTH;
                } else {
                    // Should never occur.
                    // Either UNEWTRIE2_MAX_DATA_LENGTH is incorrect, or the code writes more values than should be possible.
                    throw new Error('Internal error in Trie creation.');
                }

                const newData:Vector.<uint> = new Vector.<uint>(capacity);
                vectorSet(newData, _data.slice(0, _dataLength));
                _data = newData;
                _dataCapacity = capacity;
            }
            _dataLength = newTop;
        }

        vectorSet(
                _data,
                _data.slice(copyBlock, copyBlock + UTRIE2_DATA_BLOCK_LENGTH),
                newBlock
        );
        _map[newBlock >> UTRIE2_SHIFT_2] = 0;
        return newBlock;
    }

    private function allocIndex2Block():int {
        const newBlock:int = _index2Length;
        const newTop:int = newBlock + UTRIE2_INDEX_2_BLOCK_LENGTH;
        if (newTop > _index2.length) {
            // Should never occur.
            // Either UTRIE2_MAX_BUILD_TIME_INDEX_LENGTH is incorrect, or the code writes more values than should be possible.
            throw new Error('Internal error in Trie creation.');
        }
        _index2Length = newTop;
        vectorSet(
                _index2,
                _index2.slice(
                        _index2NullOffset,
                        _index2NullOffset + UTRIE2_INDEX_2_BLOCK_LENGTH
                ),
                newBlock
        );
        return newBlock;
    }

    /**
     * An equivalent implementation to the
     * "<a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypedArray/set">TypedArray.set()</a>"
     * method in Javascript. It reads all the input values from the specified source array and stores them in the target array.
     * @param target The target vector to copy the values to.
     * @param source The array from which to copy values. All values from the source array are copied into the target array,
     *        unless the length of the source array plus the offset exceeds the length of the target array, in which case an
     *        exception is thrown.
     * @param offset The offset into the target array at which to begin writing values from the source array. If you omit
     *        this value, 0 is assumed (that is, the source array will overwrite values in the target array starting at index 0).
     */
    private static function vectorSet(target:Vector.<uint>, source:Vector.<uint>, offset:uint = 0):void {
        const TARGET_LEN:uint = target.length;
        const SOURCE_LEN:uint = source.length;

        if (SOURCE_LEN + offset > TARGET_LEN)
            throw new Error("Source is too large");

        for (var i:uint = 0; i < SOURCE_LEN; ++i) {
            target[i + offset] = source[i];
        }
    }


    public static function serializeBase64(trie:Trie):String {
        const index:Vector.<uint> = trie.index;
        const data:Vector.<uint> = trie.data;

        const indexBytesCount:uint = index.length * 4;
        const dataBytesCount:uint = data.length * 4;
        const headerLength:uint = 4 * 6;

        const bufferLength:uint = headerLength + indexBytesCount + dataBytesCount;
        var len:uint = Math.ceil(bufferLength / 4) * 4;
        //const buffer:Vector.<uint> = new Vector.<uint>(len);
        const view32:Vector.<uint> = new Vector.<uint>(len);
        //const view16:Vector.<uint> = new Vector.<uint>(len);

        view32[0] = trie.initialValue;
        view32[1] = trie.errorValue;
        view32[2] = trie.highStart;
        view32[3] = trie.highValueIndex;
        view32[4] = indexBytesCount;
        view32[5] = 4; // data.BYTES_PER_ELEMENT

        vectorSet(view32, index, 0/*headerLength / 2*/);
        vectorSet(
                view32,
                data,
                6 + index.length
                //Math.ceil((headerLength + indexBytesCount) / 4)
        );

        return Utils.encode(view32);
    }
}
}