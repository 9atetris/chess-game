use array::ArrayTrait;
use starknet::ContractAddress;

#[derive(Component, Copy, Drop, Serde)]
struct Player {
    address: ContractAddress,
    color: bool
}