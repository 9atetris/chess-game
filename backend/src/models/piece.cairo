use array::ArrayTrait;
use traits::Into;

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
    value: u8 // Lower 3 bits for piece type, 4th bit for color
}

pub trait PieceTrait {
    fn new(piece_type: u8, color: bool) -> Piece;
    fn get_type(self: Piece) -> u8;
    fn get_color(self: Piece) -> bool;
    fn is_empty(self: Piece) -> bool;
}

pub impl PieceImpl of PieceTrait {
    fn new(piece_type: u8, color: bool) -> Piece {
        assert(piece_type <= KING, 'Invalid piece type');
        Piece { value: piece_type | (if color { 0x8 } else { 0 }) }
    }

    fn get_type(self: Piece) -> u8 {
        self.value & 0x7
    }

    fn get_color(self: Piece) -> bool {
        (self.value & 0x8) != 0
    }

    fn is_empty(self: Piece) -> bool {
        self.get_type() == EMPTY
    }
}

// ユーティリティ関数
pub trait PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252;
}

pub impl PieceUtils of PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252 {
        let piece_type = (*piece).get_type();
        let color = if (*piece).get_color() { 'W' } else { 'B' };
        let type_char = if piece_type == PAWN {
            'P'
        } else if piece_type == ROOK {
            'R'
        } else if piece_type == KNIGHT {
            'N'
        } else if piece_type == BISHOP {
            'B'
        } else if piece_type == QUEEN {
            'Q'
        } else if piece_type == KING {
            'K'
        } else {
            '-'
        };
        color.into() * 256 + type_char.into()
    }
}