# Solana SPL Token Program

## Project Summary
This is a full resolution of Solana SPL Token Program. It's functions consist of create, mint, transfer, balances token. This Project use latest development tools, in sure that code quality and deployment efficiency.

### create project & build & test

```shell
npm install -g yarn
which yarn
yarn -v

anchor --version



anchor init spl-token-program
cd spl-token-program

# enviroment
yarn add @solana/spl-token
yarn add @solana/web3.js

# fix your bussiness logic.
# ignore

# generate your keypair file in /root/.config/solana/id.json
solana-keygen new
solana-keygen pubkey ~/.config/solana/id.json

# fix your delopyment environment in Anchor.toml
# 1) localnet
# cluster = "localnet"
# 2) Devnet
# cluster = "Devnet"
# 3) Mainnet
# cluster = "Mainnet"

# run a local node in another terminal
solana-test-validator

# airdrop for you account
solana-keygen pubkey
solana airdrop 2 2LQoJDEcQUx9ef6cBkMk1BY2tYtUVzCKqzp3zAWqtSTc --url http://127.0.0.1:8899
solana balance 2LQoJDEcQUx9ef6cBkMk1BY2tYtUVzCKqzp3zAWqtSTc --url http://127.0.0.1:8899

anchor build
anchor deploy

# close solana-test-validator, and test
anchor test
```

## References
* [Anchor Docuemnt: Local delopyment](https://www.anchor-lang.com/docs/quickstart/local#project-file-structure)
* [Anchor CLI 基础](https://solana.com/zh/docs/intro/installation/anchor-cli-basics)
* [solpg](https://beta.solpg.io/tutorials/hello-solana)