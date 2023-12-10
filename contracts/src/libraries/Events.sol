// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Structs} from "./Structs.sol";

library Events {
    event DiaryCreated(
        uint256 indexed profileTokenId,
        uint256 indexed diaryId,
        string indexed tokenUri
    );

    event SavingFeeChanged(uint256 indexed newFee);

    // Profile Events
    event ProfileMint(
        address indexed profileOwner,
        uint256 indexed tokenId,
        string indexed tokenUri
    );

    event ProfileFollowed(
        address indexed followerAddress,
        address indexed followeeAddress,
        uint256 indexed followedProfileId
    );

    event ProfileUnfollowed(
        address indexed followerAddress,
        address indexed followeeAddress,
        uint256 indexed followedProfileId
    );

    event ProfilePrivacyChanged(uint256 indexed profileId, bool isPrivate);
    event FollowRequestApproved(uint256 indexed profileId, address indexed requester);
    event FollowRequestDenied(uint256 indexed profileId, address indexed requester);
    event FollowRequest(uint256 indexed profileId, address indexed requester);
}
