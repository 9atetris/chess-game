use array::ArrayTrait;
use traits::Into;

#[derive(Component, Copy, Drop, Serde)]
struct Position {
    x: u8,
    y: u8
}