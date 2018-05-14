var EDUToken = artifacts.require("./EDUToken.sol");

module.exports = function(deployer) {
  deployer.deploy(EDUToken, "0x0000000000000000000000000000000000000000");
};
