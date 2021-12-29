{ (C) 1998 Wesley Steiner }

{$MODE FPC}

{$ifdef DEBUG}
{!$define AUTO_PLAY}
{$endif}

{$I platform}

unit gaps;

interface

uses
	windows,
	cards,
	std,
	winqcktbl,
	solgapslib,
	winsoltbl;

const
	NROWS=4;
	NCOLS=13;
	NTABLEAUS=NROWS*NCOLS;

type
	GapPileP=^GapPile;
	GapPile=object(OFannedPileProp) 
		constructor Init(No:integer);
		function Accepts(tc:TCard):boolean; virtual;
		function GetAnchorPoint(table_width,table_height:word):xypair; virtual;
		procedure OnCardAdded; virtual;
	private
		function CardInPosn:boolean;
		function IsLeftMostPile:boolean;
	end;

	OGapsgame_ptr=^OGapsgame;
	OGapsgame=object(SolGame)
		Tableaus:Array[1..NTABLEAUS] of GapPileP;
		constructor Construct(tabletop:SolTableViewP);
		function GameIsLost:boolean; virtual;
		function OnPlayBlocked:LONG; virtual;
		function PileColumns:word; virtual;
		function PileRows:word; virtual;
		function PileSpacing:integer; virtual;
		function PlayIsBlocked:boolean; virtual;
		function Score:TScore; virtual;
		function ToGameState:gameState;
		procedure Setup; virtual;
		procedure OnDeal; virtual;
		procedure ToGameState(var state:gameState);
		{$ifdef AUTO_PLAY} procedure Autoplay; {$endif}
	private
		function AllSpacesRightOfKings:boolean; {$ifdef TEST} virtual; {$endif}
	end;

implementation

uses
	{$ifdef TEST} punit, gaps_tests, {$endif}
	strings,
	stdwin,
	quickWin;

var
	the_game:OGapsgame_ptr;
	game_parameters:gameparameters;
	dealing:boolean;

constructor OGapsgame.Construct(tabletop:SolTableViewP);
var
	i:integer;
begin
	inherited Construct(GID_Gaps,tabletop);
	the_game:=@Self;
	for i:=1 to NTABLEAUS do begin
		Tableaus[i]:=New(GapPileP, Init(i));
		InsertTabletop(tabletop,Tableaus[i]);
	end;
end;

{$ifdef AUTO_PLAY}

procedure OGapsgame.Autoplay; 
var
	slot:GapPileP;
	
	function NextEmptySlot:GapPileP;
	var
		n:number;
	begin
		for n:=1 to NTABLEAUS do if Tableaus[n]^.IsEmpty then begin
			if Tableaus[n]^.IsLeftMostPile then begin 
				NextEmptySlot:=Tableaus[n]; 
				Exit; 
			end
			else if (not Tableaus[n-1]^.IsEmpty) and (CardPip(Tableaus[n-1]^.Topcard)<>TKING) then begin
				NextEmptySlot:=Tableaus[n]; 
				Exit; 
			end;
		end;
	end;

	function PileThatFits(slot:GapPileP):GapPileP;
	var
		n:number;
	begin
		for n:=1 to NTABLEAUS do if (not (slot^.IsLeftMostPile and Tableaus[n]^.IsLeftMostPile)) and (not Tableaus[n]^.IsEmpty) and (slot^.Accepts(Tableaus[n]^.Topcard)) then begin
			PileThatFits:=Tableaus[n]; 
			Exit; 
		end;
	end;
	
begin
	while not AllSpacesRightOfKings do begin
		slot:=NextEmptySlot;
		PileThatFits(slot)^.DealTo(slot);
	end;
end;

{$endif}

procedure OGapsgame.OnDeal;
var
	n:number;
begin //writeln('OGapsgame.OnDeal');
	inherited OnDeal;
	dealing:=TRUE;
	for n:=1 to NTABLEAUS do deck_prop.DealTo(Tableaus[n],TRUE);
	for n:=1 to NTABLEAUS do with Tableaus[n]^ do if CardPip(Topcard)=TACE then Discard;
	dealing:=FALSE;
	InitializeGameParameters(game_parameters);
	UpdateScoreWindow(@self);
	{$ifdef AUTO_PLAY} Autoplay; {$endif}
end;

procedure OGapsgame.Setup; 
begin //writeln('OGapsgame.Setup');
	inherited Setup;
end;

function GapPile.IsLeftMostPile:boolean;
begin
	IsLeftMostPile:=(((Ordinal-1) mod NCOLS)=0);
end;

function GapPile.Accepts(tc:TCard):boolean;
begin
	Accepts:=inherited Accepts(tc) and solgapslib.PileAcceptsCard(the_game^.ToGameState, Ordinal, TCardToCard(tc));
end;

function GapPile.CardInPosn:boolean;
begin
	CardInPosn:=
		(IsLeftMostPile and (CardPip(Topcard)=TDEUCE))
		or
		(
			(not IsLeftMostPile)
			and
			(CardPip(Topcard) = Succ(CardPip(the_game^.Tableaus[Ordinal - 1]^.Topcard)))
			and
			(CardSuit(Topcard)=CardSuit(the_game^.Tableaus[Ordinal - 1]^.Topcard))
		);
end;

function OGapsgame.Score:Tscore;
var
	s:TScore;
	i,j:integer;
begin //writeln('OGapsgame.Score');
	s:=0;
	for i:=1 to NROWS do
		for j:=1 to NCOLS do
			with Tableaus[(i-1)*NCOLS+j]^ do
				if (not IsEmpty) and CardInPosn 
					then Inc(s)
					else Break;
	Score:=StartingScore - s;
end;

type
	GapPilePArray=array of GapPileP;
	GapPilePArrayP=^GapPilePArray;
	
function CountSpacesRightOfKings(const piles:array of GapPileP):word;
var
	N:word;
	count:word;
	i:number;
begin
	N:=High(piles)+1;
	count:=0;
	i:=1;
	repeat
		while (i<N) and ((piles[i-1]^.IsEmpty) or (CardPip(piles[i-1]^.Topcard)<>TKING)) do Inc(i);
			Inc(i);
			while (i<=N) and (piles[i-1]^.IsEmpty) do begin
				Inc(count);
				Inc(i);
			end;
	until (i>=N);
	CountSpacesRightOfKings:=count;
end;

function OGapsgame.AllSpacesRightOfKings:boolean;
var
	row:number;
	count:word;
begin
	count:=0;
	for row:=1 to NROWS do count:=count+CountSpacesRightOfKings(Tableaus[(NCOLS*(row-1)+1)..(NCOLS*(row-1)+13)]);
	AllSpacesRightOfKings:=(count=4);
end;

{$ifdef TEST}
type
	FakeGapPile=object(GapPile)
		constructor Init(No:integer);
		procedure AddTestCard(aCard:TCard);
	end;
	FakeGapPilePtr=^FakeGapPile;

	testable_OGapsgame=object(OGapsgame)
		constructor Construct;
	end;

	TestGapsgame=object(testable_OGapsgame)
		procedure FillRemainderWithAnyCard(aPosition:number);
	end;

constructor FakeGapPile.Init(No:integer); 
begin 
	thePile:=new(PPileOfCards,Construct(1));
	Ordinal:=No;
end;

procedure FakeGapPile.AddTestCard(aCard:TCard);
begin //writeln('FakeGapPile.AddTestCard(',aCard,')');
	thePile^.DiscardTop;
	thePile^.Add(aCard);
end;

constructor testable_OGapsgame.Construct;
var
	n:number;
begin
	for n:=1 to NTABLEAUS do FakeGapPilePtr(Tableaus[n]):=New(FakeGapPilePtr,Init(n));
end;

procedure TestGapsgame.FillRemainderWithAnyCard(aPosition:number);
var
	i:number;
begin
	for i:=aPosition to NTABLEAUS do FakeGapPilePtr(Tableaus[i])^.AddTestCard(MakeCard(3,TDIAMONDS));
end;

procedure test_CountSpacesRightOfKings;
var
	piles:array[1..4] of GapPileP;
	i:word;
	
	procedure FillAllPilesWithAnyCard;
	var
		i:number;
	begin
		for i:=1 to 4 do piles[i]^.thePile^.Add(MakeCard(3,TSPADES));
	end;

	procedure initialize_test;
	var
		i:number;
	begin
		for i:=1 to 4 do piles[i]:=New(FakeGapPilePtr,Init(1))
	end;
	
	procedure setup_all_empty_piles;
	var
		i:number;
	begin
		for i:=1 to 4 do piles[i]^.thePile^.DiscardTop;
	end;
	
	procedure setup_card_in_pile(pile:number;card:TCard);
	begin
		setup_all_empty_piles;
		FakeGapPile(piles[pile]^).AddTestCard(card);
	end;

	procedure setup_king_in_pile(pile:number);
	begin
		setup_all_empty_piles;
		FakeGapPile(piles[pile]^).AddTestCard(MakeCard(TKING,TSPADES));
	end;
	
begin
	initialize_test;
	setup_king_in_pile(1);
	AssertAreEqual(3,CountSpacesRightOfKings(piles));
	setup_king_in_pile(2);
	AssertAreEqual(2,CountSpacesRightOfKings(piles));
	setup_king_in_pile(4);
	AssertAreEqual(0,CountSpacesRightOfKings(piles));
	setup_all_empty_piles;
	AssertAreEqual(0,CountSpacesRightOfKings(piles));
	setup_card_in_pile(2,MakeCard(3,TDIAMONDS));
	AssertAreEqual(0,CountSpacesRightOfKings(piles));
end;

procedure test_AllSpacesRightOfKings;
var
	game:TestGapsgame;

	procedure add_king_to_pile(pile:number);
	begin
		FakeGapPilePtr(game.Tableaus[pile])^.AddTestCard(MakeCard(TKING,TSPADES));
	end;

	procedure fill_with_any_card_starting_at_pile(pile:number);
	begin
		game.FillRemainderWithAnyCard(pile);
	end;

	procedure setup_all_spaces_in_first_row;
	begin
		add_king_to_pile(1);
		add_king_to_pile(3);
		add_king_to_pile(5);
		add_king_to_pile(7);
		fill_with_any_card_starting_at_pile(9);
	end;

	procedure empty_pile(pile:number);
	begin
		game.Tableaus[pile]^.thePile^.DiscardTop;
	end;
	
	procedure insert_space_right_of_king_at_pile(pile:number);
	begin
		empty_pile(pile-1);
		add_king_to_pile(pile-1);
		empty_pile(pile);
	end;
	
	procedure setup_all_spaces_in_rows_1_2;
	begin
		fill_with_any_card_starting_at_pile(1);
		insert_space_right_of_king_at_pile(5);
		insert_space_right_of_king_at_pile(10);
		insert_space_right_of_king_at_pile(NCOLS+3);
		insert_space_right_of_king_at_pile(NCOLS+8);
	end;

	procedure setup_all_spaces_in_rows_1_2_3;
	begin
		fill_with_any_card_starting_at_pile(1);
		insert_space_right_of_king_at_pile(2);
		insert_space_right_of_king_at_pile(10);
		insert_space_right_of_king_at_pile(26);
		insert_space_right_of_king_at_pile(28);
	end;

	procedure setup_all_spaces_across_all_rows;
	begin
		fill_with_any_card_starting_at_pile(1);
		insert_space_right_of_king_at_pile(13);
		insert_space_right_of_king_at_pile(15);
		insert_space_right_of_king_at_pile(39);
		insert_space_right_of_king_at_pile(52);
	end;

	procedure add_space_at_pile(pile:number);
	begin
		game.Tableaus[pile]^.thePile^.DiscardTop
	end;
	
begin
	game.Construct;
	AssertIsFalse(game.AllSpacesRightOfKings);
	setup_all_spaces_in_first_row;
	AssertIsTrue(game.AllSpacesRightOfKings);
	setup_all_spaces_in_rows_1_2;
	AssertIsTrue(game.AllSpacesRightOfKings);
	setup_all_spaces_in_rows_1_2_3;
	AssertIsTrue(game.AllSpacesRightOfKings);
	setup_all_spaces_across_all_rows;
	AssertIsTrue(game.AllSpacesRightOfKings);
end;
{$endif}

function OGapsgame.PlayIsBlocked:boolean;
begin
	PlayIsBlocked:=AllSpacesRightOfKings;
end;

function OGapsgame.GameIsLost:boolean;
begin //writeln('OGapsgame.GameIsLost');
	GameIsLost:=inherited GameIsLost and (game_parameters.redeals_remaining=0);
end;

{$ifdef TEST}
type
	BlockedGapsgame=object(testable_OGapsgame)
		AllSpacesRightOfKings_result:boolean;
		function AllSpacesRightOfKings:boolean; virtual;
	end;
	
function BlockedGapsgame.AllSpacesRightOfKings:boolean; 
begin 
	AllSpacesRightOfKings:=AllSpacesRightOfKings_result; 
end;

procedure test_Blocked;
var
	game:BlockedGapsgame;
begin
	game.Construct;
	game_parameters.redeals_remaining:=1;
	game.AllSpacesRightOfKings_result:=TRUE;
	AssertIsTrue(game.PlayIsBlocked);
	AssertIsFalse(game.GameIsLost);
	game_parameters.redeals_remaining:=1;
	game.AllSpacesRightOfKings_result:=FALSE;
	AssertIsFalse(game.PlayIsBlocked);
	AssertIsFalse(game.GameIsLost);
	game_parameters.redeals_remaining:=0;
	game.AllSpacesRightOfKings_result:=FALSE;
	AssertIsFalse(game.PlayIsBlocked);
	AssertIsFalse(game.GameIsLost);
	game_parameters.redeals_remaining:=0;
	game.AllSpacesRightOfKings_result:=TRUE;
	AssertIsTrue(game.PlayIsBlocked);
	AssertIsTrue(game.GameIsLost);
end;
{$endif}

procedure GapPile.OnCardAdded;
begin
	if not dealing then UpdateScoreWindow(SolGameP(mytabletop^.myGame));
end;

constructor GapPile.Init(No:integer);
begin
	 inherited Construct;
	 m_tag:=StrNew('Gap');
	 Ordinal:=No;
	 AppendDesc('Into each space move the next higher in suit to the card at the left of the space.');
	 AppendDesc('A space at the extreme left of a row may be filled by any deuce.');
	 AppendDesc('No card may be moved into a space to the right of a king.');
 end;

function OGapsgame.OnPlayBlocked:LONG;
var
	tmp:DeckOfCards;
	i,j,k:integer;
begin //writeln('OGapsgame.OnPlayBlocked');
	OnPlayBlocked:=0;
	if game_parameters.redeals_remaining>0 then begin
		MessageBox(AppWnd,'All open spaces are to the right of Kings. One redeal is permitted.','Play is Blocked', MB_OK or MB_ICONEXCLAMATION);
		Dec(game_parameters.redeals_remaining);
		dealing:=TRUE;
		tmp.Construct(52);
		for i:=1 to NROWS do begin
			j:=1;
			while (j<=NCOLS) and (not Tableaus[(i-1)*NCOLS+j]^.IsEmpty) and Tableaus[(i-1)*NCOLS+j]^.CardInPosn do Inc(j);
			if j<=NCOLS then for k:=j to NCOLS do with Tableaus[(i-1)*NCOLS+k]^ do if not IsEmpty then begin
				tmp.Add(Topcard);
				DiscardTop;
			end;
		end;
		if (tmp.Size > 0) then begin
			tmp.Shuffle;
			for i:=1 to NROWS do begin
				j:=1;
				while (j<=NCOLS) and (not Tableaus[(i-1)*NCOLS+j]^.IsEmpty) do Inc(j);
				if j<NCOLS then for k:=j+1 to NCOLS do with Tableaus[(i-1)*NCOLS+k]^ do begin
					AddCard(tmp.removetop);
					FlipTopcard;
				end;
			end;
		end;
		dealing:=FALSE;
		{$ifdef AUTO_PLAY} Autoplay; {$endif}
	end
	else inherited OnGameLost;
end;

function GapPile.GetAnchorPoint(table_width,table_height:word):xypair;
begin
	with the_game^ do GetAnchorPoint:=MakeXYPair(
		Center(ColumnSpan(NCOLS), 0, table_width) + ColumnOffset((Ordinal-1) mod NCOLS),
		Center(RowSpan(NROWS), 0, table_height) + RowOffset((Ordinal-1) div NCOLS));
end;

function OGapsgame.PileRows:word; 
begin 
	PileRows:=NROWS; 
end;

function OGapsgame.PileColumns:word; 
begin 
	PileColumns:=NCOLS+1; 
end;

function OGapsgame.PileSpacing:integer;
begin
	PileSpacing:=3;
end;

procedure OGapsgame.ToGameState(var state:gameState);
var
	n:number;
begin
	for n:=1 to NTABLEAUS do if Tableaus[n]^.Size>0 then state.pile[n]:=TCardToCard(Tableaus[n]^.Topcard) else state.pile[n]:=NOCARD;
end;

function OGapsgame.ToGameState:gameState;
var
	state:gameState;
begin
	self.ToGameState(state);
	ToGameState:=state;
end;

{$ifdef TEST}
begin
	Suite.Add(@test_CountSpacesRightOfKings);
	Suite.Add(@test_AllSpacesRightOfKings);
	Suite.Add(@test_Blocked);
	Suite.Run('gaps');
{$endif TEST}
end.
