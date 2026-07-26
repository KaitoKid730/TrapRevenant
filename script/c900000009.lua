--Trap Revenant - Echo
--Normal Trap
--Custom card
--
--Design note: the original text does not specify where the targeted
--"Trap Revenant" Trap must be. This script targets one in your GY (the
--natural resource zone for this archetype's recursion effects). When
--Echo resolves, it directly performs that card's Set-turn activation
--effect (its cost is NOT re-paid; Echo's own cost already covers it).
Duel.LoadScript("utility_traprevenant.lua")
local s,id=GetID()
function s.initial_effect(c)
	TrapRevenant.RegisterSetTurnPermission(c)
	--You can activate this card the turn it was Set by discarding 1 card or by
	--banishing 1 Trap from your GY; target 1 "Trap Revenant" Trap in your GY;
	--this effect becomes that card's activation effect.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(TrapRevenant.MakeSetTurnCost(id))
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--You can banish this card from your GY; look at your opponent's hand,
	--then choose 1 monster in it, if any, and your opponent reveals it.
	--Inflict damage to your opponent equal to that monster's original ATK
	--or DEF (whichever is higher).
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)
end
function s.tgfilter(c)
	return TrapRevenant.IsTrapRevenant(c) and not c:IsCode(TrapRevenant.ECHO_ID)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and s.tgfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE,0,1,1,nil)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	TrapRevenant.Dispatch(tc:GetCode(),e,tp)
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local hg=Duel.GetFieldGroup(1-tp,0,LOCATION_HAND)
	Duel.ConfirmCards(tp,hg)
	local mg=hg:Filter(Card.IsMonster,nil)
	if #mg>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local tc=mg:Select(tp,1,1,nil):GetFirst()
		if tc then
			Duel.ConfirmCards(1-tp,tc)
			local atk=tc:GetTextAttack()
			local def=tc:GetTextDefense()
			local dam=math.max(atk,def)
			if dam<0 then dam=0 end
			Duel.BreakEffect()
			Duel.Damage(1-tp,dam,REASON_EFFECT)
		end
	end
end
