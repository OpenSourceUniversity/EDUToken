var EDUToken = artifacts.require("./EDUToken.sol");
var EDUCrowdsale = artifacts.require("./EDUCrowdsale.sol");

module.exports = function(deployer) {
  var certifierAddresses = {
    "kovan": "0x5082a3716b8e5f2b164fffc38c5f0ae36a179974",
    "mainnet": "0x7c465059d3288cf502d2c3cc32db825c2cfc80ba",
  }
  var certifier = certifierAddresses[
    process.env.DEPLOY_PRODUCTION == "true" ? "mainnet" : "kovan"
  ];
  var rate = 1000,
      wallet = "0xFaa1447B9Ae34C3893b486b61906B5415106eF57",
      tokenWallet = "0xFaa1447B9Ae34C3893b486b61906B5415106eF57",
      cap = 34000 * (10 ** 18);

  console.log("Using certifier " + certifier);

  return deployer
    .then(() => {
      return deployer.deploy(EDUToken, certifier);
    })
    .then(() => {
      return deployer.deploy(
        EDUCrowdsale,
        rate, wallet, EDUToken.address, tokenWallet, cap, certifier);
    });
};
