{ (C) 1998 Wesley Steiner }

{$MODE FPC}

{$I Platform}

program QuickSolitaire;

uses
	{$ifdef TEST} punit, {$endif}
	strings,
	stringsx,
	oapp,
	odlg,
	owindows,
	std,
	windowsx,
	quick,
	qcktbl,
	stdwin,
	quickWin,
	winqcktbl, {$ifdef TEST} winqcktbl_tests, {$endif}
	winsoltbl, {$ifdef TEST} winsoltbl_tests, {$endif}
	windows;

{$I punit.inc}
{$R menus.res}
{$R main.res}

const
	IDD_VARIATIONS = 9800;
	CM_GAMEFIRST = 1400;
	MAX_GAME_VARIATIONS = NGAMES*2;
	CM_GAMELAST = CM_GAMEFIRST+MAX_GAME_VARIATIONS-1;

type
	gameCmdId=CM_GAMEFIRST..CM_GAMELAST;
	CmdIdToGameIdMap=array[gameCmdId] of eGameId;

	MainAppP=^MainApp;
	MainFrameP=^MainFrame;
	
	FrameWindowP=^FrameWindow;
	FrameWindow=object(quickWin.FrameWindow)
		function Application:MainAppP; test_virtual
		function OnCmd(aCmdId:UINT):LONG; virtual;
		function OnMsg(aMsg:UINT;wParam:WPARAM;lParam:LPARAM):LONG; virtual;
		function MinFrmHt:word; virtual;
		function MinFrmWd:word; virtual;
		function Tabletop:winsoltbl.SolTableViewP;
	private
		cmdId_to_gameId_map:CmdIdToGameIdMap;
		function DoFileNew:LONG;
		function DoInitMenuPopup(aPopupMenu:HMENU;isSystemMenu:boolean;aMenuIndex:integer):integer;
		function OnSelectGame(aCmdId:UINT):LONG; test_virtual
		function OnStart:LONG;
		function OnVariation:LONG; test_virtual
		procedure AddGameMenuItem(aMenu:HMENU;beforeIndex:integer;cmdId:gameCmdId;game_id:eGameId);
		procedure AddGameMenuItems(aMenu:HMENU;beforeIndex:integer);
		procedure PostConstruct;
		procedure SelectGameById(game_id:eGameId); test_virtual
		procedure UpdateWindowTitle;
	end;
	
	MainFrame=object(quickWin.Frame)
	end;

	MainApp=object(quickWin.Application)
		constructor Init;
		destructor Done; virtual;
		function CurrentGame:SolGameP;
		function Frame:MainFrameP;
		function GetGameVariationDefault(game_id:eGameId):word;
		function HomePageUrl:pchar; virtual;
		function SavedGameId:eGameId;
		function SelectGameVariation:variationIndex; virtual;
		procedure InitMainWindow; virtual;
		procedure OnNew; virtual;
	end;

var
	the_main_app:MainApp;
	
const
	KEY_GAMEID='GameId'; { 0-based index of the current game }

function MainApp.Frame:MainFrameP;
begin
	Frame:=MainFrameP(inherited Frame);
end;

procedure MainApp.OnNew;
begin //writeln('MainApp.OnNew');
	if CurrentGame<>nil then begin
		CurrentGame^.Finish;
		Dispose(CurrentGame,Destruct);
		SetCurrentGame(nil);
	end;
	inherited OnNew;
	{$ifdef STAT_TABLE}
	FillChar(GameStats,SizeOf(GameStats),#0);
	{$endif STAT_TABLE}
end;

constructor MainApp.Init;
begin
	inherited Construct('Solitaire');
	with MainFrameP(MainWindow)^ do begin
		DrawMenuBar(MyFrameWindow^.handle);
	end;
	{$ifdef STAT_TABLE}
	FillChar(GameStats,SizeOf(GameStats),#0);
	{$endif STAT_TABLE}
	UpdateWindow(MainWindow^.MyFrameWindow^.handle);
	splash;
end;

destructor MainApp.Done;
begin
	SetIntegerData(REGKEY_ROOT,KEY_GAMEID,Ord(CurrentGame^.GetGameId));
	inherited Destruct;
end;

procedure MainApp.InitMainWindow;
begin //writeln('MainApp.InitMainWindow');
	MainWindow:=New(MainFrameP,Construct(@self,FALSE));
	MainWindow^.MyFrameWindow:=New(FrameWindowP,Construct);
	MainWindow^.Create;
	Frame^.SetTabletopWindow(
		PTabletop(New(winsoltbl.SolTableViewP,Construct(RGB(0,127,0),
		LoadBitmapFromFile(PChar(GetStringData(KEY_TABLETOP,KEY_TABLETOP_IMAGEPATH,''))),
		GetBooleanData(KEY_TABLETOP,KEY_TABLETOP_USEIMAGE,FALSE)))));
end;

procedure FrameWindow.PostConstruct;
begin
	FillChar(cmdId_to_gameId_map,SizeOf(cmdId_to_gameId_map),#0);
end;

function FrameWindow.Tabletop:SolTableViewP;
begin
	Tabletop:=SolTableViewP(Application^.Frame^.Tabletop);
end;

procedure FrameWindow.SelectGameById(game_id:eGameId);
begin
	Tabletop^.SelectGame(game_id,Application^.GetGameVariationDefault(game_id));
	UpdateWindowTitle;
end;

function FrameWindow.OnSelectGame(aCmdId:UINT):LONG;
	function ConvertCmdIdToGameId(aCmdId:UINT):EGameId; 
	begin 
		ConvertCmdIdToGameId:=cmdId_to_gameId_map[aCmdId]; 
	end;
begin
	SelectGameById(ConvertCmdIdToGameId(aCmdId));
	with Application^ do if ShowVariationDialog and (CurrentGame^.VariationCount>0) then OnVariation;
	OnSelectGame:=0;
end;

{$ifdef TEST}
type	
	testable_OMainApp=object(MainApp)
		myGetIntegerData:CallTelemetry;
		myGetIntegerDataValue:longint;
		myKey,mySubKey:string;
		myDefaultValue:longint;
		constructor Init;
		function FullName:pchar; virtual;
		function GetIntegerData(aKey,aSubKey:pchar;aDefaultValue:longint):longint; virtual;
	end;

constructor testable_OMainApp.Init; begin end;

function testable_OMainApp.FullName:PChar; begin FullName:= 'Fake Full Name'; end;

function testable_OMainApp.GetIntegerData(aKey,aSubKey:pchar;aDefaultValue:longint):longint;
begin
	myGetIntegerData.WasCalled:=TRUE;
	myKey:=StrPas(aKey);
	mySubKey:=StrPas(aSubKey);
	myDefaultValue:=aDefaultValue;
	GetIntegerData:=myGetIntegerDataValue;
end;

type
	testable_OFrameWindow=object(FrameWindow)
		constructor Construct;
	end;

constructor testable_OFrameWindow.Construct; begin end;

type	
	MainFrameProxy=object(testable_OFrameWindow)
		my_owner:MainAppP;
		constructor Construct(app:MainAppP);
		function Application:MainAppP; virtual;
	end;

constructor MainFrameProxy.Construct(app:MainAppP); 
begin 
	inherited Construct;
	my_owner:=app; 
	PostConstruct; 
	theApplication:=app;
end;

function MainFrameProxy.Application:MainAppP; begin Application:=my_owner; end;

type
	SelectGameTester=object(MainFrameProxy)
		SelectGameById_was_called:boolean;
		SelectGameById_arg:eGameId;
		OnVariation_was_called:boolean;
		function OnVariation:LONG; virtual;
		procedure SelectGameById(game_id:eGameId); virtual;
	end;

function SelectGameTester.OnVariation:LONG; 
begin 
	OnVariation_was_called:=TRUE;
	OnVariation:=0; 
end;
	
procedure SelectGameTester.SelectGameById(game_id:eGameId);
begin
	SelectGameById_was_called:=TRUE;
	SelectGameById_arg:=game_id;
end;

type
	MainAppProxy=object(testable_OMainApp)
		ShowVariationDialog_result:boolean;
		function ShowVariationDialog:boolean; virtual;
		procedure PersistVariationSelection(game_id:gameIndex;n:variationIndex); virtual;
	end;

procedure MainAppProxy.PersistVariationSelection(game_id:gameIndex;n:variationIndex); begin end;
function MainAppProxy.ShowVariationDialog:boolean; begin ShowVariationDialog:=ShowVariationDialog_result; end;
	
type
	SolGameStub=object(SolGame)
		constructor Construct(game_id:eGameId;tabletop:SolTableViewP);
	end;
	
constructor SolGameStub.Construct(game_id:eGameId;tabletop:SolTableViewP); begin end;
	
type
	SolGameProxy=object(SolGameStub)
		myTitle:pchar;
		VariationCount_result:word;
		VariationName_result:pchar;
		SelectVariation_result:variationIndex;
		constructor Construct;
		function PackCount:word; virtual;
		function Title:pchar; virtual;
		function VariationName(n:variationIndex):pchar; virtual;
		function VariationCount:variationIndex; virtual;
		function SelectVariation:variationIndex; virtual;
	end;

constructor SolGameProxy.Construct; begin end;
function SolGameProxy.VariationName(n:variationIndex):pchar; begin VariationName:=VariationName_result; end;
function SolGameProxy.Title:pchar; begin Title:=myTitle; end;
function SolGameProxy.VariationCount:variationIndex; begin VariationCount:=VariationCount_result; end;
function SolGameProxy.PackCount:word; begin PackCount:=1; end;
function SolGameProxy.SelectVariation:variationIndex; begin SelectVariation:=SelectVariation_result; end;

procedure Test_OnSelectGame;
const
	A_GAME_CMD_ID=CM_GAMEFIRST+1;
	A_GAME_ID=GID_PYRAMID;
	NON_ZERO=1;
var
	testee:SelectGameTester;
	fake_app:MainAppProxy;
	fake_game:SolGameProxy;
begin
	fake_app.Init;
	fake_game.Construct;
	fake_app.SetCurrentGame(@fake_game);
	testee.Construct(@fake_app);
	testee.cmdId_to_gameId_map[A_GAME_CMD_ID]:=A_GAME_ID;

	testee.OnVariation_was_called:=FALSE;
	fake_app.ShowVariationDialog_result:=TRUE;
	fake_game.VariationCount_result:=NON_ZERO;
	testee.OnSelectGame(A_GAME_CMD_ID);
	punit.Assert.IsTrue(testee.SelectGameById_was_called);
	punit.Assert.Equal(LongInt(A_GAME_ID),LongInt(testee.SelectGameById_arg));
	AssertIsTrue(testee.OnVariation_was_called);

	testee.OnVariation_was_called:=FALSE;
	fake_app.ShowVariationDialog_result:=TRUE;
	fake_game.VariationCount_result:=0;
	testee.OnSelectGame(A_GAME_CMD_ID);
	AssertIsFalse(testee.OnVariation_was_called);

	testee.OnVariation_was_called:=FALSE;
	fake_app.ShowVariationDialog_result:=FALSE;
	fake_game.VariationCount_result:=NON_ZERO;
	testee.OnSelectGame(A_GAME_CMD_ID);
	AssertIsFalse(testee.OnVariation_was_called);

	testee.OnVariation_was_called:=FALSE;
	fake_app.ShowVariationDialog_result:=FALSE;
	fake_game.VariationCount_result:=0;
	testee.OnSelectGame(A_GAME_CMD_ID);
	AssertIsFalse(testee.OnVariation_was_called);
end;

{$endif TEST}

function FrameWindow.Application:MainAppP;
begin
	Application:=@the_main_app;
end;

function FrameWindow.OnVariation:LONG;
begin
	with Application^ do if ChooseVariation then SelectGameById(CurrentGame^.GetGameId);
	OnVariation:=0;
end;

function FrameWindow.DoFileNew:LONG;
begin //writeln('FrameWindow.DoFileNew');
	with the_main_app do begin
		EmptyTableTop;
		with CurrentGame^ do begin
			Setup;
			Deal;
		end;
	end;
	DoFileNew:=0;
end;

function FrameWindow.OnMsg(aMsg:UINT;wParam:WPARAM;lParam:LPARAM):LONG;
begin
	case aMsg of
		WM_INITMENUPOPUP:OnMsg:=DoInitMenuPopup(HMENU(wParam),HIWORD(lParam)<>0,LOWORD(lParam));
		WM_GAMELOST:begin
			the_main_app.CurrentGame^.OnGameLost;
			OnMsg:=0;
		end;
		WM_START:OnMsg:=OnStart;
		WM_GAMEWON:begin
			the_main_app.CurrentGame^.OnGameWon;
			OnMsg:=0;
		end;
		WM_PLAYBLOCKED:OnMsg:=the_main_app.CurrentGame^.OnPlayBlocked;
		else OnMsg:=inherited OnMsg(aMsg,wParam,lParam);
	end;
end;

type
	deckRange=1..2;

function NumDecksAsText(nDecks:deckRange):pchar;
begin
	case nDecks of
		1:NumDecksAsText:='Single';
		2:NumDecksAsText:='Double';
	end;
end;

{$ifdef TEST}

procedure Test_NumDecksAsText; 
begin
	punit.Assert.EqualText('Single',NumDecksAsText(1));
	punit.Assert.EqualText('Double',NumDecksAsText(2));
end;

{$endif TEST}

function ComposeTitle(appName:pchar;aGame:SolGameP):string;
var
	title:string;
begin
	title:=StrPas(appName);
	if aGame<>nil then begin
		title:=title+' - '+StrPas(aGame^.Title);
		if (aGame^.VariationCount>0) and (aGame^.Variation>0) then title:=title+'/'+StrPas(aGame^.VariationName(aGame^.Variation));
		title:=title+' ('+StrPas(NumDecksAsText(deckRange(aGame^.PackCount)))+' Pack)';
	end;
	ComposeTitle:=title;
end;

procedure FrameWindow.UpdateWindowTitle;
var
	buffer:stringBuffer;
begin
	SetWindowText(StrPCopy(buffer,ComposeTitle(the_main_app.FullName,the_main_app.CurrentGame)));
end;

function FrameWindow.OnStart:LONG;
begin
	AddGameMenuItems(Application^.Frame^.GameMenu,3);
	InsertMenu(Application^.Frame^.GameMenu,CM_OPTIONSSOUND,MF_BYCOMMAND or MF_SEPARATOR,0,nil);
	Application^.OnNew;
	UpdateWindow;
	SelectGameById(the_main_app.SavedGameId);
	OnStart:=0;
end;

procedure FrameWindow.AddGameMenuItem(aMenu:HMENU;beforeIndex:integer;cmdId:gameCmdId;game_id:eGameId);
begin
	System.Assert(aMenu<>0,'FrameWindow.AddGameMenuItem: aMenu cannot be 0');
	InsertMenu(aMenu,beforeIndex,MF_BYPOSITION or MF_STRING,cmdId,GetGameTitle(game_id));
	cmdId_to_gameId_map[cmdId]:=game_id;
end;

{$ifdef TEST}
type
	TestMainFrame1=object(MainFrameProxy)
		OnSelectGameWasCalled:boolean;
		OnSelectGameCmdId:UINT;
		function OnVariation:LONG; virtual;
		function OnSelectGame(aCmdId:UINT):LONG; virtual;
	end;

function TestMainFrame1.OnSelectGame(aCmdId:UINT):LONG;
begin
	OnSelectGameWasCalled:=true;
	OnSelectGameCmdId:=aCmdId;
	OnSelectGame:=0;
end;

function TestMainFrame1.OnVariation:LONG; begin OnVariation:=0; end;

procedure Test_AddGameMenuItem;
var
	testee:testable_OFrameWindow;
	menu:HMENU;
begin
	testee.Construct;
	menu:=CreatePopupMenu;
	testee.AddGameMenuItem(menu,0,CM_GAMEFIRST,GID_PYRAMID);
	punit.Assert.Equal(1,GetMenuItemCount(menu));
	punit.Assert.Equal(CM_GAMEFIRST,GetMenuItemId(menu,0));
	punit.Assert.Equal(Ord(GID_PYRAMID),Ord(testee.cmdId_to_gameId_map[CM_GAMEFIRST]));
end;
{$endif}

procedure FrameWindow.AddGameMenuItems(aMenu:HMENU;beforeIndex:integer);
var
	i:integer;
begin
	for i:=NGAMES downto 1 do AddGameMenuItem(aMenu,beforeIndex,gameCmdId(CM_GAMEFIRST+i-1),eGameId(i-1));
end;

{$ifdef TEST}
procedure Test_AddGameMenuItems;
var
	aTestFrame:testable_OFrameWindow;
	aHMenu:HMENU;
	i:integer;
	aTextBuffer:array [0..99] of char;
	aLen:int;
begin
	aHMenu:=CreatePopupMenu;
	aTestFrame.Construct;
	aTestFrame.AddGameMenuItems(aHMenu,0);
	{ test that all games were added }
	punit.Assert.Equal(NGAMES, GetMenuItemCount(aHMenu));
	{ test the command id's }
	for i:= 0 to NGAMES - 1 do begin
		punit.Assert.Equal(CM_GAMEFIRST + i, GetMenuItemId(aHMenu, i));
	end;
	{ test the menu item text }
	for i:=0 to NGAMES-1 do begin
		aLen:=GetMenuString(aHMenu,i,aTextBuffer,100,MF_BYPOSITION);
		punit.Assert.EqualText(GetGameTitle(eGameId(i)), aTextBuffer);
	end;
end;
{$endif}

function FrameWindow.DoInitMenuPopup(aPopupMenu:HMENU;isSystemMenu:boolean;aMenuIndex:integer):integer;
var
	i:uint;
begin //writeln('FrameWindow.DoInitMenuPopup(aPopupMenu:HMENU;isSystemMenu;aMenuIndex)');
	if not isSystemMenu then begin
		if aMenuIndex=MENU_INDEX_GAME then begin
			for i:=CM_GAMEFIRST to CM_GAMELAST do CheckMenuItem(aPopupMenu,i,MF_BYCOMMAND or MF_UNCHECKED);
			CheckMenuItem(aPopupMenu,CM_GAMEFIRST+Ord(the_main_app.CurrentGame^.GetGameId),MF_BYCOMMAND or MF_CHECKED);
			EnableMenuItem(aPopupMenu,CM_VARIATION,MF_BYCOMMAND or Q(the_app^.CurrentGame^.VariationCount>0,MF_ENABLED,MF_GRAYED));
			DoInitMenuPopup:=0;
			Exit;
		end;
	end;
	DoInitMenuPopup:=1;
end;

function MainApp.SavedGameId:eGameId;
var
	index:word;
begin
	index:=Word(GetIntegerData(REGKEY_ROOT,KEY_GAMEID,0));
	if index>=NGAMES then
		SavedGameId:=GID_STANDARD
	else
		SavedGameId:=eGameId(index);
end;

{$ifdef TEST}

type
	testable_OMainFrame=object(MainFrame)
		constructor Init;
	end;

constructor testable_OMainFrame.Init; begin end;
type
	TestTSolApp=object(MainApp)
		myKey,mySubKey:string;
		myValue:longint;
		constructor Init;
		procedure SetIntegerData(aKey,aSubKey:pchar;aValue:longint); virtual;
	end;

constructor TestTSolApp.Init; begin end;

procedure TestTSolApp.SetIntegerData(aKey,aSubKey:pchar;aValue:longint);
begin
	myKey:=StrPas(aKey);
	mySubKey:=StrPas(aSubKey);
	myValue:=aValue;
end;

procedure Test_DefaultSavedGameId; 
var
	app:TestTSolApp;
begin
	app.Init;
	{ should return default game id if persisted value is out of range }
	punit.Assert.Equal(integer(GID_STANDARD), integer(app.SavedGameId));
end;

procedure Test_ComposeTitle_when_current_game_is_nil;
begin
	punit.Assert.EqualStr('AppName1',ComposeTitle('AppName1',nil));
end;

procedure Test_ComposeTitle_when_game_has_no_variations;
var
	aGame:testable_OSolGameBase;
begin
	aGame.Construct(GID_PYRAMID);
	punit.Assert.EqualStr('AppName2 - Pyramid (Single Pack)', ComposeTitle('AppName2',@aGame));
end;

procedure Test_ComposeTitle_when_game_has_variations;
var
	game:SolGameProxy;
begin
	game.Construct;
	game.SetVariation(1);
	game.myTitle:='MyTitle';
	game.VariationCount_result:=1;
	game.VariationName_result:='StandardVariation';
	game.SetVariation(0);
	punit.Assert.EqualStr('App Name - MyTitle (Single Pack)',ComposeTitle('App Name',@game));
	game.SetVariation(1);
	punit.Assert.EqualStr('App Name - MyTitle/StandardVariation (Single Pack)',ComposeTitle('App Name',@game));
end;
{$endif TEST}

{$ifdef TEST}
procedure Test_PersistenceKeys; 
begin
	punit.Assert.EqualText('GameId',KEY_GAMEID);
	punit.Assert.EqualText('Variation',KEY_VARIATION);
end;
{$endif TEST}

function TheApp:MainAppP;
begin
	TheApp:=MainAppP(the_app);
end;

function FrameWindow.OnCmd(aCmdId:UINT):LONG;
begin
	case aCmdId of
		CM_GAMEFIRST..CM_GAMELAST:OnCmd:=OnSelectGame(aCmdId);
		CM_FILENEW:OnCmd:=DoFileNew;
		CM_VARIATION:OnCmd:=OnVariation;
		else OnCmd:=inherited OnCmd(aCmdId);
	end
end;

function MainApp.HomePageUrl:pchar;
begin
	HomePageUrl:=quick.HOMEPAGE_DIR+'solitaire.html';
end;

{$ifdef TEST}

procedure Test_unit_initialization;
var
	aApp:TestTSolApp;
begin
	aApp.Init;
	pUnit.Assert.Equal(CM_GAMEFIRST+MAX_GAME_VARIATIONS-1,CM_GAMELAST);
	pUnit.Assert.EqualText('http://www.wesleysteiner.com/quickgames/solitaire.html',aApp.HomePageUrl);
end;

{$endif TEST}

function MainApp.GetGameVariationDefault(game_id:eGameId):word;
var
	aBuffer:stringBuffer;
begin
	GetGameVariationDefault:=Word(GetIntegerData(StrPCopy(aBuffer,GetGameKey(Ord(game_id))),KEY_VARIATION,0));
end;

{$ifdef TEST}
procedure Test_GetGameVariationDefault;
var
	aFakeApp:testable_OMainApp;
	fake_game:SolGameProxy;
begin
	fake_game.Construct;
	fake_game.VariationCount_result:=5;
	aFakeApp.Init;
	aFakeApp.SetCurrentGame(@fake_game);
	aFakeApp.myGetIntegerData.WasCalled:=FALSE;
	aFakeApp.GetGameVariationDefault(GID_PYRAMID);
	punit.Assert.IsTrue(aFakeApp.myGetIntegerData.WasCalled);
	punit.Assert.EqualStr(GetGameKey(Ord(GID_PYRAMID)),aFakeApp.myKey);
	punit.Assert.EqualStr(KEY_VARIATION,aFakeApp.mySubKey);
	punit.Assert.Equal(0,aFakeApp.myDefaultValue);
end;

procedure Test_resources;
begin
	punit.Assert.IsTrue(FindResource(hInstance,'GOLF_CLAP','WAVE')<>0);
end; 	
{$endif TEST}

function FrameWindow.MinFrmHt:word; 

begin
	MinFrmHt:=250;
end;

function FrameWindow.MinFrmWd:word;

begin
	MinFrmWd:=320;
end;

function MainApp.CurrentGame:SolGameP;

begin
	CurrentGame:=SolGameP(inherited CurrentGame);
end;

const
	VD_SHOWDIALOGCHECK=1001;
	
type
	VariationDialog=object(ODialog)
		selection_index:variationIndex;
		constructor Construct(parent:HWND;aGame:SolGameBaseP;checkbox_initial_state:boolean);
		function OnInitDialog:boolean; virtual;
		function OnEndDialog(aCommandId:UINT):boolean; virtual;
	private
		checkbox_state:boolean;
		my_game:SolGameBaseP;
		my_title:stringBuffer;
		function Title:pchar;
	end;

function VariationDialog.Title:pchar;
begin 
	StrCopy(my_title,'Variations of ');
	StrCat(my_title,my_game^.Title);
	Title:=my_title;	
end;

constructor VariationDialog.Construct(parent:HWND;aGame:SolGameBaseP;checkbox_initial_state:boolean);
begin
	inherited Construct(parent,IDD_VARIATIONS);
	self.checkbox_state:=checkbox_initial_state;
	self.my_game:=aGame;
end;

function VariationDialog.OnInitDialog:boolean;
begin
	OnInitDialog:=inherited OnInitDialog;
	SetWindowText(Title);
	XWND(GetDlgItem(VD_SHOWDIALOGCHECK)).SendMessage(BM_SETCHECK,Q(checkbox_state,BST_CHECKED,BST_UNCHECKED));
	XWND(GetDlgItem(201+my_game^.Variation)).SendMessage(BM_SETCHECK,BST_CHECKED,0);
	//for i:=0 to my_game^.VariationCount do XListBox(GetDlgItem(4001)).AddString(StrPas(my_game^.VariationName(i)));
end;

function VariationDialog.OnEndDialog(aCommandId:UINT):boolean;
var
	i:ordinal;
begin
	checkbox_state:=XCheckBox(GetDlgItem(VD_SHOWDIALOGCHECK)).IsChecked;
	i:=0;
	while (i<(my_game^.VariationCount+1)) and (windows.SendMessage(GetDlgItem(201+i),BM_GETCHECK,0,0)=BST_UNCHECKED) do Inc(i);
	selection_index:=i;
	OnEndDialog:=inherited OnEndDialog(aCommandId);
end;

{$ifdef TEST}

type
	TestVariationDialog=object(VariationDialog)
		constructor Construct;
	end;

constructor TestVariationDialog.Construct;

begin
end;

procedure Test_VariationDialog_Title;
var
	dialog:TestVariationDialog;
	fake_game:testable_OSolGameBase;
begin
	dialog.Construct;
	fake_game.Construct(GID_STANDARD);
	dialog.my_game:=@fake_game;
	punit.Assert.EqualText('Variations of Solitaire', dialog.Title);
end;

procedure Test_VariationDialog_OnInitDialog;
var
	testee:VariationDialog;
	game:testable_OSolGameBase;
begin
	game.Construct(GID_STANDARD);
	testee.Construct(NULL_HANDLE,@game,TRUE);
	testee.Create(hinstance);
	testee.OnInitDialog;
	AssertAreEqual('Variations of Solitaire',testee.Title);
	testee.checkbox_state:=TRUE;
	testee.OnInitDialog;
	AssertIsTrue(XCheckBox(testee.GetDlgItem(VD_SHOWDIALOGCHECK)).IsChecked);
	testee.checkbox_state:=FALSE;
	testee.OnInitDialog;
	AssertIsFalse(XCheckBox(testee.GetDlgItem(VD_SHOWDIALOGCHECK)).IsChecked);
end;

procedure Test_VariationDialog_OnEndDialog;
var
	testee:VariationDialog;
	game:testable_OSolGameBase;
begin
	game.Construct(GID_STANDARD);
	testee.Construct(NULL_HANDLE,@game,TRUE);
	testee.Create(hinstance);
	testee.OnInitDialog;
	XWND(testee.GetDlgItem(VD_SHOWDIALOGCHECK)).SendMessage(BM_SETCHECK,BST_CHECKED);
	testee.OnEndDialog(123);
	AssertIsTrue(testee.checkbox_state);
	testee.OnInitDialog;
	XWND(testee.GetDlgItem(VD_SHOWDIALOGCHECK)).SendMessage(BM_SETCHECK,BST_UNCHECKED);
	testee.OnEndDialog(123);
	AssertIsFalse(testee.checkbox_state);
end;

{$endif TEST}

function MainApp.SelectGameVariation:variationIndex;
var
	dialog:VariationDialog;
begin
	dialog.Construct(MainFrameP(Frame)^.MyFrameWindow^.Handle,CurrentGame,ShowVariationDialog);
	if dialog.Modal=IDOK then begin
		SetBooleanData(REGKEY_ROOT,KEY_SHOWVARIATIONDIALOG,dialog.checkbox_state);
		SelectGameVariation:=dialog.selection_index
	end
	else SelectGameVariation:=CurrentGame^.Variation;
end;

begin
	{$ifdef TEST}
	Suite.Add(@Test_unit_initialization);
	Suite.Add(@Test_resources);
	Suite.Add(@Test_PersistenceKeys);
	Suite.Add(@Test_AddGameMenuItems);
	Suite.Add(@Test_DefaultSavedGameId);
	Suite.Add(@Test_NumDecksAsText);
	Suite.Add(@Test_AddGameMenuItem);
	Suite.Add(@Test_ComposeTitle_when_current_game_is_nil);
	Suite.Add(@Test_ComposeTitle_when_game_has_no_variations);
	Suite.Add(@Test_ComposeTitle_when_game_has_variations);
	Suite.Add(@Test_OnSelectGame);
	Suite.Add(@Test_GetGameVariationDefault);
	Suite.Add(@Test_VariationDialog_Title);
	Suite.Add(@Test_VariationDialog_OnInitDialog);
	Suite.Add(@Test_VariationDialog_OnEndDialog);
	Suite.Run('main');
	{$else}
	the_main_app.Init;
	the_main_app.Run;
	the_main_app.Done;
	{$endif TEST}
end.
