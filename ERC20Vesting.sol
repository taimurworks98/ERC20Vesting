// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @author Taimoor

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract VestingContract is Ownable {
    struct VestingSchedule {
        string title; // Vesting title
        address beneficiary; // Vesting address
        uint256 amount; // Vesting amount
        uint256 duration; // Vesting duration in seconds
        uint256 startTime; // Vesting start time in seconds
        uint256 lastClaim; // Vesting last claim in seconds
        uint256 tokensClaimed; // Vesting last claim in seconds
    }

    VestingSchedule[] public vestingSchedules;

    IERC20 public immutable tokenERC20;

    constructor(
        IERC20 _tokenERC20,
        string[] memory titles,
        address[] memory beneficiaries,
        uint256[] memory amounts,
        uint256[] memory durations
    ) {
        tokenERC20 = _tokenERC20;

        require(
            titles.length == beneficiaries.length &&
                beneficiaries.length == amounts.length &&
                amounts.length == durations.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < titles.length; i++) {
            addVestingSchedule(
                titles[i],
                beneficiaries[i],
                amounts[i],
                durations[i]
            );
        }
    }

    // The following two functions allow the contract to accept ETH deposits directly
    // from a wallet without calling a function
    event Received(address, uint256);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    fallback() external payable {}

    /// @notice This is a public addVestingSchedule function, this function adds vesting schedules in this contract
    /// @param _title This parameter indicates title of vesting
    /// @param _beneficiary This parameter indicates address receiving vesting amount
    /// @param _amount This parameter indicates token amount of vesting
    /// @param _duration This parameter indicates duration in years of vesting
    function addVestingSchedule(
        string memory _title,
        address _beneficiary,
        uint256 _amount,
        uint256 _duration
    ) public onlyOwner {
        uint256 lastClaim = block.timestamp;
        uint256 startTime = block.timestamp;
        uint256 tokensClaimed = 0;
        uint256 duration = _duration;

        VestingSchedule memory newVesting = VestingSchedule({
            title: _title,
            beneficiary: _beneficiary,
            amount: _amount,
            duration: duration,
            startTime: startTime,
            lastClaim: lastClaim,
            tokensClaimed: tokensClaimed
        });

        vestingSchedules.push(newVesting);
    }

    /// @notice This is a public releaseTokens function, this function releases tokens after vesting time is completed
    /// @param scheduleIndex This parameter indicates index of vesting
    function releaseTokens(uint256 scheduleIndex) public onlyOwner {
        require(
            tokenERC20.balanceOf(address(this)) > 0,
            "No tokens left to vest"
        );
        require(
            scheduleIndex < vestingSchedules.length,
            "Invalid schedule index"
        );
        VestingSchedule storage schedule = vestingSchedules[scheduleIndex];
        require(schedule.tokensClaimed < schedule.amount, "Vesting completed");
        require(
            block.timestamp >= schedule.lastClaim + 1 days,
            "You can't claim before 1 day"
        );
        uint256 releasableTokens = (schedule.amount / schedule.duration) / 365;
        uint256 elapsedTime = (block.timestamp - schedule.startTime);
        uint256 daysPassed = elapsedTime / 1 days;
        releasableTokens = releasableTokens * daysPassed;
        tokenERC20.transfer(schedule.beneficiary, releasableTokens);
        schedule.lastClaim = block.timestamp;
        schedule.tokensClaimed = schedule.tokensClaimed + releasableTokens;
    }

    /// @notice This is a public getTokenBalance function, this function fetch token balance in multiSigWallet
    /// @return uint256 This parameter indicates amount token holding in multiSigWallet
    function getTokenBalance() public view returns (uint256) {
        return tokenERC20.balanceOf(address(this));
    }
}
