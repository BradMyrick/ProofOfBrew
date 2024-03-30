// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BrewCoin is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ReentrancyGuard {
    uint256 private immutable INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens with 18 decimals
    uint256 private immutable PRIVATE_SALE_ALLOCATION = 20_000_000 * 10**18; // 20% allocation for private sale
    uint256 private immutable PRIVATE_SALE_PRICE = 500 * 10**18; // 0.5 AVAX per 1000 $BREW
    uint256 private immutable PRIVATE_SALE_MIN_INVESTMENT = 50 * 10**18; // Minimum investment of 50 AVAX
    uint256 private immutable PRIVATE_SALE_DURATION = 30 days; // Private sale duration of 30 days
    uint256 private immutable VESTING_CLIFF_DURATION = 30 days; // 1 month cliff 
    uint256 private immutable VESTING_DURATION = 300 days; // 10 months vesting
    uint256 private immutable VESTING_INTERVAL = VESTING_DURATION / 10;
    uint256 private immutable MAX_CLAIM_LIMIT = 1_000_000 * 10**18; // Maximum claim limit per transaction

    uint256 public privateSaleStartTime;
    uint256 public privateSaleEndTime;
    uint256 public totalPrivateSaleAllocation;  
    mapping(address => uint256) public privateSaleAllocation;
    mapping(address => uint256) public lastVestingClaimTime;
    bool public emergencyStop;

    event PrivateSalePurchase(address indexed buyer, uint256 amount);
    event VestingClaim(address indexed claimer, uint256 amount);
    event EmergencyStopTriggered(bool stopped);
    event AVAXWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Recovered(address indexed token, uint256 amount);

    constructor() ERC20("BrewCoin", "BREW") {
        _mint(address(this), INITIAL_SUPPLY);
        privateSaleStartTime = block.timestamp;
        privateSaleEndTime = privateSaleStartTime + PRIVATE_SALE_DURATION;
    }

    function buyPrivateSale() external payable whenNotPaused nonReentrant {
        require(block.timestamp >= privateSaleStartTime && block.timestamp <= privateSaleEndTime, "Private sale is not active");
        require(msg.value >= PRIVATE_SALE_MIN_INVESTMENT, "Investment amount is below the minimum requirement");
        require(totalPrivateSaleAllocation + msg.value <= PRIVATE_SALE_ALLOCATION, "Private sale allocation exceeded");

        uint256 brewAmount = (msg.value * 1000) / PRIVATE_SALE_PRICE;
        privateSaleAllocation[msg.sender] += brewAmount;
        totalPrivateSaleAllocation += brewAmount;

        emit PrivateSalePurchase(msg.sender, brewAmount);
    }

    function claimVestedTokens() external nonReentrant {
        uint256 allocation = privateSaleAllocation[msg.sender];
        require(allocation > 0, "No tokens allocated for vesting");
        require(block.timestamp > privateSaleEndTime + VESTING_CLIFF_DURATION, "Vesting cliff period not reached");

        uint256 elapsedTime = block.timestamp - (privateSaleEndTime + VESTING_CLIFF_DURATION);
        uint256 vestingIntervals = elapsedTime / VESTING_INTERVAL;
        uint256 claimableAmount = (allocation * vestingIntervals) / 10;

        if (claimableAmount > MAX_CLAIM_LIMIT) {
            claimableAmount = MAX_CLAIM_LIMIT;
        }

        if (claimableAmount > 0) {
            lastVestingClaimTime[msg.sender] = block.timestamp;
            _transfer(address(this), msg.sender, claimableAmount);
            emit VestingClaim(msg.sender, claimableAmount);
        }
    }

    function triggerEmergencyStop() external onlyOwner {
        emergencyStop = true;
        _pause();
        emit EmergencyStopTriggered(true);
    }

    function releaseEmergencyStop() external onlyOwner {
        emergencyStop = false;
        _unpause();
        emit EmergencyStopTriggered(false);
    }

    function withdrawAVAX(address payable recipient) external onlyOwner nonReentrant {
        require(recipient != address(0), "Invalid recipient address");
        uint256 amount = address(this).balance;
        recipient.transfer(amount);
        emit AVAXWithdrawn(recipient, amount);
    }

    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot recover BREW tokens");
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");
        IERC20(tokenAddress).transfer(owner(), amount);
        emit ERC20Recovered(tokenAddress, amount);
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Snapshot) {
        require(!emergencyStop, "Token transfers are halted due to emergency stop");
        super._beforeTokenTransfer(from, to, amount);
    }
}
