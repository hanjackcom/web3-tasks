// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract BeggingContract {
    address private immutable owner;
    mapping(address => uint256) private donations;
    address[] private allDonors;
    uint256 public donationStartTime;
    uint256 public donationEndTime;

    event Donation(address indexed donor, uint256 amount, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyDuringDonationPeriod() {
        require(block.timestamp >= donationStartTime && block.timestamp <= donationEndTime, "Donations are not allowed at this time");
        _;
    }

    constructor(uint256 _donationDurationInDays) {
        owner = msg.sender;
        donationStartTime = block.timestamp;
        donationEndTime = block.timestamp + (_donationDurationInDays * 1 days);
    }

    function donate() external payable onlyDuringDonationPeriod {
        require(msg.value > 0, "Donation amount must be greater than 0");

        if (donations[msg.sender] == 0) {
            allDonors.push(msg.sender);
        }

        donations[msg.sender] += msg.value;

        emit Donation(msg.sender, msg.value, block.timestamp);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to windraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }

    function getTop3Donors() external view returns (address[3] memory top3Donors, uint256[3] memory top3Amounts) {
        top3Donors = [address(0), address(0), address(0)];
        top3Amounts = [uint256(0), uint256(0), uint256(0)];

        for (uint256 i = 0; i < allDonors.length; ++i) {
            address donor = allDonors[i];
            uint256 amount = donations[donor];

            for (uint256 j = 0; j < 3; ++j) {
                if (amount > top3Amounts[j]) {
                    for (uint256 k = 2; k > j; --k) {
                        top3Donors[k] = top3Donors[k-1];
                        top3Amounts[k] = top3Amounts[k-1];
                    }
                    top3Donors[j] = donor;
                    top3Amounts[j] = amount;
                    break;
                }
            }
        }
    }

    function updateDonationPeriod(uint256 _newDurationInDays) external onlyOwner {
        donationEndTime = block.timestamp + (_newDurationInDays * 1 days);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function isDonationActive() external view returns (bool) {
        return block.timestamp >= donationStartTime && block.timestamp <= donationEndTime;
    }
}