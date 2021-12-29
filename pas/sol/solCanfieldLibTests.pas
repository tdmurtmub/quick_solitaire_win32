{ (C) 2011 Wesley Steiner }

{$MODE FPC}

{$I platform}

unit solCanfieldLibTests;

interface

implementation

uses
	punit,
	cards,
	solCanfieldLib;

procedure test_ClearGameState;
begin
	AssertFail;
end;

begin
	Suite.Add(@test_ClearGameState);
	Suite.Run('solCanfieldLibTests');
end.
