use dojo::database::introspect::{Introspect, Layout, Ty, FieldLayout, Member, Struct};
use array::ArrayTrait;
use core::array::SpanTrait;
use core::serde::Serde;

#[derive(Copy, Drop, Serde, Introspect)]
pub struct Position {
    pub x: u8,
    pub y: u8
}

impl OptionPositionIntrospect of Introspect<Option<Position>> {
    fn size() -> Option<usize> {
        Option::Some(3) // u8 for is_some + Position size (2)
    }

    fn layout() -> Layout {
        Layout::Struct(
            array![
                FieldLayout {
                    selector: selector!("is_some"),
                    layout: Introspect::<u8>::layout(),
                },
                FieldLayout {
                    selector: selector!("value"),
                    layout: Introspect::<Position>::layout(),
                },
            ].span()
        )
    }

    fn ty() -> Ty {
        Ty::Struct(
            Struct {
                name: 'Option<Position>',
                attrs: array![].span(),
                children: array![
                    Member {
                        name: 'is_some',
                        ty: Introspect::<u8>::ty(),
                        attrs: array![].span(),
                    },
                    Member {
                        name: 'value',
                        ty: Introspect::<Position>::ty(),
                        attrs: array![].span(),
                    },
                ].span(),
            }
        )
    }
}