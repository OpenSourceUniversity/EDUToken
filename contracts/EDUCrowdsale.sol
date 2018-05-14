pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/AllowanceCrowdsale.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EDUToken.sol";
import "./kyc/Certifiable.sol";


contract EDUCrowdsale is AllowanceCrowdsale, CappedCrowdsale, Ownable, Certifiable {
    using SafeMath for uint256;

    EDUToken public token;

    constructor(
        uint256 _rate,
        address _wallet,
        EDUToken _token,
        address _tokenWallet,
        uint256 _cap,
        address _certifier
    ) public
      Crowdsale(_rate, _wallet, _token)
      AllowanceCrowdsale(_tokenWallet)
      CappedCrowdsale(_cap)
      Certifiable(_certifier)
    {
      token = _token;
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if (certifier.certified(_beneficiary)) {
            token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
        } else {
            token.delayedTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
        }
    }

    function changeTokenWallet(address _tokenWallet) public onlyOwner {
        tokenWallet = _tokenWallet;
    }

    function changeWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

}
