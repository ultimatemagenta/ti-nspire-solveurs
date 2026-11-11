PILE_MENUS = {}
------------------------------------------------------------------ dessin : tableau de signes et graphe
local function hauteurTab(e) return 20 + 17 * #e.tab.lignes + 4 end

local function dessinerTab(gc, e, x0, y0, w)
  local t = e.tab
  local n = #t.pts
  -- largeur colonne des noms
  gc:setFont("serif", "r", 9)
  local nomw = 22
  local boites = {}
  for i, l in ipairs(t.lignes) do
    l.txt = l.txt or (l.nom:gsub("%^2", "²"):gsub("%^3", "³"):gsub("%^4", "⁴"):gsub("%*", ""))
    boites[i] = nil
    nomw = math.max(nomw, gc:getStringWidth(l.txt) + 6)
  end
  nomw = math.min(nomw, math.floor(w * 0.35))
  local W = w - nomw - 4
  local larg = W / (n + 1)
  local function xb(i) return x0 + nomw + larg * i end  -- frontiere i (1..n)
  -- cadre
  gc:setColorRGB(0, 0, 0); gc:setPen("thin", "smooth")
  local H = hauteurTab(e) - 4
  gc:drawRect(x0, y0, w - 2, H)
  gc:drawLine(x0 + nomw, y0, x0 + nomw, y0 + H)
  gc:drawLine(x0, y0 + 18, x0 + w - 2, y0 + 18)
  -- en-tete
  gc:setFont("serif", "i", 10); gc:drawString(t.var, x0 + 4, y0 + 2, "top")
  gc:setFont("serif", "r", 9)
  gc:drawString("−∞", x0 + nomw + 2, y0 + 3, "top")
  local pinf = "+∞"; gc:drawString(pinf, x0 + w - 4 - gc:getStringWidth(pinf), y0 + 3, "top")
  for i, p in ipairs(t.pts) do
    local ok, b = pcall(function() return mise(gc, arbre(p.s), 3) end)
    if ok and b.w < larg * 1.6 and b.asc + b.desc <= 13 then b.draw(gc, xb(i) - b.w / 2, y0 + 3 + b.asc)
    else local s = (#p.s <= 11) and p.s or string.format("%.3g", p.v); gc:drawString(s, xb(i) - gc:getStringWidth(s) / 2, y0 + 3, "top") end
  end
  -- lignes
  for li, l in ipairs(t.lignes) do
    local y = y0 + 18 + (li - 1) * 17
    if li > 1 then gc:setColorRGB(170, 170, 170); gc:drawLine(x0, y, x0 + w - 2, y) end
    local res = li == #t.lignes
    gc:setColorRGB(res and 0 or 0, res and 120 or 0, 0)
    if boites[li] and boites[li].w <= nomw - 4 then boites[li].draw(gc, x0 + 3, y + 3 + boites[li].asc)
    else gc:setFont("serif", "r", 9); gc:drawString(l.txt, x0 + 2, y + 2, "top") end
    gc:setFont("sansserif", res and "b" or "r", 10)
    for k, c in ipairs(l.cells) do
      if k % 2 == 1 then  -- intervalle
        local i = (k + 1) / 2
        local xc = x0 + nomw + larg * (i - 0.5)
        gc:setColorRGB(c == "+" and 0 or 200, 0, c == "+" and 160 or 0)
        gc:drawString(c, xc - gc:getStringWidth(c) / 2, y + 2, "top")
      else
        local i = k / 2
        gc:setColorRGB(0, 0, 0)
        if c == "0" then gc:drawString("0", xb(i) - gc:getStringWidth("0") / 2, y + 2, "top")
        elseif c == "||" then gc:drawLine(xb(i) - 1, y, xb(i) - 1, y + 17); gc:drawLine(xb(i) + 1, y, xb(i) + 1, y + 17)
        else gc:setColorRGB(200, 200, 200); gc:drawLine(xb(i), y + 2, xb(i), y + 15) end
      end
    end
  end
end

local HGRAPHE = 190

local function pas(l)  -- pas de graduation 1, 2, 5 x 10^k pour ~6 graduations
  local b = 10 ^ math.floor(math.log10(l / 6))
  for _, m in ipairs({1, 2, 5, 10}) do if l / (m * b) <= 8 then return m * b end end
  return 10 * b
end

local function dessinerCourbes(gc, e, x0, y0, w)
  local h = HGRAPHE
  local xmin, xmax, ymin, ymax = 1e9, -1e9, 1e9, -1e9
  local ys = {}
  for _, c in ipairs(e.courbes) do for _, p in ipairs(c.pts) do
    if p[1] and p[2] then table.insert(ys, p[1]); table.insert(ys, p[2]) end
  end end
  table.sort(ys)
  if #ys == 0 then return end
  local lo, hi = ys[math.max(1, math.floor(#ys * 0.08))], ys[math.max(1, math.floor(#ys * 0.92))]
  lo = math.min(lo, 0); hi = math.max(hi, 0)
  if e.lo then lo, hi = e.lo, e.hi end
  if hi - lo < 1 then hi = lo + 1 end
  lo = lo - 0.1 * (hi - lo); hi = hi + 0.1 * (hi - lo)
  local function X(x) return x0 + (x - lo) / (hi - lo) * (w - 2) end
  local function Y(y) return y0 + h - (y - lo) / (hi - lo) * h end
  gc:setColorRGB(255, 255, 255); gc:fillRect(x0, y0, w - 2, h)
  gc:setColorRGB(0, 0, 0); gc:drawRect(x0, y0, w - 2, h)
  gc:clipRect("set", x0, y0, w - 2, h)
  gc:setColorRGB(120, 120, 120); gc:setPen("thin", "smooth")
  if lo < 0 and hi > 0 then gc:drawLine(X(0), y0, X(0), y0 + h); gc:drawLine(x0, Y(0), x0 + w, Y(0)) end
  gc:setFont("sansserif", "r", 7)
  local pp = pas(hi - lo)
  for k = math.ceil(lo / pp), math.floor(hi / pp) do
    local v = k * pp
    if math.abs(v) > 1e-9 then
      gc:drawLine(X(v), Y(0) - 2, X(v), Y(0) + 2); gc:drawString(string.format("%g", v), X(v) - 4, Y(0) + 2, "top")
      gc:drawLine(X(0) - 2, Y(v), X(0) + 2, Y(v)); gc:drawString(string.format("%g", v), X(0) + 3, Y(v) - 5, "top")
    end
  end
  if e.diag then gc:setColorRGB(200, 0, 0); gc:setPen("thin", "dashed"); gc:drawLine(X(lo), Y(lo), X(hi), Y(hi)) end
  gc:setPen("medium", "smooth")
  for _, c in ipairs(e.courbes) do
    gc:setColorRGB(c.coul[1], c.coul[2], c.coul[3])
    local prev = nil
    for _, p in ipairs(c.pts) do
      if p[1] and p[2] and p[2] > lo - 3 * (hi - lo) and p[2] < hi + 3 * (hi - lo) then
        if prev then gc:drawLine(X(prev[1]), Y(prev[2]), X(p[1]), Y(p[2])) end
        prev = p
      else prev = nil end
    end
  end
  gc:clipRect("reset")
  gc:setColorRGB(80, 80, 80); gc:setFont("sansserif", "r", 7)
  gc:drawString(e.legende or "", x0 + 2, y0 + h + 1, "top")
end

local COULB = {{255, 225, 225}, {220, 240, 255}, {225, 250, 220}, {255, 240, 210}, {240, 225, 255}}
local COULBT = {{200, 0, 0}, {0, 90, 200}, {0, 140, 0}, {210, 120, 0}, {130, 0, 180}}

local function dessinerGraphe(gc, e, x0, y0, w)
  local h = HGRAPHE
  local function f(x)
    local d = horner(e.den, x)
    if math.abs(d) < 1e-12 then return nil end
    return horner(e.num, x) / d
  end
  -- fenetre
  local xs = {}
  for _, l in ipairs({e.poles, e.interdits, e.zeros, e.crit}) do for _, p in ipairs(l or {}) do table.insert(xs, p.v) end end
  local a, b = -2, 2
  if #xs > 0 then a, b = math.min(unpack(xs)), math.max(unpack(xs)) end
  local larg = math.max(b - a, 4)
  local xmin, xmax = a - 0.6 * larg, b + 0.6 * larg
  local ys = {0}
  for _, l in ipairs({e.crit, e.zeros}) do for _, p in ipairs(l or {}) do local v = f(p.v); if v then table.insert(ys, v) end end end
  for _, x in ipairs({xmin, xmax}) do local v = f(x); if v then table.insert(ys, v) end end
  if e.asym and #e.asym == 1 then table.insert(ys, e.asym[1]) end
  local ymin, ymax = math.min(unpack(ys)), math.max(unpack(ys))
  local hy = math.max(ymax - ymin, 4)
  ymin, ymax = ymin - 0.5 * hy, ymax + 0.5 * hy
  local function X(x) return x0 + (x - xmin) / (xmax - xmin) * (w - 2) end
  local function Y(y) return y0 + h - (y - ymin) / (ymax - ymin) * h end
  gc:setColorRGB(255, 255, 255); gc:fillRect(x0, y0, w - 2, h)
  gc:setColorRGB(0, 0, 0); gc:drawRect(x0, y0, w - 2, h)
  gc:clipRect("set", x0, y0, w - 2, h)
  -- encadres de bijection (sous la courbe)
  for _, bx in ipairs(e.boites or {}) do
    local c = COULB[(bx.n - 1) % 5 + 1]
    local xa, xb = X(math.max(bx.x1, xmin - 1)), X(math.min(bx.x2, xmax + 1))
    local ya, yb = Y(math.min(bx.y2, ymax + 1)), Y(math.max(bx.y1, ymin - 1))
    gc:setColorRGB(c[1], c[2], c[3]); gc:fillRect(xa, ya, xb - xa, yb - ya)
    local ct = COULBT[(bx.n - 1) % 5 + 1]
    gc:setColorRGB(ct[1], ct[2], ct[3]); gc:setPen("thin", "smooth"); gc:drawRect(xa, ya, xb - xa, yb - ya)
  end
  -- axes et graduations
  gc:setColorRGB(120, 120, 120); gc:setPen("thin", "smooth")
  if xmin < 0 and xmax > 0 then gc:drawLine(X(0), y0, X(0), y0 + h) end
  if ymin < 0 and ymax > 0 then gc:drawLine(x0, Y(0), x0 + w, Y(0)) end
  gc:setFont("sansserif", "r", 7)
  local yax = (ymin < 0 and ymax > 0) and Y(0) or (y0 + h - 1)
  local xax = (xmin < 0 and xmax > 0) and X(0) or (x0 + 1)
  local px_ = pas(xmax - xmin)
  for k = math.ceil(xmin / px_), math.floor(xmax / px_) do
    local v = k * px_
    if math.abs(v) > 1e-9 then
      gc:drawLine(X(v), yax - 2, X(v), yax + 2)
      local s = string.format("%g", v)
      gc:drawString(s, X(v) - gc:getStringWidth(s) / 2, math.min(yax + 2, y0 + h - 10), "top")
    end
  end
  local py_ = pas(ymax - ymin)
  for k = math.ceil(ymin / py_), math.floor(ymax / py_) do
    local v = k * py_
    if math.abs(v) > 1e-9 then
      gc:drawLine(xax - 2, Y(v), xax + 2, Y(v))
      local s = string.format("%g", v)
      gc:drawString(s, math.max(xax + 3, x0 + 2), Y(v) - 5, "top")
    end
  end
  -- asymptotes
  gc:setColorRGB(220, 0, 0); gc:setPen("thin", "dashed")
  for _, p in ipairs(e.poles or {}) do gc:drawLine(X(p.v), y0, X(p.v), y0 + h) end
  if e.asym then
    local q = function(x) return horner(e.asym, x) end
    gc:drawLine(X(xmin), Y(q(xmin)), X(xmax), Y(q(xmax)))
  end
  -- courbe
  gc:setColorRGB(0, 0, 200); gc:setPen("medium", "smooth")
  local px, py = nil, nil
  local N = 260
  for i = 0, N do
    local x = xmin + (xmax - xmin) * i / N
    local y = f(x)
    local coupe = false
    if px then for _, p in ipairs(e.poles or {}) do if px < p.v and p.v <= x then coupe = true end end end
    if y and px and py and not coupe and math.abs(y - py) < 3 * (ymax - ymin) then
      gc:drawLine(X(px), Y(math.max(math.min(py, ymax + hy), ymin - hy)), X(x), Y(math.max(math.min(y, ymax + hy), ymin - hy)))
    end
    px, py = x, y
    if coupe then py = nil end
  end
  -- zeros et trous
  gc:setPen("thin", "smooth")
  gc:setColorRGB(0, 150, 0)
  for _, z in ipairs(e.zeros or {}) do gc:fillArc(X(z.v) - 3, Y(0) - 3, 6, 6, 0, 360) end
  for _, r in ipairs(e.interdits or {}) do
    local pole = false
    for _, p in ipairs(e.poles or {}) do if math.abs(p.v - r.v) < 1e-9 then pole = true end end
    if not pole then
      local v = f(r.v + 1e-6) or 0
      gc:setColorRGB(255, 255, 255); gc:fillArc(X(r.v) - 3, Y(v) - 3, 6, 6, 0, 360)
      gc:setColorRGB(200, 0, 0); gc:drawArc(X(r.v) - 3, Y(v) - 3, 6, 6, 0, 360)
    end
  end
  gc:clipRect("reset")
  gc:setColorRGB(80, 80, 80); gc:setFont("sansserif", "r", 7)
  gc:drawString(string.format("x∈[%.3g;%.3g] y∈[%.3g;%.3g]", xmin, xmax, ymin, ymax), x0 + 2, y0 + h + 1, "top")
end


local function hauteurGrille(e)
  return 18 + 15 * #e.lignes + (e.opts.entetes and 15 or 0) + 4
end

local function dessinerGrille(gc, e, x0, y0, w)
  local y = y0
  gc:setColorRGB(30, 70, 160); gc:setFont("sansserif", "b", 10); gc:drawString(e.titre or "", x0 + 2, y, "top")
  y = y + 17
  local ncol = 0
  for _, l in ipairs(e.lignes) do ncol = math.max(ncol, #l - 1) end
  if e.opts.entetes then ncol = math.max(ncol, #e.opts.entetes - 1) end
  local wl = math.floor((w - 4) * (ncol >= 2 and 0.46 or 0.6))
  local wc = ncol > 0 and math.floor((w - 4 - wl) / ncol) or 0
  local function ligne_(l, entete)
    if l.fond then gc:setColorRGB(235, 240, 250); gc:fillRect(x0, y - 1, w - 2, 15) end
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", (l.gras or entete) and "b" or "r", 9)
    local lib = tostring(l[1] or "")
    while gc:getStringWidth(lib) > wl - 4 and #lib > 3 do lib = lib:sub(1, -2) end
    gc:drawString(lib, x0 + 3 + (l.retrait or 0) * 8, y, "top")
    for j = 2, #l do
      local s = tostring(l[j] or "")
      local xr = x0 + wl + (j - 1) * wc - 3
      gc:drawString(s, xr - gc:getStringWidth(s), y, "top")
    end
    if l.trait then gc:setColorRGB(0, 0, 0); gc:drawLine(x0 + wl, y - 1, x0 + w - 3, y - 1) end
    y = y + 15
  end
  if e.opts.entetes then local h = {}; for i, v in ipairs(e.opts.entetes) do h[i] = v end; ligne_(h, true) end
  for _, l in ipairs(e.lignes) do ligne_(l, false) end
  gc:setColorRGB(150, 150, 150); gc:drawRect(x0, y0 + 16, w - 2, y - y0 - 16)
end

-- grille compacte (GRILLE(..., {compact = true})) : tout le tableau sur un ecran.
-- dispo = hauteur libre depuis le haut de la grille jusqu'au pied quand le document est en haut ;
-- si elle ne suffit pas, la grille se dimensionne pour un ecran entier (tableau suivant d'une serie).
local function texteC(s) return (tostring(s or ""):gsub(" %%", "%%"):gsub("−", "-")) end
local function couperC(gc, s, larg)
  while gc:getStringWidth(s) > larg and #s > 1 do
    s = s:sub(1, -2)
    while #s > 1 and s:byte(-1) >= 128 and s:byte(-1) < 192 do s = s:sub(1, -2) end   -- pas de demi-caractere UTF-8
    if #s > 0 and s:byte(-1) >= 192 then s = s:sub(1, -2) end
  end
  return s
end
local function mesureCompacte(gc, e, w, dispo)
  local rows = {}
  if e.opts.entetes then table.insert(rows, {c = e.opts.entetes, ent = true}) end
  for _, l in ipairs(e.lignes) do table.insert(rows, {c = l, l = l}) end
  local ncol = 0
  for _, r in ipairs(rows) do ncol = math.max(ncol, #r.c - 1) end
  local ht = (e.titre and e.titre ~= "") and 12 or 0
  local nr = math.max(#rows, 1)
  if not dispo or dispo < ht + nr * 9 + 2 then dispo = 212 - 36 - 2 end
  -- hauteur de ligne = hauteur reelle de la police (sinon les traits coupent le haut des chiffres) :
  -- plus grande police dont toutes les lignes tiennent dans la place libre
  local f0, rh
  for f = 9, 7, -1 do
    gc:setFont("sansserif", "r", f)
    rh = gc:getStringHeight("0Lg") + 1
    f0 = f
    if ht + nr * rh + 2 <= dispo then break end
  end
  local L
  for f = f0, 7, -1 do
    for avecEnt = 1, 0, -1 do       -- d'abord en-tetes entiers, sinon en-tetes tronques a la largeur des valeurs
      local wl, wc = 0, {}
      for j = 1, ncol do wc[j] = 0 end
      for _, r in ipairs(rows) do
        gc:setFont("sansserif", (r.ent or (r.l and r.l.gras)) and "b" or "r", f)
        wl = math.max(wl, gc:getStringWidth(texteC(r.c[1])) + 5 + (r.l and r.l.retrait or 0) * 6)
        if not r.ent or avecEnt == 1 then
          for j = 1, ncol do wc[j] = math.max(wc[j], gc:getStringWidth(texteC(r.c[j + 1])) + 5) end
        end
      end
      local tot = wl
      for j = 1, ncol do wc[j] = math.max(wc[j], 14); tot = tot + wc[j] end
      gc:setFont("sansserif", "r", f)
      local rhf = math.max(rh, gc:getStringHeight("0Lg") + 1)
      L = {f = f, rh = rhf, wl = wl, wc = wc, tot = tot, ht = ht, ncol = ncol, nr = #rows}
      if tot <= w - 2 then break end
    end
    if L.tot <= w - 2 then break end
  end
  L.deborde = L.tot > w - 2
  local reste = (w - 2) - L.tot
  if reste > 0 then          -- place en trop : un peu pour les libelles, le reste reparti entre les colonnes
    local pl = ncol > 0 and math.floor(reste * 0.25) or reste
    L.wl = L.wl + pl
    for j = 1, ncol do L.wc[j] = L.wc[j] + math.floor((reste - pl) / ncol) end
  elseif reste < 0 then L.wl = math.max(20, L.wl + reste) end   -- trop large : libelles tronques
  L.h = ht + L.nr * L.rh + 2
  e._L = L
  return L.h
end

local function dessinerCompacte(gc, e, x0, y0, w)
  local L = e._L
  local y = y0
  if L.ht > 0 then
    gc:setColorRGB(30, 70, 160); gc:setFont("sansserif", "b", 9); gc:drawString(e.titre, x0 + 2, y - 1, "top")
    y = y + L.ht
  end
  local ytab = y
  local dy = 0
  local function rang(c, l, ent)
    if ent then gc:setColorRGB(220, 230, 250); gc:fillRect(x0, y, w - 2, L.rh)
    elseif l.fond then gc:setColorRGB(235, 240, 250); gc:fillRect(x0, y, w - 2, L.rh) end
    gc:setColorRGB(0, 0, 0)
    gc:setFont("sansserif", (ent or l.gras) and "b" or "r", L.f)
    local ret = (l and l.retrait or 0) * 6
    gc:drawString(couperC(gc, texteC(c[1]), L.wl - 4 - ret), x0 + 2 + ret, y + dy, "top")
    local xr = x0 + L.wl
    for j = 1, L.ncol do
      xr = xr + L.wc[j]
      local s = couperC(gc, texteC(c[j + 1]), L.wc[j] - 3)
      gc:drawString(s, xr - 3 - gc:getStringWidth(s), y + dy, "top")
    end
    if l and l.trait then gc:setColorRGB(0, 0, 0); gc:drawLine(x0 + L.wl, y, x0 + w - 3, y) end
    y = y + L.rh
    gc:setColorRGB(225, 225, 225); gc:drawLine(x0, y, x0 + w - 3, y)
  end
  if e.opts.entetes then rang(e.opts.entetes, nil, true) end
  for _, l in ipairs(e.lignes) do rang(l, l, false) end
  gc:setColorRGB(150, 150, 150)
  gc:drawRect(x0, ytab, w - 2, y - ytab)
  gc:drawLine(x0 + L.wl, ytab, x0 + L.wl, y)
end

------------------------------------------------------------------ dessin
local BLEU = {30, 70, 160}

local function bandeau(gc, w, s)
  gc:setColorRGB(BLEU[1], BLEU[2], BLEU[3]); gc:fillRect(0, 0, w, 20)
  gc:setColorRGB(255, 255, 255); gc:setFont("sansserif", "b", 11); gc:drawString(s, 4, 2, "top")
end

local function pied(gc, w, h, s)
  gc:setColorRGB(225, 225, 225); gc:fillRect(0, h - 16, w, 16)
  gc:setColorRGB(60, 60, 60); gc:setFont("sansserif", "r", 9); gc:drawString(s, 4, h - 15, "top")
end

local function dessinerMenu(gc, w, h)
  bandeau(gc, w, MENU.titre)
  local y = 24
  local nvis = math.floor((h - 44) / 20)
  local debut = math.max(1, sel - nvis + 1)
  for i, it in ipairs(MENU.items) do
    if i >= debut and i < debut + nvis then
      if i == sel then gc:setColorRGB(200, 220, 255); gc:fillRect(2, y - 1, w - 4, 19) end
      gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", i == sel and "b" or "r", 10)
      gc:drawString((i < 10 and i or " ") .. "  " .. it[1], 8, y, "top")
      y = y + 20
    end
  end
  if #MENU.items > nvis then
    gc:setColorRGB(120, 120, 120); gc:setFont("sansserif", "r", 9)
    gc:drawString(sel .. "/" .. #MENU.items, w - 34, h - 32, "top")
  end
  pied(gc, w, h, "▲▼ choisir   enter : ouvrir   esc : retour")
end

local function couper(gc, s, larg)
  local out, cur = {}, ""
  for mot in s:gmatch("%S+") do
    local essai = cur == "" and mot or (cur .. " " .. mot)
    if gc:getStringWidth(essai) <= larg then cur = essai
    else if cur ~= "" then table.insert(out, cur) end; cur = mot end
  end
  if cur ~= "" then table.insert(out, cur) end
  if #out == 0 then out = {""} end
  return out
end

-- ecran de saisie : question (gras), aide coupee en lignes, erreur (rouge), note (gris), puis zone de saisie.
-- Si le texte ne tient pas, la police de l'aide passe de 9 a 8 ; au-dela, les dernieres lignes sont remplacees par « … ».
local function lignesSaisie(gc, w, taille)
  local blocs = {{saisie.msg or "", "b", 10, {0, 0, 0}}}
  if saisie.aide and saisie.aide ~= "" then table.insert(blocs, {saisie.aide, "r", taille, {0, 0, 0}}) end
  if saisie.erreur and saisie.erreur ~= "" then table.insert(blocs, {saisie.erreur, "b", taille, {200, 0, 0}}) end
  if saisie.note and saisie.note ~= "" then table.insert(blocs, {saisie.note, "i", taille, {100, 100, 100}}) end
  local out = {}
  for _, b in ipairs(blocs) do
    gc:setFont("sansserif", b[2], b[3])
    for par in (b[1] .. "\n"):gmatch("(.-)\n") do
      for _, l in ipairs(couper(gc, par, w - 12)) do
        table.insert(out, {s = l, st = b[2], t = b[3], c = b[4], dy = b[3] >= 10 and 14 or (b[3] == 9 and 12 or 11)})
      end
    end
  end
  local haut = 0
  for _, l in ipairs(out) do haut = haut + l.dy end
  return out, haut
end

local function dessinerSaisie(gc, w, h)
  bandeau(gc, w, saisie.titre or "Saisie")
  local dispo = h - 16 - 23 - 28            -- entre le bandeau et la zone de saisie (28 px) au-dessus du pied
  local lignes, haut = lignesSaisie(gc, w, 9)
  if haut > dispo then lignes, haut = lignesSaisie(gc, w, 8) end
  local y = 23
  saisie.deborde = haut > dispo
  for i, l in ipairs(lignes) do
    if y + l.dy > 23 + dispo then
      gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 9); gc:drawString("…", w - 14, y - l.dy, "top")
      break
    end
    gc:setColorRGB(l.c[1], l.c[2], l.c[3]); gc:setFont("sansserif", l.st, l.t)
    gc:drawString(l.s, 6, y, "top")
    y = y + l.dy
  end
  local yb = y + 2
  gc:setColorRGB(245, 245, 255); gc:fillRect(4, yb, w - 8, 24)
  gc:setColorRGB(30, 70, 160); gc:drawRect(4, yb, w - 8, 24)
  gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 11)
  gc:drawString(saisie.txt, 8, yb + 4, "top")
  local cx = 8 + gc:getStringWidth(saisie.txt:sub(1, saisie.cur))
  gc:drawLine(cx, yb + 3, cx, yb + 21)
  -- apercu 2D (seulement s'il reste de la place)
  if saisie.txt ~= "" and yb + 24 + 34 < h - 16 then
    local ok, b = pcall(function() return mise(gc, arbre(saisie.txt), 1) end)
    if ok and yb + 30 + b.asc + b.desc < h - 16 then gc:setColorRGB(0, 0, 0); b.draw(gc, 8, yb + 30 + b.asc) end
  end
  pied(gc, w, h, saisie.pied or "◄► curseur  ▲▼ historique  enter : ok  esc : annuler")
end

local function hauteurElt(gc, e, w, dispo)
  if e.k == "txt" or e.k == "gris" or e.k == "alerte" then
    gc:setFont("sansserif", e.k == "gris" and "i" or (e.k == "alerte" and "b" or "r"), e.petit and 8 or 10)
    e._l = couper(gc, e.s, w - 10)
    return 4 + (e.petit and 11 or 15) * #e._l
  end
  if e.k == "tab" then return hauteurTab(e) + 2 end
  if e.k == "grille" and e.compact then return mesureCompacte(gc, e, w - 2, dispo) + 2 end
  if e.k == "grille" then return hauteurGrille(e) + 2 end
  if e.k == "graphe" then return HGRAPHE + 14 end
  if e.k == "courbes" then return HGRAPHE + 14 end
  if e.k == "math" or e.k == "res" then
    local ok, b = pcall(function() return mise(gc, arbre(e.s), 1, e.k == "res") end)
    e._b = ok and b or nil
    police(gc, 1, e.k == "res")
    if e._b then return e._b.asc + e._b.desc + 6 end
  end
  return 18
end

local function dessinerVue(gc, w, h)
  bandeau(gc, w, vue.titre)
  gc:clipRect("set", 0, 20, w, h - 36)
  local y = 22 - vue.haut
  local total = 0
  for _, e in ipairs(vue.doc) do
    -- place libre sous l'element quand le document est en haut (independant du defilement) : grilles compactes
    local he = hauteurElt(gc, e, w, (h - 16) - (22 + total + 1))
    e._y, e._h = 22 + total + 1, he - 2   -- position dans le document en haut de vue (banc de test)
    if y + he > 20 and y < h - 16 then
      if e.k == "grille" and e.compact then dessinerCompacte(gc, e, 2, y + 1, w - 2)
      elseif e.k == "grille" then dessinerGrille(gc, e, 2, y + 1, w - 2)
      elseif e.k == "tab" then dessinerTab(gc, e, 2, y + 1, w - 2)
      elseif e.k == "graphe" then dessinerGraphe(gc, e, 2, y + 1, w - 2)
      elseif e.k == "courbes" then dessinerCourbes(gc, e, 2, y + 1, w - 2)
      elseif e.k == "titre" then
        gc:setColorRGB(220, 230, 250); gc:fillRect(0, y, w, he)
        gc:setColorRGB(BLEU[1], BLEU[2], BLEU[3]); gc:setFont("sansserif", "b", 11); gc:drawString(e.s, 4, y + 2, "top")
      elseif e.k == "txt" or e.k == "gris" or e.k == "alerte" then
        if e.k == "txt" then gc:setColorRGB(0, 0, 0); gc:setFont("sansserif", "r", 10)
        elseif e.k == "gris" then gc:setColorRGB(110, 110, 110); gc:setFont("sansserif", "i", 10)
        else gc:setColorRGB(200, 0, 0); gc:setFont("sansserif", "b", 10) end
        if e.petit then gc:setFont("sansserif", "i", 8) end
        for i, l in ipairs(e._l or {e.s}) do gc:drawString(l, 4, y + 2 + (e.petit and 11 or 15) * (i - 1), "top") end
      else
        local res = e.k == "res"
        if res then gc:setColorRGB(0, 120, 0) else gc:setColorRGB(0, 0, 0) end
        gc:setFont("sansserif", res and "b" or "r", 10)
        local x = 8 + gc:getStringWidth(e.avant)
        if e._b then
          local base = y + 3 + e._b.asc
          gc:drawString(e.avant, 8, base, "baseline")
          e._b.draw(gc, x, base)
          gc:setFont("sansserif", res and "b" or "r", 10)
          gc:drawString(e.apres, x + e._b.w, base, "baseline")
        else gc:drawString(e.avant .. e.s .. e.apres, 8, y + 2, "top") end
      end
    end
    y = y + he; total = total + he
  end
  gc:clipRect("reset")
  vue.total = total
  vue.visible = h - 36
  pied(gc, w, h, "▲▼ défiler  ◄► page  enter/esc : menu")
end

function on.paint(gc)
  local w, h = platform.window:width(), platform.window:height()
  gc:setColorRGB(255, 255, 255); gc:fillRect(0, 0, w, h)
  if ecran == "menu" then dessinerMenu(gc, w, h)
  elseif ecran == "saisie" then dessinerSaisie(gc, w, h)
  else dessinerVue(gc, w, h) end
end

------------------------------------------------------------------ touches
function on.arrowUp()
  if ecran == "menu" then sel = sel > 1 and sel - 1 or #MENU.items
  elseif ecran == "saisie" then
    if saisie.h > 1 then saisie.h = saisie.h - 1; saisie.txt = HIST[saisie.h]; saisie.cur = #saisie.txt end
  else vue.haut = math.max(0, vue.haut - 16) end
  inval()
end

function on.arrowDown()
  if ecran == "menu" then sel = sel < #MENU.items and sel + 1 or 1
  elseif ecran == "saisie" then
    if saisie.h < #HIST then saisie.h = saisie.h + 1; saisie.txt = HIST[saisie.h]; saisie.cur = #saisie.txt
    else saisie.h = #HIST + 1; saisie.txt = ""; saisie.cur = 0 end
  else vue.haut = math.min(math.max(0, (vue.total or 0) - (vue.visible or 120)), vue.haut + 16) end
  inval()
end

function on.arrowLeft()
  if ecran == "saisie" then saisie.cur = math.max(0, saisie.cur - 1)
  elseif ecran == "vue" then vue.haut = math.max(0, vue.haut - (vue.visible or 150) + 20) end
  inval()
end

function on.arrowRight()
  if ecran == "saisie" then saisie.cur = math.min(#saisie.txt, saisie.cur + 1)
  elseif ecran == "vue" then vue.haut = math.min(math.max(0, (vue.total or 0) - (vue.visible or 120)), vue.haut + (vue.visible or 150) - 20) end
  inval()
end

function on.charIn(ch)
  if ecran == "saisie" then
    saisie.txt = saisie.txt:sub(1, saisie.cur) .. ch .. saisie.txt:sub(saisie.cur + 1)
    saisie.cur = saisie.cur + #ch; inval()
  elseif ecran == "menu" and tonumber(ch) and MENU.items[tonumber(ch)] then
    sel = tonumber(ch)
    local avant = MENU
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = sel}) end
  end
end

function on.backspaceKey()
  if ecran == "saisie" and saisie.cur > 0 then
    saisie.txt = saisie.txt:sub(1, saisie.cur - 1) .. saisie.txt:sub(saisie.cur + 1)
    saisie.cur = saisie.cur - 1; inval()
  end
end

function on.clearKey()
  if ecran == "saisie" then saisie.txt = ""; saisie.cur = 0; inval() end
end

function on.enterKey()
  if ecran == "menu" then
    local avant, s0 = MENU, sel
    MENU.items[sel][2]()
    if MENU ~= avant then table.insert(PILE_MENUS, {menu = avant, sel = s0}) end
  elseif ecran == "saisie" then
    local t = saisie.txt
    if t == "" and not saisie.vide then return end
    memoriser(t)
    local s = saisie.suite
    local ok, err = pcall(s, t)
    if not ok then vider(); T("Erreur"); A(tostring(err)); montrer("Erreur") end
  else menuPrincipal() end
end

function on.escapeKey()
  if ecran ~= "menu" or MENU.titre ~= TITRE_APP then
    local p = table.remove(PILE_MENUS)
    if p then MENU = p.menu; sel = p.sel; ecran = "menu"; inval() else menuPrincipal() end
  end
end

------------------------------------------------------------------ demarrage et sauvegarde
function on.construction() menuPrincipal() end
function on.resize() inval() end
function on.save() return {hist = HIST} end
function on.restore(t) if type(t) == "table" and t.hist then HIST = t.hist end end

API_TEST = {doc = function() return DOC end, hist = function() return HIST end,
  ecran = function() return ecran end, vue = function() return vue end, saisie = function() return saisie end, menu = function() return MENU, sel end,
  -- saisie simulee : txt = nil garde le texte pre-rempli (ENTER seul)
  entrer = function(txt) if txt then saisie.txt = txt; saisie.cur = #txt end; on.enterKey() end,
  choisir = function(i) sel = i; on.enterKey() end}

