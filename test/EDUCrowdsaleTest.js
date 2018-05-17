
var EDUCrowdsale = artifacts.require("EDUCrowdsale");
var EDUToken = artifacts.require("EDUToken");
var Certifier = artifacts.require("OsuCertifierMock");
const DECIMAL = 10 ** 18;
const BigNumber = web3.BigNumber;
const duration = {
    seconds: function (val) { return val; },
    minutes: function (val) { return val * this.seconds(60); },
    hours: function (val) { return val * this.minutes(60); },
    days: function (val) { return val * this.hours(24); },
    weeks: function (val) { return val * this.days(7); },
    years: function (val) { return val * this.days(365); },
};


contract("EDUCrowdsale", function (accounts) {
    const rate = 1050;
    const wallet = accounts[0];
    const tokenWallet = accounts[8];
    const cap = new BigNumber(web3.toWei(100, 'ether')); // 100 ether value
    let crowdsale;
    let certifier;
    let eduToken;

    before(async function () {
        await advanceBlock();
    });

    beforeEach(async function () {
        this.openingTime = latestTime() + 2;
        console.log("deploy time : " + this.openingTime);
        this.closingTime = this.openingTime + duration.weeks(1);
        certifier = await Certifier.new();
        eduToken = await EDUToken.new(certifier.address, {from: tokenWallet});
        crowdsale = await EDUCrowdsale.new(rate
            , wallet
            , eduToken.address
            , tokenWallet
            , cap
            , this.openingTime
            , this.closingTime
            , certifier.address);
        console.log("contract time: " + new Date() / 1000);
        await eduToken.approve(crowdsale.address, 1000 * DECIMAL, {from: tokenWallet});
    });

    describe('crowdsale new investor', async function () {

         it('should be able to contribute', async function () {
            // await increaseTimeTo(this.openingTime + 1);
            const value = 10 * DECIMAL;
            const investor = accounts[1];
            await crowdsale.sendTransaction({value: value, from: investor});
            let investorBalance = await eduToken.balanceOf(investor);
            assert(investorBalance.eq(value * rate));
        });

         it('should not be able to transfer without kyc', async function () {
            // await increaseTimeTo(this.openingTime + 1);
            const value = 10 * DECIMAL;
            const investor = accounts[1];
            await crowdsale.sendTransaction({value: value, from: investor});

            try {
                await eduToken.transfer(accounts[3],2 * DECIMAL, {from:investor});
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
                var investorBalance = await eduToken.balanceOf(investor)
                assert(investorBalance.eq(value * rate))
            }

        });

         it('should be able to transfer after KYC', async function () {
            // await increaseTimeTo(this.openingTime + 1);
            const valueToBuy = 5 * DECIMAL;
            const valueToSend = 3 * DECIMAL;
            const investor = accounts[1];
            const reciever = accounts[2];
            await crowdsale.sendTransaction({value: valueToBuy, from: investor});
            await certifier.certify(investor);
            await eduToken.transfer(reciever,valueToSend,{from:investor});
            const investorBalance = await eduToken.balanceOf(investor);
            const recieverBalance = await eduToken.balanceOf(reciever);
            assert(investorBalance.eq(valueToBuy - valueToSend));
            assert(recieverBalance.eq(valueToSend));
        });

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
                return err2 ? reject(err2) : resolve(res);
            });
        });
    });
}



function increaseTimeTo (target) {
    let now = latestTime();
    if (target < now) throw Error(`Cannot increase current time(${now}) to a moment in the past(${target})`);
    let diff = target - now;
    return increaseTime(diff);
}

function latestTime () {
    return web3.eth.getBlock('latest').timestamp;
}

