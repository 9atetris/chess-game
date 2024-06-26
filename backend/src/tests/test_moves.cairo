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

#[test]
fn test_pawn_movement() {
    let world = setup_world();
    init_game_board(world);

    // White pawn moves
    assert_move_valid(world, Position { x: 0, y: 1 }, Position { x: 0, y: 2 }); // Single forward
    assert_move_valid(world, Position { x: 1, y: 1 }, Position { x: 1, y: 3 }); // Double forward
    assert_move_invalid(world, Position { x: 2, y: 1 }, Position { x: 2, y: 4 }); // Too far
    assert_move_invalid(world, Position { x: 3, y: 1 }, Position { x: 4, y: 2 }); // Diagonal without capture

    // Black pawn moves
    assert_move_valid(world, Position { x: 0, y: 6 }, Position { x: 0, y: 5 }); // Single forward
    assert_move_valid(world, Position { x: 1, y: 6 }, Position { x: 1, y: 4 }); // Double forward
    assert_move_invalid(world, Position { x: 2, y: 6 }, Position { x: 2, y: 3 }); // Too far
    assert_move_invalid(world, Position { x: 3, y: 6 }, Position { x: 2, y: 5 }); // Diagonal without capture

    // TODO: Add test for pawn capture when implemented
}

#[test]
fn test_rook_movement() {
    let world = setup_world();
    init_game_board(world);

    // Move pawn to open path for rook
    assert_move_valid(world, Position { x: 0, y: 1 }, Position { x: 0, y: 3 });

    // Rook moves
    assert_move_valid(world, Position { x: 0, y: 0 }, Position { x: 0, y: 2 }); // Vertical move
    assert_move_valid(world, Position { x: 0, y: 2 }, Position { x: 3, y: 2 }); // Horizontal move
    assert_move_invalid(world, Position { x: 3, y: 2 }, Position { x: 4, y: 3 }); // Diagonal move
    assert_move_invalid(world, Position { x: 3, y: 2 }, Position { x: 3, y: 6 }); // Through piece
}

#[test]
fn test_knight_movement() {
    let world = setup_world();
    init_game_board(world);

    assert_move_valid(world, Position { x: 1, y: 0 }, Position { x: 2, y: 2 }); // L shape
    assert_move_valid(world, Position { x: 1, y: 0 }, Position { x: 0, y: 2 }); // L shape
    assert_move_invalid(world, Position { x: 1, y: 0 }, Position { x: 1, y: 2 }); // Straight move
    assert_move_invalid(world, Position { x: 1, y: 0 }, Position { x: 3, y: 3 }); // Invalid L shape
}

#[test]
fn test_bishop_movement() {
    let world = setup_world();
    init_game_board(world);

    // Move pawn to open path for bishop
    assert_move_valid(world, Position { x: 3, y: 1 }, Position { x: 3, y: 3 });

    assert_move_valid(world, Position { x: 2, y: 0 }, Position { x: 0, y: 2 }); // Diagonal move
    assert_move_valid(world, Position { x: 0, y: 2 }, Position { x: 2, y: 4 }); // Diagonal move
    assert_move_invalid(world, Position { x: 2, y: 4 }, Position { x: 2, y: 6 }); // Vertical move
    assert_move_invalid(world, Position { x: 2, y: 4 }, Position { x: 4, y: 4 }); // Horizontal move
}

#[test]
fn test_queen_movement() {
    let world = setup_world();
    init_game_board(world);

    // Move pawn to open path for queen
    assert_move_valid(world, Position { x: 3, y: 1 }, Position { x: 3, y: 3 });

    assert_move_valid(world, Position { x: 3, y: 0 }, Position { x: 3, y: 2 }); // Vertical move
    assert_move_valid(world, Position { x: 3, y: 2 }, Position { x: 0, y: 2 }); // Horizontal move
    assert_move_valid(world, Position { x: 0, y: 2 }, Position { x: 2, y: 4 }); // Diagonal move
    assert_move_invalid(world, Position { x: 2, y: 4 }, Position { x: 1, y: 6 }); // Through piece
}

#[test]
fn test_king_movement() {
    let world = setup_world();
    init_game_board(world);

    // Move pawn to open path for king
    assert_move_valid(world, Position { x: 4, y: 1 }, Position { x: 4, y: 2 });

    assert_move_valid(world, Position { x: 4, y: 0 }, Position { x: 4, y: 1 }); // Vertical move
    assert_move_valid(world, Position { x: 4, y: 1 }, Position { x: 5, y: 1 }); // Horizontal move
    assert_move_valid(world, Position { x: 5, y: 1 }, Position { x: 4, y: 2 }); // Diagonal move
    assert_move_invalid(world, Position { x: 4, y: 2 }, Position { x: 4, y: 4 }); // Too far
}

#[test]
fn test_piece_capture() {
    let world = setup_world();
    init_game_board(world);

    // Move white pawn forward
    assert_move_valid(world, Position { x: 3, y: 1 }, Position { x: 3, y: 3 });
    // Move black pawn forward
    assert_move_valid(world, Position { x: 2, y: 6 }, Position { x: 2, y: 4 });
    // White pawn captures black pawn
    assert_move_valid(world, Position { x: 3, y: 3 }, Position { x: 2, y: 4 });

    // Attempt to capture own piece (should fail)
    assert_move_invalid(world, Position { x: 1, y: 0 }, Position { x: 0, y: 0 });
}

#[test]
fn test_move_to_occupied_square() {
    let world = setup_world();
    init_game_board(world);

    // Attempt to move to a square occupied by own piece
    assert_move_invalid(world, Position { x: 0, y: 1 }, Position { x: 0, y: 0 });
    assert_move_invalid(world, Position { x: 1, y: 0 }, Position { x: 0, y: 0 });
}