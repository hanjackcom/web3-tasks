# gen contrace code experience
using abigen tool generate go binding code automatically, and interact with contract of sepolia test net.

steps:
### 1. coding contract
1.1 coding a Counter.sol
1.2 compile and generate abi bytecode file
tools:
```shell
npm install -g solc
solcjs --bin contract/Counter.sol
solcjs --abi contract/Counter.sol

abigen --bin=contract_Counter_sol_Counter.bin --abi=contract_Counter_sol_Counter.abi --pkg=counter --out=counter/counter.go


```

### 2. generate binding code with abigen
2.1 install abigen tool
2.2 using abigen generate go binding code by abi file and bytecode file.

### 3. go binding code interact with contract
3.1 coding a main.go, which contains some logic, then connect to sepolia contract.
3.2 call contract's method, e.g. increment.
3.3 output result.

