use array::ArrayTrait;
use option::OptionTrait;
use super::position::Position;

#[derive(Component, Copy, Drop, Serde)]
struct GameState {
    turn: bool,
    status: u8, // 0=ongoing, 1=checkmate, 2=stalemate
    en_passant: Option<Position>,
    castling_rights: u8 // Bit flags for castling rights
}