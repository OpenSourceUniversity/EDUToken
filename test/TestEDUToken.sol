pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EDUToken.sol";

contract TestEDUToken {

    function testInitialBalanceUsingDeployedContract() public {
        EDUToken edu = EDUToken(DeployedAddresses.EDUToken());

        uint expected = 48000000 * (10 ** 18);

        Assert.equal(edu.balanceOf(tx.origin), expected, "Owner should have 10000 EDU initially");
    }

}
