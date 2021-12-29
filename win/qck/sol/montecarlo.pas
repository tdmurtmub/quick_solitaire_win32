(***********************************************************************
Copyright (c) 1998-2005 by Wesley Steiner
All rights reserved.
***********************************************************************)

unit BSMonte;

interface

{$I BSGINC}

const
	Decks=1;
	Redeals=0;
	n_Cols=5;
	n_Rows=5;
	n_Piles=n_Cols*n_Rows;

type
	PMonPile=^TMonPile;
	TMonPile=object(TTagPile)
		PileNo:integer;
		constructor Init(i:integer);
		procedure topSelected; virtual;
	end;
	PMonHand=^TMonHand;
	TMonHand=object(TActionPile)
		constructor Init;
		procedure Selected; virtual; { when the pile is empty }
		procedure topSelected; virtual; { when the pile has cards in it }
	end;
	PMonDiscard=^TMonDiscard;
	TMonDiscard=object(DiscardPileProp)
		constructor Init;
	end;
	PMonGame=^MonteCarloGame;
	MonteCarloGame=object(SolGame)
		Piles:array[1..n_Piles] of PMonPile;
		HandPile:PMonHand;
		Discards:PMonDiscard;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		procedure Arrange; { rearrange the cards in the tableau }
		function CardSize:TCardSize; virtual;
		{function GameIsLost:boolean; virtual;}
		{function FoundationFit(aCard:TCard):integer;}
	end;

implementation

uses
	Std,
	StdWin, WinTypes,WinProcs,Strings;

var
	TheGame:PMonGame;

constructor MonteCarloGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_MonteCarlo);
		TheGame:=@Self;
		with x_engine do begin
			{ Piles }
			for i:=1 to n_Piles do begin
				Piles[i]:=New(PMonPile,Init(i));
				x_aSolApp.Tabletop^.Insert(Piles[i]);
			end;
			HandPile:=New(PMonHand,Init);
			with x_aSolApp.Tabletop^ do begin
				Insert(HandPile);
			end;
			Discards:=New(PMonDiscard,Init);
			x_aSolApp.Tabletop^.Insert(Discards);
		end;
	end;

procedure MonteCarloGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		DeckToPile(1, Deck, HandPile);
		Draw;
	end;

procedure MonteCarloGame.Start;

	var
		i:integer;

	begin
		HandPile^.topSelected;
		inherited Start;
	end;

constructor TMonPile.Init;

	begin
		inherited Init('Tableau',1,True,
			Centered(ColEx(n_Cols+1),0,AppMaxX)+ColDX+((i-1) mod n_Cols)*ColDX,
			Centered(RowEx(n_Rows),0,AppMaxY)+((i-1) div n_Cols)*RowDY,
			0,0);
		{HasOutline:=False;}
		PileNo:=i;
		AppendDesc('Two cards of the same rank may be removed if they are adjacent ');
		AppendDesc('vertically, horizontally or diagonally. ');
	end;

function MonteCarloGame.Score;

	begin
		Score:=StartingScore-Discards^.Size;
	end;

constructor TMonHand.Init;

	begin
		inherited Init('Hand',52*2-8,False,
			TheGame^.Piles[1]^.Anchor.X-ColDX,
			Centered(RowEx(1),0,AppMaxY),
			0,0);
		{HasOutline:=False;}
		HasTarget:=True;
		TargetState:=True;
		AppendDesc('Selecting this pile causes the tableau to be ');
		AppendDesc('consolidated and the spaces filled with any remaining cards from this pile. ' );
	end;

constructor TMonDiscard.Init;

	begin
		inherited Init(52);
		SetCardDx(3);
		{
		SetDesc('The top card is available for play to the foundations at any time. ' );
		AppendDesc('When you play the top card to a waste pile you must continue to do so until 20 cards ');
		AppendDesc('have been played to Waste piles before you can play up to the foundations again.');
		}
	end;

procedure TMonPile.topSelected;

	function TotalTagged:integer;

		var
			i,t:integer;

		begin
			t:=0;
			with TheGame^ do for i:=1 to n_Piles do with Piles[i]^ do
				if (not IsEmpty) and Tagged then Inc(t);
			TotalTagged:=t;
		end;

	procedure DiscardThem;

		var
			i:integer;

		begin
			with TheGame^ do begin
				for i:=1 to n_Piles do with Piles[i]^ do if Tagged then begin
					topSelected;
					Piles[i]^.TopcardTo(Discards);
				end;
			end;
			x_score_window^.Update;
		end;

	function SameRank:boolean;

		var
			i,n:integer;
			Rank:array[1..2] of TPip;

		begin
			i:=0;
			n:=0;
			with TheGame^ do for i:=1 to n_Piles do with Piles[i]^ do
				if (not IsEmpty) and Tagged then begin
					Inc(n);
					Rank[n]:=CardPip(Topcard);
				end;
			SameRank:=(Rank[1]=Rank[2]);
		end;

	function Adjacent:boolean;

		var
			i,n:integer;
			Pos:array[1..2] of integer;

		function AdjH:boolean;

			begin
				AdjH:=(((Pos[1]-1) mod 5)<>4) and (Pos[1]=(Pos[2]-1));
			end;

		function AdjV:boolean;

			begin
				AdjV:=(Pos[1]=(Pos[2]-5));
			end;

		function AdjD:boolean;

			begin
				AdjD:=
					(((Pos[1]-1) div 5)<((Pos[2]-1) div 5)) { differnet rows }
					and (
						(Pos[1]=(Pos[2]-6))
						or
						(Pos[1]=(Pos[2]-4))
					)
					;
			end;

		begin
			i:=0;
			n:=0;
			with TheGame^ do for i:=1 to n_Piles do with Piles[i]^ do
				if (not IsEmpty) and Tagged then begin
					Inc(n);
					Pos[n]:=PileNo;
				end;
			Adjacent:=AdjH or AdjV or AdjD;
		end;

	begin
		inherited topSelected;
		if ((TotalTagged=2) and SameRank and Adjacent) then DiscardThem;
	end;

procedure MonteCarloGame.Arrange;

	var
		i,j:integer;

	begin
		with TheGame^ do begin
			{ un tag any left overs }
			for i:=1 to n_Piles do
				with Piles[i]^ do if Tagged then topSelected;
			{ consolidate the tableau }
			for i:=1 to n_Piles do
				if Piles[i]^.IsEmpty then
					for j:=i+1 to n_Piles do
						if (not Piles[j]^.IsEmpty) then begin
							Piles[j]^.TopcardTo(Piles[i]);
							Break;
						end;
		end;
	end;

procedure TMonHand.Selected;

	begin
		TheGame^.Arrange;
	end;

procedure TMonHand.topSelected;

	var
		i,j:integer;

	begin
		with TheGame^ do begin
			Arrange;
			{ fill the emtpy spots }
			i:=1;
			while (not IsEmpty) and (i<=n_Piles) do begin
				if Piles[i]^.IsEmpty then begin
					HandPile^.TopcardTo(Piles[i]);
					Piles[i]^.topFlip;
				end;
				Inc(i);
			end;
		end;
	end;

function MonteCarloGame.CardSize:TCardSize;
	begin
		CardSize:= MediumCards;
	end;

end.
