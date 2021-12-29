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

unit BSHelena;

interface

{$I BSGINC}

const
	Decks			=2;
	Redeals		=2;

type
	Helena_Tableau_Item_P=^Helena_Tableau_Item;
	Helena_Tableau_Item=object(TTableauUorD)
		constructor Init(aNum,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		{procedure OnCardAdded; virtual;}
	end;
	Helena_U_Foundation_Item_P=^Helena_U_Foundation_Item;
	Helena_U_Foundation_Item=object(TFoundUpInSuit)
		function Accepts(aCard:TCard):boolean; virtual;
	end;
	Helena_D_Foundation_Item_P=^Helena_D_Foundation_Item;
	Helena_D_Foundation_Item=object(TFoundDnInSuit)
		function Accepts(aCard:TCard):boolean; virtual;
	end;
	Helena_Hand_Item_P = ^Helena_Hand_Item;
	Helena_Hand_Item = object(OStockpileProp)
		constructor Init;
		procedure Redeal; virtual;
	end;
	PHelenaGame = ^HelenaGame;
	HelenaGame = object(SolGame)
		FoundU:array[1..4] of Helena_U_Foundation_Item_P;
		FoundD:array[1..4] of Helena_D_Foundation_Item_P;
		Tableaus:array[1..12] of Helena_Tableau_Item_P;
		HandPile:Helena_Hand_Item_P;
		constructor Init;
		destructor Done; virtual;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function GameIsLost:boolean; virtual;
		function CardSize:TCardSize; virtual;
	end;

implementation

uses
	Std, StdWin, WinTypes,WinProcs,Strings;

const
	nCols=6;
	nRows=2;

{type
	PDBut=^TDBut;
	TDBut=object(TButtonPanel)
		constructor Init;
	end;}

var
	TheGame:PHelenaGame;
	{DBut:PDBut;}

constructor HelenaGame.Init;

	var
		i:integer;

	function TabX(i:integer):integer;

		begin
			case i of
				1..4:
					TabX:=FoundU[i]^.Anchor.X;
				7..10:
					TabX:=FoundU[4]^.Anchor.X-(i-7)*ColDX;
				5..6:
					TabX:=FoundU[4]^.Anchor.X+ColDX;
				11..12:
					TabX:=FoundU[1]^.Anchor.X-ColDX;
			end;
		end;

	function TabY(i:integer):integer;

		begin
			case i of
				1..4:
					TabY:=FoundD[1]^.Anchor.Y-RowDY;
				7..10:
					TabY:=FoundU[i-6]^.Anchor.Y+RowDY;
				5..6:
					TabY:=FoundD[4]^.Anchor.Y+(i-5)*RowDY;
				11..12:
					TabY:=FoundU[1]^.Anchor.Y-(i-11)*RowDY;
			end;
		end;

	begin
		inherited Construct(GID_StHelena);
		TheGame:=@Self;
		with x_engine do begin
			{ foundations }
			for i:=1 to 4 do begin
				FoundD[i]:=New(Helena_D_Foundation_Item_P,Init(
					i,
					Centered(ColEx(6),0,AppMaxX)+i*ColDX,
					Centered(RowEx(4),0,AppMaxY)+RowDY
					));
				x_aSolApp.Tabletop^.Insert(FoundD[i]);
				FoundU[i]:=New(Helena_U_Foundation_Item_P,Init(
					i,
					FoundD[i]^.Anchor.X,
					FoundD[i]^.Anchor.Y+RowDY
					));
				x_aSolApp.Tabletop^.Insert(FoundU[i]);
			end;
			{ tableaus }
			for i:=1 to 12 do begin
				Tableaus[i]:=New(Helena_Tableau_Item_P,Init(i,26,True,TabX(i),TabY(i),0,0));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			HandPile:=New(Helena_Hand_Item_P,Init);
			x_aSolApp.Tabletop^.Insert(HandPile);
			{DBut:=New(PDBut,Init);
			with DBut^ do AddButton('2 Redeals are Permitted',0,0,0);}
			Draw;
			Setup;
			Start;
		end;
	end;

{constructor TDBut.Init;

	begin
		inherited Init(x_aSolApp.MainWindow,nil,0,25);
		Attr.X:=MIN_EDGE_MARGIN;
		Attr.Y:=MIN_EDGE_MARGIN;
		Create;
	end;}

destructor HelenaGame.Done;

	begin
		{DBut^.Hide;
		Dispose(DBut,Done);}
		inherited Destruct;
	end;

procedure HelenaGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		with HandPile^ do begin
			nRedealsAllowed:=2;
			DealsRemaining:=2;
			TargetState:=True;
		end;
		for i:=1 to 4 do begin
			with FoundD[i]^ do begin
				topAdd(DeckPullCard(Deck,2,MakeCard(TKing,TSuit(Ord(TClub)+i-1))));
				FlipTopcard;
				Draw;
			end;
			with FoundU[i]^ do begin
				topAdd(DeckPullCard(Deck,2,MakeCard(TACE,TSuit(Ord(TClub)+i-1))));
				FlipTopcard;
				Draw;
			end;
		end;
		DeckToPile(2,Deck,HandPile);
		HandPile^.Refresh;
	end;

procedure HelenaGame.Start;

	var
		i:integer;

	begin
		i:=1;
		while not HandPile^.IsEmpty do begin
			HandPile^.topTransfer(Tableaus[i]);
			Tableaus[i]^.FlipTopcard;
			Inc(i);
			if i=13 then i:=1;
		end;
		{DBut^.Show;}
		inherited Start;
	end;

function Helena_Tableau_Item.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			;
	end;

constructor Helena_Tableau_Item.Init;

	begin
		inherited Init(QuickViewP(TabletopView), aNum,N,FaceUp,X,Y,DX,DY);
		AppendDesc('regardless of suit. ');
		if aNum in [1..4,7..10] then begin
			AppendDesc('During the first deal these cards can only be played onto the ');
			if aNum in [1..4] then
				AppendDesc('top row of foundations. ')
			else
				AppendDesc('bottom row foundations. ');
			AppendDesc('After the first redeal they can be played onto any foundation. ')
		end;
	end;

function HelenaGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to 4 do with FoundU[i]^ do Inc(s, size);
		for i:=1 to 4 do with FoundD[i]^ do Inc(s, size);
		Score:=StartingScore-s;
	end;

function HelenaGame.GameIsLost;

	begin
		GameIsLost:=False;
	end;

{function HelenaGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to nFoundations do if Foundations[i]^.Accepts(aCard) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;}

function Helena_U_Foundation_Item.Accepts;

	begin
		with TheGame^ do Accepts:=
			(
				(TheGame^.HandPile^.DealsRemaining<2)
				or
				(Helena_Tableau_Item_P(grabbed_from)^.Ordinal in [5,6,11,12])
				or (
					(TheGame^.HandPile^.DealsRemaining=2)
					and
					(Helena_Tableau_Item_P(grabbed_from)^.Ordinal in [7..10])
				)
			)
			and
			(Inherited Accepts(aCard));
	end;

function Helena_D_Foundation_Item.Accepts;

	begin
		with TheGame^ do Accepts:=
			(
				(TheGame^.HandPile^.DealsRemaining<2)
				or
				(Helena_Tableau_Item_P(grabbed_from)^.Ordinal in [5,6,11,12])
				or (
					(TheGame^.HandPile^.DealsRemaining=2)
					and
					(Helena_Tableau_Item_P(grabbed_from)^.Ordinal in [1..4])
				)
			)
			and
			(inherited Accepts(aCard));
	end;

constructor Helena_Hand_Item.Init;

	begin
		inherited Init(thegame, 52*2,
			Centered(x_engine.CardImageWd,0,TheGame^.Tableaus[12]^.Anchor.X),
			Centered(x_engine.CardImageHt,0,AppMaxY),
			2);
		m_outlined:= TRUE;
	end;

procedure Helena_Hand_Item.ReDeal;

	var
		i,j:integer;

	begin
		inherited Redeal;
		with TheGame^ do begin
			for i:=1 to 12 do with Tableaus[i]^ do if not IsEmpty then SnapAllTo(HandPile);
			handPile^.flip;
			i:=1;
			Start;
		end;
	end;

function HelenaGame.CardSize:TCardSize;
	begin
		CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
	end;

end.
