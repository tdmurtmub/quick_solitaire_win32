(***********************************************************************
Copyright (c) 1998-2005 by Wesley Steiner
All rights reserved.
***********************************************************************)

unit BSChess;

interface

{$I BSGINC}

const
	n_Piles=10;
	n_Founds=4;

type
	Chess_Tableau_Item_P = ^Chess_Tableau_Item;
	Chess_Tableau_Item = object(TTableauUDInSuit)
		constructor	Init(i:integer);
		function 	canGrabUnit(a_index:integer):boolean; virtual;
	end;

	PChsFound=^TChsFound;
	TChsFound=object(TFoundUpInSuit)
		constructor Init(i:integer);
		function Accepts(aCard:TCard):boolean; virtual;
	end;

	PChsGame=^ChessBoardGame;
	ChessBoardGame=object(SolGame)
		Founds:array[1..n_Founds] of PChsFound;
		Piles:array[1..n_Piles] of Chess_Tableau_Item_P;
		constructor Init;
		procedure Setup; virtual;
		function Score:TScore; virtual;
		function FoundationFit(aCard:TCard):integer;
		function CardSize:TCardSize; virtual;
	end;

implementation

uses
	Std, StdWin, WinProcs,Strings;

var
	TheGame:PChsGame;

constructor ChessBoardGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Chessboard);
		TheGame:=@Self;
		for i:=1 to n_Founds do Founds[i]:=New(PChsFound,Init(i));
		for i:=1 to n_Piles do Piles[i]:=New(Chess_Tableau_Item_P,Init(i));
		with x_aSolApp.Tabletop^ do begin
			for i:=1 to n_Piles do Insert(Piles[i]);
			for i:=1 to n_Founds do Insert(Founds[i]);
		end;
	end;

procedure ChessBoardGame.Setup;

	var
		i,j:integer;

	begin
		inherited Setup;
		Draw;
		for j:=1 to 5 do for i:=1 to n_Piles do with Piles[i]^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			topFlip;
			topDraw;
		end;
		with Piles[1]^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			topFlip;
			topDraw;
		end;
		with Piles[2]^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			topFlip;
			topDraw;
		end;
	end;

constructor Chess_Tableau_Item.Init;

	function Foo(i:integer):integer;

		begin
			case ((i-1) mod 2) of
				0:Foo:=-1;
				1:Foo:=+1;
			end;
		end;

	begin
		with TheGame^,x_engine do begin
			inherited Init(QuickViewP(TabletopView), i,52,True,
				Centered(CardImageWd,0,AppMaxX)+Foo(i)*(ColDX+ColSp),
				Centered(RowEx(5),0,AppMaxY)+((i-1) div 2)*RowDY,
				Foo(i)*PipHSpace*2,0);
		end;
		{?}{HasOutline:=False;}
		{AppendDesc('Spaces can only be filled with cards from the Hand or Pile piles. ');}
	end;

function ChessBoardGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to n_Founds do with Founds[i]^ do Inc(s, Size);
		Score:=(inherited Score)-s;
	end;

{procedure Chess_Tableau_Item.OnCardAdded;

	var
		i:integer;

	begin
		inherited OnCardAdded;
		if topFaceUp and AceUp then AutoAce(@Self);
	end;}

function ChessBoardGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to n_Founds do if Founds[i]^.Accepts(aCard) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;

{procedure TChsHand.topFlip;

	begin
		inherited topFlip;
		if AceUp then AutoAce(@Self);
	end;}

constructor TChsFound.Init;

	begin
		inherited Init(i,
			Centered(x_engine.CardImageWd,0,AppMaxX),
			Centered(RowEx(4),0,AppMaxY)+(i-1)*RowDY
			);
		BaseIsOpen:=True;
	end;

function TChsFound.Accepts;

	var
		i:integer;

	function AllEmpty:boolean;

		var
			i:integer;

		begin
			AllEmpty:=True;
			for i:=1 to n_Founds do if not TheGame^.Founds[i]^.IsEmpty then begin
				AllEmpty:=False;
				Exit;
			end;
		end;

	begin
		if AllEmpty then begin
			for i:=1 to n_Founds do with TheGame^.Founds[i]^ do begin
				SetBasePip(CardPip(aCard));
			end;
			Accepts:=True;
		end
		else
			Accepts:=(inherited Accepts(aCard));
	end;


function Chess_Tableau_Item.canGrabUnit(a_index:integer):boolean;
	begin
		canGrabUnit:= False;
	end;

function ChessBoardGame.CardSize:TCardSize;
	begin
		CardSize:= MediumCards;
	end;

end.
