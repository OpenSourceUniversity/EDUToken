var EDUToken = artifacts.require("./EDUToken.sol");
var EDUCrowdsale = artifacts.require("./EDUCrowdsale.sol");

module.exports = function(deployer) {
  var certifierAddresses = {
    "kovan": "0x5082a3716b8e5f2b164fffc38c5f0ae36a179974",
    "mainnet": process.env.CERTIFIER,
  }
  var certifier = certifierAddresses[
    process.env.DEPLOY_PRODUCTION == "true" ? "mainnet" : "kovan"
  ];
  var wallet = process.env.FUNDS_WALLET,
      tokenWallet = process.env.TOKEN_WALLET,
      cap = 34000 * (10 ** 18),
      openingTime = 1528113600,
      closingTime = 1530446400;

  console.log("Using certifier " + certifier);

  return deployer
    .then(() => {
      return deployer.deploy(EDUToken, certifier);
    })
    .then(() => {
      return deployer.deploy(
        EDUCrowdsale,
        wallet,
        EDUToken.address,
        tokenWallet,
        cap,
        openingTime,
        closingTime,
        certifier);
    });
};
