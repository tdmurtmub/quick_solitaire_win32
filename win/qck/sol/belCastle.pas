(***********************************************************************
Copyright (c) 1998 by Wesley Steiner
All rights reserved.
***********************************************************************)

unit BSCastle;

interface

{$I BSGINC}

const
	Redeals		= 0;
	n_Founds		= 4;
	n_Tabs		= 8;

type
	Castle_Tableau_Item_P=^Castle_Tableau_Item;
	Castle_Tableau_Item=object(TTableauDn)
		constructor	Init(aNum,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function 	Accepts(aCard:TCard):boolean; 			virtual;
		function 	canGrabUnit(a_index:integer):boolean; 	virtual;
	end;

	Castle_Foundation_Item_P=^Castle_Foundation_Item;
	Castle_Foundation_Item = object(TFoundUpInSuit)
	end;

	Castle_Game_P = ^Castle_Game;
	Castle_Game = object(SolGame)
		Founds:array[1..n_Founds] of Castle_Foundation_Item_P;
		Tableaus:array[1..n_Tabs] of Castle_Tableau_Item_P;
		constructor Init;
		procedure Setup; virtual;
		procedure Start; virtual;
		function Score:TScore; virtual;
		function CardSize:TCardSize; virtual;
	end;

implementation

uses
	Std, StdWin, WinTypes,WinProcs,Strings;

var
	TheGame:Castle_Game_P;
	TabColDX,TabDX:integer;

constructor Castle_Game.Init;

	var
		i:integer;

	function TabX(i:integer):integer;

		begin
			TabX:=Centered(TabColDX*2-ColSp,0,AppMaxX)+((i-1) div 4)*TabColDX;
		end;

	function TabY(i:integer):integer;

		begin
			TabY:=Centered(RowEx(4),0,AppMaxY)+((i-1) mod 4)*RowDY;
		end;

	begin
		inherited Construct(GID_Bel_Castle);
		TheGame:=@Self;
		with x_engine do begin
			{ tableaus }
			TabDX:=PipHSpace+1;
			TabColDX:=(TabDX)*16+ColDX*2;
			for i:=1 to n_Tabs do begin
				Tableaus[i]:=New(Castle_Tableau_Item_P,Init(i,17,True,TabX(i),TabY(i),TabDX,0));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			{ foundations }
			for i:=1 to n_Founds do begin
				Founds[i]:=New(Castle_Foundation_Item_P, Init(
					i,
					Tableaus[5]^.Anchor.X-ColDX,
					Tableaus[i]^.Anchor.Y
					));
				x_aSolApp.Tabletop^.Insert(Founds[i]);
			end;
			Draw;
			Setup;
			Start;
		end;
	end;

procedure Castle_Game.Setup;

	begin
		inherited Setup;
	end;


procedure Castle_Game.Start;

	var
		i,j,k:integer;

	begin
		for i:=1 to n_Founds do with Founds[i]^ do begin
			topAdd(DeckPullPip(Deck,1,TACE));
			topFlip;
			Draw;
		end;
		for i:=1 to 6 do for j:=1 to 8 do with Tableaus[j]^ do begin
			topAdd(Deck^.Removetop);
			topFlip;
			topDraw;
		end;
		inherited Start;
	end;


constructor Castle_Tableau_Item.Init;

	begin
		inherited Init(ViewP(TabletopView), aNum,N,FaceUp,X,Y,DX,DY);
		AppendDesc('regardless of suit. Spaces may be filled with any available card. ');
	end;


function Castle_Game.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to 4 do with Founds[i]^ do Inc(s, Size);
		Score:=StartingScore-s;
	end;


{function Castle_Game.FoundationFit;

	var
		i:integer;

	begin
		for i:=1 to nFoundations do if Foundations[i]^.Accepts(aCard) then begin
			FoundationFit:=i;
			Exit;
		end;
		FoundationFit:=0;
	end;}


function Castle_Tableau_Item.Accepts;
begin
	Accepts:=
		IsEmpty
		or
		(inherited Accepts(aCard));
end;


function Castle_Tableau_Item.canGrabUnit(a_index:integer):boolean;
begin
	canGrabUnit:= False;
end;

function Castle_Game.CardSize:TCardSize;
begin
	CardSize:= {$ifdef WIN16} MediumCards {$else} inherited CardSize; {$endif} ;
end;

end.
