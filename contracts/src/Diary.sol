// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "./libraries/Date.sol";
import "./libraries/Errors.sol";
import "./libraries/Structs.sol";
import "./libraries/Events.sol";
import "./libraries/Enums.sol";

contract Diary is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard,
    FunctionsClient
{
    using Date for uint256;

    uint256 nonce;
    uint256 public DiarySavingFee;
    uint256 public DiaryCoverFee;
    uint256 constant ADDITIONAL_PROFILE_FEE = 100; // 100 follower token

    // Track last save date
    mapping(address => uint256) private lastSaveDate;

    // Follower token
    uint8 constant FOLLOWER_TOKEN_ID = 1;
    uint256 public followerTokenPrice = 1; // per FOLLOWER_PRICE_PER_QUANTITY follower tokens
    uint256 private constant FOLLOWER_PRICE_PER_QUANTITY = 100;
    uint256 public discountRate = 10;
    mapping(address => mapping(uint256 => bool)) private isFollowing;
    mapping(uint256 => address[]) private profileFollowers;
    mapping(uint256 => mapping(address => uint256)) private profileFollowerIndexes;

    // Diary
    mapping(uint256 => address) private DiaryOwners;
    mapping(uint256 => Enums.DiaryVisibility) private diaryVisibility;
    mapping(uint256 => Enums.Mood) private diaryMood;
    mapping(address => Structs.MoodHistory[]) moodHistory;

    // Profiles
    mapping(address => mapping(uint256 => bool)) private profileTokens;
    mapping(uint256 => address) private profileOwnedBy;
    mapping(address => bool) public hasProfile;
    mapping(uint256 => mapping(uint256 => bool)) private profileDiaries;
    mapping(uint256 => Structs.Profile) private profileData;

    uint256[] public publicProfileIds;
    mapping(uint256 => uint256) public profileIndexInPublic;

    bytes32 private immutable s_donId;

    // Token URIs
    mapping(uint256 => string) private tokenUri;

    constructor(
        uint256 diarySavingFee,
        uint256 diaryCoverFee,
        string memory ownerProfileUri,
        address routerAddress,
        bytes32 donId
    ) ERC1155("") Ownable(msg.sender) FunctionsClient(routerAddress) {
        DiarySavingFee = diarySavingFee;
        DiaryCoverFee = diaryCoverFee;

        // Mint 1000 follower token for contract owner
        _mint(msg.sender, FOLLOWER_TOKEN_ID, 1000, "");

        // Mint a profile for contract owner (add as public profile)
        mintProfile(ownerProfileUri, false);

        s_donId = donId;
    }

    function CreateProfile(string memory profileUri, bool isPrivate) external payable {
        // check if sender has a profile or not
        if (hasProfile[msg.sender]) {
            // then the requester, should pay for additional profile registration
            if (msg.value < ADDITIONAL_PROFILE_FEE) {
                revert Errors.Diary__InsufficientFee();
            }
            mintProfile(profileUri, isPrivate);
        } else {
            // no profile is registered for the requester, no fee is required
            mintProfile(profileUri, isPrivate);
            // mint 1000 follower token for the requester
            _mint(msg.sender, FOLLOWER_TOKEN_ID, 1000, "");
        }
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
        Enums.DiaryVisibility visibility
    ) public payable {
        // Check if profile is owned by caller
        if (!profileTokens[msg.sender][profileId]) {
            revert Errors.Diary__ProfileNotOwnedByYou();
        }
        // Check if the requested address has registered diaries for current date
        if (!MoreThanOneDiaryPerDay(msg.sender)) {
            // Create the diary
            _createDiary(profileId, diaryUri, visibility);
        } else {
            if (msg.value < DiarySavingFee) {
                revert Errors.Diary__InsufficientFee();
            }

            // create the diary
            _createDiary(profileId, diaryUri, visibility);
        }
    }

    function mintProfile(string memory profileUri, bool isPrivate) private {
        // get unique id
        uint256 profileTokenId = getUniqueIdAndIncrementNonce(Enums.TokenType.ProfileToken);

        // Mint profile token
        mint(msg.sender, profileTokenId, 1, "");

        // Add token uri
        tokenUri[profileTokenId] = profileUri;

        // Add to Profiles
        profileTokens[msg.sender][profileTokenId] = true;

        // set HasProfile to true
        hasProfile[msg.sender] = true;

        // set profileTokenId as owned
        profileOwnedBy[profileTokenId] = msg.sender;

        // add profile data
        profileData[profileTokenId].isPrivate = isPrivate;

        if (!isPrivate) {
            // Add this profile to list of public profiles
            publicProfileIds.push(profileTokenId);
            profileIndexInPublic[profileTokenId] = publicProfileIds.length - 1;
        }

        // emit Profile token mint
        emit Events.ProfileMint(msg.sender, profileTokenId, profileUri);
    }

    function _createDiary(
        uint256 profileId,
        string calldata diaryUri,
        Enums.DiaryVisibility visibility
    ) private {
        // get unique id for the diary
        uint256 diaryId = getUniqueIdAndIncrementNonce(Enums.TokenType.DiaryToken);

        // Mint the new diary for msg.sender
        mint(msg.sender, diaryId, 1, "");

        // set visibbility of diary in its mapping
        diaryVisibility[diaryId] = visibility;
        // set the msg.sender as the owner of this diary in its mapping
        DiaryOwners[diaryId] = msg.sender;
        // add this diary to requested profile which is owned by msg.sender
        profileDiaries[profileId][diaryId] = true;

        tokenUri[diaryId] = diaryUri;

        // emit the diary created event
        emit Events.DiaryCreated(profileId, diaryId, diaryUri);

        // Update last save date
        lastSaveDate[msg.sender] = block.timestamp;
    }

    function MoreThanOneDiaryPerDay(address diaryOwner) public view returns (bool moreThanOne) {
        uint256 lsDate = lastSaveDate[diaryOwner];
        if (lsDate == 0) {
            return false;
        }

        // get last date (d,m,y)
        (uint256 lastSaveDay, uint256 lastSaveMonth, uint256 lastSaveYear) = lsDate.GetDate();

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

    function buyFollowerTokens(uint256 quantity) external payable nonReentrant {
        uint256 totalPrice = (followerTokenPrice * quantity) / FOLLOWER_PRICE_PER_QUANTITY;
        if (quantity >= FOLLOWER_PRICE_PER_QUANTITY * 10) {
            totalPrice = totalPrice - ((totalPrice * discountRate) / 100);
        }
        if (msg.value < totalPrice) {
            revert Errors.Diary__InsufficientFee();
        }

        _mint(msg.sender, FOLLOWER_TOKEN_ID, quantity, "");
    }

    function setFollowerTokenPrice(uint256 newPrice) external onlyOwner {
        followerTokenPrice = newPrice;
    }

    function followProfile(uint256 followerProfileId, uint256 followeeProfileId) external {
        if (!profileTokens[msg.sender][followerProfileId]) {
            revert Errors.Diary__ProfileNotOwnedByYou();
        }
        if (
            profileTokens[msg.sender][followerProfileId] ==
            profileTokens[msg.sender][followeeProfileId]
        ) {
            revert Errors.Diary__NotAllowedToFollowYourself();
        }

        if (profileOwnedBy[followeeProfileId] == address(0)) {
            revert Errors.Diary__ProfileNotOwnedByAnyone();
        }
        if (balanceOf(msg.sender, FOLLOWER_TOKEN_ID) < 1) {
            revert Errors.Diary__NotEnoughFollowerToken();
        }

        if (isFollowing[msg.sender][followeeProfileId]) {
            revert Errors.Diary__ProfileAlreadyFollowedByYou();
        }

        // Transfer one Follower Token from the follower to the contract as a 'staking' concept
        _safeTransferFrom(msg.sender, address(this), FOLLOWER_TOKEN_ID, 1, "");

        // Record that the user is now following the profileId
        isFollowing[msg.sender][followeeProfileId] = true;
        profileFollowers[followeeProfileId].push(msg.sender);

        profileFollowerIndexes[followeeProfileId][msg.sender] =
            profileFollowers[followeeProfileId].length -
            1;

        emit Events.ProfileFollowed(
            msg.sender,
            profileOwnedBy[followeeProfileId],
            followeeProfileId
        );
    }

    function unfollowProfile(uint256 profileId) external {
        if (!isFollowing[msg.sender][profileId]) {
            revert Errors.Diary__ProfileNotFollowedByYou();
        }

        // Transfer the Follower Token back to the unfollower
        _safeTransferFrom(address(this), msg.sender, FOLLOWER_TOKEN_ID, 1, "");

        // Record that the user has unfollowed the profile
        isFollowing[msg.sender][profileId] = false;

        // Remove follower from the profileFollowers list in an efficient way
        uint256 followerIndex = profileFollowerIndexes[profileId][msg.sender];
        address lastFollower = profileFollowers[profileId][profileFollowers[profileId].length - 1];

        // Move the last element to the slot of the to-be-removed element
        profileFollowers[profileId][followerIndex] = lastFollower;
        // Update the index mapping for the last follower
        profileFollowerIndexes[profileId][lastFollower] = followerIndex;
        // Remove the last element
        profileFollowers[profileId].pop();

        // Clean up our index mapping
        delete profileFollowerIndexes[profileId][msg.sender];

        emit Events.ProfileUnfollowed(msg.sender, profileOwnedBy[profileId], profileId);
    }

    modifier onlyProfileOwner(uint256 profileId) {
        if (profileOwnedBy[profileId] != msg.sender) {
            revert Errors.Diary__ProfileNotOwnedByYou();
        }

        _;
    }

    function setProfilePrivacy(
        uint256 profileId,
        bool _isPrivate
    ) external onlyProfileOwner(profileId) {
        // make the profile public
        if (profileData[profileId].isPrivate && !_isPrivate) {
            // Add this profile to list of public profiles
            publicProfileIds.push(profileId);
            profileIndexInPublic[profileId] = publicProfileIds.length - 1;

            profileData[profileId].isPrivate = _isPrivate;
            emit Events.ProfilePrivacyChanged(profileId, _isPrivate);
        }
        // make the profile private
        if (!profileData[profileId].isPrivate && _isPrivate) {
            uint256 indexToRemove = profileIndexInPublic[profileId];
            uint256 lastIndex = publicProfileIds.length - 1;
            if (indexToRemove != lastIndex) {
                uint256 lastProfileId = publicProfileIds[lastIndex];

                publicProfileIds[indexToRemove] = lastProfileId;
                profileIndexInPublic[lastProfileId] = indexToRemove;
            }
            publicProfileIds.pop();
            delete profileIndexInPublic[profileId];

            profileData[profileId].isPrivate = _isPrivate;
            emit Events.ProfilePrivacyChanged(profileId, _isPrivate);
        }
    }

    function requestToFollowProfile(uint256 profileId) external {
        if (!profileData[profileId].isPrivate) {
            revert Errors.Diary__RequestedProfileIsNotPrivate();
        }
        if (profileOwnedBy[profileId] == msg.sender) {
            revert Errors.Diary__NotAllowedToFollowYourself();
        }

        //initializeProfile(profileId);
        profileData[profileId].followRequests[msg.sender] = true;

        emit Events.FollowRequest(profileId, msg.sender);
    }

    function approveFollowRequest(
        uint256 profileId,
        address requester
    ) external onlyProfileOwner(profileId) {
        if (!profileData[profileId].isPrivate) {
            revert Errors.Diary__RequestedProfileIsNotPrivate();
        }

        if (!profileData[profileId].followRequests[requester]) {
            revert Errors.Diary__NoActiveFollowRequestForRequester();
        }

        // approve and follow
        isFollowing[requester][profileId] = true;
        profileFollowers[profileId].push(requester);
        profileFollowerIndexes[profileId][requester] = profileFollowers[profileId].length - 1;

        // remove the request
        profileData[profileId].followRequests[requester] = false;

        emit Events.FollowRequestApproved(profileId, requester);
    }

    function denyFollowRequest(
        uint256 profileId,
        address requester
    ) external onlyProfileOwner(profileId) {
        if (!profileData[profileId].isPrivate) {
            revert Errors.Diary__RequestedProfileIsNotPrivate();
        }

        if (!profileData[profileId].followRequests[requester]) {
            revert Errors.Diary__NoActiveFollowRequestForRequester();
        }

        // remove the request
        profileData[profileId].followRequests[requester] = false;

        // Assume same implementation as above for removing from the array

        emit Events.FollowRequestDenied(profileId, requester);
    }

    function areFriends(uint256 profileId1, uint256 profileId2) public view returns (bool) {
        return
            isFollowing[profileOwnedBy[profileId1]][profileId2] &&
            isFollowing[profileOwnedBy[profileId2]][profileId1];
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokenUri[id];
    }

    function requestAiAsistance(uint256 diaryTokenId, Enums.AiAssistance aiAT) private {
        // The requested diaryTokenId's visibility shall be public
        if (diaryVisibility[diaryTokenId] != Enums.DiaryVisibility.Public) {
            revert Errors.Diary__AiAssistanceOnlyOnPublicMemories();
        }
        if (aiAT == Enums.AiAssistance.MoodDetection) {
            // get tokenUri and send it to script, the script gets the markdown text of the diary and returns the detected mood
            // sample token uri
            // https://gist.githubusercontent.com/omni001s/d14b6720231e2db6b9ef78429b59ca1c/raw/280884356aedfa88879b16ab17dde306bbd462f4/diary.json
        }
    }

    // Chainlink function
    using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(bytes32 indexed requestId, bytes response, bytes err);

    function sendRequest(
        string calldata source,
        FunctionsRequest.Location secretsLocation,
        bytes calldata encryptedSecretsReference,
        string[] calldata args,
        bytes[] calldata bytesArgs,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) private {
        FunctionsRequest.Request memory req;
        req.initializeRequest(
            FunctionsRequest.Location.Inline,
            FunctionsRequest.CodeLanguage.JavaScript,
            source
        );
        req.secretsLocation = secretsLocation;
        req.encryptedSecretsReference = encryptedSecretsReference;
        if (args.length > 0) {
            req.setArgs(args);
        }
        if (bytesArgs.length > 0) {
            req.setBytesArgs(bytesArgs);
        }
        s_lastRequestId = _sendRequest(req.encodeCBOR(), subscriptionId, callbackGasLimit, s_donId);
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}
