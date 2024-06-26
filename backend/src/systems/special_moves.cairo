use chess_game::models::position::Position;
use chess_game::models::piece::Piece;
use chess_game::models::game_state::GameState;
use array::ArrayTrait;
use option::OptionTrait;

#[system]
mod special_moves {
    use super::Position;
    use super::Piece;
    use super::GameState;
    use super::ArrayTrait;
    use super::OptionTrait;

    fn handle_special_moves(world: World, from: Position, to: Position, piece: Piece, mut game_state: GameState) {
        // Handle castling
        if is_castling(piece, from, to) {
            handle_castling(world, from, to);
        }

        // Handle en passant
        if is_en_passant(piece, from, to, game_state.en_passant) {
            handle_en_passant(world, from, to);
        }

        // Handle pawn promotion
        if is_promotion(piece, to) {
            handle_promotion(world, to, piece.color);
        }

        // Update en passant state
        update_en_passant_state(from, to, piece, game_state);

        // Update castling rights
        update_castling_rights(from, piece, game_state);

        // Update the game state in the world
        world.set_component(0, game_state);
    }

    fn is_castling(piece: Piece, from: Position, to: Position) -> bool {
        piece.piece_type == 6 && (to.x as i8 - from.x as i8).abs() == 2
    }

    fn handle_castling(world: World, from: Position, to: Position) {
        let rook_from = Position { x: if to.x > from.x { 7 } else { 0 }, y: from.y };
        let rook_to = Position { x: (from.x + to.x) / 2, y: from.y };
        let rook = world.get_component::<Piece>(rook_from.into());
        world.set_component(rook_from.into(), Piece { piece_type: 0, color: false });
        world.set_component(rook_to.into(), rook);
    }

    fn is_en_passant(piece: Piece, from: Position, to: Position, en_passant: Option<Position>) -> bool {
        piece.piece_type == 1 && en_passant == Option::Some(to) && from.x != to.x
    }

    fn handle_en_passant(world: World, from: Position, to: Position) {
        let captured_pawn = Position { x: to.x, y: from.y };
        world.set_component(captured_pawn.into(), Piece { piece_type: 0, color: false });
    }

    fn is_promotion(piece: Piece, to: Position) -> bool {
        piece.piece_type == 1 && (to.y == 0 || to.y == 7)
    }

    fn handle_promotion(world: World, to: Position, color: bool) {
        // Automatically promote to queen for simplicity
        world.set_component(to.into(), Piece { piece_type: 5, color: color });
    }

    fn update_en_passant_state(from: Position, to: Position, piece: Piece, mut game_state: GameState) {
        game_state.en_passant = if piece.piece_type == 1 && (to.y as i8 - from.y as i8).abs() == 2 {
            Option::Some(Position { x: from.x, y: (from.y + to.y) / 2 })
        } else {
            Option::None
        };
    }

    fn update_castling_rights(from: Position, piece: Piece, mut game_state: GameState) {
        if piece.piece_type == 6 {
            game_state.castling_rights &= if piece.color { 0b1100 } else { 0b0011 };
        } else if piece.piece_type == 2 {
            if from.y == 0 {
                game_state.castling_rights &= if from.x == 0 { 0b1110 } else { 0b1101 };
            } else if from.y == 7 {
                game_state.castling_rights &= if from.x == 0 { 0b1011 } else { 0b0111 };
            }
        }
    }
}