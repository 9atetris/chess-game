mod models {
    mod position;
    mod piece;
    mod player;
    mod game_state;
    mod move_history;
}

use models::position::Position;
use models::piece::Piece;
use models::player::Player;
use models::game_state::GameState;
use models::move_history::MoveHistory;

mod systems {
    mod actions;
    mod init_game;
    mod move_validation;
    mod special_moves;
}

mod chess_game;

use systems::actions;
use systems::init_game;
use systems::move_validation;
use systems::special_moves;

use chess_game::ChessGame;