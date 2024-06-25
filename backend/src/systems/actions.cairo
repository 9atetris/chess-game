use array::ArrayTrait;
use option::OptionTrait;
use traits::Into;
use dojo::world::Context;
use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::player::Player;
use chess_game::models::game_state::GameState;
use chess_game::models::move_history::MoveHistory;

#[system]
mod actions {
    fn execute(ctx: Context, from: Position, to: Position) -> bool {
        // ここに先ほどの chess_system の execute 関数の内容を配置
    }

    fn check_game_status(world: World, color: bool) -> u8 {
        // チェックメイトやステイルメイトの検出ロジック
    }

    fn record_move(world: World, from: Position, to: Position, piece: Piece, captured: Option<Piece>) {
        // 移動履歴の記録ロジック
    }
}