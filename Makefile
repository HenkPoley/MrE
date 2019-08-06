progs: CreateSemCatalogue CreateSynCatalogue Effect MrE Reg Tim Tom

CreateSemCatalogue: Alphabet.hs Catalogue.hs Comparison.hs Context.hs \
CreateSemCatalogue.hs Expression.hs Function.hs Fuse.hs Generator.hs \
Info.hs List.hs PreOrderTrees.hs Pressing.hs Queue.hs RegexpMemo.hs \
Sanify.hs Shrinking.hs StarPromotion.hs StarRecognition.hs UnionFindRE.hs 
	ghc -O CreateSemCatalogue

CreateSynCatalogue: Alphabet.hs Comparison.hs Context.hs CreateSynCatalogue.hs \
Expression.hs Function.hs Fuse.hs Generator.hs Info.hs List.hs PreOrderTrees.hs \
Pressing.hs Queue.hs RegexpMemo.hs Sanify.hs Shrinking.hs StarPromotion.hs \
StarRecognition.hs SyntaxCatalogue.hs UnionFindRE.hs
	ghc -O CreateSynCatalogue

Effect: Alphabet.hs Catalogue.hs Comparison.hs Context.hs Effect.hs \
Expression.hs Function.hs Fuse.hs Generator.hs GruberP.hs Info.hs \
List.hs Parser.hs PreOrderTrees.hs Pressing.hs Queue.hs RegexpMemo.hs \
Sanify.hs Shrinking.hs StarPromotion.hs StarRecognition.hs Stellation.hs \
SyntaxCatalogue.hs UnionFindRE.hs semcatalogue syncatalogue populations
	ghc -O Effect

effects: Effect allEffect populations
	if test -d "effects" ; then rm effects/* ; else mkdir effects ; fi
	./allEffect
	touch effects

MrE: Alphabet.hs Catalogue.hs Comparison.hs Context.hs Expression.hs \
Function.hs Fuse.hs Generator.hs GruberP.hs Info.hs List.hs MrE.hs \
Parser.hs PreOrderTrees.hs Pressing.hs Queue.hs RegexpMemo.hs \
Sanify.hs Shrinking.hs StarPromotion.hs StarRecognition.hs Stellation.hs \
SyntaxCatalogue.hs UnionFindRE.hs semcatalogue syncatalogue
	ghc -O MrE

populations: Reg allReg
	if test -d "populations" ; then rm populations/* ; else mkdir populations ; fi
	./allReg
	touch populations

Reg: Leonardo.hs Reg.hs
	ghc -O Reg

semcatalogue: CreateSemCatalogue
	if test -d "semcatalogue" ; then rm semcatalogue/* ; else mkdir semcatalogue ; fi
	./CreateSemCatalogue
	touch semcatalogue

syncatalogue: CreateSynCatalogue
	if test -d "syncatalogue" ; then rm syncatalogue/* ; else mkdir syncatalogue ; fi
	./CreateSynCatalogue
	touch syncatalogue

Tim: Alphabet.hs Catalogue.hs Comparison.hs Context.hs Expression.hs \
Function.hs Fuse.hs Generator.hs Info.hs List.hs PreOrderTrees.hs \
Pressing.hs Queue.hs RegexpMemo.hs Shrinking.hs StarPromotion.hs \
Sanify.hs StarRecognition.hs SyntaxCatalogue.hs Tim.hs TopShrink.hs UnionFindRE.hs
	ghc -O Tim

Tom: Alphabet.hs Catalogue.hs Comparison.hs Context.hs Expression.hs \
Function.hs Fuse.hs Generator.hs Info.hs List.hs PreOrderTrees.hs \
Pressing.hs Queue.hs RegexpMemo.hs Sanify.hs Shrinking.hs StarPromotion.hs \
StarRecognition.hs SyntaxCatalogue.hs Tom.hs TopShrink.hs UnionFindRE.hs
	ghc -O Tom

