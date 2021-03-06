pragma solidity ^0.5.0;

// Util functions caller to process strings.
library StringUtils {
    uint constant UINT256MAX = ~uint(0);

    // A decimal byte to uint. Return value of 10 indicating invalid input.
    function byte2Uint(byte b) internal pure returns(uint8) {
        if (b >= '0' && b <= '9') {
            return uint8(b) - 48;  // '0'
        }
        // Indicating invalid input.
        return 10;
    }
    // Return value of 16 indicating invalid input.
    function hexByte2Uint(byte b) internal pure returns(uint8) {
        if (b >= '0' && b <= '9') {
            return uint8(b) - 48;  // '0'
        } else if (b >= 'A' && b <= 'F') {
            return uint8(b) - 55;
        } else if (b >= 'a' && b <= 'f') {
            return uint8(b) - 87;
        }
        // Indicating invalid input.
        return 16;
    }

    /// StringToXXX helpers.

    // A decimal string (charset c in [0-9]) to uint. Like atoi(),
    // 1. processing stops once encountering character not in charset c.
    // 2. returns UINT256MAX when overflow.
    function str2Uint(string memory a) internal pure returns(uint) {
        return bytes2Uint(bytes(a));
    }

    // A decimal bytes string (charset c in [0-9]) to uint. Like atoi().
    function bytes2Uint(bytes memory b) internal pure returns(uint) {
        uint res = 0;
        for (uint i = 0; i < b.length; i++) {
            uint8 tmp = byte2Uint(b[i]);
            if (tmp >= 10) {
                return res;
            } else {
                // Overflow.
                if (res >= UINT256MAX / 10) {
                    return UINT256MAX;
                }
                res = res * 10 + tmp;
            }
        }
        return res;
    }

    // Hex string (charset c in [0-9A-Za-z]) to uint. Like atoi(),
    // 1. processing stops once encountering character not in charset c.
    // 2. returns UINT256MAX when overflow.
    function hexStr2Uint(string memory a) internal pure returns(uint) {
        bytes memory b = bytes(a);
        uint res = 0;
        uint i = 0;
        if (b.length >= 2 && b[0] == '0' && (b[1] == 'x' || b[1] == 'X')) {
            i += 2;
        }
        for (; i < b.length; i++) {
            uint tmp = hexByte2Uint(b[i]);
            if (tmp >= 16) {
                return res;
            } else {
                // Overflow.
                if (res >= UINT256MAX / 16) {
                    return UINT256MAX;
                }
                res = res * 16 + tmp;
            }
        }
        return res;
    }

    // Input: 20-byte hex string without or with 0x/0X prefix (40 characters or 42 characters)
    // Example: '0x0e7ad63d2a305a7b9f46541c386aafbd2af6b263' => address(0x0e7ad63d2a305a7b9f46541c386aafbd2af6b263)
    // address is of uint160.
    function str2Addr(string memory a) internal pure returns(address) {
        bytes memory b = bytes(a);
        require(b.length == 40 || b.length == 42, "Invalid input, should be 20-byte hex string");
        uint i = 0;
        if (b.length == 42) {
            i += 2;
        }

        uint160 res = 0;
        for (; i < b.length; i += 2) {
            res *= 256;

            uint160 b1 = uint160(hexByte2Uint(b[i]));
            uint160 b2 = uint160(hexByte2Uint(b[i+1]));
            require(b1 < 16 && b2 < 16, "address string with invalid character");

            res += b1 * 16 + b2;
        }
        return address(res);
    }

    /// XXXToString() helpers.

    // Example: 12 -> 'c' (without 0x/0X prefix).
    function uint2HexStr(uint x) internal pure returns(string memory) {
        if (x == 0) return '0';

        uint j = x;
        uint len;
        while (j != 0) {
            len++;
            j /= 16;
        }

        bytes memory b = new bytes(len);
        uint k = len - 1;
        while (x != 0) {
            uint8 curr = uint8(x & 0xf);
            b[k--] = curr > 9 ? byte(55 + curr) : byte(48 + curr);
            x /= 16;
        }
        return string(b);
    }

    // Example: 12 -> "12"
    function uint2Str(uint x) internal pure returns(string memory) {
        if (x == 0) return '0';

        uint j = x;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory b = new bytes(len);
        uint k = len - 1;
        while (x != 0) {
            b[k--] = byte(uint8(48 + x % 10));
            x /= 10;
        }
        return string(b);
    }

    // Example: address(0x0e7ad63d2a305a7b9f46541c386aafbd2af6b263) => '0x0e7ad63d2a305a7b9f46541c386aafbd2af6b263'
    function addr2Str(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory charset = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = charset[uint8(value[i + 12] >> 4)];
            str[3+i*2] = charset[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    /// bytes/string helpers.

    function bytesConcat(bytes memory a, bytes memory b) internal pure returns(bytes memory) {
        bytes memory concated = new bytes(a.length + b.length);
        uint i = 0;
        uint k = 0;
        while (i < a.length) { concated[k++] = a[i++]; }
        i = 0;
        while(i < b.length) { concated[k++] = b[i++]; }
        return concated;
    }

    function strConcat(string memory a, string memory b) internal pure returns(string memory) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        return string(bytesConcat(aa, bb));
    }

    function bytesCompare(bytes memory a, bytes memory b) internal pure returns(int) {
        uint len = a.length < b.length ? a.length : b.length;
        for (uint i = 0; i < len; i++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    // "abd" > "abcde"
    function strCompare(string memory a, string memory b) internal pure returns(int) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        return bytesCompare(aa, bb);
    }

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns(bool) {
        return (a.length == b.length) && (bytesCompare(a, b) == 0);
    }

    function strEqual(string memory a, string memory b) internal pure returns(bool) {
        bytes memory aa = bytes(a);
        bytes memory bb = bytes(b);
        return bytesEqual(aa, bb);
    }

    // Return the index of needle's first occurrance in haystack; or return index of the first byte
    // after haystack if not found.
    // Useful in case of parsing float string "123.45".
    // Example:
    //   indexOf('123', '') => 0
    //   indexOf('', '45') => 1
    //   indexOf('123', '1234') => 3
    //   indexOf('12345', '34') => 2
    //   indexOf('123.45', '.') => 3
    function indexOf(string memory haystack, string memory needle) internal pure returns(uint) {
        bytes memory b_haystack = bytes(haystack);
        bytes memory b_needle = bytes(needle);
        return indexOf(b_haystack, b_needle);
    }

    function indexOf(bytes memory haystack, bytes memory needle) internal pure returns(uint) {
        if (needle.length == 0) {
            return 0;
        } else if (haystack.length < needle.length) {
            return haystack.length;
        }
        // Instead of O(haystack.length x needle.length), saving gas using KMP:
        // O(haystack.length + needle.length)
        uint[] memory pi = new uint[](needle.length + 1);
        pi[1] = 0;
        uint k = 0;
        uint q = 0;
        // KMP pre-processing
        for(q = 2; q <= needle.length; q++) {
            while(k > 0 && needle[k] != needle[q-1]) {
                k = pi[k];
            }
            if(needle[k] == needle[q-1]) {
                k++;
            }
            pi[q] = k;
        }
        // KMP matching
        q = 0;
        for(uint i = 0; i < haystack.length; i++) {
            while(q > 0 && needle[q] != haystack[i]) {
                q = pi[q];
            }
            if(needle[q] == haystack[i]) {
                q++;
            }
            // Match
            if(q == needle.length) {
                return i - q + 1;
            }
        }
        // No match
        return haystack.length;
    }

    // subStr("123456789", 2, 5)   => "34567"
    // subStr("123456789", 2, 100) => "3456789"
    // [start, start + len), index starting from 0.
    function subStr(bytes memory a, uint start, uint len) internal pure returns(bytes memory) {
        if (start >= a.length) return "";

        if (a.length - start < len) len = a.length - start;
        bytes memory res = new bytes(len);
        for (uint i = 0; i < len; i++) {
            res[i] = a[start + i];
        }
        return res;
    }

    // string num = "123.4567";
    // subStr(num, indexOf(num, '.') + 1) => "4567"
    function subStr(bytes memory a, uint start) internal pure returns(bytes memory) {
        return subStr(a, start, a.length);
    }

    function subStr(string memory a, uint start, uint len) internal pure returns(string memory) {
        bytes memory aa = bytes(a);
        return string(subStr(aa, start, len));
    }

    function subStr(string memory a, uint start) internal pure returns(string memory) {
        bytes memory aa = bytes(a);
        return string(subStr(aa, start));
    }

    function count(bytes memory str, bytes memory delimiter) internal pure returns(uint) {
        uint cnt = 0;
        while(str.length > 0) {
            uint idx = indexOf(str, delimiter);
            if (idx != str.length) {
                cnt++;
                str = subStr(str, idx + delimiter.length);
            } else {
                return cnt;
            }
        }
        return cnt;
    }

    function count(string memory str, string memory delimiter) internal pure returns(uint) {
        return count(bytes(str), bytes(delimiter));
    }

    function split(string memory str, string memory delimiter) internal pure returns(string[] memory) {
        bytes[] memory r = split(bytes(str), bytes(delimiter));
        string[] memory ret = new string[](r.length);
        for (uint i = 0; i < r.length; i++) {
            ret[i] = string(r[i]);
        }
        return ret;
    }

    function split(bytes memory str, bytes memory delimiter) internal pure returns(bytes[] memory) {
        uint len = count(str, delimiter) + 1;
        bytes[] memory ret = new bytes[](len);
        for (uint i = 0; i < len; i++) {
            uint idx = indexOf(str, delimiter);
            ret[i] = subStr(str, 0, idx);
            str = subStr(str, idx + delimiter.length);
        }
        return ret;
    }
}
