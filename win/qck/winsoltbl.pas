{ (C) 2009 Wesley Steiner }

{$MODE FPC}

{!$define CANFIELD}

unit winsoltbl;

interface

uses
	windows,
	cards,
	qcktbl,
	std,
	winqcktbl,
	xy;
	
{$I punit.inc}

const
	NGAMES={$ifdef CANFIELD} 8 {$else} 7 {$endif};
	WM_GAMELOST = WM_USER + 0;
	WM_GAMEWON = WM_USER + 1;
	WM_PLAYBLOCKED = WM_USER + 2;

type
	tScore=integer;
	eGameId=(
		{ the order must be the same as that in the "GameInfo" array }
		GID_STANDARD,
		GID_KLONDIKE,
		GID_PYRAMID,
		GID_GOLF,
		GID_GAPS,
		GID_SPIDER,
		GID_YUKON
{$ifdef CANFIELD}
		,GID_CANFIELD
{$endif}
(*
		GID_CALCULATION,
		GID_FOURSEASONS,
		GID_STHELENA,
		GID_MONTECARLO,
		GID_CARPET,
		GID_BEL_CASTLE,
		GID_FROG,
		GID_CHESSBOARD,
		GID_BUSYACES,
		GID_FORTYTHIEVES,
		GID_SLYFOX,
		GID_DEUCES,
		GID_SCORPION
*)	);

	SolGameP=^SolGame;

	SolTableViewP=^SolTableView;
	SolTableView=object(OTabletop) // OBSOLETE: do not expand this sub-class, ideally use OTabletop only
		procedure SelectGame(game_id:eGameId;variation:variationIndex);
	end;

	SolGameBaseP=^SolGameBase;
	SolGameBase=object(winqcktbl.Game)
		deck_prop:ODeckprop;
		Deck:PDeck;
		constructor Construct(game_id:eGameId;tabletop:SolTableViewP);
		destructor Destruct; virtual;
		function GameIsLost:boolean; virtual;
		function GameIsWon:boolean; virtual;
		function GetGameId:eGameId;
		function Handicap:tScore;
		function PackCount:word; test_virtual
		function PileCenterPoint(row,col:number):xypair;
		function PlayIsBlocked:boolean; virtual;
		function StartingScore:tScore;
		function Title:pchar; test_virtual
		function Score:TScore; virtual; { return the current score in the game }
		procedure OnDeal; virtual;
		procedure RecordStats; virtual; { complete a game }
		procedure Setup; virtual;
	test_private
		my_game_id:eGameId;
		nDecks:integer;
		procedure Initialize(game_id:eGameId);
	end;

	SolGame=object(SolGameBase)
		function OnPlayBlocked:LONG; virtual;
		procedure OnGameLost; virtual;
		procedure Deal;
		procedure Finish; virtual;
		procedure OnGameWon;
	end;

	OStockpileProp=object(OSquaredpileprop)
		nRedealsAllowed,DealsRemaining:integer; { # of redeals permitted; -1 = infinite }
		constructor Construct(game:SolGameBaseP; tabletop:SolTableViewP; n:integer; d:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		procedure topSelected; virtual;
		procedure Selected; virtual;
		procedure Redeal; virtual;
		procedure Help; virtual;
	end;

	TActionPile=object(OSquaredpileprop)
		constructor Construct(game:SolGameP; aTitle:PChar);
		function Accepts(aCard:TCard):boolean; virtual;
		function CanGrabCardAt(aIndex:integer):boolean; virtual;
	end;

	TStaticPile=object(OFannedPileProp)
		constructor Init(game:SolGameBaseP;aTitle:PChar;nMax:integer;FaceUp:boolean;X,Y,iDX,iDY:integer);
		procedure topSelected; virtual;
	end;

	DiscardPileProp=object(TStaticPile)
		constructor Init(game:SolGameBaseP;n:integer);
		procedure OnCardAdded virtual;
	end;

	{ A Tag Pile is a pile of cards of which only the top card can be tagged if it is face up }
	TTagPile=object(TActionPile)
		Tagged:boolean;
		constructor Init(game:SolGameP;tabletop:SolTableViewP;aTitle:PChar;nMax:integer;FaceUp:boolean;X,Y,iDX,iDY:integer);
		procedure topSelected; virtual;
		procedure OnCardAdded virtual;
	end;

	{ Foundation Build Mode }
	fbmType=(fbmNone,fbmInSuit,fbmAltColor);

	GenericFndtnPile_ptr=^GenericFndtnPile;
	GenericFndtnPile=object(TStaticPile)
		FoundNo:integer;
		iSeq:integer; { build sequence increments by this }
		BaseIsOpen:boolean; { true if base is open for user to choose by placing a card in it }
		BasePip:TPip;
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum,N:integer;X,Y:integer);
		function Accepts(aCard:TCard):boolean; virtual;
		function IsDblClkTarget:boolean; virtual;
		procedure SetBasePip(aPip:TPip);
	private
		BldUp:boolean;
		BldMode:fbmType;
		procedure Selected; virtual;
		procedure OnCardAdded; virtual;
		procedure Help; virtual;
	end;
	{ build up from aces to kings regardless of suit }
	PFoundUp=^TFoundUp;
	TFoundUp=object(GenericFndtnPile)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
	end;
	{ build down from kings to aces regardless of suit }
	PFoundDn=^TFoundDn;
	TFoundDn=object(GenericFndtnPile)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
	end;
	{ built up in suit from Aces to kings. }
	PFoundUpInSuit=^TFoundUpInSuit;
	TFoundUpInSuit=object(TFoundUp)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;
	{ built up in alternate colors from Aces to kings. }
	PFoundUpAlt=^TFoundUpAlt;
	TFoundUpAlt=object(TFoundUp)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
	end;
	{ built down in suit from Kings to Aces. }
	PFoundDnInSuit=^TFoundDnInSuit;
	TFoundDnInSuit=object(TFoundDn)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;
	{ built down in alternate color from Kings to Aces. }
	PFoundDnAlt=^TFoundDnAlt;
	TFoundDnAlt=object(TFoundDn)
		constructor Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
	end;
	{ for compatibility only }
	PFoundation=^TFoundation;
	TFoundation=object(TFoundUpInSuit)
	end;

	PGenericTableauPile=^GenericTableauPile;
	GenericTableauPile=object(OFannedPileProp)
		m_aroundTheCorner:boolean; { cards can be built A on K or K on A }
		constructor Construct(aGame:SolGameBaseP;a_pQuickview:PTabletop;No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
		procedure OnTopcardFlipped; virtual;
		procedure OnCardAdded; virtual;
		procedure TopSelected; virtual;
	end;

	PTableauUorD=^TTableauUorD;
	TTableauUorD=object(GenericTableauPile)
		constructor Init(a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;

	PTableauUDInSuit=^TTableauUDInSuit;
	TTableauUDInSuit=object(TTableauUorD)
		constructor Init(a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;

	TTableauDn=object(GenericTableauPile)
		constructor Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;

	PTableauSuit=^TTableauSuit;
	TTableauSuit=object(TTableauDn)
		constructor Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;

	PTableauAlt=^TTableauAlt;
	TTableauAlt=object(TTableauDn)
		constructor Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
		function Accepts(tc:TCard):boolean; virtual;
	end;

	OWastepileProp=object(OSquaredpileprop)
		constructor Construct;
		function Accepts(tc:TCard):boolean; virtual;
		procedure OnCardAdded; virtual;
	end;

function GetGameTitle(game_id:eGameid):pchar;

procedure EmptyTabletop;
procedure InsertTabletop(tabletop:SolTableViewP;Item:Pointer);
procedure UpdateScoreWindow(game:SolGameP);

implementation 

uses
	mmsystem,
	punit,
	strings,
	mathx,
	oapp,
	windowsx,
	owindows,
	sdkex,
	stdwin,
	winCardFactory,
	{$ifdef CANFIELD} canfield, {$endif}
	gaps, 
	golf, 
	klondike, 
	pyramid, 
	spider, 
	yukon,
	{$ifdef TEST} 
	golf_tests, 
	klondike_tests, 
	{$endif}
	quickWin;
	
const
	SL_DESCRIPTION=511;
	
	GameInfo:array[eGameId] of record
		{ the order must be the same as that in the "eGameId" enum }
		gDks:Byte; { how many decks }
		gScr,gHcp:TScore; { starting score and handicap }
		Title:PChar;
	end = 
	(
		(gDks:1;gScr:52;gHcp:0;Title:'Solitaire'),
		(gDks:1;gScr:52;gHcp:0;Title:'Klondike'),
		(gDks:1;gScr:52;gHcp:0;Title:'Pyramid'),
		(gDks:1;gScr:52;gHcp:1;Title:'Golf'),
		(gDks:1;gScr:48;gHcp:0;Title:'Gaps'),
		(gDks:2;gScr:104;gHcp:0;Title:'Spider'),
		(gDks:1;gScr:52;gHcp:0;Title:'Yukon')
		{$ifdef CANFIELD} 
		,(gDks:1;gScr:52;gHcp:1;Title:'Canfield')
		{$endif}
		{$ifdef OBSOLETE},          
		(gDks:1;gScr:   52;gHcp: 4;		{ Calculation }
		(gDks:1;gScr:   52;gHcp: 0;		{ Four Seasons }
		(gDks:2;gScr: 8*13;gHcp: 8;		{ St. Helena }
		(gDks:1;gScr:   52;gHcp: 0;		{ Monte Carlo }
		(gDks:1;gScr:   52;gHcp: 4;		{ Carpet }
		(gDks:1;gScr:   52;gHcp: 4;		{ Beleaguered Castle }
		(gDks:2;gScr:  104;gHcp: 1;		{ Frog }
		(gDks:1;gScr:   52;gHcp: 0;		{ Chessboard }
		(gDks:2;gScr:  104;gHcp: 0;		{ Busy Aces }
		(gDks:2;gScr:  104;gHcp: 0;		{ Forty Thieves }
		(gDks:2;gScr:  104;gHcp: 8;		{ Sly Fox }
		(gDks:2;gScr:  104;gHcp: 8;		{ Deuces }
		(gDks:1;gScr:   52;gHcp: 0;		{ Scorpion }
		{$endif}
		);

constructor OStockpileProp.Construct(game:SolGameBaseP;tabletop:SolTableViewP;n:integer;d:integer);
begin
	inherited Construct(n);
	m_tag:= StrNew('Hand');
	HasTarget:=True;
	nRedealsAllowed:=d;
	DealsRemaining:=d;
	TargetState:=(DealsRemaining<>0);
	SetDesc('This pile contains the cards remaining after the deal. ');
	AppendDesc('The top card is available for play. ');
end;

function OStockpileProp.Accepts(aCard:TCard):boolean;
begin
	Accepts:=false;
end;

procedure OStockpileProp.Redeal;
begin
	Dec(DealsRemaining);
	TargetState:= (DealsRemaining > 0);
	Refresh;
end;

procedure OStockpileProp.topSelected;
begin
	if topFaceDown then
		FlipTopcard
	else
		inherited topSelected;
end;

procedure OStockpileProp.Selected;
begin
	if
		(DealsRemaining<>0)
		{or (
			(DealsRemaining>0)
			and
			(MessageBox(AppWnd,'Are you sure?','Deal Again',mb_YesNo or mb_IconQuestion)=idYes)
		)}
	then
		Redeal
	else
		inherited Selected;
end;

procedure OStockpileProp.Help;
var
	aDesc:array[0..SL_DESCRIPTION] of Char;
	Args:array[0..0] of longint;
begin
	StrCopy(aDesc, Desc);
	if nRedealsAllowed=-1 then
		AppendDesc('No limit on the number of redeals. ')
	else begin
		if DealsRemaining>0 then begin
			args[0]:=DealsRemaining;
			wvsprintf(StrEnd(Desc), '%d redeal', PChar(Args[0]));
			if DealsRemaining=1 then
				AppendDesc(' is ')
			else
				AppendDesc('s are ');
		end
		else
			AppendDesc('No redeals are ');
		AppendDesc('remaining. ');
	end;
	inherited Help;
	SetDesc(aDesc);
end;

procedure TStaticPile.topSelected;
begin
	Help;
end;

function TActionPile.CanGrabCardAt(aIndex:integer):boolean;
begin
	CanGrabCardAt:=FALSE;
end;

function TActionPile.Accepts(aCard:TCard):boolean;
begin
	Accepts:=FALSE;
end;

constructor TActionPile.Construct(game:SolGameP; aTitle:PChar);
begin
	inherited Construct(104);
	m_tag:= StrNew(aTitle);
	AppendDesc('The top card of this pile can be selected for play. ');
	Enable;
end;

constructor TTagPile.Init(game:SolGameP;tabletop:SolTableViewP;aTitle:PChar;nMax:integer;FaceUp:boolean;X,Y,iDX,iDY:integer);
begin
	inherited Construct(game, aTitle);
	SetDesc('The top card in this pile can be tagged. ');
	Tagged:=False;
end;

procedure TTagPile.OnCardAdded;
begin
	inherited OnCardAdded;
	Tagged:=False;
end;

procedure TTagPile.topSelected;
var
	aDC:hDC;
	r:TRect;
begin
	if IsEmpty then
		inherited topSelected
	else if topFaceDown then
		FlipTopcard
	else begin
		Toggle(Tagged);
		aDC:=GetDC(MyTabletop^.handle);
		with r do begin
			left:=topX+1;
			top:=topY+1;
			right:=left+CardImageWd-2;
			bottom:=top+CardImageHt-2;
		end;
		InvertRect(aDC,r);
		ReleaseDC(MyTabletop^.handle,aDC);
	end;
end;

constructor DiscardPileProp.Init(game:SolGameBaseP;n:integer);
begin
	inherited Init(game, 'Discard', n, TRUE, MIN_EDGE_MARGIN, 0,PipHSpace,0);
	Disable;
	HasTarget:=TRUE;
	m_outlined:=TRUE;
	TargetState:=FALSE;
	AppendDesc('These cards are permanently removed from play. ');
end;

procedure DiscardPileProp.OnCardAdded;
begin //writeln('DiscardPileProp.OnCardAdded');
	inherited OnCardAdded;
	if topFaceDown then FlipTopcard;
end;

constructor TTableauSuit.Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Init(aGame,a_pQuickview, No,N,FaceUp,x,y,dx,dy);
	AppendDesc('in rank and suit. ')
end;

function TTableauSuit.Accepts(tc:TCard):boolean;
begin
	Accepts:=(inherited Accepts(tc)) and (CardSuit(tc)=CardSuit(Topcard));
end;

constructor TTableauAlt.Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Init(aGame,a_pQuickview, No,N,FaceUp,x,y,dx,dy);
	AppendDesc('in rank and in alternating colors. ')
end;

function TTableauAlt.Accepts(tc:TCard):boolean;
begin
	Accepts:=(inherited Accepts(tc)) and (SuitColor(tc)<>SuitColor(Topcard));
end;

constructor TTableauDn.Init(aGame:SolGameBaseP;a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Construct(aGame,a_pQuickview,No,N,FaceUp,x,y,dx,dy);
	AppendDesc('Tableaus can be built down ')
end;

constructor TTableauUorD.Init(a_pQuickView:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Construct(nil, a_pQuickView, No,N,FaceUp,x,y,dx,dy);
	AppendDesc('Tableaus can be built up or down ')
end;

constructor TTableauUDInSuit.Init(a_pQuickview:PTabletop; No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Init(a_pQuickview, No,N,FaceUp,x,y,dx,dy);
	AppendDesc('in suit. ')
end;

function TTableauUorD.Accepts(tc:TCard):boolean;
	begin
		Accepts:=
				(inherited Accepts(tc))
				and
				(not IsEmpty)
				and
				topFaceUp
				and (
					(CardPip(tc)=Pred(CardPip(Topcard)))
					or
					(CardPip(tc)=Succ(CardPip(Topcard)))
				)
				;
	end;

function TTableauUDInSuit.Accepts(tc:TCard):boolean;

begin
	Accepts:=(inherited Accepts(tc)) and (CardSuit(tc) = CardSuit(Topcard));
end;

function TTableauDn.Accepts(tc:TCard):boolean;

begin
	Accepts:=(inherited Accepts(tc)) and
		(Size>0) and
		topFaceUp and
		(CardPip(Topcard)<>TACE) and
		(
		(CardPip(tc) = Pred(CardPip(Topcard))) or
		(m_aroundTheCorner and (CardPip(tc)=TKING) and (CardPip(Topcard)=TACE))
		);
end;

constructor GenericTableauPile.Construct(aGame:SolGameBaseP; a_pQuickview:PTabletop;
		No,N:integer;FaceUp:boolean;X,Y,DX,DY:integer);
begin
	inherited Construct;
	Ordinal:=No;
	m_outlined:=TRUE;
	m_aroundTheCorner:=FALSE;
	m_tag:=StrNew('Tableau');
	AppendDesc('The top card is always available for play to the layout.');
	Enable;
end;

function GenericTableauPile.Accepts(tc:TCard):boolean;

begin
	Accepts:=(inherited Accepts(tc));
end;

procedure GenericTableauPile.OnTopcardFlipped;
begin
	IsUnit[size]:= topFaceUp;
end;

procedure GenericTableauPile.OnCardAdded;
begin
	inherited OnCardAdded;
	if not ISEmpty then IsUnit[size]:= False;
end;

procedure GenericTableauPile.TopSelected;
begin
	if not IsEmpty and TopFaceDown then
		FlipTopcard
	else
		inherited TopSelected;
end;

constructor OWastepileProp.Construct;
begin
	inherited Construct;
	m_outlined:=TRUE;
	m_tag:=strnew('Waste');
	AppendDesc('The top card is always available for play.');
end;

function OWastepileProp.Accepts(tc:TCard):boolean;
begin
	Accepts:=(grabbed_from <> nil) and (StriComp(GenPileOfCardsP(grabbed_from)^.m_tag, 'Hand') = 0);
end;

procedure OWastepileProp.OnCardAdded;
begin
	inherited OnCardAdded;
	if topFaceDown then FlipTopcard;
end;

constructor TStaticPile.Init(game:SolGameBaseP;aTitle:PChar;nMax:integer;FaceUp:boolean;X,Y,iDX,iDY:integer);
begin
	inherited Construct;
	if (aTitle <> nil) then m_tag:= StrNew(aTitle);
	SetDesc('This is a static pile. ');
	AppendDesc('Cards are placed into or drawn from this pile automatically. ');
end;

constructor GenericFndtnPile.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum,N:integer;X,Y:integer);
begin
	FoundNo:=aNum;
	inherited Init(game, 'Foundation',N,True,x,y,0,0);
	Ordinal:=aNum;
	m_outlined:= TRUE;
	BaseIsOpen:=False;
	BasePip:= TACE;
	BldUp:=True;
	BldMode:=fbmNone;
	iSeq:=1;
	SetDesc(nil);
end;

constructor TFoundUp.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,13,x,y);
end;

constructor TFoundDn.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,13,x,y);
	BasePip:= TKING;
	BldUp:= False;
end;

constructor TFoundUpInSuit.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,x,y);
	BldMode:=fbmInSuit;
	{SetDesc('Foundation is to be built up ');}
end;

constructor TFoundDnInSuit.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,x,y);
	BldMode:=fbmInSuit;
	{SetDesc('Foundation is to be built down fromm King to Ace. ');}
end;

constructor TFoundDnAlt.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,x,y);
	BldMode:=fbmAltColor;
end;

constructor TFoundUpAlt.Init(game:SolGameBaseP;tabletop:SolTableViewP;aNum:integer;X,Y:integer);
begin
	inherited Init(game,tabletop,aNum,x,y);
	BldMode:=fbmAltColor;
end;

procedure GenericFndtnPile.Selected;
var
	pstr:array[0..80] of Char;
begin
	{StrCopy(pStr,'You cannot pick up cards from a foundation.');
	MessageBox(AppWnd,pstr,'Sorry',mb_IconExclamation or mb_OK);}
end;

function GenericFndtnPile.Accepts(aCard:TCard):boolean;
begin
	Accepts:=
		(not UnitDragging)
		and (
			(inherited Accepts(aCard))
			and (
				(IsEmpty and (CardPip(aCard)=BasePip))
				or (
					(not IsEmpty)
					and (
						(BldUp and (CardPip(aCard)=nPipCircSucc(iSeq,CardPip(Topcard))))
						or
						((not BldUp) and (CardPip(aCard)=Pred(CardPip(Topcard))))
						)
					and (
						(BldMode=fbmNone)
						or
						((BldMode=fbmInSuit) and (CardSuit(aCard)=CardSuit(Topcard)))
						or
						((BldMode=fbmAltColor) and (SuitColor(aCard)<>SuitColor(Topcard)))
						)
					)
				)
			)
		;
end;

procedure GenericFndtnPile.OnCardAdded;
begin //writeln('GenericFndtnPile.OnCardAdded');
	inherited OnCardAdded;
	BaseIsOpen:=False;
end;

procedure GenericFndtnPile.Help;
var
	OrgDesc:array[0..SL_DESCRIPTION] of char;
begin
	OrgDesc[0]:= #0;
	if Desc <> nil then StrCopy(OrgDesc, Desc);
	if BaseIsOpen then begin
		SetDesc('The base card for this foundation is still open. ');
		AppendDesc('The first card that you play on any foundation pile ');
		AppendDesc('will determine the base card for all the foundations. ');
	end
	else begin
		SetDesc('This pile is to be built ');
		if BldUp then
			AppendDesc('up ')
		else
			AppendDesc('down ');
		if iSeq>1 then begin
			AppendDesc('(by ');
			i2s(iSeq,StrEnd(Desc));
			AppendDesc(') ');
		end;
		case BldMode of
			fbmInSuit:
				AppendDesc('in suit ');
			fbmAltColor:
				AppendDesc('in alternating color ');
		end;
		AppendDesc('from ');
		AppendDesc(PipText[BasePip]);
		AppendDesc(' ');
		if not (BasePip in [TACE, TKING]) then
			AppendDesc('(around-the-corner) ');
		AppendDesc('to ');
		if BldUp 
			then AppendDesc(PipText[nPipCircSucc(Word(iSeq*12),BasePip)])
			else AppendDesc(PipText[nPipCircPred(Word(iSeq*12),BasePip)]);
		if BldMode=fbmNone then AppendDesc(' regardless of suit');
		AppendDesc('.');
	end;
	AppendDesc(OrgDesc);
	inherited Help;
	SetDesc(OrgDesc); { restore original }
end;

procedure GenericFndtnPile.SetBasePip(aPip:TPip);
begin
	BasePip:=aPip;
	BaseIsOpen:=False;
end;

function GenericFndtnPile.IsDblClkTarget:boolean;
begin
	IsDblClkTarget:= true;
end;

procedure EmptyTabletop;
var
	i:integer;
begin //writeln('EmptyTabletop');
	with GetTabletopView^.hotList do for i:=Count-1 downto 1 do if PHotSpot(At(i))^.ObjectClass=HCLASS.GENPILEOFCARDS then with OCardpileProp_ptr(At(i))^ do if not IsEmpty then Discard;
end;

procedure InsertTabletop(tabletop:SolTableViewP;Item:Pointer);
begin
	tabletop^.AddProp(item);
	PHotspot(item)^.enable;
end;

procedure SolGameBase.Initialize(game_id:eGameId);
begin //writeln('SolGameBase.Initialize(',Ord(game_id),')');
	my_game_id:=game_id;
	SetVariation(0);
	nDecks:=GameInfo[my_game_id].gDks;
	Deck:=nil;
end;

constructor SolGameBase.Construct(game_id:eGameId;tabletop:SolTableViewP);
begin
	inherited Construct(Ord(game_id),tabletop);
	Initialize(game_id);
end;

destructor SolGameBase.Destruct;
begin
	if Deck<>nil then Dispose(Deck,Destruct);
end;

function SolGameBase.PackCount:word;
begin
	PackCount:=GameInfo[my_game_id].gDks;
end;

function SolGameBase.StartingScore:TScore;
begin
	StartingScore:=GameInfo[my_game_id].gscr;
end;

function SolGameBase.Handicap:TScore;
begin
	Handicap:=GameInfo[my_game_id].ghcp;
end;

function SolGameBase.Title:pchar;
begin
	Title:=GetGameTitle(my_game_id);
end;

function SolGameBase.GetGameId:eGameId;
begin
	GetGameId:=my_game_id;
end;

function GetGameTitle(game_id:eGameid):pchar;
begin 
	GetGameTitle:=GameInfo[game_id].Title; 
end;

procedure SolGameBase.Setup;
begin //writeln('SolGameBase.Setup');
	if Deck<>nil then Dispose(Deck,Destruct);
	Deck:=new(PDeck, Construct(PackCount * 52));
	deck^.addPacks(FALSE);
	Deck^.shuffle;
	deck_prop.Construct(PackCount);
	Dispose(deck_prop.ThePile,Destruct);deck_prop.ThePile:=deck; // hack to reassign the underlying pile
	MyTabletop^.AddProp(@deck_prop, BOTTOM_CENTER);
	deck_prop.Show;
end;

function SolGameBase.PileCenterPoint(row,col:number):xypair;
begin
	PileCenterPoint:=CardAnchorToCenter(MakeXYPair(
		Center(TotalWidth,0,MyTabletop^.Width)+SpanOffset(col-1,CurrentWidth,PileSpacing), 
		Center(TotalHeight,0,MyTabletop^.Height)+SpanOffset(row-1,CurrentHeight,PileSpacing)));
end;

procedure SolGameBase.OnDeal;
begin
end;

function SolGameBase.GameIsWon:boolean;
begin //writeln('SolGame.GameIsWon');
	GameIsWon:=(Score=0);
end;

function SolGameBase.Score:Tscore;
begin
	Score:=StartingScore;
end;

function SolGameBase.GameIsLost:boolean;
begin
	GameIsLost:=PlayIsBlocked;
end;

procedure SolGameBase.RecordStats;
{ Record this game in the Stats table }
begin
	{$ifdef STAT_TABLE}
	with GameStats[the_main_app.gID] do begin
		Inc(GmsPlayed);
		GmsCumScr:=GmsCumScr+Score;
	end;
	{$endif STAT_TABLE}
end;

procedure SolGame.Deal;
var
	saved:boolean;
begin
	saved:=X_SoundStatus;
	X_SoundStatus:=FALSE;
	OnDeal;
	X_SoundStatus:=saved;
end;

procedure SolGame.Finish;
	procedure ClearIt(Pile:Pointer);
	begin
		if PHotspot(Pile)^.ObjectClass=HCLASS.GENPILEOFCARDS then with GenPileOfCardsP(Pile)^ do begin
			Discard;
			Hide;
		end;
	end;
var
	i:integer;
begin
	with MyTabletop^.hotList do for i:=Count downto 1 do ClearIt(At(i-1));
	MyTabletop^.hotList.DeleteAll;
end;

function SolGame.OnPlayBlocked:LONG;
begin
	OnPlayBlocked:=0;
	MessageBox(AppWnd, 'Play is blocked.', 'Blocked!', MB_OK or MB_ICONSTOP);
	PostMessage(AppWnd, WM_COMMAND, CM_FILENEW, 0);
end;

procedure SolGame.OnGameWon;
var
	hWave:THandle;
	pWave:Pointer;
begin
	RecordStats;
	{$ifdef STAT_TABLE}
	with GameStats[the_main_app.gID] do Inc(GmsWon);
	{$endif STAT_TABLE}
	if x_SoundStatus then begin
		hWave:=FindResource(hInstance,'GOLF_CLAP','WAVE');
		hWave:=LoadResource(hInstance,hWave);
		pWave:=LockResource(hWave);
		SndPlaySound(pWave,Snd_NoDefault or Snd_Memory);
		FreeResource(hWave);
	end;
	MessageBox(AppWnd,'You won this game!','Congratulations!',MB_OK);
	PostMessage(AppWnd,wm_Command,CM_FILENEW,0);
end;

procedure SolGame.OnGameLost;
begin
	RecordStats;
	MessageBox(AppWnd, 'Play is blocked.', 'Game Over', MB_OK or MB_ICONSTOP);
	PostMessage(AppWnd, WM_COMMAND, CM_FILENEW, 0);
end;

function CreateSolGame(tabletop:SolTableViewP; game_id:eGameId; variation:variationIndex):SolGameP;
begin
	case game_id of
		GID_STANDARD:CreateSolGame:=New(OStandardgame_ptr, Construct(variation, tabletop));
		GID_PYRAMID:CreateSolGame:=New(OPyramidgame_ptr, Construct(tabletop));
		GID_KLONDIKE:CreateSolGame:=New(OKlondikegame_ptr, Construct(tabletop));
		GID_GOLF:CreateSolGame:=New(OGolfgame_ptr, Construct(tabletop));
		GID_GAPS:CreateSolGame:=New(OGapsgame_ptr, Construct(tabletop));
		GID_SPIDER:CreateSolGame:=New(OSpidergame_ptr, Construct(tabletop));
		GID_YUKON:CreateSolGame:=New(OYukongame_ptr, Construct(tabletop));
		{$ifdef CANFIELD} 
		GID_CANFIELD:CreateSolGame:=New(OCanfieldgame_ptr, Construct(tabletop));
		{$endif}
	end;
end;

procedure SolTableView.SelectGame(game_id:eGameId; variation:variationIndex);
begin
	if current_game<>NIL then begin
		SolGameP(current_game)^.Finish;
		Dispose(SolGameP(current_game),Destruct);
		current_game:=NIL;
	end;
	current_game:=CreateSolGame(@self, game_id, variation);
	OnSize(SIZE_RESTORED,Integer(ClientAreaWidth),Integer(ClientAreaHeight));
	with SolGameP(current_game)^ do begin
		Setup;
		Deal;
	end;
end;

function SolGameBase.PlayIsBlocked:boolean;
begin
	PlayIsBlocked:=FALSE;
end;

procedure UpdateScoreWindow(game:SolGameP);
begin //writeln('winsoltbl.UpdateScoreWindow');
	with game^ do begin
		if GameIsWon 
			then PostMessage(AppWnd, WM_GAMEWON, 0, 0)
			else if GameIsLost 
				then PostMessage(AppWnd, WM_GAMELOST, 0, 0) 
				else if PlayIsBlocked then PostMessage(AppWnd, WM_PLAYBLOCKED, 0, 0);
	end;
end;

end.
