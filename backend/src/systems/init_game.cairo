use array::ArrayTrait;
use traits::Into;
use dojo::world::Context;
use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::player::Player;
use chess_game::models::game_state::GameState;

#[system]
mod init_game {
    fn execute(ctx: Context, player1: ContractAddress, player2: ContractAddress) {
        let world = ctx.world();

        // Initialize players
        world.set_component(player1.into(), Player { address: player1, color: true });  // White
        world.set_component(player2.into(), Player { address: player2, color: false }); // Black

        // Initialize game state
        world.set_component(0, GameState { 
            turn: true,  // White starts
            status: 0,   // 0 = ongoing
            en_passant: Option::None,
            castling_rights: 0b1111  // Both sides can castle both ways initially
        });

        // Initialize the board
        init_board(world);
    }

    fn init_board(world: World) {
        // Initialize pawns
        let mut i = 0;
        loop {
            if i == 8 { break; }
            world.set_component((i, 1).into(), Piece { piece_type: 1, color: true });  // White pawns
            world.set_component((i, 6).into(), Piece { piece_type: 1, color: false }); // Black pawns
            i += 1;
        }

        // Initialize other pieces
        let pieces = array![2, 3, 4, 5, 6, 4, 3, 2];  // Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook
        let mut j = 0;
        loop {
            if j == 8 { break; }
            world.set_component((j, 0).into(), Piece { piece_type: *pieces[j], color: true });  // White pieces
            world.set_component((j, 7).into(), Piece { piece_type: *pieces[j], color: false }); // Black pieces
            j += 1;
        }
    }
}