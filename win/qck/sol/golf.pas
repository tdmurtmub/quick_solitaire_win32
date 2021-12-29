{ (C) 1998 Wesley Steiner }

{$MODE FPC}

unit golf;

interface

uses
	std,cards,
	winqcktbl,
	winsoltbl;

const
	NTABLEAUS=7;

type
	OTableaupile=object(OFannedPileProp) 
		constructor Construct(aTabNo:integer);
		function CanGrabCardAt(aIndex:integer):boolean; virtual;
		function GetAnchorPoint(aNewWd,aNewHt:word):xypair; virtual;
		function OnTopcardTapped:boolean; virtual;
	private
		myTabNo:integer;
	end;

	OStockpile=object(TActionPile)
		constructor Construct;
		function OnTopcardTapped:boolean; virtual;
		function GetAnchorPoint(aNewWd,aNewHt:word):xypair; virtual;
	end;

	OFoundationpile=object(DiscardPileProp)
		constructor Construct(game:SolGameBaseP);
		function Accepts(tc:TCard):boolean; virtual;
		function GetAnchorPoint(aNewWd,aNewHt:word):xypair; virtual;
		procedure OnCardAdded; virtual;
	end;

	OGolfgame_ptr=^OGolfgame;
	OGolfgame=object(SolGame)
		tableau:array[1..NTABLEAUS] of OTableaupile;
		stock:OStockpile;
		foundation:OFoundationpile;
		constructor Construct(tabletop:SolTableViewP);
		function PlayIsBlocked:boolean; virtual;
		function PileRows:word; virtual;
		function PileColumns:word; virtual;
		function Score:TScore; virtual;
		procedure OnDeal; virtual;
	end;

implementation

uses
	xy,
	qcktbl;

var
	theGame:^OGolfgame;

function TabDeltaY:integer;
begin
	TabDeltaY:=CurrentHeight div 4;
end;

constructor OGolfgame.Construct(tabletop:SolTableViewP);
var
	aTabNo:integer;
begin
	inherited Construct(GID_GOLF,tabletop);
	TheGame:=@Self;
	for aTabNo:= 1 to NTABLEAUS do begin
		tableau[aTabNo].Construct(aTabNo);
		tabletop^.AddProp(@tableau[aTabNo]);
	end;
	stock.Construct;
	tabletop^.AddProp(@stock);
	stock.CardCountOn;
	foundation.Construct(@self);
	tabletop^.AddProp(@foundation);
end;

procedure OGolfgame.OnDeal;
var
	i,j:integer;
begin
	inherited OnDeal;
	for i:=1 to 5 do for j:=1 to NTABLEAUS do deck_prop.DealTo(@tableau[j],TRUE);
	deck_prop.TransferTo(@stock);
	stock.TopcardTo(@foundation);
end;

function OFoundationpile.Accepts(tc:TCard):boolean;
begin
	Accepts:=(CardPip(Topcard)<>TKING) and ((CardPip(tc)=Succ(CardPip(Topcard))) or ((CardPip(Topcard)<>TACE) and (CardPip(tc)=Pred(CardPip(Topcard)))));
end;

function OTableaupile.OnTopcardTapped:boolean;
begin //writeln('OTableaupile.OnTopcardTapped');
	with OGolfgame_ptr(mytabletop^.mygame)^ do if foundation.Accepts(Topcard) then TopcardTo(@foundation);
	OnTopcardTapped:=TRUE;
end;

function OStockpile.OnTopcardTapped:boolean;
begin
	OnTopcardTapped:=TRUE;
	if IsEmpty then OnTopcardTapped:=inherited OnTopcardTapped
	else TopcardTo(@OGolfgame_ptr(mytabletop^.mygame)^.foundation);
end;

procedure OFoundationpile.OnCardAdded;
begin //writeln('OFoundationpile.OnCardAdded');
	inherited OnCardAdded;
	winsoltbl.UpdateScoreWindow(SolGameP(mytabletop^.mygame));
end;

function OGolfgame.Score:TScore;
begin
	Score:=StartingScore-foundation.size;
end;

function OGolfgame.PlayIsBlocked:boolean;

	function NoPlay:boolean;
	var
		i:integer;
	begin
		NoPlay:=True;
		for i:=1 to NTABLEAUS do with tableau[i] do
			if (not IsEmpty) and foundation.Accepts(Topcard) then begin
				NoPlay:=False;
				Exit;
			end;
	end;

begin //writeln('OGolfgame.PlayIsBlocked');
	PlayIsBlocked:=deck_prop.IsEmpty and (stock.IsEmpty and NoPlay);
end;

constructor OTableaupile.Construct(aTabNo:integer);
begin
	inherited Construct;
	myTabNo:=aTabNo;
	m_outlined:=false;
	AppendDesc('Cards can be played to the foundation in sequence, up or down, regardless of suit.');
	AppendDesc('Sequence is not circular and nothing can be built on a King.');
end;

function OTableaupile.GetAnchorPoint(aNewWd,aNewHt:word):xypair;
begin
	SetCardDy(TabDeltaY);
	with mytabletop^.mygame^ do GetAnchorPoint:=MakeXYPair(Integer(Center(ColumnSpan(NTABLEAUS),0,aNewWd)+ColumnOffset(myTabNo-1)),Integer(Center(RowSpan(2)+TabDeltaY*4,0,aNewHt)));
end;

function OStockpile.GetAnchorPoint(aNewWd,aNewHt:word):xypair;
begin
	with OGolfgame_ptr(mytabletop^.mygame)^ do GetAnchorPoint:=MakeXYPair(tableau[3].Anchor.X,tableau[1].Anchor.Y+(CurrentHeight div 4)*4+CurrentHeight+MIN_EDGE_MARGIN);
end;

function OFoundationpile.GetAnchorPoint(aNewWd,aNewHt:word):xypair;
begin
	with OGolfgame_ptr(mytabletop^.mygame)^ do GetAnchorPoint:=MakeXYPair(Integer(Center(ColumnSpan(1),0,aNewWd)),stock.Anchor.Y);
end;

function OGolfgame.PileRows:word; begin PileRows:=4; end;
function OGolfgame.PileColumns:word; begin PileColumns:=NTABLEAUS+1; end;

constructor OFoundationpile.Construct(game:SolGameBaseP);
begin
	inherited Init(game, 52);
	CardsSetName(thePile^,'Foundation');
	m_outlined:=FALSE;
	SetCardDx(0);
	Disable;
end;

constructor OStockpile.Construct;
begin
	inherited Construct(theGame, 'Stock');
	HasTarget:=TRUE;
	TargetState:=FALSE;
	AppendDesc('When play is blocked select this pile to deal the next card to the foundation.');
end;

function OTableaupile.CanGrabCardAt(aIndex:integer):boolean;
begin
	CanGrabCardAt:=FALSE;
end;

end.
