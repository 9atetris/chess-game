use array::ArrayTrait;
use traits::Into;

// 駒の種類を表す定数
const EMPTY: u8 = 0;
const PAWN: u8 = 1;
const ROOK: u8 = 2;
const KNIGHT: u8 = 3;
const BISHOP: u8 = 4;
const QUEEN: u8 = 5;
const KING: u8 = 6;

// 色を表す定数
const WHITE: bool = true;
const BLACK: bool = false;

#[derive(Component, Copy, Drop, Serde)]
struct Piece {
    value: u8 // Lower 3 bits for piece type, 4th bit for color
}

trait PieceTrait {
    fn new(piece_type: u8, color: bool) -> Piece;
    fn get_type(self: Piece) -> u8;
    fn get_color(self: Piece) -> bool;
    fn is_empty(self: Piece) -> bool;
}

impl PieceImpl of PieceTrait {
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
trait PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252;
}

impl PieceUtils of PieceUtilsTrait {
    fn to_string(piece: @Piece) -> felt252 {
        let piece_type = (*piece).get_type();
        let color = if (*piece).get_color() { 'W' } else { 'B' };
        let type_char = match piece_type {
            _PAWN => 'P',
            _ROOK => 'R',
            _KNIGHT => 'N',
            _BISHOP => 'B',
            _QUEEN => 'Q',
            _KING => 'K',
            _ => '-',
        };
        color.into() * 256 + type_char.into()
    }
}