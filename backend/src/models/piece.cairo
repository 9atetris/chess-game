use array::ArrayTrait;
use traits::Into;
use super::position::Position;

// 駒の種類を表す定数
pub const EMPTY: u8 = 0;
pub const PAWN: u8 = 1;
pub const ROOK: u8 = 2;
pub const KNIGHT: u8 = 3;
pub const BISHOP: u8 = 4;
pub const QUEEN: u8 = 5;
pub const KING: u8 = 6;

// 色を表す定数
pub const WHITE: bool = true;
pub const BLACK: bool = false;

#[derive(Component, Copy, Drop, Serde)]
pub struct Piece {
    #[key]
    position: Position,
    value: u8 // Lower 3 bits for piece type, 4th bit for color
}

pub trait PieceTrait {
    fn new(piece_type: u8, color: bool) -> Piece;
    fn get_type(self: @Piece) -> u8;
    fn get_color(self: @Piece) -> bool;
    fn is_empty(self: @Piece) -> bool;
    fn set_position(ref self: Piece, position: Position);
}

pub impl PieceImpl of PieceTrait {
    fn new(piece_type: u8, color: bool) -> Piece {
        assert(piece_type <= KING, 'Invalid piece type');
        Piece { 
            position: Position { x: 0, y: 0 }, // デフォルト位置を設定
            value: piece_type | (if color { 0x8 } else { 0 }) 
        }
    }

    fn get_type(self: @Piece) -> u8 {
        *self.value & 0x7
    }

    fn get_color(self: @Piece) -> bool {
        (*self.value & 0x8) != 0
    }

    fn is_empty(self: @Piece) -> bool {
        self.get_type() == EMPTY
    }

    fn set_position(ref self: Piece, position: Position) {
        self.position = position;
    }
}

// ユーティリティ関数
use core::integer::U8IntoFelt252;

pub trait PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252;
}

pub impl PieceUtils of PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252 {
        let piece_type = piece.get_type();
        let color = if piece.get_color() { 'W' } else { 'B' };
        let type_char = match piece_type {
            PAWN => 'P',
            ROOK => 'R',
            KNIGHT => 'N',
            BISHOP => 'B',
            QUEEN => 'Q',
            KING => 'K',
            _ => '-',
        };
        
        let position = piece.position;
        let file = match *position.x {
            0 => 'a',
            1 => 'b',
            2 => 'c',
            3 => 'd',
            4 => 'e',
            5 => 'f',
            6 => 'g',
            7 => 'h',
            _ => '?',
        };
        
        let rank: felt252 = (*position.y + 1).into();
        
        // Combine all parts into a single felt252
        // Format: CTFR (Color, Type, File, Rank)
        color.into() * 256 * 256 * 256 + 
        type_char.into() * 256 * 256 + 
        file.into() * 256 + 
        rank
    }
}