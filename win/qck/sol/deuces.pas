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

unit BSDeuces;

interface

{$I BSGINC}

const
	Decks			=2;
	n_Redeals		=1;
	n_Tabs=10;
	n_Founds=8;

type
	PDeuTab=^TDeuTab;
	TDeuTab=object(TTableauSuit)
		constructor Init(i:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		{procedure OnCardAdded; virtual;}
	end;
	PDeuFound=^TDeuFound;
	TDeuFound=object(TFoundUpInSuit)
		constructor Init(i:integer);
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;
	PDeuHand=^TDeuHand;
	TDeuHand=object(OStockpileProp)
		constructor Init;
		procedure Redeal; virtual;
		procedure topSelected; virtual;
	end;
	PDeuWaste=^TDeuWaste;
	TDeuWaste=object(OWastepileProp)
		constructor Init;
	end;
	PDeuGame=^DeucesGame;
	DeucesGame=object(SolGame)
		Found:array[1..n_Founds] of PDeuFound;
		Tableaus:array[1..n_Tabs] of PDeuTab;
		HandPile:PDeuHand;
		Waste:PDeuWaste;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function CardSize:TCardSize; virtual;
		{function FoundationFit(aCard:TCard):integer;}
	end;

implementation

uses
	Std, StdWin, WinTypes, WinProcs, Strings;

var
	TheGame:PDeuGame;

constructor DeucesGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Deuces);
		TheGame:=@Self;
		for i:=1 to n_Tabs do Tableaus[i]:=New(PDeuTab,Init(i));
		for i:=1 to n_Founds do Found[i]:=New(PDeuFound,Init(i));
		HandPile:=New(PDeuHand,Init);
		Waste:=New(PDeuWaste,Init);
		with x_aSolApp.Tabletop^ do begin
			Insert(HandPile);
			Insert(Waste);
			for i:=1 to n_Tabs do Insert(Tableaus[i]);
			for i:=1 to n_Founds do Insert(Found[i]);
		end;
		Setup;
		Start;
	end;

procedure DeucesGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		with HandPile^ do begin
			nRedealsAllowed:=n_Redeals;
			DealsRemaining:=n_Redeals;
			TargetState:=True;
		end;
		Draw;
		for i:=1 to n_Founds do begin
			with Found[i]^ do begin
				topAdd(DeckPullPip(Deck,NumDecks,TDEUCE));
				topFlip;
				topDraw;
			end;
		end;
		DeckToPile(NumDecks,Deck,HandPile);
		HandPile^.Refresh;
	end;

procedure DeucesGame.Start;

	var
		i:integer;

	begin
		for i:=1 to n_Tabs do begin
			HandPile^.TopcardTo(Tableaus[i]);
			Tableaus[i]^.topFlip;
		end;
		inherited Start;
	end;

function TDeuTab.Accepts;

	begin
		with TheGame^ do Accepts:=
			(inherited Accepts(aCard))
			or (
				IsEmpty
				and
					(
						(grabbed_from = GenPileOfCardsP(HandPile))
						or
						(grabbed_from = GenPileOfCardsP(Waste))
					)
			)
			;
	end;

constructor TDeuTab.Init;

	var
		x,y:integer;

	begin
		x:=Centered(ColEx(6),0,AppMaxX);
		if i in [9,10] then
			x:=x+5*ColDX
		else if not (i in [1,2]) then
			x:=x+(i-3)*ColDX;
		y:=Centered(RowEx(4),0,AppMaxY)+RowDY;
		if i in [1,2,9,10] then
			y:=y+((i-1) mod 2)*RowDY+RowDY;
		inherited Init(QuickViewP(TabletopView), i,104,True,x,y,0,0);
		AppendDesc('Spaces can only be filled with cards from the Hand or Waste Piles. ');
	end;

function DeucesGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to n_Founds do with Found[i]^ do Inc(s, Size);
		Score:=(inherited Score)-s;
	end;

constructor TDeuHand.Init;

	begin
		inherited Init(thegame, 52*2-8,
			Centered(ColEx(2),0,AppMaxX),
			TheGame^.Tableaus[3]^.Anchor.Y-RowDY,
			n_Redeals
			);
	end;

procedure TDeuHand.ReDeal;

	var
		i,j:integer;

	begin
		if DealsRemaining<>0 then begin
			inherited Redeal;
			with TheGame^ do if not Waste^.IsEmpty then begin
				for i:=Waste^.Size downto 1 do topAdd(Waste^.Get(i));
				Waste^.Empty;
				Draw;
			end;
		end;
	end;

constructor TDeuFound.Init;

	begin
		with TheGame^ do inherited Init(13,
			Tableaus[4]^.Anchor.X+((i-1) mod 4)*ColDX,
			Tableaus[4]^.Anchor.Y+((i-1) div 4)*RowDY+RowDY
			);
		BasePip:=TDEUCE;
	end;

constructor TDeuWaste.Init;

	begin
		with TheGame^ do inherited Init(thegame, 104-8-10,
			HandPile^.Anchor.X+ColDX,
			HandPile^.Anchor.Y,
			0,0
			);
	end;

procedure TDeuHand.topSelected;

	begin
		if topFaceUp then
			TopcardTo(TheGame^.Waste)
		else
			inherited topSelected;
	end;

function DeucesGame.CardSize:TCardSize;
begin
	CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
end;

end.
