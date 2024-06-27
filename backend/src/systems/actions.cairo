use array::ArrayTrait;
use option::OptionTrait;
use traits::Into;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use crate::models::position::Position;
use crate::models::piece::{Piece, PieceTrait};
use crate::models::player::Player;
use crate::models::game_state::GameState;
use crate::models::move_history::MoveHistory;

const BOARD_SIZE: u8 = 8;
const PAWN: u8 = 1;
const ROOK: u8 = 2;
const KNIGHT: u8 = 3;
const BISHOP: u8 = 4;
const QUEEN: u8 = 5;
const KING: u8 = 6;

#[derive(Drop, PartialEq)]
enum ChessError {
    NotYourTurn,
    InvalidMove,
    PieceNotFound,
    OutOfBounds,
    GameOver,
    KingInCheck,
    CastlingNotAllowed,
    EnPassantNotAvailable,
    PromotionRequired,
    InvalidPieceType,
}

#[derive(Drop, starknet::Event)]
struct PieceMoved {
    from: Position,
    to: Position,
    piece: Piece
}

#[derive(Drop, starknet::Event)]
struct PieceCaptured {
    position: Position,
    piece: Piece
}

#[derive(Drop, starknet::Event)]
struct CastlingPerformed {
    king_from: Position,
    king_to: Position,
    rook_from: Position,
    rook_to: Position
}

#[derive(Drop, starknet::Event)]
struct PawnPromoted {
    from: Position,
    to: Position,
    new_piece: Piece
}

#[derive(Drop, starknet::Event)]
struct GameEnded {
    winner: Option<bool>,
    reason: felt252
}

#[system]
mod actions {
    use array::ArrayTrait;
    use option::OptionTrait;
    use traits::Into;
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use crate::models::position::Position;
    use crate::models::piece::{Piece, PieceTrait};
    use crate::models::player::Player;
    use crate::models::game_state::GameState;
    use crate::models::move_history::MoveHistory;

    use super::{BOARD_SIZE, PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING};
    use super::{ChessError, PieceMoved, PieceCaptured, CastlingPerformed, PawnPromoted, GameEnded};

    fn execute(world: IWorldDispatcher, from: Position, to: Position) -> Result<(), ChessError> {
        // Get the current game state
        let mut game_state = get!(world, 0, GameState);

        // Check if the game is over
        if game_state.status != 0 {
            return Result::Err(ChessError::GameOver);
        }

        // Check if it's the player's turn
        let player = get!(world, ctx.origin, Player);
        if player.color != game_state.turn {
            return Result::Err(ChessError::NotYourTurn);
        }

        // Get the piece at the 'from' position
        let piece = get!(world, from, Piece);
        if piece.get_type() == 0 {
            return Result::Err(ChessError::PieceNotFound);
        }

        // Check if the move is valid
        is_valid_move(world, from, to, piece, game_state)?;

        // Capture piece if present
        let captured = get!(world, to, Piece);
        if captured.get_type() != 0 {
            emit!(world, PieceCaptured { position: to, piece: captured });
        }
        
        // Move the piece
        set!(world, (from, Piece::new(0, false)));
        set!(world, (to, piece));
        emit!(world, PieceMoved { from, to, piece });

        // Handle special moves (castling, en passant, promotion)
        handle_special_moves(world, from, to, piece, game_state)?;

        // Check if the move leaves the king in check
        if is_king_in_check(world, player.color) {
            // Revert the move
            set!(world, (from, piece));
            set!(world, (to, captured));
            return Result::Err(ChessError::KingInCheck);
        }

        // Update game state
        game_state.turn = !game_state.turn;
        game_state.status = check_game_status(world, !game_state.turn);
        set!(world, (0, game_state));

        // Record move history
        record_move(world, from, to, piece, captured);

        // Check if the game has ended
        if game_state.status != 0 {
            let winner = if game_state.status == 1 { 
                Option::Some(!player.color) 
            } else { 
                Option::None 
            };
            let reason = if game_state.status == 1 { 'checkmate' } else { 'stalemate' };
            emit!(world, GameEnded { winner, reason });
        }

        Result::Ok(())
    }

    fn is_valid_move(world: IWorldDispatcher, from: Position, to: Position, piece: Piece, game_state: GameState) -> Result<(), ChessError> {
        // Check if the move is within the board
        if to.x >= BOARD_SIZE || to.y >= BOARD_SIZE {
            return Result::Err(ChessError::OutOfBounds);
        }
    
        // Check if the destination is not occupied by a piece of the same color
        let destination_piece = get!(world, to, Piece);
        if destination_piece.get_type() != 0 && destination_piece.get_color() == piece.get_color() {
            return Result::Err(ChessError::InvalidMove);
        }
    
        // Check specific piece movement rules
        let valid = match piece.get_type() {
            PAWN => is_valid_pawn_move(from, to, piece.get_color(), game_state.en_passant),
            ROOK => is_valid_rook_move(from, to),
            KNIGHT => is_valid_knight_move(from, to),
            BISHOP => is_valid_bishop_move(from, to),
            QUEEN => is_valid_queen_move(from, to),
            KING => is_valid_king_move(from, to, game_state.castling_rights),
            _ => Err(ChessError::InvalidPieceType), // Return Result::Err directly
        };
    
        // Check the result of the move validation
        let valid = match valid {
            Result::Ok(valid) => {
                if !valid {
                    return Result::Err(ChessError::InvalidMove);
                }
                Result::Ok(())
            },
            Result::Err(e) => Result::Err(e),
        };
    
        valid
    }

    fn is_valid_pawn_move(from: Position, to: Position, color: bool, en_passant: Option<Position>) -> Result<bool, ChessError> {
        let direction = if color { 1 } else { -1 };
        let forward_move = to.y - from.y == direction;
        let double_move = to.y - from.y == 2 * direction && from.y == (if color { 1 } else { 6 });
        let capture_move = (to.y - from.y == direction) && ((to.x - from.x).abs() == 1);

        if forward_move || double_move || capture_move || 
            (en_passant == Option::Some(to) && capture_move) {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn is_valid_rook_move(from: Position, to: Position) -> Result<bool, ChessError> {
        if from.x == to.x || from.y == to.y {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn is_valid_knight_move(from: Position, to: Position) -> Result<bool, ChessError> {
        let dx = (to.x - from.x).abs();
        let dy = (to.y - from.y).abs();
        if (dx == 2 && dy == 1) || (dx == 1 && dy == 2) {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn is_valid_bishop_move(from: Position, to: Position) -> Result<bool, ChessError> {
        if (to.x - from.x).abs() == (to.y - from.y).abs() {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn is_valid_queen_move(from: Position, to: Position) -> Result<bool, ChessError> {
        if is_valid_rook_move(from, to).is_ok() || is_valid_bishop_move(from, to).is_ok() {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn is_valid_king_move(from: Position, to: Position, castling_rights: u8) -> Result<bool, ChessError> {
        let dx = (to.x - from.x).abs();
        let dy = (to.y - from.y).abs();
        if (dx <= 1 && dy <= 1) || 
            (dx == 2 && dy == 0 && ((from.y == 0 && (castling_rights & 0b0011) != 0) || 
                                    (from.y == 7 && (castling_rights & 0b1100) != 0))) {
            Result::Ok(true)
        } else {
            Result::Err(ChessError::InvalidMove)
        }
    }

    fn handle_special_moves(world: IWorldDispatcher, from: Position, to: Position, piece: Piece, mut game_state: GameState) -> Result<(), ChessError> {
        // Handle castling
        if piece.get_type() == KING && (to.x - from.x).abs() == 2 {
            if !can_castle(world, from, to, piece.get_color(), game_state.castling_rights)? {
                return Result::Err(ChessError::CastlingNotAllowed);
            }
            let rook_from = Position { x: if to.x > from.x { 7 } else { 0 }, y: from.y };
            let rook_to = Position { x: (from.x + to.x) / 2, y: from.y };
            let rook = get!(world, rook_from, Piece);
            set!(world, (rook_from, Piece::new(0, false)));
            set!(world, (rook_to, rook));
            emit!(world, CastlingPerformed { king_from: from, king_to: to, rook_from, rook_to });
        }
    
        // Handle en passant
        if piece.get_type() == PAWN && game_state.en_passant == Option::Some(to) {
            let captured_pawn = Position { x: to.x, y: from.y };
            let captured = get!(world, captured_pawn, Piece);
            set!(world, (captured_pawn, Piece::new(0, false)));
            emit!(world, PieceCaptured { position: captured_pawn, piece: captured });
        }
    
        // Set en passant for next move
        game_state.en_passant = if piece.get_type() == PAWN && (to.y - from.y).abs() == 2 {
            Option::Some(Position { x: from.x, y: (from.y + to.y) / 2 })
        } else {
            Option::None
        };
    
        // Handle pawn promotion (simplified: always promote to queen)
        if piece.get_type() == PAWN && (to.y == 0 || to.y == 7) {
            let promoted_piece = Piece::new(QUEEN, piece.get_color());
            set!(world, (to, promoted_piece));
            emit!(world, PawnPromoted { from, to, new_piece: promoted_piece });
        }
    
        // Update castling rights
        if piece.get_type() == KING {
            let rights = if piece.get_color() { 0b1100 } else { 0b0011 };
            game_state.castling_rights = game_state.castling_rights & rights;
        } else if piece.get_type() == ROOK {
            if from.y == 0 {
                let rights = if from.x == 0 { 0b1110 } else { 0b1101 };
                game_state.castling_rights = game_state.castling_rights & rights;
            } else if from.y == 7 {
                let rights = if from.x == 0 { 0b1011 } else { 0b0111 };
                game_state.castling_rights = game_state.castling_rights & rights;
            }
        }
    
        set!(world, (0, game_state));
        Result::Ok(())
    }
    
    

    fn can_castle(world: IWorldDispatcher, from: Position, to: Position, color: bool, castling_rights: u8) -> Result<bool, ChessError> {
        let king_side = to.x > from.x;
        let rank = if color { 0 } else { 7 };
        let rights = if color { 0b0011 } else { 0b1100 };
        
        if (castling_rights & rights) == 0 {
            return Result::Err(ChessError::CastlingNotAllowed);
        }

        let rook_x = if king_side { 7 } else { 0 };
        let rook = get!(world, (rook_x, rank), Piece);
        if rook.get_type() != ROOK || rook.get_color() != color {
            return Result::Err(ChessError::CastlingNotAllowed);
        }

        let direction = if king_side { 1 } else { -1 };
        let mut x = from.x + direction;
        while x != rook_x {
            if get!(world, (x, rank), Piece).get_type() != 0 {
                return Result::Err(ChessError::CastlingNotAllowed);
            }
            x += direction;
        }

        Result::Ok(true)
    }

    fn check_game_status(world: IWorldDispatcher, color: bool) -> u8 {
        let mut has_legal_moves = false;
        let mut is_in_check = is_king_in_check(world, color);
    
        // Iterate through all pieces of the current player
        for x in range(0, BOARD_SIZE) {
            for y in range(0, BOARD_SIZE) {
                let piece = get!(world, (x, y), Piece);
                if piece.get_type() != 0 && piece.get_color() == color {
                    // Check if this piece has any legal moves
                    if has_legal_move(world, Position { x, y }, piece) {
                        has_legal_moves = true;
                        break;
                    }
                }
            }
            if has_legal_moves {
                break;
            }
        }
    
        if is_in_check && !has_legal_moves {
            return 1; // Checkmate
        } else if !is_in_check && !has_legal_moves {
            return 2; // Stalemate
        } else {
            return 0; // Game is ongoing
        }
    }    
    
    

    fn is_king_in_check(world: IWorldDispatcher, color: bool) -> bool {
        // Find the king's position
        let mut king_pos = Option::None;
        for x in range(0, BOARD_SIZE) {
            for y in range(0, BOARD_SIZE) {
                let piece = get!(world, (x, y), Piece);
                if piece.get_type() == KING && piece.get_color() == color {
                    king_pos = Option::Some(Position { x, y });
                    break;
                }
            }
            if king_pos.is_some() {
                break;
            }
        }
    
        let king_pos = king_pos.unwrap();
    
        // Check if any opponent's piece can capture the king
        for x in range(0, BOARD_SIZE) {
            for y in range(0, BOARD_SIZE) {
                let piece = get!(world, (x, y), Piece);
                if piece.get_type() != 0 && piece.get_color() != color {
                    if is_valid_move(world, Position { x, y }, king_pos, piece, GameState::default()).is_ok() {
                        return true;
                    }
                }
            }
        }
    
        false
    }    

    fn has_legal_move(world: IWorldDispatcher, from: Position, piece: Piece) -> bool {
        for x in range(0, BOARD_SIZE) {
            for y in range(0, BOARD_SIZE) {
                let to = Position { x, y };
                if is_valid_move(world, from, to, piece, GameState::default()).is_ok() {
                    // Check if this move would leave the king in check
                    let mut test_world = world.clone();
                    set!(test_world, (from, Piece::new(0, false)));
                    set!(test_world, (to, piece));
                    if !is_king_in_check(test_world, piece.get_color()) {
                        return true;
                    }
                }
            }
        }
        false
    }
    

    fn record_move(world: IWorldDispatcher, from: Position, to: Position, piece: Piece, captured: Piece) {
        let move_history = MoveHistory { from, to, piece, captured: Option::Some(captured) };
        
        // Get the current move count
        let moves_count = get!(world, 'moves_count');
    
        // Store the move history in an array
        let mut moves_array = get!(world, 'moves_array');
        moves_array.push(move_history);
    
        // Update the world state
        set!(world, ('moves_array', moves_array), ('moves_count', moves_count + 1));
    }
    
}