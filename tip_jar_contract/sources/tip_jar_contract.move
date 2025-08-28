/// Module: gratuity_box
/// A simple gratuity box that forwards SUI immediately to the owner
/// and keeps lightweight statistics on-chain.
module tip_jar_contract::gratuity_box;

use sui::coin::{Self, Coin};
use sui::event;
use sui::sui::SUI;
use sui::object::{Self, UID, ID};
use sui::transfer;
use sui::tx_context::{Self, TxContext};

/// Error codes
const EInvalidGratuityAmount: u64 = 1;
const EUnauthorized: u64 = 2;

/// Aggregated snapshot for easy reads
public struct VaultSnapshot has copy, drop {
    owner: address,
    total_gratuities: u64,
    gratuity_count: u64,
    last_tipper: address,
}

/// The main shared object; funds aren't stored here — they go to the owner
public struct GratuityVault has key {
    id: UID,
    owner: address,
    total_gratuities: u64,
    gratuity_count: u64,
    last_tipper: address,
}

/// Event emitted when a gratuity is deposited
public struct GratuityDeposited has copy, drop {
    tipper: address,
    amount: u64,
    total_gratuities: u64,
    gratuity_count: u64,
}

/// Event emitted when a vault is created
public struct VaultCreated has copy, drop {
    vault_id: ID,
    owner: address,
}

/// Bootstrap the gratuity vault (creates and shares a new GratuityVault)
#[allow(unused_function)]
fun bootstrap(ctx: &mut TxContext) {
    let owner = ctx.sender();
    let vault = GratuityVault {
        id: object::new(ctx),
        owner,
        total_gratuities: 0,
        gratuity_count: 0,
        last_tipper: @0x0,
    };

    let vault_id = object::id(&vault);
    event::emit(VaultCreated { vault_id, owner });
    transfer::share_object(vault);
}

/// Deposit a gratuity; forwards SUI directly to the owner and updates stats
public fun deposit_gratuity(vault: &mut GratuityVault, payment: Coin<SUI>, ctx: &mut TxContext) {
    let amount = coin::value(&payment);
    assert!(amount > 0, EInvalidGratuityAmount);

    // forward funds
    transfer::public_transfer(payment, vault.owner);

    // update stats
    vault.total_gratuities = vault.total_gratuities + amount;
    vault.gratuity_count = vault.gratuity_count + 1;
    vault.last_tipper = ctx.sender();

    event::emit(GratuityDeposited {
        tipper: vault.last_tipper,
        amount,
        total_gratuities: vault.total_gratuities,
        gratuity_count: vault.gratuity_count,
    });
}

/// Admin utility: reset counters (owner-only)
public fun reset_counts(vault: &mut GratuityVault, ctx: &TxContext) {
    assert!(ctx.sender() == vault.owner, EUnauthorized);
    vault.total_gratuities = 0;
    vault.gratuity_count = 0;
    vault.last_tipper = @0x0;
}

/// Read helpers
public fun total_gratuities(vault: &GratuityVault): u64 { vault.total_gratuities }
public fun gratuities_count(vault: &GratuityVault): u64 { vault.gratuity_count }
public fun vault_owner(vault: &GratuityVault): address { vault.owner }
public fun last_tipper(vault: &GratuityVault): address { vault.last_tipper }
public fun is_vault_owner(vault: &GratuityVault, addr: address): bool { vault.owner == addr }

/// Convenience snapshot for frontends
public fun stats_snapshot(vault: &GratuityVault): VaultSnapshot {
    VaultSnapshot {
        owner: vault.owner,
        total_gratuities: vault.total_gratuities,
        gratuity_count: vault.gratuity_count,
        last_tipper: vault.last_tipper,
    }
}

#[test_only]
/// Test-only function to initialize vault for tests
public fun bootstrap_for_tests(ctx: &mut TxContext) { bootstrap(ctx); }
