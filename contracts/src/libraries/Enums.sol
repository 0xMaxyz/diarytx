// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Enums {
    enum DiaryVisibility {
        Private,
        Public
    }

    enum ProfieVisibility {
        Private,
        Public
    }

    enum TokenType {
        ProfileToken,
        FollowerToken,
        DiaryToken
    }
}
