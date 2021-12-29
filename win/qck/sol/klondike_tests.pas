{ (C) 1998 Wesley Steiner }

{$MODE FPC}

unit klondike_tests;

interface

implementation

uses
	std,
	punit,
	cards,
	winsoltbl, winsoltbl_tests,
	klondike;

type
	testable_StandardGame=object(OStandardgame)
		constructor Construct;
	end;

constructor testable_StandardGame.Construct; 
begin 
end;

procedure variation_names;
var
	game:testable_StandardGame;
begin
	game.Construct;
	punit.Assert.EqualText('Standard', game.VariationName(0));
	punit.Assert.EqualText('Deal Singles', game.VariationName(1));
end;

type
	testable_klondike_OWastepile=object(klondike.OWastepile)
		procedure RefreshCard(n:number); virtual;
	end;
	testable_klondike_OWastepileP=^testable_klondike_OWastepile;

procedure testable_klondike_OWastepile.RefreshCard(n:number); begin end;
	
begin
	RunTest(@wastepile_flips_topcard_on_added, New(testable_klondike_OWastepileP, Construct));
	Suite.Add(@variation_names);
	Suite.Run('klondike_tests');
end.
