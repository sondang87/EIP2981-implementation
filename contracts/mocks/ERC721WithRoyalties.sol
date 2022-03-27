//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../ERC2981PerTokenRoyalties.sol';

/// @title Example of ERC721 contract with ERC2981
/// @author Simon Fremaux (@dievardump)
/// @notice This is a mock, mint and mintBatch are not protected. Please do not use as-is in production
contract ERC721WithRoyalties is ERC721Enumerable, ERC2981PerTokenRoyalties, Ownable {
    // uint256 nextTokenId;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Mint one token to `to`
    /// @param to the recipient of the token
    /// @param tokenId the id of the token (generated off chain for saving gas)
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    /// @param uri the URI of the token
    function mint(
        address to,
        uint256 tokenId,
        address royaltyRecipient,
        uint256 royaltyValue,
        string memory uri
    ) external {
        _safeMint(to, tokenId, '');

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        if (bytes(uri).length > 0) {
            _setTokenURI(tokenId, uri);
        }
    }

    /// @notice Mint several tokens at once
    /// @param recipients an array of recipients for each token
    /// @param tokenIds an array of ids for each token
    /// @param royaltyRecipients an array of recipients for royalties (if royaltyValues[i] > 0)
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    /// @param uris an array of URIs for each token
    function mintBatch(
        address[] memory recipients,
        uint256[] memory tokenIds,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues,
        string[] memory uris
    ) external {
        require(
            recipients.length == royaltyRecipients.length &&
                recipients.length == royaltyValues.length,
            'ERC721: Arrays length mismatch'
        );

        for (uint256 i; i < recipients.length; i++) {
            _safeMint(recipients[i], tokenIds[i], '');
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    tokenIds[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
            if (bytes(uris[i]).length > 0) {
                _setTokenURI(tokenIds[i], uris[i]);
            }
        }
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    // override
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721WithRoyalties: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721WithRoyalties: URI query for nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}
