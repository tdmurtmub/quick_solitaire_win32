(***********************************************************************
Copyright (c) 1998 by Wesley Steiner
All rights reserved.
***********************************************************************)

(**********************************************************************

Purpose:

Platforms:
	Borland Pascal 7.0

Comments:

History:
	1998/11/21	WES	Consolidating units.
	1998/01/01	WES	Created.

***********************************************************************)

unit BSCarpet;

interface

{$I BSGINC}

const
	Decks		= 1;
	Redeals	= 0;
	nCols		= 5;
	nRows		= 4;
	n_Piles	= nCols * nRows;

type
	Carpet_Pile_Item_P = ^Carpet_Pile_Item;
	Carpet_Pile_Item = object(OWastepileProp)
		constructor Init(X,Y:integer);
		function Accepts(aCard:TCard):boolean; virtual;
	end;

	Carpet_Foundation_Item_P = ^Carpet_Foundation_Item;
	Carpet_Foundation_Item = object(TFoundUpInSuit)
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;

	Carpet_Hand_Item_P = ^Carpet_Hand_Item;
	Carpet_Hand_Item = object(OStockpileProp)
		constructor Init;
		procedure topSelected; virtual;
	end;

	Carpet_Waste_Item_P=^Carpet_Waste_Item;
	Carpet_Waste_Item=object(OWastepileProp)
		constructor Init(x,y:integer);
		{procedure topSelected;}
	end;

	PCarpetGame=^CarpetGame;
	CarpetGame=object(SolGame)
		Founds:array[1..4] of Carpet_Foundation_Item_P;
		Piles:array[1..n_Piles] of Carpet_Pile_Item_P;
		HandPile:Carpet_Hand_Item_P;
		WastePile:Carpet_Waste_Item_P;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function CardSize:TCardSize; virtual;
		{function GameIsLost:boolean; virtual;}
		{function FoundationFit(aCard:TCard):integer;}
	end;

implementation

uses
	Std, StdWin, WinTypes,WinProcs,Strings;

var
	TheGame:PCarpetGame;

constructor CarpetGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Carpet);
		TheGame:=@Self;
		with x_engine do begin
			{ Piles }
			for i:=1 to n_Piles do begin
				Piles[i]:=New(Carpet_Pile_Item_P,Init(
					Centered(ColEx(nCols),0,AppMaxX)+((i-1) mod nCols)*ColDX,
					Centered(RowEx(nRows+1),0,AppMaxY)+RowDY+((i-1) div nCols)*RowDY
					));
				x_aSolApp.Tabletop^.Insert(Piles[i]);
			end;
			HandPile:=New(Carpet_Hand_Item_P, init);
			with x_aSolApp.Tabletop^ do begin
				Insert(HandPile);
			end;
			WastePile:=New(Carpet_Waste_Item_P, Init(HandPile^.Anchor.X+ColDX,HandPile^.Anchor.Y));
			x_aSolApp.Tabletop^.Insert(WastePile);
			{ foundations }
			for i:=1 to 4 do begin
				Founds[i]:=New(Carpet_Foundation_Item_P,Init(i,
					Centered(ColEx(nCols+2),0,AppMaxX)+((i-1) mod 2)*ColDX*(nCols+1),
					Centered(CardImageHt,Piles[((i-1) div 2)*10+1]^.Anchor.Y,Piles[((i-1) div 2)*10+6]^.Span.bottom)
					));
				x_aSolApp.Tabletop^.Insert(Founds[i]);
			end;
		end;
	end;

procedure CarpetGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		for i:=1 to 4 do begin
			with Founds[i]^ do begin
				topAdd(DeckPullPip(Deck, 1, TACE));
				topFlip;
			end;
		end;
		Draw;
		DeckToPile(1, Deck, HandPile);
		HandPile^.Refresh;
	end;


procedure CarpetGame.Start;

	var
		i:integer;

	begin
		for i:=1 to n_Piles do HandPile^.TopcardTo(Piles[i]);
		inherited Start;
	end;


{function Carpet_Pile_Item.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			;
	end;}

constructor Carpet_Pile_Item.Init;

	begin
		inherited Init(thegame, 1,X,Y,0,0);
		AppendDesc('Spaces may only be filled with cards from the hand or waste pile. ');
	end;

function CarpetGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to 4 do with Founds[i]^ do Inc(s,Size);
		Score:=StartingScore-s;
	end;

constructor Carpet_Hand_Item.Init;

	begin
		inherited Init(thegame, 52*2-8,
			Centered(ColEx(2),0,AppMaxX),
			TheGame^.Piles[1]^.Anchor.Y-RowDY,
			0);
		{SetDesc('Top card is available for play to the foundations at any time. ' );}
	end;

procedure Carpet_Hand_Item.topSelected;

	begin
		if topFaceUp then
			TopcardTo(TheGame^.WastePile)
		else
			inherited topSelected;
	end;


function Carpet_Pile_Item.Accepts;

	begin
		Accepts:=
			IsEmpty
			and
			(StriComp(grabbed_from^.m_tag,'Tableau') <> 0);
	end;

constructor Carpet_Waste_Item.Init;

	begin
		inherited Init(thegame, 52-4-n_Piles,x,y,0,0);
		{
		SetDesc('Top card is available for play to the foundations at any time. ' );
		AppendDesc('When you play the top card to a waste pile you must continue to do so until 20 cards ');
		AppendDesc('have been played to Waste piles before you can play up to the foundations again.');
		}
	end;

function CarpetGame.CardSize:TCardSize;
	begin
		CardSize:= MediumCards;
	end;

end.
