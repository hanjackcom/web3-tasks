package main

import (
	"context"
	"fmt"
	"log"
	"solana-go/utils"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/rpc"
	"github.com/gagliardetto/solana-go/rpc/ws"
)

func main() {
	// 0. initial rpc client
	rpcClient := rpc.New(rpc.DevNet_RPC)
	wsClient, err := ws.Connect(context.Background(), rpc.DevNet_WS)
	if err != nil {
		log.Fatalf("WebSocket connect failed: %v", err)
	}
	defer wsClient.Close()

	// 1. get latest blockhash
	recentBlockhash, lastValidBlockHeight, err := utils.GetRecentBlockhash(rpcClient)
	if err != nil {
		log.Fatalf("get latest block hash failed: %v", err)
	}
	fmt.Printf("latest block hash is: %s\n", recentBlockhash)
	fmt.Printf("last valid block height is: %d\n", lastValidBlockHeight)

	// replace your actual private key
	fromWallet := utils.GetAccountFromPrivateKey("wallet-keypair.json")
	toWallet2 := utils.GetAccountFromPrivateKey("wallet-keypair2.json")

	fmt.Printf("Account 2: %s\n", toWallet2.PublicKey().String())
	// 2. get balance
	walletAddress := solana.MustPublicKeyFromBase58(fromWallet.PublicKey().String()) // replace your actual address
	balance, err := utils.GetBalance(rpcClient, walletAddress)
	if err != nil {
		log.Fatalf("get balance failed: %v", err)
	}
	fmt.Printf("balance is: %f SOL\n", balance)

	//toWallet := solana.MustPublicKeyFromBase58("Dukdx2R3wMvnAvriU5HnLDFjqgjHDKCqLnux2opC85PT") // replace your actual address

	amount := uint64(1000000) // 0.001 SOL
	// request air drop, make sure enough balance in your account
	airdropSig, err := rpcClient.RequestAirdrop(
		context.TODO(),
		fromWallet.PublicKey(),
		solana.LAMPORTS_PER_SOL*1, // 1 SOL
		rpc.CommitmentConfirmed,   // using confirmed
	)
	if err != nil {
		log.Fatalf("Airdrop failed: %v", err)
	}
	fmt.Printf("Airdrop transaction signature: %s\n", airdropSig)
	// wait for a short while to ensure airdrop is processed
	time.Sleep(5 * time.Second)
	
	// get latest block hash and valid height
	recent, err := rpcClient.GetLatestBlockhash(
		context.TODO(),
		rpc.CommitmentConfirmed,
	)
	if err != nil {
		log.Fatalf("Failed to get recent blockhash: %v", err)
	}
	blockhash := recent.Value.Blockhash
	lastlockHeight := recent.Value.LastValidBlockHeight

	// check current block height valid
	currentHeight, err := rpcClient.GetBlockHeight(context.TODO(), rpc.CommitmentConfirmed)
	if err != nil {
		log.Fatalf("Failed to get current block height: %v", err)
	}
	if currentHeight > lastlockHeight {
		log.Fatalf("Blockhash expired. Current height: %d, Last valid height: %d", currentHeight, lastlockHeight)
	}

	// 3. create and send transfer
	signature, err := utils.TransferSOL(rpcClient, wsClient, fromWallet, toWallet2.PublicKey(), amount, blockhash)
	if err != nil {
		log.Fatalf("transfer failed: %v", err)
	}
	fmt.Printf("transfer successfully! signature is: %s\n", signature)

	// 4. listen transaction confirmation
	sub, err := wsClient.SignatureSubscribe(
		signature,
		"",
	)
	if err != nil {
		log.Fatalf("subscribe transaction event failed: %v", err)
	}
	defer sub.Unsubscribe()

	go func() {
		for {
			select {
			case <-sub.Response():
				fmt.Println("transaction is confirmed!")
				return
			case <-time.After(30 * time.Second):
				fmt.Println("transaction confirmation timeout")
				return
			}
		}
	}()

	// 5. smart contract interaction example
	//swapClient, err := tokenswap.NewTokenSwapClient(rpcClient, fromWallet)
	//if err != nil {
	//	log.Fatalf("create swap client failed: %v", err)
	//}
	//
	//// do swap
	//swapSignature, err := swapClient.SwapTokens(
	//	context.Background(),
	//	solana.MustPublicKeyFromBase58("InputTokenMint"),
	//	solana.MustPublicKeyFromBase58("OutputTokenMint"),
	//	uint64(1000000), // input amount
	//	recentBlockhash,
	//)
	//if err != nil {
	//	log.Fatalf("token swap failed: %v", err)
	//}
	//fmt.Printf("token swap successfully! signature is: %s\n", swapSignature)
	//
	// wait for user input
	//fmt.Println("input Enter, and exit...")
	//fmt.Scanln()
}