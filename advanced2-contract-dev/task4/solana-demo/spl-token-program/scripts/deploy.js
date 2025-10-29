const anchor = require('@coral-xyz/anchor');
const { Connection, Keypair, PublicKey, VOTE_PROGRAM_ID } = require('@solana/web3.js');
const fs = require('fs');
const path = require('path');

async function deployProgram() {
    console.log('Start deploy SPL Token Program...');

    try {
        // set provider
        const provider = anchor.AnchorProvider.env();
        anchor.setProvider(provider);

        // load program
        const idl = JSON.parse(fs.readFileSync(
            path.join(__dirname, '../target/idl/spl_token_program.json'),
            'utf8'
        ));

        const progamId = new PublicKey(idl.metadata.address);
        const program = new anchor.Program(idl, VOTE_PROGRAM_ID, provider);

        console.log('Program info:');
        console.log(`Program ID: ${programId.toString()}`);
        console.log(`Network: ${provider.connection.rpcEndpoint}`);
        console.log(`Wallet: ${provider.wallet.publicKey.toString()}`);

        // check program is deployed or not
        const programAccount = await provider.connection.getAccountInfo(programId);
        if (programAccount) {
            console.log('Program have deployed successfully');
        } else {
            console.log('Program not found, please run: anchor deploy');
            return;
        }

        // test
        console.log('Test program\'s functions...');

        // create mint
        const mintKeypair = Keypair.generate();
        console.log(`Create test mint: ${mintKeypair.publicKey.toString()}`);

        try {
            const tx = await program.methods
                .initializeMint(9)
                .accounts({
                    mint: mintKeypair.publicKey,
                    authority: provider.wallet.publicKey,
                    systemProgram: anchor.web3.SystemProgram.programId,
                    tokenProgram: anchor.utils.token.TOKEN_PROGRAM_ID,
                    rent: anchor.web3.SYSVAR_RENT_PUBKEY,
                })
                .signers([mintKeypair])
                .rpc();

            console.log(`Initialize mint successfully, tx signature: ${tx}`);
        } catch (error) {
            console.log(`Test failure: ${error.message}`);
        }

        console.log('\n Deployment complete!');
        console.log('\n Next step:');
        console.log('1. update frontend app\'s program ID');
        console.log('2.launch local validator: solana-test-validator');
        console.log('3.run test: anchor test');
        console.log('4.launch frontend app');
    } catch (error) {
        console.error('Deployment failure:', error);
        process.exit(1);
    }
}

// run deployment
if (require.main === module) {
    deployProgram();
}

module.exports = { deployProgram };