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

unit BSSlyFox;

interface

{$I BSGINC}

const
	Decks		= 2;
	Redeals	= 2;
	nCols		= 5;
	nRows		= 4;
	n_Piles	= nCols*nRows;

type
	Sly_Waste_Item_P=^Sly_Waste_Item;
	Sly_Waste_Item=object(OWastepileProp)
		constructor Init(X,Y:integer);
		{function Accepts(aCard:TCard):boolean; virtual;}
		procedure OnCardAdded; 										virtual;
		procedure OnPressed(p_x:integer; p_y:integer);	virtual;
{		procedure topGet; 											virtual;}
	end;

	PSlyFoundU=^TSlyFoundU;
	TSlyFoundU=object(TFoundUpInSuit)
		procedure OnCardAdded; virtual;
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;

	PSlyFoundD=^TSlyFoundD;
	TSlyFoundD=object(TFoundDnInSuit)
		procedure OnCardAdded; virtual;
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;

	Sly_Hand_Item_P=^Sly_Hand_Item;
	Sly_Hand_Item=object(OStockpileProp)
		constructor Init;
		procedure topSelected; virtual;
	end;

	PSlyGame=^TSlyGame;
	TSlyGame=object(SolGame)
		FoundU:array[1..4] of PSlyFoundU;
		FoundD:array[1..4] of PSlyFoundD;
		Piles:array[1..n_Piles] of Sly_Waste_Item_P;
		HandPile:Sly_Hand_Item_P;

		constructor Init;

		procedure 	Setup; virtual;
		procedure 	Start; virtual;
		function 	Score:TScore; virtual;
{		function 	GameIsLost:boolean; virtual;}
{		function FoundationFit(aCard:TCard):integer;}
		function CardSize:TCardSize; virtual;
	end;

implementation

uses
	Std, StdWin, WinTypes, WinProcs, Strings;

var
	x_game:PSlyGame;
	x_deal_twenty:boolean; { true when we are dealing twenty cards }
	x_count_deals:integer; { counts the number of cards that have been
		dealt to the waste piles }


constructor TSlyGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_SlyFox);
		x_game:=@Self;
		with x_engine do begin
			{ Piles }
			for i:=1 to n_Piles do begin
				Piles[i]:=New(Sly_Waste_Item_P,Init(
					Centered(ColEx(nCols),0,AppMaxX)+((i-1) mod nCols)*ColDX,
					Centered(RowEx(nRows+1),0,AppMaxY)+RowDY+((i-1) div nCols)*RowDY
					));
				x_aSolApp.Tabletop^.Insert(Piles[i]);
			end;
			HandPile:= New(Sly_Hand_Item_P, Init);
			x_aSolApp.Tabletop^.Insert(HandPile);
			{ foundations }
			for i:=1 to 4 do begin
				FoundU[i]:=New(PSlyFoundU,Init(
					i,
					Piles[(i-1)*nCols+1]^.Anchor.X-ColDX-ColSp*2,
					Piles[(i-1)*nCols+1]^.Anchor.Y
					));
				x_aSolApp.Tabletop^.Insert(FoundU[i]);
			end;
			for i:=1 to 4 do begin
				FoundD[i]:=New(PSlyFoundD,Init(
					i,
					Piles[i*nCols]^.Anchor.X+ColDX+ColSp*2,
					FoundU[i]^.Anchor.Y
					));
				x_aSolApp.Tabletop^.Insert(FoundD[i]);
			end;
		end;
	end;


procedure TSlyGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		for i:=1 to 4 do begin
			with FoundD[i]^ do begin
				topAdd(DeckPullCard(Deck,2,MakeCard(TKING,TSuit(Ord(TCLUB)+i-1))));
				topFlip;
				{Draw;}
			end;
			with FoundU[i]^ do begin
				topAdd(DeckPullCard(Deck,2,MakeCard(TACE,TSuit(Ord(TCLUB)+i-1))));
				topFlip;
				{Draw;}
			end;
		end;
		Draw;
		DeckToPile(2,Deck,HandPile);
		HandPile^.Refresh;
	end;

procedure TSlyGame.Start;

	var
		i:integer;

	begin
		x_deal_twenty:= False;
		x_count_deals:= 0;
		for i:=1 to n_Piles do begin
			HandPile^.TopcardTo(Piles[i]);
			Piles[i]^.topFlip;
		end;
		inherited Start;
	end;

{function Sly_Waste_Item.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			;
	end;}


constructor Sly_Waste_Item.Init;

	begin
		inherited Init(x_game, 104,X,Y,0,0);
		AppendDesc('Spaces may only be filled with cards from the hand. ');
	end;


function TSlyGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to 4 do with FoundU[i]^ do Inc(s, Size);
		for i:=1 to 4 do with FoundD[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;

{function TSlyGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to nFoundations do if Foundations[i]^.Accepts(aCard) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;}


constructor Sly_Hand_Item.Init;

	begin
		inherited Init(x_game, 52*2-8,
			Centered(x_engine.CardImageWd,0,AppMaxX),
			x_game^.Piles[1]^.Anchor.Y-RowDY,
			0);
		StrCopy	(Desc, 'The top card is available for play to the foundations at any time. ' );
		StrCat	(Desc, 'When you play the top card to a waste pile or foundations you must continue to do so until 20 cards ');
		StrCat	(Desc, 'have been played to the Waste piles before you can play up to the foundations again. ');
	end;


procedure Sly_Waste_Item.OnCardAdded;

	begin
		if x_deal_twenty then begin
			Inc(x_count_deals);
			if (x_count_deals = n_Piles) or (x_game^.HandPile^.IsEmpty) then begin
				MessageBox(AppWnd,
					'You may now continue to play up cards from the waste piles. ',
					'Attention',
					mb_OK or mb_IconInformation);
				x_count_deals:=0;
				x_deal_twenty:= False;
			end;
		end;
	end;


procedure Sly_Waste_Item.OnPressed(p_x:integer; p_y:integer);

begin
	if not x_deal_twenty then
		inherited OnPressed(p_x, p_y);
end;


procedure TSlyFoundU.OnCardAdded;

begin
	if
		(grabbed_from <> nil)
		and
		grabbed_from^.IsEmpty
		and
		(not x_game^.HandPile^.IsEmpty)
	then begin
		x_game^.HandPile^.topFlip;
		x_game^.HandPile^.TopcardTo(grabbed_from);
	end;
end;


procedure TSlyFoundD.OnCardAdded;

begin
	if
		(grabbed_from <> nil)
		and
		grabbed_from^.IsEmpty
		and
		(not x_game^.HandPile^.IsEmpty)
	then begin
		x_game^.HandPile^.topFlip;
		x_game^.HandPile^.TopcardTo(grabbed_from);
	end;
end;


procedure Sly_Hand_Item.topSelected;

{ Only allow hand pile to be selected when the game is blocked. }

begin
	if
		(x_deal_twenty)
		or
		(MessageBox(AppWnd,
			'When you select this pile you must deal 20 cards to the waste piles before you can continue play. Are you sure?',
			'Attention',
			mb_YESNO or mb_IconQuestion) = IDYES)
	then begin
		x_deal_twenty:= True;
		inherited topSelected;
	end;
end;


(*
function TSlyGame.GameIsLost;

{ Return true if no cards can be played from the waste piles to the foundations. }

var
	i, j:integer;

begin
	for i:= 1 to n_piles do with x_game^ do begin
		if (not Piles[i]^.IsEmpty) then begin
			for j:= 1 to 4 do begin
				if
					(FoundU[j]^.Accepts(Piles[i]^.Topcard))
					or
					(FoundD[j]^.Accepts(Piles[i]^.Topcard))
				then begin
					GameIsLost:= False;
					Exit;
				end;
			end;
		end;
	end;
	GameIsLost:= True;
end;
*)

{procedure Sly_Waste_Item.topGet;

begin
	inherited topGet;
	if x_deal_twenty then begin
		Inc(x_count_deals);
		if (x_count_deals = n_Piles) or (x_game^.HandPile^.IsEmpty) then begin
			MessageBox(AppWnd,
				'You may now continue to play up cards from the waste piles. ',
				'Attention',
				mb_OK or mb_IconInformation);
			x_count_deals:= 0;
			x_deal_twenty:= False;
		end;
	end;
end;}

function TSlyGame.CardSize:TCardSize;
	begin
		CardSize:= MediumCards;
	end;

end.
