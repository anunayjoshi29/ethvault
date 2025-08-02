// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./sETH.sol";

/**
 * @title Governance
 * @dev Contract for governance functionality using sETH tokens for voting
 */
contract Governance is Ownable, ReentrancyGuard {
    // State variables
    StakedETH public sETHToken;
    
    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    uint256 public executionDelay = 2 days;
    uint256 public quorum = 100 ether; // Minimum votes required for a proposal to pass
    
    // FIX: Add proposal cleanup limit to prevent unbounded growth
    uint256 public constant MAX_PROPOSALS = 1000; // Maximum number of proposals to keep in storage
    
    // Proposal struct
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;
        address target;
        uint256 createdAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        mapping(address => Vote) votes;
    }
    
    // Proposal details struct to avoid stack too deep errors
    struct ProposalDetails {
        address proposer;
        string description;
        uint256 createdAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        ProposalState state;
    }
    
    enum Vote {
        None,
        For,
        Against
    }
    
    enum ProposalState {
        Active,
        Defeated,
        Succeeded,
        Executed,
        Expired,
        Canceled
    }
    
    // Mapping from proposal ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 callDataHash);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    
    // Constructor
    constructor(address _sETHToken) {
        sETHToken = StakedETH(_sETHToken);
    }
    
    /**
     * @dev Creates a new proposal
     * @param description Description of the proposal
     * @param target Address of the contract to call
     * @param callData Function call data to execute if proposal passes
     */
    function createProposal(string memory description, address target, bytes memory callData) external returns (uint256) {
        require(sETHToken.balanceOf(msg.sender) >= 1 ether, "Must have at least 1 sETH to create proposal");
        
        //FIX: Add basic target validation
        require(target != address(0), "Invalid target address");
        require(target != address(this), "Cannot target this contract");
        
        //FIX: Add proposal limit check to prevent unbounded growth
        require(proposalCount < MAX_PROPOSALS, "Maximum proposals limit reached");
        
        uint256 proposalId = proposalCount++;
        
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.target = target;
        proposal.callData = callData;
        proposal.createdAt = block.timestamp;
        
        //FIX: Include callData hash in event for better transparency
        emit ProposalCreated(proposalId, msg.sender, description, keccak256(callData));
        
        return proposalId;
    }
    
    /**
     * @dev Casts a vote on a proposal
     * @param proposalId ID of the proposal
     * @param support True for voting in favor, false for voting against
     */
    function castVote(uint256 proposalId, bool support) external nonReentrant {
        require(getProposalState(proposalId) == ProposalState.Active, "Proposal not active");
        
        Proposal storage proposal = proposals[proposalId];
        
        // Check if user has already voted
        require(proposal.votes[msg.sender] == Vote.None, "Already voted");
        
        // Get user's voting weight (their sETH balance)
        uint256 weight = sETHToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");
        
        //FIX: Add minimum voting period check to prevent immediate execution abuse
        require(block.timestamp >= proposal.createdAt + 1 hours, "Voting period too early");
        
        // Record the vote
        if (support) {
            proposal.votesFor += weight;
            proposal.votes[msg.sender] = Vote.For;
        } else {
            proposal.votesAgainst += weight;
            proposal.votes[msg.sender] = Vote.Against;
        }
        
        emit VoteCast(msg.sender, proposalId, support, weight);
    }
    
    /**
     * @dev Executes a successful proposal after the voting period and execution delay
     * @param proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 proposalId) external nonReentrant {
        require(getProposalState(proposalId) == ProposalState.Succeeded, "Proposal not in succeeded state");
        
        Proposal storage proposal = proposals[proposalId];
        
        // CRITICAL FIX: Add expiry check to prevent execution after expiry
        require(block.timestamp <= proposal.createdAt + votingPeriod + executionDelay, "Proposal has expired");
        
        // Mark as executed
        proposal.executed = true;
        
        // Execute the proposal
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed");
        
        emit ProposalExecuted(proposalId);
    }
    
    /**
     * @dev Cancels a proposal (only by the proposer or admin)
     * @param proposalId ID of the proposal to cancel
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal already canceled");
        require(
            msg.sender == proposal.proposer || msg.sender == owner(),
            "Only proposer or admin can cancel"
        );
        
        proposal.canceled = true;
        
        emit ProposalCanceled(proposalId);
    }
    
    /**
     * @dev Gets the current state of a proposal
     * @param proposalId ID of the proposal
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        
        if (block.timestamp > proposal.createdAt + votingPeriod + executionDelay) {
            return ProposalState.Expired;
        }
        
        if (block.timestamp <= proposal.createdAt + votingPeriod) {
            return ProposalState.Active;
        }
        
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= quorum) {
            return ProposalState.Succeeded;
        }
        
        return ProposalState.Defeated;
    }
    
    /**
     * @dev Gets details of a proposal
     * @param proposalId ID of the proposal
     */
    function getProposalDetails(uint256 proposalId) external view returns (ProposalDetails memory) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[proposalId];
        
        // Create a ProposalDetails struct to avoid stack too deep errors
        ProposalDetails memory details = ProposalDetails({
            proposer: proposal.proposer,
            description: proposal.description,
            createdAt: proposal.createdAt,
            votesFor: proposal.votesFor,
            votesAgainst: proposal.votesAgainst,
            executed: proposal.executed,
            canceled: proposal.canceled,
            state: getProposalState(proposalId)
        });
        
        return details;
    }
    
    /**
     * @dev Gets the proposer of a proposal
     * @param proposalId ID of the proposal
     */
    function getProposalProposer(uint256 proposalId) external view returns (address) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        return proposals[proposalId].proposer;
    }
    
    /**
     * @dev Gets the description of a proposal
     * @param proposalId ID of the proposal
     */
    function getProposalDescription(uint256 proposalId) external view returns (string memory) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        return proposals[proposalId].description;
    }
    
    /**
     * @dev Gets the votes of a proposal
     * @param proposalId ID of the proposal
     */
    function getProposalVotes(uint256 proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (proposal.votesFor, proposal.votesAgainst);
    }
    
    /**
     * @dev Gets how a specific user voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address of the voter
     */
    function getVoteByUser(uint256 proposalId, address voter) external view returns (Vote) {
        require(proposalId < proposalCount, "Invalid proposal ID");
        return proposals[proposalId].votes[voter];
    }
    
    /**
     * @dev Updates governance parameters (only owner)
     */
    function updateGovernanceParams(
        uint256 _votingPeriod,
        uint256 _executionDelay,
        uint256 _quorum
    ) external onlyOwner {
        //FIX: Add reasonable bounds for governance parameters
        require(_votingPeriod >= 1 days && _votingPeriod <= 30 days, "Invalid voting period");
        require(_executionDelay >= 1 days && _executionDelay <= 7 days, "Invalid execution delay");
        require(_quorum >= 1 ether, "Quorum too low");
        
        votingPeriod = _votingPeriod;
        executionDelay = _executionDelay;
        quorum = _quorum;
    }
    
    /**
     * @dev Admin function to clean up old proposals (only owner)
     * This helps prevent unbounded storage growth
     */
    function cleanupOldProposals(uint256[] calldata proposalIds) external onlyOwner {
        for (uint256 i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            require(proposalId < proposalCount, "Invalid proposal ID");
            
            Proposal storage proposal = proposals[proposalId];
            // Only allow cleanup of executed, canceled, or expired proposals
            require(
                proposal.executed || 
                proposal.canceled || 
                getProposalState(proposalId) == ProposalState.Expired,
                "Can only cleanup finished proposals"
            );
            
            // Clear the proposal data (this is a simplified cleanup)
            delete proposals[proposalId];
        }
    }
}
