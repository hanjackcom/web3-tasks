# gen contract code experience
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

# yet using: 
# npm install -g solc-cli 
# install solc, and using:
# solc --abi Counter.sol -o build 
# generate ABI file.

```

### 2. generate binding code with abigen

2.1 install abigen tool

```shell
go get -u github.com/ethereum/go-ethereum
cd $GOPATH/pkg/mod/github.com/ethereum/go-ethereum@v1.16.4
make
make devtools
# or directly：
go install github.com/ethereum/go-ethereum/cmd/abigen@latest

which abigen
abigen -v
abigen --help
```

2.2 using abigen generate go binding code by abi file and bytecode file.

```shell
abigen --bin=contract_Counter_sol_Counter.bin --abi=contract_Counter_sol_Counter.abi --pkg=counter --out=counter/counter.go
```

### 3. go binding code interact with contract

3.1 coding a main.go, which contains some logic, then connect to sepolia contract.

3.2 call contract's method, e.g. increment.

3.3 output result.

```shell
go mod tidy
go build
./gencontractcode
```

