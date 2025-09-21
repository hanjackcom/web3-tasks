// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

contract Voting {
    mapping (address => uint256) public votesReceived;
    address[] public candidateList;

    function vote(address _candidate) public {
        require(msg.sender != _candidate, "Can not vote for yourself.");
        if (votesReceived[_candidate] == 0) {
            candidateList.push(_candidate);
        }
        votesReceived[_candidate] += 1;
    }

    function getVotes(address _candidate) public view returns (uint256) {
        uint256 number = votesReceived[_candidate];
        return number;
    }

    function resetVotes() public {
        uint len = candidateList.length;
        for (uint i = 0; i < len; ++i) {
            if (votesReceived[candidateList[i]] > 0) {
                delete votesReceived[candidateList[i]];
            }
        }
    }
}