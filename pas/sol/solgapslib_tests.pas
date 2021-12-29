{ (C) 2011 Wesley Steiner }

{$MODE FPC}

{$I platform}

unit solgapslib_tests;

interface

implementation

uses
	punit,
	cards,
	solGapsLib;

procedure test_ClearGameState;
var
	pn:pileNumber;
	state:gameState;
begin
	for pn:=Low(pileNumber) to High(pileNumber) do state.pile[pn]:=$FF;
	ClearGameState(state);
	for pn:=Low(pileNumber) to High(pileNumber) do AssertAreEqual(NOCARD,state.pile[pn]);
end;

procedure GameParametersInitialization;
var
	parameters:gameParameters;
begin
	InitializeGameParameters(parameters);
	AssertAreEqual(1, parameters.redeals_remaining);
end;

const
	ANY_PILE:pileNumber=23;

procedure PileAcceptsCard_deuce;
var
	state:gameState;
	any_deuce,non_deuce:card;
begin
	ClearGameState(state);
	any_deuce:=CreateCard(DEUCE,HEART);
	non_deuce:=CreateCard(SEVEN,SPADE);
	AssertIsTrue(PileAcceptsCard(state,1,any_deuce));
	AssertIsTrue(PileAcceptsCard(state,14,any_deuce));
	AssertIsTrue(PileAcceptsCard(state,27,any_deuce));
	AssertIsTrue(PileAcceptsCard(state,40,any_deuce));
	AssertIsFalse(PileAcceptsCard(state,40,non_deuce));
end;

procedure PileAcceptsCard_non_deuce;
var
	state:gameState;
begin
	ClearGameState(state);
	state.pile[ANY_PILE]:=CreateCard(TEN,DIAMOND);
	AssertIsTrue(PileAcceptsCard(state,ANY_PILE+1,CreateCard(JACK,DIAMOND)));
	AssertIsFalse(PileAcceptsCard(state,ANY_PILE+1,CreateCard(JACK,CLUB)));
	state.pile[13]:=CreateCard(NINE,CLUB);
	AssertIsFalse(PileAcceptsCard(state,14,CreateCard(TEN,CLUB)));
end;

procedure PileMustBeEmptyToAcceptCard;
var
	state:gameState;
begin
	ClearGameState(state);
	state.pile[ANY_PILE-1]:=CreateCard(TEN,DIAMOND);
	state.pile[ANY_PILE]:=CreateCard(KING,SPADE);
	AssertIsFalse(PileAcceptsCard(state,ANY_PILE,CreateCard(JACK,DIAMOND)));
end;

begin
	Suite.Add(@GameParametersInitialization);
	Suite.Add(@test_ClearGameState);
	Suite.Add(@PileAcceptsCard_deuce);
	Suite.Add(@PileAcceptsCard_non_deuce);
	Suite.Add(@PileMustBeEmptyToAcceptCard);
	Suite.Run('solgapslib_tests');
end.
