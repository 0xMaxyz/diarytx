// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Structs} from "./Structs.sol";

library Events {
    event DiaryCreated(
        uint256 indexed profileTokenId,
        uint256 indexed diaryId,
        string indexed tokenUri
    );

    event DiaryShared(
        uint256 indexed diaryId,
        address indexed diaryOwner,
        address indexed sharedwith,
        string metadata
    );

    event DiarySharingRevoked(
        uint256 indexed diaryId,
        address indexed diaryOwner,
        address indexed sharedwith
    );

    event SavingFeeChanged(uint256 indexed newFee);

    event PublicKeySaved(address addr);

    // Profile Events
    event ProfileMint(
        address indexed profileOwner,
        uint256 indexed tokenId,
        string indexed tokenUri
    );
    event FollowerTokensMint(address profileOwner, uint256 tokenId);
}
