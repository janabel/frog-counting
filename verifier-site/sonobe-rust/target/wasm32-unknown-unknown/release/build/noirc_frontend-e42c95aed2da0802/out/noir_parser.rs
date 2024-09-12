// auto-generated: "lalrpop 0.20.2"
// sha3: 2cf7c0415a9071b48106a247e45454a5d0792d338ef17a7e29c6aa74a98effad
use noirc_errors::Span;
use crate::lexer::token::BorrowedToken;
use crate::lexer::token as noir_token;
use crate::lexer::errors::LexerErrorKind;
use crate::parser::TopLevelStatement;
use crate::ast::{Ident, Path, PathKind, UseTree, UseTreeKind};
use lalrpop_util::ErrorRecovery;
#[allow(unused_extern_crates)]
extern crate lalrpop_util as __lalrpop_util;
#[allow(unused_imports)]
use self::__lalrpop_util::state_machine as __state_machine;
use core;
extern crate alloc;

#[rustfmt::skip]
#[allow(non_snake_case, non_camel_case_types, unused_mut, unused_variables, unused_imports, unused_parens, clippy::needless_lifetimes, clippy::type_complexity, clippy::needless_return, clippy::too_many_arguments, clippy::never_loop, clippy::match_single_binding, clippy::needless_raw_string_hashes)]
mod __parse__Path {

    use noirc_errors::Span;
    use crate::lexer::token::BorrowedToken;
    use crate::lexer::token as noir_token;
    use crate::lexer::errors::LexerErrorKind;
    use crate::parser::TopLevelStatement;
    use crate::ast::{Ident, Path, PathKind, UseTree, UseTreeKind};
    use lalrpop_util::ErrorRecovery;
    #[allow(unused_extern_crates)]
    extern crate lalrpop_util as __lalrpop_util;
    #[allow(unused_imports)]
    use self::__lalrpop_util::state_machine as __state_machine;
    use core;
    extern crate alloc;
    use super::__ToTriple;
    #[allow(dead_code)]
    pub(crate) enum __Symbol<'input>
     {
        Variant0(BorrowedToken<'input>),
        Variant1(&'input str),
        Variant2(Ident),
        Variant3(alloc::vec::Vec<Ident>),
        Variant4(usize),
        Variant5(core::option::Option<Ident>),
        Variant6(Path),
        Variant7(Vec<Ident>),
        Variant8(TopLevelStatement),
        Variant9(UseTree),
        Variant10(core::option::Option<BorrowedToken<'input>>),
    }
    const __ACTION: &[i8] = &[
        // State 0
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0,
        // State 1
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 2
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0,
        // State 3
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 4
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 5
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0,
        // State 6
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 7
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 8
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 9
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 10
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 11
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 12
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 13
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 14
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 15
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ];
    fn __action(state: i8, integer: usize) -> i8 {
        __ACTION[(state as usize) * 75 + integer]
    }
    const __EOF_ACTION: &[i8] = &[
        // State 0
        0,
        // State 1
        -17,
        // State 2
        0,
        // State 3
        -17,
        // State 4
        -17,
        // State 5
        0,
        // State 6
        -23,
        // State 7
        0,
        // State 8
        0,
        // State 9
        -13,
        // State 10
        -18,
        // State 11
        -16,
        // State 12
        -4,
        // State 13
        -14,
        // State 14
        -15,
        // State 15
        -5,
    ];
    fn __goto(state: i8, nt: usize) -> i8 {
        match nt {
            2 => 10,
            8 => match state {
                2 => 12,
                5 => 15,
                _ => 1,
            },
            9 => 6,
            10 => match state {
                3 => 13,
                4 => 14,
                _ => 11,
            },
            _ => 0,
        }
    }
    const __TERMINAL: &[&str] = &[
        r###""!""###,
        r###""!=""###,
        r###""#""###,
        r###""%""###,
        r###""&""###,
        r###""(""###,
        r###"")""###,
        r###""*""###,
        r###""+""###,
        r###"",""###,
        r###""-""###,
        r###""->""###,
        r###"".""###,
        r###""..""###,
        r###""/""###,
        r###"":""###,
        r###""::""###,
        r###"";""###,
        r###""<""###,
        r###""<<""###,
        r###""<=""###,
        r###""=""###,
        r###""==""###,
        r###"">""###,
        r###"">=""###,
        r###"">>""###,
        r###""Field""###,
        r###""[""###,
        r###""]""###,
        r###""^""###,
        r###""as""###,
        r###""assert""###,
        r###""assert_eq""###,
        r###""bool""###,
        r###""break""###,
        r###""call_data""###,
        r###""char""###,
        r###""comptime""###,
        r###""constrain""###,
        r###""continue""###,
        r###""contract""###,
        r###""crate""###,
        r###""dep""###,
        r###""else""###,
        r###""false""###,
        r###""fmtstr""###,
        r###""fn""###,
        r###""for""###,
        r###""global""###,
        r###""if""###,
        r###""impl""###,
        r###""in""###,
        r###""let""###,
        r###""mod""###,
        r###""mut""###,
        r###""pub""###,
        r###""return""###,
        r###""return_data""###,
        r###""str""###,
        r###""struct""###,
        r###""trait""###,
        r###""true""###,
        r###""type""###,
        r###""unchecked""###,
        r###""unconstrained""###,
        r###""use""###,
        r###""where""###,
        r###""while""###,
        r###""{""###,
        r###""|""###,
        r###""}""###,
        r###"r#"[\\t\\r\\n ]+"#"###,
        r###"EOF"###,
        r###"ident"###,
        r###"string"###,
    ];
    fn __expected_tokens(__state: i8) -> alloc::vec::Vec<alloc::string::String> {
        __TERMINAL.iter().enumerate().filter_map(|(index, terminal)| {
            let next_state = __action(__state, index);
            if next_state == 0 {
                None
            } else {
                Some(alloc::string::ToString::to_string(terminal))
            }
        }).collect()
    }
    fn __expected_tokens_from_states<
        'input,
        'err,
    >(
        __states: &[i8],
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> alloc::vec::Vec<alloc::string::String>
    where
        'input: 'err,
        'static: 'err,
    {
        __TERMINAL.iter().enumerate().filter_map(|(index, terminal)| {
            if __accepts(None, __states, Some(index), core::marker::PhantomData::<(&(), &())>) {
                Some(alloc::string::ToString::to_string(terminal))
            } else {
                None
            }
        }).collect()
    }
    struct __StateMachine<'input, 'err>
    where 'input: 'err, 'static: 'err
    {
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __phantom: core::marker::PhantomData<(&'input (), &'err ())>,
    }
    impl<'input, 'err> __state_machine::ParserDefinition for __StateMachine<'input, 'err>
    where 'input: 'err, 'static: 'err
    {
        type Location = usize;
        type Error = LexerErrorKind;
        type Token = BorrowedToken<'input>;
        type TokenIndex = usize;
        type Symbol = __Symbol<'input>;
        type Success = Path;
        type StateIndex = i8;
        type Action = i8;
        type ReduceIndex = i8;
        type NonterminalIndex = usize;

        #[inline]
        fn start_location(&self) -> Self::Location {
              Default::default()
        }

        #[inline]
        fn start_state(&self) -> Self::StateIndex {
              0
        }

        #[inline]
        fn token_to_index(&self, token: &Self::Token) -> Option<usize> {
            __token_to_integer(token, core::marker::PhantomData::<(&(), &())>)
        }

        #[inline]
        fn action(&self, state: i8, integer: usize) -> i8 {
            __action(state, integer)
        }

        #[inline]
        fn error_action(&self, state: i8) -> i8 {
            __action(state, 75 - 1)
        }

        #[inline]
        fn eof_action(&self, state: i8) -> i8 {
            __EOF_ACTION[state as usize]
        }

        #[inline]
        fn goto(&self, state: i8, nt: usize) -> i8 {
            __goto(state, nt)
        }

        fn token_to_symbol(&self, token_index: usize, token: Self::Token) -> Self::Symbol {
            __token_to_symbol(token_index, token, core::marker::PhantomData::<(&(), &())>)
        }

        fn expected_tokens(&self, state: i8) -> alloc::vec::Vec<alloc::string::String> {
            __expected_tokens(state)
        }

        fn expected_tokens_from_states(&self, states: &[i8]) -> alloc::vec::Vec<alloc::string::String> {
            __expected_tokens_from_states(states, core::marker::PhantomData::<(&(), &())>)
        }

        #[inline]
        fn uses_error_recovery(&self) -> bool {
            false
        }

        #[inline]
        fn error_recovery_symbol(
            &self,
            recovery: __state_machine::ErrorRecovery<Self>,
        ) -> Self::Symbol {
            panic!("error recovery not enabled for this grammar")
        }

        fn reduce(
            &mut self,
            action: i8,
            start_location: Option<&Self::Location>,
            states: &mut alloc::vec::Vec<i8>,
            symbols: &mut alloc::vec::Vec<__state_machine::SymbolTriple<Self>>,
        ) -> Option<__state_machine::ParseResult<Self>> {
            __reduce(
                self.input,
                self.errors,
                action,
                start_location,
                states,
                symbols,
                core::marker::PhantomData::<(&(), &())>,
            )
        }

        fn simulate_reduce(&self, action: i8) -> __state_machine::SimulatedReduce<Self> {
            __simulate_reduce(action, core::marker::PhantomData::<(&(), &())>)
        }
    }
    fn __token_to_integer<
        'input,
        'err,
    >(
        __token: &BorrowedToken<'input>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> Option<usize>
    {
        match *__token {
            BorrowedToken::Bang if true => Some(0),
            BorrowedToken::NotEqual if true => Some(1),
            BorrowedToken::Pound if true => Some(2),
            BorrowedToken::Percent if true => Some(3),
            BorrowedToken::Ampersand if true => Some(4),
            BorrowedToken::LeftParen if true => Some(5),
            BorrowedToken::RightParen if true => Some(6),
            BorrowedToken::Star if true => Some(7),
            BorrowedToken::Plus if true => Some(8),
            BorrowedToken::Comma if true => Some(9),
            BorrowedToken::Minus if true => Some(10),
            BorrowedToken::Arrow if true => Some(11),
            BorrowedToken::Dot if true => Some(12),
            BorrowedToken::DoubleDot if true => Some(13),
            BorrowedToken::Slash if true => Some(14),
            BorrowedToken::Colon if true => Some(15),
            BorrowedToken::DoubleColon if true => Some(16),
            BorrowedToken::Semicolon if true => Some(17),
            BorrowedToken::Less if true => Some(18),
            BorrowedToken::ShiftLeft if true => Some(19),
            BorrowedToken::LessEqual if true => Some(20),
            BorrowedToken::Assign if true => Some(21),
            BorrowedToken::Equal if true => Some(22),
            BorrowedToken::Greater if true => Some(23),
            BorrowedToken::GreaterEqual if true => Some(24),
            BorrowedToken::ShiftRight if true => Some(25),
            BorrowedToken::Keyword(noir_token::Keyword::Field) if true => Some(26),
            BorrowedToken::LeftBracket if true => Some(27),
            BorrowedToken::RightBracket if true => Some(28),
            BorrowedToken::Caret if true => Some(29),
            BorrowedToken::Keyword(noir_token::Keyword::As) if true => Some(30),
            BorrowedToken::Keyword(noir_token::Keyword::Assert) if true => Some(31),
            BorrowedToken::Keyword(noir_token::Keyword::AssertEq) if true => Some(32),
            BorrowedToken::Keyword(noir_token::Keyword::Bool) if true => Some(33),
            BorrowedToken::Keyword(noir_token::Keyword::Break) if true => Some(34),
            BorrowedToken::Keyword(noir_token::Keyword::CallData) if true => Some(35),
            BorrowedToken::Keyword(noir_token::Keyword::Char) if true => Some(36),
            BorrowedToken::Keyword(noir_token::Keyword::Comptime) if true => Some(37),
            BorrowedToken::Keyword(noir_token::Keyword::Constrain) if true => Some(38),
            BorrowedToken::Keyword(noir_token::Keyword::Continue) if true => Some(39),
            BorrowedToken::Keyword(noir_token::Keyword::Contract) if true => Some(40),
            BorrowedToken::Keyword(noir_token::Keyword::Crate) if true => Some(41),
            BorrowedToken::Keyword(noir_token::Keyword::Dep) if true => Some(42),
            BorrowedToken::Keyword(noir_token::Keyword::Else) if true => Some(43),
            BorrowedToken::Bool(false) if true => Some(44),
            BorrowedToken::Keyword(noir_token::Keyword::FormatString) if true => Some(45),
            BorrowedToken::Keyword(noir_token::Keyword::Fn) if true => Some(46),
            BorrowedToken::Keyword(noir_token::Keyword::For) if true => Some(47),
            BorrowedToken::Keyword(noir_token::Keyword::Global) if true => Some(48),
            BorrowedToken::Keyword(noir_token::Keyword::If) if true => Some(49),
            BorrowedToken::Keyword(noir_token::Keyword::Impl) if true => Some(50),
            BorrowedToken::Keyword(noir_token::Keyword::In) if true => Some(51),
            BorrowedToken::Keyword(noir_token::Keyword::Let) if true => Some(52),
            BorrowedToken::Keyword(noir_token::Keyword::Mod) if true => Some(53),
            BorrowedToken::Keyword(noir_token::Keyword::Mut) if true => Some(54),
            BorrowedToken::Keyword(noir_token::Keyword::Pub) if true => Some(55),
            BorrowedToken::Keyword(noir_token::Keyword::Return) if true => Some(56),
            BorrowedToken::Keyword(noir_token::Keyword::ReturnData) if true => Some(57),
            BorrowedToken::Keyword(noir_token::Keyword::String) if true => Some(58),
            BorrowedToken::Keyword(noir_token::Keyword::Struct) if true => Some(59),
            BorrowedToken::Keyword(noir_token::Keyword::Trait) if true => Some(60),
            BorrowedToken::Bool(true) if true => Some(61),
            BorrowedToken::Keyword(noir_token::Keyword::Type) if true => Some(62),
            BorrowedToken::Keyword(noir_token::Keyword::Unchecked) if true => Some(63),
            BorrowedToken::Keyword(noir_token::Keyword::Unconstrained) if true => Some(64),
            BorrowedToken::Keyword(noir_token::Keyword::Use) if true => Some(65),
            BorrowedToken::Keyword(noir_token::Keyword::Where) if true => Some(66),
            BorrowedToken::Keyword(noir_token::Keyword::While) if true => Some(67),
            BorrowedToken::LeftBrace if true => Some(68),
            BorrowedToken::Pipe if true => Some(69),
            BorrowedToken::RightBrace if true => Some(70),
            BorrowedToken::Whitespace(_) if true => Some(71),
            BorrowedToken::EOF if true => Some(72),
            BorrowedToken::Ident(_) if true => Some(73),
            BorrowedToken::Str(_) if true => Some(74),
            _ => None,
        }
    }
    fn __token_to_symbol<
        'input,
        'err,
    >(
        __token_index: usize,
        __token: BorrowedToken<'input>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> __Symbol<'input>
    {
        #[allow(clippy::manual_range_patterns)]match __token_index {
            0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70 | 71 | 72 => __Symbol::Variant0(__token),
            73 | 74 => match __token {
                BorrowedToken::Ident(__tok0) | BorrowedToken::Str(__tok0) if true => __Symbol::Variant1(__tok0),
                _ => unreachable!(),
            },
            _ => unreachable!(),
        }
    }
    fn __simulate_reduce<
        'input,
        'err,
    >(
        __reduce_index: i8,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> __state_machine::SimulatedReduce<__StateMachine<'input, 'err>>
    where
        'input: 'err,
        'static: 'err,
    {
        match __reduce_index {
            0 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 0,
                }
            }
            1 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 1,
                }
            }
            2 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 1,
                }
            }
            3 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 2,
                }
            }
            4 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 2,
                }
            }
            5 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 3,
                }
            }
            6 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 4,
                }
            }
            7 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 4,
                    nonterminal_produced: 5,
                }
            }
            8 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 6,
                }
            }
            9 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 6,
                }
            }
            10 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 7,
                }
            }
            11 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 7,
                }
            }
            12 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 8,
                }
            }
            13 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 9,
                }
            }
            14 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 9,
                }
            }
            15 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 9,
                }
            }
            16 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 10,
                }
            }
            17 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 10,
                }
            }
            18 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 6,
                    nonterminal_produced: 11,
                }
            }
            19 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 5,
                    nonterminal_produced: 11,
                }
            }
            20 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 12,
                }
            }
            21 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 12,
                }
            }
            22 => __state_machine::SimulatedReduce::Accept,
            23 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 14,
                }
            }
            24 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 15,
                }
            }
            25 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 15,
                }
            }
            _ => panic!("invalid reduction index {}", __reduce_index)
        }
    }
    pub(crate) struct PathParser {
        _priv: (),
    }

    impl Default for PathParser { fn default() -> Self { Self::new() } }
    impl PathParser {
        pub(crate) fn new() -> PathParser {
            PathParser {
                _priv: (),
            }
        }

        #[allow(dead_code)]
        pub(crate) fn parse<
            'input,
            'err,
            __TOKEN: __ToTriple<'input, 'err, >,
            __TOKENS: IntoIterator<Item=__TOKEN>,
        >(
            &self,
            input: &'input str,
            errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
            __tokens0: __TOKENS,
        ) -> Result<Path, __lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>>
        {
            let __tokens = __tokens0.into_iter();
            let mut __tokens = __tokens.map(|t| __ToTriple::to_triple(t));
            __state_machine::Parser::drive(
                __StateMachine {
                    input,
                    errors,
                    __phantom: core::marker::PhantomData::<(&(), &())>,
                },
                __tokens,
            )
        }
    }
    fn __accepts<
        'input,
        'err,
    >(
        __error_state: Option<i8>,
        __states: &[i8],
        __opt_integer: Option<usize>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> bool
    where
        'input: 'err,
        'static: 'err,
    {
        let mut __states = __states.to_vec();
        __states.extend(__error_state);
        loop {
            let mut __states_len = __states.len();
            let __top = __states[__states_len - 1];
            let __action = match __opt_integer {
                None => __EOF_ACTION[__top as usize],
                Some(__integer) => __action(__top, __integer),
            };
            if __action == 0 { return false; }
            if __action > 0 { return true; }
            let (__to_pop, __nt) = match __simulate_reduce(-(__action + 1), core::marker::PhantomData::<(&(), &())>) {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop, nonterminal_produced
                } => (states_to_pop, nonterminal_produced),
                __state_machine::SimulatedReduce::Accept => return true,
            };
            __states_len -= __to_pop;
            __states.truncate(__states_len);
            let __top = __states[__states_len - 1];
            let __next_state = __goto(__top, __nt);
            __states.push(__next_state);
        }
    }
    fn __reduce<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __action: i8,
        __lookahead_start: Option<&usize>,
        __states: &mut alloc::vec::Vec<i8>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> Option<Result<Path,__lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>>>
    {
        let (__pop_states, __nonterminal) = match __action {
            0 => {
                __reduce0(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            1 => {
                __reduce1(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            2 => {
                __reduce2(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            3 => {
                __reduce3(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            4 => {
                __reduce4(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            5 => {
                __reduce5(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            6 => {
                __reduce6(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            7 => {
                __reduce7(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            8 => {
                __reduce8(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            9 => {
                __reduce9(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            10 => {
                __reduce10(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            11 => {
                __reduce11(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            12 => {
                __reduce12(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            13 => {
                __reduce13(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            14 => {
                __reduce14(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            15 => {
                __reduce15(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            16 => {
                __reduce16(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            17 => {
                __reduce17(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            18 => {
                __reduce18(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            19 => {
                __reduce19(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            20 => {
                __reduce20(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            21 => {
                __reduce21(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            22 => {
                // __Path = Path => ActionFn(1);
                let __sym0 = __pop_Variant6(__symbols);
                let __start = __sym0.0;
                let __end = __sym0.2;
                let __nt = super::__action1::<>(input, errors, __sym0);
                return Some(Ok(__nt));
            }
            23 => {
                __reduce23(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            24 => {
                __reduce24(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            25 => {
                __reduce25(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            _ => panic!("invalid action code {}", __action)
        };
        let __states_len = __states.len();
        __states.truncate(__states_len - __pop_states);
        let __state = *__states.last().unwrap();
        let __next_state = __goto(__state, __nonterminal);
        __states.push(__next_state);
        None
    }
    #[inline(never)]
    fn __symbol_type_mismatch() -> ! {
        panic!("symbol type mismatch")
    }
    fn __pop_Variant0<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, BorrowedToken<'input>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant0(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant2<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Ident, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant2(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant6<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Path, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant6(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant8<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, TopLevelStatement, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant8(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant9<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, UseTree, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant9(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant7<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Vec<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant7(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant3<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, alloc::vec::Vec<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant3(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant10<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, core::option::Option<BorrowedToken<'input>>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant10(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant5<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, core::option::Option<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant5(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant4<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, usize, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant4(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant1<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, &'input str, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant1(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __reduce0<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>) = "::", Ident => ActionFn(14);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action14::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (2, 0)
    }
    fn __reduce1<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)* =  => ActionFn(12);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action12::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (0, 1)
    }
    fn __reduce2<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)* = ("::" <Ident>)+ => ActionFn(13);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action13::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (1, 1)
    }
    fn __reduce3<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)+ = "::", Ident => ActionFn(23);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action23::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (2, 2)
    }
    fn __reduce4<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)+ = ("::" <Ident>)+, "::", Ident => ActionFn(24);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant2(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action24::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (3, 2)
    }
    fn __reduce5<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // @L =  => ActionFn(16);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action16::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant4(__nt), __end));
        (0, 3)
    }
    fn __reduce6<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // @R =  => ActionFn(15);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action15::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant4(__nt), __end));
        (0, 4)
    }
    fn __reduce7<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias = r#"[\\t\\r\\n ]+"#, "as", r#"[\\t\\r\\n ]+"#, Ident => ActionFn(8);
        assert!(__symbols.len() >= 4);
        let __sym3 = __pop_Variant2(__symbols);
        let __sym2 = __pop_Variant0(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym3.2;
        let __nt = super::__action8::<>(input, errors, __sym0, __sym1, __sym2, __sym3);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (4, 5)
    }
    fn __reduce8<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias? = Alias => ActionFn(17);
        let __sym0 = __pop_Variant2(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action17::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant5(__nt), __end));
        (1, 6)
    }
    fn __reduce9<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias? =  => ActionFn(18);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action18::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant5(__nt), __end));
        (0, 6)
    }
    fn __reduce10<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Bool = "true" => ActionFn(10);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action10::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant0(__nt), __end));
        (1, 7)
    }
    fn __reduce11<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Bool = "false" => ActionFn(11);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action11::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant0(__nt), __end));
        (1, 7)
    }
    fn __reduce12<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Ident = ident => ActionFn(33);
        let __sym0 = __pop_Variant1(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action33::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (1, 8)
    }
    fn __reduce13<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = "crate", "::", PathSegments => ActionFn(34);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant7(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action34::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (3, 9)
    }
    fn __reduce14<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = "dep", "::", PathSegments => ActionFn(35);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant7(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action35::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (3, 9)
    }
    fn __reduce15<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = Ident, PathSegments => ActionFn(36);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant7(__symbols);
        let __sym0 = __pop_Variant2(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action36::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (2, 9)
    }
    fn __reduce16<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // PathSegments =  => ActionFn(37);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action37::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant7(__nt), __end));
        (0, 10)
    }
    fn __reduce17<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // PathSegments = ("::" <Ident>)+ => ActionFn(38);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action38::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant7(__nt), __end));
        (1, 10)
    }
    fn __reduce18<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // TopLevelStatement = "use", r#"[\\t\\r\\n ]+"#, UseTree, ";", r#"[\\t\\r\\n ]+"#, EOF => ActionFn(41);
        assert!(__symbols.len() >= 6);
        let __sym5 = __pop_Variant0(__symbols);
        let __sym4 = __pop_Variant0(__symbols);
        let __sym3 = __pop_Variant0(__symbols);
        let __sym2 = __pop_Variant9(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym5.2;
        let __nt = super::__action41::<>(input, errors, __sym0, __sym1, __sym2, __sym3, __sym4, __sym5);
        __symbols.push((__start, __Symbol::Variant8(__nt), __end));
        (6, 11)
    }
    fn __reduce19<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // TopLevelStatement = "use", r#"[\\t\\r\\n ]+"#, UseTree, ";", EOF => ActionFn(42);
        assert!(__symbols.len() >= 5);
        let __sym4 = __pop_Variant0(__symbols);
        let __sym3 = __pop_Variant0(__symbols);
        let __sym2 = __pop_Variant9(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym4.2;
        let __nt = super::__action42::<>(input, errors, __sym0, __sym1, __sym2, __sym3, __sym4);
        __symbols.push((__start, __Symbol::Variant8(__nt), __end));
        (5, 11)
    }
    fn __reduce20<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // UseTree = Path, Alias => ActionFn(39);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant6(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action39::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant9(__nt), __end));
        (2, 12)
    }
    fn __reduce21<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // UseTree = Path => ActionFn(40);
        let __sym0 = __pop_Variant6(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action40::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant9(__nt), __end));
        (1, 12)
    }
    fn __reduce23<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // __TopLevelStatement = TopLevelStatement => ActionFn(0);
        let __sym0 = __pop_Variant8(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action0::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant8(__nt), __end));
        (1, 14)
    }
    fn __reduce24<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // r#"[\\t\\r\\n ]+"#? = r#"[\\t\\r\\n ]+"# => ActionFn(19);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action19::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant10(__nt), __end));
        (1, 15)
    }
    fn __reduce25<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // r#"[\\t\\r\\n ]+"#? =  => ActionFn(20);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action20::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant10(__nt), __end));
        (0, 15)
    }
}
#[allow(unused_imports)]
pub(crate) use self::__parse__Path::PathParser;

#[rustfmt::skip]
#[allow(non_snake_case, non_camel_case_types, unused_mut, unused_variables, unused_imports, unused_parens, clippy::needless_lifetimes, clippy::type_complexity, clippy::needless_return, clippy::too_many_arguments, clippy::never_loop, clippy::match_single_binding, clippy::needless_raw_string_hashes)]
mod __parse__TopLevelStatement {

    use noirc_errors::Span;
    use crate::lexer::token::BorrowedToken;
    use crate::lexer::token as noir_token;
    use crate::lexer::errors::LexerErrorKind;
    use crate::parser::TopLevelStatement;
    use crate::ast::{Ident, Path, PathKind, UseTree, UseTreeKind};
    use lalrpop_util::ErrorRecovery;
    #[allow(unused_extern_crates)]
    extern crate lalrpop_util as __lalrpop_util;
    #[allow(unused_imports)]
    use self::__lalrpop_util::state_machine as __state_machine;
    use core;
    extern crate alloc;
    use super::__ToTriple;
    #[allow(dead_code)]
    pub(crate) enum __Symbol<'input>
     {
        Variant0(BorrowedToken<'input>),
        Variant1(&'input str),
        Variant2(Ident),
        Variant3(alloc::vec::Vec<Ident>),
        Variant4(usize),
        Variant5(core::option::Option<Ident>),
        Variant6(Path),
        Variant7(Vec<Ident>),
        Variant8(TopLevelStatement),
        Variant9(UseTree),
        Variant10(core::option::Option<BorrowedToken<'input>>),
    }
    const __ACTION: &[i8] = &[
        // State 0
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 1
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0,
        // State 2
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, -17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -17, 0, 0, 0,
        // State 3
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 0, 0, 0,
        // State 4
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0,
        // State 5
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, -17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -17, 0, 0, 0,
        // State 6
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, -17, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -17, 0, 0, 0,
        // State 7
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0,
        // State 8
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0,
        // State 9
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 10
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0,
        // State 11
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 12
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 13
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 14
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -13, -13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -13, 0, 0, 0,
        // State 15
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, -18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -18, 0, 0, 0,
        // State 16
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -16, 0, 0, 0,
        // State 17
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 18
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 19
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 24, 0, 0,
        // State 20
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -4, -4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -4, 0, 0, 0,
        // State 21
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0,
        // State 22
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0,
        // State 23
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 24
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -14, 0, 0, 0,
        // State 25
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -15, 0, 0, 0,
        // State 26
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -5, -5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -5, 0, 0, 0,
        // State 27
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        // State 28
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ];
    fn __action(state: i8, integer: usize) -> i8 {
        __ACTION[(state as usize) * 75 + integer]
    }
    const __EOF_ACTION: &[i8] = &[
        // State 0
        0,
        // State 1
        0,
        // State 2
        0,
        // State 3
        0,
        // State 4
        0,
        // State 5
        0,
        // State 6
        0,
        // State 7
        0,
        // State 8
        0,
        // State 9
        -24,
        // State 10
        0,
        // State 11
        0,
        // State 12
        0,
        // State 13
        0,
        // State 14
        0,
        // State 15
        0,
        // State 16
        0,
        // State 17
        0,
        // State 18
        0,
        // State 19
        0,
        // State 20
        0,
        // State 21
        0,
        // State 22
        0,
        // State 23
        -20,
        // State 24
        0,
        // State 25
        0,
        // State 26
        0,
        // State 27
        -19,
        // State 28
        0,
    ];
    fn __goto(state: i8, nt: usize) -> i8 {
        match nt {
            2 => 15,
            5 => 17,
            8 => match state {
                4 => 20,
                7 => 26,
                8 => 28,
                _ => 2,
            },
            9 => 3,
            10 => match state {
                5 => 24,
                6 => 25,
                _ => 16,
            },
            11 => 9,
            12 => 11,
            _ => 0,
        }
    }
    const __TERMINAL: &[&str] = &[
        r###""!""###,
        r###""!=""###,
        r###""#""###,
        r###""%""###,
        r###""&""###,
        r###""(""###,
        r###"")""###,
        r###""*""###,
        r###""+""###,
        r###"",""###,
        r###""-""###,
        r###""->""###,
        r###"".""###,
        r###""..""###,
        r###""/""###,
        r###"":""###,
        r###""::""###,
        r###"";""###,
        r###""<""###,
        r###""<<""###,
        r###""<=""###,
        r###""=""###,
        r###""==""###,
        r###"">""###,
        r###"">=""###,
        r###"">>""###,
        r###""Field""###,
        r###""[""###,
        r###""]""###,
        r###""^""###,
        r###""as""###,
        r###""assert""###,
        r###""assert_eq""###,
        r###""bool""###,
        r###""break""###,
        r###""call_data""###,
        r###""char""###,
        r###""comptime""###,
        r###""constrain""###,
        r###""continue""###,
        r###""contract""###,
        r###""crate""###,
        r###""dep""###,
        r###""else""###,
        r###""false""###,
        r###""fmtstr""###,
        r###""fn""###,
        r###""for""###,
        r###""global""###,
        r###""if""###,
        r###""impl""###,
        r###""in""###,
        r###""let""###,
        r###""mod""###,
        r###""mut""###,
        r###""pub""###,
        r###""return""###,
        r###""return_data""###,
        r###""str""###,
        r###""struct""###,
        r###""trait""###,
        r###""true""###,
        r###""type""###,
        r###""unchecked""###,
        r###""unconstrained""###,
        r###""use""###,
        r###""where""###,
        r###""while""###,
        r###""{""###,
        r###""|""###,
        r###""}""###,
        r###"r#"[\\t\\r\\n ]+"#"###,
        r###"EOF"###,
        r###"ident"###,
        r###"string"###,
    ];
    fn __expected_tokens(__state: i8) -> alloc::vec::Vec<alloc::string::String> {
        __TERMINAL.iter().enumerate().filter_map(|(index, terminal)| {
            let next_state = __action(__state, index);
            if next_state == 0 {
                None
            } else {
                Some(alloc::string::ToString::to_string(terminal))
            }
        }).collect()
    }
    fn __expected_tokens_from_states<
        'input,
        'err,
    >(
        __states: &[i8],
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> alloc::vec::Vec<alloc::string::String>
    where
        'input: 'err,
        'static: 'err,
    {
        __TERMINAL.iter().enumerate().filter_map(|(index, terminal)| {
            if __accepts(None, __states, Some(index), core::marker::PhantomData::<(&(), &())>) {
                Some(alloc::string::ToString::to_string(terminal))
            } else {
                None
            }
        }).collect()
    }
    struct __StateMachine<'input, 'err>
    where 'input: 'err, 'static: 'err
    {
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __phantom: core::marker::PhantomData<(&'input (), &'err ())>,
    }
    impl<'input, 'err> __state_machine::ParserDefinition for __StateMachine<'input, 'err>
    where 'input: 'err, 'static: 'err
    {
        type Location = usize;
        type Error = LexerErrorKind;
        type Token = BorrowedToken<'input>;
        type TokenIndex = usize;
        type Symbol = __Symbol<'input>;
        type Success = TopLevelStatement;
        type StateIndex = i8;
        type Action = i8;
        type ReduceIndex = i8;
        type NonterminalIndex = usize;

        #[inline]
        fn start_location(&self) -> Self::Location {
              Default::default()
        }

        #[inline]
        fn start_state(&self) -> Self::StateIndex {
              0
        }

        #[inline]
        fn token_to_index(&self, token: &Self::Token) -> Option<usize> {
            __token_to_integer(token, core::marker::PhantomData::<(&(), &())>)
        }

        #[inline]
        fn action(&self, state: i8, integer: usize) -> i8 {
            __action(state, integer)
        }

        #[inline]
        fn error_action(&self, state: i8) -> i8 {
            __action(state, 75 - 1)
        }

        #[inline]
        fn eof_action(&self, state: i8) -> i8 {
            __EOF_ACTION[state as usize]
        }

        #[inline]
        fn goto(&self, state: i8, nt: usize) -> i8 {
            __goto(state, nt)
        }

        fn token_to_symbol(&self, token_index: usize, token: Self::Token) -> Self::Symbol {
            __token_to_symbol(token_index, token, core::marker::PhantomData::<(&(), &())>)
        }

        fn expected_tokens(&self, state: i8) -> alloc::vec::Vec<alloc::string::String> {
            __expected_tokens(state)
        }

        fn expected_tokens_from_states(&self, states: &[i8]) -> alloc::vec::Vec<alloc::string::String> {
            __expected_tokens_from_states(states, core::marker::PhantomData::<(&(), &())>)
        }

        #[inline]
        fn uses_error_recovery(&self) -> bool {
            false
        }

        #[inline]
        fn error_recovery_symbol(
            &self,
            recovery: __state_machine::ErrorRecovery<Self>,
        ) -> Self::Symbol {
            panic!("error recovery not enabled for this grammar")
        }

        fn reduce(
            &mut self,
            action: i8,
            start_location: Option<&Self::Location>,
            states: &mut alloc::vec::Vec<i8>,
            symbols: &mut alloc::vec::Vec<__state_machine::SymbolTriple<Self>>,
        ) -> Option<__state_machine::ParseResult<Self>> {
            __reduce(
                self.input,
                self.errors,
                action,
                start_location,
                states,
                symbols,
                core::marker::PhantomData::<(&(), &())>,
            )
        }

        fn simulate_reduce(&self, action: i8) -> __state_machine::SimulatedReduce<Self> {
            __simulate_reduce(action, core::marker::PhantomData::<(&(), &())>)
        }
    }
    fn __token_to_integer<
        'input,
        'err,
    >(
        __token: &BorrowedToken<'input>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> Option<usize>
    {
        match *__token {
            BorrowedToken::Bang if true => Some(0),
            BorrowedToken::NotEqual if true => Some(1),
            BorrowedToken::Pound if true => Some(2),
            BorrowedToken::Percent if true => Some(3),
            BorrowedToken::Ampersand if true => Some(4),
            BorrowedToken::LeftParen if true => Some(5),
            BorrowedToken::RightParen if true => Some(6),
            BorrowedToken::Star if true => Some(7),
            BorrowedToken::Plus if true => Some(8),
            BorrowedToken::Comma if true => Some(9),
            BorrowedToken::Minus if true => Some(10),
            BorrowedToken::Arrow if true => Some(11),
            BorrowedToken::Dot if true => Some(12),
            BorrowedToken::DoubleDot if true => Some(13),
            BorrowedToken::Slash if true => Some(14),
            BorrowedToken::Colon if true => Some(15),
            BorrowedToken::DoubleColon if true => Some(16),
            BorrowedToken::Semicolon if true => Some(17),
            BorrowedToken::Less if true => Some(18),
            BorrowedToken::ShiftLeft if true => Some(19),
            BorrowedToken::LessEqual if true => Some(20),
            BorrowedToken::Assign if true => Some(21),
            BorrowedToken::Equal if true => Some(22),
            BorrowedToken::Greater if true => Some(23),
            BorrowedToken::GreaterEqual if true => Some(24),
            BorrowedToken::ShiftRight if true => Some(25),
            BorrowedToken::Keyword(noir_token::Keyword::Field) if true => Some(26),
            BorrowedToken::LeftBracket if true => Some(27),
            BorrowedToken::RightBracket if true => Some(28),
            BorrowedToken::Caret if true => Some(29),
            BorrowedToken::Keyword(noir_token::Keyword::As) if true => Some(30),
            BorrowedToken::Keyword(noir_token::Keyword::Assert) if true => Some(31),
            BorrowedToken::Keyword(noir_token::Keyword::AssertEq) if true => Some(32),
            BorrowedToken::Keyword(noir_token::Keyword::Bool) if true => Some(33),
            BorrowedToken::Keyword(noir_token::Keyword::Break) if true => Some(34),
            BorrowedToken::Keyword(noir_token::Keyword::CallData) if true => Some(35),
            BorrowedToken::Keyword(noir_token::Keyword::Char) if true => Some(36),
            BorrowedToken::Keyword(noir_token::Keyword::Comptime) if true => Some(37),
            BorrowedToken::Keyword(noir_token::Keyword::Constrain) if true => Some(38),
            BorrowedToken::Keyword(noir_token::Keyword::Continue) if true => Some(39),
            BorrowedToken::Keyword(noir_token::Keyword::Contract) if true => Some(40),
            BorrowedToken::Keyword(noir_token::Keyword::Crate) if true => Some(41),
            BorrowedToken::Keyword(noir_token::Keyword::Dep) if true => Some(42),
            BorrowedToken::Keyword(noir_token::Keyword::Else) if true => Some(43),
            BorrowedToken::Bool(false) if true => Some(44),
            BorrowedToken::Keyword(noir_token::Keyword::FormatString) if true => Some(45),
            BorrowedToken::Keyword(noir_token::Keyword::Fn) if true => Some(46),
            BorrowedToken::Keyword(noir_token::Keyword::For) if true => Some(47),
            BorrowedToken::Keyword(noir_token::Keyword::Global) if true => Some(48),
            BorrowedToken::Keyword(noir_token::Keyword::If) if true => Some(49),
            BorrowedToken::Keyword(noir_token::Keyword::Impl) if true => Some(50),
            BorrowedToken::Keyword(noir_token::Keyword::In) if true => Some(51),
            BorrowedToken::Keyword(noir_token::Keyword::Let) if true => Some(52),
            BorrowedToken::Keyword(noir_token::Keyword::Mod) if true => Some(53),
            BorrowedToken::Keyword(noir_token::Keyword::Mut) if true => Some(54),
            BorrowedToken::Keyword(noir_token::Keyword::Pub) if true => Some(55),
            BorrowedToken::Keyword(noir_token::Keyword::Return) if true => Some(56),
            BorrowedToken::Keyword(noir_token::Keyword::ReturnData) if true => Some(57),
            BorrowedToken::Keyword(noir_token::Keyword::String) if true => Some(58),
            BorrowedToken::Keyword(noir_token::Keyword::Struct) if true => Some(59),
            BorrowedToken::Keyword(noir_token::Keyword::Trait) if true => Some(60),
            BorrowedToken::Bool(true) if true => Some(61),
            BorrowedToken::Keyword(noir_token::Keyword::Type) if true => Some(62),
            BorrowedToken::Keyword(noir_token::Keyword::Unchecked) if true => Some(63),
            BorrowedToken::Keyword(noir_token::Keyword::Unconstrained) if true => Some(64),
            BorrowedToken::Keyword(noir_token::Keyword::Use) if true => Some(65),
            BorrowedToken::Keyword(noir_token::Keyword::Where) if true => Some(66),
            BorrowedToken::Keyword(noir_token::Keyword::While) if true => Some(67),
            BorrowedToken::LeftBrace if true => Some(68),
            BorrowedToken::Pipe if true => Some(69),
            BorrowedToken::RightBrace if true => Some(70),
            BorrowedToken::Whitespace(_) if true => Some(71),
            BorrowedToken::EOF if true => Some(72),
            BorrowedToken::Ident(_) if true => Some(73),
            BorrowedToken::Str(_) if true => Some(74),
            _ => None,
        }
    }
    fn __token_to_symbol<
        'input,
        'err,
    >(
        __token_index: usize,
        __token: BorrowedToken<'input>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> __Symbol<'input>
    {
        #[allow(clippy::manual_range_patterns)]match __token_index {
            0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70 | 71 | 72 => __Symbol::Variant0(__token),
            73 | 74 => match __token {
                BorrowedToken::Ident(__tok0) | BorrowedToken::Str(__tok0) if true => __Symbol::Variant1(__tok0),
                _ => unreachable!(),
            },
            _ => unreachable!(),
        }
    }
    fn __simulate_reduce<
        'input,
        'err,
    >(
        __reduce_index: i8,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> __state_machine::SimulatedReduce<__StateMachine<'input, 'err>>
    where
        'input: 'err,
        'static: 'err,
    {
        match __reduce_index {
            0 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 0,
                }
            }
            1 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 1,
                }
            }
            2 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 1,
                }
            }
            3 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 2,
                }
            }
            4 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 2,
                }
            }
            5 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 3,
                }
            }
            6 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 4,
                }
            }
            7 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 4,
                    nonterminal_produced: 5,
                }
            }
            8 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 6,
                }
            }
            9 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 6,
                }
            }
            10 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 7,
                }
            }
            11 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 7,
                }
            }
            12 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 8,
                }
            }
            13 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 9,
                }
            }
            14 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 3,
                    nonterminal_produced: 9,
                }
            }
            15 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 9,
                }
            }
            16 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 10,
                }
            }
            17 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 10,
                }
            }
            18 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 6,
                    nonterminal_produced: 11,
                }
            }
            19 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 5,
                    nonterminal_produced: 11,
                }
            }
            20 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 2,
                    nonterminal_produced: 12,
                }
            }
            21 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 12,
                }
            }
            22 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 13,
                }
            }
            23 => __state_machine::SimulatedReduce::Accept,
            24 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 1,
                    nonterminal_produced: 15,
                }
            }
            25 => {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop: 0,
                    nonterminal_produced: 15,
                }
            }
            _ => panic!("invalid reduction index {}", __reduce_index)
        }
    }
    pub(crate) struct TopLevelStatementParser {
        _priv: (),
    }

    impl Default for TopLevelStatementParser { fn default() -> Self { Self::new() } }
    impl TopLevelStatementParser {
        pub(crate) fn new() -> TopLevelStatementParser {
            TopLevelStatementParser {
                _priv: (),
            }
        }

        #[allow(dead_code)]
        pub(crate) fn parse<
            'input,
            'err,
            __TOKEN: __ToTriple<'input, 'err, >,
            __TOKENS: IntoIterator<Item=__TOKEN>,
        >(
            &self,
            input: &'input str,
            errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
            __tokens0: __TOKENS,
        ) -> Result<TopLevelStatement, __lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>>
        {
            let __tokens = __tokens0.into_iter();
            let mut __tokens = __tokens.map(|t| __ToTriple::to_triple(t));
            __state_machine::Parser::drive(
                __StateMachine {
                    input,
                    errors,
                    __phantom: core::marker::PhantomData::<(&(), &())>,
                },
                __tokens,
            )
        }
    }
    fn __accepts<
        'input,
        'err,
    >(
        __error_state: Option<i8>,
        __states: &[i8],
        __opt_integer: Option<usize>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> bool
    where
        'input: 'err,
        'static: 'err,
    {
        let mut __states = __states.to_vec();
        __states.extend(__error_state);
        loop {
            let mut __states_len = __states.len();
            let __top = __states[__states_len - 1];
            let __action = match __opt_integer {
                None => __EOF_ACTION[__top as usize],
                Some(__integer) => __action(__top, __integer),
            };
            if __action == 0 { return false; }
            if __action > 0 { return true; }
            let (__to_pop, __nt) = match __simulate_reduce(-(__action + 1), core::marker::PhantomData::<(&(), &())>) {
                __state_machine::SimulatedReduce::Reduce {
                    states_to_pop, nonterminal_produced
                } => (states_to_pop, nonterminal_produced),
                __state_machine::SimulatedReduce::Accept => return true,
            };
            __states_len -= __to_pop;
            __states.truncate(__states_len);
            let __top = __states[__states_len - 1];
            let __next_state = __goto(__top, __nt);
            __states.push(__next_state);
        }
    }
    fn __reduce<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __action: i8,
        __lookahead_start: Option<&usize>,
        __states: &mut alloc::vec::Vec<i8>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> Option<Result<TopLevelStatement,__lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>>>
    {
        let (__pop_states, __nonterminal) = match __action {
            0 => {
                __reduce0(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            1 => {
                __reduce1(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            2 => {
                __reduce2(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            3 => {
                __reduce3(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            4 => {
                __reduce4(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            5 => {
                __reduce5(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            6 => {
                __reduce6(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            7 => {
                __reduce7(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            8 => {
                __reduce8(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            9 => {
                __reduce9(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            10 => {
                __reduce10(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            11 => {
                __reduce11(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            12 => {
                __reduce12(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            13 => {
                __reduce13(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            14 => {
                __reduce14(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            15 => {
                __reduce15(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            16 => {
                __reduce16(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            17 => {
                __reduce17(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            18 => {
                __reduce18(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            19 => {
                __reduce19(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            20 => {
                __reduce20(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            21 => {
                __reduce21(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            22 => {
                __reduce22(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            23 => {
                // __TopLevelStatement = TopLevelStatement => ActionFn(0);
                let __sym0 = __pop_Variant8(__symbols);
                let __start = __sym0.0;
                let __end = __sym0.2;
                let __nt = super::__action0::<>(input, errors, __sym0);
                return Some(Ok(__nt));
            }
            24 => {
                __reduce24(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            25 => {
                __reduce25(input, errors, __lookahead_start, __symbols, core::marker::PhantomData::<(&(), &())>)
            }
            _ => panic!("invalid action code {}", __action)
        };
        let __states_len = __states.len();
        __states.truncate(__states_len - __pop_states);
        let __state = *__states.last().unwrap();
        let __next_state = __goto(__state, __nonterminal);
        __states.push(__next_state);
        None
    }
    #[inline(never)]
    fn __symbol_type_mismatch() -> ! {
        panic!("symbol type mismatch")
    }
    fn __pop_Variant0<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, BorrowedToken<'input>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant0(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant2<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Ident, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant2(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant6<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Path, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant6(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant8<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, TopLevelStatement, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant8(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant9<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, UseTree, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant9(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant7<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, Vec<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant7(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant3<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, alloc::vec::Vec<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant3(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant10<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, core::option::Option<BorrowedToken<'input>>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant10(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant5<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, core::option::Option<Ident>, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant5(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant4<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, usize, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant4(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __pop_Variant1<
      'input,
    >(
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>
    ) -> (usize, &'input str, usize)
     {
        match __symbols.pop() {
            Some((__l, __Symbol::Variant1(__v), __r)) => (__l, __v, __r),
            _ => __symbol_type_mismatch()
        }
    }
    fn __reduce0<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>) = "::", Ident => ActionFn(14);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action14::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (2, 0)
    }
    fn __reduce1<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)* =  => ActionFn(12);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action12::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (0, 1)
    }
    fn __reduce2<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)* = ("::" <Ident>)+ => ActionFn(13);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action13::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (1, 1)
    }
    fn __reduce3<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)+ = "::", Ident => ActionFn(23);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action23::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (2, 2)
    }
    fn __reduce4<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // ("::" <Ident>)+ = ("::" <Ident>)+, "::", Ident => ActionFn(24);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant2(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action24::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant3(__nt), __end));
        (3, 2)
    }
    fn __reduce5<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // @L =  => ActionFn(16);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action16::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant4(__nt), __end));
        (0, 3)
    }
    fn __reduce6<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // @R =  => ActionFn(15);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action15::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant4(__nt), __end));
        (0, 4)
    }
    fn __reduce7<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias = r#"[\\t\\r\\n ]+"#, "as", r#"[\\t\\r\\n ]+"#, Ident => ActionFn(8);
        assert!(__symbols.len() >= 4);
        let __sym3 = __pop_Variant2(__symbols);
        let __sym2 = __pop_Variant0(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym3.2;
        let __nt = super::__action8::<>(input, errors, __sym0, __sym1, __sym2, __sym3);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (4, 5)
    }
    fn __reduce8<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias? = Alias => ActionFn(17);
        let __sym0 = __pop_Variant2(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action17::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant5(__nt), __end));
        (1, 6)
    }
    fn __reduce9<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Alias? =  => ActionFn(18);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action18::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant5(__nt), __end));
        (0, 6)
    }
    fn __reduce10<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Bool = "true" => ActionFn(10);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action10::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant0(__nt), __end));
        (1, 7)
    }
    fn __reduce11<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Bool = "false" => ActionFn(11);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action11::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant0(__nt), __end));
        (1, 7)
    }
    fn __reduce12<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Ident = ident => ActionFn(33);
        let __sym0 = __pop_Variant1(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action33::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant2(__nt), __end));
        (1, 8)
    }
    fn __reduce13<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = "crate", "::", PathSegments => ActionFn(34);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant7(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action34::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (3, 9)
    }
    fn __reduce14<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = "dep", "::", PathSegments => ActionFn(35);
        assert!(__symbols.len() >= 3);
        let __sym2 = __pop_Variant7(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym2.2;
        let __nt = super::__action35::<>(input, errors, __sym0, __sym1, __sym2);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (3, 9)
    }
    fn __reduce15<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // Path = Ident, PathSegments => ActionFn(36);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant7(__symbols);
        let __sym0 = __pop_Variant2(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action36::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (2, 9)
    }
    fn __reduce16<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // PathSegments =  => ActionFn(37);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action37::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant7(__nt), __end));
        (0, 10)
    }
    fn __reduce17<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // PathSegments = ("::" <Ident>)+ => ActionFn(38);
        let __sym0 = __pop_Variant3(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action38::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant7(__nt), __end));
        (1, 10)
    }
    fn __reduce18<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // TopLevelStatement = "use", r#"[\\t\\r\\n ]+"#, UseTree, ";", r#"[\\t\\r\\n ]+"#, EOF => ActionFn(41);
        assert!(__symbols.len() >= 6);
        let __sym5 = __pop_Variant0(__symbols);
        let __sym4 = __pop_Variant0(__symbols);
        let __sym3 = __pop_Variant0(__symbols);
        let __sym2 = __pop_Variant9(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym5.2;
        let __nt = super::__action41::<>(input, errors, __sym0, __sym1, __sym2, __sym3, __sym4, __sym5);
        __symbols.push((__start, __Symbol::Variant8(__nt), __end));
        (6, 11)
    }
    fn __reduce19<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // TopLevelStatement = "use", r#"[\\t\\r\\n ]+"#, UseTree, ";", EOF => ActionFn(42);
        assert!(__symbols.len() >= 5);
        let __sym4 = __pop_Variant0(__symbols);
        let __sym3 = __pop_Variant0(__symbols);
        let __sym2 = __pop_Variant9(__symbols);
        let __sym1 = __pop_Variant0(__symbols);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym4.2;
        let __nt = super::__action42::<>(input, errors, __sym0, __sym1, __sym2, __sym3, __sym4);
        __symbols.push((__start, __Symbol::Variant8(__nt), __end));
        (5, 11)
    }
    fn __reduce20<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // UseTree = Path, Alias => ActionFn(39);
        assert!(__symbols.len() >= 2);
        let __sym1 = __pop_Variant2(__symbols);
        let __sym0 = __pop_Variant6(__symbols);
        let __start = __sym0.0;
        let __end = __sym1.2;
        let __nt = super::__action39::<>(input, errors, __sym0, __sym1);
        __symbols.push((__start, __Symbol::Variant9(__nt), __end));
        (2, 12)
    }
    fn __reduce21<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // UseTree = Path => ActionFn(40);
        let __sym0 = __pop_Variant6(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action40::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant9(__nt), __end));
        (1, 12)
    }
    fn __reduce22<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // __Path = Path => ActionFn(1);
        let __sym0 = __pop_Variant6(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action1::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant6(__nt), __end));
        (1, 13)
    }
    fn __reduce24<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // r#"[\\t\\r\\n ]+"#? = r#"[\\t\\r\\n ]+"# => ActionFn(19);
        let __sym0 = __pop_Variant0(__symbols);
        let __start = __sym0.0;
        let __end = __sym0.2;
        let __nt = super::__action19::<>(input, errors, __sym0);
        __symbols.push((__start, __Symbol::Variant10(__nt), __end));
        (1, 15)
    }
    fn __reduce25<
        'input,
        'err,
    >(
        input: &'input str,
        errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
        __lookahead_start: Option<&usize>,
        __symbols: &mut alloc::vec::Vec<(usize,__Symbol<'input>,usize)>,
        _: core::marker::PhantomData<(&'input (), &'err ())>,
    ) -> (usize, usize)
    {
        // r#"[\\t\\r\\n ]+"#? =  => ActionFn(20);
        let __start = __lookahead_start.cloned().or_else(|| __symbols.last().map(|s| s.2)).unwrap_or_default();
        let __end = __start;
        let __nt = super::__action20::<>(input, errors, &__start, &__end);
        __symbols.push((__start, __Symbol::Variant10(__nt), __end));
        (0, 15)
    }
}
#[allow(unused_imports)]
pub(crate) use self::__parse__TopLevelStatement::TopLevelStatementParser;

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action0<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, TopLevelStatement, usize),
) -> TopLevelStatement
{
    __0
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action1<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, Path, usize),
) -> Path
{
    __0
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action2<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, use_tree, _): (usize, UseTree, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, trailing_spaces, _): (usize, core::option::Option<BorrowedToken<'input>>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
) -> TopLevelStatement
{
    {
        TopLevelStatement::Import(use_tree)
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action3<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, mut prefix, _): (usize, Path, usize),
    (_, alias, _): (usize, core::option::Option<Ident>, usize),
) -> UseTree
{
    {
        let ident = prefix.pop();
        let kind = UseTreeKind::Path(ident, alias);
        UseTree { prefix, kind }
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action4<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, lo, _): (usize, usize, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, segments, _): (usize, Vec<Ident>, usize),
    (_, hi, _): (usize, usize, usize),
) -> Path
{
    {
        let kind = PathKind::Crate;
        let span = Span::from(lo as u32..hi as u32);
        Path { segments, kind, span }
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action5<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, lo, _): (usize, usize, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, segments, _): (usize, Vec<Ident>, usize),
    (_, hi, _): (usize, usize, usize),
) -> Path
{
    {
        let kind = PathKind::Plain;
        let span = Span::from(lo as u32..hi as u32);
        Path { segments, kind, span }
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action6<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, lo, _): (usize, usize, usize),
    (_, id, _): (usize, Ident, usize),
    (_, mut segments, _): (usize, Vec<Ident>, usize),
    (_, hi, _): (usize, usize, usize),
) -> Path
{
    {
        segments.insert(0, id);
        let kind = PathKind::Plain;
        let span = Span::from(lo as u32..hi as u32);
        Path { segments, kind, span }
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action7<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, lo, _): (usize, usize, usize),
    (_, segments, _): (usize, alloc::vec::Vec<Ident>, usize),
    (_, hi, _): (usize, usize, usize),
) -> Vec<Ident>
{
    {
        segments
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action8<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, __0, _): (usize, Ident, usize),
) -> Ident
{
    __0
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action9<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, lo, _): (usize, usize, usize),
    (_, i, _): (usize, &'input str, usize),
    (_, hi, _): (usize, usize, usize),
) -> Ident
{
    {
        let token = noir_token::Token::Ident(i.to_string());
        let span = Span::from(lo as u32..hi as u32);
        Ident::from_token(token, span)
    }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action10<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, BorrowedToken<'input>, usize),
) -> BorrowedToken<'input>
{
    BorrowedToken::Bool(true)
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action11<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, BorrowedToken<'input>, usize),
) -> BorrowedToken<'input>
{
    BorrowedToken::Bool(false)
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action12<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> alloc::vec::Vec<Ident>
{
    alloc::vec![]
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action13<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, v, _): (usize, alloc::vec::Vec<Ident>, usize),
) -> alloc::vec::Vec<Ident>
{
    v
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action14<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, _, _): (usize, BorrowedToken<'input>, usize),
    (_, __0, _): (usize, Ident, usize),
) -> Ident
{
    __0
}

#[allow(unused_variables)]
fn __action15<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> usize
{
    *__lookbehind
}

#[allow(unused_variables)]
fn __action16<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> usize
{
    *__lookahead
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action17<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, Ident, usize),
) -> core::option::Option<Ident>
{
    Some(__0)
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action18<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> core::option::Option<Ident>
{
    None
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action19<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, BorrowedToken<'input>, usize),
) -> core::option::Option<BorrowedToken<'input>>
{
    Some(__0)
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action20<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> core::option::Option<BorrowedToken<'input>>
{
    None
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action21<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, __0, _): (usize, Ident, usize),
) -> alloc::vec::Vec<Ident>
{
    alloc::vec![__0]
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes, clippy::just_underscores_and_digits)]
fn __action22<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    (_, v, _): (usize, alloc::vec::Vec<Ident>, usize),
    (_, e, _): (usize, Ident, usize),
) -> alloc::vec::Vec<Ident>
{
    { let mut v = v; v.push(e); v }
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action23<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, Ident, usize),
) -> alloc::vec::Vec<Ident>
{
    let __start0 = __0.0;
    let __end0 = __1.2;
    let __temp0 = __action14(
        input,
        errors,
        __0,
        __1,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action21(
        input,
        errors,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action24<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, alloc::vec::Vec<Ident>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, Ident, usize),
) -> alloc::vec::Vec<Ident>
{
    let __start0 = __1.0;
    let __end0 = __2.2;
    let __temp0 = __action14(
        input,
        errors,
        __1,
        __2,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action22(
        input,
        errors,
        __0,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action25<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, usize, usize),
    __1: (usize, usize, usize),
) -> Vec<Ident>
{
    let __start0 = __0.2;
    let __end0 = __1.0;
    let __temp0 = __action12(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action7(
        input,
        errors,
        __0,
        __temp0,
        __1,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action26<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, usize, usize),
    __1: (usize, alloc::vec::Vec<Ident>, usize),
    __2: (usize, usize, usize),
) -> Vec<Ident>
{
    let __start0 = __1.0;
    let __end0 = __1.2;
    let __temp0 = __action13(
        input,
        errors,
        __1,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action7(
        input,
        errors,
        __0,
        __temp0,
        __2,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action27<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, &'input str, usize),
    __1: (usize, usize, usize),
) -> Ident
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action9(
        input,
        errors,
        __temp0,
        __0,
        __1,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action28<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, Vec<Ident>, usize),
    __3: (usize, usize, usize),
) -> Path
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action4(
        input,
        errors,
        __temp0,
        __0,
        __1,
        __2,
        __3,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action29<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, Vec<Ident>, usize),
    __3: (usize, usize, usize),
) -> Path
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action5(
        input,
        errors,
        __temp0,
        __0,
        __1,
        __2,
        __3,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action30<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, Ident, usize),
    __1: (usize, Vec<Ident>, usize),
    __2: (usize, usize, usize),
) -> Path
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action6(
        input,
        errors,
        __temp0,
        __0,
        __1,
        __2,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action31<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, usize, usize),
) -> Vec<Ident>
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action25(
        input,
        errors,
        __temp0,
        __0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action32<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, alloc::vec::Vec<Ident>, usize),
    __1: (usize, usize, usize),
) -> Vec<Ident>
{
    let __start0 = __0.0;
    let __end0 = __0.0;
    let __temp0 = __action16(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action26(
        input,
        errors,
        __temp0,
        __0,
        __1,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action33<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, &'input str, usize),
) -> Ident
{
    let __start0 = __0.2;
    let __end0 = __0.2;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action27(
        input,
        errors,
        __0,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action34<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, Vec<Ident>, usize),
) -> Path
{
    let __start0 = __2.2;
    let __end0 = __2.2;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action28(
        input,
        errors,
        __0,
        __1,
        __2,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action35<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, Vec<Ident>, usize),
) -> Path
{
    let __start0 = __2.2;
    let __end0 = __2.2;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action29(
        input,
        errors,
        __0,
        __1,
        __2,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action36<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, Ident, usize),
    __1: (usize, Vec<Ident>, usize),
) -> Path
{
    let __start0 = __1.2;
    let __end0 = __1.2;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action30(
        input,
        errors,
        __0,
        __1,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action37<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __lookbehind: &usize,
    __lookahead: &usize,
) -> Vec<Ident>
{
    let __start0 = *__lookbehind;
    let __end0 = *__lookahead;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action31(
        input,
        errors,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action38<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, alloc::vec::Vec<Ident>, usize),
) -> Vec<Ident>
{
    let __start0 = __0.2;
    let __end0 = __0.2;
    let __temp0 = __action15(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action32(
        input,
        errors,
        __0,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action39<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, Path, usize),
    __1: (usize, Ident, usize),
) -> UseTree
{
    let __start0 = __1.0;
    let __end0 = __1.2;
    let __temp0 = __action17(
        input,
        errors,
        __1,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action3(
        input,
        errors,
        __0,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action40<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, Path, usize),
) -> UseTree
{
    let __start0 = __0.2;
    let __end0 = __0.2;
    let __temp0 = __action18(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action3(
        input,
        errors,
        __0,
        __temp0,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action41<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, UseTree, usize),
    __3: (usize, BorrowedToken<'input>, usize),
    __4: (usize, BorrowedToken<'input>, usize),
    __5: (usize, BorrowedToken<'input>, usize),
) -> TopLevelStatement
{
    let __start0 = __4.0;
    let __end0 = __4.2;
    let __temp0 = __action19(
        input,
        errors,
        __4,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action2(
        input,
        errors,
        __0,
        __1,
        __2,
        __3,
        __temp0,
        __5,
    )
}

#[allow(unused_variables)]
#[allow(clippy::too_many_arguments, clippy::needless_lifetimes,
    clippy::just_underscores_and_digits)]
fn __action42<
    'input,
    'err,
>(
    input: &'input str,
    errors: &'err mut [ErrorRecovery<usize, BorrowedToken<'input>, &'static str>],
    __0: (usize, BorrowedToken<'input>, usize),
    __1: (usize, BorrowedToken<'input>, usize),
    __2: (usize, UseTree, usize),
    __3: (usize, BorrowedToken<'input>, usize),
    __4: (usize, BorrowedToken<'input>, usize),
) -> TopLevelStatement
{
    let __start0 = __3.2;
    let __end0 = __4.0;
    let __temp0 = __action20(
        input,
        errors,
        &__start0,
        &__end0,
    );
    let __temp0 = (__start0, __temp0, __end0);
    __action2(
        input,
        errors,
        __0,
        __1,
        __2,
        __3,
        __temp0,
        __4,
    )
}
#[allow(clippy::type_complexity, dead_code)]

pub(crate)  trait __ToTriple<'input, 'err, >
{
    fn to_triple(value: Self) -> Result<(usize,BorrowedToken<'input>,usize), __lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>>;
}

impl<'input, 'err, > __ToTriple<'input, 'err, > for (usize, BorrowedToken<'input>, usize)
{
    fn to_triple(value: Self) -> Result<(usize,BorrowedToken<'input>,usize), __lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>> {
        Ok(value)
    }
}
impl<'input, 'err, > __ToTriple<'input, 'err, > for Result<(usize, BorrowedToken<'input>, usize), LexerErrorKind>
{
    fn to_triple(value: Self) -> Result<(usize,BorrowedToken<'input>,usize), __lalrpop_util::ParseError<usize, BorrowedToken<'input>, LexerErrorKind>> {
        match value {
            Ok(v) => Ok(v),
            Err(error) => Err(__lalrpop_util::ParseError::User { error }),
        }
    }
}
