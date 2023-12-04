## Best Practices

- Avoid floating pragma
- Modular approach
  - object-oriented mind-set?
- Circuit breakerk
  - Pausable
- External call/External contract interaction
  - Reentrancy
    - do state change before the call
    - follow check, effect, interaction pattern
- leverage battle-tested libraries
- delay action for a set of time(block.timestamp) when funds is involved
- use `call()` when sending Ether via calling the `fallback` function or `msg.data.length == 0`, not the recommend way to call existing functions, reasons avoid using `call()`:
  - Reverts are not bubbled up
  - Type checks are bypassed
  - Function existence checks are omitted
  - use `require(msg.data.length == 0)` inside `fallback` function
- `receive() external payable` should be used where call data is empty and any value is sent via `transfer()` or `send()`
- awareness the difference of assert(), require(), revert()
  - assert() is used to check for internal errors and to check invariants
  - require() is used to ensure valid conditions, such as inputs, or contract state variables are met, or to validate return values from calls to external contracts
  - revert() is similar to require() in usage and is used to revert state in the case of an error
- modifiers also lead reentrancy risk
  - only use modifiers to check invariants. require()/revert() should be used to check for valid conditions
- explicit labeling of visibility, `public`, `external`, `internal`, `private`
  - function in interface are always `external`
  - `external` can only be called from outside the contract, not internally
- use interface type as function parameter, so as to enable compiler guarantee type safety throughout the input life cycle

### references

- [Smart Contract Best Practices](https://consensys.github.io/smart-contract-best-practices/development-recommendations/)
- [Smart Contract Security Field Guide](https://scsfg.io/)
- [Smart Contract Security Verification Standard ](https://github.com/ComposableSecurity/SCSVS)
- [EEA EthTrust](https://entethalliance.org/specs/ethtrust-sl/#sec-security-considerations)
