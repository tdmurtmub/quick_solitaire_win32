{ (C) 1998 Wesley Steiner }

unit spider;

{$ifdef DEBUG}
{!$define TEST_WINNING}
{$endif}

interface

uses
	std,cards,
	winqcktbl,
	winsoltbl;

const
	N_TABLEAUS=10;
	N_DISCARDS=8;

type
	TableauPilePtr=^TableauPile;
	TableauPile=object(TTableauDn)
		constructor Init(No:integer);
		function Accepts(tc:TCard):boolean; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnCardAdded virtual;
		procedure dropOntop(p_x,p_y:integer); virtual;
	end;

	StockPilePtr=^StockPile;
	StockPile=object(TActionPile)
		constructor Construct;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure topSelected; virtual;
	end;

	DiscardPilePtr=^DiscardPile;
	DiscardPile=object(DiscardPileProp)
		constructor Construct(aOrdinal:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		function CanGrabCardAt(a_index:integer):boolean; virtual;
		function GetAnchorPoint(table_width, table_height:word):xypair; virtual;
		procedure OnCardAdded virtual;
	end;

	OSpidergame_ptr=^Spidergame;
	Spidergame=object(SolGame)
		myTableaus:array[1..N_TABLEAUS] of TableauPilePtr;
		myStockPile:StockPilePtr;
		myDiscardPile:array[1..N_DISCARDS] of DiscardPilePtr;
		constructor Construct(tabletop:SolTableViewP);
		function PileRows:word; virtual;
		function PileColumns:word; virtual;
		function Score:TScore; virtual;
		procedure Setup; virtual;
		procedure OnDeal; virtual;
	end;

implementation

uses
	strings,
	xy,
	qcktbl,
	stdwin,
	winCardfactory;

var
	the_game:OSpidergame_ptr;

const
	spi_TabMax= 6 + 52; { cards in a tab pile }

constructor Spidergame.Construct(tabletop:SolTableViewP);
var
	i:integer;
begin
	inherited Construct(GID_SPIDER,tabletop);
	the_game:=@Self;
	for i:=1 to N_TABLEAUS do begin
		myTableaus[i]:=New(TableauPilePtr,Init(i));
		InsertTabletop(tabletop,myTableaus[i]);
	end;
	myStockPile:=New(StockPilePtr,Construct);
	InsertTabletop(tabletop,myStockPile);
	myStockPile^.CardCountOn;
	for i:=1 to N_DISCARDS do begin
		myDiscardPile[i]:=New(DiscardPilePtr,Construct(i));
		InsertTabletop(tabletop,myDiscardPile[i]);
	end;
end;

procedure Spidergame.Setup;
var
	i:integer;
	{$ifdef TEST_WINNING} 
	procedure TestWinningSetup; 
	var
		i:integer;
	begin
		for i:=1 to 104 do Deck^.Ref(i)^:=MakeCard(i mod 13,SPADE);
	end;

	{$endif}
begin
	inherited Setup;
	{$ifdef TEST_WINNING} TestWinningSetup; {$endif}
	for i:=1 to N_DISCARDS do myDiscardPile[i]^.Refresh;
end;

procedure Spidergame.OnDeal;
var
	i,j:integer;
begin //writeln('Spidergame.OnDeal');
	inherited OnDeal;
	for i:=1 to 4 do for j:=1 to N_TABLEAUS do deck_prop.DealTo(myTableaus[j]);
	for i:=1 to 4 do deck_prop.DealTo(myTableaus[i]);
	for i:=1 to N_TABLEAUS do deck_prop.DealTo(myTableaus[i],TRUE);
	deck_prop.TransferTo(myStockPile);
end;

function TableauPile.Accepts(tc:TCard):boolean;
begin
	Accepts:=(inherited Accepts(tc)) or IsEmpty;
end;

constructor TableauPile.Init(No:integer);
begin
	inherited Init(the_game,SolTableViewP(the_game^.MyTabletop),No,spi_TabMax,FALSE,0,0,0,PipVSpace);
	AppendDesc('in rank regardless of suit.');
	AppendDesc('A descending sequence in suit can be moved in whole or in part.');
	AppendDesc('A space made by removal of an entire pile may be filled with any available card or group.');
end;

function Spidergame.Score:TScore;
var
	i:integer;
	s:TScore;
begin
	s:=StartingScore;
	for i:=1 to N_DISCARDS do s:=s-myDiscardPile[i]^.size;
	Score:=s;
end;

procedure StockPile.topSelected;
var
	i:integer;
begin
	if IsEmpty then
		inherited topSelected
	else begin
		CardCountOff;
		for i:=1 to N_TABLEAUS do if the_game^.myTableaus[i]^.IsEmpty then begin
			Help;
			CardCountOn;
			Exit;
		end;
		for i:=1 to N_TABLEAUS do if the_game^.myTableaus[i]^.size < spi_TabMax then DealTo(the_game^.myTableaus[i],TRUE);
		CardCountOn;
	end;
end;

procedure DiscardPile.OnCardAdded;
begin // Writeln('DiscardPile.OnCardAdded');
	UpdateScoreWindow(SolGameP(mytabletop^.mygame));
end;

function DiscardPile.Accepts(aCard:TCard):boolean;
begin
	Accepts:=(inherited Accepts(aCard)) and UnitDragging and (CardPip(aCard)=TKING) and (CardPip(theGrabbedCards^.gettop)=TACE);
end;

constructor StockPile.Construct;
begin
	inherited Construct(the_game, 'Hand');
	HasTarget:=True;
	TargetState:=False;
	AppendDesc('After play is blocked you can select this pile to deal another 10 cards to the tableau. ');
	AppendDesc('Every space in the Tableau must be filled before a new row can be dealt. ');
end;

constructor DiscardPile.Construct(aOrdinal:integer);
begin
	inherited Init(the_game, 13);
	SetCardDx(0);
	Ordinal:=aOrdinal;
	AppendDesc('Completed tableau piles in suit from Kings down to Aces can be discarded to this pile.');
	AppendDesc('Game is won if all the cards are discarded in this way.');
end;

procedure TableauPile.DropOntop(p_x,p_y:integer);
var
	i:integer;
	procedure InSeq(i:integer);
	begin
		IsUnit[i]:=
			IsFaceUp(i)
			and
			(CardSuit(get(i))=CardSuit(get(i+1)))
			and
			(CardPip(get(i))=Succ(CardPip(get(i+1))));
		if IsUnit[i] and (i>1) then InSeq(i-1);
	end;
begin //Writeln('TableauPile.dropOntop');
	inherited dropOntop(p_x, p_y);
	for i:=1 to size do IsUnit[i]:=False;
	if size > 1 then InSeq(size - 1);
end;

function TableauPile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with the_game^ do begin
		SetCardDY(PipVSpace);
		GetAnchorPoint:=MakeXYPair(Centered(ColumnSpan(11),0,table_width)+ColumnOffset(Ordinal),MIN_EDGE_MARGIN);
	end;
end;

function Spidergame.PileRows:word;
begin
	PileRows:=6;
end;

function Spidergame.PileColumns:word;
begin
	PileColumns:=N_TABLEAUS+1;
end;

function StockPile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with the_game^,MyTabletop^ do GetAnchorPoint:=MakeXYPair(myTableaus[1]^.Anchor.X-ColumnOffset(1),Margin);
end;

function DiscardPile.GetAnchorPoint(table_width, table_height:word):xypair;
begin
	with the_game^,MyTabletop^ do GetAnchorPoint:=MakeXYPair(Margin+(Ordinal-1)*((table_width-Margin-CurrentWidth) div (N_DISCARDS-1)),table_height-Margin-CurrentHeight);
end;

procedure TableauPile.OnCardAdded;

var
	i:integer;

	procedure InSeq(i:integer);
	begin
		IsUnit[i]:=
			IsFaceUp(i)
			and
			(CardSuit(get(i))=CardSuit(get(i+1)))
			and
			(CardPip(get(i))=Succ(CardPip(get(i+1))));
		if IsUnit[i] and (i>1) then InSeq(i-1);
	end;

begin //Writeln('TableauPile.OnCardAdded(',n,')');
	for i:=1 to size do IsUnit[i]:=False;
	if size > 1 then InSeq(size - 1);
end;

function DiscardPile.CanGrabCardAt(a_index:integer):boolean;
begin
	CanGrabCardAt:=FALSE;
end;

end.
