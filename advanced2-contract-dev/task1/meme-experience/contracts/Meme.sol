// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Meme2 is ERC20, Ownable {
    uint256 public constant MAX_TRADE_AMOUNT = 100000000;
    uint256 public constant MAX_TRADE_COUNT = 5;
    uint256 public constant TOTAL_TAX_RATE = 500; // tax: 5%
    mapping(address => bool) private _isExcludedFromFees; // free tax address

    struct UserTransactionRecord {
        uint256 amount;
        uint256 count;
        uint256 lastTradeTime;
    }

    mapping(address => UserTransactionRecord) private _userRecords;
    mapping(address => bool) private _isExemptedLimit; // free limit

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(owner(), totalSupply_)
    }

    function transfer(address to, uint256 value) public override returns (bool success) {
        require(balanceOf(msg.sender) >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        _validateTransactionLimits(msg.sender, value);
        _checkAndUpdateRecords(msg.sender, value);

        uint256 taxFee = 0;
        if (!(_isExcludedFromFees[msg.sender] || _isExcludedFromFees[to])) {
            taxFee = (value * TOTAL_TAX_RATE) / 10000;
        }
        uint256 transferAmount = value - taxFee;

        if (taxFee > 0) {
            // super.transfer(address(this), taxFee);
            _burn(msg.sender, taxFee);
        }
        return super.transfer(to, transferAmount);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        require(balanceOf(from) >= value && allowance(from, msg.sender) >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        
        _validateTransactionLimits(from, value);
        _checkAndUpdateRecords(from, value);

        uint256 taxFee = 0;
        if (!(_isExcludedFromFees[from] || _isExcludedFromFees[to])) {
            taxFee = (value * TOTAL_TAX_RATE) / 10000;
        }
        uint256 transferAmount = value - taxFee;

        if (taxFee > 0) {
            // super.transferFrom(from, address(this), taxFee);
            _burn(from, taxFee);
        }
        return super.transferFrom(from, to, transferAmount);
    }

    function _getCurrentDate() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }

    // trade limit
    function _checkAndUpdateRecords(address user, uint256 amount) internal {
        uint256 currentDate = _getCurrentDate();
        UserTransactionRecord storage record = _userRecords[user];

        // reset daily record if a new day
        if (record.lastTradeTime < currentDate) {
            record.count = 0;
            record.amount = 0;
            record.lastTradeTime = currentDate;
        }

        // update record
        record.count += 1;
        record.amount += amount;
    }

    // verify trade limit
    // admin function: set/cancel exempted address
    function setExemption(address user, bool exempt) onlyOwner() external {
        _isExemptedLimit[user] = exempt;
    }

    function getExemption(address user) external {
        return _isExemptedLimit[user];
    }

    function _validateTransactionLimits(address sender, uint256 amount) internal view {
        if (_isExemptedLimit[sender]) {
            return;
        }

        UserTransactionRecord storage record = _userRecords[sender];
        uint256 currentDate = _getCurrentDate();

        uint256 currentCount = record.lastTradeTime < currentDate ? 0 : record.count;
        uint256 currentAmount = record.lastTradeTime < currentDate ? 0 : record.amount;

        require(currentCount + 1 <= MAX_TRADE_COUNT, "Exceeded max trade count for today");
        require(currentAmount + amount <= MAX_TRADE_AMOUNT, "Exceeded max trade amount for today");
    }

    function setIsExcludedFromFees(address account, bool exempt) onlyOwner() external {
        _isExcludedFromFees[account] = exempt;
    }

    function getIsExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
}