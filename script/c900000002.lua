--Trap Revenant - Shroud
--Normal Trap
--Custom card
Duel.LoadScript("utility_traprevenant.lua")
local s,id=GetID()
function s.initial_effect(c)
	TrapRevenant.RegisterSetTurnPermission(c)
	--You can activate this card the turn it was Set by discarding 1 card or by
	--banishing 1 Trap from your GY; send 1 Trap from your Deck to the GY, then
	--look at your opponent's hand, and if you do, you can Set 1 "Trap Revenant"
	--Trap from your hand, it can be activated this turn.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SET)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(TrapRevenant.MakeSetTurnCost(id))
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--You can banish this card from your GY; send 2 cards from the top of
	--either player's Deck to the GY.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.mltg)
	e2:SetOperation(s.mlop)
	c:RegisterEffect(e2)
end
function s.tgfilter(c)
	return c:IsTrap() and c:IsAbleToGrave()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	TrapRevenant.ResolveShroud(e,tp)
end
function s.mltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,2) or Duel.IsPlayerCanDiscardDeck(1-tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,PLAYER_ALL,2)
end
function s.mlop(e,tp,eg,ep,ev,re,r,rp)
	TrapRevenant.MillEitherDeck(tp,id,2)
end
