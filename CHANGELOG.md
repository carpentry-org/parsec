# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
the project follows [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- `Parser.at-most n p` — runs `p` up to `n` times, collecting
  results. Stops early on empty failure (like `many` with a cap).
- `Parser.at-least n p` — runs `p` at least `n` times, then
  continues greedily. Fails if `p` doesn't match `n` times.
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

### Fixed
- `Lexer.unsigned-int` and `Lexer.integer` now return a parse
  error when the digit string overflows `Int` instead of silently
  yielding a clamped value (e.g. `INT_MAX`).
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
