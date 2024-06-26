use array::ArrayTrait;
use core::result::Result;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use chess_game::models::position::Position;
use chess_game::models::piece::{Piece, PieceTrait};
use chess_game::models::player::Player;
use chess_game::models::game_state::GameState;
use chess_game::systems::init_game;
use chess_game::constants::{PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING, WHITE, BLACK};

// ヘルパー関数
fn setup_world() -> IWorldDispatcher {
    // 必要なモデルのクラスハッシュのリストを作成
    // 注: これらのクラスハッシュは実際のモデル定義に基づいて更新する必要があります
    let mut models = array![
        chess_game::models::position::TEST_CLASS_HASH,
        chess_game::models::piece::TEST_CLASS_HASH,
        chess_game::models::player::TEST_CLASS_HASH,
        chess_game::models::game_state::TEST_CLASS_HASH,
        chess_game::models::move_history::TEST_CLASS_HASH
    ];

    // テストワールドを生成
    let world = spawn_test_world(models);

    // IWorldDispatcherトレイトを実装したWorldDispatcherを返す
    WorldDispatcher { world }
}

#[test]
fn test_game_initialization() {
    let world = setup_world();

    // プレイヤーのアドレスを設定
    let player1 = starknet::contract_address_const::<0x1>();
    let player2 = starknet::contract_address_const::<0x2>();

    // ゲームを初期化
    init_game::execute(world, player1, player2);

    // ゲーム状態をチェック
    let game_state = get!(world, 0, GameState);
    assert(game_state.turn == true, 'Initial turn should be white');
    assert(game_state.status == 0, 'Initial status should be ongoing');
    assert(game_state.en_passant.is_none(), 'No initial en passant');
    assert(game_state.castling_rights == 0b1111, 'All castling should be allowed');

    // プレイヤーの設定をチェック
    let player1_data = get!(world, player1, Player);
    let player2_data = get!(world, player2, Player);
    assert(player1_data.color == WHITE, 'Player 1 should be white');
    assert(player2_data.color == BLACK, 'Player 2 should be black');
}

#[test]
fn test_initial_board_setup() {
    let world = setup_world();

    // プレイヤーのアドレスを設定
    let player1 = starknet::contract_address_const::<0x1>();
    let player2 = starknet::contract_address_const::<0x2>();

    // ゲームを初期化
    init_game::execute(world, player1, player2);

    // 白の駒の配置をチェック
    assert_piece(world, 0, 0, ROOK, WHITE);
    assert_piece(world, 1, 0, KNIGHT, WHITE);
    assert_piece(world, 2, 0, BISHOP, WHITE);
    assert_piece(world, 3, 0, QUEEN, WHITE);
    assert_piece(world, 4, 0, KING, WHITE);
    assert_piece(world, 5, 0, BISHOP, WHITE);
    assert_piece(world, 6, 0, KNIGHT, WHITE);
    assert_piece(world, 7, 0, ROOK, WHITE);

    // 白のポーンの配置をチェック
    let mut i = 0;
    loop {
        if i == 8 {
            break;
        }
        assert_piece(world, i, 1, PAWN, WHITE);
        i += 1;
    };

    // 黒の駒の配置をチェック
    assert_piece(world, 0, 7, ROOK, BLACK);
    assert_piece(world, 1, 7, KNIGHT, BLACK);
    assert_piece(world, 2, 7, BISHOP, BLACK);
    assert_piece(world, 3, 7, QUEEN, BLACK);
    assert_piece(world, 4, 7, KING, BLACK);
    assert_piece(world, 5, 7, BISHOP, BLACK);
    assert_piece(world, 6, 7, KNIGHT, BLACK);
    assert_piece(world, 7, 7, ROOK, BLACK);

    // 黒のポーンの配置をチェック
    let mut i = 0;
    loop {
        if i == 8 {
            break;
        }
        assert_piece(world, i, 6, PAWN, BLACK);
        i += 1;
    };

    // 空のマスをチェック
    let mut y = 2;
    loop {
        if y == 6 {
            break;
        }
        let mut x = 0;
        loop {
            if x == 8 {
                break;
            }
            assert_empty(world, x, y);
            x += 1;
        };
        y += 1;
    };
}

// ヘルパー関数
fn assert_piece(world: IWorldDispatcher, x: u8, y: u8, expected_type: u8, expected_color: bool) {
    let piece = get!(world, Position { x, y }, Piece);
    assert(piece.get_type() == expected_type, 'Incorrect piece type');
    assert(piece.get_color() == expected_color, 'Incorrect piece color');
}

fn assert_empty(world: IWorldDispatcher, x: u8, y: u8) {
    let piece = get!(world, Position { x, y }, Piece);
    assert(piece.get_type() == 0, 'Square should be empty');
}