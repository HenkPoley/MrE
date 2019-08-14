module Derivative (derive, allDerives) where

import Expression
import Alphabet
import Info
import List

derive :: Char -> RE -> RE
derive c e = alt $ map cat $ deriveAlts c e []

deriveAlts :: Char -> RE -> [RE] -> [[RE]]
deriveAlts c (Sym d)    cont   =  [cont | c==d]
deriveAlts c (Alt i xs) cont   |  elemAlpha c (fi i)
                               =  unions [ deriveAlts c x cont | x<-xs ]
deriveAlts c (Cat i xs) cont   |  elemAlpha c (fi i)
                               =  deriveCatList c xs cont
deriveAlts c (Opt x) cont      =  deriveAlts c x cont
deriveAlts c (Rep x) cont      =  deriveAlts c x (Rep x:cont)
deriveAlts c _ _               =  [] -- Lam or Emp, or bad (fi i)

-- can assume: char can be first character
deriveCatList :: Char -> [RE] -> [RE] -> [[RE]]
deriveCatList c (x:xs) cont   |  not (elemAlpha c (fir x)) -- x must be optional
                              =  tailDerive
                              |  not (ewp x) || not (firstCharList c xs)
                              =  headDerive
                              |  otherwise -- c can be knocked off either way
                              =  tailDerive `nubMerge` headDerive
                                 where
                                 headDerive = deriveAlts c x (xs++cont)
                                 tailDerive = deriveCatList c xs cont

-- derivation tree for one letter, as a list: is it finite?
allDers :: Char -> RE -> [RE]
allDers c x = process x []
              where
              process x xs | elem x xs
                           = xs
                           | otherwise
                           = x : process (derive c x) (x:xs)


firstCharList :: Char -> [RE] -> Bool
firstCharList c []     = False
firstCharList c (x:xs) = elemAlpha c (fir x) || ewp x && firstCharList c xs

-- derivation from the end
evired :: RE -> Char -> RE
evired e c = alt $ map cat $ eviredAlts c e id

eviredAlts :: Char -> RE -> ([RE]->[RE]) -> [[RE]]
eviredAlts c (Sym d)    cont   =  [cont [] | c==d]
eviredAlts c (Alt i xs) cont   |  elemAlpha c (la i)
                               =  unions [ eviredAlts c x cont | x<-xs ]
eviredAlts c (Cat i xs) cont   |  elemAlpha c (la i)
                               =  snd $ eviredCatList c xs cont
eviredAlts c (Opt x) cont      =  eviredAlts c x cont
eviredAlts c (Rep x) cont      =  eviredAlts c x (cont . (Rep x : ))
eviredAlts c _ _               =  [] -- Lam or Emp, or bad (la i)

-- can assume: char can be last character
eviredCatList :: Char -> [RE] -> ([RE]->[RE]) -> (Bool,[[RE]])
eviredCatList _ []     _      = (True,[])
eviredCatList c (x:xs) cont   =
         addTop $ eviredCatList c xs (cont . (x:))
         where
         addTop (False,xss) = (False,xss)
         addTop (True,xss)  | elemAlpha c (las x)
                            = (ewp x,eviredAlts c x cont `nubMerge` xss)
                            | otherwise
                            = (ewp x,xss)

unsnocF :: ([a]->a->b) -> [a] -> b
unsnocF cont [x] = cont [] x
unsnocF cont (x:xs) = unsnocF (\ys y->cont (x:ys) y) xs

allDerives :: [Char] -> RE -> [RE] -> [RE]
allDerives [] _ xs = xs
allDerives (c:cs) re xs = allDerives cs re (derive c re:xs)
