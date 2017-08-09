# VentanaToken

Source file [../../contracts/VentanaToken.sol](../../contracts/VentanaToken.sol).

<br />

<hr />

```javascript
/*
file:   VentanaToken.sol
ver:    0.0.10
author: Darryl Morris
date:   8-Aug-2017
email:  o0ragman0o AT gmail.com
(c) Darryl Morris 2017

A collated contract set for a token sale specific to the requirments of
Veredictum's Ventana token product.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
0.0.10
* remove `constant` from FUND_WALLET declaration as assigning `msg.sender` is
not compile time constant.
* redeclared FUND_WALLET to `address public fundWallet`
* `fundSucceeded()` returns true on `etherRaised >= MIN_ETH_FUND` instead of
waiting for `END_DATE`


*/


// BK Ok
pragma solidity ^0.4.13;

/*-----------------------------------------------------------------------------\

 Ventana token sale configuration

\*----------------------------------------------------------------------------*/

// Contains token sale parameters
// BK Ok
contract VentanaTokenConfig
{
    // ERC20 trade name and symbol
    // BK Ok
    string public           name            = "Ventana";
    // BK Ok
    string public           symbol          = "VNT";

    // Owner has power to abort, discount addresses, sweep successful funds,
    // change owner, sweep alien tokens.
    // BK NOTE - MAKE SURE `constant` is not used in the following statement
    // BK Ok
    address public          owner           = msg.sender;
    
    // Fund wallet should also be audited prior to deployment
    // NOTE: Must be checksummed address!
    // BK Ok
    address public          fundWallet      = 0x0;

    // Tokens awarded per USD contributed
    // BK Ok
    uint public constant    TOKENS_PER_USD  = 3;

    // Ether market price in USD
    // BK Ok
    uint public constant    USD_PER_ETH     = 200;
    
    // Minimum and maximum target in USD
    // BK Ok
    uint public constant    MIN_USD_FUND    = 2000000;  // $2m
    // BK Ok
    uint public constant    MAX_USD_FUND    = 20000000; // $20m
    
    // Non-KYC contribution limit in USD
    // BK Ok
    uint public constant    KYC_USD_LMT     = 10000;
    
    // There will be exactly 300,000,000 tokens regardless of number sold
    // Unsold tokens are put into the Strategic Growth token pool
    // BK Ok
    uint public constant    MAX_TOKENS      = 300000000;
    
    // Funding begins on 14th August 2017
    // `+ new Date('14 August 2017 GMT+0')/1000`
    // BK NOTE - new Date(1502668800 * 1000).toUTCString() => "Mon, 14 Aug 2017 00:00:00 UTC"
    // BK NOTE - new Date(1502668800 * 1000) => <Date Mon, 14 Aug 2017 10:00:00 AEST>
    // BK Ok
    uint public constant    START_DATE      = 1502668800;

    // Period for fundraising
    // BK Ok
    uint public constant    FUNDING_PERIOD  = 28 days;
}


// BK Ok
library SafeMath
{
    // a add to b
    // BK Ok
    function add(uint a, uint b) internal returns (uint c) {
        // BK Ok
        c = a + b;
        // BK Ok - Overflow check
        assert(c >= a);
    }
    
    // a subtract b
    // BK Ok
    function sub(uint a, uint b) internal returns (uint c) {
        // BK Ok
        c = a - b;
        // BK Ok - Underflow check
        assert(c <= a);
    }
    
    // a multiplied by b
    // BK Ok
    function mul(uint a, uint b) internal returns (uint c) {
        // BK Ok
        c = a * b;
        // BK Ok
        assert(a == 0 || c / a == b);
    }
    
    // a divided by b
    // BK Ok
    function div(uint a, uint b) internal returns (uint c) {
        // BK Ok - The EVM will throw an error if a divide by zero is detected
        c = a / b;
        // No assert required as no overflows are posible.
    }
}


// BK Ok
contract ReentryProtected
{
    // The reentry protection state mutex.
    // BK Ok
    bool __reMutex;

    // Sets and resets mutex in order to block functin reentry
    // BK Ok
    modifier preventReentry() {
        // BK Ok
        require(!__reMutex);
        // BK Ok
        __reMutex = true;
        // BK Ok
        _;
        // BK Ok
        delete __reMutex;
    }

    // Blocks function entry if mutex is set
    // BK Ok
    modifier noReentry() {
        // BK Ok
        require(!__reMutex);
        // BK Ok
        _;
    }
}

// BK Ok
contract ERC20Token
{
    // BK Ok
    using SafeMath for uint;

/* Constants */

    // none
    
/* State variable */

    /// @return The Total supply of tokens
    // BK Ok
    uint public totalSupply;
    
    /// @return Token symbol
    // BK Ok
    string public symbol;
    
    // Token ownership mapping
    // BK Ok
    mapping (address => uint) balances;
    
    // Allowances mapping
    // BK Ok
    mapping (address => mapping (address => uint)) allowed;

/* Events */

    // Triggered when tokens are transferred.
    // BK NOTE - Better to use `uint` or `uint256` consistently
    // BK Ok
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount);

    // Triggered whenever approve(address _spender, uint256 _amount) is called.
    // BK NOTE - Better to use `uint` or `uint256` consistently
    // BK Ok
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount);

/* Modifiers */

    // none
    
/* Functions */

    // Using an explicit getter allows for function overloading    
    // BK Ok - Constant function
    function balanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        // BK Ok
        return balances[_addr];
    }
    
    // Using an explicit getter allows for function overloading    
    // BK Ok - Constant function
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint)
    {
        // BK Ok
        return allowed[_owner][_spender];
    }

    // Send _value amount of tokens to address _to
    // BK Ok
    function transfer(address _to, uint256 _amount)
        public
        returns (bool)
    {
        // BK Ok
        return xfer(msg.sender, _to, _amount);
    }

    // Send _value amount of tokens from address _from to address _to
    // BK Ok
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool)
    {
        // BK Ok - Amount to transfer is less than or equal to the approved amount
        require(_amount <= allowed[_from][msg.sender]);
        
        // BK Ok - Reduce approved amount
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        // BK Ok
        return xfer(_from, _to, _amount);
    }

    // Process a transfer internally.
    // BK Ok - Internal function
    function xfer(address _from, address _to, uint _amount)
        internal
        returns (bool)
    {
        // BK Ok - Amount to be transferred is less than or equal to the source account balance
        require(_amount <= balances[_from]);

        // BK Ok - Log event
        Transfer(_from, _to, _amount);
        
        // avoid wasting gas on 0 token transfers
        // BK Ok - 0 is a valid tranfer in this token contract
        if(_amount == 0) return true;
        
        // BK Ok
        balances[_from] = balances[_from].sub(_amount);
        // BK Ok
        balances[_to]   = balances[_to].add(_amount);
        
        // BK Ok
        return true;
    }

    // Approves a third-party spender
    // BK Ok
    function approve(address _spender, uint256 _amount)
        public
        returns (bool)
    {
        // BK Ok
        allowed[msg.sender][_spender] = _amount;
        // BK Ok - Log event
        Approval(msg.sender, _spender, _amount);
        // BK Ok
        return true;
    }
}



/*-----------------------------------------------------------------------------\

## Conditional Entry Table

Functions must throw on F conditions

Conditional Entry Table (functions must throw on F conditions)

renetry prevention on all public mutating functions
Reentry mutex set in moveFundsToWallet(), refund()

|function                |<START_DATE|<END_DATE |fundFailed  |fundSucceeded|icoSucceeded
|------------------------|:---------:|:--------:|:----------:|:-----------:|:---------:|
|()                      |KYC        |T         |F           |T            |F          |
|abort()                 |T          |T         |T           |T            |F          |
|proxyPurchase()         |KYC        |T         |F           |T            |F          |
|addKycAddress()         |T          |T         |F           |T            |T          |
|finaliseICO()           |F          |F         |F           |T            |T          |
|refund()                |F          |F         |T           |F            |F          |
|transfer()              |F          |F         |F           |F            |T          |
|transferFrom()          |F          |F         |F           |F            |T          |
|approve()               |F          |F         |F           |F            |T          |
|changeOwner()           |T          |T         |T           |T            |T          |
|acceptOwnership()       |T          |T         |T           |T            |T          |
|changeVeredictum()      |T          |T         |T           |T            |T          |
|destroy()               |F          |F         |!__abortFuse|F            |F          |
|transferAnyERC20Tokens()|T          |T         |T           |T            |T          |

\*----------------------------------------------------------------------------*/

// BK Ok
contract VentanaTokenAbstract
{
// TODO comment events
    // BK Next 5 Ok
    event KYCAddress(address indexed _addr, bool indexed _kyc);
    event Refunded(address indexed _addr, uint indexed _value);
    event ChangedOwner(address indexed _from, address indexed _to);
    event ChangeOwnerTo(address indexed _to);
    event FundsTransferred(address indexed _wallet, uint indexed _value);

    // This fuse blows upon calling abort() which forces a fail state
    // BK Ok
    bool public __abortFuse = true;
    
    // Set to true after the fund is swept to the fund wallet, allows token
    // transfers and prevents abort()
    // BK Ok
    bool public icoSuccessful;

    // Token conversion factors are calculated with decimal places at parity with ether
    // BK Ok - Good to use `uint8` as this is the standard
    uint8 public constant decimals = 18;

    // An address authorised to take ownership
    // BK Ok
    address public newOwner;
    
    // The Veredictum smart contract address
    // BK Ok
    address public veredictum;
    
    // Total ether raised during funding
    // BK Ok
    uint public etherRaised;
    
    // Preauthorized tranch discount addresses
    // holder => discount
    // BK Ok
    mapping (address => bool) public kycAddresses;
    
    // Record of ether paid per address
    // BK Ok
    mapping (address => uint) public etherContributed;

    // Return `true` if MIN_FUNDS were raised
    // BK Ok
    function fundSucceeded() public constant returns (bool);
    
    // Return `true` if MIN_FUNDS were not raised before END_DATE
    // BK Ok
    function fundFailed() public constant returns (bool);

    // Returns USD raised for set ETH/USD rate
    // BK Ok
    function usdRaised() public constant returns (uint);

    // Returns an amount in eth equivilent to USD at the set rate
    // BK Ok
    function usdToEth(uint) public constant returns(uint);
    
    // Returns the USD value of ether at the set USD/ETH rate
    // BK Ok
    function ethToUsd(uint _wei) public constant returns (uint);

    // Returns token/ether conversion given ether value and address.
    // BK Ok 
    function ethToTokens(uint _eth)
        public constant returns (uint);

    // Processes a token purchase for a given address
    // BK Ok
    function proxyPurchase(address _addr) payable returns (bool);

    // Owner can move funds of successful fund to fundWallet 
    // BK Ok
    function finaliseICO() public returns (bool);
    
    // Registers a discounted address
    // BK Ok
    function addKycAddress(address _addr, bool _kyc)
        public returns (bool);

    // Refund on failed or aborted sale
    // BK Ok 
    function refund(address _addr) public returns (bool);

    // To cancel token sale prior to START_DATE
    // BK NOTE - END_DATE, not START_DATE
    // BK Ok
    function abort() public returns (bool);
    
    // Change the Veredictum backend contract address
    // BK Ok
    function changeVeredictum(address _addr) public returns (bool);
    
    // For owner to salvage tokens sent to contract
    // BK Ok
    function transferAnyERC20Token(address tokenAddress, uint amount)
        returns (bool);
}


/*-----------------------------------------------------------------------------\

 Ventana token implimentation

\*----------------------------------------------------------------------------*/

// BK Ok
contract VentanaToken is 
    ReentryProtected,
    ERC20Token,
    VentanaTokenAbstract,
    VentanaTokenConfig
{
    // BK Ok
    using SafeMath for uint;

//
// Constants
//

    // USD to ether conversion factors calculated from `VentanaTokenConfig` constants
    // BK Ok 
    uint public constant TOKENS_PER_ETH = TOKENS_PER_USD * USD_PER_ETH;
    // BK Ok
    uint public constant MIN_ETH_FUND   = 1 ether * MIN_USD_FUND / USD_PER_ETH;
    // BK Ok
    uint public constant MAX_ETH_FUND   = 1 ether * MAX_USD_FUND / USD_PER_ETH;
    // BK Ok
    uint public constant KYC_ETH_LMT    = 1 ether * KYC_USD_LMT  / USD_PER_ETH;

    // General funding opens LEAD_IN_PERIOD after deployment (timestamps can't be constant)
    // BK Ok
    uint public END_DATE  = START_DATE + FUNDING_PERIOD;

//
// Modifiers
//

    // BK Ok
    modifier onlyOwner {
        // BK Ok
        require(msg.sender == owner);
        // BK Ok
        _;
    }

//
// Functions
//

    // Constructor
    // BK Ok - Constructor
    function VentanaToken()
    {
        // ICO parameters are set in VentanaTSConfig
        // Invalid configuration catching here
        // BK Ok
        require(bytes(symbol).length > 0);
        // BK Ok
        require(bytes(name).length > 0);
        // BK Ok
        require(owner != 0x0);
        // BK Ok
        require(fundWallet != 0x0);
        // BK Ok
        require(TOKENS_PER_USD > 0);
        // BK Ok
        require(USD_PER_ETH > 0);
        // BK Ok
        require(MIN_USD_FUND > 0);
        // BK Ok
        require(MAX_USD_FUND > MIN_USD_FUND);
        // BK Ok
        require(START_DATE > 0);
        // BK Ok
        require(FUNDING_PERIOD > 0);
        
        // Setup and allocate token supply to 18 decimal places
        // BK NOTE - Could specify as `totalSupply = MAX_TOKENS * 10**uint256(decimals);` instead of hardcoding decimals in 2 places
        // BK Ok 
        totalSupply = MAX_TOKENS * 1e18;
        // BK Ok
        balances[fundWallet] = totalSupply;
        // BK Ok
        Transfer(0x0, fundWallet, totalSupply);
    }
    
    // Default function
    // BK Ok - Anyone can call this function, with the payable modifier for the contract to accept ETH
    function ()
        payable
    {
        // Pass through to purchasing function. Will throw on failed or
        // successful ICO
        // BK Ok
        proxyPurchase(msg.sender);
    }

//
// Getters
//

    // ICO fails if aborted or minimum funds are not raised by the end date
    // BK NOTE - __abortFuse = true (default) if not aborted, false if abort() called
    // BK NOTE - failed if aborted OR minimum funding not met by end date
    // BK Ok - Constant function
    function fundFailed() public constant returns (bool)
    {
        // BK Ok - Aborted?
        return !__abortFuse
            // BK Ok - minimum funding not met by end date
            || (now > END_DATE && etherRaised < MIN_ETH_FUND);
    }
    
    // Funding succeeds if not aborted, minimum funds are raised before end date
    // BK Ok
    function fundSucceeded() public constant returns (bool)
    {
        // BK Ok
        return !fundFailed()
            // BK Ok
            && etherRaised >= MIN_ETH_FUND;
    }

    // Returns the USD value of ether at the set USD/ETH rate
    // BK Ok
    function ethToUsd(uint _wei) public constant returns (uint)
    {
        // BK Ok
        return USD_PER_ETH.mul(_wei).div(1 ether);
    }
    
    // Returns the ether value of USD at the set USD/ETH rate
    // BK Ok - Constant function
    function usdToEth(uint _usd) public constant returns (uint)
    {
        // BK Ok
        return _usd.mul(1 ether).div(USD_PER_ETH);
    }
    
    // Returns the USD value of ether raised at the set USD/ETH rate
    // BK Ok - Constant function
    function usdRaised() public constant returns (uint)
    {
        // BK Ok
        return ethToUsd(etherRaised);
    }
    
    // Returns the number of tokens for given amount of ether for an address 
    // BK Ok
    function ethToTokens(uint _wei) public constant returns (uint)
    {
        // BK Ok
        uint usd = ethToUsd(_wei);
        
        // Percent bonus funding tiers for USD funding
        // BK Ok
        uint bonus =
            usd >= 2000000 ? 35 :
            usd >= 500000  ? 30 :
            usd >= 100000  ? 20 :
            usd >= 25000   ? 15 :
            usd >= 10000   ? 10 :
            usd >= 5000    ? 5  :
                             0;  
        
        // using n.2 fixed point decimal for whole number percentage.
        // BK Ok
        return _wei.mul(TOKENS_PER_ETH).mul(bonus + 100).div(100);
    }

//
// ICO functions
//

    // The fundraising can be aborted any time before funds are swept to the
    // fundWallet.
    // This will force a fail state and allow refunds to be collected.
    // BK Ok - Owner can `abort()` if `finaliseICO()` is not called
    function abort()
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        // BK Ok - icoSuccessful is only set if `finaliseICO()` is called
        require(!icoSuccessful);
        // BK Ok
        delete __abortFuse;
        // BK Ok
        return true;
    }
    
    // General addresses can purchase tokens during funding
    // BK Ok - Anyone can call this function, with the payable modifier for the contract to accept ETH
    function proxyPurchase(address _addr)
        payable
        noReentry
        returns (bool)
    {
        // BK Ok
        require(!fundFailed());
        // BK OK
        require(!icoSuccessful);
        // BK Ok
        require(now <= END_DATE);
        // BK Ok
        require(msg.value > 0);
        
        // Non-KYC'ed funders can only contribute up to $10000 after prefund period
        // BK Ok
        if(!kycAddresses[_addr])
        {
            // BK Ok
            require(now >= START_DATE);
            // BK Ok
            require((etherContributed[_addr].add(msg.value)) <= KYC_ETH_LMT);
        }

        // Get ether to token conversion
        // BK Ok
        uint tokens = ethToTokens(msg.value);
        
        // transfer tokens from fund wallet
        // BK Ok
        xfer(fundWallet, _addr, tokens);
        
        // Update holder payments
        // BK Ok
        etherContributed[_addr] = etherContributed[_addr].add(msg.value);
        
        // Update funds raised
        // BK Ok
        etherRaised = etherRaised.add(msg.value);
        
        // Bail if this pushes the fund over the USD cap or Token cap
        // BK Ok
        require(etherRaised <= MAX_ETH_FUND);

        // BK Ok
        return true;
    }
    
    // Owner can KYC (or revoke) addresses until close of funding
    // BK Ok - Only owner can set the Yes/No KYC status for addresses at any time during the crowdsale
    function addKycAddress(address _addr, bool _kyc)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        // BK Ok
        require(!fundFailed());

        // BK Ok
        kycAddresses[_addr] = _kyc;
        // BK Ok - Log event
        KYCAddress(_addr, _kyc);
        // BK Ok
        return true;
    }
    
    // Owner can sweep a successful funding to the fundWallet
    // Contract can be aborted up until this action.
    // BK Ok - Only the owner can call this if funding is successful
    function finaliseICO()
        public
        onlyOwner
        preventReentry()
        returns (bool)
    {
        // BK Ok
        require(fundSucceeded());

        // BK Ok
        icoSuccessful = true;

        // BK Ok - Log event
        FundsTransferred(fundWallet, this.balance);
        // BK Ok
        fundWallet.transfer(this.balance);
        // BK Ok
        return true;
    }
    
    // Refunds can be claimed from a failed ICO
    // BK Ok - Anyone can call this function and the refunds for the specified address will be processed
    function refund(address _addr)
        public
        preventReentry()
        returns (bool)
    {
        // BK Ok
        require(fundFailed());
        
        // BK Ok
        uint value = etherContributed[_addr];

        // Transfer tokens back to origin
        // (Not really necessary but looking for graceful exit)
        // BK Ok
        xfer(_addr, fundWallet, balances[_addr]);

        // garbage collect
        // BK Ok
        delete etherContributed[_addr];
        // BK Ok
        delete kycAddresses[_addr];
        
        // BK Ok - Log event
        Refunded(_addr, value);
        // BK Ok
        if (value > 0) {
            // BK Ok
            _addr.transfer(value);
        }
        return true;
    }

//
// ERC20 overloaded functions
//

    // BK Ok
    function transfer(address _to, uint _amount)
        public
        preventReentry
        returns (bool)
    {
        // ICO must be successful
        // BK Ok - Can only execute after `finaliseICO()` is called
        require(icoSuccessful);
        // BK Ok
        super.transfer(_to, _amount);

        // BK Ok
        if (_to == veredictum)
            // Notify the Veredictum contract it has been sent tokens
            // BK Ok
            require(Notify(veredictum).notify(msg.sender, _amount));
        // BK Ok
        return true;
    }

    // BK Ok
    function transferFrom(address _from, address _to, uint _amount)
        public
        preventReentry
        returns (bool)
    {
        // ICO must be successful
        // BK Ok - Can only execute after `finaliseICO()` is called
        require(icoSuccessful);
        // BK Ok
        super.transferFrom(_from, _to, _amount);

        // BK Ok
        if (_to == veredictum)
            // Notify the Veredictum contract it has been sent tokens
            // BK Ok
            require(Notify(veredictum).notify(msg.sender, _amount));
        // BK Ok
        return true;
    }
    
    // BK Ok
    function approve(address _spender, uint _amount)
        public
        noReentry
        returns (bool)
    {
        // ICO must be successful
        // BK Ok - Can only execute after `finaliseICO()` is called
        require(icoSuccessful);
        // BK Ok
        super.approve(_spender, _amount);
        // BK Ok
        return true;
    }

//
// Contract managment functions
//

    // To initiate an ownership change
    // BK Ok - Only owner change change to a new owner
    function changeOwner(address _newOwner)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        // BK OK
        ChangeOwnerTo(_newOwner);
        // BK Ok
        newOwner = _newOwner;
        // BK Ok
        return true;
    }

    // To accept ownership. Required to prove new address can call the contract.
    // BK Ok - Only new owner can execute this function
    function acceptOwnership()
        public
        noReentry
        returns (bool)
    {
        // BK Ok
        require(msg.sender == newOwner);
        // BK Ok
        ChangedOwner(owner, newOwner);
        // BK Ok
        owner = newOwner;
        // BK OK
        return true;
    }

    // Change the address of the Veredictum contract address. The contract
    // must impliment the `Notify` interface.
    // BK Ok - Only the owner can set the veredictum contract address
    function changeVeredictum(address _addr)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        // BK Ok
        veredictum = _addr;
        // BK Ok
        return true;
    }
    
    // The contract can be selfdestructed after abort and ether balance is 0.
    // BK NOTE - The owner can only disable the token contract if `abort()` is called and all refunds are extracted
    // BK Ok - Only owner can abort
    function destroy()
        public
        noReentry
        onlyOwner
    {
        // BK Ok - Cannot destroy unless aborted
        require(!__abortFuse);
        // BK Ok
        require(this.balance == 0);
        // BK Ok
        selfdestruct(owner);
    }
    
    // Owner can salvage ERC20 tokens that may have been sent to the account
    // BK Ok - Only owner can execute
    function transferAnyERC20Token(address tokenAddress, uint amount)
        public
        onlyOwner
        preventReentry
        returns (bool) 
    {
        // BK Ok
        require(ERC20Token(tokenAddress).transfer(owner, amount));
        // BK Ok
        return true;
    }
}


// BK Ok
interface Notify
{
    // BK Ok
    event Notified(address indexed _from, uint indexed _amount);
    
    // BK Ok
    function notify(address _from, uint _amount) public returns (bool);
}


// BK Ok
contract VeredictumTest is Notify
{
    // BK Ok
    address public vnt;
    
    // BK Ok
    function setVnt(address _addr) { vnt = _addr; }
    
    // BK Ok
    function notify(address _from, uint _amount) public returns (bool)
    {
        // BK Ok
        require(msg.sender == vnt);
        // BK Ok
        Notified(_from, _amount);
        // BK Ok
        return true;
    }
}
```
