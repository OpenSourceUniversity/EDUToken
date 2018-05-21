var EDUCrowdsale = artifacts.require("EDUCrowdsale");
var EDUToken = artifacts.require("EDUToken");
var Certifier = artifacts.require("OsuCertifierMock");
const DECIMAL = 10 ** 18;
const BigNumber = web3.BigNumber;

const presale1 = 1528718400;
const rate1 = 1050;
const presale2 = 1529323200;
const rate2 = 850;
const presale3 = 1529928000;
const rate3 = 750;

const openingTime = 1528113600;
const closingTime = 1530446400;


/*
IMPORTANT! Tests should be executed one by one, with restart after each, because of impossibility of reverting EVM time
before last mined block.
 */
contract("rate test", function (accounts) {
    const wallet = accounts[0];
    const tokenWallet = accounts[8];
    const cap = new BigNumber(web3.toWei(34000, 'ether'));
    let crowdsale;
    let certifier;
    let eduToken;

    before(async function () {
        await advanceBlock();
        certifier = await Certifier.new();
        eduToken = await EDUToken.new(certifier.address, {from: tokenWallet});
        crowdsale = await EDUCrowdsale.new(wallet
            , eduToken.address
            , tokenWallet
            , cap
            , openingTime
            , closingTime
            , certifier.address);
        eduToken.addManager(crowdsale.address, {from:tokenWallet});
        await eduToken.approve(crowdsale.address, 5000000 * DECIMAL, {from: tokenWallet});
    });


    describe('rate tests', async function () {
        // it('presale1', async function () {
        //     await increaseTimeTo(openingTime + 1);
        //     const value = 1 * DECIMAL;
        //     const investor = accounts[1];
        //     await crowdsale.sendTransaction({value: value, from: investor});
        //     let investorBalance = await eduToken.balanceOf(investor);
        //     assert(investorBalance.eq(value * rate1));
        // });

        // it('presale2', async function () {
        //     await increaseTimeTo(presale2 + 1);
        //     const value = 10 * DECIMAL;
        //     const investor = accounts[1];
        //     await crowdsale.sendTransaction({value: value, from: investor});
        //     let investorBalance = await eduToken.balanceOf(investor);
        //     assert(investorBalance.eq(value * rate2));
        // });

        // it('presale3', async function () {
        //     await increaseTimeTo(presale3 + 1);
        //     const value = 10 * DECIMAL;
        //     const investor = accounts[1];
        //     await crowdsale.sendTransaction({value: value, from: investor});
        //     let investorBalance = await eduToken.balanceOf(investor);
        //     assert(investorBalance.eq(value * rate3));
        // });
    });


});

function advanceBlock () {
    return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: Date.now(),
        }, (err, res) => {
            return err ? reject(err) : resolve(res);
        });
    });
}

// Advances the block number so that the last mined block is `number`.
async function advanceToBlock (number) {
    if (web3.eth.blockNumber > number) {
        throw Error(`block number ${number} is in the past (current is ${web3.eth.blockNumber})`);
    }

    while (web3.eth.blockNumber < number) {
        await advanceBlock();
    }
}

function increaseTime (duration) {
    const id = Date.now();

    return new Promise((resolve, reject) => {
        web3.currentProvider.sendAsync({
            jsonrpc: '2.0',
            method: 'evm_increaseTime',
            params: [duration],
            id: id,
        }, err1 => {
            if (err1) return reject(err1);

            web3.currentProvider.sendAsync({
                jsonrpc: '2.0',
                method: 'evm_mine',
                id: id + 1,
            }, (err2, res) => {
                return  resolve(res);
            });
        });
    });
}

const duration = {
    seconds: function (val) { return val; },
    minutes: function (val) { return val * this.seconds(60); },
    hours: function (val) { return val * this.minutes(60); },
    days: function (val) { return val * this.hours(24); },
    weeks: function (val) { return val * this.days(7); },
    years: function (val) { return val * this.days(365); },
};

function increaseTimeTo (target) {
    let now = latestTime();
    let diff = target - now;
    return increaseTime(diff);
}

function latestTime () {
    return web3.eth.getBlock('latest').timestamp;
}



