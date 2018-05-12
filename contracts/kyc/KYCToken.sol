pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Certifiable.sol";


contract KYCToken is ERC20, Certifiable {
    mapping (address => bool) public icoBuyers;
    mapping (address => bool) public kycVerified;

    constructor(address _certifier) public
        Certifiable(_certifier)
    {

    }

    modifier isKnownCustomer() {
        require(!icoBuyers[msg.sender] || certifier.certified(msg.sender));
        _;
    }

    function delayedTransferFrom(address _tokenWallet, address _to, uint256 _value) public returns (bool) {
        require(!icoBuyers[_to]);
        transferFrom(_tokenWallet, _to, _value);
        icoBuyers[_to] = true;
        kycVerified[_to] = false;
    }

}
