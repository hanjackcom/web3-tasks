# Substrate Demo

https://github.com/substrate-developer-hub/substrate-node-template 该模板已废弃，使用Polkadot-SDK构建自定义区块链项目。Polkadot-sdk具有FRAME、substrate和Cumulus功能，能够自定义Pallet设计模式。

本项目使用template：solochain-template。


### 创建项目

环境安装：

```shell

rustc --version

rustup toolchain install 1.86.0
rustup default 1.86.0
rustup target add wasm32-unknown-unknown --toolchain 1.86.0
rustup component add rust-src --toolchain 1.86.0

rustup show

apt install -y protobuf-compiler libclang1 libclang-dev clang

git clone https://github.com/paritytech/polkadot-sdk-solochain-template.git substrate-demo
cd substrate-demo

cargo clean
cargo build --release

# note: 
# trie-db incompat:
# cargo report future-incompatibilities --id 1 --package trie-db@0.30.0

./target/release/solochain-template-node -h
cargo +nightly doc --open
./target/release/solochain-template-node --dev


```

未完待续。

### 参考文档
* [Polkadot Documentation](https://docs.polkadot.com/)
* [Introduction to Polkadot SDK](https://docs.polkadot.com/develop/parachains/intro-polkadot-sdk/)
* [Substrate Node Template](https://github.com/paritytech/polkadot-sdk/tree/master/templates/solochain)
