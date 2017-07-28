# Veridictum Crowdsale Contract Audit

Status: Work in progress

Commit [https://github.com/bokkypoobah/VeredictumCrowdsaleContractAudit/tree/cb51f6308fbf1c71241bf5cc08b5aaf65ff316a1](https://github.com/bokkypoobah/VeredictumCrowdsaleContractAudit/tree/cb51f6308fbf1c71241bf5cc08b5aaf65ff316a1).

## Code Review

* [ ] [code-review/VentanaToken.md](code-review/VentanaToken.md)
  * [ ] contract ReentryProtected
  * [ ] contract ERC20TokenAbstract
  * [ ] contract ERC20Token is ReentryProtected, ERC20TokenAbstract
  * [ ] contract VentanaTokenConfig
  * [ ] contract VentanaTokenAbstract is ERC20TokenAbstract
  * [ ] contract VentanaToken is ERC20Token, VentanaTokenAbstract, VentanaTokenConfig
