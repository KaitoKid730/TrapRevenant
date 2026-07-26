--Shared utility script for the "Trap Revenant" custom archetype
--Loaded by every "Trap Revenant" card via Duel.LoadScript("utility_traprevenant.lua")
--This file only *defines* the global TrapRevenant table the first time it is loaded;
--EDOPro will call Duel.LoadScript multiple times (once per card that needs it) so we
--guard against double-initialization.
if TrapRevenant then return end
TrapRevenant={}

--------------------------------------------------------------------------
-- Card IDs (passcodes). These are fan-made codes, chosen in the
-- 900000000+ range so they cannot collide with any real, official card.
--------------------------------------------------------------------------
TrapRevenant.SPECTER_ID=900000001
TrapRevenant.SHROUD_ID=900000002
TrapRevenant.UNBOUND_ID=900000003
TrapRevenant.EXILED_ID=900000004
TrapRevenant.ABSOLUTION_ID=900000005
TrapRevenant.ETHEREAL_ID=900000006
TrapRevenant.VOID_ID=900000007
TrapRevenant.RECALL_ID=900000008
TrapRevenant.ECHO_ID=900000009

--Flag-effect id (NOT an Effect code) used to flag a card as having been granted
--FREE (no discard/banish cost) permission to activate the turn it was Set, e.g.
--by Shroud/Recall's "Set 1/2 Trap Revenant Trap(s), it/they can be activated
--this turn" effects. This is distinct from the card's own inherent
--RegisterSetTurnPermission grant, which still requires paying the discard-or-
--banish cost. Uses Card.RegisterFlagEffect/Card.HasFlagEffect (the standard,
--purpose-built marker API) instead of registering a fake Effect object with a
--made-up code -- the latter was not being read back reliably by IsHasEffect
--and left freshly-Set cards from Recall unable to satisfy MakeSetTurnCost,
--so they showed as not activatable at all.
TrapRevenant.FREE_ACT_FLAG=190000001

TrapRevenant.IDS={
	TrapRevenant.SPECTER_ID,
	TrapRevenant.SHROUD_ID,
	TrapRevenant.UNBOUND_ID,
	TrapRevenant.EXILED_ID,
	TrapRevenant.ABSOLUTION_ID,
	TrapRevenant.ETHEREAL_ID,
	TrapRevenant.VOID_ID,
	TrapRevenant.RECALL_ID,
	TrapRevenant.ECHO_ID,
}

--------------------------------------------------------------------------
-- Generic helpers
--------------------------------------------------------------------------
--Is this card a "Trap Revenant" card (any of the 9)?
function TrapRevenant.IsTrapRevenant(c)
	return c:IsCode(table.unpack(TrapRevenant.IDS))
end

--------------------------------------------------------------------------
-- Shared "activate the turn it was Set" cost:
-- "You can activate this card the turn it was Set by discarding 1 card
-- or by banishing 1 Trap from your GY"
-- If the card was NOT set this turn, no cost is paid at all (normal activation).
--------------------------------------------------------------------------
function TrapRevenant.banfilter(c)
	return c:IsTrap() and c:IsAbleToRemoveAsCost()
end

--Returns a cost function bound to a specific card id (for its choice description strings)
--String offsets used: 14 = "Discard 1 card.", 15 = "Banish 1 Trap from your GY."
function TrapRevenant.MakeSetTurnCost(id)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		local c=e:GetHandler()
		--If this card was NOT activated the turn it was Set, OR it was granted a
		--free (no-cost) activation this turn (see TrapRevenant.GrantFreeSetActivation),
		--no cost is required at all.
		if not c:IsStatus(STATUS_SET_TURN) or c:HasFlagEffect(TrapRevenant.FREE_ACT_FLAG) then
			if chk==0 then return true end
			return
		end
		local b1=Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
		local b2=Duel.IsExistingMatchingCard(TrapRevenant.banfilter,tp,LOCATION_GRAVE,0,1,nil)
		if chk==0 then return b1 or b2 end
		local op=1
		if b1 and b2 then
			op=Duel.SelectEffect(tp,{true,aux.Stringid(id,14)},{true,aux.Stringid(id,15)})
		elseif b2 then
			op=2
		end
		if op==1 then
			Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST|REASON_DISCARD)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local g=Duel.SelectMatchingCard(tp,TrapRevenant.banfilter,tp,LOCATION_GRAVE,0,1,1,nil)
			Duel.Remove(g,POS_FACEUP,REASON_COST)
		end
	end
end

--Also allow the card to actually declare itself activatable during its Set turn.
--(Normal Traps cannot be activated the turn they were Set unless granted permission.)
function TrapRevenant.RegisterSetTurnPermission(c)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e0:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e0:SetCondition(function(e)
		local tp=e:GetHandlerPlayer()
		return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
			or Duel.IsExistingMatchingCard(TrapRevenant.banfilter,tp,LOCATION_GRAVE,0,1,nil)
	end)
	c:RegisterEffect(e0)
end

--Grants a card that was just Set (from GY/banished/hand, by an effect like
--Shroud or Recall) permission to be activated THIS turn, with NO discard/banish
--cost required. Registers both the permission itself and the FREE_ACT_FLAG
--flag-effect that MakeSetTurnCost checks to waive its cost.
function TrapRevenant.GrantFreeSetActivation(tc,descid)
	local e1=Effect.CreateEffect(tc)
	if descid then e1:SetDescription(descid) end
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
	tc:RegisterFlagEffect(TrapRevenant.FREE_ACT_FLAG,RESET_EVENT|RESETS_STANDARD,0,1)
end

--------------------------------------------------------------------------
-- "send X card(s) from the top of either player's Deck to the GY"
-- String offsets used: 4 = "Your Deck.", 5 = "Your opponent's Deck."
--------------------------------------------------------------------------
function TrapRevenant.MillEitherDeck(tp,id,count)
	local b1=Duel.IsPlayerCanDiscardDeck(tp,count)
	local b2=Duel.IsPlayerCanDiscardDeck(1-tp,count)
	if not (b1 or b2) then return end
	local op
	if b1 and b2 then
		op=Duel.SelectEffect(tp,{true,aux.Stringid(id,4)},{true,aux.Stringid(id,5)})
	elseif b1 then op=1
	else op=2 end
	if op then
		Duel.DiscardDeck(op==1 and tp or 1-tp,count,REASON_EFFECT)
	end
end

--------------------------------------------------------------------------
-- "You cannot activate monster effects for the rest of this turn"
--------------------------------------------------------------------------
function TrapRevenant.monsteractlimit(e,re,rp)
	return re:IsMonsterEffect()
end
function TrapRevenant.RegisterNoMonsterEffects(e,tp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(1,0)
	e1:SetValue(TrapRevenant.monsteractlimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--------------------------------------------------------------------------
-- Self-contained "resolution" functions for each card's Set-turn effect.
-- These are used both by that card's own activation, and by
-- "Trap Revenant - Echo", which becomes a copy of a targeted card's
-- activation effect. Each function performs its own internal
-- selection(s) and simply does nothing (whiffs) if no valid
-- selection exists, since Echo's own legality check does not
-- re-validate the copied effect's sub-requirements.
--------------------------------------------------------------------------

--Specter: add 1 "Trap Revenant" card from Deck/GY to hand, except Specter
function TrapRevenant.ResolveSpecter(e,tp)
	local function filter(c)
		return TrapRevenant.IsTrapRevenant(c) and not c:IsCode(TrapRevenant.SPECTER_ID) and c:IsAbleToHand()
	end
	if not Duel.IsExistingMatchingCard(filter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,filter,tp,LOCATION_DECK|LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Shroud: send 1 Trap from Deck to GY, look at opponent's hand, optionally Set 1 Trap Revenant from hand
function TrapRevenant.ResolveShroud(e,tp)
	local function tgfilter(c) return c:IsTrap() and c:IsAbleToGrave() end
	if not Duel.IsExistingMatchingCard(tgfilter,tp,LOCATION_DECK,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		local hg=Duel.GetFieldGroup(1-tp,0,LOCATION_HAND)
		Duel.ConfirmCards(tp,hg)
		local function setfilter(c) return TrapRevenant.IsTrapRevenant(c) and c:IsSSetable() end
		if Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(setfilter,tp,LOCATION_HAND,0,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(TrapRevenant.SHROUD_ID,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
			local sc=Duel.SelectMatchingCard(tp,setfilter,tp,LOCATION_HAND,0,1,1,nil):GetFirst()
			if sc and Duel.SSet(tp,sc)>0 then
				TrapRevenant.GrantFreeSetActivation(sc,aux.Stringid(TrapRevenant.SHROUD_ID,3))
			end
		end
	end
end

--Unbound: return 1 card on the field to the hand, damage if it was a monster, then lock monster effects
function TrapRevenant.ResolveUnbound(e,tp)
	local function filter(c) return c:IsOnField() and c:IsAbleToHand() end
	if Duel.IsExistingMatchingCard(filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
		local g=Duel.SelectMatchingCard(tp,filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		local tc=g:GetFirst()
		if tc then
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
	end
	TrapRevenant.RegisterNoMonsterEffects(e,tp)
end

--Exiled: banish 1 monster in either GY, inflict damage equal to its original ATK/DEF (whichever higher)
function TrapRevenant.ResolveExiled(e,tp)
	local function filter(c) return c:IsMonster() and c:IsAbleToRemove() end
	if not Duel.IsExistingMatchingCard(filter,tp,0,LOCATION_GRAVE,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,filter,tp,0,LOCATION_GRAVE,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	local atk=tc:GetTextAttack()
	local def=tc:GetTextDefense()
	if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)>0 then
		local dam=math.max(atk,def)
		if dam<0 then dam=0 end
		Duel.BreakEffect()
		Duel.Damage(1-tp,dam,REASON_EFFECT)
	end
end

--Absolution: until the end of the turn, damage you would take is inflicted to your opponent instead
--
--Uses EFFECT_REFLECT_DAMAGE (code 83 in effect.h), the generic
--(non-battle-restricted) sibling of EFFECT_REFLECT_BATTLE_DAMAGE.
--Verified directly against the ygopro-core engine source
--(field::damage() in operations.cpp): when a player is about to take
--damage, the engine checks EFFECT_REFLECT_DAMAGE FIRST, and if active,
--literally flips the damage's target player before any LP is touched
--at all -- it never subtracts LP from you and never needs to refund
--it. That's why the earlier Duel.RecoverLP() approach visibly showed
--you "gaining LP": it was taking the damage and then crediting it
--back, which is a real (visible) LP swing, not a true redirect.
--
--filter_player_effect() (field.cpp) confirmed this needs the same
--registration shape as EFFECT_CHANGE_DAMAGE: EFFECT_FLAG_PLAYER_TARGET
--+ SetTargetRange(1,0) so the engine's is_target_player(tp) check
--matches. No Operation/Value function is needed -- a bare SetValue(1)
--flag is enough, exactly like Hu-Li the Jewel Mikanko's
--EFFECT_REFLECT_BATTLE_DAMAGE clone (just SetValue(1), no callback).
function TrapRevenant.ResolveAbsolution(e,tp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_REFLECT_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--Generic "you take no damage this turn" (used by Absolution's GY effect)
function TrapRevenant.zerodamval(e,re,val,r,rp,rc)
	--Same fix as absolutionval: TargetRange(1,0) already scopes this to the
	--handler's controller, so damage should be zeroed unconditionally here.
	return 0
end
function TrapRevenant.RegisterNoDamage(e,tp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CHANGE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(TrapRevenant.zerodamval)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	Duel.RegisterEffect(e2,tp)
end

--Ethereal: change up to 2 face-up monsters on the field to face-down Defense Position
function TrapRevenant.ResolveEthereal(e,tp)
	local function filter(c) return c:IsFaceup() and c:IsCanTurnSet() end
	if not Duel.IsExistingMatchingCard(filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectMatchingCard(tp,filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,2,nil)
	if #g>0 then
		Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)
	end
end

--Void: send 5 cards from the top of either player's Deck to GY, then lock monster effects
function TrapRevenant.ResolveVoid(e,tp)
	TrapRevenant.MillEitherDeck(tp,TrapRevenant.VOID_ID,5)
	TrapRevenant.RegisterNoMonsterEffects(e,tp)
end

--Recall: Set 2 (up to 2) "Trap Revenant" Traps from GY/banished, usable this turn
function TrapRevenant.ResolveRecall(e,tp)
	local function setfilter(c) return TrapRevenant.IsTrapRevenant(c) and c:IsSSetable() end
	local ct=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ct<=0 or not Duel.IsExistingMatchingCard(setfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) then return end
	ct=math.min(ct,2)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,setfilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,ct,nil)
	if #g>0 and Duel.SSet(tp,g)>0 then
		for tc in g:Iter() do
			TrapRevenant.GrantFreeSetActivation(tc,aux.Stringid(TrapRevenant.RECALL_ID,2))
		end
	end
end

--------------------------------------------------------------------------
-- Dispatcher used by "Trap Revenant - Echo"
--------------------------------------------------------------------------
function TrapRevenant.Dispatch(code,e,tp)
	if code==TrapRevenant.SPECTER_ID then TrapRevenant.ResolveSpecter(e,tp)
	elseif code==TrapRevenant.SHROUD_ID then TrapRevenant.ResolveShroud(e,tp)
	elseif code==TrapRevenant.UNBOUND_ID then TrapRevenant.ResolveUnbound(e,tp)
	elseif code==TrapRevenant.EXILED_ID then TrapRevenant.ResolveExiled(e,tp)
	elseif code==TrapRevenant.ABSOLUTION_ID then TrapRevenant.ResolveAbsolution(e,tp)
	elseif code==TrapRevenant.ETHEREAL_ID then TrapRevenant.ResolveEthereal(e,tp)
	elseif code==TrapRevenant.VOID_ID then TrapRevenant.ResolveVoid(e,tp)
	elseif code==TrapRevenant.RECALL_ID then TrapRevenant.ResolveRecall(e,tp)
	end
end