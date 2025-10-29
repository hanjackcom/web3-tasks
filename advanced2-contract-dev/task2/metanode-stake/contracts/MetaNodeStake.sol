// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MetaNodeStake is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using Address for address;
    using Math for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    uint256 public constant ETH_PID = 0;

    struct Pool {
        // stake token's pool address
        address poolAddress;
        uint256 poolWeight;
        uint256 minDepositAmount;
        // last updated block height
        uint256 lastRewardBlock;
        uint256 accMetaNodePerST;
        uint256 stTokenAmount;
        // wait for some locked block while unstaking, in case run on banks
        uint256 unstakeLockedBlocks;
    }

    struct UnstakeRequest {
        uint256 amount;
        uint256 unlockBlock;
    }

    struct User {
        // stake amount
        uint256 amount;
        // have got reward totals
        uint256 finishedMetaNode;
        // pending gain reward
        uint256 pendingMetaNode;
        UnstakeRequest[] requests;
    }

    Pool[] public pools;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public metaNodePerBlock; // reward of per block

    bool public withdrawPaused;
    bool public claimPaused;

    uint256 public totalWeight;

    IERC20 public MetaNode;

    mapping(uint256 => mapping(address => User)) public users;

    modifier checkPid(uint256 pid_) {
        require(pid_ < pools.length, "Invalid pid");
        _;
    }

    modifier whenNotWithdrawPaused() {
        require(!withdrawPaused, "Withdraw is paused");
        _;
    }

    modifier whenNotClaimPaused() {
        require(!claimPaused, "Claim is paused");
        _;
    }

    function initialize(
        address metaNodeAddress_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 metaNodePerBlock_
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        setMetaNode(metaNodeAddress_);

        startBlock = startBlock_;
        endBlock = endBlock_;
        metaNodePerBlock = metaNodePerBlock_;
    }

    function updatePool(
        uint256 pid_,
        uint256 minDepositAmount_,
        uint256 unstakeLockedBlocks_
    ) public onlyRole(ADMIN_ROLE) checkPid(pid_) {
        pools[pid_].minDepositAmount = minDepositAmount_;
        pools[pid_].unstakeLockedBlocks = unstakeLockedBlocks_;
    }

    function setMetaNodePerBlock(uint256 metaNodePerBlock_) public onlyRole(ADMIN_ROLE) {
        metaNodePerBlock = metaNodePerBlock_;
    }

    function setStartBlock(uint256 startBlock_) public onlyRole(ADMIN_ROLE) {
        require(startBlock_ <= endBlock, "Start block must be greater than current start block");
        startBlock = startBlock_;
    }

    function setEndBlock(uint256 endBlock_) public onlyRole(ADMIN_ROLE) {
        require(endBlock_ >= startBlock, "End block must be greater than current end block");
        endBlock = endBlock_;
    }

    function poolLength() public view returns (uint256) {
        return pools.length;
    }

    function pendingMetaNode(
        uint256 pid_,
        address user_
    ) public view checkPid(pid_) returns (uint256) {
        return pendingMetaNodeByBlockNumber(pid_, user_, block.number);
    }

    function pendingMetaNodeByBlockNumber(
        uint256 pid_,
        address user_,
        uint256 blockNumber_
    ) public view checkPid(pid_) returns (uint256) {
        Pool storage pool_ = pools[pid_];
        User storage user1_ = users[pid_][user_];

        uint256 accMetaNodePerST = pool_.accMetaNodePerST;
        uint256 stSupply = pool_.stTokenAmount;

        if (blockNumber_ > pool_.lastRewardBlock) {
            uint256 multiplier = getMultiplier(blockNumber_, pool_.lastRewardBlock);
            // according to weight, total metanode amount assgined of this pool
            uint256 metaNodeForPool = multiplier * pool_.poolWeight / totalWeight;
            // assign metanode, according to stake ratio
            accMetaNodePerST = accMetaNodePerST  + metaNodeForPool * (1 ether) / stSupply;
        }

        return user1_.amount * accMetaNodePerST / (1 ether) - user1_.finishedMetaNode + user1_.pendingMetaNode;
    }

    function pausedWithdraw() public onlyRole(ADMIN_ROLE) {
        require(!withdrawPaused, "Withdraw is already paused");
        withdrawPaused = true;
    }

    function pauseClaim() public onlyRole(ADMIN_ROLE) {
        require(!claimPaused, "Claim is already paused");
        claimPaused = true;
    }

    function unpauseWithdraw() public onlyRole(ADMIN_ROLE) {
        require(withdrawPaused, "Withdraw is not paused");
        withdrawPaused = false;
    }

    function unpauseClaim() public onlyRole(ADMIN_ROLE) {
        require(claimPaused, "Claim is not paused");
        claimPaused = false;
    }

    function _authorizeUpgrade(address newImplementation_) internal override onlyRole(UPGRADER_ROLE) {}

    function setMetaNode(address metaNodeAddress_) public onlyRole(ADMIN_ROLE) {
        MetaNode = IERC20(metaNodeAddress_);
    }

    function setPoolWeight(
        uint256 pid_,
        uint256 poolWeight_,
        bool withUpdate_
    ) public onlyRole(ADMIN_ROLE) checkPid(pid_) {
        require(poolWeight_ > 0, "Pool weight must be greater than 0");

        if (withUpdate_) {
            massUpdatePools();
        }

        totalWeight = totalWeight - pools[pid_].poolWeight + poolWeight_;
        pools[pid_].poolWeight = poolWeight_;
    } 

    function stakingBalance(
        uint256 pid_,
        address user_
    ) public view checkPid(pid_) returns (uint256) {
        return users[pid_][user_].amount;
    }

    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 i = 0; i < length; i++) {
            updatePool(i);
        }
    }

    function addPool(
        address poolAddress_,
        uint256 poolWeight_,
        uint256 minDepositAmount_,
        uint256 unstakeLockedBlocks_
    ) public onlyRole(ADMIN_ROLE) {
        if (pools.length > 0) {
            require(poolAddress_ != address(0), "Pool address cannot be zero");
        } else {
            require(poolAddress_ == address(0), "Pool address cannot be zero");
        }

        uint256 lastBlock = block.number > startBlock ? block.number : startBlock;
        totalWeight += poolWeight_;

        pools.push(Pool({
            poolAddress: poolAddress_,
            poolWeight: poolWeight_,
            minDepositAmount: minDepositAmount_,
            lastRewardBlock: lastBlock,
            accMetaNodePerST: 0,
            stTokenAmount: 0,
            unstakeLockedBlocks: unstakeLockedBlocks_
        }));
    }

    function depositETH() public payable {
        Pool storage pool_ = pools[ETH_PID];
        require(pool_.poolAddress == address(0x0), "ETH staking is full");

        uint256 amount_ = msg.value;
        require(amount_ >= pool_.minDepositAmount, "Amount must be greater than min deposit amount");

        _deposit(ETH_PID, amount_);
    }

    function deposit(
        uint256 pid_,
        uint256 amount_
    ) public checkPid(pid_) {
        require(pid_ != 0, "deposit not support ETH staking");
        Pool storage pool_ = pools[pid_];
        require(amount_ > pool_.minDepositAmount, "Amount must be greater than min deposit amount");
        if (amount_ > 0) {
            IERC20(pool_.poolAddress).safeTransferFrom(msg.sender, address(this), amount_);
        }

        _deposit(pid_, amount_);
    }

    function _deposit(
        uint256 pid_,
        uint256 amount_
    ) internal checkPid(pid_) {
        Pool storage pool_ = pools[pid_];
        User storage user_ = users[pid_][msg.sender];

        updatePool(pid_);
        if (user_.amount > 0) {
            (bool succ1, uint256 accSTAmount) = user_.amount.tryMul(pool_.accMetaNodePerST);
            require(succ1, "AccSTAmount overflow");

            (bool succ2, uint256 pendingMetaNode2_) = accSTAmount.trySub(user_.finishedMetaNode);
            require(succ2, "Pending overflow");

            if (pendingMetaNode2_ > 0) {
                (bool succ3, uint256 pendingMetaNode3_) = pendingMetaNode2_.tryAdd(user_.pendingMetaNode);
                require(succ3, "PendingMetaNode overflow");
                user_.pendingMetaNode = pendingMetaNode3_;
            }
        }

        if (amount_ > 0) {
            (bool succ4, uint256 userAmount) = amount_.tryAdd(user_.amount);
            require(succ4, "UserAmount overflow");
            user_.amount = userAmount;
        }

        (bool succ5, uint256 stTokenAmount) = amount_.tryAdd(pool_.stTokenAmount);
        require(succ5, "StTokenAmount overflow");
        pool_.stTokenAmount = stTokenAmount;

        (bool succ6, uint256 finishedMetaNode) = user_.amount.tryMul(pool_.accMetaNodePerST);
        require(succ6, "AccMetaNodePerST overflow");
        user_.finishedMetaNode = finishedMetaNode;
    }

    function updatePool(uint256 pid_) internal checkPid(pid_) {
        Pool storage pool_ = pools[pid_];

        if (block.number <= pool_.lastRewardBlock) {
            return;
        }

        (bool succ, uint256 totalMetaNode) = getMultiplier(block.number, pool_.lastRewardBlock).tryMul(pool_.poolWeight);
        require(succ, "Multiplier overflow");

        (succ, totalMetaNode) = totalMetaNode.tryDiv(totalWeight);
        require(succ, "MetaNodePerST overflow");

        uint256 stSupply = pool_.stTokenAmount;
        if (stSupply > 0) {
            (bool succ2, uint256 totalMetaNode_) = totalMetaNode.tryMul(1 ether);
            require(succ2, "TotalMetaNode overflow");

            (succ2, totalMetaNode_) = totalMetaNode_.tryDiv(stSupply);
            require(succ2, "MetaNodePerST overflow");

            (bool succ3, uint256 accMetaNodePerST_) = pool_.accMetaNodePerST.tryAdd(totalMetaNode_);
            require(succ3, "AccMetaNodePerST overflow");
            pool_.accMetaNodePerST = accMetaNodePerST_;
        }

        pool_.lastRewardBlock = block.number;
    }

    function getMultiplier(
        uint256 lastBlock_,
        uint256 startBlock_
    ) public view returns (uint256 multiplier) {
        require(lastBlock_ >= startBlock_, "Last block must be greater than start block");
        if (lastBlock_ > endBlock) {
            lastBlock_ = endBlock;
        }
        if (startBlock_ < startBlock) {
            startBlock_ = startBlock;
        }

        require(startBlock_ < lastBlock_, "Start block must be less than last block");
        bool succ;
        (succ, multiplier) = (lastBlock_ - startBlock_).tryMul(metaNodePerBlock);
        require(succ, "Multiplier overflow");
    }

    function unstake(
        uint256 pid_,
        uint256 amount_
    ) public checkPid(pid_) {
        Pool storage pool_ = pools[pid_];
        User storage user_ = users[pid_][msg.sender];

        require(amount_ <= user_.amount, "Amount must be greater than user amount");

        updatePool(pid_);

        uint256 pendingMetaNode_ = user_.amount * pool_.accMetaNodePerST / (1 ether) - user_.finishedMetaNode;

        if (pendingMetaNode_ > 0) {
            user_.pendingMetaNode = pendingMetaNode_;
        }

        if (amount_ > 0) {
            user_.amount -= amount_;
            user_.requests.push(UnstakeRequest({
                amount: amount_,
                unlockBlock: block.number + pool_.unstakeLockedBlocks
            }));
        }

        pool_.stTokenAmount -= amount_;
        user_.finishedMetaNode = user_.amount * pool_.accMetaNodePerST / (1 ether);
    }

    function withdraw(uint256 pid_) public checkPid(pid_) whenNotWithdrawPaused {
        Pool storage pool_ = pools[pid_];
        User storage user_ = users[pid_][msg.sender];

        uint256 pendingWithdraw_ = 0;
        uint256 popNum_ = 0;
        for (uint256 i = 0; i < user_.requests.length; i++) {
            if (user_.requests[i].unlockBlock > block.number) {
                break;
            }

            pendingWithdraw_ += user_.requests[i].amount;
            popNum_++;
        }

        for (uint256 i = 0; i < user_.requests.length - popNum_; i++) {
            user_.requests[i] = user_.requests[i + popNum_];
        }

        for (uint256 i = 0; i < popNum_; i++) {
            user_.requests.pop();
        }

        if (pendingWithdraw_ > 0) {
            if (pool_.poolAddress == address(0x0)) {
                _safeETHTransfer(msg.sender, pendingWithdraw_);
            } else {
                IERC20(pool_.poolAddress).safeTransfer(msg.sender, pendingWithdraw_);
            }
        }
    }

    function withdrawAmount(
        uint256 pid_,
        address user_
    ) public view checkPid(pid_) returns (uint256 requestAmount, uint256 pendingWithdrawAmount) {
        User storage user1_ = users[pid_][user_];

        for (uint256 i = 0; i < user1_.requests.length; i++) {
            if (user1_.requests[i].unlockBlock < block.number) {
                pendingWithdrawAmount += user1_.requests[i].amount;
            }

            requestAmount += user1_.requests[i].amount;
        }
    }

    function claim(uint256 pid_) public checkPid(pid_) whenNotClaimPaused {
        Pool storage pool_ = pools[pid_];
        User storage user_ = users[pid_][msg.sender];

        updatePool(pid_);

        uint256 pendingMetaNode_ = user_.amount * pool_.accMetaNodePerST / (1 ether) - user_.finishedMetaNode + user_.pendingMetaNode;

        if (pendingMetaNode_ > 0) {
            user_.pendingMetaNode = 0;
            _safeMetaNodeTransfer(msg.sender, pendingMetaNode_);
        }

        user_.finishedMetaNode = user_.amount * pool_.accMetaNodePerST / (1 ether);
    }

    function _safeETHTransfer(
        address to_,
        uint256 amount_
    ) internal {
        (bool succ, bytes memory data) = address(to_).call{value: amount_}("");
        require(succ, "ETH tranfer failed");

        if (data.length > 0) {
            require(abi.decode(data, (bool)), "ETH tranfer operation did not succeed");
        }
    }

    function _safeMetaNodeTransfer(
        address to_,
        uint256 amount_
    ) internal {
        uint256 MetaNodeBal = MetaNode.balanceOf(address(this));

        if (amount_ > MetaNodeBal) {
            MetaNode.transfer(to_, MetaNodeBal);
        } else {
            MetaNode.transfer(to_, amount_);
        }
    }
}