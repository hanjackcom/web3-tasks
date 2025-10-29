// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Meme {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // tax:
    uint256 public constant TOTAL_TAX_RATE = 500; // 5%

    // free tax address: 
    mapping(address => bool) private _isExcludedFromFees;

    uint256 private _maxTradeAmount;
    uint256 private _maxTradeCount;

    struct UserTransactionRecord {
        uint256 amount;
        uint256 count;
        uint256 lastTradeTime;
    }
    mapping(address => UserTransactionRecord) private _userRecords;

    mapping(address => bool) private _isExempted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        _owner = msg.sender;
        _balances[msg.sender] = totalSupply_;

        _maxTradeAmount = 100000000;
        _maxTradeCount = 5;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(_balances[msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        _validateTransactionLimits(msg.sender, value);
        _checkAndUpdateRecords(msg.sender, value);

        uint256 taxFee = value * TOTAL_TAX_RATE / 10000;
        uint256 transferAmount = value - taxFee;

        _balances[msg.sender] -= transferAmount;
        _balances[to] += transferAmount;
        emit Transfer(msg.sender, to, transferAmount);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(spender != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(_balances[from] >= value && _allowances[from][msg.sender] >= value, "Insufficient balance");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        
        _validateTransactionLimits(from, value);
        _checkAndUpdateRecords(from, value);

        uint256 taxFee = 0;
        if (!(_isExcludedFromFees[from] || _isExcludedFromFees[to])) {
            taxFee = (value * TOTAL_TAX_RATE) / 10000;
        }

        if (taxFee > 0) {
            _balances[address(this)] += taxFee;
        }

        uint256 transferAmount = value - taxFee;

        _balances[from] -= value;
        _balances[to] += transferAmount;
        _allowances[from][msg.sender] -= value;
        emit Transfer(from, to, transferAmount);
        return true;
    }

    function addExcludedFromFees(address account) public returns (bool success) {
        require(msg.sender == _owner, "Only owner can add excluded address");
        _isExcludedFromFees[account] = true;
        return true;
    }

    function removeExcludedFromFees(address account) public returns (bool success) {
        require(msg.sender == _owner, "Only owner can remove excluded address");
        _isExcludedFromFees[account] = false;
        return true;
    }

    function getCurrentDate() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }

    // trade limit
    function _checkAndUpdateRecords(address user, uint256 amount) internal {
        uint256 currentDate = getCurrentDate();
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
    function setExemption(address user, bool exempt) external {
        require(msg.sender == _owner, "Only owner can set exemption");
        _isExcludedFromFees[user] = exempt;
    }

    function _validateTransactionLimits(address sender, uint256 amount) internal view {
        if (_isExempted[sender]) {
            return;
        }

        UserTransactionRecord storage record = _userRecords[sender];
        uint256 currentDate = getCurrentDate();

        uint256 currentCount = record.lastTradeTime < currentDate ? 0 : record.count;
        uint256 currentAmount = record.lastTradeTime < currentDate ? 0 : record.amount;

        require(currentCount + 1 <= _maxTradeCount, "Exceeded max trade count for today");
        require(currentAmount + amount <= _maxTradeAmount, "Exceeded max trade amount for today");
    }

    function mint(address to, uint256 value) public returns (bool success) {
        require(msg.sender == _owner, "Only owner can mint");
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");

        _totalSupply += value;
        _balances[to] += value;
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool success) {
        require(msg.sender == _owner, "Only owner can burn");
        require(value > 0, "Invalid value");
        require(_balances[msg.sender] >= value, "Insufficient balance");

        _totalSupply -= value;
        _balances[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getIsExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }
}