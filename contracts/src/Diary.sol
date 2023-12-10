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

    uint256 nonce;
    uint256 public DiarySavingFee;
    uint256 public DiaryCoverFee;

    uint8 constant FOLLOWER_TOKEN_ID = 1;

    mapping(address => uint256) LastSaveDate;

    // Diary
    mapping(uint256 => address) DiaryOwners;
    mapping(uint256 diaryTokenId => Enums.DiaryVisibility visibility) DiaryVisibility;

    // Profiles
    mapping(address profileOwner => mapping(uint256 profileTokenID => bool isOwned)) Profiles;
    mapping(address profileOwner => bool hasProfile) HasProfile;
    mapping(uint256 profileTokenId => mapping(uint256 diaryTokenId => bool ownedByProfile)) ProfileDiaries;

    // Token URIs
    mapping(uint256 tokenId => string tokenMetadataUri) TokenUri;

    constructor(
        uint256 diarySavingFee,
        uint256 diaryCoverFee,
        string memory ownerProfileUri
    ) ERC1155("") Ownable(msg.sender) {
        DiarySavingFee = diarySavingFee;
        DiaryCoverFee = diaryCoverFee;

        // Mint 1000 follower token for contract owner
        _mint(msg.sender, FOLLOWER_TOKEN_ID, 1000, "");

        // Mint a profile for contract owner
        mintProfile(ownerProfileUri);
    }

    function _getUniqueId(Enums.TokenType tokenType) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(msg.sender, blockhash(block.number - 1), tokenType, nonce)
                )
            );
    }

    function _incrementNounce() private {
        unchecked {
            ++nonce;
        }
    }

    function getUniqueIdAndIncrementNonce(Enums.TokenType tokenType) private returns (uint256 id) {
        id = _getUniqueId(tokenType);
        _incrementNounce();
    }

    function CreateDiary(
        uint256 profileId,
        string calldata diaryUri,
        Enums.DiaryVisibility diaryVisibility
    ) public payable {
        // Check if profile is owned by caller
        if (!Profiles[msg.sender][profileId]) {
            revert Errors.Diary__ProfileNotOwnedByYou();
        }
        // Check if the requested address has registered diaries for current date
        if (!MoreThanOneDiaryPerDay(msg.sender)) {
            // Create the diary
            _createDiary(profileId, diaryUri, diaryVisibility);
        } else {
            if (msg.value < DiarySavingFee) {
                revert Errors.Diary__InsufficientFee();
            }

            // create the diary
            _createDiary(profileId, diaryUri, diaryVisibility);
        }
    }

    function mintProfile(string memory profileUri) private {
        // get unique id
        uint256 profileTokenId = getUniqueIdAndIncrementNonce(Enums.TokenType.ProfileToken);

        // Mint profile token
        mint(msg.sender, profileTokenId, 1, "");

        // Add token uri
        TokenUri[profileTokenId] = profileUri;

        // Add to Profiles
        Profiles[msg.sender][profileTokenId] = true;

        // set HasProfile to true
        HasProfile[msg.sender] = true;

        // emit Profile token mint
        emit Events.ProfileMint(msg.sender, profileTokenId, profileUri);
    }

    function _createDiary(
        uint256 profileId,
        string calldata diaryUri,
        Enums.DiaryVisibility diaryVisibility
    ) private {
        // get unique id for the diary
        uint256 diaryId = getUniqueIdAndIncrementNonce(Enums.TokenType.DiaryToken);

        // Mint the new diary for msg.sender
        mint(msg.sender, diaryId, 1, "");

        // set visibbility of diary in its mapping
        DiaryVisibility[diaryId] = diaryVisibility;
        // set the msg.sender as the owner of this diary in its mapping
        DiaryOwners[diaryId] = msg.sender;
        // add this diary to requested profile which is owned by msg.sender
        ProfileDiaries[profileId][diaryId] = true;

        TokenUri[diaryId] = diaryUri;

        // emit the diary created event
        emit Events.DiaryCreated(profileId, diaryId, diaryUri);

        // Update last save date
        LastSaveDate[msg.sender] = block.timestamp;
    }

    function MoreThanOneDiaryPerDay(address diaryOwner) public view returns (bool moreThanOne) {
        uint256 lastSaveDate = LastSaveDate[diaryOwner];
        if (lastSaveDate == 0) {
            return false;
        }

        // get last date (d,m,y)
        (uint256 lastSaveDay, uint256 lastSaveMonth, uint256 lastSaveYear) = lastSaveDate.GetDate();

        // Get current date from block timestamp
        (uint256 currentDay, uint256 currentMonth, uint256 currentYear) = block.timestamp.GetDate();

        // If these two dates are different, return 0
        if (
            lastSaveDay != currentDay ||
            lastSaveMonth != currentMonth ||
            lastSaveYear != currentYear
        ) {
            return false;
        }
        // if these two dates are the same, then return 1
        if (
            lastSaveDay == currentDay &&
            lastSaveMonth == currentMonth &&
            lastSaveYear == currentYear
        ) {
            return true;
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) private {
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

    // TODO: this func should use chainlink functions to retrieve the cover
    function GetCover(address diaryUri) private returns (string memory aiCover) {}
}
