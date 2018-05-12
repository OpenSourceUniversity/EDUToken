// var ConvertLib = artifacts.require("./ConvertLib.sol");
var EDUToken = artifacts.require("./EDUToken.sol");

module.exports = function(deployer) {
  // var startDate = Math.floor(Date.now()/1000);

  deployer.deploy(EDUToken,
  	web3.eth.accounts[0],
  	web3.eth.accounts[1],
  	web3.eth.accounts[2],
  	web3.eth.accounts[3],
  	web3.eth.accounts[4],
    web3.eth.accounts[5],
    1150
  );
};
