# FarvilleAvatar NFT Smart Contract

FarvilleAvatar is an ERC721-compliant NFT collection with signature-based minting verification, royalty support, and pausable functionality.

## Features

- **Signature-Based Minting**: Secure minting process requiring owner signature verification
- **One-Per-Address**: Each address can only mint one NFT
- **Royalty Support**: Built-in royalty mechanism for secondary sales
- **Pausable**: Contract owner can pause/unpause minting operations
- **Price Control**: Minimum price threshold for minting
- **ERC20 Payment**: Minting fees paid in specified ERC20 token
- **Metadata Management**: Configurable token URIs and contract metadata

## Contract Details

- **Name**: FarvilleAvatar
- **Symbol**: FVA
- **Standards**: ERC721, ERC2981 (Royalties)

## Key Functions

### Minting
```solidity
function mint(
    address recipient,
    uint256 tokenId,
    uint256 price,
    string memory tokenIdURI,
    bytes memory signature
) external whenNotPaused
```
Mints a new NFT with the following requirements:
- Price must be >= minimum price
- Valid owner signature
- Recipient hasn't minted before
- Token ID hasn't been minted before

### Signature Validation
```solidity
function validateSignature(
    address recipient,
    uint256 tokenId,
    string memory tokenIdURI,
    bytes memory signature
) public view returns (bool)
```
Validates the owner's signature for minting authorization.

### Administrative Functions

- `setContractURIMetadata(string)`: Update contract-level metadata
- `setTokenURI(uint256, string)`: Set specific token metadata
- `pause()`: Pause minting operations
- `unpause()`: Resume minting operations

## Setup

1. Deploy the contract with the following parameters:
   - `_initialOwner`: Contract owner address
   - `_royaltyRecipient`: Address to receive royalty payments
   - `_priceToken`: ERC20 token address for payment
   - `_priceRecipient`: Address to receive minting payments
   - `_royaltyFee`: Royalty percentage in basis points (e.g., 250 = 2.5%)
   - `_minPrice`: Minimum minting price
   - `_contractURIMetadata`: Initial contract URI

## Events

- `ContractURIUpdated`: Emitted when contract URI is updated
- `MetadataUpdate`: Emitted when token metadata is updated

## Error Conditions

- `AddressAlreadyMinted`: Address has already minted
- `InvalidPrice`: Minting price below minimum
- `InvalidSignature`: Invalid owner signature
- `InvalidTokenURI`: Empty token URI provided
- `TokenAlreadyMinted`: Token ID already exists

## Security Features

- OpenZeppelin's secure contract implementations
- ECDSA signature verification
- SafeERC20 for token transfers
- Pausable functionality for emergency stops
- Access control via Ownable pattern

## Dependencies

- OpenZeppelin Contracts ^5.0.0
  - ERC721
  - ERC721Royalty
  - Ownable
  - Pausable
  - SafeERC20
  - ECDSA
  - MessageHashUtils

## License

MIT License
