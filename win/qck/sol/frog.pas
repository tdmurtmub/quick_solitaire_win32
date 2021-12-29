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

unit BSFrog;

interface

{$I BSGINC}

const
	n_Wastes=5;
	n_Founds=8;

type
	Frog_Waste_Item_P=^Frog_Waste_Item;
	Frog_Waste_Item=object(OWastepileProp)
		constructor Init(i:integer);
		{function Accepts(tc:TCard):boolean; virtual;}
		{procedure OnCardAdded; virtual;}
	end;
	Frog_Foundation_Item_P=^Frog_Foundation_Item;
	Frog_Foundation_Item=object(TFoundUp)
		constructor Init(i:integer);
		{function Accepts(tc:TCard):boolean; virtual;}
		{procedure OnCardAdded; virtual;}
	end;
	PFrgHand=^TFrgHand;
	TFrgHand=object(OStockpileProp)
		constructor Init;
		{procedure OnCardAdded; virtual;}
		{procedure topFlip; virtual;
		procedure topSelected; virtual;}
	end;
	Frog_Stock_Item_P=^Frog_Stock_Item;
	Frog_Stock_Item=object(TStockPile)
		constructor Init;
		{procedure OnCardAdded; virtual;}
		{procedure topFlip; virtual;}
		{procedure topSelected; virtual;}
	end;
	PFrgGame=^FrogGame;
	FrogGame=object(SolGame)
		Founds:array[1..n_Founds] of Frog_Foundation_Item_P;
		Wastes:array[1..n_Wastes] of Frog_Waste_Item_P;
		Hand:PFrgHand;
		Stock:Frog_Stock_Item_P;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function FoundationFit(aCard:TCard):integer;
		function CardSize:TCardSize; virtual;
	end;


implementation

uses
	Std, StdWin, WinProcs,Strings;

var
	TheGame:PFrgGame;


constructor FrogGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Frog);
		TheGame:=@Self;
		for i:=1 to n_Founds do Founds[i]:=New(Frog_Foundation_Item_P,Init(i));
		for i:=1 to n_Wastes do Wastes[i]:=New(Frog_Waste_Item_P,Init(i));
		Stock:= New(Frog_Stock_Item_P,Init);
		Hand:= New(PFrgHand,Init);
		with x_aSolApp.Tabletop^ do begin
			for i:=1 to n_Wastes do Insert(Wastes[i]);
			for i:=1 to n_Founds do Insert(Founds[i]);
			Insert(Hand);
			Insert(Stock);
		end;
	end;


procedure FrogGame.Setup;

	var
		i:integer;
		pile:Frog_Foundation_Item_P;

	function AllEmpty:boolean;

		var
			i:integer;

		begin
			AllEmpty:=True;
			for i:=1 to n_Founds do if not Founds[i]^.IsEmpty then begin
				AllEmpty:=False;
				Exit;
			end;
		end;

	begin
		inherited Setup;
		Draw;
		for i:=1 to 13 do with Stock^ do begin
			topAdd(DeckPulltopCard(Deck,NumDecks));
			topFlip;
			topDraw;
			if CardPip(Topcard) = TACE then begin
				pile:= Founds[FoundationFit(Topcard)];
				TopcardTo(pile);
			end;
		end;
		if AllEmpty then with Founds[1]^ do begin
			topAdd(DeckPullPip(Deck,NumDecks,TACE));
			topFlip;
			Draw;
		end;
		DeckToPile(NumDecks,Deck,Hand);
		Hand^.Refresh;
	end;


procedure FrogGame.Start;

	var
		i:integer;

	begin
		{ deal out the starting setup }
		{for i:=1 to 13 do begin
			Hand^.topPick;
			Wastes[i]^.topPlace;
		end;
		for i:=1 to n_Wastes do if Wastes[i]^.AceUp then AutoAce(Wastes[i]);}
		inherited Start;
	end;


constructor Frog_Waste_Item.Init;

	begin
		with TheGame^,x_engine do inherited Init(thegame, 104-13,
			Centered(ColEx(5),Founds[1]^.Anchor.X,Founds[1]^.Anchor.X+ColEx(8))+(i-1)*ColDX,
			Founds[1]^.Anchor.Y+RowDY,
			0,(PipVSpace div 3)*2);
		{AppendDesc('Spaces can only be filled with cards from the Hand or Waste piles. ');}
	end;


function FrogGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to n_Founds do with Founds[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;


{procedure Frog_Waste_Item.OnCardAdded;

	var
		i:integer;

	begin
		inherited OnCardAdded;
		if topFaceUp and AceUp then AutoAce(@Self);
	end;}

function FrogGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to n_Founds do if Founds[i]^.Accepts(aCard) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;

{procedure TFrgHand.topFlip;

	begin
		inherited topFlip;
		if AceUp then AutoAce(@Self);
	end;}

{procedure TFrgHand.topSelected;

	begin
		if topFaceDown then
			inherited topSelected
		else
			TopcardTo(TheGame^.WastePile);
	end;}

constructor Frog_Foundation_Item.Init;

	begin
		inherited Init(i,
			Centered(ColEx(9),0,AppMaxX)+i*ColDX,
			MIN_EDGE_MARGIN
			);
	end;

constructor TFrgHand.Init;

	begin
		with TheGame^ do inherited Init(TheGame, 104,
			Centered(x_engine.CardImageWd,0,Wastes[1]^.Anchor.X),
			Centered(x_engine.CardImageHt,0,AppMaxY),
			0
			);
	end;

constructor Frog_Stock_Item.Init;

	begin
		with TheGame^ do inherited Init(13,
			Centered(x_engine.CardImageWd+12*3,0,Founds[1]^.Anchor.X),
			MIN_EDGE_MARGIN,
			3,3
			);
	end;

function FrogGame.CardSize:TCardSize;
begin
	CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
end;

end.
