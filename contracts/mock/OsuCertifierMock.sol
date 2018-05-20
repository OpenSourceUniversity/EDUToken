pragma solidity ^0.4.24;

import "../kyc/Certifier.sol";
import "./OwnedMock.sol";



contract OsuCertifierMock is OwnedMock, Certifier {

    function certified(address _who) public constant returns (bool) {
        return certs[_who];
    }

    function certify(address _who) public only_owner {
        certs[_who] = true;
        Confirmed(_who);
    }

    function revoke(address _who) public only_owner {
        certs[_who] = false;
        Revoked(_who);
    }

    // Unused methods
    function get(address, string) public constant returns (bytes32) {}
    function getAddress(address, string) public constant returns (address) {}
    function getUint(address, string) public constant returns (uint) {}

    mapping (address => bool) certs;
}
