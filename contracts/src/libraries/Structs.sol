// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Enums} from "./Enums.sol";

library Structs {
    struct DiaryMetadata {
        string DiaryUri;
        string AiCover;
        address SharedWith0;
        address SharedWith1;
        address SharedWith2;
        Enums.State State;
        uint256 CreatedTimestamp;
        uint256 ModifiedTimestamp;
    }
}
