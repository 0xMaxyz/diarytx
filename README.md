# DiaryTx (Cloudiary)

## Installation

To set up the Diary smart contract for development on your local machine, make sure you have [Node.js](https://nodejs.org/) and [npm](https://www.npmjs.com/) installed. You'll also need [Hardhat](https://hardhat.org/getting-started/) for compiling, testing, and deploying the smart contract, as well as [Next.js](https://nextjs.org/) for the frontend application.

```bash
# Clone the repository
git clone https://github.com/omni001s/diarytx.git
cd diarytx

# Install Hardhat and project dependencies
npm install

# Compile the smart contract
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to a local test network (harthat node)
npx hardhat node
```

Ensure you have copied the deployed contract address and ABI to the frontend's configuration file for it to interact correctly with the smart contract (the default config uses relative address that should work, check constants.js in ./web/context/constants.js).

## Inspiration

In the digital age, the sanctity of our personal reflections and connections can be maintained through secure, private diaries, coupled with the social fabric of modern networking. This Diary smart contract is a manifestation of privacy and connectedness, providing an immutable ledger of self-expression whilst fostering a community that can grow and connect in meaningful ways. It enables users to perpetuate their daily experiences on the blockchain and selectively share these snippets with followers, admirers, and friends in a protected and respectful manner.

## What It Does

The Diary smart contract allows users to create digital diaries tied to unique profiles, akin to social media but on the blockchain. Users can save diary entries with particular visibility settings, mint profiles, follow others' public profiles, request to follow private profiles, and approve or deny such requests. Profiles can switch between public and private settings, allowing control over visibility and access. Additionally, the contract ensures that no more than one diary entry per profile can be saved per day.

## Backend

The smart contract is written in Solidity ^0.8.20 and uses OpenZeppelin's ERC1155 for multi-token support with a mixture of custom functionality to handle profile and diary operations. Hardhat is used for development tasks like compiling, testing, and deploying the contract. The smart contract optimizes for gas efficiency through careful data structuring and making use of mappings and arrays in concert.

## Frontend

The user interface is built with Next.js, offering a responsive client-side application that interacts seamlessly with the smart contract. State management is handled efficiently to provide a smooth user experience while interacting with the Ethereum blockchain. The frontend handles tasks such as sending transactions to create diaries, manage profile visibility, and follow or unfollow other profiles. It also captures events emitted by the smart contract to update the UI accordingly.

The `.env` file shall be set for the contract to work properly, a `.env.example` file is provided in this repository that could be used to make `.env` file.
