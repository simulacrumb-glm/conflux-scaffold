// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.20;

import "./NestableToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract NestableNFT2 is NestableToken {
    constructor() NestableToken() {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId, "");
    }

    function nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) external {
        _nestMint(to, tokenId, destinationId, "");
    }

    // Utility transfers:

    function transfer(address to, uint256 tokenId) public virtual {
        transferFrom(_msgSender(), to, tokenId);
    }

    function nestTransfer(
        address to,
        uint256 tokenId,
        uint256 destinationId
    ) public virtual {
        nestTransferFrom(_msgSender(), to, tokenId, destinationId, "");
    }

    /**
     * @dev GLM own work below
     * @dev changed usage of Address.isContract() to Address.code.length
     * @dev polyfilled toChecksumHexString
     * @dev Tree parsing functions start from a token in this contract 
     *  but can access descendants in any contract that implements IERC7401 interface
     */ 

    struct TreeNode {
        address contractAddress;
        uint256 tokenId;
        TreeNode[] children;
    }

    struct Tree{
        TreeNode rootNode;
        bool isSubTree;
    }

    /**
     * @notice polyfilled locally from unreleased head of @openzeppelin/contracts/utils/Strings.sol
     * @dev Converts an `address` with fixed length of 20 bytes to its checksummed ASCII `string` hexadecimal
     * representation, according to EIP-55.
     */
    function toChecksumHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = bytes(Strings.toHexString(addr));

        // hash the hex part of buffer (skip length + 2 bytes, length 40)
        uint256 hashValue;
        assembly ("memory-safe") {
            hashValue := shr(96, keccak256(add(buffer, 0x22), 40))
        }

        for (uint256 i = 41; i > 1; --i) {
            // possible values for buffer[i] are 48 (0) to 57 (9) and 97 (a) to 102 (f)
            if (hashValue & 0xf > 7 && uint8(buffer[i]) > 96) {
                // case shift by xoring with 0x20
                buffer[i] ^= 0x20;
            }
            hashValue >>= 4;
        }
        return string(buffer);
    }

    /**
     * @notice Used to build a string representation of the tree using bracket notation
     * @dev recursive function
     * @param node TreeNode struct
     * @return string bracked notation of the tree visited pre-order
     */
    function getTreeAsString(
        TreeNode memory node
    ) internal view virtual returns (string memory) {
        string memory summary = string.concat(
            toChecksumHexString(node.contractAddress),
            ":",
            Strings.toString(node.tokenId)
        );
        if(node.children.length > 0){
            for (uint256 i; i < node.children.length; ++i) {
                summary = string.concat(summary, "(", getTreeAsString(node.children[i]), ")");
            }
        }
        return summary;
    }

    function showTreeOf(
        uint256 parentId
    ) public view virtual returns (string memory) {
        Tree memory tree = _getTreeOf(parentId);
        return getTreeAsString(tree.rootNode);
    }

    /**
     * @notice Used to build a string representation of the tree using bracket notation
     * @dev has to be internal because structs are not ABI types
     *  setting to public results in:
     *  TypeError: Internal or recursive type is not allowed for public state variables.
     *  a public getter function must be provided
     * @param parentId tokenId to start decendant tree from
     */
    function _getTreeOf(
        uint256 parentId
    ) internal view virtual returns (Tree memory) {
        Tree memory tree;
        tree.rootNode = _newNode(address(this), parentId);
        (,,bool n) = directOwnerOf(tree.rootNode.tokenId);
        tree.isSubTree = n;
        console.log(tree.isSubTree);
        return tree;
    }

    function _newNode (
        address contractAddress, uint256 tokenId
    ) internal view virtual returns (TreeNode memory) {
        TreeNode memory node;
        node.contractAddress = contractAddress;
        node.tokenId = tokenId;
        console.log(node.tokenId);
        node.children = _addNodeChildren(node);
        return node;
    }
    /**
     * @notice accesses children from this or other ERC7401 tokens through the IERC7401 interface
     */
    function _addNodeChildren(
        TreeNode memory node
    ) internal view virtual returns (TreeNode[] memory) {
        IERC7401 destContract = IERC7401(node.contractAddress);
        Child[] memory children = destContract.childrenOf(node.tokenId);
        uint arrayLen = children.length;
        TreeNode[] memory childNodes = new TreeNode[](arrayLen);
        for (uint256 i; i < arrayLen; ++i) {
            Child memory child = children[i];
            childNodes[i] = _newNode(child.contractAddress, child.tokenId);
        }
        return childNodes;
    }

}