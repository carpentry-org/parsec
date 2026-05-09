{-# LANGUAGE BangPatterns #-}
-- Head-to-head benchmark of Haskell Parsec on the same grammars as
-- Carp parsec. Grammars are kept structurally identical between sides
-- so the comparison is apples-to-apples.

module Main where

import Text.Parsec
import Text.Parsec.String (Parser)
import qualified Data.List as L
import Text.Printf (printf)
import Data.Time.Clock (getCurrentTime, diffUTCTime)

------------------------------------------------------------
-- kv grammar
------------------------------------------------------------

ident :: Parser String
ident = do
  c  <- letter <|> char '_'
  cs <- many (alphaNum <|> char '_')
  return (c : cs)

integer :: Parser Int
integer = do
  sign   <- optionMaybe (char '-')
  digits <- many1 digit
  let n = read digits
  return $ maybe n (const (negate n)) sign

ws :: Parser ()
ws = skipMany (oneOf " \t\n\r")

pair :: Parser (String, Int)
pair = do
  ws
  name <- ident
  ws
  _    <- char '='
  ws
  n    <- integer
  ws
  return (name, n)

kvGrammar :: Parser [(String, Int)]
kvGrammar = pair `sepBy1` (char ';')

parseKv :: String -> Either ParseError [(String, Int)]
parseKv = parse (kvGrammar <* eof) ""

------------------------------------------------------------
-- s-expression grammar (mirrors examples/lisp.carp)
------------------------------------------------------------

data SExp = Sym String | Lst [SExp] deriving (Show)

symChar :: Parser Char
symChar = noneOf " \t\n()"

symbolP :: Parser SExp
symbolP = do
  ws
  cs <- many1 symChar
  ws
  return (Sym cs)

listP :: Parser SExp
listP = do
  ws
  _ <- char '('
  xs <- many sexpP
  _ <- char ')'
  ws
  return (Lst xs)

sexpP :: Parser SExp
sexpP = symbolP <|> listP

parseSexp :: String -> Either ParseError SExp
parseSexp = parse (ws *> sexpP <* eof) ""

------------------------------------------------------------
-- Comma-separated integer list (mirrors sep-by integer ',')
------------------------------------------------------------

intList :: Parser [Int]
intList = integer `sepBy` (char ',')

parseIntList :: String -> Either ParseError [Int]
parseIntList = parse (intList <* eof) ""

------------------------------------------------------------
-- Inputs (must match Carp side byte-for-byte)
------------------------------------------------------------

genKv :: Int -> String
genKv n = L.intercalate "; " [printf "k%d=%d" i i | i <- [0 .. n - 1]]

genIntList :: Int -> String
genIntList n = L.intercalate "," [show i | i <- [0 .. n - 1]]

genDeepSexp :: Int -> String
genDeepSexp n = replicate n '(' ++ "x" ++ replicate n ')'

genFlatSexp :: Int -> String
genFlatSexp n = "(" ++ unwords (replicate n "x") ++ ")"

------------------------------------------------------------
-- Timing
------------------------------------------------------------

forceList :: Either e [a] -> Int
forceList (Right xs) = length xs
forceList (Left _)   = -1

forceSexp :: Either e SExp -> Int
forceSexp (Right s) = sexpSize s
forceSexp (Left _)  = -1

sexpSize :: SExp -> Int
sexpSize (Sym _)  = 1
sexpSize (Lst xs) = 1 + sum (map sexpSize xs)

benchN :: String -> Int -> (a -> Int) -> a -> IO ()
benchN name n force input = do
  let !_ = force input  -- warmup
  times <- mapM (\_ -> timeOnce force input) [1 .. n]
  let total = sum times
      best  = minimum times
      avg   = total / fromIntegral n
  printf "%-26s  best=%9.2f us   avg=%9.2f us  (n=%d)\n"
         name (best / 1000) (avg / 1000) n

timeOnce :: (a -> Int) -> a -> IO Double
timeOnce force input = do
  t0 <- getCurrentTime
  let !_ = force input
  t1 <- getCurrentTime
  return (realToFrac (diffUTCTime t1 t0) * 1e9)

------------------------------------------------------------
-- Main
------------------------------------------------------------

main :: IO ()
main = do
  let kv100   = genKv 100
      kv1000  = genKv 1000
      ints100 = genIntList 100
      ints1k  = genIntList 1000
      deep    = genDeepSexp 100
      flat    = genFlatSexp 1000

  putStrLn "=== Haskell Parsec ==="
  benchN "kv 100"            200 (forceList . parseKv)      kv100
  benchN "kv 1000"           100 (forceList . parseKv)      kv1000
  benchN "int-list 100"      200 (forceList . parseIntList) ints100
  benchN "int-list 1000"     100 (forceList . parseIntList) ints1k
  benchN "sexp deep 100"     200 (forceSexp . parseSexp)    deep
  benchN "sexp flat 1000"    100 (forceSexp . parseSexp)    flat
