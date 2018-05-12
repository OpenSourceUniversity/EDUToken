pragma solidity ^0.4.21;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
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

    // Call certifier
    Certifier public certifier;

    event EDUtransfered(address receiver, uint256 _amountOfEDU);
    event ETHcontributed(address contributor, uint256 _amountOfETH);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // GENERAL INFORMATION ABOUT THE TOKEN
    string public constant name = "EDU Token";
    string public constant symbol = "EDUx";
    uint256 public constant decimals = 18;
    string public version = "2.0";

    // Addresses
    address public ownerAddress;                                                // Address used by Open Source University
    address public saleAddress;                                                 // Address used in the crowdsale period
    address public sigTeamAndAdvisersAddress;                                   // EDU tokens for the team and advisers
    address public sigBountyProgramAddress;                                     // EDU tokens bounty program
    address public contributionsAddress;
    address public certifierAddress;

    // EDU amounts
    uint256 public TotalEDUSupply;
    uint256 public TokensForSale;
    uint256 public OSUniEDUSupply;
    uint256 public sigTeamAndAdvisersEDUSupply;
    uint256 public sigBountyProgramEDUSupply;

    // Flags
    bool public isTokenSellOpen;
    uint256 public LockEDUTeam;

    // Price
    uint256 public EDU_PER_ETH;
    uint256 public currentBalance;

    // Running totals
    uint256 public totalWEIInvested = 0;                                        // Total WEI invested
    uint256 public totalEDUsold = 0;                                            // Total EDUs sold
    uint256 public totalEDUSLeft = 0;                                           // Total EDUs left

    // MODIFIERS
    // Functions with this modifier can only be executed by the owner of following smart contract
    modifier onlyOwner() {
        if (msg.sender != ownerAddress) {
            revert();
        }
        _;
    }

    // Preventing
    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    // Freeze EDU tokens for TeamAndAdvisers for 1 year after the end of the presale
    modifier freezeTeamAndAdvisersEDUTokens(address _address) {
        if (_address == sigTeamAndAdvisersAddress) {
            if (LockEDUTeam > block.timestamp) { revert(); }
        }
        _;
    }


    // INITIALIZATIONS FUNCTION
    function EDUToken(
        address _saleAddress,
        address _sigTeamAndAdvisersAddress,
        address _sigBountyProgramAddress,
        address _certifierAddress,
        address _contributionsAddress,
        uint256 _EDU_PER_ETH
    )
        public
    {
        certifier = Certifier(_certifierAddress);

        // Set initial price of EDUTokens
        EDU_PER_ETH = _EDU_PER_ETH;

        // Owner of the contract
        ownerAddress = msg.sender;                                                               // Store owners address

        // Store addresses
        saleAddress = _saleAddress;
        sigTeamAndAdvisersAddress = _sigTeamAndAdvisersAddress;
        sigBountyProgramAddress = _sigBountyProgramAddress;
        contributionsAddress = _contributionsAddress;
        certifierAddress = _certifierAddress;

        // Initial EDU amounts
        TotalEDUSupply = 48000000*1000000000000000000;
        TokensForSale = 34800000*1000000000000000000;
        OSUniEDUSupply = 8400000*1000000000000000000;
        sigTeamAndAdvisersEDUSupply = 3840000*1000000000000000000;              // EDU tokens supply allocated for team and advisers
        sigBountyProgramEDUSupply = 960000*1000000000000000000;                 // EDU tokens supply allocated for bounty program

        transfer(contributionsAddress, OSUniEDUSupply);
        transfer(saleAddress, TokensForSale);
        transfer(sigTeamAndAdvisersAddress, sigTeamAndAdvisersEDUSupply);
        transfer(sigBountyProgramAddress, sigBountyProgramEDUSupply);

        totalSupply_ = TotalEDUSupply;                                           // Total EDU Token supply

        isTokenSellOpen = false;
        LockEDUTeam = 1511179200 + 1 years;
    }


    // FALLBACK FUNCTION
    function()
        public
        payable
        validDestination(msg.sender)
    {
        require(isTokenSellOpen);

        // Check if contributor passed KYC
        if (!certifier.certified(msg.sender)) {
            revert();
        }

        // Transaction value in Wei
        uint256 amountInWei = msg.value;
        require(amountInWei > 0);

        // Transaction value in EDU
        uint256 amountOfEDU = 0;
        amountOfEDU = amountInWei.mul(EDU_PER_ETH).div(1000000000000000000);

        currentBalance = this.balanceOf(saleAddress);
        require(currentBalance >= amountOfEDU);

        // Transfer contributions to Open Source University
        contributionsAddress.transfer(amountInWei);
        // Transfer the EDU tokens
        this.transfer(msg.sender, amountOfEDU);

        // Update total WEI Invested
        totalWEIInvested = totalWEIInvested.add(amountInWei);
        totalEDUsold = totalEDUsold.add(amountOfEDU);

        uint256 balanceSafe = balances[msg.sender].add(amountOfEDU);
        assert(balanceSafe > 0);
        balances[msg.sender] = balanceSafe;
        uint256 balanceDiv = balances[saleAddress].sub(amountOfEDU);
        balances[saleAddress] = balanceDiv;

        totalEDUSLeft = this.balanceOf(saleAddress);    // ??? is this going to be updated before current block is mined

        emit Transfer(saleAddress, msg.sender, amountOfEDU);
        emit EDUtransfered(msg.sender, amountOfEDU);
        emit ETHcontributed(msg.sender, msg.value.div(1000000000000000000));
    }

    /**
     * @dev Set contribution flag status
     * @param _allowContribution This allows EDU token sale to begin
     * @return A boolean that indicates if the operation was successful.
     */
    function setAllowContributionFlag(bool _allowContribution) public returns (bool) {
        require(msg.sender == ownerAddress);
        isTokenSellOpen = _allowContribution;
        return isTokenSellOpen;
    }

    /**
     * @dev Set genuine burning mechanism of EDU token in such a way also to
     *      update totalSupply of EDU tokens
     * @param _nrEDUToBurn  This argument specifies the amount of EDU tokens
     *      which will be burned from OSU token sale address.
     * @return Balance after burning process in token sale address
     */
    function burningOfEDU(uint256 _nrEDUToBurn) public returns (uint256) {
        require(msg.sender == ownerAddress);
        require(_nrEDUToBurn > 0);
        uint256 curBalance = this.balanceOf(saleAddress);
        require(curBalance >= _nrEDUToBurn);
        balances[saleAddress] = curBalance.sub(_nrEDUToBurn);
        totalSupply_ = totalSupply_.sub(_nrEDUToBurn);
        return balances[saleAddress];
    }

    function setEDUPrice(uint256 _valSale) public returns (uint256) {
        require(msg.sender == ownerAddress);
        EDU_PER_ETH = _valSale;
        return EDU_PER_ETH;
    }

    function setTeamAndAdvisersTokensPeriod(uint256 _value) public returns (uint256) {
        require(msg.sender == ownerAddress);
        LockEDUTeam = _value;
        return LockEDUTeam;
    }

    function updateCertifier(address _address) public returns (bool success) {
        require(msg.sender == ownerAddress);
        certifier = Certifier(_address);
        return true;
    }

    // Balance of a specific account
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) freezeTeamAndAdvisersEDUTokens(msg.sender) returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from, address _to, uint256 _amount) freezeTeamAndAdvisersEDUTokens(_from) returns (bool success) {
        if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {

            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) freezeTeamAndAdvisersEDUTokens(msg.sender) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


}
