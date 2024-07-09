// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.20;

import "./NestableToken.sol";

contract NestableNFT is NestableToken {
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
     * @dev GLM own work
     */ 


    struct TreeNode {
        bool isRoot;
        address contractAddress;
        uint256 tokenId;
        TreeNode[] children;
    }

    struct Tree{
        TreeNode rootNode;
        uint256 dummy;
    }

    function showTreeOf(
        uint256 parentId
    ) public view virtual returns (Child memory) {
        Tree memory tree = _getTreeOf(parentId);
        Child memory child = Child({
            contractAddress: tree.rootNode.contractAddress,
            tokenId: tree.rootNode.tokenId
        });
        return child;
    }

    function _getTreeOf(
        uint256 parentId
    ) internal view virtual returns (Tree memory) {
        Tree memory tree;
        tree.rootNode = _newNode(true, address(this), parentId);
        tree.dummy = 0;
        return tree;
    }

    function _newNode (
        bool root, address contractAddress, uint256 tokenId
    ) internal view virtual returns (TreeNode memory) {
        TreeNode memory node;
        node.isRoot = root;
        node.contractAddress = contractAddress;
        node.tokenId = tokenId;
        node.children = _addNodeChildren(node);
        return node;
    }

    function _addNodeChildren(
        TreeNode memory node
    ) internal view virtual returns (TreeNode[] memory) {
        Child[] memory children = _activeChildren[node.tokenId];
        uint256 length = children.length;
        TreeNode[] memory childNodes = new TreeNode[](length);
        for (uint256 i; i < length; ) {
            Child memory child = children[i];
            childNodes[i] = _newNode(false, child.contractAddress, child.tokenId);
        }
        return childNodes;
    }

}