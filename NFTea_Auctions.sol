// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts@4.4.1/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts@4.4.0/access/Ownable.sol";

/** 
 * @title NFTea_Auctions
 * @dev Contract allowing many sale/buy auctions to manage NFTs
 */
 contract NFT_Auctions is Ownable {
     address private nftContract;
     string private contractName;

     uint feesAmount = 0;

    IERC721 public nft;

    uint public newBidsAuctionFees = 1500 gwei;
    uint public saleFees = 10 ;

     constructor(address _tokenContractAddress, string memory _contractName) {
         nft = IERC721(_tokenContractAddress) ;
         contractName = _contractName;
     }
        // Fees and contract management
     function updateNewBidsAuctionFees(uint _newBidsAuctionFeeInGwei) public onlyOwner {
         newBidsAuctionFees = _newBidsAuctionFeeInGwei * 1 gwei;
     }

     function updateSaleFees(uint _newSaleFees) public onlyOwner {
         require(_newSaleFees < 100, "Fees part can't be more than 100%");
         saleFees = _newSaleFees;
     }

        // Withdrawal of earning fees to owner
     function withdrawal() public {
         require(feesAmount > 0 , "No amount to withdraw");
         payable(owner).call{value: feesAmount}("");
         feesAmount = 0;
     }

        // Kill contract = ending all auctions
     function killContract() external onlyOwner {
         for (uint i = 0 ; i < nbBidsAuctions ; i++) {
             if (! bidsAuctions[i].ended) {
                 _forceEndBidAuction(i);
             }
         }
         payable(owner).call{value: this.balance}("");
         feesAmount = 0;
     }

        // Event of auctions
    event NewBidsAuction(uint tokenId, uint startAt, uint endAt, uint floorPrice);
    event NewBid(uint tokenId, address owner, uint bidAmount);
    event NewFixedPrice(uint tokenId, uint fixedPrice);
    event NewSale(uint tokenId, address from, address to, uint price);

    struct BidsAuction {
         uint       tokenId;
         uint       startAt;
         uint       endAt;
         uint       floorPrice;
         uint       nbBids;
         uint       higesthBid;
         bool       started;
         bool       ended;
     }
    
    uint private nbBidsAuctions;
    BidsAuction[] private bidsAuctions;
    mapping(uint => uint) private tokenToBidsAuction;

    
        // There will be only one active auction by token 
    function _isOnAuction(uint tokenId) public view returns (bool) {
        require(tokenId < nft.totalMinted, "NFT_Auction: Token never minted");
        uint auctionId = tokenToBidsAuction[tokenId];
        return bidsAuctions[auctionId].ended;
    }
        // Ending auction 
    function _forceEndAuction(uint tokenId) private returns (bool isSold) {
        require(_isOnAuction(tokenId), "NFT_Auction: Token not on auction");
        uint auctionId = tokenToBidsAuction[tokenId];
        BidsAuction storage auction = bidsAuctions[auctionId];
        if (auction.nbBids > 0) {
            _closeWinningBid(auction.higesthBid);
        }
        auction.endAt = block.timestamp;
        auction.ended = true;
        tokenToBidsAuction = 0;
    }

    function endAuction(uint auctionId) external {
        require(bidsAuctions[auctionId].started && ! (bidsAuctions[auctionId].ended), "NFT_Auctions - endAuction error: Auction still disabled");
        require(bidsAuctions[auctionId].endAt <= block.timestamp);
        if (bidsAuctions[auctionId].nbBids > 0 ) {
            _closeWinningBid(bidsAuctions[auctionId].higesthBid);
        }
        bidsAuctions[auctionId].ended = true;
    }

    function createBidsAuction(uint _tokenId, uint _floorPrice, uint _startAt, uint _endAt) external payable {
        require(msg.value >= newBidsAuctionFees, "NFT_Auction: not enough to cover fees");
        require(nft.ownerOf(_tokenId) == msg.sender || nft.getApproved(_tokenId) == msg.sender, "NFT_Auction: Caller is not token owner nor approved");
        if (_isOnAuction(_tokenId)) {
            _forceEndAuction(_tokenId);
        } else {
            nbBidsAuctions++;
            BidsAuction memory auction = new BidsAuction(_tokenId, _startAt, _endAt, _floorPrice, 0, 0, false, false );
            auction.started = auction.startAt <= block.timestamp;
            bidsAuctions[nbBidsAuctions] = auction;
            tokenToBidsAuction[_tokenId] = nbBidsAuctions;
            emit NewBidsAuction(_tokenId, _startAt, _endAt, _floorPrice);
        }
    }

    function _forceEndBidAuction(uint _auctionId) private {
        require(bidsAuctions[_auctionId].started && ! (bidsAuctions[_auctionId].ended), "NFT_Auction: Auction still ended");
        if (bidsAuctions[_auctionId].nbBids > 0) {
            _closeWinningBid(bidsAuctions[_auctionId].higesthBid);
        }
        if (bidsAuctions[_auctionId].endAt > block.timestamp) {
            bidsAuctions[_auctionId].endAt = block.timestamp;
        }
        bidsAuctions[_auctionId].ended = true;
    }

    struct Bid {
         uint       auctionId;
         uint       amount;
         bool       active;
     }
    uint private nbBids;
    mapping(uint => address) bidToOwner;
    mapping(uint => Bid) bids;

    function newBid(uint auctionId, uint bid) external payable {
        require(msg.value >= bid, "NFT_Auctions - newBid error: not enough to make bid");
        require(bids[bidsAuctions[auctionId].higesthBid], "NFT_Auctions - newBid error: Bid amount under current highest bid");
        require(bidsAuctions[auctionId].floorPrice <= bid, "NFT_Auctions - newBid error: Bid amount under floor price");
        require(bidsAuctions[auctionId].started && ! bidsAuctions[auctionId].ended, "NFT_Auctions - newBid error: Auction is not active");
            // if previous bid, payback them
        if (bidsAuctions[auctionId].nbBids > 0 ) {
            uint lastbidId = bidsAuctions[auctionId].higesthBid;
            payable(bidToOwner[lastbidId]).call{value: bids[lastbidId].amount}("");
            bids[lastbidId].active = false;
        }
            // Then create new bid
        nbBids++;
        bids[nbBids] = Bid(auctionId, bid, true);
        bidToOwner[nbBids] = msg.sender;
        bidsAuctions[auctionId].nbBids++;
        bidsAuctions[auctionId].higesthBid = nbBids;
        emit NewBid(bidsAuctions[auctionId].tokenId, msg.sender, bid);
    }

    function _closeWinningBid(uint bidId) private {
        require(bids[bidId].active, "NFT_Auctions - closing Bid error: bid still inactive");
        uint tokenId = bidsAuctions[bids[bidId].auctionId].tokenId;
        feesAmount += (saleFees * bids[bidId].amount) / 100;
        emit NewSale(tokenId, nft.ownerOf(tokenId), bidToOwner[bidId], bids[bidId].amount );
        nft.ownerOf(tokenId).call{value: bids[bidId].amount * ((100 - saleFees) / 100)}("");
        nft.safeTransferFrom(address(this), bidToOwner[bidId], tokenId);
        bids[bidId].active = false;
    }

    mapping(uint => uint) fixedPrices;
        // To create new fixed price offer to buyers
    function createFixedPriceOffer(uint _tokenId, uint _newFixedPrice) external  {
        require(nft.ownerOf(_tokenId) == msg.sender || nft.getApproved(_tokenId) == msg.sender, "NFT_Auction: caller is not token owner nor approved");
        require(bidsAuctions[tokenToBidsAuction[_tokenId]].nbBids == 0, "NFT_Auction: Token already sold into Auction");
        require(_newFixedPrice > 0 , "NFT_Auction: Fixed price cannot be null");
        fixedPrices[_tokenId] = _newFixedPrice;
        emit NewFixedPrice(_tokenId, _newFixedPrice);
    }
        // To stop fixed price auction
    function cancelFixedPrice(uint _tokenId) external {
        require(fixedPrices[_tokenId] > 0 , "NFT_Auction: No fixed price offer to cancel");
        require(nft.ownerOf(_tokenId) == msg.sender || nft.getApproved(_tokenId) == msg.sender, "NFT_Auction: caller is not token owner nor approved");
        fixedPrices[_tokenId] = 0;
    }
        // To buy at fixed price offer
    function buyFixedPriceToken(uint _tokenId) external payable {
        require(msg.value >= fixedPrices[_tokenId], "NFT_Auction: Not enough money to pay item");
        require(fixedPrices[_tokenId] > 0, "NFT_Auction: Token is not on sale");
        uint tokenSaleFees = fixedPrices[_tokenId] * saleFees / 100;
        uint tokensaleAmount = msg.value - tokenSaleFees; 
        emit NewSale(_tokenId, nft.ownerOf(_tokenId), msg.sender, msg.value);
        payable(nft.ownerOf(_tokenId)).call{value: tokensaleAmount}("");
        nft.safeTransferFrom(nft.ownerOf(_tokenId), msg.sender, _tokenId);
        feesAmount += tokenSaleFees;
        fixedPrices[_tokenId] = 0;
    }
     


 }
