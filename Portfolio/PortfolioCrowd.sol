// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PortfolioCrowd is ERC721, Ownable {
    using SafeERC20 for IERC20;

    // Token ID counter
    uint256 private _tokenIdCounter;

    // ERC-20 token used for token giveaway
    IERC20 public giveawayToken;
    uint256 public giveawayAmount; // amount (in wei) per claim
    mapping(address => bool) public tokenClaimed;

    // NFT parameters
    string private _baseTokenURI;
    mapping(address => bool) public nftMinted; // one NFT per address by default

    // Tipping parameters
    uint256 public minTipWei = 0; // 0 means any tip allowed
    bool public autoMintNFTOnTip = true; // whether to mint NFT upon tip

    // Events
    event CoffeeBought(address indexed from, uint256 amountWei, string message);
    event NFTMinted(address indexed to, uint256 tokenId);
    event TokenClaimed(address indexed to, uint256 amount);
    event GiveawayTokenSet(address indexed tokenAddr);
    event GiveawayAmountSet(uint256 amount);
    event BaseURISet(string baseURI);
    event MinTipSet(uint256 minTipWei);
    event AutoMintOnTipEnabled(bool enabled);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(
        address initialOwner,
        address _giveawayToken,
        uint256 _giveawayAmount,
        string memory baseURI_
    ) ERC721("PortfolioVisitNFT", "PVNFT") Ownable(initialOwner) {
        if (_giveawayToken != address(0)) {
            giveawayToken = IERC20(_giveawayToken);
        }
        giveawayAmount = _giveawayAmount;
        _baseTokenURI = baseURI_;
    }

    // ---------- Tipping / Buy me a coffee ----------
    function buyCoffee(string memory message) external payable {
        require(msg.value >= minTipWei, "Tip below minimum");

        emit CoffeeBought(msg.sender, msg.value, message);

        // Optionally mint an NFT for the tipper if they have not minted before
        if (autoMintNFTOnTip && !nftMinted[msg.sender]) {
            _mintPortfolioNFT(msg.sender);
        }
    }

    // ---------- NFT logic ----------
    function _mintPortfolioNFT(address to) internal {
        _tokenIdCounter++;
        uint256 newId = _tokenIdCounter;
        _safeMint(to, newId);
        nftMinted[to] = true;
        emit NFTMinted(to, newId);
    }

    /// Public function to claim a free NFT (one per address)
    function claimNFT() external {
        require(!nftMinted[msg.sender], "NFT already minted for address");
        _mintPortfolioNFT(msg.sender);
    }

    // ---------- ERC20 giveaway faucet ----------
    function claimTokens() external {
        require(giveawayAmount > 0, "Giveaway amount not set");
        require(!tokenClaimed[msg.sender], "Already claimed tokens");
        require(address(giveawayToken) != address(0), "Giveaway token unset");
        uint256 bal = giveawayToken.balanceOf(address(this));
        require(bal >= giveawayAmount, "Contract has insufficient token balance");

        tokenClaimed[msg.sender] = true;
        giveawayToken.safeTransfer(msg.sender, giveawayAmount);

        emit TokenClaimed(msg.sender, giveawayAmount);
    }

    // ---------- Owner utility functions ----------
    function setGiveawayToken(address tokenAddr) external onlyOwner {
        giveawayToken = IERC20(tokenAddr);
        emit GiveawayTokenSet(tokenAddr);
    }

    function setGiveawayAmount(uint256 amount) external onlyOwner {
        giveawayAmount = amount;
        emit GiveawayAmountSet(amount);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
        emit BaseURISet(baseURI_);
    }

    function setMinTip(uint256 weiAmount) external onlyOwner {
        minTipWei = weiAmount;
        emit MinTipSet(weiAmount);
    }

    function enableAutoMintOnTip(bool enabled) external onlyOwner {
        autoMintNFTOnTip = enabled;
        emit AutoMintOnTipEnabled(enabled);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        emit Withdrawn(owner(), amount);
    }

    // ---------- Metadata override ----------
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Fallback/receive in case someone sends ETH without calling buyCoffee
    receive() external payable {
        emit CoffeeBought(msg.sender, msg.value, "ETH received (no message)");
        if (autoMintNFTOnTip && !nftMinted[msg.sender]) {
            _mintPortfolioNFT(msg.sender);
        }
    }
}