use array::ArrayTrait;
use option::OptionTrait;
use super::position::Position;
use super::piece::Piece;

#[derive(Component, Copy, Drop, Serde)]
struct MoveHistory {
    from: Position,
    to: Position,
    piece: Piece,
    captured: Option<Piece>
}