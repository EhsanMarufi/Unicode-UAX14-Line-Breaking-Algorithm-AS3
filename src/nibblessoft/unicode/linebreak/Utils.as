package nibblessoft.unicode.linebreak {
import flash.utils.ByteArray;
import flash.utils.Dictionary;

// TODO: CHANGE TO INTERNAL AFTER TESTS ARE DONE
public class Utils {
    public static function toCodePoints(str:String):Vector.<uint> {
        var codePoints:Vector.<uint> = new Vector.<uint>();

        var i:uint = 0;
        const STR_LEN:uint = str.length;

        while (i < STR_LEN) {
            const value:uint = str.charCodeAt(i++);

            // Characters outside the BMP (Basic Multilingual Plane) can ONLY be encoded in UTF-16 using two 16-bit
            // "code units." They are called "surrogate pairs". A surrogate pair only represents a single character.
            // The first "code unit" of a surrogate pair is always in the range from '0xD800' to '0xDBFF', and is
            // called a high surrogate or a lead surrogate.
            // The second "code unit" of a surrogate pair is always in the range from '0xDC00' to '0xDFFF', and is
            // called a low surrogate or a trail surrogate.
            // To convert the surrogate pairs to Unicode code-points implemented here refer to:
            // https://en.wikipedia.org/wiki/UTF-16

            if (value >= 0xD800 && value <= 0xDBFF && i < STR_LEN) {
                const trailSurrogate:uint = str.charCodeAt(i++);
                if ((trailSurrogate & 0xFC00) === 0xDC00) {
                    codePoints.push(((value & 0x3ff) << 10) + (trailSurrogate & 0x3ff) + 0x10000);
                } else {
                    codePoints.push(value);
                    i--;
                }
            } else {
                codePoints.push(value);
            }
        }

        return codePoints;
    }

    public static function fromCodePoints(codePoints:Vector.<uint>):String {
        const LEN:uint = codePoints.length;
        if (!LEN)
            return "";

        // a list of 16-bit code units
        var codeUnits:Array = [];

        var index:int = -1;
        var result:String = "";
        while (++index < LEN) {
            var codePoint:uint = codePoints[index];

            if (codePoint <= 0xFFFF) {
                // All of the code points in the range from '0' to '0xFFFF' (i.e. the BMP) fit inside of a single
                // 16-bit field (UCS-2).
                codeUnits.push(codePoint);
            } else {
                // Characters outside the BMP (non-BMP characters) can only be encoded in UTF-16 using two 16-bit
                // code units. They are called surrogate pairs. A surrogate pair only represents a single character.
                // To convert the Unicode code-points into surrogate pairs implemented here refer to:
                // https://en.wikipedia.org/wiki/UTF-16
                codePoint -= 0x10000;
                codeUnits.push((codePoint >> 10) + 0xD800, codePoint % 0x400 + 0xDC00);
            }

            if (index + 1 == LEN || codeUnits.length > 0x4000) {
                // Store the chunk (when it's the last character of the sequence, or the list has grown big)
                result += String.fromCharCode.apply(null, codeUnits);
                codeUnits.length = 0;
            }
        }

        return result;
    }


    private static const BASE64_CHARS:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    private static var base64_lookup:Dictionary = new Dictionary();

    private static function init_base64():void {

        const BASE64_CHARS_LEN:uint = BASE64_CHARS.length;
        var i:uint;
        for (i = 0; i < BASE64_CHARS_LEN; i++) {
            base64_lookup[BASE64_CHARS.charCodeAt(i)] = i;
        }
    }

    {
        // Static initializer
        init_base64();
    }


    public static function decode(base64:String):Vector.<uint> {
        var LEN:uint = base64.length;
        var bufferLength:uint = LEN * 0.75,
                i:uint,
                p:uint = 0,
                encoded1:uint,
                encoded2:uint,
                encoded3:uint,
                encoded4:uint;

        if (base64.charAt(LEN - 1) == '=') {
            bufferLength--;
            if (base64.charAt(LEN - 2) == '=') {
                bufferLength--;
            }
        }

        var bytes:Vector.<uint> = new Vector.<uint>(bufferLength);

        for (i = 0; i < LEN; i += 4) {
            encoded1 = base64_lookup[base64.charCodeAt(i)];
            encoded2 = base64_lookup[base64.charCodeAt(i + 1)];
            encoded3 = base64_lookup[base64.charCodeAt(i + 2)];
            encoded4 = base64_lookup[base64.charCodeAt(i + 3)];

            bytes[p++] = (encoded1 << 2) | (encoded2 >> 4);
            bytes[p++] = ((encoded2 & 15) << 4) | (encoded3 >> 2);
            bytes[p++] = ((encoded3 & 3) << 6) | (encoded4 & 63);
        }

        return bytes;
    }

    public static function encode (bytes:Vector.<uint>):String {
        var len:uint = bytes.length, base64:String = "", strTemp:String;

        for (var i:uint = 0; i < len; i+=3) {
            strTemp = "";
            strTemp += BASE64_CHARS.charAt(bytes[i] >> 2);
            strTemp += BASE64_CHARS.charAt(((bytes[i] & 3) << 4) | (bytes[i + 1] >> 4));
            strTemp += BASE64_CHARS.charAt(((bytes[i + 1] & 15) << 2) | (bytes[i + 2] >> 6));
            strTemp += BASE64_CHARS.charAt(bytes[i + 2] & 63);

            base64 += strTemp;
        }

        if ((len % 3) == 2) {
            base64 = base64.substring(0, base64.length - 1) + "=";
        } else if (len % 3 == 1) {
            base64 = base64.substring(0, base64.length - 2) + "==";
        }

        return base64;
    }

    public static function polyUint16Array (buffer: Vector.<uint>): Vector.<uint> {
        const LEN:uint = buffer.length;
        var bytes:Vector.<uint> = new Vector.<uint>();
        for (var i:uint = 0; i < LEN; i += 2) {
            bytes.push((buffer[i + 1] << 8) | buffer[i]);
        }
        return bytes;
    }

    public static function polyUint32Array (buffer: Vector.<uint>): Vector.<uint> {
        const LEN:uint = buffer.length;
        var bytes:Vector.<uint> = new Vector.<uint>();
        for (var i:uint = 0; i < LEN; i += 4) {
            bytes.push((buffer[i + 3] << 24) | (buffer[i + 2] << 16) | (buffer[i + 1] << 8) | buffer[i]);
        }
        return bytes;
    }
}
}
