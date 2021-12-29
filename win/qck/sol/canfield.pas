unit canfield;

interface

uses
	std,
	cards,
	winqcktbl,
	winsoltbl,
	xy;

type
(*
	PCanTab=^TCanTab;
	TCanTab=object(TTableauAlt)
		constructor Init(aNum,X,Y:integer);
		procedure OnCardAdded; virtual;
		function Accepts(aCard:TCard):boolean; virtual;
		procedure topRemoved; virtual;
		procedure UnitRemoved; virtual;
		{procedure topSelected; virtual;}
	end;
	PCanFound=^TCanFound;
	TCanFound=object(TFoundUpInSuit)
		constructor Init(aNum,X,Y:integer);
		{procedure OnCardAdded; virtual;}
		{function Accepts(aCard:TCard):boolean; virtual;}
	end;
	PCanHand=^TCanHand;
	TCanHand=object(OStockpileProp)
		constructor Init(X,Y:integer);
		procedure topSelected; virtual;
		procedure Redeal; virtual;
	end;
	PCanStock=^TCanStock;
	TCanStock=object(OSolPileProp)
		{procedure topRemoved; virtual;}
	end;
	PCanWaste=^TCanWaste;
	TCanWaste=object(OWastepileProp)
		procedure topGet; virtual;
		function getCardX(p_index:integer):integer; virtual;
		procedure makeSpanRect; virtual;
	end;
*)
	OCanfieldgame_ptr=^CanfieldGame;
	CanfieldGame=object(SolGame)
//		Foundations:array[1..n_Founds] of PCanFound;
//		Tableaus:array[1..n_Tabs] of PCanTab;
//		HandPile:PCanHand;
//		Stock:PCanStock;
//		Waste:PCanWaste;
		constructor Construct(tabletop:SolTableViewP);
		function PileColumns:word; virtual;
		function PileRows:word; virtual;
		procedure Setup; virtual;
		procedure OnDeal; virtual;
//		function Score:TScore; virtual;
	private
		stock_prop:PHotspot;
	end;

implementation

uses
	Strings;

var
	TheGame:OCanfieldgame_ptr;
	TabRowEx,TabDY:integer;
	Foo:boolean;

constructor CanfieldGame.Construct(tabletop:SolTableViewP);
begin
	inherited Construct(GID_CANFIELD,tabletop);
	thegame:=@Self;
end;

(*
constructor CanfieldGame.Init;

	var
		i:integer;

	begin
		inherited Construct(GID_Canfield);
		foo:= FALSE;
		TheGame:=@Self;
		with x_engine do begin
			TabDY:=PipVSpace-3;
			TabRowEx:=TabDY*12+CardIMageHt;
			{ foundations }
			for i:=1 to n_Founds do begin
				Foundations[i]:=New(PCanFound,Init(i,
					Centered(ColEx(6),0,AppMaxX)+(i+1)*ColDX,
					Centered(RowEx(1)+TabRowEx,0,AppMaxY)
					));
				x_aSolApp.Tabletop^.Insert(Foundations[i]);
			end;
			{ tableaus }
			for i:=1 to n_Tabs do begin
				Tableaus[i]:=New(PCanTab,Init(i,
					Foundations[i]^.Anchor.X,
					Foundations[i]^.Anchor.Y+RowDY
					));
				x_aSolApp.Tabletop^.Insert(Tableaus[i]);
			end;
			{ stock pile }
			Stock:=New(PCanStock, Construct(thegame, ViewP(TabletopView), new(PPileOfCards, Construct(13)), 0,
				Centered(CardImageWd+12*3,0,Tableaus[1]^.Anchor.X),
				Centered(CardImageHt+12*3,Foundations[1]^.Anchor.Y,Tableaus[1]^.Anchor.Y+CardImageHt),
				3,3
				));
			with Stock^ do begin
				m_outlined:= False;
				m_tag:= StrNew('Stock');
			end;
			x_aSolApp.Tabletop^.Insert(Stock);

			{ hand pile }

			HandPile:=New(PCanHand,Init(
				Centered(CIW * 3, 0, Tableaus[1]^.Anchor.X),
				Tableaus[1]^.Anchor.Y+RowDY
				));
			x_aSolApp.Tabletop^.Insert(HandPile);

			{ waste pile }
			Waste:=New(PCanWaste,Init(@self, 52-13-1-4,
				HandPile^.Anchor.X+ColDX,
				HandPile^.Anchor.Y,
				PipHSpace div 2,0
				));
			x_aSolApp.Tabletop^.Insert(Waste);
			Draw;
		end;
	end;

constructor TCanHand.Init;

	begin
		inherited Init(thegame, 52, x, y, -1);
		m_outlined:= TRUE;
		HasTarget:=True;
		TargetState:=True;
		AppendDesc('When selected cards are dealt in groups of three to the Waste pile. ');
	end;

procedure CanfieldGame.Setup;

	var
		i:integer;

	begin
		inherited Setup;
		with Stock^ do for i:=1 to 13 do begin
			topAdd(DeckPulltopCard(Deck,1));
			FlipTopcard;
		end;
		DeckToPile(NumDecks, Deck, HandPile);
		HandPile^.Refresh;
		Stock^.Refresh;
	end;

procedure CanfieldGame.Start;

	var
		i:integer;

	begin
		with HandPile^ do begin
			TopcardTo(Foundations[1]);
			with Foundations[1]^ do begin
				topFlip;
				BasePip:=CardPip(Topcard);
			end;
			for i:=2 to 4 do Foundations[i]^.BasePip:=Foundations[1]^.BasePip;
			for i:=1 to 4 do begin
				TopcardTo(Tableaus[i]);
				Tableaus[i]^.topFlip;
			end;
		end;
		inherited Start;
	end;

constructor TCanTab.Init;

	begin
		inherited Init(ViewP(TabletopView), aNum,13,True,X,Y,0,TabDY);
		m_aroundTheCorner:= TRUE;
		{AppendDesc('. ');}
	end;

constructor TCanFound.Init;

	begin
		inherited Init(aNum,X,Y);
		AppendDesc('This foundation is to be built up from ');
	end;

function CanfieldGame.Score;

	var
		s:TScore;
		i:integer;

	begin
		s:=0;
		for i:=1 to n_Founds do with Foundations[i]^ do Inc(s, size);
		Score:=(inherited Score)-s;
	end;

procedure TCanHand.Redeal;

	var
		i:integer;

	begin
		with TheGame^ do begin
			for i:=Waste^.size downto 1 do topAdd(Waste^.get(i));
			Waste^.Empty;
			flip;
		end;
		Refresh;
	end;

procedure TCanTab.topRemoved;

	begin
		inherited topRemoved;
		with TheGame^ do if IsEmpty and (not Stock^.IsEmpty) then Stock^.TopcardTo(@Self);
			{if not IsEmpty then topFlip;}
	end;

{procedure TCanStock.topRemoved;

	begin
		inherited topRemoved;
		if not IsEmpty and topFaceDown then topFlip;
	end;}

procedure TCanTab.UnitRemoved;

	begin
		inherited UnitRemoved;
		with TheGame^ do if IsEmpty and (not Stock^.IsEmpty) then with Stock^ do begin
			TopcardTo(@Self);
			{if not IsEmpty then topFlip;}
		end;
	end;

procedure TCanTab.OnCardAdded;

	begin
		inherited OnCardAdded;
		topSetUnit(size = 1);
	end;

{procedure TCanFound.OnCardAdded;

	begin
		inherited OnCardAdded;
		FillTabs;
		with TheGame^.Stock^ do if (not IsEmpty) and topFaceDown then topFlip;
	end;}

function TCanTab.Accepts;

	begin
		Accepts:=
			(inherited Accepts(aCard))
			or
			(IsEmpty and (StriComp(PSolPileProp(grabbed_from)^.m_tag, 'Tableau')<>0))
			;
	end;

{function tcanfound.accepts;

	begin
		accepts:=true;
	end;}

var
	jFoo:integer;

procedure TCanWaste.topGet;

	begin
		if (Foo) then begin
			if jFoo=1 then
				SetCardDx(Anchor.X-topX)
			else
				SetCardDx(x_engine.PipHSpace);
		end
		else if (size mod 3)=0 then
			SetCardDx(Anchor.X-topX)
		else
			SetCardDx(x_engine.PipHSpace);
		inherited topGet;
	end;

procedure TCanHand.topSelected;

	begin
		with TheGame^ do begin
			Foo:=True;
			jFoo:=1;
			while (size > 0) and (jFoo < 4) do begin
				TopcardTo(Waste);
				Inc(jFoo);
			end;
		end;
	end;

function TCanWaste.getCardX(p_index:integer):integer;

	begin
		getCardX:= ((p_index - 1) div 3) * (optXSpace * 1 div 2);
	end;

procedure TCanWaste.makeSpanRect;

	begin
		inherited MakeSpanRect;
		span.right:= span.left + optXSpace * 2 + CIW;
	end;
*)

procedure CanfieldGame.Setup;
begin
	inherited Setup;
end;

procedure CanfieldGame.OnDeal;
var
	i:integer;
begin
	inherited OnDeal;
	for i:=1 to 13 do begin
		deck_prop.FlipTopcard;
		deck_prop.DealTo(PileCenterPoint(1,6));
	end;
	stock_prop:=deck_prop.DealTo(PileCenterPoint(1,2), TRUE);
//	stock_prop^.OnTapped:=@StockTappedHandler;
	for i:=1 to 4 do deck_prop.DealTo(PileCenterPoint(2,i+1), TRUE);
	while (deck_prop.Size>0) do deck_prop.DealTo(PileCenterPoint(1,1));
end;

function CanfieldGame.PileRows:word;
begin
	PileRows:=4;
end;

function CanfieldGame.PileColumns:word;
begin
	PileColumns:=6;
end;

end.
