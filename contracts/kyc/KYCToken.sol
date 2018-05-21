pragma solidity ^0.4.24;

import "./Certifiable.sol";


contract KYCToken is Certifiable {
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

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
        emit ManagerAdded(_address);
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
        emit ManagerRemoved(_address);
    }

}
