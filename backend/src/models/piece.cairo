use array::ArrayTrait;

#[derive(Component, Copy, Drop, Serde)]
struct Piece {
    piece_type: u8, // 1=Pawn, 2=Rook, 3=Knight, 4=Bishop, 5=Queen, 6=King
    color: bool // true for white, false for black
}