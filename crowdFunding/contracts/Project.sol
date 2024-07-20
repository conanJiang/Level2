// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Project {
    //项目创建者
    address public creator;
    //项目描述
    string public description;
    //目标金额
    uint256 public goalAmount;
    //截止日期（时间戳）
    uint256 public deadline;
    //当前筹集金额
    uint256 public currentAmount;
    //项目状态
    enum ProjectState {
        Ongoing,
        Successful,
        Failed
    }
    //当前项目状态
    ProjectState public state;
    //捐赠结构
    struct Donation {
        address donor;
        uint256 amount;
    }
    //捐赠记录数组
    Donation[] public donations;

    //捐赠事件
    event DonationReceived(address indexed donor, uint256 amount);
    //项目状态变化事件
    event ProjectStateChanged(ProjectState newState);
    //资金提取事件
    event FundsWithdrawn(address indexed creator, uint256 amount);
    //资金撤回事件
    event FundsRefunded(address indexed donor, uint256 amount);

    //只允许创建者
    modifier onlyCreator() {
        require(msg.sender == creator, "Not the project creator");
        _;
    }

    //众筹到期
    modifier onlyAfterDeadline() {
        require(block.timestamp >= deadline, "Project is still ongoing");
        _;
    }

    //初始化项目，设置创建者、描述、目标金额和截止日期
    function initialize(
        address _creator,
        string memory _description,
        uint256 _goalAmount,
        uint256 _duration
    ) public {
        creator = _creator;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + _duration;
        state = ProjectState.Ongoing;
    }

    //用户向项目捐款，更新当前筹集金额并记录捐赠
    function donate() external payable {
        //当前捐赠还在进行中
        require(state == ProjectState.Ongoing, "Project is not ongoing");
        require(block.timestamp < deadline, "Project deadline has passed");
        require(msg.value > 0, "Project deadline has passed");
        donations.push(Donation(msg.sender, msg.value));
        currentAmount += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    //项目成功时，创建者提取筹集的资金
    function withdrawFunds() external onlyCreator onlyAfterDeadline {
        require(state == ProjectState.Successful, "Project is not successful");

        uint256 amount = address(this).balance;
        payable(creator).transfer(amount);

        emit FundsWithdrawn(creator, amount);
    }

    //项目失败时，捐赠者撤回他们的捐款
    function refund() external onlyAfterDeadline {
        require(state == ProjectState.Failed, "Project is not failed");
        uint256 totalRefund = 0;
        for (uint256 i = 0; i < donations.length; i++) {
            if (donations[i].donor == msg.sender) {
                totalRefund += donations[i].amount;
                donations[i].amount = 0;
            }
        }
        require(totalRefund > 0, "No funds to refund");
        //退钱
        payable(msg.sender).transfer(totalRefund);
        emit FundsRefunded(msg.sender, totalRefund);
    }

    function updateProjectState() external onlyAfterDeadline {
        require(state == ProjectState.Ongoing, "Project is already finalized");
        if (currentAmount >= goalAmount) {
            state = ProjectState.Successful;
        } else {
            state = ProjectState.Failed;
        }
        emit ProjectStateChanged(state);
    }
}
