pragma solidity ^0.4.21;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract Certifier {
    event Confirmed(address indexed who);
    event Revoked(address indexed who);
    function certified(address) public constant returns (bool);
    function get(address, string) public constant returns (bytes32);
    function getAddress(address, string) public constant returns (address);
    function getUint(address, string) public constant returns (uint);
}

contract EDUToken is StandardToken {
    using SafeMath for uint256;

    Certifier public certifier;

    event EDUtransfered(address receiver, uint256 _amountOfEDU);
    event ETHcontributed(address contributor, uint256 _amountOfETH);

    string public constant name = "EDU Token";
    string public constant symbol = "EDUX";
    uint256 public constant decimals = 18;

    address public ownerAddress;
    address public saleAddress;
    address public sigTeamAndAdvisersAddress;
    address public sigBountyProgramAddress;
    address public contributionsAddress;
    address public certifierAddress;

    uint256 public TotalEDUSupply;
    uint256 public TokensForSale;
    uint256 public OSUniEDUSupply;
    uint256 public sigTeamAndAdvisersEDUSupply;
    uint256 public sigBountyProgramEDUSupply;

    bool public isTokenSellOpen;
    uint256 public LockEDUTeam;

    uint256 public EDU_PER_ETH;
    uint256 public currentBalance;

    uint256 public totalWEIInvested = 0;
    uint256 public totalEDUsold = 0;
    uint256 public totalEDUSLeft = 0;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    constructor(
        address _saleAddress,
        address _sigTeamAndAdvisersAddress,
        address _sigBountyProgramAddress,
        address _certifierAddress,
        address _contributionsAddress,
        uint256 _EDU_PER_ETH
    ) public {
        certifier = Certifier(_certifierAddress);

        EDU_PER_ETH = _EDU_PER_ETH;

        ownerAddress = msg.sender;

        saleAddress = _saleAddress;
        sigTeamAndAdvisersAddress = _sigTeamAndAdvisersAddress;
        sigBountyProgramAddress = _sigBountyProgramAddress;
        contributionsAddress = _contributionsAddress;
        certifierAddress = _certifierAddress;

        TotalEDUSupply = 48000000*1000000000000000000;
        TokensForSale = 34800000*1000000000000000000;
        OSUniEDUSupply = 8400000*1000000000000000000;
        sigTeamAndAdvisersEDUSupply = 3840000*1000000000000000000;
        sigBountyProgramEDUSupply = 960000*1000000000000000000;

        transfer(contributionsAddress, OSUniEDUSupply);
        transfer(saleAddress, TokensForSale);
        transfer(sigTeamAndAdvisersAddress, sigTeamAndAdvisersEDUSupply);
        transfer(sigBountyProgramAddress, sigBountyProgramEDUSupply);

        totalSupply_ = TotalEDUSupply;

        isTokenSellOpen = false;
        LockEDUTeam = 1511179200 + 1 years;
    }

    function()
        public
        payable
        validDestination(msg.sender)
    {
        require(isTokenSellOpen);
        if (!certifier.certified(msg.sender)) {
            revert();
        }

        uint256 amountInWei = msg.value;
        require(amountInWei > 0);

        uint256 amountOfEDU = 0;
        amountOfEDU = amountInWei.mul(EDU_PER_ETH).div(1000000000000000000);

        currentBalance = this.balanceOf(saleAddress);
        require(currentBalance >= amountOfEDU);

        contributionsAddress.transfer(amountInWei);
        this.transfer(msg.sender, amountOfEDU);

        totalWEIInvested = totalWEIInvested.add(amountInWei);
        totalEDUsold = totalEDUsold.add(amountOfEDU);

        uint256 balanceSafe = balances[msg.sender].add(amountOfEDU);
        assert(balanceSafe > 0);
        balances[msg.sender] = balanceSafe;
        uint256 balanceDiv = balances[saleAddress].sub(amountOfEDU);
        balances[saleAddress] = balanceDiv;

        totalEDUSLeft = this.balanceOf(saleAddress);

        emit Transfer(saleAddress, msg.sender, amountOfEDU);
        emit EDUtransfered(msg.sender, amountOfEDU);
        emit ETHcontributed(msg.sender, msg.value.div(1000000000000000000));
    }

    function setAllowContributionFlag(bool _allowContribution) public returns (bool) {
        require(msg.sender == ownerAddress);
        isTokenSellOpen = _allowContribution;
        return isTokenSellOpen;
    }

    function setEDUPrice(uint256 _valSale) public returns (uint256) {
        require(msg.sender == ownerAddress);
        EDU_PER_ETH = _valSale;
        return EDU_PER_ETH;
    }

    function updateCertifier(address _address) public returns (bool success) {
        require(msg.sender == ownerAddress);
        certifier = Certifier(_address);
        return true;
    }

}
