# Changelog

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
the project follows [Semantic Versioning](https://semver.org/).

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
