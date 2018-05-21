pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC827/ERC827Token.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./kyc/KYCToken.sol";


contract EDUToken is BurnableToken, KYCToken, ERC827Token {
    using SafeMath for uint256;

    string public constant name = "EDU Token";
    string public constant symbol = "EDUX";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 48000000 * (10 ** uint256(decimals));

    constructor(address _certifier) public KYCToken(_certifier) {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public isKnownCustomer(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public isKnownCustomer(_from) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public isKnownCustomer(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isKnownCustomer(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isKnownCustomer(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function delayedTransferFrom(address _tokenWallet, address _to, uint256 _value) public onlyManager returns (bool) {
        transferFrom(_tokenWallet, _to, _value);
        kycPending[_to] = true;
    }

}
