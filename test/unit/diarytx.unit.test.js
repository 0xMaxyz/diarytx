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

              it("Should set the right owner", async function () {
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

          describe("Profiles", () => {
              it("Should allow to make one free profile per each address", async () => {
                  //await diaryContract.connect(user1).CreateProfile("uri", false);
              });
          });
      });
