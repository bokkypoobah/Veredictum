# Veredictum Crowdsale Contract Audit

## Summary

Bok Consulting Pty Ltd was commissioned to perform an audit on the crowdsale and token Ethereum smart contract for the upcoming
Veredictum crowdsale.

This audit has been conducted on the Veredictum's source code in commits
[10ddcc98](https://github.com/o0ragman0o/Veredictum/tree/10ddcc98ede5696ed6a79d11607bd8000f8e0f7a),
[e6926f99](https://github.com/o0ragman0o/Veredictum/tree/e6926f9948bbce592af09a8456db08949f41f149),
[c140554b](https://github.com/o0ragman0o/Veredictum/tree/c140554b16d3d26ce71ffdd57bb3b0dcddd16f07)

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

### Crowdsale Mainnet Address

As listed in [https://tokensale.veredictum.io/](https://tokensale.veredictum.io/), the *VentanaToken* crowdsale/token contract is deployed at [0x30cefbcb5c26a5b19a019092ab8d09f8739c904f](https://etherscan.io/address/0x30cefbcb5c26a5b19a019092ab8d09f8739c904f#code).

The `fundWallet` multisig wallet is deployed at [0xd6514387236595e080b97c8ead1cbf12f9a6ab65](https://etherscan.io/address/0xd6514387236595e080b97c8ead1cbf12f9a6ab65).

<br />

### Crowdsale Statistics

`{TBA}`

<br />

### Crowdsale/Token Contract

Ethers contributed by participants to the crowdsale contract will result in VNT tokens being allocated to the participant's 
account in the token contract. The contributed ethers are accumulated in the crowdsale/token contract and is only transferred
to the crowdsale multisig wallet when the crowdsale is finalised.

Participants that have been Know-Your-Client (KYC) verified are able to contribute to this crowdsale contract prior
to the commencement of the public crowdsale.

The token contract is [ERC20](https://github.com/ethereum/eips/issues/20) compliant with the following features:

* `decimals` is correctly defined as `uint8` instead of `uint256`
* `transfer(...)` and `transferFrom(...)` will throw instead of returning false if there is an error. A transfer of 0 tokens is a valid transfer.
* `transfer(...)` and `transferFrom(...)` have not been built with a check on the size of the data being passed
* `approve(...)` has no requirement that a non-zero approval limit be set to 0 before a new non-zero limit can be set

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
  * [Crowdsale Mainnet Address](#crowdsale-mainnet-address)
  * [Crowdsale Statistics](#crowdsale-statistics)
  * [Crowdsale/Token Contract](#crowdsaletoken-contract)
* [Table Of Contents](#table-of-contents)
* [Recommendations](#recommendations)
* [Notes](#notes)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Testing](#testing)
* [Code Review](#code-review)
* [References](#references)

<br />

<hr />

## Recommendation

* **MEDIUM IMPORTANCE** Add a token `name()`
  * [x] Fixed in [e6926f99](https://github.com/o0ragman0o/Veredictum/commit/e6926f9948bbce592af09a8456db08949f41f149)
* **LOW IMPORTANCE** Provide start and end dates that are better defined. The current configuration start/end dates depend on the
  deployment date/time of the contracts:

      uint public FUND_DATE = now + PREFUND_PERIOD;
      uint public END_DATE  = FUND_DATE + FUNDING_PERIOD;

  It would be clearer for investors if a start date/time like Aug 14 2017 12:00:00 UTC is used instead of Aug 14 2017 11:21:52 UTC.
  * [x] Fixed in [e6926f99](https://github.com/o0ragman0o/Veredictum/commit/e6926f9948bbce592af09a8456db08949f41f149)
* **LOW IMPORTANCE** Group ownership variables, modifiers and functions into an *Owned* contract - makes it easier to check this 
  standard functionality and move it away from the other custom functionalities
  * [x] Not done as author has a preference to group by the configuration
* **LOW IMPORTANCE** `__abortFuse` should be declared **public** so users can read this variable from EtherScan to determine if the 
  crowdsale has been aborted
  * [x] Fixed in [c140554b](https://github.com/o0ragman0o/Veredictum/commit/c140554b16d3d26ce71ffdd57bb3b0dcddd16f07)
* **MEDIUM IMPORTANCE** Add the following type of code at the end of `proxyPurchase(...)` to transfer contributed funds directly
  into the more tested project multisig wallet - to minimise the risk of funds sitting in the crowdsale contract:

      if (etherRaised > MIN_ETH_FUND) {
          FUND_WALLET.transfer(this.balance);
      }
  * [x] Not done as author prefers for the funds to be held by the crowdsale contract until the crowdsale is finalised and the
    tokens are released to the investors
* **MEDIUM IMPORTANCE** Cannot `finaliseICO()` before the crowdsale end date even if the minimum funding level is reached.
  * [x] Fixed in [c140554b](https://github.com/o0ragman0o/Veredictum/commit/c140554b16d3d26ce71ffdd57bb3b0dcddd16f07)

<br />

<hr />

## Notes

* Make sure that `constant` is not used in the `address public owner = msg.sender;` statement. It is far safer to
  assign this variable in a/the constructor.
* If `veredictum` is set to 0x0, accounts cannot burn tokens by transferring them to 0x0 as an exception will be thrown

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that funds contributed to
these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is that ensure the coded algorithms work
as expected. This audit does not guarantee that that the code is bugfree, but intends to highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the Veredictum's business proposition, the individuals involved in
this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition before funding
any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on the
crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as duplicating
crowdsale websites. Potential participants should NOT just click on any links received through these messages. Scammers have also hacked
the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address matches the
audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Testing

* [x] Deploy crowdsale/token contract
* [x] Happy path testing - script [test/01_test1.sh](test/01_test1.sh) with results [test/test1results.txt](test/test1results.txt):
  * [x] Add KYC-ed accounts
  * [x] KYC-ed account can contribute before START_DATE, non-KYC-ed account cannot contributed before START_DATE
  * [x] KYC-ed account can contribute after START_DATE, and non-KYC-ed account can contributed after START_DATE
  * [x] Contribute past the minimum funding goal
  * [x] Finalise the crowdsale
  * [x] `transfer(...)`, `approve(...)` and `transferFrom(...)` the tokens
  * [x] Cannot send contributions after the crowdsale has been finalised
* [x] Abort and refund testing - script [test/02_test2.sh](test/02_test2.sh) with results [test/test2results.txt](test/test2results.txt):
  * [x] Add KYC-ed accounts
  * [x] KYC-ed account can contribute before START_DATE, non-KYC-ed account cannot contributed before START_DATE
  * [x] KYC-ed account can contribute after START_DATE, and non-KYC-ed account can contributed after START_DATE
  * [x] Contribute past the minimum funding goal
  * [x] Abort the crowdsale
  * [x] Claim refunds
* [x] Minimum goal not reached and refund testing - script [test/03_test3.sh](test/03_test3.sh) with results [test/test3results.txt](test/test3results.txt):
  * [x] Add KYC-ed accounts
  * [x] KYC-ed account can contribute before START_DATE, non-KYC-ed account cannot contributed before START_DATE
  * [x] KYC-ed account can contribute after START_DATE, and non-KYC-ed account can contributed after START_DATE
  * [x] Contribute below the minimum funding goal
  * [x] Wait until crowdsale ends
  * [x] Claim refunds

Details of the testing environment can be found in [test](test).

<br />

<hr />

## Code Review

* [x] [code-review/VentanaToken.md](code-review/VentanaToken.md)
  * [x] contract VentanaTokenConfig
  * [x] library SafeMath
  * [x] contract ReentryProtected
  * [x] contract ERC20Token
  * [x] contract VentanaTokenAbstract
  * [x] contract VentanaToken is ReentryProtected, ERC20Token, VentanaTokenAbstract, VentanaTokenConfig
  * [x] interface Notify
  * [x] contract VeredictumTest is Notify

<br />

<hr />

## References

* [Ethereum Contract Security Techniques and Tips](https://github.com/ConsenSys/smart-contract-best-practices)

<br />

<br />

Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd for Veredictum Aug 10 2017. The MIT Licence.