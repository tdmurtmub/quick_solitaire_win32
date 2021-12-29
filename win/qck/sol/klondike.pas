{ (C) 1998 Wesley Steiner }

{$MODE FPC}

{$ifdef DEBUG}
{!$define TEST_TAB_ACCEPTS_ANY_CARD}
{$endif DEBUG}

unit klondike;

interface

uses
	std,cards,
	winqcktbl,
	winsoltbl;

const
	NTABLEAUS=7;
	NFOUNDATIONS=4;

type
	OStandardgame_ptr=^OStandardgame;

	TableauPileBasePtr=^TableauPileBase;
	TableauPileBase=object(TTableauAlt)
        constructor Construct(game:SolGameP;No,N:integer;FaceUp:boolean; X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnTopcardFlipped; virtual;
	end;

	KondikeFndtnPileBase_ptr=^KondikeFndtnPileBase;
	KondikeFndtnPileBase=object(TFoundation) private
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
	end;

	OWastepile=object(OWastepileProp) 
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		function GetCardX(p_index:integer):integer; virtual;
	end;
	OWastepile_ptr=^OWastepile;

	OStockpilePropShared=object(OStockpileProp) 
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
	end;
	
	PKlondikeStockpile=^OKlondikeStockpile;
	OKlondikeStockpile=object(OStockpilePropShared) 
		constructor Init(tabletop:SolTableViewP;n,X,Y:integer);
		procedure TopSelected; virtual;
		procedure OnTopcardFlipped; virtual;
	end;

	StandardTabPilePtr=^StandardTabPile;
	StandardTabPile=object(TableauPileBase) private
		procedure OnCardAdded virtual;
		function CanGrabUnit(aIndex:integer):boolean; virtual;
	end;

	PStandardStockpile=^OStandardStockpile;
	OStandardStockpile=object(TActionPile) 
		constructor Init(a_pGame:OStandardgame_ptr;tabletop:SolTableViewP;n,X,Y:integer);
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure topSelected; virtual;
		procedure Selected; virtual;
	end;

	StandardFndtnPilePtr=^StandardFndtnPile;
	StandardFndtnPile=object(KondikeFndtnPileBase)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
	end;

	TableauIndex=1..NTABLEAUS;
	FndtnIndex=1..NFOUNDATIONS;

	OBasegame=object(SolGame)
		Wastepile:OWastepile_ptr;
		Tableaus:array[TableauIndex] of TableauPileBasePtr;
		Foundations:array[FndtnIndex] of KondikeFndtnPileBase_ptr;
		constructor Init(anID:eGameId;tabletop:SolTableViewP);
		function PileRows:word; virtual;
		function PileColumns:word; virtual;
		function Score:TScore; virtual;
		procedure Setup; virtual;
	end; 
	OBasegame_ptr=^OBasegame;

	OKlondikegame=object(OBasegame)
		constructor Construct(tabletop:SolTableViewP);
	private
		stock:PKlondikeStockpile;
		procedure Setup; virtual;
		procedure OnDeal; virtual;
	end; 
	OKlondikegame_ptr=^OKlondikegame;

	OStandardgame=object(OBasegame)
		constructor Construct(aVariation:word;tabletop:SolTableViewP);
		function VariationCount:quantity; virtual;
		function VariationName(n:quantity):pchar; virtual;
	private
		stock:PStandardStockpile;
		procedure Setup; virtual;
		procedure OnDeal; virtual;
	end;

implementation

uses
	wincrt,
	windows,strings,
	xy,
	qcktbl,
	winCardFactory,
	stdwin;

var
	TheGame:OBasegame_ptr;

constructor OBasegame.Init(anID:eGameId;tabletop:SolTableViewP);
begin
	inherited Construct(anID, tabletop);
	TheGame:=@Self;
	Wastepile:=New(OWastepile_ptr, Construct);
end;

constructor OStandardgame.Construct(aVariation:word;tabletop:SolTableViewP);
var
	i:integer;
begin //writeln('OStandardgame.Construct(',aVariation,',tabletop:SolTableViewP)');
	inherited Init(GID_STANDARD,tabletop);
	SetVariation(aVariation);
	for i:=1 to NTABLEAUS do begin
		Tableaus[i]:=New(StandardTabPilePtr,Construct(@self,i,i+11,False,-1,-1,0,0));
		InsertTabletop(tabletop,Tableaus[i]);
	end;
	for i:=1 to NFOUNDATIONS do begin
		Foundations[i]:=New(StandardFndtnPilePtr,Init(@self,tabletop,i,-1,-1));
		InsertTabletop(tabletop,Foundations[i]);
	end;
	stock:=New(PStandardStockpile,Init(@self,tabletop,52,-1,-1));
	InsertTabletop(tabletop, stock);
	InsertTabletop(tabletop, Wastepile);
	stock^.CardCountOn;
end;

constructor OKlondikegame.Construct(tabletop:SolTableViewP);
var
	i:integer;
begin
	inherited Init(GID_KLONDIKE,tabletop);
	for i:=1 to NTABLEAUS do begin
		Tableaus[i]:=New(TableauPileBasePtr,Construct(@self,i,i+11,False,-1,-1,0,0));
		InsertTabletop(tabletop,Tableaus[i]);
	end;
	for i:=1 to NFOUNDATIONS do begin
		Foundations[i]:=New(KondikeFndtnPileBase_ptr,Init(@self,tabletop,i,-1,-1));
		InsertTabletop(tabletop,Foundations[i]);
	end;
	stock:=New(PKlondikeStockpile,Init(tabletop,52,-1,-1));
	InsertTabletop(tabletop, stock);
	InsertTabletop(tabletop, Wastepile);
//	stock^.CardCountOn;
end;

procedure OKlondikegame.OnDeal;
var
	i,j:integer;
begin
	inherited OnDeal;
	for i:=1 to NTABLEAUS do for j:=i to NTABLEAUS do deck_prop.DealTo(Tableaus[j],i=j);
	deck_prop.TransferTo(stock);
end;

procedure OBasegame.Setup;
begin
	inherited Setup;
end;

procedure OKlondikegame.Setup;
begin
	inherited Setup;
end;

procedure OStandardgame.OnDeal;
var
	i,j:integer;
begin
	inherited OnDeal;
	for i:=1 to NTABLEAUS do for j:=i to NTABLEAUS do deck_prop.DealTo(Tableaus[j],i=j);
	deck_prop.TransferTo(stock);
end;

procedure OStandardgame.Setup;
begin
	inherited Setup;
	if Variation=0 then with Wastepile^ do SetCardDx(PipHSpace);
end;

function OBasegame.Score:TScore;
var
	s:TScore;
	i:integer;
begin
	s:=0;
	for i:=1 to NFOUNDATIONS do with Foundations[i]^ do Inc(s, size);
	Score:=StartingScore-s;
end;

function TableauPileBase.Accepts(tc:TCard):boolean;
begin
	Accepts:=
		{$ifdef TEST_TAB_ACCEPTS_ANY_CARD}
		TRUE;
		{$else}
		(inherited Accepts(tc))
		or
		((size=0) and (CardPip(tc)=TKING));
		{$endif}
end;

constructor TableauPileBase.Construct(game:SolGameP;No,N:integer;FaceUp:boolean; X,Y,DX,DY:integer);
begin
	inherited Init(game,SolTableViewP(game^.MyTabletop), No,N,FaceUp, X, Y, DX, DY);
	AppendDesc('All faceup cards ');
	if game^.GetGameId=GID_STANDARD then AppendDesc('(in whole or in part) ');
	AppendDesc('can be moved as a unit. ');
	AppendDesc('Spaces can only be filled with Kings. ');
end;

procedure AutoAce(Pile:OFannedPileProp_ptr);
begin
	Pile^.TryTopcardToDblClkTargets;
end;

procedure OKlondikeStockpile.OnTopcardFlipped;
begin //writeln('OKlondikeStockpile.OnTopcardFlipped');
	if AceUp then AutoAce(@Self);
end;

constructor OStandardStockpile.Init(a_pGame:OStandardgame_ptr;tabletop:SolTableViewP;n,X,Y:integer);
begin
	inherited Construct(a_pGame, 'Hand');
	m_outlined:= TRUE;
	HasTarget:=True;
	TargetState:=True;
end;

constructor OKlondikeStockpile.Init(tabletop:SolTableViewP;n,X,Y:integer);
begin
	inherited Construct(thegame,tabletop,n,0);
end;

procedure OStandardStockpile.Selected;
var
	i:integer;
	c:TCard;
begin
	CardCountOff;
	with TheGame^ do begin
		Wastepile^.snapAllTo(@self);
	end;
	Flip;
	CardCountOn;
end;

var
	Foo:boolean;
	jFoo:integer;

function OWastepile.GetCardX(p_index:integer):integer;
begin
	getCardX:= ((p_index - 1) div 3) * (optXSpace * 5 div 6);
end;

procedure OStandardStockpile.TopSelected;
const
	M:array[0..1] of integer=(4,2);
begin
	CardCountOff;
	with TheGame^ do begin
		Foo:= True;
		jFoo:= 1;
		while (size>0) and (jFoo < M[Variation]) do begin
			TopcardTo(Wastepile);
			Inc(jFoo);
		end;
		Foo:= False;
	end;
	CardCountOn;
end;

procedure OKlondikeStockpile.TopSelected;
begin
	if TopFaceUp then
		TopcardTo(OCardpileProp_ptr(TheGame^.Wastepile))
	else
		inherited TopSelected;
end;

procedure TableauPileBase.OnTopcardFlipped;
begin
	inherited OnTopcardFlipped;
	if TopFaceUp then if (SolGameP(mytabletop^.mygame)^.GetGameId=GID_KLONDIKE) and AceUp then AutoAce(@Self) else SetCardDy(PipVSpace);
end;

procedure StandardTabPile.OnCardAdded;
begin
	UpdateScoreWindow(SolGameP(mytabletop^.mygame));
end;

function StandardTabPile.CanGrabUnit(aIndex:integer):boolean;

begin
	CanGrabUnit:=(aIndex < Size) and IsFaceup(aIndex);
end;

function TabPosX(Ordinal:integer):integer;
begin
	TabPosX:=Center(TheGame^.ColumnSpan(NTABLEAUS),0,TheGame^.MyTabletop^.ClientWidth)+TheGame^.ColumnOffset(Ordinal-1);
end;

function TabPosY(Ordinal:integer):integer;
begin
	TabPosY:=MIN_EDGE_MARGIN+TheGame^.RowOffset(1);
end;

function TableauPileBase.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	SetCardDY(PipVSpace);
	GetAnchorPoint:=MakeXYPair(TabPosX(Ordinal),TabPosY(Ordinal));
end;

function OStockpilePropShared.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with TheGame^ do GetAnchorPoint:=MakeXYPair(TabPosX(1), TabPosY(1)-RowOffset(1));
end;

function OStandardStockpile.GetAnchorPoint(table_width,table_height:word):xypair;
begin
	with TheGame^ do GetAnchorPoint:=MakeXYPair(TabPosX(1), TabPosY(1)-RowOffset(1));
end;

function OWastepile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with TheGame^ do GetAnchorPoint:=MakeXYPair(TabPosX(2),TabPosY(1)-RowOffset(1));
end;

function KondikeFndtnPileBase.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with TheGame^ do GetAnchorPoint:=MakeXYPair(TabPosX(4)+ColumnOffset(FoundNo-1),TabPosY(1)-RowOffset(1));
end;

constructor StandardFndtnPile.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,X,Y);
	AppendDesc('The top card is always available for play back to the Tableaus.');
end;

function OBasegame.PileRows:word; 
begin 
	PileRows:=4; 
end;

function OBasegame.PileColumns:word; 
begin 
	PileColumns:=8; 
end;

function OStandardgame.VariationCount:quantity;
begin
	VariationCount:=1;
end;

function OStandardgame.VariationName(n:quantity):pchar;
begin
	System.Assert(n<=VariationCount,'OStandardgame.VariationName: index out of range');
	case n of
		0:VariationName:=inherited VariationName(n);
		1:VariationName:='Deal Singles';
	end;
end;

end.
