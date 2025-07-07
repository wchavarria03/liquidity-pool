# SimpleDEX Manual Testing Results

## Pre-Testing Setup
- Open Remix IDE (https://remix.ethereum.org/)
- Upload TokenA.sol, TokenB.sol, and SimpleDEX.sol
- Compile all contracts with Solidity 0.8.20
- Note down the default Remix account addresses:
  - Account1: 0x43308eB6470bE6464de961827B9244776a768B7F
  - Account2: 0x0099884963469B157E4eBA4E0c71C8eC5A4BB41b  
  - Account3: 0x76add8b76C0f2E2177e9Cd7694b5408c3dc99F0F

---

## Phase 1: Contract Deployment Testing

### 1.1 Deploy TokenA
- Select TokenA contract in Remix
- Deploy with `initialSupply`: `2000000000000000000000` (2000 tokens)
- Verify deployment success
- Copy TokenA address: 0xDEF3a304c67F70AC25Ef83CC7f2132B18017c821
- Test `name()` function → Should return "TokenA"
- Test `symbol()` function → Should return "TKA"
- Test `decimals()` function → Should return 18
- Test `totalSupply()` function → Should return 2000000000000000000000

### 1.2 Deploy TokenB
- Select TokenB contract in Remix
- Deploy with `initialSupply`: `1000000000000000000000` (1000 tokens)
- Verify deployment success
- Copy TokenB address: 0x83dDe59FA972D3ed2566e50a403EaD76b0309d55
- Test `name()` function → Should return "TokenB"
- Test `symbol()` function → Should return "TKB"
- Test `decimals()` function → Should return 18
- Test `totalSupply()` function → Should return 1000000000000000000000

### 1.3 Deploy SimpleDEX
- Select SimpleDEX contract in Remix
- Deploy with:
  - `_tokenA`: 0xDEF3a304c67F70AC25Ef83CC7f2132B18017c821
  - `_tokenB`: 0x83dDe59FA972D3ed2566e50a403EaD76b0309d55
- Verify deployment success
- Copy SimpleDEX address: 0xBA3412737EEdD29CE08674108A74bcDE31A15ae2
- Test `tokenA()` function → Should return TokenA address
- Test `tokenB()` function → Should return TokenB address
- Test `totalLPTokenSupply()` function → Should return 0

---

## Phase 2: Initial Token Distribution Testing

### 2.1 Check Initial Balances (Account1)
- Go to TokenA contract
- Test `balanceOf(Account1)` → Should return 2000000000000000000000
- Go to TokenB contract
- Test `balanceOf(Account1)` → Should return 1000000000000000000000

### 2.2 Transfer Tokens to Account2
- Stay on Account1
- Go to TokenA contract
- Call `transfer(Account2, 500000000000000000000)` (500 TokenA)
- Verify transaction success
- Test `balanceOf(Account2)` → Should return 500000000000000000000
- Go to TokenB contract
- Call `transfer(Account2, 250000000000000000000)` (250 TokenB)
- Verify transaction success
- Test `balanceOf(Account2)` → Should return 250000000000000000000

### 2.3 Transfer Tokens to Account3
- Stay on Account1
- Go to TokenA contract
- Call `transfer(Account3, 500000000000000000000)` (500 TokenA)
- Verify transaction success
- Test `balanceOf(Account3)` → Should return 500000000000000000000
- Go to TokenB contract
- Call `transfer(Account3, 250000000000000000000)` (250 TokenB)
- Verify transaction success
- Test `balanceOf(Account3)` → Should return 250000000000000000000

---

## Phase 4: Account2 Liquidity Testing

### 4.1 Switch to Account2
- Change Remix account to Account2

### 4.2 Approve Tokens (Account2)
- Go to TokenA contract
- Call `approve(SimpleDEX_address, 100000000000000000000)` (100 TokenA)
- Verify transaction success
- Go to TokenB contract
- Call `approve(SimpleDEX_address, 50000000000000000000)` (50 TokenB)
- Verify transaction success

### 4.3 Add Liquidity (Account2)
- Go to SimpleDEX contract
- Call `addLiquidity(100000000000000000000, 50000000000000000000)` (100 TokenA, 50 TokenB)
- Verify transaction success
- Check transaction logs for `LiquidityAdded` event
- Test `addressToLPTokenBalance(Account2)` → Should return LP tokens
- Test `totalLPTokenSupply()` → Should be higher than before

---

## Phase 5: Account3 Liquidity Testing

### 5.1 Switch to Account3
- Change Remix account to Account3

### 5.2 Approve Tokens (Account3)
- Go to TokenA contract
- Call `approve(SimpleDEX_address, 100000000000000000000)` (100 TokenA)
- Verify transaction success
- Go to TokenB contract
- Call `approve(SimpleDEX_address, 50000000000000000000)` (50 TokenB)
- Verify transaction success

### 5.3 Add Liquidity (Account3)
- Go to SimpleDEX contract
- Call `addLiquidity(100000000000000000000, 50000000000000000000)` (100 TokenA, 50 TokenB)
- Verify transaction success
- Check transaction logs for `LiquidityAdded` event
- Test `addressToLPTokenBalance(Account3)` → Should return LP tokens
- Test `totalLPTokenSupply()` → Should be higher than before

---

## Phase 6: Swap Testing (Account3)

### 6.1 Approve TokenA for Swap
- Stay on Account3
- Go to TokenA contract
- Call `approve(SimpleDEX_address, 20000000000000000000)` (20 TokenA)
- Verify transaction success

### 6.2 Perform Swap A→B
- Go to SimpleDEX contract
- Call `swapAforB(100000000000000000000)` (10 TokenA)
- Verify transaction success
- Verify amount of TokenB received from event

---

## Phase 7: Reverse Swap Testing (Account2)

### 7.1 Switch to Account2
- Change Remix account to Account2

### 7.2 Approve TokenB for Swap
- Go to TokenB contract
- Call `approve(SimpleDEX_address, 40000000000000000000)` (40 TokenB)
- Verify transaction success

### 7.3 Perform Swap B→A
- Go to SimpleDEX contract
- Call `swapBforA(30000000000000000000)` (30 TokenB)
- Verify transaction success
- Check transaction logs for `Swap` event

---

## Phase 8: Liquidity Removal Testing

### 8.1 Switch to Account2
- Change Remix account to Account2

### 8.2 Record Pre-Removal Balances
- Test `TokenA.balanceOf(Account2)` → Record: 462112676056338028168
- Test `TokenB.balanceOf(Account2)` → Record: 160000000000000000000
- Test `SimpleDEX.addressToLPTokenBalance(Account2)` → Record: 70710678118654752440

### 8.3 Remove Some Liquidity
- Go to SimpleDEX contract
- Calculate amount to remove: 50% of 70710678118654752440 = 35355339059327376220
- Call `removeLiquidity(35355339059327376220)`
- Verify transaction success
- Check transaction logs for `LiquidityRemoved` event

### 8.4 Verify Post-Removal Balances
- Test `TokenA.balanceOf(Account2)` → Should be higher than pre-removal: 499084507042253521126
- Test `TokenB.balanceOf(Account2)` → Should be higher than pre-removal: 193809523809523809524
- Test `SimpleDEX.addressToLPTokenBalance(Account2)` → Should be lower than pre-removal: 35355339059327376220

---

## Testing Summary

### Completed Test Phases:
- ✅ Contract Deployment (TokenA, TokenB, SimpleDEX)
- ✅ Token Distribution (Account1 → Account2 & Account3)
- ✅ Liquidity Addition (Account2 & Account3)
- ✅ Token Swapping (Account3: A→B, Account2: B→A)
- ✅ Liquidity Removal (Account2: 50% removal)

### Key Results:
- **Pool Creation**: Successfully created with 200 TokenA + 100 TokenB
- **Multiple Providers**: Account2 and Account3 both added liquidity
- **Swap Functionality**: Both A→B and B→A swaps working correctly
- **Price Impact**: Swaps affected pool prices as expected
- **Liquidity Removal**: Account2 successfully removed 50% of LP tokens
- **Proportional Returns**: Received correct proportional amounts of both tokens

### Contract Addresses:
- **TokenA**: 0xDEF3a304c67F70AC25Ef83CC7f2132B18017c821
- **TokenB**: 0x83dDe59FA972D3ed2566e50a403EaD76b0309d55
- **SimpleDEX**: 0xBA3412737EEdD29CE08674108A74bcDE31A15ae2