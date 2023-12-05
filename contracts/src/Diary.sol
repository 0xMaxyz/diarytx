// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./libraries/Date.sol";
import "./libraries/Errors.sol";
import "./libraries/Structs.sol";
import "./libraries/Events.sol";
import "./libraries/Enums.sol";

contract Diary is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using Date for uint256;

    uint256 public DiarySavingFee;
    uint256 public DiaryCoverFee;

    uint256 private s_lastTokenId = 1;
    uint32 constant FOLLOWER_TOKEN_AMOUNT = 1_000_000_000;
    mapping(address => uint32) LastSaveDate;

    // Diary
    mapping(uint256 => Structs.DiaryMetadata) DiaryMetaData;
    mapping(uint256 => address) DiaryOwners;

    // Profiles
    mapping(address profileOwner => uint256 profileTokenID) Profiles;
    mapping(uint256 => Structs.ProfileMetadata) ProfileMetaData;

    // Follower Tokens
    mapping(address profileOwner => uint256 followerTokenId) FollowerTokens;

    constructor(
        address initialOwner,
        uint256 diarySavingFee,
        uint256 diaryCoverFee,
        string memory initUri
    ) ERC1155(initUri) Ownable(initialOwner) {
        DiarySavingFee = diarySavingFee;
        DiaryCoverFee = diaryCoverFee;
    }

    function CreateDiary(
        string calldata diaryUri,
        bool addAiCover,
        address[3] calldata sharedWith,
        Enums.State state
    ) public payable {
        // Check if the requested address has registered diaries for current date
        if (GetNumberOfDiariesForCurrentDate(msg.sender) == 0) {
            if (addAiCover) {
                if (msg.value < DiaryCoverFee) {
                    revert Errors.Diary__CoverFeeInsufficient();
                }
            }
            // Check if the caller has a profile token
            if (!hasProfile(_msgSender())) {
                // mint a new profile token for the caller
                mintProfile();
            }
            // Create the diary
            _createDiary(msg.sender, diaryUri, addAiCover, sharedWith, state);
        } else {
            if (addAiCover) {
                if (msg.value < DiaryCoverFee + DiarySavingFee) {
                    revert Errors.Diary__InsufficientFee();
                }
            } else {
                if (msg.value < DiarySavingFee) {
                    revert Errors.Diary__InsufficientFee();
                }
            }
            // create the diary
            _createDiary(msg.sender, diaryUri, addAiCover, sharedWith, state);
        }
        // emit the diary created event
        emit Events.DiaryCreated(msg.sender, DiaryMetaData[s_lastTokenId]);
        unchecked {
            s_lastTokenId++;
        }
    }

    function mintProfile() private {
        if (hasProfile(_msgSender())) {
            revert Errors.Diary__ProfileExists(Profiles[_msgSender()]);
        }
        // Mint profile token
        mint(_msgSender(), s_lastTokenId, 1, "");
        // Add metadata
        // TODO: no uri implemented for profile token
        Structs.ProfileMetadata memory metadata = Structs.ProfileMetadata(
            "",
            Enums.ProfieVisibility.Private,
            block.timestamp,
            block.timestamp
        );
        ProfileMetaData[s_lastTokenId] = metadata;
        // Add to Profiles
        Profiles[_msgSender()] = s_lastTokenId;
        // emit Profile token mint
        emit Events.ProfileMint(_msgSender(), s_lastTokenId, metadata);

        increaseLastTokenId();

        // Mint follower tokens
        mint(_msgSender(), s_lastTokenId, FOLLOWER_TOKEN_AMOUNT, "");
        FollowerTokens[_msgSender()] = s_lastTokenId;

        // emit Follower token mint
        emit Events.FollowerTokensMint(_msgSender(), s_lastTokenId);
        increaseLastTokenId();
    }

    function hasProfile(address queriedAddress) private view returns (bool) {
        return Profiles[queriedAddress] > 0;
    }

    function increaseLastTokenId() private {
        unchecked {
            s_lastTokenId++;
        }
    }

    function _createDiary(
        address diaryOwner,
        string calldata diaryUri,
        bool addAiCover,
        address[3] calldata sharedWith,
        Enums.State state
    ) private {
        DiaryOwners[s_lastTokenId] = msg.sender;
        string memory aiCover = addAiCover ? GetCover(diaryOwner) : "";
        DiaryMetaData[s_lastTokenId] = _createMetadata(
            diaryUri,
            aiCover,
            sharedWith,
            state
        );
    }

    function _createMetadata(
        string calldata diaryUri,
        string memory aiCover,
        address[3] calldata sharedWith,
        Enums.State state
    ) private view returns (Structs.DiaryMetadata memory) {
        return
            Structs.DiaryMetadata({
                DiaryUri: diaryUri,
                AiCover: aiCover,
                SharedWith0: sharedWith[0],
                SharedWith1: sharedWith[1],
                SharedWith2: sharedWith[2],
                State: state,
                CreatedTimestamp: block.timestamp,
                ModifiedTimestamp: block.timestamp
            });
    }

    function GetNumberOfDiariesForCurrentDate(
        address diaryOwner
    ) public view returns (uint8 numberOfDiaries) {
        uint256 lastSaveDate = LastSaveDate[diaryOwner];
        (
            uint256 lastSaveDay,
            uint256 lastSaveMonth,
            uint256 lastSaveYear
        ) = lastSaveDate.GetDate();

        if (lastSaveDate == 0) {
            return 0;
        }
        (uint256 currentDay, uint256 currentMonth, uint256 currentYear) = block
            .timestamp
            .GetDate();
        if (
            lastSaveDay != currentDay ||
            lastSaveMonth != currentMonth ||
            lastSaveYear != currentYear
        ) {
            return 0;
        }
        if (
            lastSaveDay == currentDay &&
            lastSaveMonth == currentMonth &&
            lastSaveYear == currentYear
        ) {
            return 1;
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        _mintBatch(to, ids, amounts, data);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    // todo: this func should use chainlink functions to retrieve the cover
    function GetCover(
        address diaryUri
    ) private returns (string memory aiCover) {}
}

