package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"math"
	"math/big"
	"strings"
	"time"
	"crypto/ecdsa"
	"encoding/hex"

	"experienceblock/store"
	"experienceblock/token"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/crypto"
	"golang.org/x/crypto/sha3"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"

	"github.com/joho/godotenv"
)

var MY_API_KEY_URL string
var MY_API_WSS_URL string

func init() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
		return
	}
	MY_API_KEY_URL = os.Getenv("ALCHEMY_RPC")
	MY_API_WSS_URL = os.Getenv("WSS_SEPOLIA_RPC")
}

func query1() {
	fmt.Println("================= query block ================")

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal(err)
	}

	blockNumber := big.NewInt(5671744)

	header, err := client.HeaderByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(header.Number.Uint64())
	fmt.Println(header.Number.String())
	fmt.Println(header.Time)
	fmt.Println(header.Difficulty.Uint64())
	fmt.Println(header.Hash().Hex())

	block, err := client.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(block.Number().Uint64())
	fmt.Println(block.Time())
	fmt.Println(block.Difficulty().Uint64())
	fmt.Println(block.Hash().Hex())
	fmt.Println(block.Transactions())
	
	count, err := client.TransactionCount(context.Background(), block.Hash())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(count)

	fmt.Println("================= query transaction ================")

	chainID, err := client.ChainID(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	for _, tx := range block.Transactions() {
		fmt.Println(tx.Hash().Hex())
		fmt.Println(tx.Value().String())
		fmt.Println(tx.Gas())
		fmt.Println(tx.GasPrice().Uint64())
		fmt.Println(tx.Nonce())
		fmt.Println(tx.Data())
		fmt.Println(tx.To().Hex())

		if sender, err := types.Sender(types.NewEIP155Signer(chainID), tx); err == nil {
			fmt.Println("sender", sender.Hex())
		} else {
			log.Fatal(err)
		}

		receipt, err := client.TransactionReceipt(context.Background(), tx.Hash())
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(receipt.Status)
		fmt.Println(receipt.Logs)
		break
	}

	blockHash := common.HexToHash("0xae713dea1419ac72b928ebe6ba9915cd4fc1ef125a606f90f5e783c47cb1a4b5")
	count, err = client.TransactionCount(context.Background(), blockHash)
	if err != nil {
		log.Fatal(err)
	}

	for idx := uint(0); idx < count; idx++ {
		tx, err := client.TransactionInBlock(context.Background(), blockHash, idx)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(tx.Hash().Hex())
		break
	}

	txHash := common.HexToHash("0x20294a03e8766e9aeab58327fc4112756017c6c28f6f99c7722f4a29075601c5")
	tx, isPending, err := client.TransactionByHash(context.Background(), txHash)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(isPending)
	fmt.Println(tx.Hash().Hex())

	fmt.Println("================= query receipt ================")

	receiptByHash, err := client.BlockReceipts(context.Background(), rpc.BlockNumberOrHashWithHash(blockHash, false))
	if err != nil {
		log.Fatal(err)
	}
	receiptsByNum, err := client.BlockReceipts(context.Background(), rpc.BlockNumberOrHashWithNumber(rpc.BlockNumber(blockNumber.Int64())))
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(receiptByHash[0] == receiptsByNum[0])

	for _, receipt := range receiptByHash {
		fmt.Println(receipt.Status)
		fmt.Println(receipt.Logs)
		fmt.Println(receipt.TxHash.Hex())
		fmt.Println(receipt.TransactionIndex)
		fmt.Println(receipt.ContractAddress.Hex())
		break
	}

	txHash = common.HexToHash("0x20294a03e8766e9aeab58327fc4112756017c6c28f6f99c7722f4a29075601c5")
	receipt, err := client.TransactionReceipt(context.Background(), txHash)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(receipt.Status)
	fmt.Println(receipt.Logs)
	fmt.Println(receipt.TxHash.Hex())
	fmt.Println(receipt.TransactionIndex)
	fmt.Println(receipt.ContractAddress.Hex())

	fmt.Println("================= create new wallet ================")

	privateKey, err := crypto.GenerateKey()
	if err != nil {
		log.Fatal(err)
	}

	privateKeyBytes := crypto.FromECDSA(privateKey)
	fmt.Println(hexutil.Encode(privateKeyBytes)[2:])
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	publicKeyBytes := crypto.FromECDSAPub(publicKeyECDSA)
	fmt.Println("from pubKey:", hexutil.Encode(publicKeyBytes)[4:])
	address := crypto.PubkeyToAddress(*publicKeyECDSA).Hex()
	fmt.Println(address)
	hash := sha3.NewLegacyKeccak256()
	hash.Write(publicKeyBytes[1:])
	fmt.Println("full:", hexutil.Encode(hash.Sum(nil)[:]))
	fmt.Println(hexutil.Encode(hash.Sum(nil)[12:]))

}

func transfer2() {
	fmt.Println("================= eth transfer ================")

	// according to the bellow wallet logic, firstly, generate privatekey and address. Secondly, we transfer to it manully, then transfer back.
	// privateKey: f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9
	// address: 0x2e55dd100abeB5ecD371eEDA26792Ab18bBA78aa

	// client, err := ethclient.Dial("https://rinkeby.infura.io")
	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA("f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9")
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	// value := big.NewInt(10000000000000000)
	// value := big.NewInt(890000000000000000)
	value := big.NewInt(1999936900000)
	gasLimit := uint64(21000)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	// toAddress := common.HexToAddress("0x4592d8f8d7b001e72cb26a73e4fa1806a51ac79d")
	toAddress := common.HexToAddress("0x4134c35B29e59d3BA487bcAB0591138Ca207E91A")
	var data []byte
	tx := types.NewTransaction(nonce, toAddress, value, gasLimit, gasPrice, data)

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("tx send: %s\n", signedTx.Hash().Hex())
}

func tokenTransfer3() {
	fmt.Println("================= token transfer ================")
	// contract creator/from: 0x4134c35B29e59d3BA487bcAB0591138Ca207E91A
	// contract address: 0xedc0a3c94d1a72a2d2f70ae5fe9b0ed7a748a522
	// to: 0x2e55dd100abeB5ecD371eEDA26792Ab18bBA78aa 

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}

	privateKey, err := crypto.HexToECDSA("f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9")
	if err != nil {
		log.Fatal("private key err: ", err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal("nonce err: ", err)
	}

	value := big.NewInt(0)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal("gas price err: ", err)
	}

	toAddress := common.HexToAddress("0x4134c35B29e59d3BA487bcAB0591138Ca207E91A")
	// toAddress := common.HexToAddress("0x2e55dd100abeB5ecD371eEDA26792Ab18bBA78aa")
	tokenAddress := common.HexToAddress("0xedc0a3c94d1a72a2d2f70ae5fe9b0ed7a748a522")

	transferFnSignature := []byte("transfer(address,uint256)")
	hash := sha3.NewLegacyKeccak256()
	hash.Write(transferFnSignature)
	methodID := hash.Sum(nil)[:4]
	fmt.Println(hexutil.Encode(methodID))
	paddedAddress := common.LeftPadBytes(toAddress.Bytes(), 32)
	fmt.Println(hexutil.Encode(paddedAddress))
	amount := new(big.Int)
	amount.SetString("1000000000000000000", 10) // 1000 tokens
	paddedAmount := common.LeftPadBytes(amount.Bytes(), 32)
	fmt.Println("paddedAmount: ", hexutil.Encode(paddedAmount))
	var data []byte
	data = append(data, methodID...)
	data = append(data, paddedAddress...)
	data = append(data, paddedAmount...)

	gasLimit, err := client.EstimateGas(context.Background(), ethereum.CallMsg{
		To: &toAddress,
		Data: data,
	})
	if err != nil {
		log.Fatal("gas limit err: ", err)
	}
	fmt.Println(gasLimit)
	tx := types.NewTransaction(nonce, tokenAddress, value, gasLimit, gasPrice, data)

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal("chain id err: ", err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal("signed tx err: ", err)
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal("send transaction err: ", err)
	}

	fmt.Printf("tx sent: %s\n", signedTx.Hash().Hex())
}

func queryAccountBalance4() {
	fmt.Println("================= query account balance ================")

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}

	account := common.HexToAddress("0x4134c35B29e59d3BA487bcAB0591138Ca207E91A")
	balance, err := client.BalanceAt(context.Background(), account, nil)
	if err != nil {
		log.Fatal("balance at err: ", err)
	}
	fmt.Println(balance)
	blockNumber := big.NewInt(9409312)
	balanceAt, err := client.BalanceAt(context.Background(), account, blockNumber)
	if err != nil {
		log.Fatal("balance at 2 err: ", err)
	}
	fmt.Println(balanceAt)
	fbalance := new(big.Float)
	fbalance.SetString(balanceAt.String())
	ethValue := new(big.Float).Quo(fbalance, big.NewFloat(math.Pow10(18)))
	fmt.Println(ethValue)
	pendingBalance, err := client.PendingBalanceAt(context.Background(), account)
	if err != nil {
		log.Fatal("pending balance err: ", err)
	}
	fmt.Println(pendingBalance)
}

func queryTokenBalance5() {
	fmt.Println("================= query token balance ================")

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}

	tokenAddress := common.HexToAddress("0xedc0a3c94d1a72a2d2f70ae5fe9b0ed7a748a522")
	instance, err := token.NewToken(tokenAddress, client)
	if err != nil {
		log.Fatal("new token err: ", err)
	}
	address := common.HexToAddress("0x4134c35B29e59d3BA487bcAB0591138Ca207E91A")
	bal, err := instance.BalanceOf(&bind.CallOpts{}, address)
	if err != nil {
		log.Fatal("balance of err: ", err)
	}
	name, err := instance.Name(&bind.CallOpts{})
	if err != nil {
		log.Fatal("name err: ", err)
	}
	symbol, err := instance.Symbol(&bind.CallOpts{})
	if err != nil {
		log.Fatal("symbol err: ", err)
	}
	decimals, err := instance.Decimals(&bind.CallOpts{})
	if err != nil {
		log.Fatal("decimals err: ", err)
	}
	fmt.Printf("name: %s\n", name)
	fmt.Printf("symbol: %s\n", symbol)
	fmt.Printf("decimals: %v\n", decimals)
	fmt.Printf("wei: %s\n", bal)
	fbal := new(big.Float)
	fbal.SetString(bal.String())
	value := new(big.Float).Quo(fbal, big.NewFloat(math.Pow10(int(decimals))))
	fmt.Printf("balance: %f\n", value)
}

func subscribeBlock6() {
	fmt.Println("================= subscribe block ================")

	client, err := ethclient.Dial(MY_API_WSS_URL)
	if err != nil {
		log.Fatal(err)
	}

	headers := make(chan *types.Header)
	sub, err := client.SubscribeNewHead(context.Background(), headers)
	if err != nil {
		log.Fatal(err)
	}

	for {
		select {
		case err := <-sub.Err():
			log.Fatal(err)
		case header := <-headers:
			fmt.Println(header.Hash().Hex())
			block, err := client.BlockByHash(context.Background(), header.Hash())
			if err != nil {
				log.Fatal(err)
			}
			fmt.Println(block.Hash().Hex())
			fmt.Println(block.Number().Uint64())
			// fmt.Println(block.Time().Uint64())
			fmt.Println(block.Time())
			fmt.Println(block.Nonce())
			fmt.Println(len(block.Transactions()))
		}
	}
}

func delopyContract7_1() {
	fmt.Println("================= deploy contract 7_1 with abigen ================")

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal(err)
	}
	privateKey, err := crypto.HexToECDSA("f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9")
	if err != nil {
		log.Fatal(err)
	}
	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	chainId, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainId)
	if err != nil {
		log.Fatal(err)
	}
	auth.Nonce = big.NewInt(int64(nonce))
	auth.Value = big.NewInt(0) // in wei
	auth.GasLimit = uint64(300000) // in units
	auth.GasPrice = gasPrice

	input := "1.0"
	address, tx, instance, err := store.DeployStore(auth, client, input)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(address.Hex())
	fmt.Println(tx.Hash().Hex())

	_ = instance
}

func delopyContract7_2() {
	fmt.Println("================= deploy contract 7_2 with ethclient ================")

	const contractBytecode = "608060405234801561000f575f5ffd5b5060405161087838038061087883398181016040528101906100319190610193565b805f908161003f91906103ea565b50506104b9565b5f604051905090565b5f5ffd5b5f5ffd5b5f5ffd5b5f5ffd5b5f601f19601f8301169050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52604160045260245ffd5b6100a58261005f565b810181811067ffffffffffffffff821117156100c4576100c361006f565b5b80604052505050565b5f6100d6610046565b90506100e2828261009c565b919050565b5f67ffffffffffffffff8211156101015761010061006f565b5b61010a8261005f565b9050602081019050919050565b8281835e5f83830152505050565b5f610137610132846100e7565b6100cd565b9050828152602081018484840111156101535761015261005b565b5b61015e848285610117565b509392505050565b5f82601f83011261017a57610179610057565b5b815161018a848260208601610125565b91505092915050565b5f602082840312156101a8576101a761004f565b5b5f82015167ffffffffffffffff8111156101c5576101c4610053565b5b6101d184828501610166565b91505092915050565b5f81519050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602260045260245ffd5b5f600282049050600182168061022857607f821691505b60208210810361023b5761023a6101e4565b5b50919050565b5f819050815f5260205f209050919050565b5f6020601f8301049050919050565b5f82821b905092915050565b5f6008830261029d7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff82610262565b6102a78683610262565b95508019841693508086168417925050509392505050565b5f819050919050565b5f819050919050565b5f6102eb6102e66102e1846102bf565b6102c8565b6102bf565b9050919050565b5f819050919050565b610304836102d1565b610318610310826102f2565b84845461026e565b825550505050565b5f5f905090565b61032f610320565b61033a8184846102fb565b505050565b5b8181101561035d576103525f82610327565b600181019050610340565b5050565b601f8211156103a25761037381610241565b61037c84610253565b8101602085101561038b578190505b61039f61039785610253565b83018261033f565b50505b505050565b5f82821c905092915050565b5f6103c25f19846008026103a7565b1980831691505092915050565b5f6103da83836103b3565b9150826002028217905092915050565b6103f3826101da565b67ffffffffffffffff81111561040c5761040b61006f565b5b6104168254610211565b610421828285610361565b5f60209050601f831160018114610452575f8415610440578287015190505b61044a85826103cf565b8655506104b1565b601f19841661046086610241565b5f5b8281101561048757848901518255600182019150602085019450602081019050610462565b868310156104a457848901516104a0601f8916826103b3565b8355505b6001600288020188555050505b505050505050565b6103b2806104c65f395ff3fe608060405234801561000f575f5ffd5b506004361061003f575f3560e01c806348f343f31461004357806354fd4d5014610073578063f56256c714610091575b5f5ffd5b61005d600480360381019061005891906101d7565b6100ad565b60405161006a9190610211565b60405180910390f35b61007b6100c2565b604051610088919061029a565b60405180910390f35b6100ab60048036038101906100a691906102ba565b61014d565b005b6001602052805f5260405f205f915090505481565b5f80546100ce90610325565b80601f01602080910402602001604051908101604052809291908181526020018280546100fa90610325565b80156101455780601f1061011c57610100808354040283529160200191610145565b820191905f5260205f20905b81548152906001019060200180831161012857829003601f168201915b505050505081565b8060015f8481526020019081526020015f20819055507fe79e73da417710ae99aa2088575580a60415d359acfad9cdd3382d59c80281d48282604051610194929190610355565b60405180910390a15050565b5f5ffd5b5f819050919050565b6101b6816101a4565b81146101c0575f5ffd5b50565b5f813590506101d1816101ad565b92915050565b5f602082840312156101ec576101eb6101a0565b5b5f6101f9848285016101c3565b91505092915050565b61020b816101a4565b82525050565b5f6020820190506102245f830184610202565b92915050565b5f81519050919050565b5f82825260208201905092915050565b8281835e5f83830152505050565b5f601f19601f8301169050919050565b5f61026c8261022a565b6102768185610234565b9350610286818560208601610244565b61028f81610252565b840191505092915050565b5f6020820190508181035f8301526102b28184610262565b905092915050565b5f5f604083850312156102d0576102cf6101a0565b5b5f6102dd858286016101c3565b92505060206102ee858286016101c3565b9150509250929050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602260045260245ffd5b5f600282049050600182168061033c57607f821691505b60208210810361034f5761034e6102f8565b5b50919050565b5f6040820190506103685f830185610202565b6103756020830184610202565b939250505056fea26469706673582212202e6325285e4a6346e8f6e9ca520717624c14dbcaa677f82c1ef1898a3d56c78f64736f6c634300081e0033"

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal(err)
	}

	privateKey, err := crypto.HexToECDSA("f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9")
	if err != nil {
		log.Fatal(err)
	}

	publicKey := privateKey.Public()
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("error casting public key to ECDSA")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)
	if err != nil {
		log.Fatal(err)
	}

	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	data, err := hex.DecodeString(contractBytecode)
	if err != nil {
		log.Fatal(err)
	}

	tx := types.NewContractCreation(nonce, big.NewInt(0), 3000000, gasPrice, data)

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err)
	}

	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Transaction send: %s\n", signedTx.Hash().Hex())

	receipt, err := waitForReceipt(client, signedTx.Hash())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Contract deployed at: %s\n", receipt.ContractAddress.Hex())
}

func waitForReceipt(client *ethclient.Client, txHash common.Hash) (*types.Receipt, error) {
	for {
		receipt, err := client.TransactionReceipt(context.Background(), txHash)
		if err == nil {
			return receipt, nil
		}
		if err != ethereum.NotFound {
			return nil, err
		}
		time.Sleep(1 * time.Second)
	}
}

func loadContract8() {
	fmt.Println("================= load contract ================")

	const contractAddr = "0x21Ec3E453cFFa50c074f7A77cCd44ea13f8b0404"

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}
	storeContract, err := store.NewStore(common.HexToAddress(contractAddr), client)
	if err != nil {
		log.Fatal("load contract err: ", err)
	}

	_ = storeContract
	fmt.Println("loaded contract: ", storeContract)
}

func executeContract9() {
	fmt.Println("================= execute contract ================")

	const contractAddr = "0x21Ec3E453cFFa50c074f7A77cCd44ea13f8b0404"

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}

	storeContract, err := store.NewStore(common.HexToAddress(contractAddr), client)
	if err != nil {
		log.Fatal("load contract err: ", err)
	}

	privateKey, err := crypto.HexToECDSA("f382f5d0a53cf5f9ec5fcfb23d2b65ae99f1fcf4ac36444f22476c064123fff9")
	if err != nil {
		log.Fatal("private key err: ", err)
	}

	var key [32]byte
	var value [32]byte
	copy(key[:], []byte("demo_save_key2"))
	copy(value[:], []byte("demo_save_value11112"))

	opt, err := bind.NewKeyedTransactorWithChainID(privateKey, big.NewInt(11155111))
	if err != nil {
		log.Fatal("transactor err: ", err)
	}
	tx, err := storeContract.SetItem(opt, key, value)
	if err != nil {
		log.Fatal("execute contract err: ", err)
	}
	fmt.Println("tx hash: ", tx.Hash().Hex())

	callOpt := &bind.CallOpts{Context: context.Background()}
	valueInContract, err := storeContract.Items(callOpt, key)
	if err != nil {
		log.Fatal("call contract Items err: ", err)
	}
	fmt.Println("is value saving in contract equals to origin vlaue: ", valueInContract == value)
}

func contractEvent10_filter() {
	var StoreABI = `[{"inputs":[{"internalType":"string","name":"_version","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"key","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"ItemSet","type":"event"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"items","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"setItem","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]`

	client, err := ethclient.Dial(MY_API_KEY_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}

	fromBlockNum := big.NewInt(9409312)
	toBlockNum := big.NewInt(0).Add(fromBlockNum, big.NewInt(9)) // free user, only 10 numbers
	contractAddress := common.HexToAddress("0x21Ec3E453cFFa50c074f7A77cCd44ea13f8b0404")
	query := ethereum.FilterQuery{
		FromBlock: fromBlockNum,
		ToBlock: toBlockNum,
		Addresses: []common.Address{
			contractAddress,
		},
		// Topics: [][]common.Hash {
		// 	{},
		// 	{},
		// },
	}

	logs, err := client.FilterLogs(context.Background(), query)
	if err != nil {
		log.Fatal("filter logs err: ", err)
	}

	contractAbi, err := abi.JSON(strings.NewReader(StoreABI))
	if err != nil {
		log.Fatal("contractabi err: ", err)
	}

	for _, vLog := range logs {
		fmt.Println(vLog.BlockHash.Hex())
		fmt.Println(vLog.BlockNumber)
		fmt.Println(vLog.TxHash.Hex())
		event := struct {
			Key [32]byte
			Value [32]byte
		}{}
		err := contractAbi.UnpackIntoInterface(&event, "ItemSet", vLog.Data)
		if err != nil {
			log.Fatal("unpack into interface err: ", err)
		}

		fmt.Println(common.Bytes2Hex(event.Key[:]))
		fmt.Println(common.Bytes2Hex(event.Value[:]))
		var topics []string
		for i := range vLog.Topics {
			topics = append(topics, vLog.Topics[i].Hex())
		}

		fmt.Println("topics[0]=", topics[0])
		if len(topics) > 1 {
			fmt.Println("indexed topics:", topics[1:])
		}
	}

	eventSignature := []byte("ItemSet(bytes32, bytes32)")
	hash := crypto.Keccak256Hash(eventSignature)
	fmt.Println("signature topics=", hash.Hex())
}

func contractEvent10_subscribe() {
	var StoreABI = `[{"inputs":[{"internalType":"string","name":"_version","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"key","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"ItemSet","type":"event"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"items","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"setItem","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]`

	client, err := ethclient.Dial(MY_API_WSS_URL)
	if err != nil {
		log.Fatal("dial err: ", err)
	}
	contractAddress := common.HexToAddress("0x21Ec3E453cFFa50c074f7A77cCd44ea13f8b0404")
	query := ethereum.FilterQuery{
		Addresses: []common.Address{contractAddress},
	}
	logs := make(chan types.Log)
	sub, err := client.SubscribeFilterLogs(context.Background(), query, logs)
	if err != nil {
		log.Fatal("subscribe filter logs err: ", err)
	}
	contractAbi, err := abi.JSON(strings.NewReader(string(StoreABI)))
	if err != nil {
		log.Fatal("contractabi err: ", err)
	}

	for {
		select {
		case err := <-sub.Err():
			log.Fatal("sub err: ", err)
		case vLog := <-logs:
			fmt.Println(vLog.BlockHash.Hex())
			fmt.Println(vLog.BlockNumber)
			fmt.Println(vLog.TxHash.Hex())
			event := struct {
				Key [32]byte
				Value [32]byte
			}{}
			err := contractAbi.UnpackIntoInterface(&event, "ItemSet", vLog.Data)
			if err != nil {
				log.Fatal("unpack into interface err: ", err)
			}
			fmt.Println(common.Bytes2Hex(event.Key[:]))
			fmt.Println(common.Bytes2Hex(event.Value[:]))
			var topics []string
			for i := range vLog.Topics {
				topics = append(topics, vLog.Topics[i].Hex())
			}
			fmt.Println("topics[0]=", topics[0])
			if len(topics) > 1 {
				fmt.Println("index topic: ", topics[1:])
			}
		}
	}
}

func main() {
	// query1()
	// transfer2()
	
	// tokenTransfer3()

	// queryAccountBalance4()
	// queryTokenBalance5()
	// subscribeBlock6()

	// delopyContract7_1()
	// delopyContract7_2()

	// loadContract8()
	// executeContract9()
	// contractEvent10_filter()
	contractEvent10_subscribe()
}


