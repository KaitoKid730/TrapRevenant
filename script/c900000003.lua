--Trap Revenant - Unbound
--Normal Trap
--Custom card
Duel.LoadScript("utility_traprevenant.lua")
local s,id=GetID()
function s.initial_effect(c)
	TrapRevenant.RegisterSetTurnPermission(c)
	--You can activate this card the turn it was Set by discarding 1 card or by
	--banishing 1 Trap from your GY; target 1 card on the field; return it to
	--the hand, then, if it was a monster, inflict damage to your opponent
	--equal to its original ATK or DEF (whichever is higher). You cannot
	--activate monster effects for the rest of this turn after this card resolves.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(TrapRevenant.MakeSetTurnCost(id))
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--You can banish this card from your GY; send 1 card from the top of
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
function s.filter(c)
	return c:IsOnField() and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		local was_monster=tc:IsMonster()
		local atk,def
		if was_monster then atk=tc:GetTextAttack() def=tc:GetTextDefense() end
		if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 then
			Duel.ConfirmCards(1-tp,tc)
			if was_monster then
				local dam=math.max(atk,def)
				if dam<0 then dam=0 end
				Duel.BreakEffect()
				Duel.Damage(1-tp,dam,REASON_EFFECT)
			end
		end
	end
	TrapRevenant.RegisterNoMonsterEffects(e,tp)
end
function s.mltg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1) or Duel.IsPlayerCanDiscardDeck(1-tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,PLAYER_ALL,1)
end
function s.mlop(e,tp,eg,ep,ev,re,r,rp)
	TrapRevenant.MillEitherDeck(tp,id,1)
end
