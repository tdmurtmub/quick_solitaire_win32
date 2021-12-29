(***********************************************************************
Copyright (c) 1998-2005 by Wesley Steiner
All rights reserved.
***********************************************************************)

unit BSForty;

interface

{$I BSGINC}

const
	Decks=2;
	Redeals=0;
	n_Tabs=13;
	n_Founds=8;

type
	P40BTableau=^T40BTableau;
	T40BTableau=object(TTableauSuit)
		constructor Init(No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;
	P40CTableau=^T40CTableau;
	T40CTableau=object(TTableauAlt)
		constructor Init(No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
		procedure topAdd(aCard:TCard); virtual;
	end;
	P40BHand=^T40BHand;
	T40BHand=object(OStockpileProp)
		procedure topSelected; virtual;
	end;
	P40AGame=^T40AGame;
	T40AGame=object(SolGame)
		Foundations:array[1..n_Founds] of PFoundation;
		HandPile:P40BHand;
		WastePile:PWastepileProp;
		constructor Init(anID:eGameId;nTabs,nRows:integer);
		procedure Setup; virtual;
		function Score:TScore; virtual;
		{function FoundationFit(tc:TCard):integer;}
		function CardSize:TCardSize; virtual;
	end;
	P40BGame=^T40BGame;
	T40BGame=object(T40AGame)
		Tableaus:array[1..n_Tabs] of P40BTableau;
		constructor Init(anID:eGameId;nTabs,nRows:integer);
		procedure Start; virtual;
	end;
	{ tableaus are built in alternating color }
	P40CGame=^T40CGame;
	T40CGame=object(T40AGame)
		Tableaus:array[1..n_Tabs] of P40CTableau;
		constructor Init(anID:eGameId;nTabs,nRows:integer);
		procedure Start; virtual;
	end;
	P40TGame=^T40TGame;
	T40TGame=object(T40BGame)
		constructor Init;
	end;

implementation

uses
	Std, StdWin,WinProcs,Strings;

var
	TheGame:P40AGame;
	TabDY,m_Tabs,n_Rows:integer;

constructor T40AGame.Init;

	var
		i:integer;

	begin
		inherited Construct(anID);
		TheGame:=@Self;
		with x_engine do begin
			{ hand pile }
			HandPile:=New(P40BHand,Init(thegame,
				NumDecks*52,
				MIN_EDGE_MARGIN,
				tabletopView^.clientAreaHt - RowDY,
				Redeals));
			x_aSolApp.Tabletop^.Insert(HandPile);
			WastePile:=New(PWastepileProp, Init(@self, NumDecks*52,
				HandPile^.Anchor.X+ColSpace,
				HandPile^.Anchor.Y,
				PipHSpace,0));
			x_aSolApp.Tabletop^.Insert(WastePile);
		end;
	end;

	function TabX(i:integer):integer;

		begin
			TabX:=Centered(ColEx(m_Tabs),0,AppMaxX)+(i-1)*ColDX;
		end;

	function TabY(i:integer):integer;

		begin
			TabY:=Centered(ColEx(3)+TabDY*(n_Rows-1+12),0,AppMaxY)+RowDY;
		end;

constructor T40BGame.Init;

	var
		i:integer;

	begin
		inherited Init(anID,nTabs,nRows);
		m_Tabs:=nTabs;
		n_Rows:=nRows;
		with x_engine do begin
			TabDY:=PipVSpace;
			{ tableaus }
			for i:=1 to m_Tabs do begin
				Tableaus[i]:=New(P40BTableau,Init(i,n_Rows+12,True,TabX(i),TabY(i),0,TabDY));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			{ foundations }
			for i:=1 to n_Founds do begin
				Foundations[i]:=New(PFoundation,Init(i,
					Centered(ColEx(8),0,AppMaxX)+(i-1)*ColDX,
					Tableaus[1]^.Anchor.Y-RowDY
					));
				x_aSolApp.Tabletop^.Insert(Foundations[i]);
			end;
			Setup;
			Start;
		end;
	end;

constructor T40CGame.Init;

	var
		i:integer;

	begin
		inherited Init(anID,nTabs,nRows);
		m_Tabs:=nTabs;
		n_Rows:=nRows;
		with x_engine do begin
			TabDY:=PipVSpace;
			{ tableaus }
			for i:=1 to m_Tabs do begin
				Tableaus[i]:=New(P40CTableau,Init(i,n_Rows+12,True,TabX(i),TabY(i),0,TabDY));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			{ foundations }
			for i:=1 to n_Founds do begin
				Foundations[i]:=New(PFoundation,Init(i,
					Centered(ColEx(8),0,AppMaxX)+(i-1)*ColDX,
					Tableaus[1]^.Anchor.Y-RowDY
					));
				x_aSolApp.Tabletop^.Insert(Foundations[i]);
			end;
			Setup;
			Start;
		end;
	end;

procedure T40AGame.Setup;

	{var
		i:integer;}

	begin
		inherited Setup;
		{for i:=1 to 13 do begin
			foundations[1]^.topadd(deckpullcard(deck,2,makecard(i,1)));
			foundations[2]^.topadd(deckpullcard(deck,2,makecard(i,2)));
			foundations[3]^.topadd(deckpullcard(deck,2,makecard(i,3)));
			foundations[4]^.topadd(deckpullcard(deck,2,makecard(i,4)));
		end;}
		DeckToPile(NumDecks, Deck, HandPile);
		Draw;
	end;


procedure T40BGame.Start;

	var
		j,i:integer;

	begin
		{ deal out the starting setup }
		for j:=1 to n_Rows do for i:=1 to m_Tabs do begin
			HandPile^.topTransfer(Tableaus[i]);
			Tableaus[i]^.FlipTopcard;
		end;
		inherited Start;
	end;

procedure T40CGame.Start;

	var
		j,i:integer;

	begin
		{ deal out the starting setup }
		for j:=1 to n_Rows do for i:=1 to m_Tabs do begin
			HandPile^.topTransfer(Tableaus[i]);
		end;
		inherited Start;
	end;

function T40BTableau.Accepts;

	begin
		Accepts:=
			(inherited Accepts(tc))
			or
			IsEmpty
			;
	end;

function T40CTableau.Accepts;

	begin
		Accepts:=
			(inherited Accepts(tc))
			or
			IsEmpty
			;
	end;

constructor T40BTableau.Init;

	begin
		inherited Init(QuickViewP(TabletopView), No,N,FaceUp,X,Y,DX,DY);
		AppendDesc('A space can be filled with any available card. ');
	end;

constructor T40CTableau.Init;

	begin
		inherited Init(QuickViewP(TabletopView), No,N,FaceUp,X,Y,DX,DY);
		AppendDesc('A space can be filled with any available card. ');
	end;

function T40AGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to n_Founds do with Foundations[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;

{function T40BGame.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to n_Founds do if Foundations[i]^.Accepts(tc) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;}

procedure T40BHand.topSelected;

	begin
		if topFaceDown then
			inherited topSelected
		else
			TopcardTo(TheGame^.WastePile);
	end;

procedure T40CTableau.topAdd;

	begin
		inherited topAdd(aCard);
	end;

constructor T40TGame.Init;

	begin
		inherited Init(GID_FortyThieves,10,4);
	end;

function T40AGame.CardSize:TCardSize;
begin
	CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
end;

end.
