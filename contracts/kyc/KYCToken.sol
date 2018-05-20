pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Certifiable.sol";


contract KYCToken is ERC20, Certifiable {
    mapping(address => bool) public kycPending;
    mapping(address => bool) public managers;

    event ManagerAdded(address indexed newManager);
    event ManagerRemoved(address indexed removedManager);

    modifier onlyManager() {
        require(managers[msg.sender] == true);
        _;
    }

    modifier isKnownCustomer(address _address) {
        require(!kycPending[_address] || certifier.certified(_address));
        if (kycPending[_address]) {
            kycPending[_address] = false;
        }
        _;
    }

    constructor(address _certifier) public Certifiable(_certifier)
    {

    }

    function delayedTransferFrom(address _tokenWallet, address _to, uint256 _value) public onlyManager returns (bool) {
        transferFrom(_tokenWallet, _to, _value);
        kycPending[_to] = true;
    }

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
        emit ManagerAdded(_address);
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
        emit ManagerRemoved(_address);
    }

}
