package nibblessoft.unicode.linebreak {

public class Trie {

    /** Shift size for getting the index-2 table offset. */
    public static const UTRIE2_SHIFT_2:uint = 5;

    /** Shift size for getting the index-1 table offset. */
    public static const UTRIE2_SHIFT_1:uint = 6 + 5;

    /**
     * Shift size for shifting left the index array values.
     * Increases possible data size with 16-bit index values at the cost
     * of compactability.
     * This requires data blocks to be aligned by UTRIE2_DATA_GRANULARITY.
     */
    public static const UTRIE2_INDEX_SHIFT:uint = 2;

    /**
     * Difference between the two shift sizes,
     * for getting an index-1 offset from an index-2 offset. 6=11-5
     */
    public static const UTRIE2_SHIFT_1_2:uint = UTRIE2_SHIFT_1 - UTRIE2_SHIFT_2;

    /**
     * The part of the index-2 table for U+D800..U+DBFF stores values for
     * lead surrogate code _units_ not code _points_.
     * Values for lead surrogate code _points_ are indexed with this portion of the table.
     * Length=32=0x20=0x400>>UTRIE2_SHIFT_2. (There are 1024=0x400 lead surrogates.)
     */
    public static const UTRIE2_LSCP_INDEX_2_OFFSET:uint = 0x10000 >> UTRIE2_SHIFT_2;

    /** Number of entries in a data block. 32=0x20 */
    public static const UTRIE2_DATA_BLOCK_LENGTH:uint = 1 << UTRIE2_SHIFT_2;
    /** Mask for getting the lower bits for the in-data-block offset. */
    public static const UTRIE2_DATA_MASK:uint = UTRIE2_DATA_BLOCK_LENGTH - 1;

    public static const UTRIE2_LSCP_INDEX_2_LENGTH:uint = 0x400 >> UTRIE2_SHIFT_2;
    /** Count the lengths of both BMP pieces. 2080=0x820 */
    public static const UTRIE2_INDEX_2_BMP_LENGTH:uint = UTRIE2_LSCP_INDEX_2_OFFSET + UTRIE2_LSCP_INDEX_2_LENGTH;
    /**
     * The 2-byte UTF-8 version of the index-2 table follows at offset 2080=0x820.
     * Length 32=0x20 for lead bytes C0..DF, regardless of UTRIE2_SHIFT_2.
     */
    public static const UTRIE2_UTF8_2B_INDEX_2_OFFSET:uint = UTRIE2_INDEX_2_BMP_LENGTH;
    public static const UTRIE2_UTF8_2B_INDEX_2_LENGTH:uint =
            0x800 >> 6;
    /* U+0800 is the first code point after 2-byte UTF-8 */
    /**
     * The index-1 table, only used for supplementary code points, at offset 2112=0x840.
     * Variable length, for code points up to highStart, where the last single-value range starts.
     * Maximum length 512=0x200=0x100000>>UTRIE2_SHIFT_1.
     * (For 0x100000 supplementary code points U+10000..U+10ffff.)
     *
     * The part of the index-2 table for supplementary code points starts
     * after this index-1 table.
     *
     * Both the index-1 table and the following part of the index-2 table
     * are omitted completely if there is only BMP data.
     */
    public static const UTRIE2_INDEX_1_OFFSET:uint = UTRIE2_UTF8_2B_INDEX_2_OFFSET + UTRIE2_UTF8_2B_INDEX_2_LENGTH;

    /**
     * Number of index-1 entries for the BMP. 32=0x20
     * This part of the index-1 table is omitted from the serialized form.
     */
    public static const UTRIE2_OMITTED_BMP_INDEX_1_LENGTH:uint = 0x10000 >> UTRIE2_SHIFT_1;

    /** Number of entries in an index-2 block. 64=0x40 */
    public static const UTRIE2_INDEX_2_BLOCK_LENGTH:uint = 1 << UTRIE2_SHIFT_1_2;
    /** Mask for getting the lower bits for the in-index-2-block offset. */
    public static const UTRIE2_INDEX_2_MASK:uint = UTRIE2_INDEX_2_BLOCK_LENGTH - 1;

    public static function createTrieFromBase64(base64:String):Trie {
        var buffer:Vector.<uint> = Utils.decode(base64);
        var view32:Vector.<uint> = Utils.polyUint32Array(buffer);
        var view16:Vector.<uint> = Utils.polyUint16Array(buffer);
        const headerLength:uint = 24;

        var index:Vector.<uint> = view16.slice(headerLength / 2, view32[4] / 2);
        var data:Vector.<uint> =
                view32[5] === 2
                        ? view16.slice((headerLength + view32[4]) / 2)
                        : view32.slice(Math.ceil((headerLength + view32[4]) / 4));

        return new Trie(view32[0], view32[1], view32[2], view32[3], index, data);
    }


    public var initialValue:int;
    public var errorValue:int;
    public var highStart:int;
    public var highValueIndex:int;
    public var index:Vector.<uint>;
    public var data:Vector.<uint>;


    public function Trie(
            initialValue:int,
            errorValue:int,
            highStart:int,
            highValueIndex:int,
            index:Vector.<uint>,
            data:Vector.<uint>
    ) {
        this.initialValue = initialValue;
        this.errorValue = errorValue;
        this.highStart = highStart;
        this.highValueIndex = highValueIndex;
        this.index = index;
        this.data = data;
    }

    /**
     * Get the value for a code point as stored in the Trie.
     *
     * @param codePoint the code point
     * @return the value
     */
    public function get(codePoint:uint):uint {
        var ix:uint;
        if (codePoint >= 0) {
            if (codePoint < 0x0d800 || (codePoint > 0x0dbff && codePoint <= 0x0ffff)) {
                // Ordinary BMP code point, excluding leading surrogates.
                // BMP uses a single level lookup.  BMP index starts at offset 0 in the Trie2 index.
                // 16 bit data is stored in the index array itself.
                ix = this.index[codePoint >> UTRIE2_SHIFT_2];
                ix = (ix << UTRIE2_INDEX_SHIFT) + (codePoint & UTRIE2_DATA_MASK);
                return this.data[ix];
            }

            if (codePoint <= 0xffff) {
                // Lead Surrogate Code Point.  A Separate index section is stored for
                // lead surrogate code units and code points.
                //   The main index has the code unit data.
                //   For this function, we need the code point data.
                // Note: this expression could be refactored for slightly improved efficiency, but
                //       surrogate code points will be so rare in practice that it's not worth it.
                ix = this.index[
                UTRIE2_LSCP_INDEX_2_OFFSET + ((codePoint - 0xd800) >> UTRIE2_SHIFT_2)
                        ];
                ix = (ix << UTRIE2_INDEX_SHIFT) + (codePoint & UTRIE2_DATA_MASK);
                return this.data[ix];
            }

            if (codePoint < this.highStart) {
                // Supplemental code point, use two-level lookup.
                ix =
                        UTRIE2_INDEX_1_OFFSET -
                        UTRIE2_OMITTED_BMP_INDEX_1_LENGTH +
                        (codePoint >> UTRIE2_SHIFT_1);
                ix = this.index[ix];
                ix += (codePoint >> UTRIE2_SHIFT_2) & UTRIE2_INDEX_2_MASK;
                ix = this.index[ix];
                ix = (ix << UTRIE2_INDEX_SHIFT) + (codePoint & UTRIE2_DATA_MASK);
                return this.data[ix];
            }
            if (codePoint <= 0x10ffff) {
                return this.data[this.highValueIndex];
            }
        }

        // Fall through.  The code point is outside of the legal range of 0..0x10ffff.
        return this.errorValue;
    }
}

}
