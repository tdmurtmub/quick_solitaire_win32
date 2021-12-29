{ (C) 2011 Wesley Steiner }

{$MODE FPC}

unit gaps_tests;

interface

implementation

uses
	punit,
	std,
	cards,
	solgapslib, solgapslib_tests,
	gaps;

type
	mock_GapPile=object(GapPile)
		constructor Init(No:integer);
		procedure AddTestCard(aCard:TCard);
	end;
	mock_PGapPile=^mock_GapPile;

	testable_OGapsgame=object(OGapsgame)
		constructor Construct;
	end;

constructor mock_GapPile.Init(No:integer); 
begin 
	thePile:=new(PPileOfCards,Construct(1));
	Ordinal:=No;
end;

procedure mock_GapPile.AddTestCard(aCard:TCard);
begin //writeln('mock_GapPile.AddTestCard(',aCard,')');
	thePile^.DiscardTop;
	thePile^.Add(aCard);
end;

constructor testable_OGapsgame.Construct;
var
	n:number;
begin
	for n:=1 to NTABLEAUS do mock_PGapPile(Tableaus[n]):=New(mock_PGapPile,Init(n));
end;

const
	ANY_PILE:pileNumber=9;

procedure test_convert_to_GameState;
var
	game:testable_OGapsgame;
	state:solGapsLib.GameState;
begin
	game.Construct;
	game.ToGameState(state);
	AssertAreEqual(NOCARD,state.pile[ANY_PILE]);
	mock_PGapPile(game.Tableaus[10])^.AddTestCard(MakeCard(TTHREE,TCLUB));
	game.ToGameState(state);
	AssertAreEqual(CreateCard(THREE,CLUB),state.pile[10]);
	mock_PGapPile(game.Tableaus[NTABLEAUS])^.AddTestCard(MakeCard(TKING,TSPADE));
	game.ToGameState(state);
	AssertAreEqual(CreateCard(KING,SPADE),state.pile[High(pileNumber)]);
	mock_PGapPile(game.Tableaus[1])^.AddTestCard(MakeCard(TACE,TCLUB));
	game.ToGameState(state);
	AssertAreEqual(CreateCard(ACE,CLUB),state.pile[Low(pileNumber)]);
end;

procedure test_convert_to_GameState_function;
var
	game:testable_OGapsgame;
	state:solGapsLib.GameState;
begin
	game.Construct;
	mock_PGapPile(game.Tableaus[ANY_PILE])^.AddTestCard(MakeCard(TTHREE,TCLUB));
	AssertAreEqual(CreateCard(THREE,CLUB),game.ToGameState.pile[ANY_PILE]);
end;

begin
	Suite.Add(@test_convert_to_GameState);
	Suite.Add(@test_convert_to_GameState_function);
	Suite.Run('gapsTests');
end.
