# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
the project follows [Semantic Versioning](https://semver.org/).

## Unreleased

### Fixed
- `Parser.UTF8` codepoint parsers (`any-char`, `char`, `codepoint-satisfy`)
  now reject malformed UTF-8 — invalid continuation bytes, overlong
  encodings, UTF-16 surrogates, and codepoints above U+10FFFF — instead of
  silently mis-decoding them and, on a bad continuation byte, swallowing the
  following byte.

## [0.5.0]

### Added
- `Parser.Lexer.string-literal` — parses a double-quoted string literal,
  decoding backslash escapes (`\n`, `\t`, `\r`, `\\`, `\"`, `\'`, `\0`,
  `\a`, `\b`, `\f`, `\v`, and `\xHH`), and returns the decoded text.
- `Parser.Lexer.char-literal` — parses a single-quoted character literal
  with the same escape set and returns the decoded `Char`.

### Changed
- `Parser.string-ci` — fused the comparison and cursor-advance loops
  into a single pass, halving byte reads on successful matches.

## [0.4.0]

### Added
- `Parser.Lexer.hex-int` — parses `0x`/`0X`-prefixed hexadecimal
  integer literals (digits `0`-`9`, `a`-`f`, `A`-`F`). Fused; fails
  on overflow.
- `Parser.Lexer.octal-int` — parses `0o`/`0O`-prefixed octal integer
  literals (digits `0`-`7`). Fused; fails on overflow.
- `Parser.Lexer.binary-int` — parses `0b`/`0B`-prefixed binary
  integer literals (digits `0` and `1`). Fused; fails on overflow.
- `Parser.string-ci s` — case-insensitive (ASCII) string matching.
  Returns the matched slice from the input, preserving its original
  case. Atomic like `Parser.string`.
- `Parser.range lo hi p` — runs `p` between `lo` and `hi` times
  (inclusive). The first `lo` applications are mandatory; after that,
  `p` is applied greedily up to `hi` times total.
- `Parser.Lexer.line-comment prefix` — skips from `prefix` to end of
  line (or EOF). The newline itself is not consumed.
- `Parser.Lexer.block-comment open close` — skips a block comment
  with nesting support. An `open` inside the comment increments
  depth; each `close` decrements it.
- `Parser.at-most n p` — runs `p` up to `n` times, collecting
  results. Stops early on empty failure (like `many` with a cap).
- `Parser.at-least n p` — runs `p` at least `n` times, then
  continues greedily. Fails if `p` doesn't match `n` times.
- `Parser.sep-end-by p sep` / `Parser.sep-end-by1 p sep` — like
  `sep-by` / `sep-by1` but allow an optional trailing separator.
- `Parser.option default p` — tries `p`; on empty failure, returns
  `default` instead of `Maybe`. Consumed failures propagate.
- `Parser.skip p` — runs `p` and discards its value, returning
  `()`. Useful for consumption-only effects.
- `Parser.Lexer.digit`, `Parser.Lexer.letter`,
  `Parser.Lexer.upper`, `Parser.Lexer.lower`,
  `Parser.Lexer.alpha-num`, `Parser.Lexer.space` — character class
  parsers that match a single ASCII byte. These were previously
  private predicates only; now exposed as public combinators.

### Fixed
- `Lexer.unsigned-int` and `Lexer.integer` now return a parse
  error when the digit string overflows `Int` instead of silently
  yielding a clamped value (e.g. `INT_MAX`).

### Tests
- Added edge case tests: `lookahead` consumed failure,
  `not-followed-by` consumed inner failure, `block-comment`
  overlapping delimiters, `chainl1` with multiple operator types,
  `string-ci` empty pattern on non-empty input, `range` with
  lo > hi.

## [0.3.0]

### Added
- `Parser.skip-many p` — like `many` but discards all results,
  returning `()`. Avoids building an `Array`, saving allocations.
- `Parser.skip-many1 p` — like `many1` but discards results.
  Fails if the first application of `p` fails.
- `Parser.many-till p end` — repeats `p` until `end` succeeds,
  collecting `p` results in an `Array`. Returns the array (not
  the `end` result).
- `Parser.parse-partial p src` — runs `p` without requiring it to
  consume all input. Returns `(Result (Pair a String) ParseErr)`
  where the `String` is the unconsumed remainder.
- `Parser.chainl1 p op` — parse one or more occurrences of `p`
  separated by `op`, folding left-associatively. `op` returns a
  binary function.
- `Parser.chainr1 p op` — like `chainl1` but folds
  right-associatively.
- `Parser.chainl p op default` — like `chainl1` but returns
  `default` if `p` fails on the first attempt.
- `Parser.chainr p op default` — like `chainr1` but returns
  `default` if `p` fails on the first attempt.
- `Parser.Lexer.float` — parses a floating-point number (optional
  sign, integer/fractional digits, optional exponent) and returns
  a `Double`.

### Changed
- `Parser.string` now uses C `memcmp` for comparison and advances the
  cursor in a single pass, avoiding per-character `Cursor` allocation.
  `Parser.string-ci` also benefits from the single-pass cursor advance.

### Fixed
- `Parser.satisfy` now populates `ParseErr.unexpected` with the
  actual byte seen when the predicate fails, so error messages
  report "unexpected 'x'; expected digit" instead of only the
  expected label.
- `Parser.eof` now populates `ParseErr.unexpected` with the byte
  seen when the input is not at end.

### Tests
- Added tests for `Parser.then`, `Parser.before`, and
  `Parser.bind-result` (shipped in 0.2.0 with no coverage).
- Added edge case tests: `count 0`, `take 0`, `sep-by1` with
  trailing separator, 4-byte UTF-8 codepoint (`U+1F600`).
- Added tests verifying `unexpected` appears in `satisfy` and
  `eof` error messages.
- Added tests for `Parser.parse-partial`.

## [0.2.0]

### Added
- `Parser.then p q` — runs `p` then `q`, returning `q`'s value.
  Avoids the continuation-closure allocation of
  `(Parser.bind p (fn [_] q))`.
- `Parser.before p q` — runs `p` then `q`, returning `p`'s value.
  Mirror of `Parser.then`.
- `Parser.bind-result p f` — variant of `bind` where `f` takes the
  parsed value and a `&Cursor` and returns `(Result b ParseErr)`.
  Skips the per-parse `Parser.pure` / `Parser.fail` rebuild the
  equivalent `bind` formulation does.
- `Expected` sumtype (`(One String)` / `(Many (Array String))`)
  representing the expected-set on a `ParseErr`, plus
  `Expected.empty`, `Expected.to-array`, `Expected.length`, and
  `Expected.append-into`.

### Changed
- **Breaking**: `ParseErr.expected` is now `Expected`, not
  `(Array String)`. Code that read the field directly should call
  `(Expected.to-array (ParseErr.expected &e))` for the old
  behaviour, or use `Expected.length` /
  `Expected.append-into` where appropriate.

## [0.1.0]

- Initial release.
