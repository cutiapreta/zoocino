// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SimpleGovernance {
    IERC20 public govToken;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public lastVoteBlock;

    struct Proposal {
        address proposer;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 endBlock;
        bool executed;
    }

    event ProposalCreated(uint256 indexed proposalId, address proposer);
    event VoteCast(uint256 indexed proposalId, address voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(IERC20 _govToken) {
        govToken = _govToken;
    }

    function createProposal() external returns (uint256) {
        require(govToken.balanceOf(msg.sender) > 0, "Not enough tokens");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposer: msg.sender,
            forVotes: 0,
            againstVotes: 0,
            endBlock: block.number + 100,
            executed: false
        });
        emit ProposalCreated(proposalCount, msg.sender);
        return proposalCount;
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number < proposal.endBlock, "Voting ended");
        require(lastVoteBlock[msg.sender] < block.number, "Already voted this block");

        uint256 balance = govToken.balanceOf(msg.sender);
        require(balance > 0, "No tokens");

        if (support) {
            proposal.forVotes += balance;
        } else {
            proposal.againstVotes += balance;
        }

        lastVoteBlock[msg.sender] = block.number;
        emit VoteCast(proposalId, msg.sender, support, balance);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.number >= proposal.endBlock, "Voting not ended");
        require(!proposal.executed, "Already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");

        proposal.executed = true;
        // Execute proposal logic here (e.g., change parameters)
        emit ProposalExecuted(proposalId);
    }
}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}