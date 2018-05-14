pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./Certifiable.sol";


contract KYCToken is ERC20, Certifiable {
    mapping (address => bool) public kycPending;

    constructor(address _certifier) public
        Certifiable(_certifier)
    {

    }

    modifier isKnownCustomer(address _address) {
        require(!kycPending[_address] || certifier.certified(_address));
        if (kycPending[_address]) {
            kycPending[_address] = false;
        }
        _;
    }

    function delayedTransferFrom(address _tokenWallet, address _to, uint256 _value) public returns (bool) {
        transferFrom(_tokenWallet, _to, _value);
        kycPending[_to] = true;
    }

}
