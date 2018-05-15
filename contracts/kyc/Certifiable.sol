pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Certifier.sol";


contract Certifiable is Ownable {
    Certifier public certifier;
    event CertifierChanged(address indexed newCertifier);

    constructor(address _certifier) public {
        certifier = Certifier(_certifier);
    }

    function updateCertifier(address _address) public onlyOwner returns (bool success) {
        require(_address != address(0));
        emit CertifierChanged(_address);
        certifier = Certifier(_address);
        return true;
    }
}
