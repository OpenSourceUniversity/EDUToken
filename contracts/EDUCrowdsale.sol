pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";
import "openzeppelin-solidity/contracts/crowdsale/emission/AllowanceCrowdsale.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./EDUToken.sol";
import "./kyc/Certifiable.sol";


contract EDUCrowdsale is AllowanceCrowdsale, CappedCrowdsale, TimedCrowdsale, Ownable, Certifiable {
    using SafeMath for uint256;

    EDUToken public token;

    constructor(
        uint256 _rate,
        address _wallet,
        EDUToken _token,
        address _tokenWallet,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        address _certifier
    ) public
      Crowdsale(_rate, _wallet, _token)
      AllowanceCrowdsale(_tokenWallet)
      CappedCrowdsale(_cap)
      TimedCrowdsale(_openingTime, _closingTime)
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

    /**
     * @dev Returns the rate of tokens per wei at the present time.
     * Note that, as price _increases_ with time, the rate _decreases_.
     * @return The number of tokens a buyer gets per wei at a given time
     */
    function getCurrentRate() public view returns (uint256) {
        if (block.timestamp < 1528718400) {
            return 1050;
        } else if (block.timestamp < 1529323200) {
            return 950;
        } else if (block.timestamp < 1529928000) {
            return 850;
        } else {
            return 750;
        }
    }

    /**
     * @dev Overrides parent method taking into account variable rate.
     * @param _weiAmount The value in wei to be converted into tokens
     * @return The number of tokens _weiAmount wei will buy at present time
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256)
    {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(_weiAmount);
    }

    function changeTokenWallet(address _tokenWallet) external onlyOwner {
        tokenWallet = _tokenWallet;
    }

    function changeWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }

}
