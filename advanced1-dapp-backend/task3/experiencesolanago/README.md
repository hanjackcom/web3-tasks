# README
## SDK

https://github.com/gagliardetto/solana-go.git

## document

[solana experience](./solana-experience.md)

## some enviroment

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env" # reload PATH
rustc --version

sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
solana --version
agave-install update

cargo install --git https://github.com/solana-foundation/anchor avm --force
avm --version
avm install latest
avm use latest
anchor --version
```

```shell
solana-keygen new --outfile ~/.config/solana/wallet-keypair.json
solana-keygen new --outfile ~/.config/solana/wallet-keypair2.json

solana config get
Config File: /root/.config/solana/cli/config.yml
RPC URL: https://api.mainnet-beta.solana.com
WebSocket URL: wss://api.mainnet-beta.solana.com/ (computed)
Keypair Path: /root/.config/solana/id.json
Commitment: confirmed

solana config set --url https://api.devnet.solana.com
solana balance 8BSvbQ5uMdQDYFyP7FupCA5RataTQegZXMpJFfrM3TEy

```

soscan.io

https://solscan.io/account/8BSvbQ5uMdQDYFyP7FupCA5RataTQegZXMpJFfrM3TEy?cluster=devnet

## build & run
```shell
go mod init experiencesolanago
go mod tidy
go build
./experiencesolanago
```



