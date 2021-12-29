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

unit BSCalc;

interface

{$I BSGINC}

const
	Decks			=1;
	nTableaus	=4;
	nFound=4;

type
	PCalPile=^TCalPile;
	TCalPile=object(OWastepileProp)
		constructor Init(X,Y:integer);
		{procedure topSelected; virtual;}
	end;
	PCalHand=^TCalHand;
	TCalHand=object(OStockpileProp)
		constructor Init(X,Y:integer);
		{procedure topSelected; virtual;}
	end;
	PCalFound=^TCalFound;
	TCalFound=object(GenericFndtnPile)
		constructor Init(aNum,X,Y:integer);
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;
	PCalGame=^TCalGame;
	TCalGame=object(SolGame)
		TabDY:integer;
		Foundations:array[1..nFound] of PCalFound;
		Tableaus:array[1..nTableaus] of PCalPile;
		HandPile:PCalHand;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		{function FitsFoundation(aCard:TCard):integer;}
		{function GameIsLost:boolean; virtual;}
	end;

implementation

uses
	WinProcs,Strings,
	Std,
	StdWin;

const
	nCols=4;
	nRows=1;

var
	TheGame:PCalGame;

constructor TCalGame.Init;

	var
		i:integer;

	function TabX(i:integer):integer;

		begin
			TabX:=Centered(ColEx(nCols+2),0,AppMaxX)+(i+1)*ColDX;
		end;

	function TabY(i:integer):integer;

		begin
			TabY:=Centered(RowEx(2)+15*TabDY,0,AppMaxY)+RowSpace;
		end;

	begin
		inherited Construct(GID_Calculation);
		TheGame:=@Self;
		with x_engine do begin
			{ foundations }
			for i:=1 to nFound do begin
				Foundations[i]:=New(PCalFound,Init(i,
					Centered(ColEx(5),0,AppMaxX)+ColDX*i,
					MIN_EDGE_MARGIN
					));
				with Foundations[i]^ do begin
					iSeq:=i;
					BasePip:=TPip(Ord(TACE)+i-1);
				end;
				x_Tabletop^.Insert(Foundations[i]);
			end;
			{ tableaus }
			TabDY:=PipVSpace;
			for i:=1 to nTableaus do begin
				Tableaus[i]:=New(PCalPile,Init(
					Foundations[i]^.Anchor.X,
					Foundations[i]^.Anchor.Y+RowDY
					));
				x_Tabletop^.Insert(Tableaus[i]);
			end;
			{ hand pile }
			HandPile:=New(PCalHand,Init(
				Tableaus[1]^.Anchor.X-ColDX,
				Tableaus[1]^.Anchor.Y
				));
			x_Tabletop^.Insert(HandPile);
			Draw;
			Setup;
			Start;
		end;
	end;

constructor TCalHand.Init;

	begin
		inherited Init(thegame, 48,x,y,0);
		{AppendDesc('');}
	end;

procedure TCalGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		for i:=1 to 4 do with Foundations[i]^ do begin
			topAdd(DeckPullPip(Deck, 1, TPip(Ord(TACE) + i - 1)));
			FlipTopcard;
			Draw;
		end;
		DeckToPile(NumDecks, Deck, HandPile);
		HandPile^.Refresh;
	end;

procedure TCalGame.Start;

	var
		i:integer;

	begin
		inherited Start;
	end;

constructor TCalPile.Init;

	begin
		inherited Init(thegame, 51,X,Y,0,TheGame^.TabDY);
		{AppendDesc('. ');}
	end;

constructor TCalFound.Init;

	begin
		inherited Init(aNum,13,X,Y);
		AppendDesc('This foundation is to be built up from ');
		case aNum of
			1:AppendDesc('Ace to King in the sequence A,2,3,4,5,6,7,8,9,T,J,Q,K. ');
			2:AppendDesc('Deuce to King in the circular sequence 2,4,6,8,T,Q,A,3,5,7,9,J,K. ');
			3:AppendDesc('3 to King in the circular sequence 3,6,9,Q,2,5,8,J,A,4,7,T,K. ');
			4:AppendDesc('4 to King in the circular sequence 4,8,Q,3,7,J,2,6,T,A,5,9,K. ');
		end;
	end;

function TCalGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to nFound do with Foundations[i]^ do Inc(s, size);
		Score:=(inherited Score)-s;
	end;

{function TCalFound.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			and
			(CardPip(aCard)=nPipCircSucc(FoundNo,CardPip(Topcard)))
			;
	end;}

end.
