// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract EnglishAuction is ReentrancyGuard {
    IERC721 public nft;
    uint256 public nftId;
    address public seller;
    uint256 public endTime;
    uint256 public highestBid;
    address public highestBidder;
    mapping(address => uint256) public bids;
    mapping(address => uint256) public pendingWithdrawals;


    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    constructor(address _nft, uint256 _nftId, uint256 _duration) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = msg.sender;
        endTime = block.timestamp + _duration;
    }

    function placeBid() external payable nonReentrant {
        require(block.timestamp < endTime, "Auction ended");
        require(msg.value > highestBid, "Bid too low");
        require(msg.sender != seller, "Seller cannot bid");

        // Refund previous highest bidder
        if (highestBidder != address(0)) {
            (bool success, ) = highestBidder.call{value: highestBid}("");
            if (!success ){
                    pendingWithdrawals[highestBidder] += highestBid;
            }
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        bids[msg.sender] = msg.value;
        emit BidPlaced(msg.sender, msg.value);
    }

    function endAuction() external nonReentrant {
        require(block.timestamp >= endTime, "Auction not ended");
        require(msg.sender == seller, "Only seller can end");

        if (highestBidder != address(0)) {
            nft.transferFrom(seller, highestBidder, nftId);
            (bool success, ) = seller.call{value: highestBid}("");
            require(success, "Transfer to seller failed");
        } else {
            nft.transferFrom(seller, address(this), nftId);
        }
        emit AuctionEnded(highestBidder, highestBid);
    }
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}



interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

