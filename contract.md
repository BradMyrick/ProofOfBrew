# BrewCoin (BREW)

BrewCoin is an ERC20 token designed for Proof-of-Brew Eco-Farm. It enables participation in a private token sale, vesting of purchased tokens, and includes various security and administrative features.

## Features

- **Private Sale**: Users can participate in a token private sale by purchasing BREW tokens with AVAX. The private sale has a minimum investment amount and a total allocation limit.

- **Vesting**: Tokens purchased in the private sale are subject to a vesting schedule. There is a cliff period, after which vested tokens can be claimed gradually over the vesting duration. 

- **Emergency Stop**: The contract owner can trigger an emergency stop to halt token transfers and pause the contract in case of any issues.

- **AVAX Withdrawal**: The contract owner can withdraw any AVAX balance held by the contract to a designated recipient address.

- **ERC20 Recovery**: The contract owner can recover any ERC20 tokens (except BREW) that are mistakenly sent to the contract.

- **Snapshots**: The contract owner can create snapshots of token balances at any point in time. This can be useful for various purposes like voting, airdrops, etc.

## Security

The contract incorporates various security measures:

- Uses OpenZeppelin's audited implementations of ERC20, Ownable, Pausable, and ReentrancyGuard.
- Follows the Checks-Effects-Interactions pattern to avoid reentrancy vulnerabilities.
- Uses function modifiers for access control and to enforce conditions.
- Includes an emergency stop mechanism to halt transfers if needed.
- Validates critical parameters like recipient addresses, allocation limits, vesting times, etc.

## Development

The contract is written in Solidity 0.8.17 and can be compiled, tested, and deployed using standard Ethereum development tools like Hardhat, Truffle, Remix, etc.

Before deploying, be sure to thoroughly test the contract and have it audited by reputable security experts.

## Deployment

deployment notes:
1. Deploy the BrewCoin contract, passing in any necessary constructor parameters.
2. The deployer account will be set as the owner and will have administrative privileges.
3. The contract will mint the initial token supply to itself on deployment.
4. The private sale will automatically start on deployment and last for the configured duration.

## Interact

Users can interact with the deployed contract to:

- Participate in the private sale by calling `buyPrivateSale` with the desired AVAX amount.
- Claim their vested tokens after the cliff period by calling `claimVestedTokens`.
- Transfer and manage their BREW tokens like any standard ERC20 token.

The contract owner can:

- Trigger or release an emergency stop using `triggerEmergencyStop` and `releaseEmergencyStop`.
- Withdraw contract's AVAX balance using `withdrawAVAX`.
- Recover any stuck ERC20 tokens using `recoverERC20`.
- Create balance snapshots using `snapshot`.

Refer to the contract source code for more details on each function and its parameters.