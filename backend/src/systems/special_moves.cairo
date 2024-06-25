use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::game_state::GameState;

#[system]
mod special_moves {
    fn handle_special_moves(world: World, from: Position, to: Position, piece: Piece, game_state: GameState) {
        // キャスリング、アンパッサン、プロモーションの処理
    }
}