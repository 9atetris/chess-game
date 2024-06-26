use array::ArrayTrait;
use core::result::Result;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use chess_game::models::position::Position;
use chess_game::models::piece::{Piece, PieceTrait};
use chess_game::models::player::Player;
use chess_game::models::game_state::GameState;
use chess_game::systems::actions;
use chess_game::systems::init_game;
use chess_game::constants::{PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING, WHITE, BLACK};

// ヘルパー関数
fn setup_world() -> IWorldDispatcher {
    // TODO: 実際のDojo world設定に合わせて実装する
    let world = IWorldDispatcher { ... };
    world
}

fn init_game_board(world: IWorldDispatcher) {
    let player1 = starknet::contract_address_const::<0x1>();
    let player2 = starknet::contract_address_const::<0x2>();
    init_game::execute(world, player1, player2);
}

fn assert_move_valid(world: IWorldDispatcher, from: Position, to: Position) {
    let result = actions::execute(world, from, to);
    assert(result.is_ok(), 'Move should be valid');
}

fn assert_move_invalid(world: IWorldDispatcher, from: Position, to: Position) {
    let result = actions::execute(world, from, to);
    assert(result.is_err(), 'Move should be invalid');
}

fn clear_path(world: IWorldDispatcher, positions: Array<Position>) {
    let mut i = 0;
    loop {
        if i == positions.len() {
            break;
        }
        let pos = *positions[i];
        set!(world, (pos, Piece::new(0, false)));
        i += 1;
    }
}

#[test]
fn test_castling_kingside_white() {
    let world = setup_world();
    init_game_board(world);

    // Clear path for castling
    clear_path(world, array![Position { x: 5, y: 0 }, Position { x: 6, y: 0 }]);

    // Perform castling
    assert_move_valid(world, Position { x: 4, y: 0 }, Position { x: 6, y: 0 });

    // Verify king and rook positions after castling
    let king = get!(world, Position { x: 6, y: 0 }, Piece);
    let rook = get!(world, Position { x: 5, y: 0 }, Piece);
    assert(king.get_type() == KING && king.get_color() == WHITE, 'King not in correct position');
    assert(rook.get_type() == ROOK && rook.get_color() == WHITE, 'Rook not in correct position');
}

#[test]
fn test_castling_queenside_black() {
    let world = setup_world();
    init_game_board(world);

    // Clear path for castling
    clear_path(world, array![Position { x: 1, y: 7 }, Position { x: 2, y: 7 }, Position { x: 3, y: 7 }]);

    // Perform castling
    assert_move_valid(world, Position { x: 4, y: 7 }, Position { x: 2, y: 7 });

    // Verify king and rook positions after castling
    let king = get!(world, Position { x: 2, y: 7 }, Piece);
    let rook = get!(world, Position { x: 3, y: 7 }, Piece);
    assert(king.get_type() == KING && king.get_color() == BLACK, 'King not in correct position');
    assert(rook.get_type() == ROOK && rook.get_color() == BLACK, 'Rook not in correct position');
}

#[test]
fn test_castling_invalid() {
    let world = setup_world();
    init_game_board(world);

    // Attempt castling without clearing path
    assert_move_invalid(world, Position { x: 4, y: 0 }, Position { x: 6, y: 0 });

    // Move king and attempt castling
    assert_move_valid(world, Position { x: 4, y: 0 }, Position { x: 5, y: 0 });
    assert_move_valid(world, Position { x: 5, y: 0 }, Position { x: 4, y: 0 });
    clear_path(world, array![Position { x: 5, y: 0 }, Position { x: 6, y: 0 }]);
    assert_move_invalid(world, Position { x: 4, y: 0 }, Position { x: 6, y: 0 });
}

#[test]
fn test_en_passant() {
    let world = setup_world();
    init_game_board(world);

    // Move white pawn two squares forward
    assert_move_valid(world, Position { x: 4, y: 1 }, Position { x: 4, y: 3 });

    // Move black pawn to setup en passant
    assert_move_valid(world, Position { x: 3, y: 6 }, Position { x: 3, y: 4 });

    // Perform en passant capture
    assert_move_valid(world, Position { x: 4, y: 3 }, Position { x: 3, y: 2 });

    // Verify captured pawn is removed
    let captured_pawn = get!(world, Position { x: 3, y: 4 }, Piece);
    assert(captured_pawn.get_type() == 0, 'Captured pawn should be removed');
}

#[test]
fn test_pawn_promotion() {
    let world = setup_world();
    init_game_board(world);

    // Move white pawn to the edge of the board
    set!(world, (Position { x: 0, y: 6 }, Piece::new(PAWN, WHITE)));
    assert_move_valid(world, Position { x: 0, y: 6 }, Position { x: 0, y: 7 });

    // Verify pawn is promoted (assuming automatic promotion to queen)
    let promoted_piece = get!(world, Position { x: 0, y: 7 }, Piece);
    assert(promoted_piece.get_type() == QUEEN && promoted_piece.get_color() == WHITE, 'Pawn should be promoted to queen');
}

#[test]
fn test_check() {
    let world = setup_world();
    init_game_board(world);

    // Move white queen to put black king in check
    clear_path(world, array![Position { x: 3, y: 1 }, Position { x: 3, y: 2 }, Position { x: 3, y: 3 }]);
    assert_move_valid(world, Position { x: 3, y: 0 }, Position { x: 3, y: 4 });

    // Verify black king is in check
    let game_state = get!(world, 0, GameState);
    assert(game_state.status == 1, 'Black king should be in check');

    // Attempt move that doesn't resolve check (should be invalid)
    assert_move_invalid(world, Position { x: 0, y: 6 }, Position { x: 0, y: 5 });

    // Move to resolve check
    assert_move_valid(world, Position { x: 4, y: 7 }, Position { x: 3, y: 6 });

    // Verify check is resolved
    let updated_game_state = get!(world, 0, GameState);
    assert(updated_game_state.status == 0, 'Check should be resolved');
}

#[test]
fn test_checkmate() {
    let world = setup_world();
    init_game_board(world);

    // Set up fool's mate scenario
    assert_move_valid(world, Position { x: 5, y: 1 }, Position { x: 5, y: 2 });
    assert_move_valid(world, Position { x: 4, y: 6 }, Position { x: 4, y: 4 });
    assert_move_valid(world, Position { x: 6, y: 1 }, Position { x: 6, y: 3 });

    // Perform checkmate move
    assert_move_valid(world, Position { x: 3, y: 7 }, Position { x: 7, y: 3 });

    // Verify game is in checkmate state
    let game_state = get!(world, 0, GameState);
    assert(game_state.status == 2, 'Game should be in checkmate');
}

#[test]
fn test_stalemate() {
    let world = setup_world();
    init_game_board(world);

    // Set up stalemate scenario (this is a simplified scenario)
    clear_path(world, array![
        Position { x: 0, y: 0 }, Position { x: 1, y: 0 }, Position { x: 2, y: 0 },
        Position { x: 0, y: 1 }, Position { x: 1, y: 1 }, Position { x: 2, y: 1 },
        Position { x: 3, y: 1 }, Position { x: 4, y: 1 }, Position { x: 5, y: 1 },
        Position { x: 6, y: 1 }, Position { x: 7, y: 1 }
    ]);
    set!(world, (Position { x: 0, y: 0 }, Piece::new(KING, BLACK)));
    set!(world, (Position { x: 2, y: 1 }, Piece::new(QUEEN, WHITE)));
    set!(world, (Position { x: 2, y: 2 }, Piece::new(KING, WHITE)));

    // Perform move leading to stalemate
    assert_move_valid(world, Position { x: 2, y: 1 }, Position { x: 1, y: 1 });

    // Verify game is in stalemate
    let game_state = get!(world, 0, GameState);
    assert(game_state.status == 3, 'Game should be in stalemate');
}