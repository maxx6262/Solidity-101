// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts@4.4.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.4.0/access/Ownable.sol";

/**
  * @title NFTea : Non Fungible Token collection representing many varieties of tea
  *
  *@dev NFTea is an ERC721, ERC721Metadata and Ownabe implementation
*/

contract NFTea is ERC721 , Ownable {

    // maxSupply = maximum Supply of NFTeas token
    uint private maxSupply = 7;
    // totalMinted amount of minted tokens
    uint private totalMinted = 0;
    // burned tokens amount
    uint private burnedTokensAmount = 0;
    // current supply = total minted - burned amount
    uint private currentSupply = 0 ;
    //mintFees is minting fees to pay to the contract
    uint mintFees = 0 gwei;
    // mintable when contract is active and current supply still under maxSupply
    bool private mintable;

    // burned tokens archived
    mapping(uint => uint)  private burnedTokens;

    constructor() ERC721("NFTeas Varieties", "NFTea")   {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/QmNccL3Nq5mk1rWJ5ouq2nf8gvAv74mtsYLWZ4RBbdWRmM/";
    }

    /**
     * @dev any address would be able to call minter by paying mint fees
     */
    function safeMint(address to, uint256 tokenId) public payable {
        require(msg.value >= mintFees, "NFTea: sender must pay mint auction fees");
        require(tokenId < maxSupply, "NFTea: token ID value is more than total supply on contract");
        require(mintable, "NFTea: Contract currently disabled");
        _safeMint(to, tokenId);
        currentSupply++;
    }

    /**
     * @param _newSupply new maximum amount tokens the contract would be able to mint
     */
    function updateTotalSupply(uint _newSupply) external onlyOwner {
        require(_newSupply >= currentSupply, "NFTEA: MaxSupply can't be less than amount already minted");
        _updateMaxSupply(_newSupply);
        _updateMintable();
    }

    function _updateMaxSupply(uint _newSupply) internal {
        maxSupply = _newSupply;
    }

    /**
     * @dev enabling minter when current Supply < Max Supply and minter currently disabled
     */
    function enableMinter() external onlyOwner {
        require(! mintable, "NFTea: Minter already enabled");
        require(currentSupply < maxSupply, "NFTea: All tokens already minted");
        mintable = true;
    }

    function disableMinter() external onlyOwner {
        require(mintable, "NFTea: Minter already disabled");
        mintable = false;
    }

    /**
     * @dev EndMinter Stop all future minting ability
     * @dev By updating maxSupply at currentSupply Value and mintable to false value
     */
    function endMinter() external onlyOwner {
        require(currentSupply < maxSupply, "NFTea: Already ended contract");
        maxSupply = currentSupply;
        mintable = false;
    }

    /**
     * @dev calculation of mintable value
     */
    function _updateMintable() internal {
        if (mintable) {
            mintable = maxSupply > currentSupply;
        }
    }

    /**
     * @dev returns amount of burned tokens
     */
    function getBurnedTokensAmount() public view returns (uint) {
        return burnedTokensAmount;
    }

    /**
     * @dev returns current active tokens supply
     */
    function getCurrentActiveSupply() public view returns (uint) {
        return currentSupply - burnedTokensAmount;
    }

    /**
     * @dev returns amount of still mintable tokens amount 
    */
    function getMintableTokensAmount() public view returns (uint) {
        return maxSupply - currentSupply;
    }

    /** 
     * @dev Burning token
     */
    function burn(uint tokenId) external {
        require(tokenId <= currentSupply, "NFTea: tokenId must exist");
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender, "NFTea: only owner or approved address can burn token");
        _burn(tokenId);
        burnedTokens[burnedTokensAmount] = tokenId;
        burnedTokensAmount++;
    }

    /**
     * @dev Withdrawal of earnings to owner address
      */
    function withdraw() public returns (bool) {
        uint withrawalAmount = address(this).balance;
        address payable owner_address = payable(owner());
        (bool sent, ) = owner_address.call{value: withrawalAmount}("");
        require(sent, "NFTea: Error during withdrawal");
        return sent;
    }

    /**
     * @dev _setNewFees
       * @param _newFeesAmount : New fee amount to be paid in gwei
       * @dev fees to pay to the contract at mintage
       */
    function _setNewMintFees(uint _newMintFeesAmount) public onlyOwner {
        mintFees = _newFeesAmount * 1 gwei;
    }

            // 2nd market P2P Exchange and auction management
    event PutOnSale(uint tokenId, uint fixedPrice);

    event NewSale(address seller, address buyer, uint tokenId, uint price);

    
    // Mapping for on-sale at fixed price tokens - null price => item not on sale
    mapping(uint => uint) private onSaleFixedPriceTokens;


    struct fixedPriceOffer {
        uint        price,
    } 
    
    mapping(uint => uint)
    

    /**
     * @param _price amount to be paid to buy item in gwei
     * @dev put token on sale at fixed price
     */
     function putOnSale(uint _tokenId, uint _price) external {
         require(ownerOf(_tokenId) == msg.sender || getApproved(_tokenId) == msg.sender, "NFTea: Caller is not token owner nor approved");
         require(_price > 0, "NFTea: Price must be > 0");
     }
} 
