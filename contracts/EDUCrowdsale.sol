pragma solidity ^0.4.24;

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

    uint256 constant FIFTY_ETH = 50 * (10 ** 18);
    uint256 constant HUNDRED_AND_FIFTY_ETH = 150 * (10 ** 18);
    uint256 constant TWO_HUNDRED_AND_FIFTY_ETH = 250 * (10 ** 18);

    EDUToken public token;
    event TokenWalletChanged(address indexed newTokenWallet);
    event WalletChanged(address indexed newWallet);

    constructor(
        address _wallet,
        EDUToken _token,
        address _tokenWallet,
        uint256 _cap,
        uint256 _openingTime,
        uint256 _closingTime,
        address _certifier
    ) public
      Crowdsale(getCurrentRate(), _wallet, _token)
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
        if (block.timestamp < 1528156799) {         // 4th of June 2018 23:59:59 GTC
            return 1050;
        } else if (block.timestamp < 1528718400) {  // 11th of June 2018 12:00:00 GTC
            return 940;
        } else if (block.timestamp < 1529323200) {  // 18th of June 2018 12:00:00 GTC
            return 865;
        } else if (block.timestamp < 1529928000) {  // 25th of June 2018 12:00:00 GTC
            return 790;
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
        uint256 volumeBonus = _getVolumeBonus(currentRate, _weiAmount);
        return currentRate.mul(_weiAmount).add(volumeBonus);
    }

    function _getVolumeBonus(uint256 _currentRate, uint256 _weiAmount) internal view returns (uint256) {
        if (_weiAmount >= FIFTY_ETH) {
            if (_weiAmount >= HUNDRED_AND_FIFTY_ETH) {
                if (_weiAmount >= TWO_HUNDRED_AND_FIFTY_ETH) {
                    return _currentRate.mul(_weiAmount).mul(15).div(100);
                }
                return _currentRate.mul(_weiAmount).mul(10).div(100);
            }
            return _currentRate.mul(_weiAmount).mul(5).div(100);
        }
        return 0;
    }

    function changeTokenWallet(address _tokenWallet) external onlyOwner {
        require(_tokenWallet != address(0x0));
        tokenWallet = _tokenWallet;
        emit TokenWalletChanged(_tokenWallet);
    }

    function changeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0x0));
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

}
