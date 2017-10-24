pragma solidity ^0.4.15;
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract EDUToken is StandardToken {
		using SafeMath for uint256;

    // EVENTS
    event CreatedEDU(address indexed _creator, uint256 _amountOfEDU);
		event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

		// GENERAL INFORMATION ABOUT THE TOKEN
		string public constant name = "EDU Token";
		string public constant symbol = "EDU";
		uint256 public constant decimals = 4;
		string public version = "0.8";

		// CONSTANTS
		// Purchase limits
		uint256 public constant TotalEDUSupply = 48000000*10000; 										// MAX TOTAL EDU TOKENS 48 million
		uint256 public constant maxEarlyPresaleEDUSupply = 2601600*10000;						// Maximum EDU tokens early presale supply (Presale Stage 1)
		uint256 public constant maxPresaleEDUSupply = 2198400*10000;								// Maximum EDU tokens presale supply (Presale Stage 2)
		uint256 public constant OSUniEDUSupply = 8400000*10000;											// Open Source University EDU tokens supply
		uint256 public constant SaleEDUSupply = 30000000*10000;											// Allocated EDU tokens for crowdsale
		uint256 public constant TeamAndAdvisersEDUSupply = 3840000*10000;						// EDU tokens supply allocated for team and advisers
		uint256 public constant BountyProgramEDUSupply = 960000*10000;							// EDU tokens supply allocated for bounty program

		//ASSIGNED IN INITIALIZATION
		// Time limits
		uint256 public earlyPreSaleStartTime;																				// Start early presale time (start presale stage 1)
		uint256 public earlyPreSaleEndTime;																					// End early presale time
		uint256 public preSaleStartTime;																						// Start presale time (start presale stage 2)
		uint256 public preSaleEndTime;																							// End presale time
		uint256 public saleStartTime;																								// Start sale time (start crowdsale)
		uint256 public saleEndTime;																									// End crowdsale

		// Purchase limits
		uint256 public earlyPresaleEDUSupply;
		uint256 public PresaleEDUSupply;

		// Token bonuses
		uint256 public EDU_PER_ETH_EARLY_PRE_SALE = 1350;  													// 1350 EDU = 1 ETH  presale stage 1
		uint256 public EDU_PER_ETH_PRE_SALE = 1200;																	// 1200 EDU = 1 ETH  presale stage 2
		uint256 public EDU_PER_ETH_SALE_1 = 790;  																	// 790 EDU = 1 ETH   crowdsale week 1
		uint256 public EDU_PER_ETH_SALE_2 = 760;																		// 760 EDU = 1 ETH   crowdsale week 2
		uint256 public EDU_PER_ETH_SALE_3 = 730;																		// 730 EDU = 1 ETH   crowdsale week 3
		uint256 public EDU_PER_ETH_SALE_4 = 700;																		// 700 EDU = 1 ETH 	 crowdsale week 4

		// Addresses
		address public ownerAddress; 																								// Address used by Open Source University
		address public earlyPresaleAddress; 																				// Address used in the early presale period
		address public presaleAddress;																							// Address used in the presale period
		address public saleAddress;																									// Address used in the crowdsale period
		address public multisigTeamAndAdvisersAddress;															// EDU tokens for the team and advisers
		address public multisigBountyProgramAddress;																// EDU tokens bounty program
		address public multisigAddress;																							// Address used for contributions

		// Contribution indicator
		bool public allowContribution = true;																				// Flag to change if transfering is allowed

		// Running totals
		uint256 public totalWEIInvested = 0;																				// Total WEI invested
		uint256 public totalEDUSLeft = 0; 																					// Total EDU left
		uint256 public totalEDUSAllocated = 0;																			// Total EDU allocated
		mapping (address => uint256) public WEIContributed; 												// Total WEI Per Account

		// Checks saving GAS
		bool presaleCheck;
		bool saleCheck;

		// Owner of account approves the transfer of an amount to another account
  	mapping(address => mapping (address => uint256)) allowed;

		// MODIFIERS
		// Functions with this modifier can only be executed by the owner of following smart contract
	  modifier onlyOwner() {
	  	if (msg.sender != ownerAddress) {
	        revert();
	    }
	    _;
	  }

		// Minimal contribution which will be processed is 0.01 ETH
		modifier minimalContribution() {
			require(10000000000000000 <= msg.value);
			_;
		}

		// INITIALIZATIONS FUNCTION
		function EDUToken(
			address _earlyPresaleAddress,
			address _presaleAddress,
			address _saleAddress,
			address _multisigTeamAndAdvisersAddress,
			address _multisigBountyProgramAddress,
			address _multisigAddress
		) {
				ownerAddress = msg.sender;																							// Store owners address
				earlyPresaleAddress = _earlyPresaleAddress;															// Store early presale address
				presaleAddress = _presaleAddress;																				// Store presale address
				saleAddress = _saleAddress;
				multisigTeamAndAdvisersAddress = _multisigTeamAndAdvisersAddress;				// Store sale address
				multisigBountyProgramAddress = _multisigBountyProgramAddress;
				multisigAddress = _multisigAddress;

				earlyPreSaleStartTime = now;																						// Start earli presale right after deploying of the smart contract
				earlyPreSaleEndTime = earlyPreSaleStartTime + 1 weeks;									// End of early presale period 1 week after the begining of presale
				preSaleStartTime = earlyPreSaleEndTime;																	// Start of presale right after end of early presale period
				preSaleEndTime = preSaleStartTime + 1 weeks;														// End of the presale period 1 week after end of early presale
				saleStartTime = preSaleEndTime;																					// Start of sale right after the end of presale period
				saleEndTime = saleStartTime + 4 weeks;																	// End of the sale period 4 weeks after the beginning of the

				earlyPresaleEDUSupply = maxEarlyPresaleEDUSupply; 											// MAX TOTAL DURING EARLY PRESALE (2 000 000 EDU Tokens)
				PresaleEDUSupply = maxPresaleEDUSupply; 																// MAX TOTAL DURING PRESALE (2 200 000 EDU Tokens)

				balances[multisigAddress] = OSUniEDUSupply;																// Allocating EDU tokens for Open Source University
				balances[earlyPresaleAddress] = maxEarlyPresaleEDUSupply;								// Allocating EDU tokens for early presale
				balances[presaleAddress] = maxPresaleEDUSupply;													// Allocating EDU tokens for presale
				balances[saleAddress] = SaleEDUSupply;																	// Allocating EDU tokens for sale
				balances[multisigTeamAndAdvisersAddress] = TeamAndAdvisersEDUSupply;		// Allocating EDU tokens for team and advisers
				balances[multisigBountyProgramAddress] = BountyProgramEDUSupply;				// Bounty program address


				totalEDUSAllocated = OSUniEDUSupply + TeamAndAdvisersEDUSupply + BountyProgramEDUSupply;
				totalEDUSLeft = SafeMath.sub(TotalEDUSupply, totalEDUSAllocated);				// EDU Tokens left for sale

				totalSupply = TotalEDUSupply;																						// Total EDU Token supply

				saleCheck = false;
				presaleCheck = false;
		}



	// FALL BACK FUNCTION TO ALLOW ETHER CONTRIBUTIONS
	function()
		payable
		minimalContribution
	{
		require(allowContribution);

		// Transaction value in Wei
		uint256 amountInWei = msg.value;

		// Initial amounts
		uint256 amountOfEDU = 0;
		uint256 earlyPresaleEndBalance = 0;
		uint256 presaleEndBalance = 0;

		if (block.timestamp > earlyPreSaleStartTime && block.timestamp < earlyPreSaleEndTime) {
			// Early presale period
			amountOfEDU = amountInWei.mul(EDU_PER_ETH_EARLY_PRE_SALE).div(100000000000000);
			require(earlyPresaleEDUSupply >= amountOfEDU);
			require(updateEDUBalanceFunc(earlyPresaleAddress, amountOfEDU));
			earlyPresaleEDUSupply = earlyPresaleEDUSupply.sub(amountOfEDU);
		} else if (block.timestamp > preSaleStartTime && block.timestamp < preSaleEndTime) {
			// Second presale period
			amountOfEDU = amountInWei.mul(EDU_PER_ETH_PRE_SALE).div(100000000000000);
			require(PresaleEDUSupply >= amountOfEDU);
			require(updateEDUBalanceFunc(presaleAddress, amountOfEDU));
			PresaleEDUSupply = PresaleEDUSupply.sub(amountOfEDU);
			if (!presaleCheck) {
				earlyPresaleEndBalance = balances[earlyPresaleAddress];
				if (earlyPresaleEndBalance > 0) {
						balances[earlyPresaleAddress] = 0;
						balances[presaleAddress] += earlyPresaleEndBalance;
						presaleCheck = true;
				}
			}
		} else if (block.timestamp > saleStartTime && block.timestamp < saleEndTime) {
			// Sale period
			if (block.timestamp <= SafeMath.add(saleStartTime, 1 weeks)) {
					amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE_1).div(100000000000000);
			} else if (block.timestamp <= SafeMath.add(saleStartTime, 2 weeks)) {
					amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE_2).div(100000000000000);
			} else if (block.timestamp <= SafeMath.add(saleStartTime, 3 weeks)) {
					amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE_3).div(100000000000000);
			} else {
					amountOfEDU = amountInWei.mul(EDU_PER_ETH_SALE_4).div(100000000000000);
			}
			require(totalEDUSLeft >= amountOfEDU);
			require(updateEDUBalanceFunc(saleAddress, amountOfEDU));
			if (!saleCheck) {
				earlyPresaleEndBalance = balances[earlyPresaleAddress];
				presaleEndBalance = balances[presaleAddress];
				if (earlyPresaleEndBalance > 0) {
						balances[earlyPresaleAddress] = 0;
						balances[saleAddress] += earlyPresaleEndBalance;
					}
				if (presaleEndBalance > 0) {
						balances[presaleAddress] = 0;
						balances[saleAddress] += presaleEndBalance;
				}
				saleCheck = true;
			}
		} else {
			// Outside contribution period
			revert();
		}


		// Update total WEI Invested
		totalWEIInvested = totalWEIInvested.add(amountInWei);
		assert(totalWEIInvested > 0);
		// Update total WEI Invested by account
		uint256 contributedSafe = WEIContributed[msg.sender].add(amountInWei);
		assert(contributedSafe > 0);
		WEIContributed[msg.sender] = contributedSafe;

		// Transfer contributions to Open Source University
		multisigAddress.transfer(amountInWei);

		// CREATE EVENT FOR SENDER
		CreatedEDU(msg.sender, amountOfEDU);
	}


	/**
   * @dev Function for updating the balance and double checks allocated EDU tokens
   * @param _from The address that will send EDU tokens.
   * @param _amountOfEDU The amount of tokens which will be send to contributor.
   * @return A boolean that indicates if the operation was successful.
   */
	function updateEDUBalanceFunc(address _from, uint256 _amountOfEDU) internal returns (bool) {
			// Update total EDU balance
			totalEDUSLeft = totalEDUSLeft.sub(_amountOfEDU);
			totalEDUSAllocated += _amountOfEDU;

			// Validate EDU allocation
			if (totalEDUSAllocated <= TotalEDUSupply && totalEDUSAllocated > 0) {
					// Update user EDU balance
					uint256 balanceSafe = balances[msg.sender].add(_amountOfEDU);
					assert(balanceSafe > 0);
					balances[msg.sender] = balanceSafe;
					uint256 balanceDiv = balances[_from].sub(_amountOfEDU);
					balances[_from] = balanceDiv;
					return true;
			} else {
					totalEDUSLeft = totalEDUSLeft.add(_amountOfEDU);
					totalEDUSAllocated -= _amountOfEDU;
					return false;
			}

	}



	// METHODS
	/**
   * @dev Gets current EDU amount in presale
   * @param _part Part of presale period (early presale '1')
   * @return A uint256 containing current EDU amount in presale
   */
	function getPresaleCurrentAmount(uint _part) public constant returns (uint256 CurrentPresaleAmount) {
		// This method is not called by another contracts
		if (_part == 1) {
			return earlyPresaleEDUSupply;
		} else {
			return PresaleEDUSupply;
		}
	}


	/**
   * @dev Gets current EDU amount for sale
   * @return A uint256 containing current EDU amount for sale
   */
	function getSaleCurrentAmount() public constant returns (uint256 CurrentSaleAmount) {
		// This method is not called by another contracts
		return totalEDUSLeft;
	}

	/**
   * @dev Set contribution flag status
	 * @param _allowContribution This is additional parmition for the contributers
   * @return A boolean that indicates if the operation was successful.
   */
	function setAllowContributionFlag(bool _allowContribution) returns (bool success) {
		require(msg.sender == ownerAddress);
		allowContribution = _allowContribution;
		return true;
	}

	/**
   * @dev Get contribution flag status
   * @return A boolean that indicates current status of the flag.
   */
	function getAllowContributionFlag() returns (bool) {
		require(msg.sender == ownerAddress);
		return allowContribution;
	}

	/**
   * @dev Set the sale period
	 * @param _saleStartTime Sets the starting time of the sale period
	 * @param _saleEndTime Sets the end time of the sale period
   * @return A boolean that indicates if the operation was successful.
   */
	function setSaleTimes(uint256 _saleStartTime, uint256 _saleEndTime) returns (bool success) {
		require(msg.sender == ownerAddress);
		saleStartTime = _saleStartTime;
		saleEndTime	= _saleEndTime;
		return true;
	}

	/**
   * @dev Set the early presale period if necessary
	 * @param _earlyPreSaleStartTime Sets the starting time of the early presale period
	 * @param _earlyPreSaleEndTime Sets the end time of the early presale period
   * @return A boolean that indicates if the operation was successful.
   */
	function setEarlyPresaleTime(uint256 _earlyPreSaleStartTime, uint256 _earlyPreSaleEndTime) returns (bool success) {
		require(msg.sender == ownerAddress);
		earlyPreSaleStartTime = _earlyPreSaleStartTime;
		earlyPreSaleEndTime = _earlyPreSaleEndTime;
		return true;
	}

	/**
   * @dev Set change the presale period if necessary
	 * @param _preSaleStartTime Sets the starting time of the presale period
	 * @param _preSaleEndTime Sets the end time of the presale period
   * @return A boolean that indicates if the operation was successful.
   */
	function setPresaleTime(uint256 _preSaleStartTime, uint256 _preSaleEndTime) returns (bool success) {
		require(msg.sender == ownerAddress);
		preSaleStartTime = _preSaleStartTime;
		preSaleEndTime = _preSaleEndTime;
		return true;
	}

	// Rates update
  function edupricesale(uint256 _valEarlyPresale, uint256 _valPresale, uint256 _valSale1, uint256 _valSale2, uint256 _valSale3, uint256 _valSale4) returns (bool success) {
		require(msg.sender == ownerAddress);
		EDU_PER_ETH_EARLY_PRE_SALE = _valEarlyPresale;
		EDU_PER_ETH_PRE_SALE = _valPresale;
		EDU_PER_ETH_SALE_1 = _valSale1;
		EDU_PER_ETH_SALE_2 = _valSale2;
		EDU_PER_ETH_SALE_3 = _valSale3;
		EDU_PER_ETH_SALE_4 = _valSale4;
		return true;
	}

	// Balance of a specific account
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	// Transfer the balance from owner's account to another account
	function transfer(address _to, uint256 _amount) returns (bool success) {
			if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
					balances[msg.sender] -= _amount;
					balances[_to] += _amount;
					Transfer(msg.sender, _to, _amount);
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
	function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
				if (balances[_from] >= _amount
						 && allowed[_from][msg.sender] >= _amount
						 && _amount > 0
						 && balances[_to] + _amount > balances[_to]) {
						 balances[_from] -= _amount;
						 allowed[_from][msg.sender] -= _amount;
						 balances[_to] += _amount;
						 Transfer(_from, _to, _amount);
						 return true;
				} else {
						 return false;
				}
	}

	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
  function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

}
