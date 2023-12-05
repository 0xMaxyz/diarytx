// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Enums {
    enum State {
        Public, // Not signed by a key
        Shareable, // Signed by an intermediary entity's key
        Private // Signed by issuer's key
    }

    enum ProfieVisibility {
        Private,
        Public
    }
}
