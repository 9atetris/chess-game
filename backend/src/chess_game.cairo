use starknet::ContractAddress;
use array::ArrayTrait;
use option::OptionTrait;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use crate::models::{Position, Piece, PieceTrait, Player, GameState, MoveHistory};
use crate::systems::actions;

// 駒の種類を表す定数
const EMPTY: u8 = 0;
const PAWN: u8 = 1;
const ROOK: u8 = 2;
const KNIGHT: u8 = 3;
const BISHOP: u8 = 4;
const QUEEN: u8 = 5;
const KING: u8 = 6;

// ボードサイズの定数
const BOARD_SIZE: u8 = 8;

#[contract]
mod ChessGame {
    use super::*;

    #[external]
    fn init_game(world: IWorldDispatcher, player1: ContractAddress, player2: ContractAddress) {
        init_board(world);
        set!(world, (player1, Player { address: player1, color: true }));
        set!(world, (player2, Player { address: player2, color: false }));
        set!(world, (0, GameState { 
            turn: true, 
            status: 0, 
            en_passant: Option::None, 
            castling_rights: 0b1111 // Both sides can castle both ways initially
        }));
    }

    #[external]
    fn move(world: IWorldDispatcher, from: Position, to: Position) -> bool {
        actions::execute(world, from, to)
    }

    fn init_board(world: IWorldDispatcher) {
        let pieces = array![ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK];
        
        let mut x = 0;
        loop {
            if x == BOARD_SIZE {
                break;
            }
            
            // 白の駒を配置
            set!(world, ((x, 0), Piece::new(*pieces[x], true)));
            set!(world, ((x, 1), Piece::new(PAWN, true)));
            
            // 黒の駒を配置
            set!(world, ((x, 6), Piece::new(PAWN, false)));
            set!(world, ((x, 7), Piece::new(*pieces[x], false)));
            
            x += 1;
        }
        
        // 残りのマスを空にする
        let mut y = 2;
        loop {
            if y == 6 {
                break;
            }
            let mut x = 0;
            loop {
                if x == BOARD_SIZE {
                    break;
                }
                set!(world, ((x, y), Piece::new(EMPTY, false)));
                x += 1;
            }
            y += 1;
        }
    }

    #[view]
    fn get_piece(world: IWorldDispatcher, position: Position) -> Piece {
        get!(world, position, Piece)
    }

    #[view]
    fn get_game_state(world: IWorldDispatcher) -> GameState {
        get!(world, 0, GameState)
    }
}