// var ConvertLib = artifacts.require("./ConvertLib.sol");
var EDUToken = artifacts.require("./EDUToken.sol");

module.exports = function(deployer) {
  deployer.deploy(EDUToken);
};
