use starknet::ContractAddress;
use array::ArrayTrait;
use option::OptionTrait;
use crate::models::{Position, Piece, Player, GameState, MoveHistory};
use crate::systems::actions;

#[contract]
mod ChessGame {
    use super::Position;
    use super::Piece;
    use super::Player;
    use super::GameState;
    use super::ContractAddress;
    use super::ArrayTrait;
    use super::OptionTrait;

    #[external]
    fn init_game(player1: ContractAddress, player2: ContractAddress) {
        init_board();
        world::set_component(player1.into(), Player { address: player1, color: true });
        world::set_component(player2.into(), Player { address: player2, color: false });
        world::set_component(0, GameState { 
            turn: true, 
            status: 0, 
            en_passant: Option::None, 
            castling_rights: 0b1111 // Both sides can castle both ways initially
        });
    }

    #[external]
    fn move(from: Position, to: Position) -> bool {
        actions::execute(from, to)
    }

    fn init_board() {
        let pieces = array![2, 3, 4, 5, 6, 4, 3, 2];
        let mut i = 0;
        loop {
            if i == 8 {
                break;
            }
            world::set_component((i, 0).into(), Piece { piece_type: *pieces[i], color: true });
            world::set_component((i, 1).into(), Piece { piece_type: 1, color: true });
            world::set_component((i, 6).into(), Piece { piece_type: 1, color: false });
            world::set_component((i, 7).into(), Piece { piece_type: *pieces[i], color: false });
            i += 1;
        }
    }

    #[view]
    fn get_piece(position: Position) -> Piece {
        world::get_component(position.into())
    }

    #[view]
    fn get_game_state() -> GameState {
        world::get_component(0)
    }
}