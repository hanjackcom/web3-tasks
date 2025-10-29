const anchor = require('@coral-xyz/anchor');
const { Connection, Keypair, PublicKey, LAMPORTS_PER_SOL } = require('@solana/web3.js');
const {
    TOKEN_PROGRAM_ID,
    createMint,
    getOrCreateAssociatedTokenAccount,
    mintTo,
    transfer,
    burn,
    getMint,
    getAccount
} = require('@solana/spl-token');
const fs = require('fs');
const { sign } = require('crypto');

class TokenManager {
    constructor() {
        this.connection = new Connection('http://localhost:8899', 'confirmed');
        this.payer = null;
        this.mint = null;
    }

    async initialize() {
        console.log('Initialize toekn manager...');

        // create or load payer's wallet
        try {
            const keypairPath = './keypair.json';
            if (fs.existsSync(keypairPath)) {
                const keypairData = JSON.parse(fs.readFileSync(keypairPath, 'utf8'));
                this.payer = Keypair.fromSecretKey(new Uint8Array(keypairData));
                console.log(`Load current wallet: ${this.payer.publicKey.toString()}`);
            } else {
                this.payer = Keypair.generate();
                fs.writeFileSync(keypairPath, JSON.stringify(Array.from(this.payer.secretKey)));
                console.log(`Create new wallet: ${this.payer.publicKey.toString()}`);
            }
        } catch (error) {
            console.error('Wallet initial fail:', error);
            return false;
        }

        // check balance and request airdrop
        await this.ensureBalance();

        return true;
    }

    async ensureBalance() {
        const balance = await this.connection.getBalance(this.payer.publicKey);
        console.log(`Current balance: ${balance / LAMPORTS_PER_SOL} SOL`);

        if (balance < LAMPORTS_PER_SOL) {
            console.log('Balance insufficient, request airdrop...');
            try {
                const signature = await this.connection.requestAirdrop(
                    this.payer.publicKey,
                    2 * LAMPORTS_PER_SOL
                );
                await this.connection.confirmTransaction(signature);
                console.log('Airdrop successfully');
            } catch (error) {
                console.error('Airdrop fail:', error);
            }
        }
    }

    async createToken(decimals = 9) {
        console.log(`Create new token (${decimals} decimals)...`);

        try {
            this.mint = await createMint(
                this.connection,
                this.payer,
                this.payer.publicKey, // mint authority
                this.payer.publicKey, // freeze authority
                decimals
            );

            console.log(`Create token successfully: ${this.mint.toString()}`);

            // save mint addresss
            fs.writeFileSync('./mint-address.txt', this.mint.toString());

            return this.mint;
        } catch (error) {
            console.error('Create token fail:', error);
            return null;
        }
    }

    async loadToken(mintAddress) {
        console.log(`Load token: ${mintAddress}`);

        try {
            this.mint = new PublicKey(mintAddress);

            // check mint exists or not
            const mintInfo = await getMint(this.connection, this.mint);
            console.log('Load token successfully');
            console.log(`Decimals: ${mintInto.decimals}`);
            console.log(`Total supply: ${mintInfo.supply.toString()}`);

            return this.mint;
        } catch (error) {
            console.error('Load token fail:', error);
            return null;
        }
    }

    async mintTokens(toAddress, amount) {
        if (!this.mint) {
            console.error('Create/Load toekn firstly, please');
            return null;
        }

        console.log(`Mint ${amount} token to ${toAddress} ...`);

        try {
            const toPublicKey = new PublicKey(toAddress);

            // get or create associated account
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                toPublicKey
            );

            // get mint info ensure that decimals
            const mintInfo = await getMint(this.connection, this.mint);
            const mintAmount = amount * Math.pow(10, mintInfo.decimals);

            // mint token
            const signature = await mintTo(
                this.connection,
                this.payer,
                this.mint,
                tokenAccount.address,
                this.payer,
                mintAddress
            );

            console.log(`Mint successfully, tx signature: ${signature}`);
            return signature;
        } catch (error) {
            console.error('Mint fail:', error);
            return null;
        }
    }

    async trasnferTokens(fromAddress, toAddress, amount) {
        if (!this.mint) {
            console.error('Create/Load token firstly, please');
            return null;
        }

        console.log(`From ${fromAddress} to ${toAddress}, transfer ${amount} ...`);

        try {
            const fromPublicKey = new PublicKey(fromAddress);
            const toPublicKey = new PublicKey(toAddress);

            // get source account
            const fromTokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                fromPublicKey
            );

            // get destination account
            const toTokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                toPublicKey
            );

            // get mint info ensure that decimals
            const mintInfo = await getMint(this.connection, this.mint);
            const transferAmount = amount * Math.pow(10, mintInfo.decimals);

            // transfer
            const signature = await transfer(
                this.connection,
                this.payer,
                fromTokenAccount.address,
                toTokenAccount.address,
                fromPublicKey,
                transferAmount
            );

            console.log(`Transfer successfully, tx signature: ${signature}`);
            return signature;
        } catch (error) {
            console.error('Transfer fail:', error);
            return null;
        }
    }

    async burnTokens(ownerAddress, amount) {
        if (!this.mint) {
            console.error('Create/Load token firstly, please');
            return null;
        }

        console.log(`Burn ${ownerAddress} token amount: ${amount} ...`);

        try {
            const ownerPublicKey = new PublicKey(ownerAddress);

            // get token account
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                ownerPublicKey
            );

            // get mint info ensure that decimals
            const mintInfo = await getMint(this.connection, this.mint);
            const burnAmount = amount * Math.pow(10, mintInfo.decimals);

            // burn token
            const signature = await burn(
                this.connection,
                this.payer,
                tokenAccount.address,
                this.mint,
                ownerPublicKey,
                burnAmount
            );

            console.log(`Burn successfully, tx signature: ${signature}`);
            return signature;
        } catch (error) {
            console.error('Burn fail:', error);
            return null;
        }
    }

    async getTokenInfo() {
        if (!this.mint) {
            console.error('Create/Load token firstly, please');
            return null;
        }

        try {
            const mintInfo = await getMint(this.connection, this.mint);

            console.log('Token info:');
            console.log(` Address: ${this.mint.toString()}`);
            console.log(`  Decimals: ${mintInfo.decimals}`);
            console.log(`  Total supply ${Number(mintInfo.supply) / Math.pow(10, mintInfo.decimals)}`);
            console.log(`  Burn authority: ${mintInfo.mintAuthority?.toString() || 'None'}`);
            console.log(`  Freeze authority: ${mintInfo.freezeAuthority?.toString() || 'None'}`);

            return mintInfo;
        } catch (error) {
            console.error('Get token info fail:', error);
            return null;
        }
    }

    async getBalance(ownerAddress) {
        if (!this.mint) {
            console.error('Create/Load token firstly, please');
            return null;
        }

        try {
            const ownerPublicKey = new PublicKey(ownerAddress);
            const tokenAccount = await getOrCreateAssociatedTokenAccount(
                this.connection,
                this.payer,
                this.mint,
                ownerPublicKey
            );

            const accountInfo = await getAccount(this.connection, tokenAccount.address);
            const mintInfo = await getMint(this.connection, this.mint);

            const balance = Number(accountInfo.amount) / Math.pow(10, mintInfo.decimals);
            console.log(`${ownerAddress} blance: ${balance}`);

            return balance;
        } catch (error) {
            console.error('Get balance fail:', error);
            return null;
        }
    }
}

// commnad interface
async function main() {
    const args = process.argv.slice(2);
    const command = args[0];
    
    const manager = new TokenManager();
    await manager.initialize();

    switch(command) {
        case 'create':
            const decimals = parseInt(args[1]) || 9;
            await manager.createToken(decimals);
            break;

        case 'load':
            if (!args[1]) {
                console.error('Input mint address, please');
                break;
            }
            await manager.loadToken(args[1]);
            break;

        case 'mint':
            if (!args[1] || !args[2]) {
                console.error('Usage: mint <receive address> <amount>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.mintTokens(args[1], parseFload(args[2]));
            break;

        case 'transfer':
            if (!args[1] || !args[2] || !args[3]) {
                console.error('Usage: transfer <send address> <receive address> <amount>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'tf8').trim());
            await manager.trasnferTokens(ars[1], args[2], parseFload(args[3]));
            break;

        case 'burn':
            if (!args[1] || !args[2]) {
                console.error('Usage: burn <owner address> <amount>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.burnTokens(args[1], parseFloat(args[2]));
            break;

        case 'info':
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.getTokenInfo();
            break;

        case 'balance':
            if (!args[1]) {
                console.error('Usage: blanace <address>');
                break;
            }
            await manager.loadToken(fs.readFileSync('./mint-address.txt', 'utf8').trim());
            await manager.getBalance(args[1]);
            break;

        default:
            console.log('SPL token management tool');
            console.log('');
            console.log('Usage:')
            console.log('  node token-manager.js create [decimals]              - create new token');
            console.log('  node token-manager.js load <mint address>            - load current token');
            console.log('  node token-manager.js mint <address> <amount>        - mint token');
            console.log('  node token-manager.js transfer <from> <to> <amount>  - transfer token');
            console.log('  node token-manager.js burn <address> <amount>        - burn token');
            console.log('  node token-manager.js info                           - get token info');
            console.log('  node token-manager.js balance <address>              - get balance');
            break;
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = TokenManager;