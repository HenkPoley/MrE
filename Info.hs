module Info (
  Info(..), ExpInfo(..), Grade(..), Cxt(..), CGMap,
  emptyInfo, lamInfo, charInfo, newInfo, newInfo5, extractInfo,
  nocxt, nullcxt, outerCxt, ok, lookupCGMap, upgradeCGMap, subAltCGMap, subCatCGMap ) where

import Alphabet

data Info = Info {gr :: CGMap, ew :: Bool, 
                  al :: Alphabet,
                  fi,la,sw :: Alphabet, si :: Int} deriving Show

data ExpInfo = ExpInfo { graded::Grade, nullable::Bool,
                         alphabet,firsts,lasts,singles :: Alphabet, expressionSize :: Int }
               deriving Show
                 
emptyInfo, lamInfo :: ExpInfo
emptyInfo = ExpInfo {
              graded = Minimal, nullable=False,
              alphabet=emptyAlpha,firsts=emptyAlpha,lasts=emptyAlpha,singles=emptyAlpha,
              expressionSize=0 }

lamInfo   = emptyInfo { nullable=True }

lamListInfo :: Info -- info of empty list in a cat, size is set to -1 so that x and [x] have the same size
lamListInfo = Info { gr=[], ew=True, al=emptyAlpha, fi=emptyAlpha, la=emptyAlpha, sw=emptyAlpha, si= -1}

emptyListInfo :: Info -- info of empty list in an alt, size is set to -1 so that x and [x] have the same size
emptyListInfo = Info { gr=[], ew=False, al=emptyAlpha, fi=emptyAlpha, la=emptyAlpha, sw=emptyAlpha, si= -1}

release :: Bool -> Alphabet -> Alphabet
release True s  = s
release False _ = emptyAlpha

charInfo :: Char -> ExpInfo
charInfo c = ExpInfo { graded=Minimal, nullable=False,alphabet=cs,firsts=cs,lasts=cs,singles=cs,expressionSize=1 }
             where cs=char2Alpha c

extractInfo :: Cxt -> Info -> ExpInfo
extractInfo c i =
    ExpInfo { graded = lookupCGMap c (gr i),
              nullable=ew i, alphabet=al i,
              firsts = fi i, lasts=la i, singles=sw i,
              expressionSize = si i }

nocxt NoCxt i = i
nocxt _     i = i { graded = NoGrade }

nullcxt NoCxt i = i
nullcxt c     i = i { nullable=True }

noInfo :: Info
noInfo = Info {gr = [], ew = error "undefined ew in info",
               fi = error "undefined fi in info",
               al = error "undefined al in info",
               la = error "undefined la in info",
               sw = error "undefined sw in info",
               si = error "undefined size in info"}

newInfo :: Bool -> Info
newInfo b = noInfo { ew = b }

newInfo5 :: Bool -> Alphabet -> Alphabet -> Alphabet -> Alphabet -> Info
newInfo5 b cs1 cs2 cs3 cs4 = noInfo { ew=b, fi=cs1, la=cs2, al=cs3, sw=cs4 }

-- We do not wish to distinguish info values under comparison operations as
-- we want them to be neutral in RE comparisons.

instance Eq Info where
  _ == _  =  True

instance Ord Info where
  compare _ _  =  EQ

-- at least, also useful: size, derivatives, firsts?

data Cxt = RootCxt | NoCxt | EwpCxt | OptCxt | RepCxt
  deriving (Eq,Ord,Show)

data Grade = NoGrade | Kata | Fused | Promoted | Recognised | BottomCatalogued |
             Topshrunk | Shrunk | Pressed | Refactorized | 
             Catalogued | Stellar | Auto | Minimal
  deriving (Eq, Ord, Show)

type CGMap = [(Cxt,Grade)]

-- A contextual grading is a finite map, an unordered set of ordered pairs representing
-- an antitone function f: c1 <= c2 ==> f c1 >= f c2
-- the *representation* is injective:
-- if both (c1,g1) & (c2,g2) are in gr then g1==g2 <=> c1==c2

ok :: Cxt -> Grade -> CGMap -> Bool
ok c g cgm  =  any (\(c',g') -> c' >= c && g' >= g) cgm

outerCxt :: Bool -> Cxt -> Cxt
outerCxt _ c      |  c>=OptCxt
                  =  c
outerCxt True _   =  OptCxt
outerCxt False _  =  NoCxt

lookupCGMap :: Cxt -> CGMap -> Grade
lookupCGMap c cgm = maximum (NoGrade : [ g | (c',g) <- cgm, c' >=c] )

okInfo :: Cxt -> Grade -> Info -> Bool
okInfo c g i = ok c g (gr i)

upgradeCGMap :: Cxt -> Grade -> CGMap -> CGMap
upgradeCGMap c g cgm  |  ok c g cgm
                      =  cgm
                      |  otherwise
                      =  (c,g): [(c',g')|(c',g')<-cgm, c'<c && g'>g || c'>c && g'<g]

-- noCxtCG :: CGMap -> CGMap
-- noCxtCG []  = []
-- noCxtCG cgm = [(NoCxt,lookupCGMap NoCxt cgm)]

-- arises when an expression is a common subexpression of two expressions
-- noCxtCG2 :: CGMap -> CGMap -> CGMap
-- noCxtCG2 [] x = noCxtCG x
-- noCxtCG2 x [] = noCxtCG x
-- noCxtCG2 x y  = [(NoCxt,max(lookupCGMap NoCxt x)(lookupCGMap NoCxt y))]

upgradeInfo :: Cxt -> Grade -> Info -> Info
upgradeInfo c g i = i { gr = upgradeCGMap c g (gr i)}

-- which grade maps can we give to subcats of graded cats, subalts of graded alts?
-- both context and grade may be affected
subAltCxt :: Cxt -> Cxt
subAltCxt RootCxt = NoCxt
subAltCxt x       = x

-- the catalogue-builds do not guarantee that subcats/subalts are catalogued, so defer to previous level
subGrade :: Grade -> Grade
subGrade Catalogued       = Promoted
subGrade BottomCatalogued = Promoted
subGrade x                = x

subAltCGMap :: CGMap -> CGMap
subAltCGMap m = [(subAltCxt c,subGrade g) | (c,g)<-m]

subCatCGMap :: CGMap -> CGMap
subCatCGMap m = [(NoCxt,subGrade g)|(c,g)<-m]


