# parsec

A Parsec-style parser combinator library for Carp.

## Install

```clojure
(load "git@github.com:carpentry-org/parsec@0.6.1")
```

## Example

```clojure
(let [p (Parser.between (Parser.byte \[)
                        (Parser.byte \])
                        (Parser.Lexer.integer))]
  (match (Parser.parse p "[42]")
    (Result.Success n) (println* &n)
    (Result.Error e)   (IO.errorln &(Parser.format-error &e))))
```

`Parser.parse` is strict, the parser must consume the whole input.

For a step-by-step walk-through building an arithmetic expression
parser from scratch, see [the tutorial](https://carpentry.dev/parsec/Tutorial.html).
For caveats and idioms, see [pitfalls](https://carpentry.dev/parsec/Pitfalls.html).
The full API reference is generated from the source and lives at
[the carpentry](https://carpentry.dev/parsec).

## Backtracking

Alternation follows Parsec semantics: `(Parser.alt p q)` only tries
`q` when `p` fails *without consuming*. To allow backtracking after
`p` has consumed, wrap it in `Parser.try`:

```clojure
(Parser.alt
  (Parser.try (Parser.string @"foobar"))
  (Parser.string @"foobaz"))
```

`Parser.string` is atomic: a partial mismatch fails empty without
needing `try`.

## Recursive grammars

Use `Parser.recurse` against a `Parser.placeholder`-initialized cell.
Declare the recursive grammar in a top-level `def`, `set!` it once at
startup, reference it from sub-parsers:

```clojure
(def *sexp* (the (Parser SExp) (Parser.placeholder)))

(defn list-p []
  (Parser.between (Parser.byte \()
                  (Parser.byte \))
                  (Parser.many (Parser.recurse &*sexp*))))

(defn init-grammar []
  (set! *sexp* (Parser.alt (sym-p) (list-p))))
```

`Parser.lazy` is also available for small one-off grammars but
rebuilds the parser tree on every call.

## Examples

- [`kv.carp`](examples/kv.carp) is a key-value config parser
- [`lisp.carp`](examples/lisp.carp) are s-expressions with a recursive `Box` AST
- [`arith.carp`](examples/arith.carp) is an arithmetic expression evaluator
  with operator precedence and parens

For a full Carp source-form reader built on parsec — atoms, compound
forms, reader macros, and first-class comments — see
[`carpentry-org/carp-reader`](https://github.com/carpentry-org/carp-reader).


<hr/>

Have fun!
