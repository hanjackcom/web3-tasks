package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log"
	"math/big"
	"os"
	"time"

	"gencontractcode/counter"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
		return
	}

	rpcURL := os.Getenv("SEPOLIA_RPC")
	privHex := os.Getenv("PRIV_KEY_HEX")
	chainIDStr := os.Getenv("CHAIN_ID")
	if chainIDStr == "" {
		chainIDStr = "11155111" // Sepolia
	}
	log.Printf("rpcURL: %s\n", rpcURL)
	log.Printf("privHex: %s\n", privHex)
	log.Printf("chainID: %s\n", chainIDStr)
	// parse chainID
	chainID, _ := new(big.Int).SetString(chainIDStr, 10)

	// 1. connect Sepolia
	ctx := context.Background()
	client, err := ethclient.DialContext(ctx, rpcURL)
	if err != nil {
		log.Fatalf("dial rpc err: %v", err)
	}
	defer client.Close()

	// 2. get private key and account
	privateKey, err := crypto.HexToECDSA(privHex)
	if err != nil {
		log.Fatalf("bad PRIV_KEY_HEX: %v", err)
	}
	publicKey := privateKey.Public()
	pubECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("cannot cast public key")
	}
	fromAddr := crypto.PubkeyToAddress(*pubECDSA)
	fmt.Printf("Using account: %s\n", fromAddr.Hex())

	// 3) new transaction auth (EIP-1559)
	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatalf("new transactor: %v", err)
	}
	// estimate gas with geth automatically, or set gas manually
	// auth.GasFeeCap / GasTipCap / GasLimit

	// 4) deploy contract
	contractAddr, deployTx, c, err := counter.DeployCounter(auth, client)
	if err != nil {
		log.Fatalf("deploy: %v", err)
	}
	fmt.Printf("Deployment tx: %s\n", deployTx.Hash().Hex())
	fmt.Printf("Contract address (pending): %s\n", contractAddr.Hex())

	// wait for on chain
	waitMined(ctx, client, deployTx.Hash())
	fmt.Printf("Deployed at: %s\n", contractAddr.Hex())

	// 5) get count 
	cur, err := c.GetCount(&bind.CallOpts{Context: ctx})
	if err != nil {
		log.Fatalf("read getCount(): %v", err)
	}
	fmt.Printf("getCount(): %s\n", cur.String())

	// 6) call increment
	tx, err := c.Increment(auth)
	if err != nil {
		log.Fatalf("increment: %v", err)
	}
	fmt.Printf("increment() tx: %s\n", tx.Hash().Hex())
	waitMined(ctx, client, tx.Hash())

	// 7) get count again
	cur2, err := c.GetCount(&bind.CallOpts{Context: ctx})
	if err != nil {
		log.Fatalf("read getCount() after increment: %v", err)
	}
	fmt.Printf("getCount() after increment: %s\n", cur2.String())
}

func waitMined(ctx context.Context, c *ethclient.Client, txHash common.Hash) {
	for {
		_, isPending, err := c.TransactionByHash(ctx, txHash)
		if err != nil {
			// sometimes we get "not found" if it is not mined yet
			time.Sleep(2 * time.Second)
			continue
		}
		if !isPending {
			break
		}
		time.Sleep(2 * time.Second)
	}
}

