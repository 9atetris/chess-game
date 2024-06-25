use array::ArrayTrait;
use option::OptionTrait;
use traits::Into;
use dojo::world::Context;
use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::player::Player;
use chess_game::models::game_state::GameState;
use chess_game::models::move_history::MoveHistory;

const BOARD_SIZE: u8 = 8;

#[system]
mod actions {
    use super::Position;
    use super::Piece;
    use super::Player;
    use super::GameState;
    use super::MoveHistory;
    use super::Context;
    use super::OptionTrait;
    use super::BOARD_SIZE;

    fn execute(ctx: Context, from: Position, to: Position) -> bool {
        let world = ctx.world();
        
        // Get the current game state
        let mut game_state = world.get_component::<GameState>(0);

        // Check if it's the player's turn
        let player = world.get_component::<Player>(ctx.origin.into());
        assert(player.color == game_state.turn, 'Not your turn');

        // Get the piece at the 'from' position
        let piece = world.get_component::<Piece>(from.into());
        
        // Check if the move is valid
        if is_valid_move(world, from, to, piece, game_state) {
            // Capture piece if present
            let captured = world.get_component::<Piece>(to.into());
            
            // Move the piece
            world.set_component(from.into(), Piece { piece_type: 0, color: false });
            world.set_component(to.into(), piece);

            // Handle special moves (castling, en passant, promotion)
            handle_special_moves(world, from, to, piece, game_state);

            // Update game state
            game_state.turn = !game_state.turn;
            game_state.status = check_game_status(world, !game_state.turn);
            world.set_component(0, game_state);

            // Record move history
            record_move(world, from, to, piece, captured);

            true
        } else {
            false
        }
    }

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

    fn handle_special_moves(world: World, from: Position, to: Position, piece: Piece, mut game_state: GameState) {
        // Handle castling
        if piece.piece_type == 6 && (to.x - from.x).abs() == 2 {
            let rook_from = Position { x: if to.x > from.x { 7 } else { 0 }, y: from.y };
            let rook_to = Position { x: (from.x + to.x) / 2, y: from.y };
            let rook = world.get_component::<Piece>(rook_from.into());
            world.set_component(rook_from.into(), Piece { piece_type: 0, color: false });
            world.set_component(rook_to.into(), rook);
        }

        // Handle en passant
        if piece.piece_type == 1 && game_state.en_passant == Option::Some(to) {
            let captured_pawn = Position { x: to.x, y: from.y };
            world.set_component(captured_pawn.into(), Piece { piece_type: 0, color: false });
        }

        // Set en passant for next move
        game_state.en_passant = if piece.piece_type == 1 && (to.y - from.y).abs() == 2 {
            Option::Some(Position { x: from.x, y: (from.y + to.y) / 2 })
        } else {
            Option::None
        };

        // Handle pawn promotion (simplified: always promote to queen)
        if piece.piece_type == 1 && (to.y == 0 || to.y == 7) {
            world.set_component(to.into(), Piece { piece_type: 5, color: piece.color });
        }

        // Update castling rights
        if piece.piece_type == 6 {
            game_state.castling_rights &= if piece.color { 0b1100 } else { 0b0011 };
        } else if piece.piece_type == 2 {
            if from.y == 0 {
                game_state.castling_rights &= if from.x == 0 { 0b1110 } else { 0b1101 };
            } else if from.y == 7 {
                game_state.castling_rights &= if from.x == 0 { 0b1011 } else { 0b0111 };
            }
        }

        world.set_component(0, game_state);
    }

    fn check_game_status(world: World, color: bool) -> u8 {
        let mut has_legal_moves = false;
        let mut is_in_check = is_king_in_check(world, color);

        // Iterate through all pieces of the current player
        for x in 0..BOARD_SIZE {
            for y in 0..BOARD_SIZE {
                let piece = world.get_component::<Piece>((x, y).into());
                if piece.piece_type != 0 && piece.color == color {
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
            1 // Checkmate
        } else if !is_in_check && !has_legal_moves {
            2 // Stalemate
        } else {
            0 // Game is ongoing
        }
    }

    fn is_king_in_check(world: World, color: bool) -> bool {
        // Find the king's position
        let mut king_pos = Option::None;
        for x in 0..BOARD_SIZE {
            for y in 0..BOARD_SIZE {
                let piece = world.get_component::<Piece>((x, y).into());
                if piece.piece_type == 6 && piece.color == color {
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
        for x in 0..BOARD_SIZE {
            for y in 0..BOARD_SIZE {
                let piece = world.get_component::<Piece>((x, y).into());
                if piece.piece_type != 0 && piece.color != color {
                    if is_valid_move(world, Position { x, y }, king_pos, piece, GameState::default()) {
                        return true;
                    }
                }
            }
        }

        false
    }

    fn has_legal_move(world: World, from: Position, piece: Piece) -> bool {
        for x in 0..BOARD_SIZE {
            for y in 0..BOARD_SIZE {
                let to = Position { x, y };
                if is_valid_move(world, from, to, piece, GameState::default()) {
                    // Check if this move would leave the king in check
                    let mut test_world = world.clone();
                    test_world.set_component(from.into(), Piece { piece_type: 0, color: false });
                    test_world.set_component(to.into(), piece);
                    if !is_king_in_check(test_world, piece.color) {
                        return true;
                    }
                }
            }
        }
        false
    }

    fn record_move(world: World, from: Position, to: Position, piece: Piece, captured: Option<Piece>) {
        let move_history = MoveHistory { from, to, piece, captured };
        
        // Get the current move count
        let moves_count = world.get_component::<u32>(0, 'moves_count');

        // Store the move history in an array
        let mut moves_array = world.get_component::<Array<MoveHistory>>(0, 'moves_array');
        moves_array.push(move_history);

        // Update the world state
        world.set_component(0, 'moves_array', moves_array);
        world.set_component(0, 'moves_count', moves_count + 1);
    }
}