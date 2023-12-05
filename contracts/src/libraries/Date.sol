// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Date {
    /// @dev The visibility of this function shall be changed to external for the test to run successfully
    function GetDate(
        uint timestamp
    ) internal pure returns (uint day, uint month, uint year) {
        unchecked {
            int __days = int(timestamp / 86400);

            int L = __days + 2509157;
            int N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int _month = (80 * L) / 2447;
            int _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint(_year);
            month = uint(_month);
            day = uint(_day);
        }
    }
}
