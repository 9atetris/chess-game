use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::game_state::GameState;
use array::ArrayTrait;
use option::OptionTrait;

const BOARD_SIZE: u8 = 8;

#[system]
mod move_validation {
    use super::Position;
    use super::Piece;
    use super::GameState;
    use super::BOARD_SIZE;
    use super::ArrayTrait;
    use super::OptionTrait;

    fn is_valid_move(world: World, from: Position, to: Position, piece: Piece, game_state: GameState) -> bool {
        // Check if the move is within the board
        if to.x >= BOARD_SIZE || to.y >= BOARD_SIZE {
            return false;
        }

        // Check if the destination is not occupied by a piece of the same color
        let destination_piece = world.get_component::<Piece>(to.into());
        if destination_piece.piece_type != 0 && destination_piece.color == piece.color {
            return false;
        }

        // Check specific piece movement rules
        match piece.piece_type {
            1 => is_valid_pawn_move(from, to, piece.color, game_state.en_passant),
            2 => is_valid_rook_move(from, to),
            3 => is_valid_knight_move(from, to),
            4 => is_valid_bishop_move(from, to),
            5 => is_valid_queen_move(from, to),
            6 => is_valid_king_move(from, to, game_state.castling_rights),
            _ => false,
        }
    }

    fn is_valid_pawn_move(from: Position, to: Position, color: bool, en_passant: Option<Position>) -> bool {
        let direction = if color { 1 } else { -1 };
        let forward_move = to.y - from.y == direction;
        let double_move = to.y - from.y == 2 * direction && from.y == (if color { 1 } else { 6 });
        let capture_move = (to.y - from.y == direction) && ((to.x - from.x).abs() == 1);

        forward_move || double_move || capture_move || 
            (en_passant == Option::Some(to) && capture_move)
    }

    fn is_valid_rook_move(from: Position, to: Position) -> bool {
        from.x == to.x || from.y == to.y
    }

    fn is_valid_knight_move(from: Position, to: Position) -> bool {
        let dx = (to.x - from.x).abs();
        let dy = (to.y - from.y).abs();
        (dx == 2 && dy == 1) || (dx == 1 && dy == 2)
    }

    fn is_valid_bishop_move(from: Position, to: Position) -> bool {
        (to.x - from.x).abs() == (to.y - from.y).abs()
    }

    fn is_valid_queen_move(from: Position, to: Position) -> bool {
        is_valid_rook_move(from, to) || is_valid_bishop_move(from, to)
    }

    fn is_valid_king_move(from: Position, to: Position, castling_rights: u8) -> bool {
        let dx = (to.x - from.x).abs();
        let dy = (to.y - from.y).abs();
        (dx <= 1 && dy <= 1) || 
            (dx == 2 && dy == 0 && ((from.y == 0 && (castling_rights & 0b0011) != 0) || 
                                    (from.y == 7 && (castling_rights & 0b1100) != 0)))
    }

    fn is_path_clear(world: World, from: Position, to: Position) -> bool {
        let dx = (to.x - from.x).signum();
        let dy = (to.y - from.y).signum();
        let mut x = from.x + dx;
        let mut y = from.y + dy;

        while x != to.x || y != to.y {
            if world.get_component::<Piece>((x, y).into()).piece_type != 0 {
                return false;
            }
            x += dx;
            y += dy;
        }

        true
    }
}