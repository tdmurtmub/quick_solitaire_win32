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

unit BSFourS;

interface

{$I BSGINC}

const
	nTableaus	=5;
	nFoundations=4;

type
	PFouTableau=^TFouTableau;
	TFouTableau=object(TTableauDn)
		constructor Init(No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
		procedure OnCardAdded; virtual;
	end;
	PFouHand=^TFouHand;
	TFouHand=object(OStockpileProp)
		{procedure OnCardAdded; virtual;}
		procedure topSelected; virtual;
	end;
	PFouGame=^TFouGame;
	TFouGame=object(SolGame)
		Foundations:array[1..nFoundations] of PFoundUpInSuit;
		Tableaus:array[1..nTableaus] of PFouTableau;
		HandPile:PFouHand;
		WastePile:PWastepileProp;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		{function FoundationFit(tc:TCard):integer;}
	end;

implementation

uses
	Std, StdWin, WinProcs,Strings;

var
	TheGame:PFouGame;

constructor TFouGame.Init;

	var
		i:integer;

	function TabX(i:integer):integer;

		begin
			case i of
				1,5:
					TabX:=Foundations[1]^.Anchor.X+ColDX;
				else
					TabX:=Foundations[1]^.Anchor.X+(i-2)*ColDX;
			end;
		end;

	function TabY(i:integer):integer;

		begin
			case i of
				1:
					TabY:=Foundations[1]^.Anchor.Y;
				5:
					TabY:=Foundations[3]^.Anchor.Y;
				else
					TabY:=Foundations[1]^.Anchor.Y+RowDY;
			end;
		end;

	begin
		inherited Construct(GID_FourSeasons);
		TheGame:=@Self;
		with x_engine do begin
			{ foundations }
			for i:=1 to nFoundations do begin
				Foundations[i]:=New(PFoundUpInSuit,Init(i,
					Centered(ColEx(5),0,AppMaxX)+ColDX*2+((i-1) mod 2)*ColDX*2,
					Centered(RowEx(3),0,AppMaxY)+((i-1) div 2)*RowDY*2
					));
				x_aSolApp.Tabletop^.Insert(Foundations[i]);
			end;
			{ tableaus }
			for i:=1 to nTableaus do begin
				Tableaus[i]:=New(PFouTableau,Init(i,13,True,TabX(i),TabY(i),0,0));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			{ hand pile }
			HandPile:=New(PFouHand,Init(thegame,
				52,
				Centered(ColEx(2),0,Foundations[1]^.Anchor.X),
				Tableaus[2]^.Anchor.Y,
				0));
			x_aSolApp.Tabletop^.Insert(HandPile);
			WastePile:=New(PWastepileProp, Init(@self, 52-nTableaus-1,HandPile^.Anchor.X+ColDX,HandPile^.Anchor.Y,0,0));
			x_aSolApp.Tabletop^.Insert(WastePile);
		end;
	end;

procedure TFouGame.Setup;

	begin
		inherited Setup;
		DeckToPile(NumDecks, Deck,HandPile);
		Draw;
	end;

procedure TFouGame.Start;

	var
		i:integer;

	begin
		{ deal out the starting setup }
		for i:=1 to nTableaus do HandPile^.TopcardTo(Tableaus[i]);
		HandPile^.TopcardTo(Foundations[1]);
		with Foundations[1]^ do begin
			topFlip;
			BasePip:=CardPip(Topcard);
		end;
		for i:=2 to 4 do Foundations[i]^.BasePip:=Foundations[1]^.BasePip;
		inherited Start;
	end;

procedure TFouTableau.OnCardAdded;

	begin
		inherited OnCardAdded;
		if topFaceDown then topFlip;
	end;

function TFouTableau.Accepts;

	begin
		Accepts:=
			(inherited Accepts(tc))
			or
			IsEmpty
			;
	end;

constructor TFouTableau.Init;

	begin
		inherited Init(QuickViewP(TabletopView), No,N,FaceUp,X,Y,DX,DY);
		m_aroundTheCorner:= TRUE;
		AppendDesc('in rank regardless of suit. ');
		AppendDesc('Spaces may be filled with any available card. ');
	end;

function TFouGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to nFoundations do with Foundations[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;

{procedure TFouTableau.OnCardAdded;

	var
		i:integer;

	begin
		inherited OnCardAdded;
		if topFaceUp and AceUp then AutoAce(@Self);
	end;}

(*
function TFouGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to nFoundations do if Foundations[i]^.Accepts(tc) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;
*)

procedure TFouHand.topSelected;

	begin
		if topFaceDown then
			inherited topSelected
		else
			TopcardTo(TheGame^.WastePile);
	end;

end.
