var EDUToken = artifacts.require("EDUToken");
const DECIMAL = 10 ** 18;

//EDU token functionality testing without certifier
contract("EDUToken", function(accounts){
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
    let eduToken;
    const owner = accounts[0];

    beforeEach(async function () {
        eduToken = await EDUToken.new(ZERO_ADDRESS);
    });

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

    it('transfer of 1000 tokens from creator to empty account', async function () {
        const value = 1000 * DECIMAL;
        await eduToken.transfer(accounts[1],value);
        const totalSupply = await eduToken.totalSupply();
        const creatorBalance = await eduToken.balanceOf(accounts[0]);
        const recieverBalance = await eduToken.balanceOf(accounts[1]);
        assert(creatorBalance.eq(totalSupply - value));
        assert(recieverBalance.eq(value));
    });

    it('transfer from zero balance account', async function () {
        const value = 1000 * DECIMAL;
        try {
            await eduToken.transferFrom(accounts[1], accounts[2], value);
            assert.fail('Expected revert not received');
        } catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
        }
    });

    it('approved account is able to transfer', async function () {
        await eduToken.approve(accounts[1], 1000 * DECIMAL);
        await eduToken.transferFrom(accounts[0],accounts[2], 800 * DECIMAL, {from: accounts[1]});
        var account1Balance = await eduToken.balanceOf(accounts[1]);
        var account2Balance = await eduToken.balanceOf(accounts[2]);
        assert(account1Balance.eq(0));
        assert(account2Balance.eq(800 * DECIMAL));

        //should not be able to transfer over 1000
        try {
            await eduToken.transferFrom(accounts[0], accounts[2], 400 * DECIMAL, {from: accounts[1]});
            assert.fail('Expected revert not received');
        }catch (error) {
            const revertFound = error.message.search('revert') >= 0;
            assert(revertFound, `Expected "revert", got ${error} instead`);
        }
    });

});
