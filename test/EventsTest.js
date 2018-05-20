var EDUCrowdsale = artifacts.require("EDUCrowdsale");
var EDUToken = artifacts.require("EDUToken");
var Certifier = artifacts.require("OsuCertifierMock");
const DECIMAL = 10 ** 18;
const BigNumber = web3.BigNumber;

const duration = {
    seconds: function (val) {
        return val;
    },
    minutes: function (val) {
        return val * this.seconds(60);
    },
    hours: function (val) {
        return val * this.minutes(60);
    },
    days: function (val) {
        return val * this.hours(24);
    },
    weeks: function (val) {
        return val * this.days(7);
    },
    years: function (val) {
        return val * this.days(365);
    },
};


/*
IMPORTANT! ganache should be restarted after execution of tests for proper work
 */
contract("EventsTest", function (accounts) {
    const rate = 1050;
    const wallet = accounts[0];
    const tokenWallet = accounts[8];
    let cap = new BigNumber(web3.toWei(34, 'ether'));
    let crowdsale;
    let certifier;
    let eduToken;

    before(async function () {
        await advanceBlock();
    });

    beforeEach(async function () {
        this.openingTime = latestTime() + duration.days(1);
        this.closingTime = this.openingTime + duration.weeks(4);
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
        await eduToken.addManager(crowdsale.address, {from: tokenWallet});
        await eduToken.approve(crowdsale.address, 5000000 * DECIMAL, {from: tokenWallet});
    });


    describe('certifier events', async function () {

        const certified = accounts[5];
        it('confirmed event emited', async function () {
            await certifier.certify(certified).then((result) => {
                var log = result.logs[0];
                assert.equal(log.event, "Confirmed");
                assert.equal(log.args.who, certified);
            });
        });

        it('revoked event emited', async function () {
            await certifier.certify(certified);
            await certifier.revoke(certified).then((result) => {
                var log = result.logs[0];
                assert.equal(log.event, "Revoked");
                assert.equal(log.args.who, certified);
            });
        });

    });

    describe('token events', async function () {

        it('burn event emited', async function () {
            await eduToken.burn(1000, {from: tokenWallet}).then((result) =>{
               var log = result.logs[0];
               assert.equal(log.event, "Burn");
               assert.equal(log.args.burner, tokenWallet);
               assert.equal(log.args.value, 1000);
            });
        });

        it('transfer event emited', async function () {
            await eduToken.transfer(accounts[1], 10 * DECIMAL, {from:tokenWallet}).then((result) =>{
               var log = result.logs[0];
               assert.equal(log.event, "Transfer");
            });
        });

        it('approval event emited', async function () {
            await eduToken.approve(accounts[1], 1000 * DECIMAL, {from: tokenWallet}).then((result) =>{
                var log = result.logs[0];
                assert.equal(log.event, "Approval");
            });
        });

        it('add manager event emited', async function () {
            await eduToken.addManager(accounts[1], {from:tokenWallet}).then((result) =>{
                var log = result.logs[0];
                assert.equal(log.event, "ManagerAdded");
            });
        });

        it('remove manager event emited', async function () {
            await eduToken.removeManager(crowdsale.address,{from:tokenWallet}).then((result) =>{
                var log = result.logs[0];
                assert.equal(log.event, "ManagerRemoved");
            });
        });

        it('certifier changed event emited', async function () {
            await eduToken.updateCertifier(certifier.address,{from:tokenWallet}).then((result) => {
                var log = result.logs[0];
                assert.equal(log.event, "CertifierChanged");
            });
        });

        it('ownership transfered event emited', async function () {
            await eduToken.transferOwnership(accounts[1], {from: tokenWallet}).then((result) => {
                var log = result.logs[0];
                assert.equal(log.event, "OwnershipTransferred");
            });
        });
    });

    describe('crowdsale events', async function () {
        it('token purchase event emited', async function () {
           await increaseTimeTo(this.openingTime + 1);
           await crowdsale.sendTransaction({value: 2 * DECIMAL, from: accounts[1]}).then((result) =>{
              var log = result.logs[0];
              assert.equal(log.event, "TokenPurchase");
           });
        });
    });
});

function advanceBlock() {
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
async function advanceToBlock(number) {
    if (web3.eth.blockNumber > number) {
        throw Error(`block number ${number} is in the past (current is ${web3.eth.blockNumber})`);
    }

    while (web3.eth.blockNumber < number) {
        await advanceBlock();
    }
}

function increaseTime(duration) {
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
                return resolve(res);
            });
        });
    });
}


function increaseTimeTo(target) {
    let now = latestTime();
    let diff = target - now;
    return increaseTime(diff);
}

function latestTime() {
    return web3.eth.getBlock('latest').timestamp;
}

