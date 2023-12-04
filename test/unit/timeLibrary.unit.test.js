const { expect } = require("chai");
const { ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat.config.js");
const { readFile } = require("fs").promises;
const path = require("node:path");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Time Library", () => {
          function RandBetween(min, max) {
              return Math.floor(Math.random() * (max - min + 1) + min);
          }
          it("Correctly parses epoch unix time", async () => {
              let abi, bytecode;
              await readFile(
                  path.resolve(
                      __dirname,
                      "../../artifacts/contracts/src/libraries/Date.sol/Date.json",
                  ),
                  (err, data) => {
                      if (err) throw err;
                      console.log(data);
                  },
              ).then((contents) => {
                  var artifact = JSON.parse(contents);
                  abi = JSON.stringify(artifact.abi);
                  bytecode = JSON.stringify(artifact.bytecode)
                      .split('"')
                      .filter((i) => i)[0];
              });
              if (abi.length > 10) {
                  const deployer = (await ethers.getSigners())[0];

                  const factory = new ethers.ContractFactory(
                      abi,
                      bytecode,
                      deployer,
                  );
                  const lib = await factory.deploy();

                  // make random date, convert it to epoch unix time and get date from chain
                  const year = RandBetween(1970, 2300);
                  const month = RandBetween(1, 12);
                  const day = RandBetween(1, 29);

                  const epochUnixTime =
                      new Date(year, month - 1, day + 1).getTime() / 1000;

                  dateFromChain = await lib.GetDate(epochUnixTime);

                  expect(day.toString()).to.be.equal(
                      dateFromChain.day.toString(),
                  );
                  expect(month.toString()).to.be.equal(
                      dateFromChain.month.toString(),
                  );
                  expect(year.toString()).to.be.equal(
                      dateFromChain.year.toString(),
                  );
              } else {
                  console.log(
                      'The visibility of GetDate function shall be external for this test to run, change the visibility to external and run\n yarn hardhat test --grep "Correctly parses epoch unix time"',
                  );
              }
          });
      });
