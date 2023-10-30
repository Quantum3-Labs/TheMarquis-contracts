use starknet::ContractAddress;
use l2::models::{Choice};

// define the interface
#[starknet::interface]
trait IActions<TContractState> {
    fn spawn(self: @TContractState, player_address: ContractAddress) -> u32;
    fn move(self: @TContractState, game_id: u32, choice: Choice, amount: u8);
    fn set_winner(self: @TContractState, game_id: u32, vrf: u8);
}

// dojo decorator
#[dojo::contract]
mod actions {
    use starknet::{ContractAddress, get_caller_address};
    use l2::models::{Game, GameTurn,Choice};
    use l2::utils::{betting, seed, random};
    use super::IActions;

    // declaring custom event struct
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Moved: Moved,
    }

    // declaring custom event struct
    #[derive(Drop, starknet::Event)]
    struct Moved {
        game_id: u32,
        player: ContractAddress,
        amount: u8
    }

    // impl: implement functions specified in trait
    #[external(v0)]
    impl ActionsImpl of IActions<ContractState> {
        // ContractState is defined by system decorator expansion
        fn spawn(self: @ContractState, player_address: ContractAddress) -> u32{
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();
            let game_id = world.uuid();
            // house address = 0x00
            let winner = starknet::contract_address_const::<0x00>();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            set!(
                world,
                (
                    Game {
                        game_id, winner, player: player_address
                    },
                    GameTurn {
                        game_id, player: player_address, choice: Choice::None(()), amount: 0
                    }
                )
            );
            game_id
        }

        // Implementation of the move function for the ContractState struct.
        fn move(self: @ContractState, game_id: u32, choice: Choice, amount: u8) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();

            // Retrieve current game and game_turn data from the world.
            let (game, mut game_turn) = get!(world, game_id, (Game, GameTurn));

            // player's move.
            //let game_turn = betting(game_turn, choice, amount);
             game_turn.choice = choice;
             game_turn.amount = amount;

            // Update the world state with the new moves data and position.
            set!(world, (game, game_turn));

            // Emit an event to the world to notify about the player's move.
            emit!(world, Moved { game_id, player, amount });
        }

        fn set_winner(self: @ContractState, game_id: u32, vrf: u8) {
            // Access the world dispatcher for reading.
            let world = self.world_dispatcher.read();

            // Retrieve current game and game_turn data from the world.
            let (mut game, game_turn) = get!(world, game_id, (Game, GameTurn));

            let vrf: felt252 = vrf.into();

            if vrf == game_turn.choice.into() {
                game.winner = game_turn.player;
                // Update the world state with the new moves data and position.
                set!(world, (game, game_turn));
            }
        }
    }
}

#[cfg(test)]
mod tests {
        use debug::PrintTrait;

    use starknet::{class_hash::Felt252TryIntoClassHash,contract_address_const};

    // import world dispatcher
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

    // import test utils
    use dojo::test_utils::{spawn_test_world, deploy_contract};

    // import models
    use l2::models::{game, game_turn};
    use l2::models::{Game, GameTurn, Choice};

    // import actions
    use super::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    use l2::utils::{seed, random};


    // reusable function for tests
    fn setup_world() -> (IWorldDispatcher, IActionsDispatcher) {
        // models
        let mut models = array![game::TEST_CLASS_HASH, game_turn::TEST_CLASS_HASH];
        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        (world, actions_system)
    }
    #[test]
    #[available_gas(30000000)]
    fn test_spawn() {
        // caller
        let caller = contract_address_const::<0x1>();
        let (world, actions_system) = setup_world();

        // call spawn()
        let game_id = actions_system.spawn(caller);
        let game = get!(world, game_id, (Game));
        assert(game.winner == contract_address_const::<0x0>(), 'winner is wrong');
        assert(game.player == contract_address_const::<0x1>(), 'player is wrong');

        let game_turn = get!(world, game_id, (GameTurn));
        assert(game_turn.game_id == game_id, 'game_id is wrong');
        assert(game_turn.player == game.player, 'player is wrong');
        assert(game_turn.choice == Choice::None(()), 'choice is wrong');
        assert(game_turn.amount == 0, 'amount is wrong');
    }
    #[test]
    #[available_gas(30000000)]
    fn test_move() {
        // caller
        let caller = starknet::contract_address_const::<0x1>();

        let (world, actions_system) = setup_world();

        // call spawn()
        let game_id = actions_system.spawn(caller);
        let amount = 10;
        let choice = Choice::OneRed(());
        actions_system.move(game_id, choice, amount);

        // call move with OneRed choice
        let game_turn = get!(world, game_id, (GameTurn));

        // casting OneRed choice
        let one_red_felt: felt252 = choice.into();

        // check moves
        assert(game_turn.amount == amount, 'amount is wrong');

        // check choice
        assert(game_turn.choice.into() == one_red_felt, 'choice is wrong');
     }

     #[test]
    #[available_gas(30000000)]
    fn test_fixed_winner() {
        // caller
        let caller = starknet::contract_address_const::<0x1>();

        let (world, actions_system) = setup_world();

        // call spawn()
        let game_id = actions_system.spawn(caller);
        let amount = 20;
        let choice = Choice::TwoBlack(());
        actions_system.move(game_id, choice, amount);

        let fixed_number_winner = 2;

        actions_system.set_winner(game_id, fixed_number_winner);

        let game = get!(world, game_id, (Game));
        assert(game.winner == starknet::contract_address_const::<0x1>(), 'winner is not player');

        
    }

     #[test]
    #[available_gas(30000000)]
    fn test_random() {
        // caller
        let caller = starknet::contract_address_const::<0x1>();

        let (world, actions_system) = setup_world();

        // call spawn()
        let game_id = actions_system.spawn(caller);
        let amount = 30;
        let choice = Choice::ThreeRed(()); 
        actions_system.move(game_id, choice, amount);
        
        // dummy vrf, FIXME
        let vrf = random(pedersen::pedersen(seed(), choice.into()), 6);
        vrf.print(); // Beacuse of seed(), this vrf value is 3, thats is mapped into Choice::ThreeRed(())

        actions_system.set_winner(game_id, vrf);

        let (game, game_turn) = get!(world, game_id, (Game, GameTurn));
        assert(game_turn.choice != Choice::None(()), 'Choice still empty');
        game.winner.print();  // Because of seed (), player wins

        
    }
}
