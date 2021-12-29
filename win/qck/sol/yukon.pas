{ (C) 1998 Wesley Steiner }

{$MODE FPC}

unit yukon;

interface

uses
	std,cards,
	winqcktbl,
	winsoltbl;

const
	NPILES=7;
	NFOUNDATIONS=4;

type
	TableauPropP=^TableauProp;
	TableauProp=object(TTableauAlt)
		constructor Construct(aOrdinal:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		function GetAnchorPoint(aNewWd,aNewHt:word):xypair; virtual;
		function CanGrabUnit(aIndex:integer):boolean; virtual;
	end;

	FoundationPropP=^FoundationProp;
	FoundationProp=object(TFoundUpInSuit)
		constructor Construct(tabletop:SolTableViewP;aOrdinal:integer);
		function GetAnchorPoint(aNewWd,aNewHt:word):xypair; virtual;
	end;

	OYukongame_ptr=^OYukongame;
	OYukongame=object(SolGame)
		Founds:array[1..NFOUNDATIONS] of FoundationPropP;
		piles:array[1..NPILES] of TableauPropP;
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
	winCardFactory,
	stdwin;

var
	the_game:OYukongame_ptr;

constructor OYukongame.Construct(tabletop:SolTableViewP);
begin
	inherited Construct(GID_YUKON,tabletop);
	the_game:=@Self;
end;

procedure OYukongame.OnDeal;
var i,j:integer;
begin
	inherited OnDeal;
	for i:=1 to NPILES do for j:=1 to i do deck_prop.DealTo(piles[i],(j=i));
	for i:=2 to NPILES do for j:=1 to 4 do deck_prop.DealTo(piles[i],TRUE);
end;
 
procedure OYukongame.Setup;
var i:integer;
begin
	inherited Setup;
	for i:=1 to NPILES do piles[i]:=TableauPropP(MyTableTop^.AddProp(New(TableauPropP,Construct(i))));
	for i:=1 to NFOUNDATIONS do Founds[i]:=FoundationPropP(MyTableTop^.AddProp(New(FoundationPropP,Construct(winsoltbl.SolTableViewP(MyTabletop),i))));
end;

function TableauProp.Accepts(aCard:TCard):boolean;

begin
	Accepts:=(inherited Accepts(aCard)) or (IsEmpty and (CardPip(aCard)=TKING));
end;

constructor TableauProp.Construct(aOrdinal:integer);

begin
	inherited Init(the_game,SolTableViewP(the_game^.MyTabletop),aOrdinal,52,FALSE,0,0,0,0);
	AppendDesc('Partial piles may be moved as a unit.');
	AppendDesc('A space by removal of an entire pile can only filled by a King.');
end;

function OYukongame.Score:TScore;

var
	s:TScore;
	i:integer;

begin
	s:=0;
	for i:=1 to NFOUNDATIONS do with Founds[i]^ do Inc(s, Size);
	Score:=(inherited Score)-s;
end;

constructor FoundationProp.Construct(tabletop:SolTableViewP;aOrdinal:integer);
begin
	inherited Init(the_game,tabletop,aOrdinal,0,0);
end;

function TableauProp.CanGrabUnit(aIndex:integer):boolean;

begin //writeln('TableauProp.CanGrabUnit(aIndex:integer)');
	canGrabUnit:=(aIndex<size) and IsFaceup(aIndex);
end;

function OYukongame.PileRows:word;
begin
	PileRows:=5;
end;

function OYukongame.PileColumns:word;
begin
	PileColumns:=NPILES+1;
end;

function TableauProp.GetAnchorPoint(aNewWd,aNewHt:word):xypair;
begin
	with mytabletop^.mygame^ do 
		GetAnchorPoint:=MakeXYPair(
			Center(ColumnSpan(NPILES+1),0,Integer(aNewWd))+ColumnOffset(Word(Ordinal-1)),
			myTabletop^.Top+(NPILES-Ordinal)*PipVSpace);
	SetCardDy(PipVSpace);
end;

function FoundationProp.GetAnchorPoint(aNewWd,aNewHt:word):xypair;

begin
	with mytabletop^.mygame^ do 
		GetAnchorPoint:=MakeXYPair(
			Center(ColumnSpan(NPILES+1),0,Integer(aNewWd))+ColumnOffset(NPILES),
			Center(RowSpan(NFOUNDATIONS),0,aNewHt)+RowOffset(Ordinal-1));
end;

end.
