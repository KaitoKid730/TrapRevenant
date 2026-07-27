--Trap Revenant - Absolution
--Normal Trap
--Custom card
Duel.LoadScript("utility_traprevenant.lua")
local s,id=GetID()
function s.initial_effect(c)
	TrapRevenant.RegisterSetTurnPermission(c)
	--You can activate this card the turn it was Set by discarding 1 card or by
	--banishing 1 Trap from your GY. If you do, until the end of this turn, any
	--damage you would take is inflicted to your opponent instead.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(TrapRevenant.MakeSetTurnCost(id))
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--You can banish this card from your GY; for the rest of this turn, you
	--take no damage, then send the top 2 cards of either player's Deck to the GY.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DECKDES)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.noDamageTarget)
	e2:SetOperation(s.noDamageOp)
	c:RegisterEffect(e2)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	TrapRevenant.ResolveAbsolution(e,tp)
end
function s.noDamageTarget(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,PLAYER_ALL,2)
end
function s.noDamageOp(e,tp,eg,ep,ev,re,r,rp)
	TrapRevenant.RegisterNoDamage(e,tp)
	TrapRevenant.MillEitherDeck(tp,id,2)
end
