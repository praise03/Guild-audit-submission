// SPDX-License-Identifier: MIT
interface S_M {
    struct MSS_SS_SSM {
        uint8 offset__0;
        uint8 offset__1;
        uint8 offset__2;
        uint8 offset__3;
        uint8 offset__4;
        uint8 offset__5;
        uint8 offset__6;
        uint8 offset__7;
        uint64 offset2_8;
        uint64 offset2_9;
        uint16 __boom__;
        uint48 offset2_10;
    }

    function __expected__() external view returns (MSS_SS_SSM memory);
}

