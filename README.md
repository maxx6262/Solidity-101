# Solidity-101
Dacade Solidity course : NFTea contract and auctioner
1. NFTea : An ERC721 with URI, Metadata, and Ownability features
  # Deployed on Rinkeby : 0x67F98fb190516A3b982d606F2d4a00F187af90fe
     "Simple & educational collection of 7 mintable tokens"
  # Contract owner will be able to manage fees settings and mint timing
     Owner would also definitively renounce to its ownership, or reduce amount of mintable tokens
  # Token owner will be able to burn tokens
  # To launch minter, owner has to enable it
2. Thanks to the standard URI format used, token's UTIs are findable in IPFS with CID 'QmNccL3Nq5mk1rWJ5ouq2nf8gvAv74mtsYLWZ4RBbdWRmM' 
  # Token are seeable in Opensea's testnet account :
  # Tokens are tradable, transferrable or burnable
4. NFT_Auctions :
  # Fixed price : Using contract as escrow and marketplace solution
  # BidsAuction : For determined time, anyone could make higher bid than previous one. 
    => Payback automatic at new Bid submission
    => Fees level manageable by contract owner 
    => Regular withdrawability
