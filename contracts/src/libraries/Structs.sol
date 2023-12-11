// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Enums.sol";

library Structs {
    struct Profile {
        bool isPrivate;
        mapping(address => bool) followRequests;
    }

    struct MoodHistory {
        Enums.Mood mood;
        uint256 timestamp;
    }
}
