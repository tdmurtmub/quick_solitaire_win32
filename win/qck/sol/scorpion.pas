(***********************************************************************
Copyright (C) 1998-2002 by Wesley Steiner {BP7}
All rights reserved.
***********************************************************************)

(**********************************************************************

History:
	2002/10/13	WES	Fix scoring algorithm.
	1998/11/21	WES	Consolidating units.
	1998/01/01	WES	Created.

***********************************************************************)

unit BSScorp;

interface

{$I BSGINC}

const
	n_Piles=7;

type
	PScoTableau = ^TScoTableau;
	TScoTableau = object(TTableauSuit)
		constructor Init(i:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		procedure topFlip; virtual;
		procedure topGet; virtual;
		function canGrabUnit(a_index:integer):boolean; virtual;
		procedure DropOntop(const p_x:integer; const p_y:integer); virtual;
			{ 10-13-02: Added to override this method to update score during
				tableau moves. }
	end;

	Scorpion_Reserve_Item_P = ^Scorpion_Reserve_Item;
	Scorpion_Reserve_Item = object(TActionPile)
		constructor Init;
		procedure topSelected; virtual;
	end;

	PScoGame=^ScorpionGame;
	ScorpionGame=object(SolGame)
		Piles:array[1..n_Piles] of PScoTableau;
		Reserve:Scorpion_Reserve_Item_P;
		constructor Init;
		procedure Setup; virtual;
		{procedure Start; virtual;}
		function Score:TScore; virtual;
		function CardSize:TCardSize; virtual;
	end;


implementation

uses
	Std, WinTypes, WinProcs, StdWin, Strings;

var
	TheGame:PScoGame;

constructor ScorpionGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Scorpion);
		TheGame:=@Self;
		for i:=1 to n_Piles do Piles[i]:=New(PScoTableau,Init(i));
		Reserve:=New(Scorpion_Reserve_Item_P,Init);
		with x_aSolApp.Tabletop^ do begin
			for i:=1 to n_Piles do Insert(Piles[i]);
			Insert(Reserve);
		end;
	end;

procedure ScorpionGame.Setup;

	var
		i,j:integer;

	begin
		inherited Setup;
		Draw;
		for j:=1 to n_Piles do for i:=1 to n_Piles do with Piles[i]^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			if ((i>4) or (j>3)) then topFlip;
			topDraw;
		end;
		for i:=1 to 3 do with Reserve^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			topDraw;
		end;
	end;

function TScoTableau.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			or
			(
				IsEmpty
				and
				(CardPip(aCard) = TKING)
			);
	end;

constructor TScoTableau.Init;

	begin
		with TheGame^,x_engine do inherited Init(QuickViewP(TabletopView),
			i,52,False,
			Centered(ColEx(n_Piles),0,AppMaxX)+(i-1)*ColDX,
			MIN_EDGE_MARGIN,
			0,PipVSpace);
		AppendDesc('Spaces can only be filled with a King or a build with a King at the bottom. ');
	end;

procedure TScoTableau.topFlip;

	begin
		inherited topFlip;
		topSetUnit(topFaceUp);
		if (x_score_window <> nil) then UpdateScoreWindow(SolGameP(myGame));
	end;

procedure TScoTableau.topGet;

	var
		i:integer;

	begin
		inherited topGet;
		UpdateScoreWindow;
	end;

procedure Scorpion_Reserve_Item.topSelected;

	var
		i:integer;

	begin
		for i:=1 to 3 do begin
			TopcardTo(TheGame^.Piles[i]);
			TheGame^.Piles[i]^.topFlip;
		end;
	end;

constructor Scorpion_Reserve_Item.Init;

	begin
		inherited Init('Reserve',3,False,
			MIN_EDGE_MARGIN,
			AppMaxY - BUTTON_BAR_HT - RowDY,
			x_engine.PipHSpace,0);
		AppendDesc('Selecting this pile deals all the cards to the first three tableau columns. ');
		AppendDesc('Game is won if all four suits are assembled in descending sequence upon the Kings. ');
	end;

function ScorpionGame.Score;

	var
		s:TScore;
		i,j:integer;

	begin
		{$ifdef DEBUG}
		{MessageBox(0, 'scoring...', nil, MB_OK);}
		{$endif}
			{ 10-09-02: Added this debug code to see when we get here. }

		s:= 0;
		for i:= 1 to n_piles do with Piles[i]^ do if Size > 1 then begin
			j:= 1;

			{ Skip face down cards. }
			while (j <= Size) and (IsFacedown(j)) do Inc(j);

			{ Look for start of a king sequence. }
			while (j <= Size) do
			begin
				if (CardPip(Get(j)) = TKING) then
				begin
					Inc(s);

					{ Count up the cards in sequence. }
					while
							((j + 1) <= Size)
							and
							(
								(CardSuit(Get(j + 1)) = CardSuit(Get(j)))
								and
								(CardPip(Get(j + 1)) = Pred(CardPip(Get(j)))
								)
							) do
					begin
						Inc(s);
						Inc(j);
					end;
				end;
				Inc(j);
			end;
		end;
		Score:= (inherited Score) - s;
	end;
	{ 10-20-02: Fixed this score algorithm. }

function TScoTableau.canGrabUnit(a_index:integer):boolean;

begin
	canGrabUnit:= (a_index < size) and IsFaceup(a_index);
end;

procedure TScoTableau.DropOntop(const p_x:integer; const p_y:integer);

	begin
		inherited dropOntop(p_x, p_y);
		if (x_score_window <> nil) then UpdateScoreWindow;
	end;

function ScorpionGame.CardSize:TCardSize;
	begin
		CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
	end;

end.
