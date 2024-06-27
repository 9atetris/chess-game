use array::ArrayTrait;
use traits::Into;

#[derive(Component, Copy, Drop, Serde)]
pub struct Position {
    pub x: u8,
    pub y: u8
}