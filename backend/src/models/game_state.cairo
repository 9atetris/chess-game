use array::ArrayTrait;
use option::OptionTrait;
use dojo::model::Model;
use dojo::database::introspect::Introspect;
use super::position::Position;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameState {
    #[key]
    game_id: u32,
    turn: bool,
    status: u8,
    en_passant: Option<Position>,
    castling_rights: u8
}
