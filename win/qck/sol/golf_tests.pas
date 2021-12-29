{ (C) 2013 Wesley Steiner }

{$MODE FPC}

unit golf_tests;

interface

implementation

uses
	punit, 
	cards,
	golf;

type
	testable_OFoundationpile=object(golf.OFoundationpile)
		constructor Construct;
	end;

constructor testable_OFoundationpile.Construct; 
begin 
	inherited Construct(NIL);
end;

procedure Test_Accepts;
var
	pile:testable_OFoundationpile;
begin
	pile.Construct;
	pile.thePile^.Add(MakeCard(TACE, TSPADES));
	AssertIsTrue(pile.Accepts(MakeCard(TDEUCE, TCLUBS)));
	AssertIsFalse(pile.Accepts(MakeCard(TTHREE, TCLUBS)));
end;

begin
	Suite.Add(@Test_Accepts);
	Suite.Run('golf_tests');
end.
