
pragma solidity ^0.4.11;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract EDUToken is StandardToken {
	using SafeMath for uint256;

    // EVENTS
    event CreatedEDU(address indexed _creator, uint256 _amountOfEDU);

	// GENERAL INFO
	string public constant name = "EDUToken";
	string public constant symbol = "EDU";
	uint256 public constant decimals = 18;													// value in wei
	string public version = "0.3";

	// EDU TOKEN PURCHASE LIMITS
	uint256 public constant maxEarlyPresaleSupply = 2000000000000000000000000;				// Early presale supply
	uint256 public earlyPresaleEDUSupply;
	uint256 public constant maxPresaleSupply = 2200000000000000000000000;					// Presale supply
	uint256 public PresaleEDUSupply;

	// PURCHASE DATES
	uint256 public earlyPreSaleStartTime; 
	uint256 public earlyPreSaleEndTime; 
	uint256 public preSaleStartTime;
	uint256 public preSaleEndTime;
	uint256 public saleStartTime;
	uint256 public saleEndTime; 

	// PRICING INFO
	uint256 public constant EDU_PER_ETH_PRE_SALE_50 = 1110;  								// 50% bonus early presale 1110 EDU = 1 ETH
	uint256 public constant EDU_PER_ETH_PRE_SALE_20 = 888;									// 20% bonus presale 888 EDU = 1 ETH
	uint256 public constant EDU_PER_ETH_SALE = 740;  										// sale 740 EDU = 1 ETH
	
	// EXCHANGE
	uint256 public rateBTCtoETH;
	uint256 public rateUSDtoETH;
	uint256 public currencyExchange;															// ETH=0, BTC=1, USD=2

	// ADDRESSES
	address public ownerAddress; 															// The owners address

	// STATE INFO	
	bool public allowInvestment = true;														// Flag to change if transfering is allowed
	uint256 public totalWEIInvested = 0;
	uint256 public totalEDUSLeft = 0; 														// Total WEI invested
	uint256 public totalEDUSAllocated = 0;													// Total EDU allocated
	mapping (address => uint256) public WEIContributed; 									// Total WEI Per Account


	// INITIALIZATIONS FUNCTION
	function EDUToken() {
		require(msg.sender == ownerAddress);

		uint256 totalSupply = 42*1000000*1000000000000000000; 								// MAX TOTAL EDU TOKENS 42 million
		uint256 totalEDUSReserved = totalSupply.mul(22).div(100);							// 22% reserved for OS.UNIVERSITY
		earlyPresaleEDUSupply = maxEarlyPresaleSupply; 										// MAX TOTAL DURING EARLY PRESALE (2 000 000 EDU)
		PresaleEDUSupply = maxPresaleSupply; 												// MAX TOTAL DURING PRESALE (2 200 000 EDU)

		balances[msg.sender] = totalEDUSReserved;
		totalEDUSAllocated = totalEDUSReserved;
		totalEDUSLeft = totalSupply.sub(totalEDUSReserved);
	}

	// FALL BACK FUNCTION TO ALLOW ETHER INVESTMENTS
	function() payable {
		require(allowInvestment);

		// Transaction value in Wei
		uint256 amountInWei = msg.value;
		// Presale smallest investment is 0.01 ether
		require(10000000000000000 <= amountInWei);
		// Initial amounts
		uint256 amountOfEDU = 0;
		
		if (block.timestamp > earlyPreSaleStartTime && block.timestamp < earlyPreSaleEndTime) {
			// First presale period 10 days
			amountOfEDU = amountInWei.mul(EDU_PER_ETH_PRE_SALE_50);
			require(earlyPresaleEDUSupply >= amountOfEDU);
			earlyPresaleEDUSupply = earlyPresaleEDUSupply.sub(amountOfEDU);
		} else if (block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) {
			// Second presale period 14 days
			amountOfEDU = amountInWei.mul(EDU_PER_ETH_PRE_SALE_20);
			require(PresaleEDUSupply >= amountOfEDU);
			PresaleEDUSupply = PresaleEDUSupply.sub(amountOfEDU);
		} else if (block.timestamp > saleStartTime && block.timestamp < saleEndTime) {
			// Sale period
			amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE);
			require(totalEDUSLeft >= amountOfEDU);
		} else {
			// Outside investment period 
			revert();
		}

		// Update total EDU balance
		totalEDUSLeft = totalEDUSLeft.sub(amountOfEDU);
		totalEDUSAllocated = totalEDUSAllocated + amountOfEDU;

		// CHECK VALUES
		assert(totalEDUSAllocated <= totalSupply);
		assert(totalEDUSAllocated > 0);

		// Update user EDU balance
		uint256 balanceSafe = balances[msg.sender].add(amountOfEDU);
		balances[msg.sender] = balanceSafe;

		// Update total WEI Invested
		totalWEIInvested = totalWEIInvested.add(amountInWei);

		// Update total WEI Invested by account
		uint256 contributedSafe = WEIContributed[msg.sender].add(amountInWei);
		WEIContributed[msg.sender] = contributedSafe;

		// CHECK VALUES
		assert(balanceSafe > 0);
		assert(totalWEIInvested > 0);
		assert(contributedSafe > 0);

		// CREATE EVENT FOR SENDER
		CreatedEDU(msg.sender, amountOfEDU);
	}
	
	
	// METHODS

	function checkPresaleCurrentAmont (uint _part) public constant returns (uint256) {
		// This method is not called by another contracts
		if (_part == 1) { 
			return earlyPresaleEDUSupply; 
		} else { 
			return PresaleEDUSupply; 
		}
	}

	function checkSaleCurrentAmont () public constant returns (uint256) {
		// This method is not called by another contracts
		return totalEDUSLeft;
	}

	function changeAllowInvestment(bool _allowInvestment) {
		require(msg.sender == ownerAddress);
		allowInvestment = _allowInvestment;
	}

	function transferEther(address addressToSendTo, uint256 value) {
		require(msg.sender == ownerAddress);
		addressToSendTo.transfer(value);
	}

	function changeSaleTimes(uint256 _saleStartTime, uint256 _saleEndTime) {
		require(msg.sender == ownerAddress);
		saleStartTime = _saleStartTime;
		saleEndTime	= _saleEndTime;
	}

	function changeEarlyPresaleTime(uint256 _earlyPreSaleStartTime, uint256 _earlyPreSaleEndTime) {
		require(msg.sender == ownerAddress);
		earlyPreSaleStartTime = _earlyPreSaleStartTime;
		earlyPreSaleEndTime = _earlyPreSaleEndTime;
	}

	function changePresaleTime(uint256 _preSaleStartTime, uint256 _preSaleEndTime) {
		require(msg.sender == ownerAddress);
		preSaleStartTime = _preSaleStartTime;
		preSaleEndTime = _preSaleEndTime;
	}

	function exchangeRateBTCtoETH(uint _rateBTCtoETH) {
		require(msg.sender == ownerAddress);
		rateBTCtoETH = _rateBTCtoETH;
	}

	function exchangeRateUSDtoETH(uint _rateUSDtoETH) {
		require(msg.sender == ownerAddress);
		rateUSDtoETH = _rateUSDtoETH;
	}

	function currency(uint _index) {
		require(msg.sender == ownerAddress);
		if (_index == 0 || _index == 1 || _index == 2) {
			currencyExchange = _index;
		}
	}

}
