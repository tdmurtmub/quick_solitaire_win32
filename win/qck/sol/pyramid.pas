{ (C) 1998 Wesley Steiner }

{$I Platform}

{$ifdef DEBUG}
{$define ACCEPTS_ANY}
{$endif}

unit pyramid;

interface

uses
	std,cards,
	winqcktbl,
	winsoltbl;
	
const
	NTABLEAUS=28;

type
	OPyramidgame_ptr=^OPyramidgame;

	OTableaupile=object(GenericTableauPile) 
		constructor Construct(game:OPyramidgame_ptr; n:integer;x,y:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnCardAdded; virtual;
		procedure TopSelected; virtual;
	end;
	PTableauProp=^OTableaupile;

	PWastepile=^OWastepile;

	OStockpile=object(OStockpileProp) 
		constructor Construct(game:OPyramidgame_ptr; target:PWastepile);
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnTopcardFlipped; virtual;
		procedure TopSelected; virtual;
	private
		target_pile:PWastepile;
	end;
	PStockpile=^OStockpile;

	OWastepile=object(OWastepileProp) 
		constructor Construct;
		procedure OnCardAdded; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
	end;

	ODiscardpile=object(DiscardPileProp) 
		constructor Init(game:SolGameBaseP);
		function Accepts(aCard:TCard):boolean; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnCardAdded; virtual;
		Owner:OPyramidgame_ptr
	end;
	PDiscardProp=^ODiscardpile;

	OPyramidgame=object(SolGame)
		constructor Construct(tabletop:SolTableViewP);
		function PileRows:word; virtual;
		function PileColumns:word; virtual;
		function PileSpacing:integer; virtual;
	private
		myTableaus:array[1..NTABLEAUS] of PTableauProp;
		stockpile:PStockpile;
		wastepile:PWastepile;
		myDiscardPile:PDiscardProp;
		procedure OnDeal; virtual;
		function Score:TScore; virtual;
	end;

implementation

uses
	{$ifdef TEST} PUnit, {$endif}
	windows, strings,
	xy,
	windowsx,
	winCardFactory,
	stdwin;

constructor OPyramidgame.Construct(tabletop:SolTableViewP);
var
	i:integer;
begin
	inherited Construct(GID_PYRAMID,tabletop);
	for i:=1 to NTABLEAUS do begin
		myTableaus[i]:= New(PTableauProp, Construct(@self, i, 0, 0));
		with myTableaus[i]^ do m_outlined:=False;
		InsertTabletop(tabletop,myTableaus[i]);
	end;
	wastepile:=New(PWastepile, Construct);
	stockpile:=New(PStockpile, Construct(@self, wastepile));
	InsertTabletop(tabletop,wastepile);
//	wastepile^.CardCountOn;
	InsertTabletop(tabletop,stockpile);
//	stockpile^.CardCountOn;
	myDiscardPile:=New(PDiscardProp, Init(@self));
	InsertTabletop(tabletop,myDiscardPile);
end;

procedure OPyramidgame.OnDeal;
var
	i:integer;
begin
	inherited OnDeal;
	for i:=1 to NTABLEAUS do deck_prop.DealTo(myTableaus[i],TRUE);
	deck_prop.TransferTo(stockpile);
end;

function OPyramidgame.Score:TScore;
begin
	Score:=StartingScore-myDiscardPile^.size;
end;

function OTableaupile.Accepts(aCard:TCard):boolean;
begin
	Accepts:=
		{$ifdef ACCEPTS_ANY} 
		TRUE; 
		{$else}
		(inherited Accepts(aCard))
		and
		(not IsEmpty) and (not Covered) and (Ord(CardPip(aCard)) + Ord(CardPip(Topcard)) = 11);
		{$endif}
end;

constructor OTableaupile.Construct(game:OPyramidgame_ptr; n:integer;x,y:integer);
begin
	inherited Construct(game, SolTableViewP(game^.MyTabletop), n, 2, True, x, y, 0, 0);
	AppendDesc('Uncovered cards are available for discarding.');
	AppendDesc('Discard Kings singly and all others in pairs totaling 13.');
end;

procedure OTableaupile.OnCardAdded;
begin
	inherited OnCardAdded;
	if (size = 2) {$ifndef ACCEPTS_ANY} and (Ord(CardPip(get(1))) + Ord(CardPip(get(size))) = 11) {$endif} then begin
		TopcardTo(OPyramidgame_ptr(mytabletop^.mygame)^.myDiscardPile);
		TopcardTo(OPyramidgame_ptr(mytabletop^.mygame)^.myDiscardPile);
	end;
end;

procedure OStockpile.OnTopcardFlipped;
begin
	if CardPip(Topcard)=TKING then begin
		Delay(300);
		TopcardTo(OPyramidgame_ptr(mytabletop^.mygame)^.myDiscardPile);
	end;
end;

procedure OWastepile.OnCardAdded;
begin
	inherited OnCardAdded;
	if (size >= 2) and (Ord(CardPip(get(size - 1))) + Ord(CardPip(get(size))) = 11) then begin
		TopcardTo(OPyramidgame_ptr(mytabletop^.mygame)^.myDiscardPile);
		TopcardTo(OPyramidgame_ptr(mytabletop^.mygame)^.myDiscardPile);
	end;
end;

function ODiscardpile.Accepts(aCard:TCard):boolean;
begin
	Accepts:=(CardPip(aCard)=TKING);
end;

constructor OStockpile.Construct(game:OPyramidgame_ptr; target:PWastepile);
begin
//	myGame:=game;
	inherited Construct(game, NIL, 52, 0);
	self.target_pile:=target;
	AppendDesc('Discard the top card of this pile with cards from the layout to make pairs totalling 13.');
	AppendDesc('Kings are discarded automatically when they come up.');
	AppendDesc('Move unplayable cards to the Waste pile.');
end;

procedure OTableaupile.TopSelected;
begin
	if not covered then with OPyramidgame_ptr(mytabletop^.mygame)^ do if myDiscardPile^.Accepts(Topcard) then
		TopcardTo(myDiscardPile)
	else
		inherited TopSelected;
end;

constructor OWastepile.Construct;
begin
	inherited Construct;
	AppendDesc('Discard the top card of this pile with cards from the layout to make pairs totalling 13.');
end;

procedure ODiscardpile.OnCardAdded;
begin
	inherited OnCardAdded;
	UpdateScoreWindow(SolGameP(mytabletop^.mygame));
end;

procedure OStockpile.TopSelected;
begin
	if topFaceDown then
		inherited TopSelected
	else
		TopcardTo(target_pile);
end;

function ODiscardpile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with Owner^ do GetAnchorPoint:=MakeXYPair(Center(ColumnSpan(1),0,table_width), table_height*2);
end;

function OWastepile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with OPyramidgame_ptr(mytabletop^.mygame)^ do GetAnchorPoint:=MakeXYPair(myTableaus[28]^.Left,myTableaus[1]^.Top);
end;

constructor ODiscardpile.Init(game:SolGameBaseP);
begin
	inherited Init(game, 52);
	Owner:=OPyramidgame_ptr(game);
	SetCardDx(0);
end;

function OStockpile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with OPyramidgame_ptr(mytabletop^.mygame)^ do GetAnchorPoint:=MakeXYPair(myTableaus[22]^.Left, myTableaus[1]^.Top);
end;

function OTableaupile.GetAnchorPoint(table_width, table_height:word):xypair;

	function TabSpacing:integer;
	begin
		TabSpacing:=mytabletop^.mygame^.PileSpacing;
	end;

	function PyrDX:integer;
	begin
		PyrDX:=CurrentWidth+TabSpacing;
	end;

	function PyrEx(i:integer):integer;
	begin
		PyrEx:=PyrDX*(i)-TabSpacing;
	end;

	function PyrRowEx(i:integer):integer;
	begin
		PyrRowEx:=i*(CardImageHt*5 div 11);
	end;

	function TabX(game:OPyramidgame_ptr;i:integer;a_aTableWd:word):integer;
	begin
		if i=1 then TabX:=Center(PyrEx(1), 0, a_aTableWd)
		else if i=2 then TabX:=Center(PyrEx(2), 0, a_aTableWd)
		else if i=4 then TabX:=Center(PyrEx(3), 0, a_aTableWd)
		else if i=7 then TabX:=Center(PyrEx(4), 0, a_aTableWd)
		else if i=11 then TabX:=Center(PyrEx(5), 0, a_aTableWd)
		else if i=16 then TabX:=Center(PyrEx(6), 0, a_aTableWd)
		else if i=22 then TabX:=Center(PyrEx(7), 0, a_aTableWd)
		else TabX:=game^.myTableaus[i-1]^.Anchor.X+PyrDX;
	end;

	function TabY(game:OPyramidgame_ptr;i:integer;aNewHeight:word):integer;
	begin
		if i<2 then TabY:=Center(game^.RowSpan(game^.PileRows),0,aNewHeight)
		else if i<4 then TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(1)
		else if i<7 then TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(2)
		else if i<11 then TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(3)
		else if i<16 then TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(4)
		else if i<22 then TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(5)
		else TabY:=game^.myTableaus[1]^.Anchor.Y+PyrRowEx(6)
	end;
begin
	GetAnchorPoint:=MakeXYPair(
		TabX(OPyramidgame_ptr(mytabletop^.mygame), Ordinal, table_width), 
		TabY(OPyramidgame_ptr(mytabletop^.mygame), Ordinal, table_height));
end;

function OPyramidgame.PileRows:word; 
begin 
	PileRows:=4; 
end;

function OPyramidgame.PileColumns:word; 
begin 
	PileColumns:=8; 
end;

function OPyramidgame.PileSpacing:integer; 
begin 
	PileSpacing:=Min(20, MyTabletop^.ClientWidth div 40); 
end;

{$ifdef TEST}
begin
	Suite.Run('pyramid');
{$endif TEST}
end.
