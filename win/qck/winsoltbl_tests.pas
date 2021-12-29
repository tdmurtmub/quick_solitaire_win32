{ (C) 2009 Wesley Steiner }

{$MODE FPC}

unit winsoltbl_tests;

interface

uses
	std,
	punit,
	cards,
	winCardFactory,
	winqcktbl,
	winsoltbl,
	xy;
	
{$I punit.inc}

type
	TTableauDnTester=object(TTableauDn)
		constructor Construct;
	end;

	testable_OSolGameBase=object(SolGameBase)
		constructor Construct(game_id:eGameId);
		function PileRows:word; virtual;
		function PileColumns:word; virtual;
		function PileSpacing:integer; virtual;
	end;

	mock_SolGame=object(testable_OSolGameBase)
	end;
	mock_PSolGame=^mock_SolGame;
	
	testable_OWastepileProp=object(OWastepileProp)
		constructor Construct;
		procedure RefreshCard(n:number); virtual;
	end;
	testable_PWastepileProp=^testable_OWastepileProp;

procedure wastepile_flips_topcard_on_added(p:pointer);

implementation 

uses
	windowsx;
	
type
	MockSolTableViewP=^MockSolTableView;
	MockSolTableView=object(SolTableView)
		constructor Construct;
		function Height:word; virtual;
		function Width:word; virtual;
	end;

constructor MockSolTableView.Construct;
begin
	inherited Construct(0, NULL_HANDLE, FALSE);
end;

function MockSolTableView.Height:WORD;
begin
	Height:= 400;
end;

function MockSolTableView.Width:WORD;
begin
	Width:= 500;
end;

constructor TTableauDnTester.Construct; 
begin 
	thePile:= New(PPileOfCards,Construct(2));
end;

procedure Test_TTableauDn_Accepts;
var
	testee:TTableauDnTester;
begin
	testee.Construct;
	testee.thePile^.Add(MakeCard(TACE,TSPADES));
	testee.thePile^.FlipTop;
	punit.Assert.IsFalse(testee.Accepts(MakeCard(TKING,TSPADES)));
end;

type
	TestGenericFndtnPile = object(GenericFndtnPile)
		constructor Init;
	end;

constructor TestGenericFndtnPile.Init; begin end;

procedure IsDblClkTargetShouldReturnTrueByDefault; 
var
	aTestGenericFndtnPile:TestGenericFndtnPile;
begin
	aTestGenericFndtnPile.Init;
	{ should return true by default }
	punit.Assert.IsTrue(aTestGenericFndtnPile.IsDblClkTarget);
end; 

constructor testable_OSolGameBase.Construct(game_id:eGameId); 
begin 	
	inherited Construct(game_id,New(MockSolTableViewP,Construct));
	Initialize(game_id);
end;

function testable_OSolGameBase.PileRows:word; 
begin 
	PileRows:=2; 
end;

function testable_OSolGameBase.PileColumns:word; 
begin 
	PileColumns:=3; 
end;

function testable_OSolGameBase.PileSpacing:integer; 
begin 
	PileSpacing:=10; 
end;

procedure PileCenterPoint;
var
	game:testable_OSolGameBase;
begin
	game.Construct(GID_STANDARD);
	CardImageWd:=21;
	CardImageHt:=41;
	AssertAreEqual(Center(83, 0, 500)+10, xypairWrapper(game.PileCenterPoint(1,1)).X);
	AssertAreEqual(Center(92, 0, 400)+20, xypairWrapper(game.PileCenterPoint(1,1)).Y);
end;

procedure PlayIsNotBlockedByDefault;
var
	game:testable_OSolGameBase;
begin
	game.Construct(GID_STANDARD);
	AssertIsFalse(game.PlayIsBlocked);
end;

constructor testable_OWastepileProp.Construct;
begin
	inherited Construct;
end;

procedure testable_OWastepileProp.RefreshCard(n:number); begin end;
	
procedure wastepile_flips_topcard_on_added(p:pointer);
var
	waste:testable_PWastepileProp;
begin
	waste:=testable_PWastepileProp(p);
	waste^.AddCard(MakeCard(TACE,TSPADES));
	AssertIsTrue(waste^.TopFaceup);
end;

begin
	x_SoundStatus:=FALSE;
	Suite.Add(@IsDblClkTargetShouldReturnTrueByDefault);
	Suite.Add(@PileCenterPoint);
	Suite.Add(@Test_TTableauDn_Accepts);
	Suite.Add(@PlayIsNotBlockedByDefault);
	RunTest(@wastepile_flips_topcard_on_added, New(testable_PWastepileProp, Construct));
	Suite.Run('winsoltbl_tests');
end.
