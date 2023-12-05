// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Structs} from "./Structs.sol";

library Events {
    event DiaryCreated(
        address indexed diaryOwner,
        Structs.DiaryMetadata metadata
    );

    event DiaryModified(
        uint256 indexed diaryId,
        address indexed diaryOwner,
        Structs.DiaryMetadata indexed metadata
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
        address profileOwner,
        uint256 tokenId,
        Structs.ProfileMetadata metadata
    );
    event FollowerTokensMint(address profileOwner, uint256 tokenId);
}
