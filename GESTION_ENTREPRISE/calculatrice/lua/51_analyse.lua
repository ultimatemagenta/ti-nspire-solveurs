-- 51_analyse.lua : analyse de bilan et du résultat (chap. 51) — types C1 à C9 du plan, extensions marquées « (hors test) »
-- Sources : liste des ratios Profil M [R] ; chap. 51 (pages PDF) ; corrigés 51.8, 51.10, 51.11, 51.14, 51.15, 51.19, 51.21,
-- 51.23, 51.24, 51.25, 51.27, 51.28 ; test 2025 ex. 3 et 5 ; 57.22 (ratios de cash flow).
do
local F = {}          -- fonctions internes du module (une seule variable locale pour tout ranger)

------------------------------------------------------------------ formats
local function m(x)   -- montant : 12'500, 1'670'841.5, 1'216.8
  if type(x) ~= "number" then return "?" end
  if math.abs(x - math.floor(x + 0.5)) < 1e-9 then return fmt(x, 0) end
  if math.abs(x * 10 - math.floor(x * 10 + 0.5)) < 1e-6 then return fmt(x, 1) end
  return fmt(x, 2)
end
local function p2(x) if not x then return "—" end; return string.format("%.2f %%", x) end   -- x déjà multiplié par 100
local function d2(x) if not x then return "—" end; return string.format("%.2f", x) end
local function r2(x) return math.floor(x * 100 + 0.5) / 100 end
function F.ok(...)
  for i = 1, select("#", ...) do if select(i, ...) == nil then return false end end
  return true
end

------------------------------------------------------------------ champs et exemples du prof
local CAT = {
  liq = "Liquidités", cre = "Créances", sto = "Stocks", ac = "Actifs circulants", ai = "Actifs immobilisés", tot = "Total du bilan",
  ct = "CE à court terme", lt = "CE à long terme", ce = "Capitaux étrangers", fp = "Capitaux propres", cc = "Capital de croissance",
  liq1 = "Liquidités N-1", cre1 = "Créances N-1", sto1 = "Stocks N-1", ai1 = "AI N-1", ct1 = "CE ct N-1", lt1 = "CE lt N-1",
  fp1 = "Capitaux propres N-1", cc1 = "Cap. croissance N-1", tot1 = "Total du bilan N-1", ce1 = "CE N-1",
  can = "CA net", cac = "CA à crédit (vide = CAN)", pramv = "PRAMV", prama = "PRAMA (vide = PRAMV + var. stock)", mb = "Marge brute",
  ebit = "EBIT (vide = BN + ch. fin. − prod. fin. + impôts)", bn = "Bénéfice net", chf = "Charges financières",
  pf = "Produits financiers", imp = "Impôts", amo = "Amortissements",
  frs = "Dettes fournisseurs (vide = CE ct)", frs1 = "Dettes fournisseurs N-1 (vide = CE ct N-1)",
  cf = "Cash flow (vide = BN + amort.)", inv = "Investissements nets (vide = AI − AI N-1 + amort.)",
  ee = "Endettement effectif (vide = CE − liq. − créances)", dcl = "Délai accordé aux clients (jours)", dfo = "Délai des fournisseurs (jours)",
}
-- composition de chaque poste (affichée sous la question du questionnaire) : liste Profil M [R], 51 p.4 (bilan analytique), 51 p.31
local AIDE = {
  liq = "Liquidités = caisse + poste + banque (c/c actif) + titres cotés détenus à court terme (placements facilement réalisables). Les participations vont dans les AI (51 p.4).",
  cre = "Créances = créances clients − ducroire (provision pour pertes sur créances) + autres créances à court terme (AFC, impôt préalable) + actifs de régularisation (51 p.4).",
  sto = "Stocks = stock de marchandises (+ matières, produits finis, en-cours) + acomptes aux fournisseurs pour marchandises − acomptes de clients (51 p.4).",
  ai = "Actifs immobilisés = mobilier + machines + véhicules + immeubles + brevets + participations (− fonds d'amortissements cumulés) (51 p.4).",
  ct = "CE à court terme = dettes fournisseurs + dividendes à payer (décidés par l'AG) + dettes bancaires à court terme (banque c/c passif) + autres dettes à c.t. + passifs de régularisation. Garder le classement de l'énoncé (test 2025 : dividendes en CE l.t.).",
  lt = "CE à long terme = prêts et emprunts bancaires à long terme + hypothèques + obligations + provisions à long terme (51 p.4).",
  fp = "Capitaux propres = capital-actions (− actionnaires : capital non libéré) + réserves (issues du capital et du bénéfice) + bénéfice reporté (− perte reportée) + bénéfice non distribué.",
  cc = "Capital de croissance = réserves issues du bénéfice + bénéfice reporté (− perte reportée), sans agio ni réserve issue du capital (51 p.10). Sert au degré d'autofinancement.",
  ac = "Actifs circulants = liquidités + créances + stocks.",
  tot = "Total du bilan = actifs circulants + actifs immobilisés (= total du passif).",
  ce = "Capitaux étrangers = CE à court terme + CE à long terme.",
  can = "CA net = ventes − retours des clients − déductions accordées (rabais, escomptes) − pertes sur créances − frais directs de vente (51 p.31).",
  cac = "CA à crédit = part du CA vendue à crédit. Vide = on prend le CAN total (51 p.41).",
  pramv = "PRAMV = PRAMA + diminution de stock (ou − augmentation) ; PRAMA = achats + frais d'achats − déductions obtenues (51 p.31).",
  prama = "PRAMA (à crédit) = achats − retours aux fournisseurs − déductions obtenues + frais d'achats. Vide = PRAMV + stock final − stock initial.",
  mb = "Marge brute = CAN − PRAMV.",
  ebit = "EBIT = bénéfice net + impôts + charges financières − produits financiers (résultat avant intérêts et impôts). Vide = calculé ainsi (51.25).",
  bn = "Bénéfice net de l'exercice : dernière ligne du compte de résultat.",
  chf = "Charges financières = intérêts payés sur les dettes (+ frais bancaires). Sert à l'EBIT.",
  pf = "Produits financiers = intérêts et dividendes reçus ; 0 s'il n'y en a pas.",
  imp = "Impôts directs (sur le bénéfice et le capital) ; 0 s'ils ne sont pas donnés.",
  amo = "Amortissements de l'exercice (compte de résultat). Sert au cash flow (chap. 57).",
  frs = "Dettes fournisseurs (bilan). Vide = on prend les CE à court terme, comme le prof en 51.24.",
  cf = "Cash flow = bénéfice net + amortissements (méthode indirecte simplifiée, chap. 57). Vide = calculé ainsi.",
  inv = "Investissements nets = AI N − AI N-1 + amortissements (57 p.62). Vide = calculé ainsi.",
  ee = "Endettement effectif = capitaux étrangers − liquidités − créances. Vide = calculé ainsi.",
  dcl = "Délai de paiement accordé aux clients, en jours (ex. 30). Vide = pas de comparaison.",
  dfo = "Délai de paiement des fournisseurs, en jours. Vide = pas de comparaison.",
}
-- champs facultatifs : vide = ignoré ou valeur reconstituée
local OPT = {cc = true, cac = true, prama = true, ebit = true, frs = true, frs1 = true, cf = true, inv = true, ee = true, dcl = true,
  dfo = true, pf = true, imp = true, amo = true, chf = true}
-- par défaut : sommes des comptes de l'énoncé du prof (le rendu réécrit la composition : « Liquidités = 35 + 30 = 65 »)
local EX = {
  T25 = {nom = "test 2025 ex. 3, année 2026", liq = "35+30", cre = "470", sto = "440", ac = "65+470+440", ai = "20+590+90", tot = "975+700",
         ct = "450", lt = "110+220", ce = "450+330", fp = "625+250+20", cc = "250+20"},
  M23 = {nom = "51.23, année N", can = 4500845, mb = 1800338, ebit = 298274, bn = 205016},
  C24 = {nom = "51.24, coopérative A 2014", cac = 6134.2, cre = 1216.8, cre1 = 1149.1, pramv = 5356.4, sto = 228.5, sto1 = 261.3,
         prama = 5323.6, frs = 1737.1, frs1 = 1979.6},
  CF = {nom = "57.22, Chaudpain SA", cf = 18, inv = 77, can = 369, ce = 288, liq = 6, cre = 55},
  COL = {nom = "51.25 et 51.27, Colibri SA", can = 8432560, ebit = 124361, bn = 117881, chf = 6480, tot = 1828321, tot1 = 1513362,
         fp = 1289789, fp1 = 1226908},
}
function F.champs(cles, ex)
  local t = {}
  for _, k in ipairs(cles) do
    local d = ex and ex[k]
    local base, an = k:match("^(%a+)(1)$")
    local aide = AIDE[k] or (base and AIDE[base] and (AIDE[base] .. " — Année N-1 (vide = pas de moyenne, on prend la valeur N).")) or nil
    table.insert(t, {cle = k, lib = CAT[k] or k, defaut = d and tostring(d) or "", aide = aide, opt = OPT[k] or (an ~= nil)})
  end
  return t
end

------------------------------------------------------------------ valeurs déduites et moyennes
-- complète les grandeurs qui manquent (sans écraser une saisie) ; v._auto garde l'explication de chaque déduction
function F.deriver(v)
  v._r = v._r or {}; v._m = v._m or {}; v._auto = v._auto or {}
  local function note(s) table.insert(v._auto, s) end
  for _, s in ipairs({"", "1"}) do
    local liq, cre, sto = v["liq" .. s], v["cre" .. s], v["sto" .. s]
    if not v["ac" .. s] and F.ok(liq, cre, sto) then v["ac" .. s] = liq + cre + sto end
    if not v["tot" .. s] and F.ok(v["ac" .. s], v["ai" .. s]) then v["tot" .. s] = v["ac" .. s] + v["ai" .. s] end
    if not v["ce" .. s] and F.ok(v["ct" .. s], v["lt" .. s]) then v["ce" .. s] = v["ct" .. s] + v["lt" .. s] end
    if not v["ce" .. s] and F.ok(v["tot" .. s], v["fp" .. s]) then v["ce" .. s] = v["tot" .. s] - v["fp" .. s] end
  end
  if not v.mb and F.ok(v.can, v.pramv) then
    v.mb = v.can - v.pramv; note("Marge brute = CAN − PRAMV = " .. m(v.can) .. " − " .. m(v.pramv) .. " = " .. m(v.mb))
  end
  if not v.ebit and v.bn then
    v.ebit = v.bn + (v.imp or 0) + (v.chf or 0) - (v.pf or 0)
    note("EBIT = BN + impôts + charges financières − produits financiers = " .. m(v.bn) .. " + " .. m(v.imp or 0) .. " + "
      .. m(v.chf or 0) .. " − " .. m(v.pf or 0) .. " = " .. m(v.ebit) .. " (modèle 51.25)")
  end
  if not v.cac and v.can then v.cac = v.can; note("CA à crédit inconnu : on prend le CAN total = " .. m(v.can) .. " (51 p.41)") end
  if not v.prama and F.ok(v.pramv, v.sto, v.sto1) then
    v.prama = v.pramv + v.sto - v.sto1
    note("PRAMA = PRAMV + stock final − stock initial = " .. m(v.pramv) .. " + " .. m(v.sto) .. " − " .. m(v.sto1) .. " = " .. m(v.prama))
  end
  if not v.frs and v.ct then v.frs = v.ct; note("Dettes fournisseurs inconnues : on prend les CE à court terme (comme le prof en 51.24)") end
  if not v.frs1 and v.ct1 then v.frs1 = v.ct1 end
  if not v.cf and F.ok(v.bn, v.amo) then
    v.cf = v.bn + v.amo; note("Cash flow (méthode indirecte simplifiée, chap. 57) = BN + amortissements = " .. m(v.bn) .. " + " .. m(v.amo) .. " = " .. m(v.cf))
  end
  if not v.inv and F.ok(v.ai, v.ai1, v.amo) then
    v.inv = v.ai - v.ai1 + v.amo
    note("Investissements nets = AI N − AI N-1 + amortissements = " .. m(v.ai) .. " − " .. m(v.ai1) .. " + " .. m(v.amo) .. " = " .. m(v.inv) .. " (57 p.62, amortissement direct)")
  end
  return v
end

-- moyenne de deux bilans : ø = (N-1 + N) ÷ 2, écrite une seule fois par document
function F.moy(v, k, lib)
  if v._m[k] then return v._m[k] end
  local a, b = v[k], v[k .. "1"]
  if not a then return nil end
  local r
  if b then r = (a + b) / 2; X("ø " .. lib .. " = (" .. m(b) .. " + " .. m(a) .. ") ÷ 2 = " .. m(r))
  else r = a; G("ø " .. lib .. " : pas de valeur N-1, on prend la valeur N (" .. m(a) .. ")") end
  v._m[k] = r
  return r
end

------------------------------------------------------------------ commentaires (tournures des corrigés du prof)
local REP = "(repères tirés des corrigés 51.8, 51.10, 51.11 : le manuel ne donne pas de norme)"
function F.synthLiq(l1, l2, l3)
  if not F.ok(l1, l2, l3) then return "Liquidité : données incomplètes." end
  local s
  if l2 >= 100 then
    if l1 < 20 then
      s = string.format("La liquidité 1 (%s) est sous la valeur indicative de 20 à 30 %%, mais les créances clients devraient permettre à l'entreprise de payer ses dettes à court terme sans difficulté : la liquidité 2 (%s) dépasse 100 %% (modèle : test 2025 ex. 3).", p2(l1), p2(l2))
    elseif l1 <= 30 then
      s = string.format("Liquidité saine : la liquidité 1 (%s) est dans la norme (20 à 30 %%) et la liquidité 2 (%s) dépasse 100 %% ; l'entreprise peut faire face à ses dettes à court terme.", p2(l1), p2(l2))
    else
      s = string.format("L'entreprise est nettement en excédent de liquidités (liquidité 1 = %s > 30 %%). Peut-être est-ce volontaire pour acheter une autre entreprise ou réaliser prochainement des investissements importants ; sinon, c'est de l'argent qui ne rapporte rien (modèle 51.8). Ses dettes à court terme sont largement couvertes (liquidité 2 = %s).", p2(l1), p2(l2))
    end
  else
    s = string.format("La liquidité 2 (%s) est sous la norme de 100 %% : liquidités et créances ne suffisent pas à payer les dettes à court terme", p2(l2))
    if l3 >= 100 then s = s .. string.format(" ; l'entreprise devra vendre ses stocks (liquidité 3 = %s) ou obtenir un crédit.", p2(l3))
    else s = s .. string.format(", même en vendant tous ses stocks (liquidité 3 = %s < 100 %%) : risque d'insolvabilité, ses dettes à court terme sont très importantes.", p2(l3)) end
    if l1 < 20 then s = s .. string.format(" La liquidité 1 (%s) est elle aussi insuffisante : l'entreprise manque de liquidités.", p2(l1))
    elseif l1 > 30 then s = s .. string.format(" La liquidité 1 (%s) est pourtant élevée : ce sont les créances qui sont faibles.", p2(l1)) end
  end
  return s
end
function F.synthFin(e)
  if not e then return "Financement : données incomplètes." end
  if e < 50 then
    return string.format("Endettement faible (%s) : l'entreprise se finance avant tout par des fonds propres. Les risques sont moindres, mais cela va compromettre la rentabilité des fonds propres (modèle 51.8). %s", p2(e), REP)
  elseif e <= 70 then
    return string.format("Endettement de %s : un financement qui correspond assez à la norme (51.8 : 56 %% « dans la norme »). %s", p2(e), REP)
  end
  return string.format("Endettement de %s : l'entreprise est surendettée et très vulnérable en cas de perte ; ses charges financières sont élevées (modèle 51.8 : 82 %%). %s", p2(e), REP)
end
function F.synthCouv(c1, c2, iai, e)
  if not F.ok(c1, c2) then return "Couverture : données incomplètes." end
  local s
  if c2 >= 100 and c1 >= 100 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) et l'entreprise paie ses actifs immobilisés avec ses fonds propres (couverture 1 = %s), donc tout va bien (modèle : test 2025 ex. 3).", p2(c2), p2(c1))
  elseif c2 >= 100 and c1 > 80 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) et les immobilisations sont largement financées par les fonds propres (couverture 1 = %s > 80 %%) : risque faible.", p2(c2), p2(c1))
  elseif c2 >= 100 and c1 >= 60 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) : les immobilisations sont financées par des capitaux permanents, majoritairement par des fonds propres (couverture 1 = %s, dans la norme de 60 à 80 %%).", p2(c2), p2(c1))
  elseif c2 >= 100 then
    s = string.format("La règle d'or est respectée (couverture 2 = %s ≥ 100 %%) grâce aux capitaux étrangers à long terme, mais la part des fonds propres est insuffisante (couverture 1 = %s < 60 %%).", p2(c2), p2(c1))
  else
    s = string.format("La règle d'or n'est pas respectée (couverture 2 = %s < 100 %%) : une partie des immobilisations est financée par des dettes à court terme, qu'il faudra rembourser avant que ces investissements ne rapportent (couverture 1 = %s).", p2(c2), p2(c1))
  end
  if c2 >= 100 and iai and iai < 30 and e and e > 70 then
    s = s .. string.format(" Attention : la couverture 2 n'est élevée que parce que les immobilisations sont faibles (intensité de l'AI = %s), alors que l'entreprise est très endettée.", p2(iai))
  end
  return s
end

------------------------------------------------------------------ les 26 ratios de la liste Profil M [R]
-- calc(v) -> numérateur, dénominateur, application écrite (ou {r = valeur}, nil, application)
-- u : "%" (× 100), "x" (fois), "j" (jours), "f" (facteur), "pt" (pourcentage déjà calculé)
local RAT = {
  {id = "liq1", nom = "Liquidité 1", u = "%", dec = true, ex = "T25", champs = {"liq", "ct"}, fam = "Liquidité",
   formule = "Liquidités × 100 ÷ CE à court terme",
   calc = function(v) return v.liq, v.ct, m(v.liq) .. " × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r < 20 then return p2(r) .. " < valeur indicative de 20 à 30 % : peu de liquidités immédiates pour payer les dettes à court terme ; à juger avec la liquidité 2 (créances)." end
     if r <= 30 then return p2(r) .. " : dans la valeur indicative (20 à 30 %) ; les dettes urgentes peuvent être payées sans garder trop d'argent qui ne rapporte rien." end
     return p2(r) .. " > 30 % : ratio trop élevé, excédent de liquidités (peut-être volontaire : investissement prévu, rachat d'entreprise) ; de l'argent qui dort (51.8, 51.10)."
   end, src = "51 p.11 (PDF) · modèle : test 2025 ex. 3, 51.10"},
  {id = "liq2", nom = "Liquidité 2", u = "%", dec = true, ex = "T25", champs = {"liq", "cre", "ct"}, fam = "Liquidité",
   formule = "(Liquidités + Créances) × 100 ÷ CE à court terme",
   calc = function(v) if not F.ok(v.liq, v.cre) then return nil end
     return v.liq + v.cre, v.ct, "(" .. m(v.liq) .. " + " .. m(v.cre) .. ") × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % (le ratio le plus important) : liquidités et créances couvrent les dettes à court terme ; l'entreprise peut y faire face." end
     return p2(r) .. " < 100 % : ratio faible par rapport à la norme ; il faudra vendre des stocks ou obtenir un crédit pour payer les dettes à court terme (risque d'illiquidité)."
   end, src = "51 p.11-12 · modèle : 51.10, 51.11"},
  {id = "liq3", nom = "Liquidité 3", u = "%", dec = true, ex = "T25", champs = {"ac", "ct"}, fam = "Liquidité",
   formule = "Actifs circulants × 100 ÷ CE à court terme",
   calc = function(v) return v.ac, v.ct, m(v.ac) .. " × 100 ÷ " .. m(v.ct) end,
   comm = function(r)
     if r >= 150 then return p2(r) .. " > 150 % : les actifs circulants couvrent largement les dettes à court terme (FRN positif)." end
     if r >= 100 then return p2(r) .. " : sous la valeur indicative de 150 %, mais ce n'est pas forcément problématique si la liquidité 2 est bonne (51 p.12)." end
     return p2(r) .. " < 100 % : FRN négatif, une partie des immobilisations est financée par des dettes à court terme ; situation dangereuse."
   end, src = "51 p.11-12 · 51.11 : « dans la norme (150 à 200 %) »"},
  {id = "iac", nom = "Intensité de l'actif circulant", u = "%", dec = true, ex = "T25", champs = {"ac", "tot"}, fam = "Structure de l'actif",
   formule = "Actifs circulants × 100 ÷ Total de l'actif",
   calc = function(v) return v.ac, v.tot, m(v.ac) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r) return p2(r) .. " : pas de valeur indicative ; dépend du secteur (une bijouterie n'est pas une industrie chimique). À comparer avec des entreprises du même secteur et dans le temps (51 p.9)." end,
   src = "51 p.9 · modèle 51.10"},
  {id = "iai", nom = "Intensité de l'actif immobilisé", u = "%", dec = true, ex = "T25", champs = {"ai", "tot"}, fam = "Structure de l'actif",
   formule = "Actifs immobilisés × 100 ÷ Total de l'actif",
   calc = function(v) return v.ai, v.tot, m(v.ai) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     local s = r >= 60 and "élevée : beaucoup d'immobilisations, donc des charges fixes importantes (amortissements, entretien) (51.15)"
       or (r < 30 and "faible : peu d'immobilisations (commerce, services), peu de charges fixes" or "moyenne")
     return p2(r) .. " : " .. s .. " ; la valeur dépend du secteur d'activité."
   end, src = "51 p.9 · 51.15"},
  {id = "end", nom = "Degré d'endettement", u = "%", dec = true, ex = "T25", champs = {"ce", "tot"}, fam = "Financement",
   formule = "Capitaux étrangers × 100 ÷ Total du passif",
   calc = function(v) return v.ce, v.tot, m(v.ce) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     if r < 50 then return p2(r) .. " : endettement faible (51.10 : 43.78 % « faible »), risque moindre ; mais rentabilité des fonds propres moins favorisée. " .. REP end
     if r <= 70 then return p2(r) .. " : endettement dans la norme (51.8 : 56 %). Un endettement fort implique des charges financières et un risque plus élevés. " .. REP end
     return p2(r) .. " : endettement élevé, entreprise surendettée et vulnérable en cas de perte (51.8 : 82 %). " .. REP
   end, src = "51 p.10-11 · 51.8, 51.10"},
  {id = "fp", nom = "Degré de financement propre", u = "%", dec = true, ex = "T25", champs = {"fp", "tot"}, fam = "Financement",
   formule = "Capitaux propres × 100 ÷ Total du passif",
   calc = function(v) return v.fp, v.tot, m(v.fp) .. " × 100 ÷ " .. m(v.tot) end,
   comm = function(r)
     if r >= 50 then return p2(r) .. " : capitaux propres élevés ; indépendance envers les bailleurs de fonds, sécurité en cas de pertes, charges financières faibles (51.10)." end
     if r >= 30 then return p2(r) .. " : dans la moyenne (environ 30 %), mais sous l'idéal bancaire de 50 % (51.11)." end
     return p2(r) .. " : faible ; forte dépendance envers les créanciers, peu de réserve pour absorber des pertes."
   end, src = "51 p.10 · 51.10, 51.11 ; endettement + financement propre = 100 % (51.15)"},
  {id = "auto", nom = "Degré d'autofinancement", u = "%", dec = true, ex = "T25", champs = {"cc", "fp"}, fam = "Financement",
   formule = "Capital de croissance × 100 ÷ Capitaux propres",
   calc = function(v) return v.cc, v.fp, m(v.cc) .. " × 100 ÷ " .. m(v.fp) end,
   comm = function(r)
     local s = r < 20 and "faible : entreprise jeune, faible capacité bénéficiaire ou bénéfices distribués"
       or (r > 60 and "élevé : les bénéfices ont été accumulés dans les réserves (cas des coopératives, 51.14)" or "moyen")
     return p2(r) .. " : " .. s .. ". Dépend de l'âge de l'entreprise, des bénéfices antérieurs et de la politique de dividendes : à utiliser avec prudence (51.10, 51.15)."
   end, src = "51 p.10-11 · capital de croissance = réserves issues du bénéfice + bénéfice reporté (sans agio ni réserve issue du capital)"},
  {id = "couv1", nom = "Degré de couverture 1", u = "%", dec = true, ex = "T25", champs = {"fp", "ai"}, fam = "Couverture des immobilisations",
   formule = "Capitaux propres × 100 ÷ Actifs immobilisés",
   calc = function(v) return v.fp, v.ai, m(v.fp) .. " × 100 ÷ " .. m(v.ai) end,
   comm = function(r)
     if r > 80 then return p2(r) .. " > 80 % : les immobilisations sont " .. (r >= 100 and "entièrement" or "largement") .. " payées par les fonds propres ; risque très faible, entreprise pérenne." end
     if r >= 60 then return p2(r) .. " : dans la norme (entre 60 et 80 %) ; investissements majoritairement financés par les fonds propres." end
     return p2(r) .. " < 60 % : insuffisant par rapport à la norme (60 à 80 %) ; les immobilisations dépendent des capitaux étrangers."
   end, src = "51 p.13 · 51.10, 51.11"},
  {id = "couv2", nom = "Degré de couverture 2", u = "%", dec = true, ex = "T25", champs = {"fp", "lt", "ai"}, fam = "Couverture des immobilisations",
   formule = "(Capitaux propres + CE à long terme) × 100 ÷ Actifs immobilisés",
   calc = function(v) if not F.ok(v.fp, v.lt) then return nil end
     return v.fp + v.lt, v.ai, "(" .. m(v.fp) .. " + " .. m(v.lt) .. ") × 100 ÷ " .. m(v.ai) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % : la règle d'or est respectée ; les immobilisations sont financées par des capitaux permanents." end
     return p2(r) .. " < 100 % : ratio faible par rapport à la règle d'or (min. 100 %) ; une partie des immobilisations est financée à court terme."
   end, src = "51 p.13 · test 2025 ex. 3 (1.75) · 51.10"},
  {id = "tmb", nom = "Taux de marge brute", u = "%", ex = "M23", champs = {"mb", "can"}, fam = "Marges",
   formule = "Marge brute × 100 ÷ CAN",
   calc = function(v) return v.mb, v.can, m(v.mb) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " du CA reste après le coût des marchandises vendues pour couvrir les frais généraux et le bénéfice ; à comparer dans le temps et avec le secteur (51.23)." end,
   src = "51 p.35-37 · modèle 51.23"},
  {id = "tme", nom = "Taux de marge économique", u = "%", ex = "M23", champs = {"ebit", "can"}, fam = "Marges",
   formule = "EBIT × 100 ÷ CAN",
   calc = function(v) return v.ebit, v.can, m(v.ebit) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r, v)
     local s = p2(r) .. " : rentabilité de l'exploitation, avant intérêts et impôts"
     if v._r.tmb then s = s .. string.format(" ; l'écart avec le taux de marge brute (%s) mesure le poids des charges d'exploitation", p2(v._r.tmb)) end
     return s .. "."
   end, src = "51 p.36 · 51.23 · 51.27 (marge EBIT)"},
  {id = "tmn", nom = "Taux de marge nette", u = "%", ex = "M23", champs = {"bn", "can"}, fam = "Marges",
   formule = "Bénéfice net × 100 ÷ CAN",
   calc = function(v) return v.bn, v.can, m(v.bn) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " : part de chaque franc de CA qui reste en bénéfice net ; à comparer dans le temps (51.23)." end,
   src = "51 p.36 · 51.23"},
  {id = "rotcli", nom = "Rotation des créances clients", u = "x", ex = "C24", champs = {"cac", "cre", "cre1"}, fam = "Rotations et durées",
   formule = "CA à crédit ÷ ø créances clients",
   calc = function(v) local mo = F.moy(v, "cre", "créances clients"); return v.cac, mo, m(v.cac) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois : plus la rotation est rapide, plus les clients paient vite (CAN total si le CA à crédit est inconnu)." end,
   src = "51 p.41 · 51.24"},
  {id = "durcli", nom = "Durée moyenne des crédits accordés", u = "j", ex = "C24", champs = {"cac", "cre", "cre1", "dcl"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des clients", rot = "rotcli",
   comm = function(r, v)
     if v.dcl then
       if r > v.dcl then return string.format("%s jours > délai accordé de %s jours : les clients paient en retard ; relancer et suivre les factures, avec diplomatie (un débiteur reste un client, 51 p.41).", d2(r), m(v.dcl)) end
       return string.format("%s jours ≤ délai accordé de %s jours : les clients paient dans les délais.", d2(r), m(v.dcl))
     end
     return d2(r) .. " jours : les clients paient en moyenne après ce délai ; à comparer au délai de paiement accordé (au-delà : retards de paiement)."
   end, src = "51 p.41 · 51.24"},
  {id = "rotfrs", nom = "Rotation des dettes fournisseurs", u = "x", ex = "C24", champs = {"prama", "frs", "frs1"}, fam = "Rotations et durées",
   formule = "PRAMA à crédit ÷ ø dettes fournisseurs",
   calc = function(v) local mo = F.moy(v, "frs", "dettes fournisseurs"); return v.prama, mo, m(v.prama) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois : PRAMA total si le PRAMA à crédit est inconnu (51 p.42) ; attention, PRAMA et non PRAMV." end,
   src = "51 p.42 · 51.24"},
  {id = "durfrs", nom = "Durée moyenne des crédits obtenus", u = "j", ex = "C24", champs = {"prama", "frs", "frs1", "dfo"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des fournisseurs", rot = "rotfrs",
   comm = function(r, v)
     if v.dfo then
       if r > v.dfo then return string.format("%s jours > délai de %s jours : l'entreprise paie ses fournisseurs en retard (perte des escomptes, mauvaise image).", d2(r), m(v.dfo)) end
       return string.format("%s jours ≤ délai de %s jours : l'entreprise respecte les conditions de paiement ; inutile de payer avant l'échéance de l'escompte.", d2(r), m(v.dfo))
     end
     return d2(r) .. " jours : à comparer aux délais des fournisseurs ; plus long = retards de paiement (ou délais favorables obtenus, 51.24)."
   end, src = "51 p.42 · 51.24"},
  {id = "rotsto", nom = "Rotation des stocks", u = "x", ex = "C24", champs = {"pramv", "sto", "sto1"}, fam = "Rotations et durées",
   formule = "PRAMV ÷ ø stocks",
   calc = function(v) local mo = F.moy(v, "sto", "stocks"); return v.pramv, mo, m(v.pramv) .. " ÷ " .. m(mo) end,
   comm = function(r) return d2(r) .. " fois par an : une rotation rapide = gestion des stocks efficace (51.24)." end,
   src = "51 p.43 · 51.24"},
  {id = "dursto", nom = "Durée de stationnement des stocks", u = "j", ex = "C24", champs = {"pramv", "sto", "sto1"}, fam = "Rotations et durées",
   formule = "360 ÷ Rotation des stocks", rot = "rotsto",
   comm = function(r) return d2(r) .. " jours : durée à garder aussi courte que possible sans risque de rupture (flux tendus)." end,
   src = "51 p.40, 43 · 51.24"},
  {id = "rinv", nom = "Ratio d'investissement", u = "%", ex = "CF", champs = {"cf", "inv"}, fam = "Cash flow (chap. 57)",
   formule = "Cash flow × 100 ÷ Investissements nets",
   calc = function(v) return v.cf, v.inv, m(v.cf) .. " × 100 ÷ " .. m(v.inv) end,
   comm = function(r)
     if r >= 100 then return p2(r) .. " ≥ 100 % : les investissements nets sont entièrement financés par le cash flow (financement interne)." end
     return p2(r) .. " < 100 % : l'entreprise n'arrive pas à financer l'intégralité de ses investissements avec le cash flow qu'elle dégage ; prendre en compte la tendance à long terme (57.22)."
   end, src = "57 p.62 · modèle 57.22 (23.38 %)"},
  {id = "mcf", nom = "Marge de cash flow", u = "%", ex = "CF", champs = {"cf", "can"}, fam = "Cash flow (chap. 57)",
   formule = "Cash flow × 100 ÷ CAN",
   calc = function(v) return v.cf, v.can, m(v.cf) .. " × 100 ÷ " .. m(v.can) end,
   comm = function(r) return p2(r) .. " : liquidités dégagées par l'exploitation pour 100 CHF de CA ; à utiliser pour des comparaisons dans le temps (57 p.62)." end,
   src = "57 p.62 · modèle 57.22 (4.88 %)"},
  {id = "fend", nom = "Facteur d'endettement", u = "f", ex = "CF", champs = {"ce", "liq", "cre", "cf"}, fam = "Cash flow (chap. 57)",
   formule = "Endettement effectif ÷ Cash flow",
   calc = function(v)
     if not v.ee and F.ok(v.ce, v.liq, v.cre) then
       v.ee = v.ce - v.liq - v.cre
       X("Endettement effectif = CE − liquidités − créances = " .. m(v.ce) .. " − " .. m(v.liq) .. " − " .. m(v.cre) .. " = " .. m(v.ee))
     end
     return v.ee, v.cf, m(v.ee) .. " ÷ " .. m(v.cf)
   end,
   comm = function(r)
     if r <= 0 then return d2(r) .. " : endettement effectif négatif, liquidités et créances couvrent toutes les dettes." end
     if r <= 3 then return d2(r) .. " : très bon (entre 1 et 3) ; grande sécurité pour les prêteurs." end
     if r <= 5 then return d2(r) .. " : acceptable (entre 3 et 5)." end
     return string.format("%s : largement insuffisant (> 5) ; il faudrait plus de %d ans à l'entreprise pour rembourser ses dettes avec le cash flow qu'elle dégage (57.22).", d2(r), math.floor(r))
   end, src = "57 p.62 · modèle 57.22 (12.6)"},
  {id = "roi", nom = "Rendement des capitaux investis (ROI)", u = "%", ex = "COL", champs = {"ebit", "tot", "tot1"}, fam = "Rentabilité",
   formule = "EBIT × 100 ÷ Total moyen des bilans",
   calc = function(v) local mo = F.moy(v, "tot", "actifs (total des bilans)"); return v.ebit, mo, m(v.ebit) .. " × 100 ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = p2(r) .. " : rentabilité de l'ensemble des capitaux investis (propres et étrangers), avant intérêts"
     if v.chf and v._m.ce then
       local t = v.chf * 100 / v._m.ce
       s = s .. string.format(" ; supérieure au taux d'intérêt moyen (%s) : l'endettement est rentable", p2(t))
       if r < t then s = p2(r) .. string.format(" : rentabilité des capitaux investis inférieure au taux d'intérêt moyen (%s) : l'endettement coûte plus qu'il ne rapporte", p2(t)) end
     else s = s .. " ; à comparer au taux d'intérêt des dettes et au rendement d'un placement sans risque" end
     return s .. "."
   end, src = "51 p.41-42 (PDF 45-46) · modèle 51.25 (7.44 %)"},
  {id = "roe", nom = "Rendement des fonds propres (ROE)", u = "%", ex = "COL", champs = {"bn", "fp", "fp1"}, fam = "Rentabilité",
   formule = "BN × 100 ÷ Total moyen des capitaux propres",
   calc = function(v) local mo = F.moy(v, "fp", "capitaux propres"); return v.bn, mo, m(v.bn) .. " × 100 ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = p2(r) .. " : rémunération des actionnaires, à comparer au rendement d'un placement sans risque"
     if v._r.roi then
       if r > v._r.roi then s = s .. string.format(" ; ROE > ROI (%s) : l'endettement a un effet de levier positif", p2(v._r.roi))
       else s = s .. string.format(" ; ROE ≤ ROI (%s) : pas d'effet de levier positif", p2(v._r.roi)) end
     end
     return s .. "."
   end, src = "51 p.42 · modèle 51.25 (9.37 %)"},
  {id = "rota", nom = "Rotation de l'actif (hors test)", u = "x", ex = "COL", champs = {"can", "tot", "tot1"}, fam = "Rentabilité",
   formule = "CAN ÷ Moyenne des actifs",
   calc = function(v) local mo = F.moy(v, "tot", "actifs (total des bilans)"); return v.can, mo, m(v.can) .. " ÷ " .. m(mo) end,
   comm = function(r, v)
     local s = string.format("%.5f fois : chaque franc d'actif génère %s CHF de CA", r, d2(r))
     if v.ebit and v.can then
       local tme = v.ebit * 100 / v.can
       s = s .. string.format(". Décomposition (DuPont) : ROI = taux de marge économique × rotation de l'actif = %.4f %% × %.5f = %s", tme, r, p2(tme * r))
       s = s .. (r >= 3 and " ; c'est la rotation élevée qui explique le ROI, la marge EBIT est plutôt faible (51.27)" or
         (r < 1.5 and " ; rotation faible : c'est la marge EBIT qui porte le ROI (51.28)" or ""))
     end
     return s .. "."
   end, src = "51.27, 51.28 · décomposition du ROI : hors périmètre du 12.11"},
  {id = "levier", nom = "Effet de levier (hors test)", u = "pt", ex = "COL", champs = {"ebit", "chf", "tot", "tot1", "fp", "fp1"}, fam = "Rentabilité",
   formule = "(ROI − t) × ø CE ÷ ø FP",
   calc = function(v)
     local roi = F.val(v, "roi", true)
     local mce = F.moy(v, "ce", "capitaux étrangers")
     local mfp = F.moy(v, "fp", "capitaux propres")
     if not F.ok(roi, mce, mfp, v.chf) or mce == 0 or mfp == 0 then return nil end
     local t = v.chf * 100 / mce
     v._t = t
     X(string.format("t = charges financières × 100 ÷ ø CE = %s × 100 ÷ %s = %.4f %%", m(v.chf), m(mce), t))
     return {r = (roi - t) * mce / mfp}, nil, string.format("(%.4f %% − %.4f %%) × %s ÷ %s", roi, t, m(mce), m(mfp))
   end,
   comm = function(r, v)
     local roi = v._r.roi
     local s = string.format("ROE = ROI + effet de levier = %.4f %% + %.4f %% = %s. ", roi, r, p2(roi + r))
     if r > 0 then
       s = s .. "Le différentiel (ROI − t) est favorable : chaque franc emprunté rapporte plus qu'il ne coûte"
       s = s .. (r > roi and " ; la rentabilité des fonds propres est avant tout due à l'effet de levier (51.28)." or
         " ; la rentabilité des fonds propres est avant tout due à la rentabilité des capitaux investis, l'effet de levier est faible mais pourrait augmenter avec plus de fonds étrangers (51.27).")
     else s = s .. "Effet de levier négatif : les dettes coûtent plus qu'elles ne rapportent ; s'endetter fait baisser le ROE." end
     return s .. " Un effet de levier positif peut vite devenir négatif si la rentabilité baisse ou si les taux montent."
   end, src = "51.27, 51.28 · effet de levier : hors périmètre du 12.11"},
}
local RID = {}
for i, d in ipairs(RAT) do RID[d.id] = d; d.no = i end
-- libellés courts pour les grilles (écran de 318 px : 22 caractères au plus)
local COURT = {liq1 = "Liquidité 1", liq2 = "Liquidité 2", liq3 = "Liquidité 3", iac = "Intensité AC", iai = "Intensité AI",
  ["end"] = "Endettement", fp = "Financement propre", auto = "Autofinancement", couv1 = "Couverture 1", couv2 = "Couverture 2",
  tmb = "Taux marge brute", tme = "Taux marge écon.", tmn = "Taux marge nette", rotcli = "Rotation clients", durcli = "Durée crédits accordés",
  rotfrs = "Rotation fournisseurs", durfrs = "Durée crédits obtenus", rotsto = "Rotation stocks", dursto = "Durée stocks",
  rinv = "Ratio d'investissement", mcf = "Marge de cash flow", fend = "Facteur d'endettement", roi = "ROI", roe = "ROE",
  rota = "Rotation actif (HT)", levier = "Effet levier (HT)"}
-- abréviations des tableaux comparatifs compacts (premier écran) ; légende : F.legende(ids)
local ABR = {liq1 = "Liq. 1", liq2 = "Liq. 2", liq3 = "Liq. 3", iac = "Int. AC", iai = "Int. AI", ["end"] = "Endett.", fp = "Fin. propre",
  auto = "Autofin.", couv1 = "Couv. 1", couv2 = "Couv. 2", tmb = "TMB", tme = "TME", tmn = "TMN", rotcli = "Rot. cli.",
  durcli = "Durée cli.", rotfrs = "Rot. fourn.", durfrs = "Durée fourn.", rotsto = "Rot. stocks", dursto = "Durée stocks",
  rinv = "Invest.", mcf = "Marge CF", fend = "Fact. endett.", roi = "ROI", roe = "ROE", rota = "Rot. actif HT", levier = "Levier HT"}
-- {ids concernés, texte de légende} dans l'ordre d'affichage
local LEG = {{{"liq1", "liq2", "liq3"}, "Liq. = liquidité"}, {{"iac", "iai"}, "Int. AC / AI = intensité des actifs circulants / immobilisés"},
  {{"end"}, "Endett. = degré d'endettement"}, {{"fp"}, "Fin. propre = degré de financement propre"}, {{"auto"}, "Autofin. = degré d'autofinancement"},
  {{"couv1", "couv2"}, "Couv. = degré de couverture des AI"}, {{"tmb", "tme", "tmn"}, "TMB, TME, TMN = taux de marge brute, économique, nette"},
  {{"rotcli", "durcli", "rotfrs", "durfrs", "rotsto", "dursto", "rota"}, "Rot. = rotation, cli. = clients, fourn. = fournisseurs (durée en jours)"},
  {{"rinv"}, "Invest. = ratio d'investissement"}, {{"mcf"}, "Marge CF = marge de cash flow"}, {{"fend"}, "Fact. endett. = facteur d'endettement"},
  {{"roi", "roe"}, "ROI, ROE = rentabilité des capitaux investis, des fonds propres"}, {{"rota", "levier"}, "HT = hors test"}}
function F.legende(ids)
  local pres, t = {}, {}
  for _, id in ipairs(ids) do pres[id] = true end
  for _, g in ipairs(LEG) do
    local ok = false
    for _, id in ipairs(g[1]) do if pres[id] then ok = true end end
    if ok then table.insert(t, g[2]) end
  end
  return table.concat(t, " · ")
end

-- durées : 360 ÷ rotation arrondie à 2 décimales (le prof divise par la rotation arrondie : 51.24, 360 ÷ 5.19 = 69.36)
for _, d in ipairs(RAT) do
  if d.rot then
    d.calc = function(v)
      local rt = F.val(v, d.rot, true)
      if not rt then return nil end
      return 360, r2(rt), "360 ÷ " .. d2(r2(rt))
    end
  end
end

function F.res(d, r)
  if d.u == "%" then return p2(r) .. (d.dec and ("   (ou " .. d2(r / 100) .. ")") or "") end
  if d.u == "x" then return d2(r) .. " fois" end
  if d.u == "j" then return d2(r) .. " jours" end
  if d.u == "pt" then return string.format("%.4f %%", r) end
  return d2(r)
end
function F.court(d, r)
  if not r then return "—" end
  if d.u == "%" or d.u == "pt" then return p2(r) end
  if d.u == "j" then return string.format("%.1f j", r) end
  return d2(r)
end

-- valeur d'un ratio (sans commentaire) ; avecLigne : écrit « Nom = application = résultat » sur une ligne
function F.val(v, id, avecLigne)
  if v._r[id] then return v._r[id] end
  local d = RID[id]
  local n, den, app = d.calc(v)
  local r
  if type(n) == "table" then r = n.r
  else
    if not F.ok(n, den) or den == 0 then return nil end
    r = n / den; if d.u == "%" then r = r * 100 end
  end
  v._r[id] = r
  if avecLigne then X(d.nom .. " = " .. app .. " = " .. F.res(d, r)) end
  return r
end

-- affichage complet : formule [R], application numérique, résultat, commentaire
function F.aff(d, v, sansComm)
  local n, den, app = d.calc(v)
  local r
  if type(n) == "table" then r = n.r
  else
    if not F.ok(n, den) then A(d.nom .. " : données manquantes (" .. table.concat(d.champs, ", ") .. ")"); return nil end
    if den == 0 then A(d.nom .. " : dénominateur nul"); return nil end
    r = n / den; if d.u == "%" then r = r * 100 end
  end
  v._r[d.id] = r
  COMMUN.calc(d.nom, d.formule, app, F.res(d, r))
  if not sansComm and d.comm then X("Commentaire : " .. d.comm(r, v)) end
  return r
end

-- famille de ratios du bilan (1 à 10) + FRN + commentaires de synthèse
function F.ratiosBilan(v)
  T("Liquidité")
  for _, id in ipairs({"liq1", "liq2", "liq3"}) do F.aff(RID[id], v) end
  X("Commentaire (liquidité) : " .. F.synthLiq(v._r.liq1, v._r.liq2, v._r.liq3))
  F.frn(v)
  T("Structure de l'actif")
  F.aff(RID.iac, v); F.aff(RID.iai, v)
  T("Financement")
  F.aff(RID["end"], v); F.aff(RID.fp, v)
  if v.cc then F.aff(RID.auto, v) else G("Degré d'autofinancement : capital de croissance non saisi (cc = réserves issues du bénéfice + bénéfice reporté).") end
  X("Commentaire (financement) : " .. F.synthFin(v._r["end"]))
  T("Couverture des immobilisations")
  F.aff(RID.couv1, v); F.aff(RID.couv2, v)
  X("Commentaire (couverture) : " .. F.synthCouv(v._r.couv1, v._r.couv2, v._r.iai, v._r["end"]))
end

function F.frn(v)
  if not F.ok(v.ac, v.ct, v.fp, v.lt, v.ai) then return end
  local a, b = v.ac - v.ct, v.fp + v.lt - v.ai
  COMMUN.calc("FRN", "Actifs circulants − CE à court terme", m(v.ac) .. " − " .. m(v.ct), m(a))
  COMMUN.calc("FRN", "(Capitaux propres + CE à long terme) − Actifs immobilisés", m(v.fp) .. " + " .. m(v.lt) .. " − " .. m(v.ai), m(b))
  if math.abs(a - b) > 0.5 then A("Les deux calculs du FRN diffèrent : le bilan n'est pas équilibré.") end
  X("Commentaire (FRN) : " .. (a >= 0 and "FRN positif, la situation est favorable : les capitaux permanents financent toutes les immobilisations et une partie de l'actif circulant (51 p.12)."
    or "FRN négatif : une partie des immobilisations est financée par des dettes à court terme ; la règle d'or n'est pas respectée (51 p.12)."))
end

------------------------------------------------------------------ bilan structuré
function F.grilleBilan(v, deux)
  local function L(lib, k, o)
    local l = {lib, m(v[k])}
    if deux then l[3] = m(v[k .. "1"]) end
    for kk, vv in pairs(o or {}) do l[kk] = vv end
    return l
  end
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    if F.ok(v["ce" .. s], v["fp" .. s]) then v["pas" .. s] = v["ce" .. s] + v["fp" .. s] end
  end
  GRILLE("Bilan structuré", {
    L("Liquidités", "liq", {retrait = 1}), L("Créances", "cre", {retrait = 1}), L("Stocks", "sto", {retrait = 1}),
    L("Actifs circulants", "ac", {gras = true}), L("Actifs immobilisés", "ai", {gras = true}),
    L("Total de l'actif", "tot", {gras = true, trait = true, fond = true}),
    L("CE à court terme", "ct", {retrait = 1}), L("CE à long terme", "lt", {retrait = 1}),
    L("Capitaux étrangers", "ce", {gras = true}), L("Capitaux propres", "fp", {gras = true}),
    L("dont cap. croissance", "cc", {retrait = 1}),
    L("Total du passif", "pas", {gras = true, trait = true, fond = true}),
  }, {entetes = deux and {"", "N", "N-1"} or {"", "Montant"}})
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    if F.ok(v["tot" .. s], v["pas" .. s]) and math.abs(v["tot" .. s] - v["pas" .. s]) > 0.5 then
      A("Bilan " .. (s == "" and "N" or "N-1") .. " déséquilibré : actif " .. m(v["tot" .. s]) .. " ≠ passif " .. m(v["pas" .. s]) .. ". Vérifier la saisie.")
    end
  end
end

------------------------------------------------------------------ composition chiffrée des postes agrégés
local POSTES = {
  {"liq", "Liquidités", "caisse + poste + banque + titres à court terme"},
  {"cre", "Créances", "créances clients − ducroire + autres créances à c.t."},
  {"sto", "Stocks", "marchandises (+ acomptes aux fournisseurs − acomptes de clients)"},
  {"ai", "Actifs immobilisés", "mobilier + machines + véhicules + immeubles + brevets + participations"},
  {"ct", "CE à court terme", "dettes fournisseurs + dividendes à payer + dettes bancaires à c.t. + autres dettes à c.t."},
  {"lt", "CE à long terme", "prêts et emprunts à long terme + hypothèques + provisions à l.t."},
  {"fp", "Capitaux propres", "capital-actions + réserves + bénéfice reporté"},
  {"cc", "Capital de croissance", "réserves issues du bénéfice + bénéfice reporté"},
}
function F.postes(v, deux)
  T("Postes du bilan (composition)")
  G("Chaque poste agrégé est la somme des comptes de l'énoncé (51 p.4) ; une somme saisie (ex. 35600+292979) est réécrite ici. Puis les sous-totaux du bilan structuré.")
  for _, s in ipairs(deux and {"", "1"} or {""}) do
    local an = s == "" and "" or " N-1"
    if deux then X(s == "" and "Année N :" or "Année N-1 :") end
    for _, p in ipairs(POSTES) do
      local k = p[1] .. s
      local val, t = v[k], v._txt and v._txt[k]
      if val then
        X(p[2] .. an .. " = " .. p[3])
        local app = (t and COMMUN.estExpr(t)) and (COMMUN.exprTexte(t) .. " = " .. m(val)) or (m(val) .. " (montant saisi)")
        if #app <= 44 then R("  = ", "", app) else X("  = " .. app) end   -- R ne coupe pas les lignes
      end
    end
    local liq, cre, sto, ai, ct, lt, fp = v["liq" .. s], v["cre" .. s], v["sto" .. s], v["ai" .. s], v["ct" .. s], v["lt" .. s], v["fp" .. s]
    if F.ok(liq, cre, sto) then
      X("Actifs circulants" .. an .. " = liquidités + créances + stocks = " .. m(liq) .. " + " .. m(cre) .. " + " .. m(sto) .. " = " .. m(liq + cre + sto))
    end
    if F.ok(v["ac" .. s], ai) then X("Total de l'actif" .. an .. " = AC + AI = " .. m(v["ac" .. s]) .. " + " .. m(ai) .. " = " .. m(v["ac" .. s] + ai)) end
    if F.ok(ct, lt) then X("Capitaux étrangers" .. an .. " = CE ct + CE lt = " .. m(ct) .. " + " .. m(lt) .. " = " .. m(ct + lt)) end
    if F.ok(v["ce" .. s], fp) then X("Total du passif" .. an .. " = CE + capitaux propres = " .. m(v["ce" .. s]) .. " + " .. m(fp) .. " = " .. m(v["ce" .. s] + fp)) end
  end
end

-- conclusion rédigée : points forts, points faibles, appréciation d'ensemble (à partir des ratios déjà calculés dans v._r)
function F.conclusion(v)
  local r = v._r
  local fort, faible = {}, {}
  local function aj(t, s) table.insert(t, s) end
  if r.liq2 then
    if r.liq2 >= 100 then aj(fort, "dettes à court terme couvertes par liquidités et créances (liquidité 2 = " .. p2(r.liq2) .. " ≥ 100 %)")
    else aj(faible, "liquidités et créances insuffisantes pour payer les dettes à court terme (liquidité 2 = " .. p2(r.liq2) .. " < 100 %)") end
  end
  if r.liq1 then
    if r.liq1 > 30 then aj(faible, "excédent de liquidités qui ne rapportent rien (liquidité 1 = " .. p2(r.liq1) .. " > 30 %), sauf investissement prévu")
    elseif r.liq1 < 20 and not (r.liq2 and r.liq2 >= 100) then aj(faible, "manque de liquidités immédiates (liquidité 1 = " .. p2(r.liq1) .. " < 20 %)") end
  end
  if r.liq3 and r.liq3 < 100 then aj(faible, "FRN négatif (liquidité 3 = " .. p2(r.liq3) .. " < 100 %)") end
  if r["end"] then
    if r["end"] < 50 then aj(fort, "endettement faible (" .. p2(r["end"]) .. "), risque réduit")
    elseif r["end"] > 70 then aj(faible, "surendettement (" .. p2(r["end"]) .. "), vulnérable en cas de perte") end
  end
  if r.couv2 then
    if r.couv2 >= 100 then aj(fort, "règle d'or respectée (couverture 2 = " .. p2(r.couv2) .. ")")
    else aj(faible, "règle d'or non respectée (couverture 2 = " .. p2(r.couv2) .. " < 100 %)") end
  end
  if r.couv1 and r.couv1 < 60 then aj(faible, "immobilisations trop peu financées par les fonds propres (couverture 1 = " .. p2(r.couv1) .. " < 60 %)") end
  if r.roi and r.roe then
    if r.roe > r.roi then aj(fort, "ROE (" .. p2(r.roe) .. ") supérieur au ROI (" .. p2(r.roi) .. ") : l'endettement profite aux actionnaires")
    else aj(faible, "ROE (" .. p2(r.roe) .. ") pas supérieur au ROI (" .. p2(r.roi) .. ")") end
  end
  if r.tme and r.tme < 3 then aj(faible, "marge économique faible (" .. p2(r.tme) .. " du CA)") end
  if r.fend and r.fend > 5 then aj(faible, "facteur d'endettement de " .. d2(r.fend) .. " (> 5)") end
  if r.durcli and v.dcl and r.durcli > v.dcl then aj(faible, "clients en retard de paiement (" .. d2(r.durcli) .. " j > " .. m(v.dcl) .. " j)") end
  T("Conclusion")
  if #fort > 0 then X("Points forts : " .. table.concat(fort, " ; ") .. ".") end
  if #faible > 0 then X("Points faibles ou à surveiller : " .. table.concat(faible, " ; ") .. ".") end
  local grave = (r.liq2 and r.liq2 < 100 and r.liq3 and r.liq3 < 100) or (r["end"] and r["end"] > 70) or (r.couv2 and r.couv2 < 100)
  local s
  if grave then s = "Situation financière fragile : à corriger en priorité (encaisser les créances, obtenir des capitaux permanents, réduire l'endettement)."
  elseif #faible == 0 then s = "Situation financière saine : l'entreprise peut payer ses dettes et finance correctement ses immobilisations."
  else s = "Situation financière globalement saine, avec les points à surveiller ci-dessus." end
  X("Appréciation : " .. s)
end

------------------------------------------------------------------ 1. analyse complète
local CH_ANA = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc", "liq1", "cre1", "sto1", "ai1", "ct1", "lt1", "fp1", "cc1",
  "can", "cac", "pramv", "prama", "bn", "chf", "pf", "imp", "amo", "ebit", "frs", "frs1", "cf", "inv", "dcl", "dfo"}
local EX_ANA = {liq = "35600+292979", cre = 528920, sto = 459822, ai = "305000+106000+100000", ct = 202540, lt = "55000+280992",
  fp = "1000000+284000+5789", cc = "284000+5789",
  liq1 = "14560+48250", cre1 = 450622, sto1 = 368930, ai1 = "365000+146000+120000", ct1 = 125654, lt1 = "40000+120800",
  fp1 = "1000000+218000+8908", cc1 = "218000+8908",
  can = 8432560, pramv = 5059536, bn = 117881, chf = 6480, pf = 0, imp = 0, amo = 125000}

function F.analyse(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_ANA, EX_ANA)))
  local deux = v.liq1 ~= nil
  vider()
  T("Analyse complète du bilan et du résultat")
  G("Méthode : bilan structuré (liquidités, créances, stocks | AI ; CE ct, CE lt, FP), puis les 26 ratios de la liste Profil M, chacun avec la formule, l'application numérique, le résultat (en % et en décimal) et un commentaire : valeur, valeur indicative du manuel, conséquence pour l'entreprise. Les ratios du bilan portent sur l'année N ; rotations et rentabilités utilisent les moyennes (N-1 + N) ÷ 2.")
  G("Par défaut : Colibri SA (51.25, corrigé : EBIT 124'361, ROI 7.44 %, ROE 9.37 % ; 51.27 : levier 1.9249 %). Dividendes laissés en CE l.t. comme dans le bilan du prof.")
  F.grilleBilan(v, deux)
  F.postes(v, deux)
  if v.can then
    local l = {{"CA net", m(v.can)}, {"./. PRAMV", m(v.pramv and -v.pramv)}, {"Marge brute", m(v.mb), gras = true, trait = true}}
    table.insert(l, {"EBIT", m(v.ebit), gras = true})
    table.insert(l, {"./. Charges financières", m(-(v.chf or 0))})
    if (v.pf or 0) ~= 0 then table.insert(l, {"+ Produits financiers", m(v.pf)}) end
    if (v.imp or 0) ~= 0 then table.insert(l, {"./. Impôts", m(-v.imp)}) end
    table.insert(l, {"Bénéfice net", m(v.bn), gras = true, trait = true, fond = true})
    GRILLE("Compte de résultat (résumé)", l, {entetes = {"", "N"}})
  end
  if #v._auto > 0 then
    T("Valeurs déduites")
    for _, s in ipairs(v._auto) do X(s) end
  end
  F.ratiosBilan(v)
  local fam = ""
  for i = 11, #RAT do
    local d = RAT[i]
    if d.fam ~= fam then
      fam = d.fam; T(fam)
      if fam == "Cash flow (chap. 57)" then G("Ratios du chap. 57 (test de janvier) ; cash flow et investissements nets reconstitués s'ils ne sont pas saisis.") end
    end
    F.aff(d, v)
  end
  if F.ok(v.cf, v.inv) then
    COMMUN.calc("Free cash flow", "Cash flow − Investissements nets", m(v.cf) .. " − " .. m(v.inv), m(v.cf - v.inv))
    X("Commentaire : " .. (v.cf - v.inv >= 0 and "free cash flow positif : marge de manœuvre pour rembourser des dettes ou verser un dividende."
      or "free cash flow négatif : aucune marge de manœuvre pour rembourser des dettes ou verser un dividende exceptionnel (57.22)."))
  end
  F.conclusion(v)
  -- tableau des 26 ratios en tête du document (juste sous le titre) : 2 tableaux compacts de 13 lignes, chacun sur un écran
  local l, ids = {}, {}
  local v1
  if deux then
    v1 = F.deriver({liq = v.liq1, cre = v.cre1, sto = v.sto1, ai = v.ai1, ct = v.ct1, lt = v.lt1, fp = v.fp1, cc = v.cc1})
  end
  for i, d in ipairs(RAT) do
    local ligne = {ABR[d.id], F.court(d, v._r[d.id])}
    if deux then ligne[3] = (i <= 10) and F.court(d, F.val(v1, d.id)) or "" end
    table.insert(l, ligne); table.insert(ids, d.id)
  end
  GRILLE("Les 26 ratios", l, {entetes = deux and {"", "N", "N-1"} or {"", "N"}, compact = true, pos = 2,
    legende = F.legende(ids) .. ". N-1 : ratios du bilan seulement. Détail (formule, application, commentaire) plus bas. Liste des ratios 2018 Profil M · normes : 51 p.11-13 (PDF) · cash flow : 57 p.62."})
  montrer("Analyse complète")
end

------------------------------------------------------------------ 2. ratios du bilan, une année (test 2025 ex. 3)
local CH_BIL = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc"}
function F.bilan(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_BIL, EX.T25)))
  vider()
  T("Ratios du bilan (une année)")
  G("Méthode : classer le bilan en liquidités, créances, stocks, AI | CE ct, CE lt, FP (garder le classement de l'énoncé : en 2025, dividendes en CE l.t.), choisir la bonne année, puis formule, application, résultat et commentaire (2 pts par commentaire). Modèle : test 2025 ex. 3 (14.44 % · 118.89 % · 216.67 % · 1.28 · 1.75).")
  G("Par défaut : test 2025 ex. 3, colonne 2026 ; capital de croissance = réserves 250 + bénéfice reporté 20 (hypothèse : réserves issues du bénéfice).")
  F.grilleBilan(v, false)
  F.postes(v, false)
  F.ratiosBilan(v)
  F.conclusion(v)
  montrer("Ratios du bilan")
end

------------------------------------------------------------------ 3. comparer des entreprises (test 2025 ex. 5, 51.8)
-- deux entrées : à partir des bilans (F.comparer) ou des ratios déjà calculés (F.comparerRatios) ; même analyse (F.cmpRendu).
-- Ratios du bilan en décimal comme le corrigé du prof (0.82) ; rentabilités et marges en %.
local CMP_IDS = {"liq1", "liq2", "liq3", "iai", "end", "fp", "couv1", "couv2", "roi", "roe", "tmb", "tme", "tmn"}
local CMP_PCT = {roi = true, roe = true, tmb = true, tme = true, tmn = true}
local CMP_AIDE = {
  liq1 = "Liquidité 1 = liquidités ÷ CE à court terme. Valeur indicative 0.2 à 0.3.",
  liq2 = "Liquidité 2 = (liquidités + créances) ÷ CE à court terme. Valeur indicative ≥ 1 (le ratio le plus important).",
  liq3 = "Liquidité 3 = actifs circulants ÷ CE à court terme. Valeur indicative 1.5 à 2 ; < 1 = FRN négatif.",
  iai = "Intensité des actifs immobilisés = AI ÷ total du bilan. Pas de norme : élevée = charges fixes importantes.",
  ["end"] = "Degré d'endettement = capitaux étrangers ÷ total du passif. Repères des corrigés : 0.40 faible, 0.56 dans la norme, 0.82 surendettée.",
  fp = "Degré de financement propre = capitaux propres ÷ total du passif (= 1 − endettement). Idéal bancaire ≥ 0.5.",
  couv1 = "Degré de couverture 1 = capitaux propres ÷ AI. Valeur indicative 0.6 à 0.8.",
  couv2 = "Degré de couverture 2 = (capitaux propres + CE à long terme) ÷ AI. Règle d'or : ≥ 1.",
  roi = "ROI = EBIT ÷ total moyen des bilans. Facultatif.",
  roe = "ROE = bénéfice net ÷ capitaux propres moyens. Facultatif.",
  tmb = "Taux de marge brute = marge brute ÷ CAN. Facultatif.",
  tme = "Taux de marge économique = EBIT ÷ CAN. Facultatif.",
  tmn = "Taux de marge nette = bénéfice net ÷ CAN. Facultatif.",
}
local FORMAT_R = " En décimal (0.82) ou en % (82%) ; un nombre > 10 (ratios du bilan) ou ≥ 1 (rentabilités, marges) est lu comme un %. Vide = ignoré."
local DEF_NOMS = {"Bouvier", "Corgi", "Husky", "E4", "E5"}
-- corrigé du prof (test 2025 ex. 5) ; fp et couv1 : calculés depuis les bilans de l'énoncé (non demandés en 2025)
local DEF_RAT = {
  {liq1 = "0.82", liq2 = "0.95", liq3 = "2.27", iai = "0.5", ["end"] = "0.4", fp = "0.6", couv1 = "1.2", couv2 = "1.56"},
  {liq1 = "0.26", liq2 = "0.97", liq3 = "1", iai = "0.62", ["end"] = "0.58", fp = "0.42", couv1 = "0.68", couv2 = "1.00"},
  {liq1 = "0.17", liq2 = "0.75", liq3 = "1.27", iai = "0.24", ["end"] = "0.82", fp = "0.18", couv1 = "0.75", couv2 = "1.67"},
}
-- bilans de l'énoncé (test 2025 ex. 5) : liquidités, créances, stocks, AI, CE ct, CE lt, capitaux propres, [capital de croissance]
local CMP_K = {"liq", "cre", "sto", "ai", "ct", "lt", "fp", "cc"}
local DEF_BIL = {{"18", "3", "29", "50", "22", "18", "60", ""}, {"10", "27", "1", "62", "38", "20", "42", ""}, {"10", "35", "31", "24", "60", "22", "18", ""}}
local DEF_CMP = "Bouvier: 18 3 29 50 22 18 60 / Corgi: 10 27 1 62 38 20 42 / Husky: 10 35 31 24 60 22 18"

function F.defRatios()
  local seg = {}
  for j, d in ipairs(DEF_RAT) do
    local t = {}
    for _, id in ipairs(CMP_IDS) do if d[id] then table.insert(t, id .. "=" .. d[id]) end end
    table.insert(seg, DEF_NOMS[j] .. ": " .. table.concat(t, ";"))
  end
  return table.concat(seg, " / ")
end

-- 82 -> 0.82 pour un ratio du bilan ; 9.37 -> 0.0937 pour une rentabilité
function F.normR(id, x)
  if not x then return nil end
  if CMP_PCT[id] then if math.abs(x) >= 1 then return x / 100 end
  elseif math.abs(x) > 10 then return x / 100 end
  return x
end

-- coupe un nom à n caractères (UTF-8) pour les en-têtes de colonnes
function F.tronquer(s, n)
  local out, k = "", 0
  for ch in tostring(s):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    k = k + 1
    if k > n then return out end
    out = out .. ch
  end
  return out
end

local NIV_LIQ = {[0] = "risque d'insolvabilité", "liquidité tendue", "liquidité juste suffisante", "aucun problème de paiement"}
local NIV_LIQC = {[0] = "critique", "tendue", "juste", "bonne"}
local NIV_FIN = {[0] = "structure de financement fragile", "structure de financement correcte", "structure de financement solide"}
local NIV_FINC = {[0] = "fragile", "correcte", "solide"}

-- appréciation de la liquidité (ratios en décimal) : phrases (tournures du corrigé 51.8) et niveau 0 à 3
function F.cmpLiq(r)
  local l1, l2, l3 = r.liq1, r.liq2, r.liq3
  local p = {}
  if l1 then
    if l1 > 0.3 then table.insert(p, "liquidité 1 = " .. d2(l1) .. " > 0.3 : nettement en excédent de liquidités ; peut-être est-ce volontaire (achat d'une autre entreprise, investissements importants à venir), sinon c'est de l'argent qui ne rapporte rien")
    elseif l1 >= 0.2 then table.insert(p, "liquidité 1 = " .. d2(l1) .. " : assez dans la norme (entre 0.2 et 0.3)")
    else table.insert(p, "liquidité 1 = " .. d2(l1) .. " < 0.2 : en manque de liquidités immédiates") end
  end
  if l2 then
    if l2 >= 1 then table.insert(p, "liquidité 2 = " .. d2(l2) .. " ≥ 1 : liquidités et créances couvrent les dettes à court terme")
    elseif l2 >= 0.9 then table.insert(p, "liquidité 2 = " .. d2(l2) .. ", juste sous 1 : liquidités et créances couvrent presque les dettes à court terme")
    else table.insert(p, "liquidité 2 = " .. d2(l2) .. " < 1 : liquidités et créances ne suffisent pas à payer les dettes à court terme ; il faudra vendre du stock ou obtenir un crédit") end
  end
  if l3 then
    if l3 >= 1.5 then table.insert(p, "liquidité 3 = " .. d2(l3) .. " > 1.5 : avec les stocks, les dettes à court terme sont largement couvertes")
    elseif l3 >= 1 then
      if l2 and l3 - l2 < 0.1 then table.insert(p, "liquidité 3 = " .. d2(l3) .. ", sous 1.5 et à peine au-dessus de la liquidité 2 : presque pas de stock pour compléter")
      else table.insert(p, "liquidité 3 = " .. d2(l3) .. ", entre 1 et 1.5 : les dettes à court terme ne sont couvertes que si le stock se vend") end
    else table.insert(p, "liquidité 3 = " .. d2(l3) .. " < 1 : même en vendant tout son stock, l'entreprise ne peut pas payer ses dettes à court terme (FRN négatif)") end
  end
  local n
  if l3 and l3 < 1 then n = 0
  elseif l2 and l2 < 0.9 then n = 1
  elseif (l2 and l2 >= 1) or (l3 and l3 >= 1.5) then n = 3
  elseif l2 or l3 then n = 2
  elseif l1 then n = l1 >= 0.2 and 2 or 1 end
  return p, n
end

-- appréciation de la structure de financement : phrases et niveau 0 à 2
function F.cmpFin(r)
  local e, f, i, c1, c2 = r["end"], r.fp, r.iai, r.couv1, r.couv2
  local p = {}
  if e then
    if e < 0.5 then table.insert(p, "degré d'endettement = " .. d2(e) .. " : endettement faible, l'entreprise se finance avant tout par des fonds propres ; les risques sont moindres, mais cela va compromettre la rentabilité des fonds propres")
    elseif e <= 0.7 then table.insert(p, "degré d'endettement = " .. d2(e) .. " : un financement qui correspond assez à la norme (51.8 : 0.56)")
    else table.insert(p, "degré d'endettement = " .. d2(e) .. " : l'entreprise est surendettée, très dépendante de ses créanciers et vulnérable en cas de perte ; ses charges financières sont élevées") end
  end
  if f then
    local s = "financement propre = " .. d2(f) .. (f >= 0.5 and " ≥ 0.5 (idéal bancaire) : indépendance envers les bailleurs de fonds"
      or (f >= 0.3 and ", dans la moyenne (environ 0.3) mais sous l'idéal bancaire de 0.5" or " : faible, peu de réserve pour absorber des pertes"))
    if e and math.abs(e + f - 1) > 0.02 then s = s .. " (attention : endettement + financement propre ≠ 1, vérifier la saisie)" end
    table.insert(p, s)
  end
  if i then
    if i >= 0.6 then table.insert(p, "intensité des AI = " .. d2(i) .. " : beaucoup d'immobilisations, donc des charges fixes importantes (amortissements, entretien)")
    elseif i < 0.3 then table.insert(p, "intensité des AI = " .. d2(i) .. " : peu d'immobilisations (commerce, services), peu de charges fixes")
    else table.insert(p, "intensité des AI = " .. d2(i) .. " : immobilisations moyennes") end
  end
  if c1 then
    if c1 >= 1 then table.insert(p, "couverture 1 = " .. d2(c1) .. " ≥ 1 : les immobilisations sont entièrement payées par les fonds propres")
    elseif c1 > 0.8 then table.insert(p, "couverture 1 = " .. d2(c1) .. " > 0.8 : les immobilisations sont largement payées par les fonds propres")
    elseif c1 >= 0.6 then table.insert(p, "couverture 1 = " .. d2(c1) .. " : dans la norme (0.6 à 0.8), immobilisations financées surtout par les fonds propres")
    else table.insert(p, "couverture 1 = " .. d2(c1) .. " < 0.6 : les immobilisations dépendent des capitaux étrangers") end
  end
  local n
  if (e and e > 0.7) or (c2 and r2(c2) < 1) then n = 0
  elseif (e or c2) and (not e or e <= 0.5) and (not c2 or r2(c2) > 1) then n = 2
  elseif e or c2 then n = 1 end
  return p, n
end

-- règle d'or (couverture 2) ; nil si non saisie
function F.cmpOr(r)
  local c2 = r.couv2
  if not c2 then return nil end
  local s
  if r2(c2) > 1 then s = "couverture 2 = " .. d2(c2) .. " > 1 : règle d'or respectée, les immobilisations sont financées par des capitaux permanents (fonds propres + CE à long terme)"
  elseif r2(c2) == 1 then s = "couverture 2 = " .. d2(c2) .. " : tout juste à la limite de la règle d'or ; les capitaux permanents couvrent exactement les immobilisations, sans aucune marge (FRN nul)"
  else s = "couverture 2 = " .. d2(c2) .. " < 1 : règle d'or non respectée ; une partie des immobilisations est financée par des dettes à court terme, à rembourser avant que ces investissements ne rapportent" end
  if r2(c2) > 1 and r.iai and r.iai < 0.3 and r["end"] and r["end"] > 0.7 then
    s = s .. " ; mais elle n'est élevée que parce que les immobilisations sont faibles (intensité des AI = " .. d2(r.iai) .. "), alors que l'entreprise est très endettée"
  end
  return s
end

-- analyse complète d'un groupe d'entreprises : ents = {{nom = "…", r = {liq1 = 0.82, …}}, …}
-- tableau comparatif compact (ratios renseignés seulement), à placer juste sous le titre : pos = rang dans le document
function F.cmpTableau(ents, lignesSup, pos)
  local ent = {""}
  for _, e in ipairs(ents) do table.insert(ent, e.nom) end   -- la grille compacte tronque les noms à la largeur des colonnes
  local l, ids = {}, {}
  for _, id in ipairs(CMP_IDS) do
    local present = false
    for _, e in ipairs(ents) do if e.r[id] then present = true end end
    if present then
      local ligne = {ABR[id]}
      for _, e in ipairs(ents) do local x = e.r[id]; ligne[#ligne + 1] = x and (CMP_PCT[id] and p2(x * 100) or d2(x)) or "—" end
      table.insert(l, ligne); table.insert(ids, id)
    end
  end
  for _, x in ipairs(lignesSup or {}) do table.insert(l, x) end
  local leg = F.legende(ids)
  if lignesSup and #lignesSup > 0 then leg = leg .. " · FRN = fonds de roulement net (AC − CE ct)" end
  GRILLE("", l, {entetes = ent, compact = true, pos = pos, legende = leg .. ". Rentabilités et marges en %, autres ratios en décimal."})
end

function F.cmpRendu(ents)
  local n = #ents
  G("Valeurs indicatives (51 p.11-13) : liquidité 1 de 0.2 à 0.3 ; liquidité 2 ≥ 1 ; liquidité 3 de 1.5 à 2 ; couverture 1 de 0.6 à 0.8 ; couverture 2 ≥ 1 (règle d'or). Endettement, repères des corrigés 51.8 et 51.10 : 0.40 faible, 0.56 dans la norme, 0.82 surendetté.")

  local function classer(cle, ratio, desc)
    local t = {}
    for _, e in ipairs(ents) do if e[cle] then table.insert(t, e) end end
    table.sort(t, function(a, b)
      if a[cle] ~= b[cle] then return a[cle] > b[cle] end
      local x, y = a.r[ratio] or 0, b.r[ratio] or 0
      if desc then return x > y end
      return x < y
    end)
    return t
  end
  local function extreme(id, plusGrand)
    local best
    for _, e in ipairs(ents) do
      local x = e.r[id]
      if x and (not best or (plusGrand and x > best.r[id]) or (not plusGrand and x < best.r[id])) then best = e end
    end
    return best
  end

  -- a) liquidité
  T("a) Niveau de liquidité")
  G("Pour chaque entreprise : ratio, valeur indicative, conséquence (tournures du corrigé 51.8). Barème 2025 (hypothèse, BAREME.md §3) : 3 pts, soit 1 pt par entreprise.")
  for _, e in ipairs(ents) do
    local p, nl = F.cmpLiq(e.r)
    e.nl = nl
    if #p > 0 then X(e.nom .. " : " .. table.concat(p, " ; ") .. ". → " .. NIV_LIQ[nl] .. ".")
    else G(e.nom .. " : aucun ratio de liquidité saisi.") end
  end
  local tl = classer("nl", "liq2", true)
  if #tl >= 2 then
    local a, z = tl[1], tl[#tl]
    local s = a.nom .. " a la meilleure liquidité (" .. NIV_LIQ[a.nl] .. "), " .. z.nom .. " la plus faible (" .. NIV_LIQ[z.nl] .. ")"
    for k = 2, #tl - 1 do s = s .. " ; " .. tl[k].nom .. " se situe entre les deux (" .. NIV_LIQ[tl[k].nl] .. ")" end
    local hi, lo = extreme("liq2", true), extreme("liq2", false)
    if hi and lo and hi ~= lo then
      s = s .. ". La liquidité 2, le ratio le plus important, va de " .. d2(lo.r.liq2) .. " (" .. lo.nom .. ") à " .. d2(hi.r.liq2) .. " (" .. hi.nom .. ")"
    end
    local exc = {}
    for _, e in ipairs(ents) do if e.r.liq1 and e.r.liq1 > 0.3 then table.insert(exc, e.nom) end end
    if #exc > 0 then s = s .. ". " .. table.concat(exc, " et ") .. (#exc > 1 and " gardent" or " garde") .. " beaucoup de liquidités qui ne rapportent rien" end
    X("Comparaison : " .. s .. ".")
  end

  -- b) structure de financement
  T("b) Structure de financement")
  G("Endettement, financement propre, poids des immobilisations, couverture 1 (barème 2025, hypothèse : 3 pts, 1 pt par entreprise).")
  for _, e in ipairs(ents) do
    local p, nf = F.cmpFin(e.r)
    e.nf = nf
    if #p > 0 then X(e.nom .. " : " .. table.concat(p, " ; ") .. ". → " .. (nf and NIV_FIN[nf] or "à compléter avec la règle d'or") .. ".")
    else G(e.nom .. " : aucun ratio de financement saisi.") end
  end
  local tf = classer("nf", "end", false)
  if #tf >= 2 then
    local function det(e) return NIV_FIN[e.nf] .. (e.r["end"] and (", endettement " .. d2(e.r["end"])) or "") end
    local a, z = tf[1], tf[#tf]
    local s = a.nom .. " a la structure la plus sûre (" .. det(a) .. "), " .. z.nom .. " la plus risquée (" .. det(z) .. ")"
    for k = 2, #tf - 1 do s = s .. " ; " .. tf[k].nom .. " se situe entre les deux (" .. det(tf[k]) .. ")" end
    local im = extreme("iai", true)
    if im and im.r.iai >= 0.5 then s = s .. ". " .. im.nom .. " a le plus d'immobilisations (intensité " .. d2(im.r.iai) .. "), donc le plus de charges fixes" end
    X("Comparaison : " .. s .. ". Moins d'endettement = moins de risque, mais une rentabilité des fonds propres moins favorisée (51.8).")
  end

  -- c) règle d'or
  local ok, lim, non = {}, {}, {}
  local avecOr = false
  for _, e in ipairs(ents) do if e.r.couv2 then avecOr = true end end
  if avecOr then
    T("c) Règle d'or (couverture 2)")
    for _, e in ipairs(ents) do
      local s = F.cmpOr(e.r)
      if s then
        X(e.nom .. " : " .. s .. ".")
        local c = r2(e.r.couv2)
        table.insert(c > 1 and ok or (c == 1 and lim or non), e.nom)
      end
    end
    if n >= 2 then
      local t = {}
      if #ok > 0 then table.insert(t, "respectée par " .. table.concat(ok, ", ")) end
      if #lim > 0 then table.insert(t, "tout juste par " .. table.concat(lim, ", ")) end
      if #non > 0 then table.insert(t, "non respectée par " .. table.concat(non, ", ")) end
      X("Bilan : règle d'or " .. table.concat(t, " ; ") .. ".")
    end
  end

  -- d) rentabilité (facultatif)
  local avecRen = false
  for _, e in ipairs(ents) do for id in pairs(CMP_PCT) do if e.r[id] then avecRen = true end end end
  if avecRen then
    T("d) Rentabilité et marges")
    for _, e in ipairs(ents) do
      local t = {}
      for _, id in ipairs({"roe", "roi", "tmb", "tme", "tmn"}) do if e.r[id] then table.insert(t, COURT[id] .. " = " .. p2(e.r[id] * 100)) end end
      if #t > 0 then
        local s = e.nom .. " : " .. table.concat(t, ", ")
        if e.r.roe and e.r.roi then
          s = s .. (e.r.roe > e.r.roi and " ; ROE > ROI : l'endettement profite aux actionnaires (effet de levier positif, hors test)"
            or " ; ROE ≤ ROI : l'endettement ne profite pas aux actionnaires")
        end
        X(s .. ".")
      end
    end
    local b, nroe = extreme("roe", true), 0
    for _, e in ipairs(ents) do if e.r.roe then nroe = nroe + 1 end end
    if b and nroe >= 2 then X("Comparaison : " .. b.nom .. " rémunère le mieux ses actionnaires (ROE = " .. p2(b.r.roe * 100) .. ") ; à rapprocher de son endettement (le levier augmente le ROE mais aussi le risque).") end
  end

  -- classement et conclusion
  for _, e in ipairs(ents) do
    e.score = (e.nl or 0) + 1.5 * (e.nf or 0) + 0.1 * (e.r.liq2 or 0) - 0.1 * (e.r["end"] or 0) + (e.r.roe or 0)
  end
  local cl = {}
  for _, e in ipairs(ents) do table.insert(cl, e) end
  table.sort(cl, function(a, b) return a.score > b.score end)
  if n >= 2 then
    T("Classement")
    local lc = {}
    for k, e in ipairs(cl) do
      table.insert(lc, {k .. ". " .. e.nom, e.nl and NIV_LIQC[e.nl] or "—", e.nf and NIV_FINC[e.nf] or "—", gras = k == 1})
    end
    GRILLE("Du plus solide au plus fragile", lc, {entetes = {"", "Liquidité", "Financement"}})
    G("Classement de la calculatrice : niveau de liquidité + 1.5 × niveau de financement (le financement pèse plus : il engage l'entreprise à long terme). Repère personnel, pas une règle du prof.")
  end
  T("Conclusion")
  for k, e in ipairs(cl) do
    local liq = e.nl and NIV_LIQ[e.nl] or "liquidité non évaluée"
    local fin = e.nf and NIV_FIN[e.nf] or "financement non évalué"
    local det = {}
    if e.r["end"] then table.insert(det, "endettement " .. d2(e.r["end"])) end
    if e.r.couv2 then
      local c = r2(e.r.couv2)
      table.insert(det, c > 1 and "règle d'or respectée" or (c == 1 and "règle d'or tout juste respectée" or "règle d'or non respectée"))
    end
    local s
    if n == 1 then s = e.nom .. " : " .. liq .. " et " .. fin
    elseif k == 1 then s = e.nom .. " présente la situation la plus solide : " .. liq .. " et " .. fin
    elseif k == n then s = e.nom .. " est la plus fragile : " .. liq .. " et " .. fin
    else s = e.nom .. " se situe entre les deux : " .. liq .. " et " .. fin end
    if #det > 0 then s = s .. " (" .. table.concat(det, ", ") .. ")" end
    local c = {}
    if e.nl and e.nl <= 1 then table.insert(c, "encaisser ses créances, vendre du stock ou obtenir un crédit pour payer ses dettes à court terme") end
    if e.nf == 0 then table.insert(c, "renforcer ses fonds propres ou réduire son endettement") end
    if e.r.liq1 and e.r.liq1 > 0.3 then table.insert(c, "placer ou investir son excédent de liquidités") end
    if #c > 0 then s = s .. " ; elle devrait " .. table.concat(c, " et ") end
    X(s .. ".")
  end
end

-- a) à partir des ratios déjà calculés : « Nom: liq1=0.82;liq2=0.95;… / Nom: … » (1 à 5 entreprises)
function F.comparerRatios(brut)
  local defaut = brut == nil or brut == F.defRatios()
  brut = brut or F.defRatios()
  local champs = {}
  for _, id in ipairs(CMP_IDS) do table.insert(champs, {cle = id}) end
  local ents = {}
  local i = 0
  for seg in brut:gmatch("[^/]+") do
    i = i + 1
    if i > 5 then break end
    local nom, reste = seg:match("^%s*([^:]+):(.*)$")
    if not nom then nom, reste = "E" .. i, seg end
    local v = COMMUN.lireChamps(reste, champs)
    local r = {}
    for _, id in ipairs(CMP_IDS) do r[id] = F.normR(id, v[id]) end
    table.insert(ents, {nom = (nom:gsub("%s+$", "")), r = r})
  end
  vider()
  T("Comparer " .. #ents .. " entreprise" .. (#ents > 1 and "s" or "") .. " (ratios)")
  G("Méthode (modèle : test 2025 ex. 5 et 51.8) : tableau des ratios en décimal comme le corrigé du prof, puis, par entreprise et par question, une à deux phrases (constat chiffré, valeur indicative, hypothèse ou conséquence) et une comparaison. Barème 2025 : 3 pts de calculs, 6 pts de commentaires (liquidité, structure de financement).")
  if defaut then G("Par défaut : test 2025 ex. 5, ratios du corrigé du prof (Bouvier, Corgi, Husky) ; financement propre et couverture 1 calculés depuis les bilans de l'énoncé (non demandés en 2025).") end
  F.cmpRendu(ents)
  montrer("Comparer (ratios)")
end

-- b) à partir des bilans : « Nom: liquidités créances stocks AI CEct CElt FP [cap. croissance] / Nom: … » (1 à 5)
function F.comparer(brut)
  local defaut = brut == nil or brut == DEF_CMP
  brut = brut or DEF_CMP
  local vs = {}
  local i = 0
  for seg in brut:gmatch("[^/]+") do
    i = i + 1
    if i > 5 then break end
    local nom, reste = seg:match("^%s*([^:]+):(.*)$")
    if not nom then nom, reste = "E" .. i, seg end
    local t = {}
    for x in reste:gmatch("%S+") do table.insert(t, COMMUN.num(x)) end
    local v = F.deriver({liq = t[1], cre = t[2], sto = t[3], ai = t[4], ct = t[5], lt = t[6], fp = t[7], cc = t[8]})
    v.nom = (nom:gsub("%s+$", ""))
    table.insert(vs, v)
  end
  vider()
  T("Comparer " .. #vs .. " bilan" .. (#vs > 1 and "s" or ""))
  G("Méthode (modèle : test 2025 ex. 5 et 51.8) : pour chaque bilan, ratio = numérateur ÷ dénominateur, en décimal comme le corrigé du prof ; puis une à deux phrases par entreprise et par question (constat chiffré, norme, hypothèse ou conséquence) et une comparaison. Barème 2025 : 3 pts de calculs, 6 pts de commentaires.")
  if defaut then G("Par défaut : test 2025 ex. 5 (bilans de Bouvier, Corgi, Husky).") end
  -- rappel des bilans structurés
  local larg = math.max(4, math.floor(170 / math.max(#vs, 1) / 6))
  local ent = {""}
  for _, v in ipairs(vs) do table.insert(ent, F.tronquer(v.nom, larg)) end
  local function rang(lib, k, o)
    local l = {lib}
    for _, v in ipairs(vs) do l[#l + 1] = m(v[k]) end
    for kk, vv in pairs(o or {}) do l[kk] = vv end
    return l
  end
  for _, v in ipairs(vs) do if F.ok(v.ce, v.fp) then v.pas = v.ce + v.fp end end
  GRILLE("Bilans structurés", {
    rang("Liquidités", "liq", {retrait = 1}), rang("Créances", "cre", {retrait = 1}), rang("Stocks", "sto", {retrait = 1}),
    rang("Actifs circulants", "ac", {gras = true}), rang("Actifs immobilisés", "ai", {gras = true}),
    rang("Total de l'actif", "tot", {gras = true, trait = true, fond = true}),
    rang("CE à court terme", "ct", {retrait = 1}), rang("CE à long terme", "lt", {retrait = 1}),
    rang("Capitaux propres", "fp", {gras = true}), rang("Total du passif", "pas", {gras = true, trait = true, fond = true}),
  }, {entetes = ent})
  for _, v in ipairs(vs) do
    if F.ok(v.tot, v.pas) and math.abs(v.tot - v.pas) > 0.5 then A(v.nom .. " : bilan déséquilibré (actif " .. m(v.tot) .. " ≠ passif " .. m(v.pas) .. ").") end
  end
  -- calculs : formule (liste Profil M, en décimal) puis application
  T("Calcul des ratios")
  local ids = {"liq1", "liq2", "liq3", "iai", "end", "fp", "couv1", "couv2"}
  local ents = {}
  for _, id in ipairs(ids) do
    local d = RID[id]
    X(d.nom .. " = " .. d.formule:gsub(" × 100", ""))
    for _, v in ipairs(vs) do
      local nn, den, app = d.calc(v)
      if F.ok(nn, den) and den ~= 0 then
        R("  " .. v.nom .. " : ", "", app:gsub(" × 100", "") .. " = " .. d2(nn / den))
        v._r[id] = nn * 100 / den
      end
    end
  end
  local lf = {"FRN"}
  for _, v in ipairs(vs) do
    table.insert(ents, {nom = v.nom, r = {liq1 = v._r.liq1 and v._r.liq1 / 100, liq2 = v._r.liq2 and v._r.liq2 / 100,
      liq3 = v._r.liq3 and v._r.liq3 / 100, iai = v._r.iai and v._r.iai / 100, ["end"] = v._r["end"] and v._r["end"] / 100,
      fp = v._r.fp and v._r.fp / 100, couv1 = v._r.couv1 and v._r.couv1 / 100, couv2 = v._r.couv2 and v._r.couv2 / 100}})
    lf[#lf + 1] = F.ok(v.ac, v.ct) and m(v.ac - v.ct) or "—"
  end
  X("FRN = actifs circulants − CE à court terme")
  for _, v in ipairs(vs) do if F.ok(v.ac, v.ct) then R("  " .. v.nom .. " : ", "", m(v.ac) .. " − " .. m(v.ct) .. " = " .. m(v.ac - v.ct)) end end
  F.cmpRendu(ents, {lf})
  if defaut then G("Corrigé du prof (test 2025 ex. 5) : Bouvier 0.82 · 0.95 · 2.27 · 0.5 · 0.4 · 1.56 ; Corgi 0.26 · 0.97 · 1 · 0.62 · 0.58 · 1.00 ; Husky 0.17 · 0.75 · 1.27 · 0.24 · 0.82 · 1.67.") end
  montrer("Comparer des bilans")
end

-- questionnaire en trois temps : nombre d'entreprises, noms, puis chaque bilan ou chaque ratio
function F.qComparer(parRatios)
  local titre = parRatios and "Comparer (ratios)" or "Comparer (bilans)"
  COMMUN.questionnaire(titre, {{cle = "n", lib = "Nombre d'entreprises à comparer (1 à 5)", defaut = "3",
      aide = "Modèle : test 2025 ex. 5 (Bouvier, Corgi, Husky) et 51.8 (X, Y, Z). Les valeurs proposées ensuite sont celles du corrigé du prof.",
      valider = function(t) local x = COMMUN.num(t); if not x or x < 1 or x > 5 or x ~= math.floor(x) then return "Entrer un nombre entier de 1 à 5." end end}},
    function(v1)
      local n = v1.n
      local cn = {}
      for j = 1, n do
        table.insert(cn, {cle = "nom" .. j, lib = "Nom de l'entreprise " .. j, defaut = DEF_NOMS[j], texte = true,
          aide = "Nom court (8 caractères au plus) : il sert d'en-tête de colonne dans le tableau comparatif."})
      end
      COMMUN.questionnaire(titre, cn, function(v2)
        local noms = {}
        for j = 1, n do noms[j] = ((v2["nom" .. j] or ("E" .. j)):gsub("[/:;]", " ")) end
        local ch = {}
        for j = 1, n do
          if parRatios then
            for _, id in ipairs(CMP_IDS) do
              table.insert(ch, {cle = id .. "_" .. j, lib = noms[j] .. " — " .. RID[id].nom, defaut = DEF_RAT[j] and DEF_RAT[j][id] or "",
                aide = CMP_AIDE[id] .. FORMAT_R, opt = true})
            end
          else
            for q, k in ipairs(CMP_K) do
              table.insert(ch, {cle = k .. "_" .. j, lib = noms[j] .. " — " .. CAT[k], defaut = DEF_BIL[j] and DEF_BIL[j][q] or "",
                aide = AIDE[k], opt = k == "cc"})
            end
          end
        end
        COMMUN.questionnaire(titre, ch, function(v3)
          local seg = {}
          for j = 1, n do
            local t = {}
            if parRatios then
              for _, id in ipairs(CMP_IDS) do
                local s = v3._txt[id .. "_" .. j] or ""
                if s ~= "" then table.insert(t, id .. "=" .. s:gsub("%s", "")) end
              end
              table.insert(seg, noms[j] .. ": " .. table.concat(t, ";"))
            else
              for _, k in ipairs(CMP_K) do
                local s = (v3._txt[k .. "_" .. j] or ""):gsub("%s", "")
                table.insert(t, s ~= "" and s or "-")
              end
              table.insert(seg, noms[j] .. ": " .. table.concat(t, " "))
            end
          end
          if parRatios then F.comparerRatios(table.concat(seg, " / ")) else F.comparer(table.concat(seg, " / ")) end
        end)
      end)
    end)
end

------------------------------------------------------------------ 4. bilan analytique depuis une liste de postes (51.10, 51.11)
local DEF_LISTE = "Actionnaires=60000;Bénéfice de l'exercice=25000;Caisse=2600;Capital-actions=160000;Créances clients=24800;"
  .. "Dettes fournisseurs=46820;Mobilier=64800;Poste=28000;Emprunt bancaire à long terme=40980;Réserve issue du bénéfice=12000;"
  .. "Réserve issue du capital=10000;Véhicules=46000;Infra. informatique=68600;div=15000"
-- règles de classement : motif (minuscules sans accents), catégorie, signe ; la première qui correspond gagne
local REGLES = {
  {"ducroire", "cre", -1}, {"^fac", "ai", -1}, {"amort.*cumul", "ai", -1}, {"actionnaire", "cs", -1}, {"perte", "cc", -1},
  {"reserve.*capital", "cs", 1}, {"agio", "cs", 1}, {"capital", "cs", 1},
  {"reserve", "cc", 1}, {"benefice reporte", "cc", 1}, {"report", "cc", 1}, {"benefice", "bn", 1}, {"resultat", "bn", 1},
  {"dividende", "ct", 1}, {"fournisseur", "ct", 1}, {"creancier", "ct", 1}, {"passif.*regul", "ct", 1}, {"passifs? transitoire", "ct", 1},
  {"c/c passif", "ct", 1}, {"court terme", "ct", 1}, {"tva due", "ct", 1},
  {"emprunt", "lt", 1}, {"hypoth", "lt", 1}, {"pret", "lt", 1}, {"obligat", "lt", 1}, {"long terme", "lt", 1}, {"provision", "lt", 1},
  {"participation", "ai", 1}, {"liquidit", "liq", 1}, {"caisse", "liq", 1}, {"poste", "liq", 1}, {"banque", "liq", 1}, {"titre", "liq", 1},
  {"placement", "liq", 1},
  {"client", "cre", 1}, {"debiteur", "cre", 1}, {"creance", "cre", 1}, {"actif.*regul", "cre", 1}, {"actifs? transitoire", "cre", 1},
  {"impot prealable", "cre", 1}, {"tva", "cre", 1},
  {"stock", "sto", 1}, {"marchandise", "sto", 1}, {"matiere", "sto", 1}, {"produits? finis", "sto", 1}, {"en.cours", "sto", 1},
  {"mobilier", "ai", 1}, {"machine", "ai", 1}, {"vehicule", "ai", 1}, {"immeuble", "ai", 1}, {"immobil", "ai", 1}, {"terrain", "ai", 1},
  {"informatique", "ai", 1}, {"equipement", "ai", 1}, {"installation", "ai", 1}, {"brevet", "ai", 1}, {"licence", "ai", 1},
  {"outillage", "ai", 1}, {"agencement", "ai", 1}, {"goodwill", "ai", 1},
}
local ACC = {{"é", "e"}, {"è", "e"}, {"ê", "e"}, {"ë", "e"}, {"à", "a"}, {"â", "a"}, {"ô", "o"}, {"û", "u"}, {"ù", "u"}, {"î", "i"},
  {"ï", "i"}, {"ç", "c"}, {"É", "e"}, {"È", "e"}, {"À", "a"}, {"’", "'"}}
function F.cle(s)
  for _, p in ipairs(ACC) do s = s:gsub(p[1], p[2]) end   -- accents d'abord : lower() peut abîmer l'UTF-8 selon la locale
  return (s:gsub("%a", string.lower))
end
local CODES = {liq = true, cre = true, sto = true, ai = true, ct = true, lt = true, cs = true, cc = true, bn = true}
function F.classer(nom)
  local code, reste = nom:match("^%s*(%a+)%s*:%s*(.+)$")
  if code and CODES[code:lower()] then return code:lower(), 1, reste end
  local s = F.cle(nom):gsub("^%./%.%s*", "")
  for _, r in ipairs(REGLES) do if s:find(r[1]) then return r[2], r[3], nom end end
  return nil, 1, nom
end

function F.analytique(brut)
  brut = brut or DEF_LISTE
  local G_ = {liq = {}, cre = {}, sto = {}, ai = {}, ct = {}, lt = {}, cs = {}, cc = {}}
  local tot = {liq = 0, cre = 0, sto = 0, ai = 0, ct = 0, lt = 0, cs = 0, cc = 0}
  local inconnus, bn, div = {}, nil, nil
  for seg in brut:gmatch("[^;]+") do
    local nom, val = seg:match("^%s*(.-)%s*=%s*(.-)%s*$")
    local x = val and COMMUN.num(val)
    if nom and x then
      if F.cle(nom) == "div" or F.cle(nom):find("^dividende decide") then div = x
      else
        local cat, signe, lib = F.classer(nom)
        if nom:match("^%s*%./%.") then signe = -1 end
        if cat == "bn" then bn = (bn or 0) + x * signe
        elseif cat then
          local mt = math.abs(x) * signe
          if x < 0 then mt = x end
          table.insert(G_[cat], {(mt < 0 and "./. " or "") .. lib:gsub("^%s*%./%.%s*", ""), mt}); tot[cat] = tot[cat] + mt
        else table.insert(inconnus, nom) end
      end
    end
  end
  vider()
  T("Bilan analytique")
  G("Méthode (51 p.4, modèles 51.10 et 51.11) : 1) répartir le bénéfice AVANT de classer : dividende décidé → CE à court terme, solde → réserve issue du bénéfice (capital de croissance) ; 2) liquidités (caisse, poste, banque, titres de placement), créances (./. ducroire, actifs de régularisation), stocks ; AI (./. FAC, participations) ; CE ct (fournisseurs, dividende, passifs de régularisation) ; CE lt (emprunts, hypothèque, provisions à long terme) ; capital social (capital-actions ./. actionnaires + réserve issue du capital) ; capital de croissance (réserves issues du bénéfice, bénéfice reporté ./. perte reportée).")
  G("Saisie : nom=montant;… ; div=dividende décidé ; forcer une catégorie avec un code devant le nom : liq: cre: sto: ai: ct: lt: cs: cc: bn: (ex. « ct:Banque=500 »). Par défaut : Xénon SA (51.10).")
  if bn then
    if div then
      X("Répartition du bénéfice : dividende " .. m(div) .. " → CE à court terme ; solde " .. m(bn) .. " − " .. m(div) .. " = " .. m(bn - div) .. " → réserve issue du bénéfice.")
      table.insert(G_.ct, {"Dividende", div}); tot.ct = tot.ct + div
      table.insert(G_.cc, {"Attribution à la réserve", bn - div}); tot.cc = tot.cc + bn - div
    else
      G("Bénéfice de l'exercice sans répartition donnée : laissé dans le capital de croissance (préciser div=… si l'AG a décidé un dividende).")
      table.insert(G_.cc, {"Bénéfice de l'exercice", bn}); tot.cc = tot.cc + bn
    end
  elseif div then A("Dividende saisi mais pas de bénéfice de l'exercice : dividende ignoré.") end
  if #inconnus > 0 then A("Postes non classés (ajouter un code devant le nom) : " .. table.concat(inconnus, ", ")) end
  local v = F.deriver({liq = tot.liq, cre = tot.cre, sto = tot.sto, ai = tot.ai, ct = tot.ct, lt = tot.lt, fp = tot.cs + tot.cc, cc = tot.cc})
  local function bloc(l, cat, lib, ret)
    table.insert(l, {lib, "", m(tot[cat]), retrait = ret, gras = ret == 0})
    for _, it in ipairs(G_[cat]) do table.insert(l, {it[1], m(it[2]), "", retrait = ret + 1}) end
  end
  local la = {{"Actifs circulants", "", m(v.ac), gras = true, fond = true}}
  bloc(la, "liq", "Liquidités", 1); bloc(la, "cre", "Créances", 1); bloc(la, "sto", "Stocks", 1)
  table.insert(la, {"Actifs immobilisés", "", m(v.ai), gras = true, fond = true})
  for _, it in ipairs(G_.ai) do table.insert(la, {it[1], m(it[2]), "", retrait = 1}) end
  table.insert(la, {"Total de l'actif", "", m(v.tot), gras = true, trait = true})
  GRILLE("Actif", la, {entetes = {"", "Détail", "Total"}})
  local lp = {{"Capitaux étrangers", "", m(v.ce), gras = true, fond = true}}
  bloc(lp, "ct", "Dettes à court terme", 1); bloc(lp, "lt", "Dettes à long terme", 1)
  table.insert(lp, {"Capitaux propres", "", m(v.fp), gras = true, fond = true})
  bloc(lp, "cs", "Capital social", 1); bloc(lp, "cc", "Capital de croissance", 1)
  table.insert(lp, {"Total du passif", "", m(v.ce + v.fp), gras = true, trait = true})
  GRILLE("Passif", lp, {entetes = {"", "Détail", "Total"}})
  if math.abs(v.tot - v.ce - v.fp) > 0.5 then A("Actif " .. m(v.tot) .. " ≠ passif " .. m(v.ce + v.fp) .. " : vérifier la saisie et le classement.") end
  F.ratiosBilan(v)
  G("Corrigé 51.10 : AC 55'400, AI 179'400, CE ct 61'820, CE lt 40'980, CP 132'000 (capital social 110'000, croissance 22'000), total 234'800 ; ratios 49.50 % · 89.62 % · 23.59 % · 76.41 % · 43.78 % · 56.22 % · 16.67 % · 73.58 % · 96.42 %.")
  montrer("Bilan analytique")
end

------------------------------------------------------------------ 5. compte de résultat à degrés (51.19, 51.20)
local CH_CR = {
  {cle = "ven", lib = "Ventes", defaut = "2650", aide = "Ventes brutes de marchandises. CAB = ventes − retours des clients."}, {cle = "rcl", lib = "Retours des clients", defaut = "21", aide = "Retours des clients : diminuent les ventes (CAB = ventes − retours)."},
  {cle = "dac", lib = "Déductions accordées", defaut = "28", aide = "Déductions accordées (rabais, remises, escomptes accordés). CAN = CAB − déductions − pertes sur créances − frais directs de vente."}, {cle = "pcr", lib = "Pertes sur créances", defaut = "140", aide = "Pertes sur créances (clients insolvables) : diminuent le CAN (51 p.31)."},
  {cle = "fdv", lib = "Frais directs de vente", defaut = "200", aide = "Frais directs de vente (commissions sur cartes de crédit…) : diminuent le CAN."}, {cle = "ach", lib = "Achats", defaut = "1200", aide = "Achats de marchandises. PRAMA = achats − retours aux fournisseurs − déductions obtenues + frais d'achats."},
  {cle = "rfo", lib = "Retours aux fournisseurs", defaut = "14", aide = "Retours aux fournisseurs : diminuent les achats."}, {cle = "dob", lib = "Déductions obtenues", defaut = "15", aide = "Déductions obtenues (rabais, escomptes obtenus) : diminuent le PRAMA."},
  {cle = "fra", lib = "Frais d'achats", defaut = "274", aide = "Frais d'achats (transport, douane) : augmentent le PRAMA."}, {cle = "si", lib = "Stock initial", defaut = "10", aide = "Stock initial de marchandises (bilan d'ouverture)."},
  {cle = "sf", lib = "Stock final", defaut = "40", aide = "Stock final de marchandises (inventaire). PRAMV = PRAMA − augmentation de stock (+ diminution)."}, {cle = "sal", lib = "Salaires", defaut = "360", aide = "Salaires et charges sociales (charges de personnel)."},
  {cle = "ace", lib = "Autres charges d'exploitation", defaut = "140", aide = "Autres charges d'exploitation (loyer, énergie, publicité…). EBITDA = MB − personnel − autres charges."}, {cle = "amo", lib = "Amortissements", defaut = "60", aide = "Amortissements de l'exercice. EBIT = EBITDA − amortissements."},
  {cle = "chf", lib = "Charges financières", defaut = "3", aide = "Charges financières (intérêts payés). Bénéfice = EBIT − charges financières + produits financiers − impôts."}, {cle = "pf", lib = "Produits financiers", defaut = "2", aide = "Produits financiers (intérêts reçus) ; 0 s'il n'y en a pas."},
  {cle = "imp", lib = "Impôts", defaut = "0", aide = "Impôts directs ; 0 s'ils ne sont pas donnés."},
}
function F.cr(brut)
  local v = COMMUN.lireChamps(brut or "", CH_CR)
  for _, c in ipairs(CH_CR) do v[c.cle] = v[c.cle] or 0 end
  vider()
  T("Compte de résultat à degrés")
  G("Méthode (51 p.31-33, modèle 51.19) : calculs préliminaires CAB, CAN, PRAMA, variation de stock, PRAMV, puis le CR en liste : marge brute, EBITDA (avant amortissements), EBIT (avant charges et produits financiers et impôts), bénéfice net. Par défaut : 51.19 (en milliers de CHF).")
  T("Calculs préliminaires")
  local cab = v.ven - v.rcl
  COMMUN.calc("CAB", "Ventes − Retours des clients", m(v.ven) .. " − " .. m(v.rcl), m(cab))
  local can = cab - v.dac - v.pcr - v.fdv
  COMMUN.calc("CAN", "CAB − Déductions accordées − Pertes sur créances − Frais directs de vente", m(cab) .. " − " .. m(v.dac) .. " − " .. m(v.pcr) .. " − " .. m(v.fdv), m(can))
  local prama = v.ach - v.rfo - v.dob + v.fra
  COMMUN.calc("PRAMA", "Achats − Retours aux fournisseurs − Déductions obtenues + Frais d'achats", m(v.ach) .. " − " .. m(v.rfo) .. " − " .. m(v.dob) .. " + " .. m(v.fra), m(prama))
  local var = v.sf - v.si
  COMMUN.calc("Variation de stock", "Stock final − Stock initial", m(v.sf) .. " − " .. m(v.si), m(var) .. (var >= 0 and " (augmentation)" or " (diminution)"))
  local pramv = prama - var
  COMMUN.calc("PRAMV", "PRAMA − augmentation de stock (ou + diminution)", m(prama) .. (var >= 0 and " − " or " + ") .. m(math.abs(var)), m(pramv))
  local mb = can - pramv
  local ebitda = mb - v.sal - v.ace
  local ebit = ebitda - v.amo
  local bai = ebit - v.chf + v.pf
  local bn = bai - v.imp
  local l = {
    {"CAN", m(can)}, {"./. PRAMV", m(-pramv)}, {"Marge brute", m(mb), gras = true, trait = true},
    {"./. Salaires", m(-v.sal)}, {"./. Autres ch. d'exploit.", m(-v.ace)}, {"EBITDA", m(ebitda), gras = true, trait = true},
    {"./. Amortissements", m(-v.amo)}, {"EBIT", m(ebit), gras = true, trait = true},
    {"./. Charges financières", m(-v.chf)}, {"+ Produits financiers", m(v.pf)},
  }
  if v.imp ~= 0 then
    table.insert(l, {"Bénéfice avant impôts", m(bai), gras = true, trait = true})
    table.insert(l, {"./. Impôts", m(-v.imp)})
  end
  table.insert(l, {bn >= 0 and "Bénéfice net" or "Perte nette", m(bn), gras = true, trait = true, fond = true})
  GRILLE("Compte de résultat", l, {entetes = {"", "N"}})
  if can ~= 0 then
    T("Taux de marge")
    COMMUN.calc("Taux de marge brute", "Marge brute × 100 ÷ CAN", m(mb) .. " × 100 ÷ " .. m(can), p2(mb * 100 / can))
    COMMUN.calc("Taux de marge économique", "EBIT × 100 ÷ CAN", m(ebit) .. " × 100 ÷ " .. m(can), p2(ebit * 100 / can))
    COMMUN.calc("Taux de marge nette", "Bénéfice net × 100 ÷ CAN", m(bn) .. " × 100 ÷ " .. m(can), p2(bn * 100 / can))
  end
  G("Pièges : retours des clients → CAB ; pertes sur créances et frais directs de vente (commissions sur carte) diminuent le CAN ; une augmentation de stock diminue le PRAMV. Corrigé 51.19 : 2'629 · 2'261 · 1'445 · 30 · 1'415 · MB 846 · EBITDA 346 · EBIT 286 · BN 285.")
  memoriser(tostring(bn))
  montrer("CR à degrés")
end

------------------------------------------------------------------ 6. chiffres clés sur plusieurs années (51.21, 51.22, 51.23)
local DEF_CLES = "an=1 2 3 4;ca=2356000 2458000 2625000 2825000;mb=942400 1007780 997500 1186500;ebit=122400 177780 87500 246500;"
  .. "bn=24400 89780 15500 166500;eff=6 6 8 8;m2=220 220 220 220"
function F.cles(brut)
  brut = brut or DEF_CLES
  local d = {}
  for seg in brut:gmatch("[^;]+") do
    local k, val = seg:match("^%s*(%w+)%s*=%s*(.-)%s*$")
    if k then
      d[k] = {}
      for x in val:gmatch("%S+") do table.insert(d[k], k == "an" and x or COMMUN.num(x)) end
    end
  end
  local ca = d.ca or {}
  local n = #ca
  local an = d.an or {}
  for i = 1, n do an[i] = an[i] or ("A" .. i) end
  vider()
  T("Chiffres clés du compte de résultat")
  G("Méthode (51 p.35-37, modèles 51.21 et 51.23) : évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent (base = année précédente) ; taux de marge = marge × 100 ÷ CAN ; CA par employé ; CA au m². Le prof arrondit au % dans le tableau (51.21).")
  G("Saisie : an=… ; ca=… ; mb=… ; ebit=… ; bn=… ; eff=… ; m2=… (valeurs séparées par des espaces). Par défaut : Medica SA (51.21).")
  local ent = {""}
  for i = 1, n do ent[#ent + 1] = an[i] end
  local function rang(lib, f, form)
    local l = {lib}
    for i = 1, n do local r = f(i); l[#l + 1] = r and form(r) or "—" end
    return l
  end
  local pc0 = function(r) return string.format("%.0f %%", r) end
  local function taux(k) return function(i) local x = d[k] and d[k][i]; return x and ca[i] and ca[i] ~= 0 and x * 100 / ca[i] or nil end end
  local evol = function(i) return i > 1 and ca[i - 1] and ca[i - 1] ~= 0 and (ca[i] - ca[i - 1]) * 100 / ca[i - 1] or nil end
  local par = function(k) return function(i) local x = d[k] and d[k][i]; return x and x ~= 0 and ca[i] / x or nil end end
  local l = {rang("Évolution du CA", evol, pc0), rang("Taux de marge brute", taux("mb"), pc0), rang("Taux de marge écon.", taux("ebit"), pc0),
    rang("Taux de marge nette", taux("bn"), pc0), rang("CA par employé", par("eff"), function(r) return m(math.floor(r + 0.5)) end),
    rang("CA au m²", par("m2"), function(r) return m(math.floor(r + 0.5)) end)}
  GRILLE("Chiffres clés", l, {entetes = ent})
  T("Calculs")
  X("Évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent")
  for i = 2, n do X(string.format("  %s : (%s − %s) × 100 ÷ %s = %s", an[i], m(ca[i]), m(ca[i - 1]), m(ca[i - 1]), p2(evol(i)))) end
  for _, t in ipairs({{"mb", "Taux de marge brute = Marge brute × 100 ÷ CAN"}, {"ebit", "Taux de marge économique = EBIT × 100 ÷ CAN"},
      {"bn", "Taux de marge nette = Bénéfice net × 100 ÷ CAN"}}) do
    if d[t[1]] then
      X(t[2])
      for i = 1, n do X(string.format("  %s : %s × 100 ÷ %s = %s", an[i], m(d[t[1]][i]), m(ca[i]), p2(taux(t[1])(i)))) end
    end
  end
  for _, t in ipairs({{"eff", "CA par employé = CAN ÷ effectif"}, {"m2", "CA au m² = CAN ÷ surface de vente"}}) do
    if d[t[1]] then
      X(t[2])
      for i = 1, n do X(string.format("  %s : %s ÷ %s = %s", an[i], m(ca[i]), m(d[t[1]][i]), m(par(t[1])(i)))) end
    end
  end
  if n >= 2 and d.mb and d.ebit then
    local a, b = n - 1, n
    local tb0, tb1 = taux("mb")(a), taux("mb")(b)
    local te0, te1 = taux("ebit")(a), taux("ebit")(b)
    if F.ok(tb0, tb1, te0, te1) then
      T("Commentaire (" .. an[a] .. " → " .. an[b] .. ")")
      local s = string.format("Le taux de marge brute %s de %.2f points (ou %.2f %%) ; le taux de marge économique %s de %.2f points.",
        tb1 < tb0 and "a diminué" or "a augmenté", math.abs(tb1 - tb0), math.abs((tb1 - tb0) * 100 / tb0),
        te1 < te0 and "a diminué" or "a augmenté", math.abs(te1 - te0))
      if tb1 < tb0 and te1 > te0 then
        s = s .. " L'entreprise a bien contrôlé ses charges fixes, mais elle a dû soit diminuer son prix de vente, soit subir une hausse des charges de marchandises sans pouvoir la répercuter sur le prix de vente (modèle 51.23)."
      elseif tb1 > tb0 and te1 < te0 then
        s = s .. " La marge sur les marchandises s'améliore, mais les charges d'exploitation (personnel, loyers, amortissements) augmentent plus vite : à surveiller."
      elseif tb1 < tb0 then
        s = s .. " Les deux taux baissent : prix de vente sous pression ou coût des marchandises en hausse, sans compensation par les charges fixes."
      else s = s .. " Les deux taux progressent : meilleure rentabilité de l'exploitation." end
      X(s)
    end
  end
  G("Corrigé 51.21 : évolution 4 % · 7 % · 8 % ; marge brute 40 % · 41 % · 38 % · 42 % ; économique 5 % · 7 % · 3 % · 9 % ; nette 1 % · 4 % · 1 % · 6 % ; CA/employé 392'667 · 409'667 · 328'125 · 353'125 ; CA/m² 10'709 · 11'173 · 11'932 · 12'841.")
  montrer("Chiffres clés")
end

------------------------------------------------------------------ 7. rotations et durées (51.24)
local CH_ROT = {"cac", "cre", "cre1", "pramv", "sto", "sto1", "prama", "frs", "frs1", "dcl", "dfo"}
local EX_ROT = {cac = 6134.2, cre = 1216.8, cre1 = 1149.1, pramv = 5356.4, sto = 228.5, sto1 = 261.3, frs = 1737.1, frs1 = 1979.6}
function F.rotations(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_ROT, EX_ROT)))
  vider()
  T("Rotations et durées")
  G("Méthode (51 p.40-43, modèle 51.24) : moyenne = (N-1 + N) ÷ 2 ; rotation = flux ÷ moyenne ; durée = 360 ÷ rotation. Flux : CA à crédit (sinon CAN) pour les clients, PRAMA pour les fournisseurs, PRAMV pour les stocks. Le prof divise 360 par la rotation arrondie à 2 décimales (360 ÷ 5.19 = 69.36).")
  G("Par défaut : coopérative A 2014 (51.24 : 21.87 fois, 16.46 j ; 5.19 fois, 69.36 j ; 2.86 fois, 125.87 j). Le prof prend les fonds étrangers à c.t. comme dettes fournisseurs.")
  for _, s in ipairs(v._auto) do X(s) end
  T("Stocks")
  F.aff(RID.rotsto, v); F.aff(RID.dursto, v)
  T("Clients (crédits accordés)")
  F.aff(RID.rotcli, v); F.aff(RID.durcli, v)
  T("Fournisseurs (crédits obtenus)")
  F.aff(RID.rotfrs, v); F.aff(RID.durfrs, v)
  local a, b, c = v._r.dursto, v._r.durcli, v._r.durfrs
  if F.ok(a, b, c) then
    T("Cycle des liquidités (hors test)")
    COMMUN.calc("Cycle", "Durée des stocks + Durée des crédits accordés − Durée des crédits obtenus", d2(a) .. " + " .. d2(b) .. " − " .. d2(c), d2(a + b - c) .. " jours")
    X("Commentaire : " .. (a + b - c > 0 and "nombre de jours pendant lesquels l'entreprise doit financer elle-même son exploitation (besoin en fonds de roulement) ; plus il est court, moins il faut de liquidités."
      or "cycle négatif : les fournisseurs sont payés après l'encaissement des clients ; ce sont eux qui financent l'exploitation (cas du commerce de détail)."))
    G("Cycle des liquidités : 51.16-51.18, retiré du programme du 12.11.")
  end
  montrer("Rotations et durées")
end

------------------------------------------------------------------ 8. ROI, ROE, décomposition et effet de levier (51.25, 51.27)
local CH_REN = {"bn", "chf", "pf", "imp", "ebit", "tot", "tot1", "fp", "fp1", "can"}
local EX_REN = {bn = 117881, chf = 6480, pf = 0, imp = 0, tot = 1828321, tot1 = 1513362, fp = 1289789, fp1 = 1226908, can = 8432560}
function F.rentab(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_REN, EX_REN)))
  vider()
  T("Rentabilités ROI et ROE")
  G("Méthode (51 p.41-42 imprimées, modèle 51.25) : EBIT = BN + charges financières (− produits financiers + impôts) ; ROI = EBIT × 100 ÷ total moyen des bilans ; ROE = BN × 100 ÷ capitaux propres moyens ; moyennes = (N-1 + N) ÷ 2. Par défaut : Colibri SA (EBIT 124'361 ; 7.44 % ; 9.37 %).")
  T("a) EBIT")
  if v.bn then
    local l = {{"Bénéfice net", m(v.bn)}}
    if (v.imp or 0) ~= 0 then table.insert(l, {"+ Impôts", m(v.imp)}) end
    table.insert(l, {"+ Charges financières", m(v.chf or 0)})
    if (v.pf or 0) ~= 0 then table.insert(l, {"./. Produits financiers", m(-v.pf)}) end
    table.insert(l, {"EBIT", m(v.ebit), gras = true, trait = true})
    GRILLE("EBIT", l, {entetes = {"", "N"}})
  end
  T("b) Rentabilité des capitaux investis")
  F.aff(RID.roi, v)
  T("c) Rentabilité des fonds propres")
  F.aff(RID.roe, v)
  if v.can then
    T("d) Décomposition du ROI (hors test)")
    local tme = F.aff(RID.tme, v, true)
    local rot = F.aff(RID.rota, v, true)
    if F.ok(tme, rot) then
      R(string.format("ROI = %.4f %% × %.5f = %s", tme, rot, p2(tme * rot)), "", "")
      X("Commentaire : " .. (rot >= 3 and "un niveau de rotation de l'actif assez élevé explique dans une large mesure le ROI ; le taux de marge EBIT est plutôt faible (51.27)."
        or (rot < 1.5 and "c'est grâce au taux de marge EBIT que l'entreprise obtient son ROI ; la rotation de l'actif est faible (51.28)."
        or "marge EBIT et rotation de l'actif contribuent toutes deux au ROI.")))
    end
  end
  if v.chf and F.ok(v.tot, v.fp) then
    T("e) Effet de levier (hors test)")
    F.aff(RID.levier, v)
  end
  G("Décomposition et effet de levier : 51.26-51.33, hors périmètre du test du 12.11 (chap. 51 évalué jusqu'à la p.65).")
  montrer("ROI, ROE")
end

------------------------------------------------------------------ 9. FRN seul
local CH_FRN = {"ac", "ct", "fp", "lt", "ai"}
function F.frnSeul(brut)
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(CH_FRN, EX.T25)))
  vider()
  T("Fonds de roulement net")
  G("Méthode (51 p.12) : deux calculs qui doivent donner le même résultat ; FRN positif = situation favorable. Comme la liquidité 3, il mesure la capacité à payer les dettes à court terme, mais en valeur absolue. Par défaut : test 2025 ex. 3 (2026). Absent de la liste des ratios.")
  F.frn(v)
  if F.ok(v.ac, v.ct) and v.ct ~= 0 then G("Lien : FRN > 0 ⇔ liquidité 3 > 100 % (ici " .. p2(v.ac * 100 / v.ct) .. ").") end
  montrer("FRN")
end

------------------------------------------------------------------ 10. vrai / faux (51.15 et pièges du chapitre)
local VF = {
  {"Un ratio d'intensité de l'actif immobilisé élevé implique des charges fixes importantes.", "V", "", "51.15"},
  {"En additionnant les taux de financement par fonds propres et par fonds étrangers, on obtient 100 %.", "V", "", "51.15"},
  {"Les banques exigent un degré de liquidité 1 de 40 % au minimum.", "F", "Un degré de liquidité 1 élevé ne donne pas beaucoup d'informations ; ce n'est pas un ratio intéressant pour une demande de crédit (valeur indicative 20 à 30 %).", "51.15"},
  {"Un degré de liquidité 2 de 100 % est considéré comme satisfaisant.", "V", "", "51.15"},
  {"Si le degré de liquidité 3 est supérieur à 100 %, le degré de couverture 1 l'est également.", "F", "Valable pour le degré de couverture 2 (FRN positif ⇔ liquidité 3 > 100 % ⇔ couverture 2 > 100 %).", "51.15"},
  {"Un faible degré d'autofinancement indique toujours une capacité bénéficiaire insuffisante.", "F", "L'entreprise peut faire de gros bénéfices mais les distribuer ; le ratio dépend aussi de l'âge de l'entreprise et de la politique de dividendes.", "51.15"},
  {"Les réserves issues du capital (agio) font partie du capital de croissance.", "F", "Elles font partie du capital social ; le capital de croissance = réserves issues du bénéfice + bénéfice reporté.", "51 p.10"},
  {"Le dividende décidé par l'AG reste dans les capitaux propres du bilan analytique.", "F", "Il devient une dette à court terme (bilan après répartition du bénéfice).", "51.10"},
  {"Le compte Actionnaires (capital non libéré) se déduit du capital-actions.", "V", "", "51.10"},
  {"Les titres de placement rapidement réalisables sont classés dans les liquidités.", "V", "Les participations, elles, sont des actifs immobilisés.", "51.11"},
  {"Le FRN peut se calculer par AC − CE ct ou par CP + CE lt − AI.", "V", "", "51 p.12"},
  {"La durée moyenne des crédits obtenus se calcule avec le PRAMV.", "F", "Avec le PRAMA (achats) ; le PRAMV sert à la rotation des stocks.", "51 p.42-43"},
  {"Si l'on ne connaît pas le CA à crédit, on prend le CAN total pour la rotation des clients.", "V", "", "51 p.41"},
  {"Le ROI se calcule avec le bénéfice net.", "F", "Avec l'EBIT (avant intérêts et impôts) ; le ROE utilise le bénéfice net.", "Liste des ratios"},
  {"Un degré de couverture 2 inférieur à 100 % signifie que la règle d'or n'est pas respectée.", "V", "", "51 p.13"},
  {"L'effet de levier est positif lorsque le ROI dépasse le taux d'intérêt moyen des dettes (hors test).", "V", "", "51.27"},
}
function F.vraiFaux()
  vider()
  T("Vrai / faux sur les ratios")
  G("Méthode (51.15) : répondre V ou F ; justifier par une brève explication si F. Réponses du prof (51.15) puis pièges tirés du chapitre.")
  for i, q in ipairs(VF) do
    X(i .. ". " .. q[1])
    R((q[2] == "V" and "Vrai" or "Faux") .. (q[3] ~= "" and (" — " .. q[3]) or ""), "", "")
    G(q[4])
  end
  montrer("Vrai / faux")
end

------------------------------------------------------------------ ratios un par un
function F.unRatio(id, brut)
  local d = RID[id]
  local ex = EX[d.ex]
  local v = F.deriver(COMMUN.lireChamps(brut or "", F.champs(d.champs, ex)))
  vider()
  T(d.nom)
  G("Formule (liste Profil M) : " .. d.nom .. " = " .. d.formule .. ". Par défaut : " .. ex.nom .. ".")
  F.aff(d, v)
  if d.src then G(d.src) end
  montrer(d.nom)
end
function F.menuRatios()
  local it = {}
  for _, d in ipairs(RAT) do
    local dd = d
    table.insert(it, {dd.nom, function()
      COMMUN.questionnaire(dd.nom, F.champs(dd.champs, EX[dd.ex]), function(_, brut) F.unRatio(dd.id, brut) end)
    end})
  end
  MENU = {titre = "Ratios un par un (26)", items = it}; sel = 1; ecran = "menu"; inval()
end

------------------------------------------------------------------ questionnaires guidés (bilan analytique, chiffres clés)
local AIDE_LISTE = "Format nom=montant (ex. Caisse=2600 ; déduction : ./.Ducroire=1200). Classement d'après le nom : caisse, poste, banque, titres → liquidités ; clients, ducroire → créances ; stock ; mobilier, machines, véhicules → AI ; fournisseurs → CE ct ; emprunt, hypothèque → CE lt ; capital, réserves, bénéfice. Forcer : ct:Banque=500."
function F.validerPoste(t)
  if t == "" then return nil end
  local nom, val = t:match("^(.-)=(.*)$")
  if not nom or nom:gsub("%s", "") == "" or COMMUN.num(val) == nil then return "Format attendu : nom=montant (ex. Caisse=2600)." end
end
function F.qAnalytique()
  local ch, div = {}, nil
  for seg in DEF_LISTE:gmatch("[^;]+") do
    local val = seg:match("^div=(.*)$")
    if val then div = val
    else table.insert(ch, {cle = "p" .. (#ch + 1), lib = "Poste " .. (#ch + 1) .. " du bilan (nom=montant)", defaut = seg, texte = true, aide = AIDE_LISTE, valider = F.validerPoste}) end
  end
  for _ = 1, 4 do
    table.insert(ch, {cle = "p" .. (#ch + 1), lib = "Poste " .. (#ch + 1) .. " du bilan (nom=montant)", defaut = "", texte = true, opt = true,
      aide = "Poste supplémentaire (vide = aucun). " .. AIDE_LISTE, valider = F.validerPoste})
  end
  table.insert(ch, {cle = "div", lib = "Dividende décidé par l'AG", defaut = div or "", opt = true,
    aide = "Le bénéfice de l'exercice est réparti AVANT de classer : dividende → CE à court terme, solde → réserve issue du bénéfice (capital de croissance) (51.10). Vide = bénéfice laissé dans le capital de croissance."})
  COMMUN.questionnaire("Bilan analytique", ch, function(_, _, rep)
    local t = {}
    for k, c in ipairs(ch) do
      if rep[k] ~= "" then table.insert(t, c.cle == "div" and ("div=" .. rep[k]) or rep[k]) end
    end
    F.analytique(table.concat(t, ";"))
  end)
end

local AIDE_CLES = {
  an = {"Années (séparées par des espaces)", "Ex. 1 2 3 4 ou 2023 2024 2025. Les questions suivantes demandent une valeur par année, dans le même ordre, séparées par des espaces."},
  ca = {"CA net de chaque année", "CA net = ventes − déductions accordées − pertes sur créances − frais directs de vente. Une valeur par année."},
  mb = {"Marge brute de chaque année", "Marge brute = CAN − PRAMV. Vide = taux de marge brute non calculé."},
  ebit = {"EBIT de chaque année", "EBIT = bénéfice net + impôts + charges financières − produits financiers. Vide = ignoré."},
  bn = {"Bénéfice net de chaque année", "Dernière ligne du compte de résultat. Vide = ignoré."},
  eff = {"Effectif (employés) de chaque année", "Sert au CA par employé = CAN ÷ effectif. Vide = ignoré."},
  m2 = {"Surface de vente (m²) de chaque année", "Sert au CA au m² = CAN ÷ surface. Vide = ignoré."},
}
function F.qCles()
  local ch = {}
  for seg in DEF_CLES:gmatch("[^;]+") do
    local k, val = seg:match("^%s*(%w+)%s*=%s*(.-)%s*$")
    if k and AIDE_CLES[k] then
      table.insert(ch, {cle = k, lib = AIDE_CLES[k][1], defaut = val, texte = true, aide = AIDE_CLES[k][2], opt = k ~= "an" and k ~= "ca",
        valider = k ~= "an" and function(t)
          for x in t:gmatch("%S+") do if COMMUN.num(x) == nil then return "« " .. x .. " » n'est pas un nombre : une valeur par année, séparées par des espaces." end end
        end or nil})
    end
  end
  COMMUN.questionnaire("Chiffres clés", ch, function(_, _, rep)
    local t = {}
    for k, c in ipairs(ch) do if rep[k] ~= "" then table.insert(t, c.cle .. "=" .. rep[k]) end end
    F.cles(table.concat(t, ";"))
  end)
end

------------------------------------------------------------------ exposition et menu
SOLVEURS.analyse = F.analyse
SOLVEURS.bilan = F.bilan
SOLVEURS.comparer = F.comparer
SOLVEURS.comparerRatios = F.comparerRatios
SOLVEURS.analytique = F.analytique
SOLVEURS.crDegres = F.cr
SOLVEURS.chiffresCles = F.cles
SOLVEURS.rotations = F.rotations
SOLVEURS.rentab = F.rentab
SOLVEURS.frn = F.frnSeul
SOLVEURS.vraiFaux = F.vraiFaux
SOLVEURS.ratio = F.unRatio

-- chaque entrée pose les questions une par une (COMMUN.questionnaire), puis appelle le solveur avec « cle=valeur;… »
local function quest(titre, champs, f) return function() COMMUN.questionnaire(titre, champs, function(_, brut) f(brut) end) end end
table.insert(MENUS_COMPTA, {ordre = 51, titre = "Analyse de bilan et résultat (51)", items = {
  {"Analyse complète, 26 ratios", quest("Analyse complète", F.champs(CH_ANA, EX_ANA), F.analyse)},
  {"Ratios du bilan, 1 année", quest("Bilan (test 2025 ex. 3)", F.champs(CH_BIL, EX.T25), F.bilan)},
  {"Comparer 1 à 5 bilans", function() F.qComparer(false) end},
  {"Comparer X entreprises (ratios)", function() F.qComparer(true) end},
  {"Bilan analytique (liste)", F.qAnalytique},
  {"CR à degrés (balance)", quest("CR à degrés (51.19)", CH_CR, F.cr)},
  {"Chiffres clés (années)", F.qCles},
  {"Rotations et durées", quest("Rotations (51.24)", F.champs(CH_ROT, EX_ROT), F.rotations)},
  {"ROI, ROE (+ levier, hors test)", quest("ROI, ROE (51.25)", F.champs(CH_REN, EX_REN), F.rentab)},
  {"Fonds de roulement net", quest("FRN", F.champs(CH_FRN, EX.T25), F.frnSeul)},
  {"Ratios un par un (26)", F.menuRatios},
  {"Vrai / faux (51.15)", F.vraiFaux},
}})
end
