// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "./IFactoryERC1155.sol";
import "./Creature.sol";

contract CreatureFactory is FactoryERC1155, Ownable {
    using Strings for string;
    using SafeMath for uint256;

    // event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    address public proxyRegistryAddress;
    address public nftAddress;
    string constant internal baseMetadataURI = "https://opensea-creatures-api.herokuapp.com/api/";
    uint256 constant UINT256_MAX = ~uint256(0);

    /**
    * Optionally set this to a small integer to enforce limited existence per option/token ID
    * (Otherwise rely on sell orders on OpenSea, which can only be made by the factory owner.)
    */
    uint256 constant SUPPLY_PER_TOKEN_ID = 1;

    uint256 constant NUM_OPTIONS = 10;
    uint[] options = [1,3,4,5,6,7,8,9,10,11];
    uint[] optionsAmounts = [1,1,1,1,1,1,1,1,1,1];

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "My Collectible Pre-Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "MCP";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function factorySchemaName() override external pure returns (string memory) {
        return "ERC1155";
    }

    function numOptions() override public pure returns (uint256) {
        return NUM_OPTIONS;
    }

    function canMint(uint256 _optionId, uint256 _amount) override public view returns (bool) {
        return _canMint(msg.sender, _optionId, _amount);
    }

    function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) override public {
        return _mint(_optionId, _toAddress, _amount, _data);
    }

    function fireTransferEvents(address _from, address _to) private {
        emit TransferBatch(_msgSender(), _from, _to, options, optionsAmounts);
    }

    function uri(uint256 _optionId) override external pure returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, "factory/", Strings.toString(_optionId)));
    }

    /**
    * @dev Main minting logic implemented here!
    */
    function _mint(
        uint256 _optionId,
        address _toAddress,
        uint256 _amount,
        bytes memory _data
    ) internal {
        require(_canMint(msg.sender, _optionId, _amount), "MyFactory#_mint: CANNOT_MINT_MORE");
        Creature nftContract = Creature(nftAddress);
        nftContract.mint(_toAddress, _optionId, _amount, _data);
    }

    /**
    * Get the factory's ownership of Option.
    * Should be the amount it can still mint.
    * NOTE: Called by `canMint`
    */
    function balanceOf(
        address _owner,
        uint256 _optionId
    ) override public view returns (uint256) {
        if (!_isOwnerOrProxy(_owner)) {
        // Only the factory owner or owner's proxy can have supply
        return 0;
        }

        Creature nftContract = Creature(nftAddress);
        uint256 currentSupply = nftContract.totalSupply(_optionId);
        return SUPPLY_PER_TOKEN_ID.sub(currentSupply);
    }

    /**
    * Hack to get things to work automatically on OpenSea.
    * Use safeTransferFrom so the frontend doesn't have to worry about different method names.
    */
    function safeTransferFrom(
        address /* _from */,
        address _to,
        uint256 _optionId,
        uint256 _amount,
        bytes calldata _data
    ) external {
        _mint(_optionId, _to, _amount, _data);
    }

    //////
    // Below methods shouldn't need to be overridden or modified
    //////

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view returns (bool) {
        return owner() == _owner && _isOwnerOrProxy(_operator);
    }

    function _canMint(
        address _fromAddress,
        uint256 _optionId,
        uint256 _amount
    ) internal view returns (bool) {
        return _amount > 0 && balanceOf(_fromAddress, _optionId) >= _amount;
    }

    function _isOwnerOrProxy(
        address _address
    ) internal view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        return owner() == _address || address(proxyRegistry.proxies(owner())) == _address;
    }
}
