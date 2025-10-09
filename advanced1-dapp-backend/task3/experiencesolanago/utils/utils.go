package utils

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/programs/system"
	"github.com/gagliardetto/solana-go/rpc"
	confirm "github.com/gagliardetto/solana-go/rpc/sendAndConfirmTransaction"
	"github.com/gagliardetto/solana-go/rpc/ws"
)

type KeyPairJSON struct {
	SecretKey []byte `json:"secret_key"`
}

// get latest block hash, and last effiency height
func GetRecentBlockhash(rpcClient *rpc.Client) (solana.Hash, uint64, error) {
	resp, err := rpcClient.GetLatestBlockhash(context.TODO(), rpc.CommitmentConfirmed)
	if err != nil {
		return solana.Hash{}, 0, fmt.Errorf("Get block hash failed: %v", err)
	}

	// last effiency height
	lastValidBlockHeight, err := rpcClient.GetBlockHeight(context.TODO(), rpc.CommitmentConfirmed)
	if err != nil {
		return solana.Hash{}, 0, fmt.Errorf("Get block height failed: %v", err)
	}

	return resp.Value.Blockhash, lastValidBlockHeight + 150, nil // generally, effiency height+150
}

// query account balance
func GetBalance(rpcClient *rpc.Client, account solana.PublicKey) (*rpc.GetBalanceResult, error) {
	balance, err := rpcClient.GetBalance(
		context.TODO(),
		account,
		rpc.CommitmentConfirmed,
	)
	if err != nil {
		return nil, fmt.Errorf("Get balance failed: %w", err)
	}
	return balance, nil
}

// query account from private key
func GetAccountFromPrivateKey(filePath string) solana.PrivateKey {
	privateKey, err := solana.PrivateKeyFromSolanaKeygenFile(filePath)
	if err != nil {
		panic(err)
	}
	//data, err := ioutil.ReadFile("wallet-keypair.json")
	//if err != nil {
	//	log.Fatal(err)
	//}
	//var keypair []byte
	//if err := json.Unmarshal(data, &keypair); err != nil {
	//	log.Fatal(err)
	//}
	//privateKeyBase58 := base58.Encode(keypair[:32])
	return privateKey
}

// transfer SOL
func TransferSOL(
	rpcClient *rpc.Client,
	wsClient *ws.Client,
	from solana.PrivateKey,
	to solana.PublicKey,
	amount uint64,
	recentBlockhash solana.Hash,
) (solana.Signature, error) {
	// create transfer instruction
	instruction := system.NewTransferInstruction(
		amount,
		from.PublicKey(),
		to,
	).Build()

	// create transaction
	tx, err := solana.NewTransaction(
		[]solana.Instruction{instruction},
		recentBlockhash,
		solana.TransactionPayer(from.PublicKey()),
	)
	if err != nil {
		return solana.Signature{}, fmt.Errorf("Create transaction failed: %v", err)
	}

	// sign transaction
	_, err = tx.Sign(func(key solana.PublicKey) *solana.PrivateKey {
		if from.PublicKey().Equals(key) {
			return &from
		}
		return nil
	})
	if err != nil {
		return solana.Signature{}, fmt.Errorf("Sign transaction failed: %v", err)
	}

	// send transaction and confirm with retry mechanism
	maxRetries := 3
	var sig solana.Signature
	for i := 0; i < maxRetries; i++ {
		sig, err = confirm.SendAndConfirmTransaction(
			context.TODO(),
			rpcClient,
			wsClient,
			tx,
		)
		if err != nil {
			if shouldRetry(err) {
				log.Printf("Attempt %d/%d failed: %v. Retrying...", i+1, maxRetries, err)
				time.Sleep(2 * time.Second) // wait for retry
				continue
			}
			log.Fatalf("Failed to send transaction: %v", err)
		}
		break
	}

	return sig, nil
}

// should retry
func shouldRetry(err error) bool {
	errMsg := err.Error()
	retryableErrors := []string{
		"Blockhash not found",
		"block height exceeded",
		"BlockhashNotFound",
	}
	for _, retryable := range retryableErrors {
		if strings.Contains(errMsg, retryable) {
			return true
		}
	}
	return false
}

// monitor transaction until confirmed
func WaitForConfirmation(wsClient *ws.Client, signature solana.Signature, timeout time.Duration) error {
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// create WebSocket client for listening transaction status
	wsClient, err := ws.Connect(ctx, rpc.MainNetBeta_WS)
	if err != nil {
		return fmt.Errorf("failed to connect to websocket: %v", err)
	}
	defer wsClient.Close()

	// subscribe to transaction signature
	sub, err := wsClient.SignatureSubscribe(
		signature,
		"",
	)
	if err != nil {
		return fmt.Errorf("failed to subscribe to signature: %v", err)
	}
	defer sub.Unsubscribe()

	// wait for confirmation or timeout
	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("context cancelled while waiting for confirmation")

		case resp, ok := <-sub.Response():
			if !ok {
				return fmt.Errorf("subscription closed")
			}

			if resp.Value.Err != nil {
				return fmt.Errorf("transaction failed: %v", resp.Value.Err)
			}

			//// check transaction status
			//if resp.Value.Context.Slot== rpc.ConfirmationStatusFinalized {
			//	return nil
			//}
		}
	}
}