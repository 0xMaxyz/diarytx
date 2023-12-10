// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error Diary__NotAuthorized();
    error Diary__NotOwnedByYou();
    error Diary__InsufficientFee();
    error Diary__CoverFeeInsufficient();
    error Diary__SharedSlotsAreFull();
    error Diary__NotSharedWithInput();
    error Diary__PublicKeyAlreadySaved();
    error Diary__ProfileExists(uint256);
    error Diary__ProfileNotOwnedByYou();
    error Diary__NotEnoughFollowerToken();
    error Diary__NotAllowedToFollowYourself();
    error Diary__ProfileNotOwnedByAnyone();
    error Diary__ProfileAlreadyFollowedByYou();
    error Diary__ProfileNotFollowedByYou();
    error Diary__RequestedProfileIsNotPrivate();
    error Diary__NoActiveFollowRequestForRequester();
}
