pragma solidity ^0.4.23;

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

}
