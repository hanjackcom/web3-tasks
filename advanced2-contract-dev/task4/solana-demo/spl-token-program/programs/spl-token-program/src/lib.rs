use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Tranfser, MintTo, Burn};

declare_id!("Ag9Uf6x8qU2vXLQqg1YkG7ijpt2YJR72FcMHzJWbfHn4");

#[program]
pub mod spl_token_program {
    use super::*;

    pub fn initialize(ctx: Context<InitializeMint>) -> Result<()> {
        msg!("Greetings from: {:?}", ctx.program_id);
        Ok(())
    }

    // initial mint account
    pub fn initialize_mint(
        ctx: Context<InitializeMint>,
        decimals: u8,
        name: String,
        symbol: String,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;
        token_metadata.authority = ctx.accounts.authority.key();
        token_metadata.mint = ctx.accounts.mint.key();
        token_metadata.name = name;
        token_metadata.symbol = symbol;
        token_metadata.decimals = decimals;
        token_metadata.token_supply = 0;

        msg!("Token mint initialized: {}", ctx.accounts.mint.key());
        msg!("Name: {}, Symbol: {}, Decimals: {}", token_metadata.anme, token_metadata.symbol, decimals);
        Ok(())
    }

    // mint token
    pub fn mint_tokens(
        ctx: Context<MintTokens>,
        amount: u64,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;

        // check auth
        require!(ctx.accounts.authority.key() == token_metadata.authority, ErrorCode::UnauthorizedMintAuthority);

        // mint token
        let cpi_accounts = MintTo {
            mint: ctx.accounts.mint.to_account_info(),
            to: ctx.accounts.token_account.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);

        token::mint_to(cpi_ctx, amount)?;

        // update total supply
        token_metadata.total_supply = token_metadata.total_supply.checked_add(amount).ok_or(ErrorCode::MathOverflow);

        msg!("Minted {} tokens to {}", amount, ctx.accounts.token_account.key());
        Ok(())
    }

    // transfer token
    pub fn transfer_tokens(
        ctx: Context<TransferTokens>,
        amount: u64,
    ) -> Result<()> {
        let cpi_accounts = Transfer {
            from: ctx.accounts.from.to_account_info(),
            to: ctx.accounts.to.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);

        token::transfer(cpi_ctx, amount)?;

        msg!("Transferred {} tokens from {} to {}", amount, ctx.accounts.from.key(), ctx.accounts.to.key());
        Ok(())
    }

    // burn token
    pub fn burn_tokens(
        ctx: Context<BurnTokens>,
        amount: u64,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;

        let cpi_accounts = Burn {
            mint: ctx.accounts.mint.to_account_info(),
            from: ctx.accounts.token_account.to_account_info(),
            authority: ctx.accounts.authority.to_account_info(),
        };
        let cpi_program = ctx.accounts.token_program.to_account_info();
        let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);

        token::burn(cpi_ctx, amount)?;

        // update total supply
        token_metadata.total_supply = token_metadata.total_supply.checked_sub(amount).ok_or(ErrorCode::MathUnderflow)?;

        msg!("Burned {} tokens from {}", amount, ctx.accounts.toekn_account.key());
        Ok(())
    }

    // update mint auth
    pub fn update_mint_authority(
        ctx: Context<UpdateMintAuthority>,
        new_authority: Option<Pubkey>,
    ) -> Result<()> {
        let token_metadata = &mut ctx.accounts.token_metadata;

        // check current auth
        require!(ctx.accounts.current_authority.key() == token_metadata.authority, ErrorCode::UnauthorizedMintAuthority);

        // update auth
        if let Some(new_auth) = new_authority {
            token_metadata.authority = new_auth;
            msg!("Mint authority updated to: {}", new_auth);
        } else {
            // if None, then disable mint
            token_metadata.authority = Pubkey::default();
            msg!("Mint authority disabled");
        }

        Ok(())
    }

    // get token info
    pub fn get_token_info(ctx: Context<GetTokenInfo>) -> Result<()> {
        let token_metadata = &ctx.accounts.token_metadata;

        msg!("Token info:");
        msg!("  Mint: {}", token_metadata.mint);
        msg!("  Name: {}", token_metadata.name);
        msg!("  Symbol: {}", token_metadata.symbol);
        msg!("  Decimals: {}", token_metadata.decimals);
        msg!("  Total Supply: {}", token_metadata.total_supply);
        msg!("  Authority: {}", token_metadata.authority);

        Ok(())
    }
}

// account structure defines

#[derive(Accounts)]
#[instruction(decimals: u8, name: String, symbol: String)]
pub struct InitializeMint<'info> {
    #[account(
        init,
        payer = authority,
        mint::decimals = decimals,
        mint::authority = authority,
    )]
    pub mint: Account<'info, Mint>,

    #[account(
        init,
        payer = authority,
        space = 8 + TokenMetadata::INIT_SPACE,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,

    #[account(mut)]
    pub authority: Signer<'info>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}

#[derive(Accounts)]
pub struct MintTokens<'info> {
    #[account(mut)]
    pub mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,

    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = recipient,
    )]
    pub token_account: Account<'info, TokenAccount>,

    // check : this is the recipient of the tokens
    pub recipient: AccountInfo<'info>,

    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct TransferTokens<'info> {
    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = authority,
    )]
    pub from: Account<'info, TokenAccount>,

    #[acount(mut)]
    pub to: Account<'info, TokenAccount>,

    pub mint: Account<'info, Mint>,
    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct BurnTokens<'info> {
    #[account(mut)]
    pub mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,

    #[account(
        mut,
        associated_token::mint = mint,
        associated_token::authority = authority,
    )]
    pub token_account: Account<'info, TokenAccount>,

    pub authority: Signer<'info>,
    pub token_program: Program<'info, Token>,
}

#[derive(Accounts)]
pub struct UpdateMintAuthority<'info> {
    #[account(
        mut,
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,

    pub mint: Account<'info, Mint>,
    pub current_authority: Signer<'info>,
}

#[derive(Accounts)]
pub struct GetTokenInfo<'info> {
    #[account(
        seeds = [b"metadata", mint.key().as_ref()],
        bump
    )]
    pub token_metadata: Account<'info, TokenMetadata>,

    pub mint: Account<'info, Mint>,
}

// data structure defines

#[account]
#[derive(InitSpace)]
pub struct TokenMetadata {
    pub authority: Pubkey,
    pub mint: Pubkey,
    #[max_len(32)]
    pub name: String,
    #[max_len(10)]
    pub symbol: String,
    pub decimals: u8,
    pub total_supply: u64,
}

// error defines

#[error_code]
pub enum ErrorCode {
    #[msg("Unauthorized mint authority")]
    UnauthorizedMintAuthority,
    #[msg("Maht overflow")]
    MathOverflow,
    #[msg("Math underflow")]
    MathUnderflow,
}


