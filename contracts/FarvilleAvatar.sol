// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.11;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title FarvilleAvatar NFT Contract
/// @notice This contract implements the FarvilleAvatar NFT collection with signature mint verification
/// @dev Extends ERC721Royalty and Ownable for NFT functionality with royalties
contract FarvilleAvatar is ERC721Royalty, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /// @notice Error thrown when attempting to mint an already minted address
    error AddressAlreadyMinted();
    /// @notice Error thrown when attempting to mint an NFT with an invalid price
    error InvalidPrice();
    /// @notice Error thrown when attempting to mint an NFT with an invalid signature
    error InvalidSignature();
    /// @notice Error thrown when attempting to set an invalid token URI
    error InvalidTokenURI();
    /// @notice Error thrown when attempting to mint an already minted token
    error TokenAlreadyMinted();

    /// @notice Event emitted when the contract URI is updated
    event ContractURIUpdated();
    /// @notice Event emitted when the metadata for a token is updated
    event MetadataUpdate(uint256 tokenId);

    /// @notice The contract uri
    /// @dev value set during contract deployment
    string public contractURIMetadata;

    /// @notice The minimum price of the NFT
    /// @dev value set during contract deployment
    uint256 public minPrice;

    /// @notice The address of the price token
    /// @dev value set during contract deployment
    address public priceToken;

    /// @notice The address of the price recipient
    /// @dev value set during contract deployment
    address public priceRecipient;

    /// @notice Mapping to track which token IDs have been minted
    /// @dev Maps token ID to minting status
    mapping(uint256 => bool) public minted;

    /// @notice Mapping to track which addresses have minted
    /// @dev Maps address to minting status
    mapping(address => bool) public hasMinted;

    /// @notice Mapping to track uri for each token ID
    /// @dev Maps token ID to token URI
    mapping(uint256 => string) public tokenURIs;
    
    /// @notice Initializes the FarvilleAvatar NFT contract
    /// @dev Sets up the NFT collection with royalty information
    /// @param _initialOwner Address of the contract owner
    /// @param _royaltyRecipient Address to receive royalty payments
    /// @param _priceToken The address of the price token
    /// @param _royaltyFee The royalty fee in basis points (e.g., 250 = 2.5%)
    /// @param _minPrice The minimum price of the NFT
    /// @param _priceRecipient The address of the price recipient
    /// @param _contractURIMetadata The contract URI metadata
    constructor(address _initialOwner, address _royaltyRecipient, address _priceToken, address _priceRecipient, uint96 _royaltyFee, uint256 _minPrice, string memory _contractURIMetadata)
        ERC721("FarvilleAvatar", "FVA")
        Ownable(_initialOwner)
    {
        _setDefaultRoyalty(_royaltyRecipient, _royaltyFee);
        minPrice = _minPrice;
        priceToken = _priceToken;
        priceRecipient = _priceRecipient;
        contractURIMetadata = _contractURIMetadata;
    }

    /// @notice Returns the contract URI according to EIP7572
    /// @return Contract URI string
    function contractURI() public view returns (string memory) {
        return contractURIMetadata;
    }

    /// @notice Returns the token URI for a given token ID
    /// @param tokenId The ID of the token to get the URI for
    /// @return Token URI string
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return tokenURIs[tokenId];
    }

    /// @notice Validates the signature of a given token ID
    /// @param recipient The address of the recipient
    /// @param tokenId The ID of the token to validate the signature for
    /// @param tokenIdURI The URI of the token to validate the signature for
    /// @param signature The signature to validate
    /// @return True if the signature is valid, false otherwise
    function validateSignature(address recipient, uint256 tokenId, string memory tokenIdURI, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(recipient, tokenId, tokenIdURI));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(signature);
        return signer == owner();
    }

    /// @notice Sets the contract URI metadata
    /// @dev Only the contract owner can set the URI
    /// @param newContractURIMetadata The new contract URI metadata to set
    function setContractURIMetadata(string memory newContractURIMetadata) external onlyOwner {
        contractURIMetadata = newContractURIMetadata;
        emit ContractURIUpdated();
    }

    /// @notice Sets the id URI for a given token ID
    /// @dev Only the contract owner can set the URI
    /// @param tokenId The ID of the token to set the URI for
    /// @param tokenIdURI The new URI to set
    function setTokenURI(uint256 tokenId, string memory tokenIdURI) external onlyOwner {
        if (bytes(tokenIdURI).length == 0) {
            revert InvalidTokenURI();
        }
        tokenURIs[tokenId] = tokenIdURI;
    }

    /// @notice Pauses all token minting
    /// @dev Only the contract owner can pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token minting
    /// @dev Only the contract owner can unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mints a new FarvilleAvatar NFT
    /// @dev Verifies signature before minting
    /// @param tokenId The ID of the token to mint
    /// @param signature The signature to verify eligibility
    function mint(address recipient, uint256 tokenId, uint256 price, string memory tokenIdURI, bytes memory signature) external whenNotPaused {
        if (minted[tokenId]) revert TokenAlreadyMinted();
        if (hasMinted[recipient]) revert AddressAlreadyMinted();
        if (price < minPrice) revert InvalidPrice();
        if (!validateSignature(recipient, tokenId, tokenIdURI, signature)) revert InvalidSignature();
        // Mark the token ID as minted
        minted[tokenId] = true;
        // Mark the address as minted
        hasMinted[recipient] = true;
        // Set the token URI
        _setTokenURI(tokenId, tokenIdURI);
        // Mint the NFT
        _safeMint(recipient, tokenId);
        // Transfer the price amount to the price recipient
        IERC20(priceToken).safeTransferFrom(msg.sender, priceRecipient, price);
    }

    /// @notice Sets the token URI for a given token ID
    /// @dev Only the contract owner can set the URI
    /// @param tokenId The ID of the token to set the URI for
    /// @param tokenIdURI The new URI to set
    function _setTokenURI(uint256 tokenId, string memory tokenIdURI) internal {
        if (bytes(tokenIdURI).length == 0) {
            revert InvalidTokenURI();
        }
        tokenURIs[tokenId] = tokenIdURI;
        emit MetadataUpdate(tokenId);
    }

}
