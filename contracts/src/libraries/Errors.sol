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
}
