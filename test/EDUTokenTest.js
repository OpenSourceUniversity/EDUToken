var EDUToken = artifacts.require("EDUToken");
const DECIMAL = 10 ** 18;

//EDU token functionality testing without certifier
contract("EDUToken", function (accounts) {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    let eduToken;

    beforeEach(async function () {
        eduToken = await EDUToken.new(ZERO_ADDRESS);
    });

    describe('token properties ', async function () {

        it('has a name', async function () {
            const name = await eduToken.name();
            assert.equal(name, 'EDU Token');
        });

        it('has a symbol', async function () {
            const symbol = await eduToken.symbol();
            assert.equal(symbol, 'EDUX');
        });

        it('has 18 decimals', async function () {
            const decimals = await eduToken.decimals();
            assert(decimals.eq(18));
        });
    });

    describe('token deployment', async function () {

        it('total supply equals 48000000', async function () {
            const totalSupply = await eduToken.totalSupply();
            assert(totalSupply.eq(48000000 * DECIMAL));
        });

        it('assigns the initial total supply to the creator', async function () {
            const totalSupply = await eduToken.totalSupply();
            const creatorBalance = await eduToken.balanceOf(accounts[0]);
            assert(creatorBalance.eq(totalSupply));
        });

        it('new account has zero balance', async function () {
            const balance = await eduToken.balanceOf(accounts[1]);
            assert.equal(balance, 0);
        });
    });

    describe('token transfer', async function () {

        it('transfer of 1000 tokens from creator to empty account', async function () {
            const value = 1000 * DECIMAL;
            const totalSupply = await eduToken.totalSupply();
            await eduToken.transfer(accounts[1], value);
            const creatorBalance = await eduToken.balanceOf(accounts[0]);
            const recieverBalance = await eduToken.balanceOf(accounts[1]);
            assert(creatorBalance.eq(totalSupply - value));
            assert(recieverBalance.eq(value));
        });

        it('revert on transfer from zero balance account', async function () {
            const value = 1000 * DECIMAL;
            try {
                await eduToken.transferFrom(accounts[1], accounts[2], value);
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
            }
        });

        it('revert on transfer to zero address', async function () {
            try {
                await eduToken.transfer(ZERO_ADDRESS,10000 * DECIMAL);
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
            }
        });
    });

    describe('approve functionality ', async function () {

        it('approved account is able to transfer', async function () {
            await eduToken.approve(accounts[1], 1000 * DECIMAL);
            await eduToken.transferFrom(accounts[0], accounts[2], 800 * DECIMAL, {from: accounts[1]});
            var account1Balance = await eduToken.balanceOf(accounts[1]);
            var account2Balance = await eduToken.balanceOf(accounts[2]);
            assert(account1Balance.eq(0));
            assert(account2Balance.eq(800 * DECIMAL));
        });

        it('approved account is not able to transfer over limit', async function () {
            try {
                await eduToken.approve(accounts[1], 200 * DECIMAL);
                await eduToken.transferFrom(accounts[0], accounts[2], 400 * DECIMAL, {from: accounts[1]});
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
            }
        });

        it('increase approval', async function () {
            await eduToken.approve(accounts[1], 100 * DECIMAL);
            await eduToken.increaseApproval(accounts[1], 200 * DECIMAL);
            await eduToken.transferFrom(accounts[0], accounts[2], 300 * DECIMAL, {from : accounts[1]});
            var account2Balance = await eduToken.balanceOf(accounts[2]);
            assert(account2Balance.eq(300 * DECIMAL));
        });

        it('decrease approval', async function () {
            await eduToken.approve(accounts[1], 300 * DECIMAL);
            await eduToken.decreaseApproval(accounts[1], 100 * DECIMAL);
            try {
                await eduToken.transferFrom(accounts[0], accounts[2], 300 * DECIMAL, {from : accounts[1]});
                assert.fail('Expected revert not received');
            } catch (error) {
                const revertFound = error.message.search('revert') >= 0;
                assert(revertFound, `Expected "revert", got ${error} instead`);
            }
        });

        it('allowance view returns correct value', async function () {
            await eduToken.approve(accounts[1], 300 * DECIMAL);
            let allowed =  await eduToken.allowance(accounts[0], accounts[1]);
            assert(allowed.eq(300 * DECIMAL));
        });
    });

    describe('token burning', async function () {
       it('account balance and initial supply changed after burn', async function () {
           const burnVal = 1000 * DECIMAL;
           const intialTotalSupply = await eduToken.totalSupply();
           await eduToken.burn(burnVal);
           const account0Balance = await eduToken.balanceOf(accounts[0]);
           const totalSupplyAfterBurn = await eduToken.totalSupply();
           assert(account0Balance.eq(intialTotalSupply - burnVal));
           assert(totalSupplyAfterBurn.eq(intialTotalSupply - burnVal));
       });

       it('revert on burning insufficient amount', async function () {
           const burnVal = 1000 * DECIMAL;
           const intialTotalSupply = await eduToken.totalSupply();
           try {
               await eduToken.burn(burnVal,{from:accounts[1]});
               assert.fail('Expected revert not received');
           } catch (error) {
               const revertFound = error.message.search('revert') >= 0;
               assert(revertFound, `Expected "revert", got ${error} instead`);

               const totalSupplyAfterBurn = await eduToken.totalSupply();
               assert(totalSupplyAfterBurn.eq(intialTotalSupply));
           }
       });
    });

});
