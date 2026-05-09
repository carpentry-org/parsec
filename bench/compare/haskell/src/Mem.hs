{-# LANGUAGE BangPatterns #-}
-- Memory-pressure driver: runs each grammar 10000 times. Run with
-- `+RTS -s` for GC stats.

module Main where

import Text.Parsec
import Text.Parsec.String (Parser)
import qualified Data.List as L
import Text.Printf (printf)
import Control.Monad (replicateM_)

------------------------------------------------------------
-- Grammars (mirror Carp side)
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

intList :: Parser [Int]
intList = integer `sepBy` (char ',')

parseIntList :: String -> Either ParseError [Int]
parseIntList = parse (intList <* eof) ""

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
-- Inputs
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
-- Force enough work that GHC actually does the parse.
------------------------------------------------------------

forceList :: Either e [a] -> Int
forceList (Right xs) = length xs
forceList (Left _)   = -1

sexpSize :: SExp -> Int
sexpSize (Sym _)  = 1
sexpSize (Lst xs) = 1 + sum (map sexpSize xs)

forceSexp :: Either e SExp -> Int
forceSexp (Right s) = sexpSize s
forceSexp (Left _)  = -1

------------------------------------------------------------
-- Main: 10_000 iterations of each grammar.
------------------------------------------------------------

-- Sum of forced parse outputs over n distinct inputs (each input
-- generated for the iteration index, so GHC can't hoist or CSE).
sumOver :: Int -> (Int -> String) -> (String -> Int) -> Int
sumOver n gen f = go 0 0
  where
    go !acc !i
      | i >= n    = acc
      | otherwise = go (acc + f (gen i)) (i + 1)

main :: IO ()
main = do
  -- 10_000 iterations, but the input slightly varies per iteration so
  -- GHC can't precompute the result.
  let !s1 = sumOver 10000 (\i -> genKv      1000 ++ if i == 0 then "" else " ")
                          (forceList . parseKv)
  let !s2 = sumOver 10000 (\i -> genIntList 1000 ++ if i == 0 then "" else " ")
                          (forceList . parseIntList)
  let !s3 = sumOver 10000 (\i -> genDeepSexp 100  ++ if i == 0 then "" else " ")
                          (forceSexp . parseSexp)
  let !s4 = sumOver 10000 (\i -> genFlatSexp 1000 ++ if i == 0 then "" else " ")
                          (forceSexp . parseSexp)
  putStrLn $ "done: " ++ show (s1, s2, s3, s4)
