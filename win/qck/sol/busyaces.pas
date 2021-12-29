(***********************************************************************
Copyright (c) 1998-2005 by Wesley Steiner
All rights reserved.
***********************************************************************)

unit BSBusy;

interface

{$I BSGINC}

const
	Decks			=2;
	Redeals		=0;
	CardSize	=LargeCards;
	nTableaus	=12;
	nFoundations=8;

type
	PBusTableau=^TBusTableau;
	TBusTableau=object(TTableauSuit)
		constructor Init(No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
		{procedure OnCardAdded; virtual;}
	end;
	PBusHand=^TBusHand;
	TBusHand=object(OStockpileProp)
		{procedure OnCardAdded; virtual;}
		procedure topFlip; virtual;
		procedure topSelected; virtual;
	end;
	PBusyAcesGame=^BusyAcesGame;
	BusyAcesGame=object(SolGame)
		Foundations:array[1..nFoundations] of PFoundation;
		Tableaus:array[1..nTableaus] of PBusTableau;
		HandPile:PBusHand;
		WastePile:PWastepileProp;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function FoundationFit(tc:TCard):integer;
		function CardSize:TCardSize; virtual;
	end;

implementation

uses
	Std, StdWin, WinProcs, Strings;

const
	nCols=6;
	nRows=2;

var
	TheGame:PBusyAcesGame;

constructor BusyAcesGame.Init;

	var
		i:integer;

	function TabX(i:integer):integer;

		begin
			if ((i-1) mod nCols)=0 then
				TabX:=Centered(ColSpace*nCols-MIN_EDGE_MARGIN,0,AppMaxX)
			else
				TabX:=Tableaus[i-1]^.Anchor.X+ColSpace;
		end;

	function TabY(i:integer):integer;

		begin
			if (i<=nCols) then
				TabY:=Centered(RowSpace*(nRows+1)-MIN_EDGE_MARGIN,0,AppMaxY)+RowSpace
			else
				TabY:=Tableaus[1]^.Anchor.Y+RowSpace;
		end;

	begin
		inherited Construct(GID_BusyAces);
		TheGame:=@Self;
		with x_engine do begin
			{ foundations }
			for i:=1 to nFoundations do begin
				Foundations[i]:=New(PFoundation,Init(i,
					Centered(ColEx(8),0,AppMaxX)+(i-1)*ColDX,
					Centered(RowEx(3),0,AppMaxY)
					));
				x_Tabletop^.Insert(Foundations[i]);
			end;
			{ tableaus }
			for i:=1 to nTableaus do begin
				Tableaus[i]:=New(PBusTableau,Init(i,13,True,
					Foundations[((i-1) mod 6)+2]^.Anchor.X,
					Foundations[1]^.Anchor.Y+(((i-1) div 6)+1)*RowDY,
					0,0));
				x_Tabletop^.Insert(Tableaus[i]);
			end;
			{ hand pile }
			HandPile:=New(PBusHand,Init(thegame,
				NumDecks*52,
				Foundations[1]^.Anchor.X-ColDX,
				{Centered(RowDY,Tableaus[1]^.Anchor.Y,Tableaus[nCols+1]^.EndY),} {?}
				Centered(RowDY,Tableaus[1]^.Anchor.Y,Tableaus[nCols+1]^.span.bottom),
				Redeals));
			x_Tabletop^.Insert(HandPile);
			WastePile:=New(PWastepileProp,Init(@self, NumDecks*52-nTableaus,HandPile^.Anchor.X+ColSpace,HandPile^.Anchor.Y,0,0));
			x_Tabletop^.Insert(WastePile);
			Setup;
			Start;
		end;
	end;

procedure BusyAcesGame.Setup;

	begin
		inherited Setup;
		DeckToPile(NumDecks,Deck,HandPile);
		Draw;
	end;

procedure AutoAce(Pile:GenPileOfCardsP);

	begin
		Pile^.topGrab;
		TheGame^.Foundations[TheGame^.FoundationFit(GrabbedCard)]^.topGet;
	end;

procedure BusyAcesGame.Start;

	var
		i:integer;

	begin
		{ deal out the starting setup }
		for i:=1 to nTableaus do begin
			HandPile^.TopGrab;
			Tableaus[i]^.topPlace;
			Tableaus[i]^.topFlip;
		end;
		for i:=1 to nTableaus do if Tableaus[i]^.AceUp then AutoAce(Tableaus[i]);
		inherited Start;
	end;


function TBusTableau.Accepts;

	begin
		Accepts:=
			(inherited Accepts(tc))
			or
			(
				IsEmpty
				and
				(
					(grabbed_from = GenPileOfCardsP(TheGame^.HandPile))
					or
					(grabbed_from = GenPileOfCardsP(TheGame^.WastePile))
				)
			);
	end;


constructor TBusTableau.Init;

	begin
		inherited Init(ViewP(TabletopView), No,N,FaceUp,X,Y,DX,DY);
		AppendDesc('Spaces can only be filled with cards from the Hand or Waste piles. ');
	end;

function BusyAcesGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to nFoundations do with Foundations[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;

{procedure TBusTableau.OnCardAdded;

	var
		i:integer;

	begin
		inherited OnCardAdded;
		if topFaceUp and AceUp then AutoAce(@Self);
	end;}

function BusyAcesGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to nFoundations do if Foundations[i]^.Accepts(tc) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;

procedure TBusHand.topFlip;

	begin
		inherited topFlip;
		if AceUp then AutoAce(@Self);
	end;

procedure TBusHand.topSelected;

	begin
		if topFaceDown then
			inherited topSelected
		else
			TopcardTo(TheGame^.WastePile);
	end;

function BusyAcesGame.CardSize:TCardSize;
begin
	CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
end;

end.
