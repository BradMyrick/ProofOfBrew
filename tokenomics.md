# Proof of Brew Smart Contract

## Overview
The Proof of Brew smart contract is designed for the Avalanche blockchain, utilizing Solidity version 0.8.25. It incorporates features from OpenZeppelin's libraries, including ERC20 standard functionalities, burnable tokens, ownership management, pausability, and reentrancy guards to ensure secure transactions. This contract manages the issuance and distribution of the "BREW" token, particularly focusing on private and public sales. There is also a vesting mechanism for private sale participants, allowing them to claim their tokens over a 10 month period, in 10 equal installments.

## Features
- **ERC20 Token**: Implements a standard ERC20 token with additional burnable functionality.
- **Ownership and Access Control**: Utilizes OpenZeppelin's `Ownable` for ownership management.
- **Pausable**: Contract operations can be paused and resumed by the owner, enhancing security and operational control.
- **Reentrancy Guard**: Protects against reentrancy attacks during token purchase and vesting claim operations.

## Tokenomics
- **Initial Supply**: 100 million BREW tokens.
- **Private Sale Allocation**: 20 million tokens. (Vested over 10 months)
- **Public Sale Allocation**: 70 million tokens.
- **Team Allocation**: 10 million tokens reserved for the team.

### Pricing and Sale Details
- **Private Sale Price**: 0.5 AVAX per 50,000 BREW. (Vested over 10 months)
- **Public Sale Price**: 0.00002 AVAX per BREW.
- **Minimum Private Sale Investment**: 1 AVAX.

### Vesting Schedule
- **Cliff Duration**: 60 days.
- **Total Vesting Duration**: 300 days, with tokens released in 10 equal intervals.

## Functions

### Constructor
Initializes the contract with the private sale start time and mints the initial supply and team allocation.

### buyPrivateSale
Allows users to purchase BREW tokens during the private sale period, adhering to specified conditions such as minimum investment and sale timing.

### buyPublicSale
Enables public purchase of BREW tokens post-private sale, ensuring compliance with public sale conditions and allocation limits.

### finalizePrivateSale
Marks the end of the private sale and prevents further private purchases.

### claimVestedTokens
Allows users to claim their vested tokens after the cliff period, based on the predefined vesting schedule.

### Emergency Controls
- **triggerEmergencyStop**: Pauses contract operations in case of an emergency.
- **releaseEmergencyStop**: Resumes contract operations post-emergency.

### Financial Operations
- **withdrawAVAX**: Withdraws collected AVAX funds to a specified recipient.
- **recoverERC20**: Recovers ERC20 tokens accidentally sent to the contract.

## Events
- **PrivateSalePurchase**: Logs purchases made during the private sale.
- **PublicSalePurchase**: Logs purchases made during the public sale.
- **VestingClaim**: Logs vested tokens claimed by users.
- **EmergencyStopTriggered**: Indicates the contract's paused or unpaused state.
- **AVAXWithdrawn**: Logs AVAX withdrawals by the owner.
- **ERC20Recovered**: Logs recovery of non-BREW ERC20 tokens.

## Security Features
The contract incorporates several security measures:
- **Pausable**: Enhances control over contract functionality, allowing operations to be halted in suspicious circumstances.
- **ReentrancyGuard**: Prevents reentrant calls to sensitive functions, protecting against certain types of logical errors in contract interactions.
- **Ownership Controls**: Restricts critical administrative functions to the contract owner, mitigating the risk of unauthorized access.
