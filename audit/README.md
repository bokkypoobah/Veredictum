# Veredictum Crowdsale Contract Audit

Status: Work in progress

Commits [10ddcc98](https://github.com/o0ragman0o/Veredictum/tree/10ddcc98ede5696ed6a79d11607bd8000f8e0f7a),
[e6926f99](https://github.com/o0ragman0o/Veredictum/tree/e6926f9948bbce592af09a8456db08949f41f149),
[c140554b](https://github.com/o0ragman0o/Veredictum/tree/c140554b16d3d26ce71ffdd57bb3b0dcddd16f07)

<br />

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

<br />

<hr />

## Code Review

* [ ] [code-review/VentanaToken.md](code-review/VentanaToken.md)
  * [ ] contract VentanaTokenConfig
  * [ ] contract ReentryProtected
  * [ ] contract ERC20Token
  * [ ] contract VentanaTokenAbstract
  * [ ] contract VentanaToken is ReentryProtected, ERC20Token, VentanaTokenAbstract, VentanaTokenConfig
  * [ ] contract VeredictumTest is Notify