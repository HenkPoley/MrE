module Main where

import Data.Maybe
import Data.List
import Expression
import StarPromotion
import System.Environment
import Parameters
import Info

-- Input, list of outputs Output
data IPO = IPO {inp :: RE, outs :: [(Grade,RE)] }

instance Show IPO where
  show (IPO e1 e2) =
    "IN:  " ++ show e1 ++ "\n" ++
    "OUT: " ++ show e2 ++ "\n"
    -- ++ grading e' ++ "\n"   (Gruber Gulan don't do grading)

main = do
  args <- getArgs
  let p = argsToParams args
  input <- contents (inputsource p)
  let trafos = allGrades p
  let ipos = catMaybes $ map (process trafos) (lines input)
  mapM_ print ipos

process :: [Grade] -> String -> Maybe IPO
process ts s  |  sameSizes (map snd rs)
              =  Nothing
              |  otherwise
              =  Just (IPO { inp=e, outs=xs })
  where
  e  =  readBeforeT (head ts) s
  rs =  [ (t,transFun t e) | t <- ts]
  xs = sortBy (\p q -> compare(size(snd p))(size(snd q))) rs

sameSizes :: [RE] -> Bool
sameSizes (x:xs) = all (\e->size e==size x) xs

