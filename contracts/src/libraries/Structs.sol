// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Enums.sol";

library Structs {
    struct DiaryMetadata {
        string DiaryUri;
        string AiCover;
        Enums.State State;
        uint256 CreatedTimestamp;
        uint256 ModifiedTimestamp;
    }
    struct ProfileMetadata {
        string ProfileUri;
        Enums.ProfieVisibility Visibility;
        uint256 CreatedTimestamp;
        uint256 ModifiedTimestamp;
    }
}
