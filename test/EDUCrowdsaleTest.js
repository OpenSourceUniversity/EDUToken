
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


/*
IMPORTANT! ganache should be restarted after execution of tests for proper work.
Set account balance to 1000 eth.
 */
contract("EDUCrowdsale", function (accounts) {
    const wallet = accounts[0];
    const tokenWallet = accounts[8];
    let rate;
    let cap = new BigNumber(web3.toWei(340, 'ether'));
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
        crowdsale = await EDUCrowdsale.new(wallet
            , eduToken.address
            , tokenWallet
            , cap
            , this.openingTime
            , this.closingTime
            , certifier.address);
        await eduToken.addManager(crowdsale.address, {from: tokenWallet});
        await eduToken.approve(crowdsale.address, 5000000 * DECIMAL, {from: tokenWallet});
        rate = await crowdsale.getCurrentRate();
    });

    afterEach(async function () {
       for(var i = 0; i < accounts.length; i++){
           console.log("account " + i + ":" +  web3.eth.getBalance(accounts[i]));
       }
    });

    describe('crowdsale new investor', async function () {

         it('should be able to contribute', async function () {
            await increaseTimeTo(this.openingTime + 1);
            const value = 10 * DECIMAL;
            const investor = accounts[1];
            await crowdsale.sendTransaction({value: value, from: investor});
            let investorBalance = await eduToken.balanceOf(investor);
            assert(investorBalance.eq(value * rate));
        });

         it('should not be able to transfer without kyc', async function () {
             await increaseTimeTo(this.openingTime + 1);
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
             await increaseTimeTo(this.openingTime + 1);
            const valueToBuy = 1 * DECIMAL;
            const valueToSend = 3 * DECIMAL;
            const investor = accounts[1];
            const reciever = accounts[2];
            await crowdsale.sendTransaction({value: valueToBuy, from: investor});
            await certifier.certify(investor);
            await eduToken.transfer(reciever,valueToSend,{from:investor});
            const investorBalance = await eduToken.balanceOf(investor);
            const recieverBalance = await eduToken.balanceOf(reciever);
            assert(investorBalance.eq(valueToBuy * rate - valueToSend));
            assert(recieverBalance.eq(valueToSend));
        });
    });

    describe('investor passed kyc before crowdsale', async function () {

        it('should be able to contribute', async function () {
            const investor = accounts[1];
            await certifier.certify(investor);
            await increaseTimeTo(this.openingTime + 1);
            const value = 10 * DECIMAL;
            await crowdsale.sendTransaction({value: value, from: investor});
            let investorBalance = await eduToken.balanceOf(investor);
            assert(investorBalance.eq(value * rate));
        });
    });

    describe('opening/closing time', async function () {

        it('should not be able to contribute before opening time', async function () {
            const investor = accounts[1];
            const value = 10 * DECIMAL;
            try {
                await crowdsale.sendTransaction({value: value, from: investor});
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
                var investorBalance = await eduToken.balanceOf(investor)
                assert(investorBalance.eq(0));
            }
        });

        it('should not be able to contribute after closing time', async function () {
            const investor = accounts[1];
            const value = 10 * DECIMAL;
            await increaseTimeTo(this.closingTime + 1);
            try {
                await crowdsale.sendTransaction({value: value, from: investor});
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
                var investorBalance = await eduToken.balanceOf(investor)
                assert(investorBalance.eq(0));
            }
        });

    });


    it('wei raised updated correctly', async function () {
        await increaseTimeTo(this.openingTime + 1);
        const value1 = 4 * DECIMAL;
        const value2 = 2 * DECIMAL;
        const investor1 = accounts[1];
        const investor2 = accounts[2];
        await crowdsale.sendTransaction({value: value1, from: investor1});
        await crowdsale.sendTransaction({value: value2, from: investor2});
        let investor1Balance = await eduToken.balanceOf(investor1);
        let investor2Balance = await eduToken.balanceOf(investor2);
        assert(investor1Balance.eq(value1 * rate));
        assert(investor2Balance.eq(value2 * rate));
        const weiRaised = await crowdsale.weiRaised();
        assert(weiRaised.eq(value1 + value2));
    });

    it('could not contribute over cap', async function () {
        await increaseTimeTo(this.openingTime + 1);
        const value = 300 * DECIMAL;
        const investor = accounts[0];
        await crowdsale.sendTransaction({value: value, from: investor});
        let investorBalance = await eduToken.balanceOf(investor);
        assert(investorBalance.eq(value * rate * 1.15));
        certifier.certify(investor);
        const valOverCap = 41 * DECIMAL;
        try {
            await crowdsale.sendTransaction({value: valOverCap, from: accounts[9]});
            assert.fail('Expected revert not received');
        } catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
            investorBalance = await eduToken.balanceOf(accounts[9])
            assert(investorBalance.eq(0));
        }
    });

    it('delayed transfer blocking transactions', async function () {
        await increaseTimeTo(this.openingTime + 1);
        const accountToBlock = accounts[1];
        await eduToken.addManager(accounts[0], {from:tokenWallet});
        await eduToken.transfer(accountToBlock, 4 * DECIMAL, {from: tokenWallet});
        await eduToken.transfer(accounts[2], 1 * DECIMAL, {from: accountToBlock});
        let balance = await eduToken.balanceOf(accounts[2]);
        assert(balance.eq(1 * DECIMAL));
        await eduToken.approve(accounts[0], 5 * DECIMAL, {from: tokenWallet});
        await eduToken.delayedTransferFrom(tokenWallet, accountToBlock,1 * DECIMAL);
        try {
            await eduToken.transfer(accounts[2], 1 * DECIMAL, {from: accountToBlock});
            assert.fail('Expected revert not received');
        } catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
            balance = await eduToken.balanceOf(accountToBlock);
            assert(balance.eq( 4 * DECIMAL));
        }
    });

    describe('wallet change', async function () {

        it('token wallet change', async function () {
            await increaseTimeTo(this.openingTime + 1);
            const newTokenWallet = accounts[1];
            let oldWalletBalance = await eduToken.balanceOf(tokenWallet);
            let newWalletBalance = await eduToken.balanceOf(newTokenWallet);
            assert(oldWalletBalance.eq(48000000 * DECIMAL));
            assert(newWalletBalance.eq(0));

            eduToken.transfer(newTokenWallet, 48000000 * DECIMAL, {from: tokenWallet});
            oldWalletBalance = await eduToken.balanceOf(tokenWallet);
            newWalletBalance = await eduToken.balanceOf(newTokenWallet);
            assert(oldWalletBalance.eq(0));
            assert(newWalletBalance.eq(48000000 * DECIMAL));

            await crowdsale.changeTokenWallet(newTokenWallet);
            await eduToken.approve(crowdsale.address,5000000 * DECIMAL, {from: newTokenWallet});
            await crowdsale.sendTransaction({value: 1 * DECIMAL, from: accounts[3]});
            let balanceOfReciever = await eduToken.balanceOf(accounts[3]);
            oldWalletBalance = await eduToken.balanceOf(tokenWallet);
            newWalletBalance = await eduToken.balanceOf(newTokenWallet);
            assert(balanceOfReciever.eq(1 * DECIMAL * rate));
            assert(oldWalletBalance.eq(0));
            assert(newWalletBalance.eq(48000000 * DECIMAL - balanceOfReciever));
        });

        it('eth wallet change', async function (){
            await increaseTimeTo(this.openingTime + 1);
            const newWallet = accounts[7];
            await crowdsale.sendTransaction({value: 1 * DECIMAL, from: accounts[3]});
            crowdsale.changeWallet(newWallet);
            await crowdsale.sendTransaction({value: 2 * DECIMAL, from: accounts[4]});
            const newWalletBalance = web3.eth.getBalance(newWallet);
            assert(newWalletBalance.eq((1000 + 2) * DECIMAL));
        });

        it('test volume bonus over 50', async function () {
           await increaseTimeTo(this.openingTime + 1);
           const value = 50 * DECIMAL;
           const investor = accounts[5];
           await crowdsale.sendTransaction({value: value, from: investor});
           let investorBalance = await eduToken.balanceOf(investor);
           assert(investorBalance.eq(value * rate * 1.05));
        });

        it('test volume bonus over 150', async function () {
           await increaseTimeTo(this.openingTime + 1);
           const value = 150 * DECIMAL;
           const investor = accounts[5];
           await crowdsale.sendTransaction({value: value, from: investor});
           let investorBalance = await eduToken.balanceOf(investor);
           assert(investorBalance.eq(value * rate * 1.1));
        });

        it('test volume bonus over 250', async function () {
           await increaseTimeTo(this.openingTime + 1);
           const value = 250 * DECIMAL;
           const investor = accounts[6];
           await crowdsale.sendTransaction({value: value, from: investor});
           let investorBalance = (await eduToken.balanceOf(investor)).toString();
           let assertion = (value * rate * 1.15).toPrecision(4);
           assert.equal(investorBalance.substr(0,4), assertion.substr(0,4));
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
                return  resolve(res);
            });
        });
    });
}



function increaseTimeTo (target) {
    let now = latestTime();
    let diff = target - now;
    return increaseTime(diff);
}

function latestTime () {
    return web3.eth.getBlock('latest').timestamp;
}
