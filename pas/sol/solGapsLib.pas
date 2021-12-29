{ (C) 2011 Wesley Steiner }

{$MODE FPC}

{$I platform}

unit solgapslib;

interface

uses
	std,
	cards;

type
	gameparameters=record
		redeals_remaining:quantity;
	end;
	
	pilenumber=1..52;
	gamestate=record
		pile:array[pilenumber] of cards.card;
	end;

function PileAcceptsCard(const state:gamestate; pile:pilenumber; card:cards.card):boolean;

procedure ClearGameState(var state:gamestate);
procedure InitializeGameParameters(var parameters:gameparameters);
	
implementation

function PileAcceptsCard(const state:gamestate; pile:pilenumber; card:cards.card):boolean;
	function IsLeftMostPile(pile:pilenumber):boolean; begin IsLeftMostPile:=(((pile-1) mod 13)=0); end;
	function DeuceCheck:boolean; begin DeuceCheck:=(GetCardPip(card)=DEUCE) and IsLeftMostPile(pile); end;

	function NonDeuceCheck:boolean;
	begin
		NonDeuceCheck:=(not IsLeftmostPile(pile)) and
			(
				(GetCardPip(state.pile[pile-1])=pip(Ord(GetCardPip(card))-1))
				and
				(GetCardSuit(state.pile[pile-1])=GetCardSuit(card))
			);
	end;

begin
	PileAcceptsCard:=(state.pile[pile]=NOCARD) and (DeuceCheck or NonDeuceCheck);
end;

procedure ClearGameState(var state:gamestate);
var
	pn:pilenumber;
begin
	for pn:=Low(pilenumber) to High(pilenumber) do state.pile[pn]:=NOCARD;
end;

procedure InitializeGameParameters(var parameters:gameparameters);
begin
	parameters.redeals_remaining:=1;
end;

end.
