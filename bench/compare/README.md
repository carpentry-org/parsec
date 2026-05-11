# Head-to-head benchmarks vs Haskell Parsec

Identical grammars and inputs on both sides, comparing Carp `parsec` to
Haskell's [`parsec`](https://hackage.haskell.org/package/parsec).

## Running

```
# Carp side (--optimize is mandatory for any timing measurement)
cd ../..
carp --optimize -x bench/compare/carp/all_bench.carp

# Haskell side
cd bench/compare/haskell
cabal run -v0 parsec-bench
```

## Grammars

- **kv** — `identifier '=' integer (';' identifier '=' integer)*`
  Tests bind, lexer integer, sep-by, identifier.
- **int-list** — `integer (',' integer)*`
  Pure integer-list parsing; tests sep-by + Lexer.integer hot path.
- **sexp deep** — fully nested `((((((((...x...))))))))` of depth 100.
  Tests `recurse`-style recursion under deep input.
- **sexp flat** — one root with 1000 children: `(x x x x ... x)`.
  Tests `many` over a recursive parser at shallow depth.

The Carp side uses `Parser.recurse &*sexp*` against a top-level cell;
the Haskell side uses Parsec's natural laziness.

## Inputs

Generated identically on both sides — kv pairs `k0=0`/`k1=1`/..., integer
lists `0,1,2,...`, sexp shapes match byte-for-byte. See `genKv`/etc. in
`haskell/src/Main.hs` and `build-*` in `carp/all_bench.carp`.

## Reference numbers

Measured on an M-series Mac, Carp at `--optimize`, GHC at `-O2`,
best-case timings:

| Grammar | Haskell Parsec | Carp parsec |
|---|---|---|
| kv 100 pairs | 57 µs | 30 µs |
| kv 1000 pairs | 660 µs | 303 µs |
| int-list 100 | 15 µs | 3.3 µs |
| int-list 1000 | 168 µs | 34 µs |
| sexp deep 100 | 46 µs | 36 µs |
| sexp flat 1000 | 219 µs | 66 µs |

On a 40k-iteration combined workload, peak RSS is ~3.2 MB (Carp) vs
~13.6 MB (Haskell GHC).
