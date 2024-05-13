// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Proof_of_Brew is ERC20, ERC20Burnable, Ownable, Pausable, ReentrancyGuard {
    uint256 private immutable INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens with 18 decimals
    uint256 private immutable PRIVATE_SALE_ALLOCATION = 20_000_000 * 10**18; // 20% allocation for private sale
    uint256 private immutable PRIVATE_SALE_PRICE = 0.5 ether; // 0.5 AVAX = 50000 BREW
    uint256 private immutable PUBLIC_SALE_PRICE = 0.00002 ether; // 0.00002 AVAX = 1 BREW
    uint256 private immutable PRIVATE_SALE_MIN_INVESTMENT = 1 * 10**18; // Minimum investment of 1 AVAX
    uint256 private immutable PRIVATE_SALE_DURATION = 30 days; // Private sale duration of 30 days
    uint256 private immutable VESTING_CLIFF_DURATION = 60 days; //  60 day cliff 
    uint256 private immutable VESTING_DURATION = 300 days; // 10 months vesting
    uint256 private immutable VESTING_INTERVAL = VESTING_DURATION / 10;
    uint256 private immutable PUBLIC_SALE_ALLOCATION = 70_000_000 * 10**18; // 70% allocation for public sale
    uint256 private immutable TEAM_ALLOCATION = 10_000_000 * 10**18; // 10% allocation for team

    uint256 public publicSaleStartTime;
    uint256 public privateSaleStartTime;
    uint256 public privateSaleEndTime;
    uint256 public totalPrivateSaleAllocation;  
    uint256 public totalPublicPurchased;
    mapping(address => uint256) public privateSaleAllocation;
    mapping(address => uint256) public lastVestingClaimTime;
    mapping (address => uint256) public totalVestedClaimed;
    bool public emergencyStop;
    bool public privateSaleFinalized;

    event PrivateSalePurchase(address indexed buyer, uint256 amount);
    event VestingClaim(address indexed claimer, uint256 amount);
    event EmergencyStopTriggered(bool stopped);
    event AVAXWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Recovered(address indexed token, uint256 amount);
    event PrivateSaleFinalized();
    event PublicSalePurchase(address indexed buyer, uint256 amount);


    constructor(uint256 privateStart) ERC20("Proof of Brew", "BREW") Ownable(msg.sender){
        require(privateStart > 0, "Private sale start time must be greater than 0");
        _mint(address(this), INITIAL_SUPPLY);
        privateSaleStartTime = privateStart;
        privateSaleEndTime = privateSaleStartTime + PRIVATE_SALE_DURATION;
        publicSaleStartTime = privateSaleEndTime + 1 days;
        // mint team allocation
        _transfer(address(this), msg.sender, TEAM_ALLOCATION);

    }

    function buyPrivateSale() external payable whenNotPaused nonReentrant {
        require(!privateSaleFinalized, "Private sale has been finalized");
        require(block.timestamp >= privateSaleStartTime && block.timestamp <= privateSaleEndTime, "Private sale is not active");
        require(msg.value >= PRIVATE_SALE_MIN_INVESTMENT, "Investment amount is below the minimum requirement");
        require(msg.value % PRIVATE_SALE_PRICE == 0, "Investment amount is not a multiple of the token price");

        uint256 brewAmount = (msg.value / PRIVATE_SALE_PRICE) * (50_000 * 10**18); // 50,000 BREW per half AVAX
        
        require(totalPrivateSaleAllocation + brewAmount <= PRIVATE_SALE_ALLOCATION, "Private sale allocation exceeded");

        privateSaleAllocation[msg.sender] += brewAmount;
        totalPrivateSaleAllocation += brewAmount;

        emit PrivateSalePurchase(msg.sender, brewAmount);
    }

    function buyPublicSale(uint256 amount) external payable whenNotPaused nonReentrant {
        require(block.timestamp >= publicSaleStartTime, "Public sale has not started yet");
        require(!privateSaleFinalized, "Private sale has been finalized");
        require(amount > 0, "Invalid amount");
        require(amount + totalPublicPurchased <= PUBLIC_SALE_ALLOCATION, "Public sale allocation exceeded");
        require(msg.value == amount * PUBLIC_SALE_PRICE, "Invalid payment amount");
        totalPublicPurchased += amount;
        _transfer(address(this), msg.sender, amount);
        emit PublicSalePurchase(msg.sender, amount);
    }

    function finalizePrivateSale() external onlyOwner {
        require(block.timestamp > privateSaleEndTime, "Private sale period has not ended yet");
        privateSaleFinalized = true;
        emit PrivateSaleFinalized();
    }

    function claimVestedTokens() external nonReentrant {
        require(privateSaleFinalized, "Private sale not finalized");
        uint256 allocation = privateSaleAllocation[msg.sender];
        require(allocation > 0, "No tokens allocated for vesting");
        require(block.timestamp > privateSaleEndTime + VESTING_CLIFF_DURATION, "Vesting cliff period not reached");
        if (lastVestingClaimTime[msg.sender] == 0) {
            lastVestingClaimTime[msg.sender] = privateSaleEndTime;
        }
        uint256 elapsedTime = block.timestamp - lastVestingClaimTime[msg.sender];

        uint256 vestingIntervals = elapsedTime / VESTING_INTERVAL;
        
        require(vestingIntervals > 0, "No vested tokens currently available");

        uint256 claimableAmount = (allocation * vestingIntervals) / 10;
        uint256 maxClaimable = allocation - totalVestedClaimed[msg.sender];
        claimableAmount = claimableAmount > maxClaimable ? maxClaimable : claimableAmount;

        if (claimableAmount > 0) {
            totalVestedClaimed[msg.sender] += claimableAmount;
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

}
