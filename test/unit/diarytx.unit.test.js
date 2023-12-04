const { assert, expect } = require("chai");
const { network, deployments, ethers, getNamedAccounts } = require("hardhat");
const {
    developmentChains,
    networkConfig,
} = require("../../helper-hardhat.config");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Diary Unit Tests", () => {
          let diary,
              diaryContract,
              deployer,
              user1,
              user2,
              diarySavingFee,
              diaryCoverFee,
              initUri;
          beforeEach(async () => {
              ({ deployer, user1, user2 } = await getNamedAccounts());
              await deployments.fixture("all");
              diaryContract = await ethers.getContract("Diary");
              diary = diaryContract.connect(user1);
          });
          describe("Constructor", () => {
              it("Initializes the contract", async () => {
                  diarySavingFee = await diaryContract.DiarySavingFee();
                  diaryCoverFee = await diaryContract.DiaryCoverFee();

                  assert.equal(
                      ethers.parseEther(process.env.INIT_DIARY_SAVING_FEE),
                      diarySavingFee,
                  );
                  assert.equal(
                      ethers.parseEther(process.env.INIT_COVER_FEE),
                      diaryCoverFee,
                  );
              });
          });
      });
