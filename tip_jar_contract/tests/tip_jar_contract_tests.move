#[test_only]
module tip_jar_contract::gratuity_box_tests {
    use sui::test_scenario::{Self};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use tip_jar_contract::gratuity_box::{Self, GratuityVault};

    const OWNER: address = @0xA11CE;
    const TIPPER_1: address = @0xB0B;
    const TIPPER_2: address = @0xCAFE;

    // Helper function to create test coins
    fun create_test_coin(amount: u64, ctx: &mut TxContext): Coin<SUI> {
        coin::mint_for_testing<SUI>(amount, ctx)
    }

    #[test]
    fun test_bootstrap_creates_vault() {
        let mut scenario = test_scenario::begin(OWNER);
        let ctx = test_scenario::ctx(&mut scenario);

        // Initialize the vault
        gratuity_box::bootstrap_for_tests(ctx);
        
        // Check that TipJarCreated event was emitted
        test_scenario::next_tx(&mut scenario, OWNER);
        
        // Verify the vault was created and shared
        let vault = test_scenario::take_shared<GratuityVault>(&scenario);
        
        // Verify initial state
        assert!(gratuity_box::vault_owner(&vault) == OWNER, 0);
        assert!(gratuity_box::total_gratuities(&vault) == 0, 1);
        assert!(gratuity_box::gratuities_count(&vault) == 0, 2);
        assert!(gratuity_box::is_vault_owner(&vault, OWNER) == true, 3);
        assert!(gratuity_box::is_vault_owner(&vault, TIPPER_1) == false, 4);
        
        test_scenario::return_shared(vault);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_deposit_gratuity_basic() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Tipper sends a gratuity
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let tip_coin = create_test_coin(1_000_000_000, ctx); // 1 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, tip_coin, ctx);
            
            // Verify tip jar state updated
            assert!(gratuity_box::total_gratuities(&vault) == 1_000_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 1, 1);
            
            test_scenario::return_shared(vault);
        };
        
        // Verify owner received the coin
        test_scenario::next_tx(&mut scenario, OWNER);
        {
            let received_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&received_coin) == 1_000_000_000, 2);
            test_scenario::return_to_sender(&scenario, received_coin);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_gratuities() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // First tipper sends 0.5 SUI
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let tip_coin = create_test_coin(500_000_000, ctx); // 0.5 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, tip_coin, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 500_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 1, 1);
            
            test_scenario::return_shared(vault);
        };
        
        // Second tipper sends 1.5 SUI
        test_scenario::next_tx(&mut scenario, TIPPER_2);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let tip_coin = create_test_coin(1_500_000_000, ctx); // 1.5 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, tip_coin, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 2_000_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 2, 1);
            
            test_scenario::return_shared(vault);
        };
        
        // Verify owner received both coins (order might vary)
        test_scenario::next_tx(&mut scenario, OWNER);
        {
            // Take all coins and verify total
            let coin1 = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            let coin2 = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            
            let value1 = coin::value(&coin1);
            let value2 = coin::value(&coin2);
            let total_received = value1 + value2;
            
            // Should have received both tips totaling 2 SUI
            assert!(total_received == 2_000_000_000, 2);
            // Should have received coins of the right individual amounts
            assert!((value1 == 500_000_000 && value2 == 1_500_000_000) || 
                   (value1 == 1_500_000_000 && value2 == 500_000_000), 3);
            
            test_scenario::return_to_sender(&scenario, coin1);
            test_scenario::return_to_sender(&scenario, coin2);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_same_tipper_multiple_times() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Same tipper sends multiple tips
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            
            // First tip: 0.1 SUI
            let tip_coin1 = create_test_coin(100_000_000, ctx);
            gratuity_box::deposit_gratuity(&mut vault, tip_coin1, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 100_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 1, 1);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            
            // Second tip: 0.2 SUI
            let tip_coin2 = create_test_coin(200_000_000, ctx);
            gratuity_box::deposit_gratuity(&mut vault, tip_coin2, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 300_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 2, 1);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_zero_gratuity_fails() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Try to send zero tip (should fail)
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let zero_coin = create_test_coin(0, ctx); // 0 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, zero_coin, ctx); // Should abort
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_events_emitted() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Send a tip
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let tip_coin = create_test_coin(500_000_000, ctx); // 0.5 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, tip_coin, ctx);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_getter_functions_and_snapshot() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        test_scenario::next_tx(&mut scenario, OWNER);
        {
            let vault = test_scenario::take_shared<GratuityVault>(&scenario);
            
            // Test all getter functions
            assert!(gratuity_box::vault_owner(&vault) == OWNER, 0);
            assert!(gratuity_box::total_gratuities(&vault) == 0, 1);
            assert!(gratuity_box::gratuities_count(&vault) == 0, 2);
            assert!(gratuity_box::is_vault_owner(&vault, OWNER) == true, 3);
            assert!(gratuity_box::is_vault_owner(&vault, TIPPER_1) == false, 4);
            let snap = gratuity_box::stats_snapshot(&vault);
            assert!(snap.owner == OWNER, 5);
            assert!(snap.total_gratuities == 0, 6);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_large_gratuity_amounts() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Send a large tip (1000 SUI)
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let large_tip = create_test_coin(1000_000_000_000, ctx); // 1000 SUI
            
            gratuity_box::deposit_gratuity(&mut vault, large_tip, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 1000_000_000_000, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 1, 1);
            
            test_scenario::return_shared(vault);
        };
        
        // Verify owner received the large tip
        test_scenario::next_tx(&mut scenario, OWNER);
        {
            let received_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&received_coin) == 1000_000_000_000, 2);
            test_scenario::return_to_sender(&scenario, received_coin);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    fun test_minimal_gratuity_amount() {
        let mut scenario = test_scenario::begin(OWNER);
        
        // Initialize the vault
        {
            let ctx = test_scenario::ctx(&mut scenario);
            gratuity_box::bootstrap_for_tests(ctx);
        };
        
        // Send minimal tip (1 MIST)
        test_scenario::next_tx(&mut scenario, TIPPER_1);
        {
            let mut vault = test_scenario::take_shared<GratuityVault>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let minimal_tip = create_test_coin(1, ctx); // 1 MIST
            
            gratuity_box::deposit_gratuity(&mut vault, minimal_tip, ctx);
            
            assert!(gratuity_box::total_gratuities(&vault) == 1, 0);
            assert!(gratuity_box::gratuities_count(&vault) == 1, 1);
            
            test_scenario::return_shared(vault);
        };
        
        test_scenario::end(scenario);
    }
}
