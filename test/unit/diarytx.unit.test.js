const { assert, expect } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat.config");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("DiaryTx Unit Tests", () => {
          let diaryContract,
              deployer,
              user1,
              user2,
              diarySavingFee,
              diaryCoverFee,
              initUri,
              txnReceipt;
          beforeEach(async () => {
              ({ deployer, user1, user2 } = await getNamedAccounts());
              const fixt = await deployments.fixture("all");

              diaryContract = await ethers.getContract("Diary");

              txnReceipt = await ethers.provider.getTransactionReceipt(
                  fixt.Diary.receipt.transactionHash,
              );
          });

          describe("Deployment", () => {
              it("Initializes the contract", async () => {
                  diarySavingFee = await diaryContract.DiarySavingFee();
                  diaryCoverFee = await diaryContract.DiaryCoverFee();

                  assert.equal(
                      ethers.parseEther(process.env.INIT_DIARY_SAVING_FEE),
                      diarySavingFee,
                  );
                  assert.equal(ethers.parseEther(process.env.INIT_COVER_FEE), diaryCoverFee);
              });

              it("Should set the right owner", async () => {
                  expect(await diaryContract.owner()).to.equal(deployer);
              });

              it("Should make a public profile for the owner", async () => {
                  // ProfileMint event signature
                  const profileMintEventSignature = ethers.id(
                      "ProfileMint(address,uint256,string)",
                  );

                  // loop through the transaction receipt logs
                  for (const log of txnReceipt.logs) {
                      // Find ProfileMint event signature from transaction receipt logs
                      if (log.topics[0] === profileMintEventSignature) {
                          // Decode and extract the event parameters
                          const decodedEvent = diaryContract.interface.decodeEventLog(
                              "ProfileMint",
                              log.data,
                              log.topics,
                          );
                          // Access the event parameters directly
                          const minterAddress = decodedEvent[0];
                          const tokenId = decodedEvent[1];
                          const hashedTokenUri = decodedEvent[2];

                          var hashedInputUri = ethers.keccak256(
                              ethers.toUtf8Bytes(process.env.INIT_URI),
                          );

                          const firstPublicProfile = await diaryContract.publicProfileIds(0);

                          assert(minterAddress == deployer);
                          assert(hashedTokenUri.hash == hashedInputUri);
                          assert(tokenId == firstPublicProfile);
                      }
                  }
              });

              it("It should mint 1000 follower tokens for the owner", async () => {
                  const followerTokenCount = await diaryContract.balanceOf(deployer, 1);
                  assert(followerTokenCount == 1000);
              });
          });

          describe("CreateProfile", () => {
              const ADDITIONAL_PROFILE_FEE = ethers.parseEther("100");
              const profileUri = "profileUri";

              it("Allows user without a profile to create one without a fee", async () => {
                  user1Signer = await ethers.getSigner(user1);

                  const tx = await diaryContract
                      .connect(user1Signer)
                      .CreateProfile(profileUri, false);
                  const txnReceipt = await tx.wait(1);

                  // ProfileMint event signature
                  const profileMintEventSignature = ethers.id(
                      "ProfileMint(address,uint256,string)",
                  );

                  // loop through the transaction receipt logs
                  for (const log of txnReceipt.logs) {
                      // Find ProfileMint event signature from transaction receipt logs
                      if (log.topics[0] === profileMintEventSignature) {
                          // Decode and extract the event parameters
                          const decodedEvent = diaryContract.interface.decodeEventLog(
                              "ProfileMint",
                              log.data,
                              log.topics,
                          );
                          // Access the event parameters directly
                          const minterAddress = decodedEvent[0];
                          const tokenId = decodedEvent[1];
                          const hashedTokenUri = decodedEvent[2];

                          var hashedInputUri = ethers.keccak256(ethers.toUtf8Bytes(profileUri));

                          const secondPublicProfile = await diaryContract.publicProfileIds(1);

                          assert(minterAddress == user1);
                          assert(hashedTokenUri.hash == hashedInputUri);
                          assert(tokenId == secondPublicProfile);
                      }
                  }
              });

              it("Allows user with a profile to create an additional one with sufficient fee", async () => {
                  // User creates initial profile without fee
                  user1Signer = await ethers.getSigner(user1);

                  const tx = await diaryContract
                      .connect(user1Signer)
                      .CreateProfile(profileUri, false);
                  await tx.wait(1);

                  // User attempts to create an additional profile with fee
                  const txWithFee = await diaryContract
                      .connect(user1Signer)
                      .CreateProfile(profileUri, false, {
                          value: ADDITIONAL_PROFILE_FEE,
                      });
                  const txnReceipt = await txWithFee.wait(1);

                  // ProfileMint event signature
                  const profileMintEventSignature = ethers.id(
                      "ProfileMint(address,uint256,string)",
                  );

                  // loop through the transaction receipt logs
                  for (const log of txnReceipt.logs) {
                      // Find ProfileMint event signature from transaction receipt logs
                      if (log.topics[0] === profileMintEventSignature) {
                          // Decode and extract the event parameters
                          const decodedEvent = diaryContract.interface.decodeEventLog(
                              "ProfileMint",
                              log.data,
                              log.topics,
                          );
                          // Access the event parameters directly
                          const minterAddress = decodedEvent[0];
                          const tokenId = decodedEvent[1];
                          const hashedTokenUri = decodedEvent[2];

                          var hashedInputUri = ethers.keccak256(ethers.toUtf8Bytes(profileUri));

                          const thirdPublicProfile = await diaryContract.publicProfileIds(2);

                          assert(minterAddress == user1);
                          assert(hashedTokenUri.hash == hashedInputUri);
                          assert(tokenId == thirdPublicProfile);
                      }
                  }
              });

              it("Reverts if user with a profile does not pay sufficient fee for an additional one", async () => {
                  // User creates initial profile without fee
                  user1Signer = await ethers.getSigner(user1);

                  const tx = await diaryContract
                      .connect(user1Signer)
                      .CreateProfile(profileUri, false);
                  await tx.wait(1);

                  // User attempts to create an additional profile without paying the ADDITIONAL_PROFILE_FEE
                  await expect(diaryContract.connect(user1Signer).CreateProfile(profileUri, false))
                      .to.be.reverted;
              });
          });

          describe("CreateDiary", () => {
              let ownerProfileId;
              const diaryUri = "diaryUri";
              const DiarySavingFee = ethers.parseEther(process.env.INIT_DIARY_SAVING_FEE);
              beforeEach(async () => {
                  ownerProfileId = await diaryContract.publicProfileIds(0);
              });

              it("Allows an owned profile to create a diary without a fee if no diaries exist for the date", async () => {
                  await expect(diaryContract.CreateDiary(ownerProfileId, diaryUri, 0)).to.emit(
                      diaryContract,
                      "DiaryCreated",
                  );
              });

              it("Reverts when a diary creation is attempted from a non-owned profile", async () => {
                  user1Signed = await ethers.getSigner(user1);
                  await expect(
                      diaryContract.connect(user1Signed).CreateDiary(ownerProfileId, diaryUri, 0),
                  ).to.be.revertedWithCustomError(diaryContract, "Diary__ProfileNotOwnedByYou");
              });

              it("Allows a diary to be created with additional fee if diaries already exist for the date", async () => {
                  // Create initial diary
                  await diaryContract.CreateDiary(ownerProfileId, diaryUri, 0);

                  // Attempt to create another diary on the same date with an additional saving fee
                  await expect(
                      diaryContract.CreateDiary(ownerProfileId, diaryUri, 0, {
                          value: DiarySavingFee,
                      }),
                  ).to.emit(diaryContract, "DiaryCreated");
              });

              it("Reverts if a diary is attempted to be created on the same date without the additional fee", async () => {
                  // Create initial diary
                  await diaryContract.CreateDiary(ownerProfileId, diaryUri, 0);

                  // Attempt to create another diary on the same date without the additional saving fee
                  await expect(
                      diaryContract.CreateDiary(ownerProfileId, diaryUri, 0),
                  ).to.be.revertedWithCustomError(diaryContract, "Diary__InsufficientFee");
              });
          });

          describe("Buy Follower Tokens", () => {
              const followerTokenPrice = ethers.parseEther("1");
              const FOLLOWER_PRICE_PER_QUANTITY = ethers.toBigInt(100);
              const discountRate = ethers.toBigInt(10);
              const FOLLOWER_TOKEN_ID = ethers.toBigInt(1);

              it("Allows a user to buy follower tokens at the correct price", async () => {
                  const quantity = ethers.toBigInt(1000);
                  const totalPrice = (followerTokenPrice * quantity) / FOLLOWER_PRICE_PER_QUANTITY;

                  await expect(
                      diaryContract.buyFollowerTokens(quantity, { value: totalPrice }),
                  ).to.emit(diaryContract, "TransferSingle");

                  expect(await diaryContract.balanceOf(deployer, FOLLOWER_TOKEN_ID)).to.be.equal(
                      2000,
                  );
              });

              it("Applies a discount when a user buys follower tokens in bulk", async () => {
                  const quantity = FOLLOWER_PRICE_PER_QUANTITY * ethers.toBigInt(10);
                  let totalPrice = (followerTokenPrice * quantity) / FOLLOWER_PRICE_PER_QUANTITY;

                  totalPrice =
                      totalPrice - (totalPrice * discountRate) / FOLLOWER_PRICE_PER_QUANTITY;

                  await expect(
                      diaryContract.buyFollowerTokens(quantity, { value: totalPrice }),
                  ).to.emit(diaryContract, "TransferSingle");
              });

              it("Reverts when not enough ether is sent to buy the desired quantity of follower tokens", async () => {
                  const quantity = ethers.toBigInt(1000);
                  const insufficientValue = ethers.toBigInt(1);

                  await expect(
                      diaryContract.buyFollowerTokens(quantity, { value: insufficientValue }),
                  ).to.be.revertedWithCustomError(diaryContract, "Diary__InsufficientFee");
              });

              it("Mints the correct quantity of follower tokens", async () => {
                  const quantity = ethers.toBigInt(3);
                  const totalPrice = (followerTokenPrice * quantity) / FOLLOWER_PRICE_PER_QUANTITY;

                  await diaryContract.buyFollowerTokens(quantity, { value: totalPrice });
                  const balance = await diaryContract.balanceOf(deployer, FOLLOWER_TOKEN_ID);

                  expect(balance).to.equal(quantity + ethers.toBigInt(1000));
              });
          });
      });
