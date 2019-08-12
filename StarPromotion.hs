module StarPromotion (
  promote, promoteP, promoteKP, isPromoted,
  promoteAlt, promoteCat, promoteOpt, promoteRep, promoteCxt ) where

import Expression
import Fuse
import OK
import Context
import Info
import List
import Data.List (partition)
import Data.Bits
import Alphabet

promoteExtension :: Extension
promoteExtension = mkExtension altPromotion catPromotion fuseKP Promoted

promote :: RE -> RE
promote = mkTransform promoteK

promoteCxt = katahom promoteK

promoteK = trg promoteExtension
promoteH = mkHomTrans promoteK
HomTrans { falt=promoteAlt,  fcat=promoteCat, frep= promoteRep, fopt=promoteOpt} = fuseH

promoteKP = target promoteExtension

promoteP = tpr promoteExtension
isPromoted = checkWith promoteP

altPromotion, catPromotion :: RewRule
altPromotion c i xs = altSigmaStarPromotion i xs `orOK` altStarPrune c i xs `orOK` altCharSubsumption i xs
catPromotion c i xs = catSigmaStarPromotion i xs `orOK` catStarPrune c i xs

catStarPrune RepCxt i xs | not (ew i) && not (isEmptyAlpha swx)
                         = debunkList swx xs `orOK` knubedList swx xs `orOK` innerPrune True xs
                           where
                           swx = sw i
catStarPrune c _ xs = innerPrune (c>=OptCxt) xs

-- new 24072019 SMK
innerPrune :: Bool -> [RE] -> OK [RE]
innerPrune True [x,Rep y] | x==y
                          = changed [Rep y]
innerPrune True [Rep y,x] | x==y
                          = changed [Rep y]
innerPrune b xs =
    list2OK xs [valOf pp ++ (e:valOf ss) | (pre,e,suf)<-segElemSuf xs, isRep e,
                                            let swx=swa e, not(isEmptyAlpha swx),
                                            let pp=knubedList swx pre, let ss=debunkList swx suf,
                                            hasChanged pp || hasChanged ss]
                                    
altStarPrune RepCxt i xs | not (ew i) && not (isEmptyAlpha swx)
                         = list2OK xs [ catSegment x xs':ys | (x@(Cat _ xs),ys) <-itemRest xs,
                                        xs' <- [ valOf xs1 | let xs1=debunkList swx xs, hasChanged xs1 ]
                                            ++ [ valOf xs2 | let xs2=knubedList swx xs, hasChanged xs2 ]
                                      ]
                           where
                           swx = sw i
altStarPrune _ _ xs      = unchanged xs

altSigmaStarPromotion :: Info -> [RE] -> OK [RE]
altSigmaStarPromotion i xs |  any (==sigmastar) xs -- most common special case, singled out for efficiency
                           =  changed [ sigmastar ]
                           |  otherwise
                           =  list2OK xs cands                    
    where
    alphabet  = alpha2String (al i)
    sigmastar = Rep (kataAlt (map Sym alphabet))
    cands     = [ Rep y: ys2 |
                  (Rep y,ys)<-itemRest xs, let al1=swa y, not(isEmptyAlpha al1),
                  let (ys1,ys2)=partition (\r->subAlpha (alpha r) al1) ys,
                  not $ null ys1 ]

starredAlphas :: [RE] -> [Alphabet] -> [Alphabet]
starredAlphas [] ys         = nubSort ys
starredAlphas (Rep x:xs) ys = starredAlphas xs (swa x:ys)
starredAlphas (_ : xs)   ys = starredAlphas xs ys

altSigmaStarSubsumption :: Info -> [RE] -> OK [RE]
altSigmaStarSubsumption i xs = filterOK (not . demote css) xs
    where
    css = drop1 $ starredAlphas xs []
    drop1 (0:xs) = xs
    drop1 xs     = xs

isAlphabet :: RE -> Bool
isAlphabet (Sym _) = True
isAlphabet (Alt i xs) = not (ew i) && al i==sw i && all isSym xs

filterOK :: (a->Bool) -> [a] -> OK [a]
filterOK p xs = fOK xs [] False
                where
                fOK [] ys b = mkOK (reverse ys) b
                fOK (x:xs) ys b | p x
                                = fOK xs (x:ys) b
                                | otherwise
                                = fOK xs ys True

demote :: [Alphabet] -> RE -> Bool
demote css (Rep y) | isAlphabet y
                   = any (strictSubAlpha (alpha y)) css
                     where
                     ys=alpha y
demote css x       = any (subAlpha (alpha x)) css

altCharSubsumption :: Info -> [RE] -> OK [RE]
altCharSubsumption i xs = list2OK xs [ filter (goodElem cs) xs | not(isEmptyAlpha(sw i)), let cs=droppableAltSymbols xs,
                                          not(isEmptyAlpha cs) ]
                          where
                          goodElem chset (Sym c) = not $ elemAlpha c chset
                          goodElem chset _       = True

droppableAltSymbols :: [RE] -> Alphabet
droppableAltSymbols xs = dralsy xs emptyAlpha emptyAlpha
                         where
                         dralsy [] csym osym = csym .&. osym
                         dralsy (Sym x:xs) csym osym = dralsy xs (char2Alpha x .|. csym) osym
                         dralsy (y    :xs) csym osym = dralsy xs csym (swa y .|. osym)

swcheck :: Char -> RE -> Bool
swcheck c re = elemAlpha c (swa re) --elem c (fir re) && elem c (las re) && swp c re 

sigmaStarTest :: Alphabet -> RE -> Bool
sigmaStarTest cs (Rep x) = swa x==cs
sigmaStarTest cs _       = False

catSigmaStarPromotion :: Info -> [RE] -> OK [RE]
catSigmaStarPromotion i xs | ew i && sw i==cs
                           = list2OK xs [ [x] | x<-xs, sigmaStarTest cs x]
                           | otherwise
                           = unchanged xs
                             where cs = al i

debunkList :: Alphabet -> [RE] -> OK [RE]
debunkList al1 []      = unchanged []
debunkList al1 (re:ps) | isLam nre
                       = unsafeChanged $ debunkList al1 ps -- greedy
                       | b && not(ewp nre) && singularAlpha al3 && subAlpha al3 al1
                       = unsafeChanged $ okmap (nre:) $ debunkList al3 ps --greedy
                       | not b && not(ewp re) && singularAlpha al2 && subAlpha al2 al1 
                       = okmap (re:) $ debunkList al2 ps -- changed: used to require al1==al2
                       | b
                       = changed (nre:ps)
                       | otherwise
                       = unchanged (re:ps)
                         where
                         al2 = alpha re
                         al3 = alpha nre
                         d   = debunkRECxt False al1 re
                         nre = valOf d
                         b   = hasChanged d 

debunkRECxt :: Bool -> Alphabet -> RE -> OK RE
debunkRECxt c al1 re | (c||ewp re) && subAlpha (alpha re) al1
                     = changed Lam
debunkRECxt c al1 (Alt i res) = okmap kataAlt $ katalift (debunkRECxt (c||ew i) al1) res
debunkRECxt _ al1 (Cat _ res) = okmap mkCat $ debunkList al1 res
debunkRECxt _ al1 (Opt re)    = okmap Opt   $ debunkRECxt True al1 re
debunkRECxt _ al1 (Rep c@(Cat i xs)) --Conway rule for debunking, alphaLength condition for efficiency only
                              | alphaLength (al i)>1 && isRep y && subAlpha(alpha r) al1
                              = changed $ Rep (kataAlt [r,catSegment c ys])
                                where
                                Just(ys,y) = unsnoc xs
                                Rep r      = y
debunkRECxt _ _    e          = unchanged e                       

knubedList :: Alphabet -> [RE] -> OK [RE]
knubedList al1 [] = unchanged []
knubedList al1 xs | isLam ny
                  = unsafeChanged $ knubedList al1 ys
                  | b && not(ewp ny) && singularAlpha al3 && subAlpha al3 al1
                  = unsafeChanged $ okmap (++ [ny]) $ knubedList al3 ys
                  | not b && not(ewp y) && singularAlpha al2 && subAlpha al2 al1 
                  = okmap (++[y]) $ knubedList al2 ys
                  | b
                  = changed (ys ++ [ny])
                  | otherwise
                  = unchanged xs
                    where
                    Just (ys,y) = unsnoc xs
                    al2 = alpha y
                    al3 = alpha ny
                    k   = knubedRE al1 y
                    ny  = valOf k
                    b   = hasChanged k

knubedRECxt :: Bool -> Alphabet -> RE -> OK RE
knubedRECxt c al1 re | (c||ewp re) && subAlpha (alpha re) al1
                     = changed Lam
knubedRECxt c al1 (Alt i res) = okmap kataAlt $ katalift (knubedRECxt (c||ew i) al1) res
knubedRECxt _ al1 (Cat _ res) = okmap mkCat $ knubedList al1 res
knubedRECxt _ al1 (Opt re)    = okmap Opt   $ knubedRECxt True al1 re
knubedRECxt _ al1 (Rep c@(Cat i (Rep r:ys))) | subAlpha(alpha r) al1
                              = changed $ Rep (kataAlt [r,catSegment c ys])
knubedRECxt _ _   e           = unchanged e

knubedRE :: Alphabet -> RE -> OK RE
knubedRE al1 re | ewp re && subAlpha (alpha re) al1
                = changed Lam
knubedRE al1 (Alt _ res) = okmap kataAlt $ katalift (knubedRE al1) res
knubedRE al1 (Cat _ res) = okmap mkCat $ knubedList al1 res
knubedRE al1 o@(Opt (Alt _ res)) = okmap mkAlt (katalift (knubedRE al1 . Opt) res) `orOK` unchanged o
knubedRE al1 (Opt re)    = okmap Opt   $ knubedRE al1 re
knubedRE _   e           = unchanged e

