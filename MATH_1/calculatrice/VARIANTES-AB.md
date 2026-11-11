# Variantes des problèmes A (vecteurs) et B (figure) : couverture du solveur Lua

> Analyse du 10.11.2026, en lecture seule, de `lua/solveur.lua` (commit a400b39 : `problemeA` l.1915, `problemeB` l.2007, outils l.1238-1447 et 1814-1910).
> Sources des variantes :
> - test 2025 : `examens/2025/txt/enonce.md` p.1-2 (énoncé) et `corrige-prof.md` p.1-2 (corrigé) ;
> - examen blanc 1 : `examens/2026/blancs/blanc-1/enonce.html` ;
> - séries 4, 5 et 6 : `exercices/serie-04|05|06/enonce.md` et `corrige-exoNN.md` (série 4 2025 : `exercices/serie-04/2025/`) ;
> - polycopié : `sources/txt/06-polycopie-Math1a.md` p.6-26. Les pages citées sont les marqueurs `--- p.N ---` ; pour le chapitre 1, ils concordent avec les pages imprimées (déf. 1.18, p.22 ; déf. 1.19, p.24) ;
> - notes : `notes/annotations-2025.md` ; cadrage de l'examen : `examens/2026/PERIMETRE.md` et `BAREME.md`.
>
> Statuts : **OK** = la fonction donne le résultat et l'essentiel de la rédaction du prof ; **PARTIEL** = on obtient le résultat avec un contournement (saisie à la main, deux outils, rédaction absente) ou un défaut connu ; **MANQUE** = rien d'utilisable.
> « À tester » : le code le permet, mais le comportement du CAS n'a pas été vérifié sur la calculatrice.

## 0. Défauts relevés dans le code (à corriger quelle que soit la priorité)

| # | Où | Défaut | Effet |
|---|---|---|---|
| D1 | `vVectoriel` l.1332, `vComposantes` l.1393 | `comp()` d'un vecteur 2D renvoie 2 composantes. `a[3]` / `A1[3]` valent `nil`, donc la concaténation plante. | Pour une aire 2D (S6 ex.5, T25 P3 c), il faut taper `x,y,0`. Une base 2D (poly p.16-17) est impossible. |
| D2 | `problemeB` l.2007 | Contrairement à `chasles` l.1864, les définitions ne substituent pas les points déjà définis. `M=(B+C)/2` est donc refusé. | Il faut calculer chaque point à la main en u, v, w (milieux du parallélépipède, J de S4 ex.3 c, points du logo). |
| D3 | `problemeB` / `reconnaitre` l.2029 | Dès qu'un vecteur nommé égal existe, la fonction renvoie seulement les égaux et cache les multiples. | `MN` affiche « IK = MN », mais pas « ½·BD » (blanc B c). Contournement : taper `MN-1/2*BD` (résultat attendu : vecteur nul). |
| D4 | `problemeB` | `total` part de `[0,0,0]` : une figure libre en coordonnées 2D (`A=[-1,4]`) donne une erreur de dimension. | Pour le logo (quadrillage), il faut taper `[-1,4,0]`. Les étiquettes u, v affichées sont alors en fait i, j. |
| D5 | `problemeA` partie c) | Pas d'interprétation quand V = 0. De plus, l'ordre [QP;QR;QS] est l'opposé de celui du prof, [QP;QS;QR]. | Le point R10 « vecteurs coplanaires ! » (BAREME §2, `corrige-prof.md` p.2) n'est pas proposé. Le signe est opposé (sans effet sur \|V\|). |
| D6 | `problemeA`, variante « B orthonormée ? » | Le message dit « ni normée ni orthogonale » dès que ‖QP‖ ≠ 1, même si QP·QR = 0. Le contre-exemple du prof (QP·k ≠ 0) n'est jamais testé. | Conclusion parfois fausse dans sa justification (`corrige-prof.md` p.2, b-iv). |
| D7 | `problemeA` et `vComposantes` | `solve(...)` donne α, β, γ d'un bloc. | Le prof note β, α, γ séparément (1 pt chacun, BAREME P2 b-iii) et résout par substitution. Les étapes ne sont pas affichées. |
| D8 | `systemeVect` l.1835 | `|uxv|` devient `|crossP(u,v)|`, que le CAS ne lit pas comme une norme. Il faut écrire `norm(uxv)=…`. | Saisie d'une condition d'aire non intuitive (à tester). |

## 1. Problème A : vecteurs dans l'espace

| # | Question type | Source (fichier, page) | Statut | Fonction et saisie, ou ce qui manque |
|---|---|---|---|---|
| A1 | Projection orthogonale T de P sur (QR) | T25 `enonce.md` p.1 a ; `corrige-prof.md` p.1 ; blanc A a ; poly p.20-21 (Cor. 1.1, projeté H) | OK | `problemeA` a), ou `Vecteurs > Projection d'un point` : `P(…)`, `Q(…)`, `R(…)`. Le prof écrit QT = (QP·QR/‖QR‖²)QR puis OT = QT + OQ ; le solveur écrit T = Q + k·QR (équivalent). Le schéma vaut 1 pt (rappelé en gris). |
| A2 | Distance de P à la droite (QR), hauteur du triangle PQR | poly p.20 (Cor. 1.1 b) ; annotations-2025 §8 | OK | `problemeA` a) : ‖PT‖. |
| A3 | Symétrique P′ de P par rapport à (QR) | extension plausible de A1 | MANQUE | P′ = 2T − P. Une ligne à ajouter dans `vProjPoint` et dans `problemeA` a). |
| A4 | Projection d'un vecteur sur un vecteur | S5 ex.5 (`enonce.md` p.1, `corrige-exo05.md` p.1) | OK | `Vecteurs > Projection v sur u`. |
| A5 | Valeur algébrique de la projection sur un axe unitaire | S5 ex.6 (`enonce.md` p.1, `corrige-exo06.md` p.1) | PARTIEL | `vProjVect` donne le vecteur, mais pas b·a/‖a‖. Ajouter une ligne « valeur = v·u/‖u‖ ». |
| A6 | S(x;2x;1) avec QS ⊥ QR | T25 b-i ; blanc A b ; PERIMETRE (S5 ex.2) | OK | `problemeA` b), S = `x,2x,1`. |
| A7 | S paramétré avec une autre orthogonalité (PS ⊥ QR, RS ⊥ PQ, triangle QRS rectangle en S, donc équation du 2e degré) | S5 ex.2 ; S6 ex.5 (rectangle en A) | PARTIEL | `problemeA` impose QS ⊥ QR. Contournement : `Vecteurs > Paramètre u ⊥ v`, avec u = `[x,2x,1]-[7,2,0]` (vec() évalue la différence) et v = `[3,3,1]-[1,2,3]`. |
| A8 | S sur la droite (QR) : S = Q + t·QR, avec une condition (‖QS‖ = d, S milieu, PS ⊥ QR) | poly p.20-21 ; extension de T25 a | PARTIEL | Pas de saisie « S ∈ (QR) ». Contournement : `systemeVect`, `u=[1+2t-1,…]` puis `norm(u)=3` (à tester). |
| A9 | S tel que QS soit colinéaire à un vecteur donné, ou P, Q, S alignés (un paramètre) | poly p.15-16 (Déf. 1.15, Prop. 1.8) ; S4 2025 ex.8 | PARTIEL | `Vecteurs > Paramètre colinéaires` passe par u×v = 0. Le prof pose v = λu, isole λ sur une ligne et le reporte dans l'autre (`corrige-exo08-2025.md` p.1). Cette rédaction n'est pas donnée. |
| A10 | Colinéarité en 2D avec un paramètre, cas du 2e degré (m ∈ {−2 ; 6}) | S4 2025 ex.8 a-b (`enonce-2025.md` p.2) | PARTIEL | `vParam` en mode « c » avec `1,5` / `-2,m+4` : crossP 2D, à tester. La rédaction par λ manque (voir A9). |
| A11 | Vecteur (7;a;b) orthogonal à deux vecteurs : deux paramètres | S5 ex.2 (`corrige-exo02.md` p.1) | OK | `systemeVect` : `u=[7,a,b];v=[4,3,8];w=[-5,20,9]` puis `u.v=0 and u.w=0`. Le prof résout par substitution ([1] dans [2]) ; le solveur affiche les 2 équations puis la solution. |
| A12 | Vecteur unitaire orthogonal à deux vecteurs (deux réponses ±) | Prop. 1.13 p.24 ; plausible après T25 c | PARTIEL | Deux étapes : `Produit vectoriel`, puis `Norme`. Le ± n'est pas affiché. |
| A13 | Vecteur de norme donnée, de même direction et de même sens (ou de sens contraire) | S4 ex.8 a ; S5 ex.1 ; poly p.13 (Déf. 1.11) | PARTIEL | `vNorme` donne û ; il faut multiplier à la main. |
| A14 | Norme, distance entre deux points | S4 ex.8 a ; S5 ex.1 ; poly p.16 (Prop. 1.9) | OK | `Vecteurs > Norme` avec `[5,1,4]-[2,3,0]`. |
| A15 | Angle entre deux vecteurs, angle PQR (« ① = ② », cos θ, rad et degrés) | S5 ex.3 ; poly p.19 (Déf. 1.17 `***`) ; PERIMETRE (ajout « problème A ») | OK | `Vecteurs > Produit scalaire, angle`. L'angle PQR figure aussi dans les variantes de `problemeA` (cos et degrés, sans la valeur en rad). |
| A16 | Angle donné, paramètre à trouver (ex. x tel que (QS, QR) = 60°) | extension plausible de Déf. 1.17 p.19 | MANQUE | `systemeVect` avec `u.v=norm(u)*norm(v)*1/2` peut-être (à tester). Il manque l'élévation au carré, la condition de signe et le rejet des solutions parasites. |
| A17 | Nature d'un triangle (rectangle, isocèle) ou angle en un autre sommet | S5 ex.3 ; S6 ex.5 | PARTIEL | `vScalaire` et `vNorme`, sommet par sommet. |
| A18 | Aire du triangle PQR, du parallélogramme | poly p.24 (Prop. 1.13 `***`) ; S6 ex.5 | OK | Variantes de `problemeA`, ou `Produit vectoriel` (aire du parallélogramme et du triangle). |
| A19 | Aire en 2D | S6 ex.5 ; T25 P3 c | PARTIEL | Défaut D1 : il faut taper `3/2,2,0`. |
| A20 | Aire donnée et angle droit : point C inconnu, deux solutions | S6 ex.5 (`corrige-exo05.md` p.1-2) | PARTIEL | `systemeVect` : `u=[3/2,2];v=[x-4,y+5]`, puis `u.v=0 and norm(uxv)=25/2` (à tester, D8). Le prof discute ±25/2, ce qui donne les cas [1] et [1′] : non affiché. |
| A21 | Volume du parallélépipède, interprétation si V = 0 | T25 b-ii (V = 0 : « coplanaires ! ») ; blanc A c ; poly p.25 (Prop. 1.15) | PARTIEL | `problemeA` c) ou `vMixte` donnent V. `problemeA` ne commente pas V = 0 (D5). `vMixte` dit « Coplanaires » mais calcule a·(b×c) dans l'ordre saisi. |
| A22 | Volume du tétraèdre | poly p.25 ; S6 | OK | Variantes de `problemeA`, et `vMixte`. |
| A23 | Volume donné, paramètre à trouver | extension plausible de S6 ex.6 b | MANQUE | `vMixte` ne résout que [a;b;c] = 0. Il faut ajouter une cible V, donc `solve(m=V or m=-V, p)`. |
| A24 | Coplanarité de 4 points | S6 ex.6 a (`corrige-exo06.md` p.1) | OK | `Produit mixte` avec `[1,-1,3]-[0,2,4]`, etc. |
| A25 | Coplanarité avec un paramètre (z = −2) | S6 ex.6 b (`corrige-exo06.md` p.2) | OK | `vMixte` : un vecteur contient z, et le paramètre est détecté. |
| A26 | Distance d'un point au plan (QRS), hauteur du parallélépipède (= V / aire de la base) | Prop. 1.13 et 1.15, p.24-25 | MANQUE | h = \|[a;b;c]\| / ‖b×c‖ : une ligne à ajouter dans `vMixte` et `problemeA`. |
| A27 | Démontrer que 3 points sont alignés ou non | poly p.16 (Prop. 1.8 a) ; annotations-2025 §5 | PARTIEL | Les variantes de `problemeA` testent seulement P, Q, R (par QP×QR). Le prof rédige par λ (« ×(−2) sur les deux lignes », « ×3 puis ×4 ≠ 3 »). Il n'y a pas d'outil générique. |
| A28 | Démontrer que (AB) ∥ (CD) | poly p.16 (Prop. 1.8 b) | PARTIEL | Même contournement que A27 (`Produit vectoriel` = 0). |
| A29 | Point D tel que ABCD soit un parallélogramme | poly p.9 (règle « AB = CD », encadrée, annotations-2025 fin) ; S4 ex.4 (AD = BC) | MANQUE | D = A + C − B, avec la justification AB = DC. |
| A30 | Milieu d'un segment, centre d'un parallélogramme | S4 ex.3 b ; blanc B | PARTIEL | vec() évalue `([1,2,3]+[3,3,1])/2` dans n'importe quel champ, mais il n'y a ni outil ni rédaction. |
| A31 | Centre de gravité G du triangle PQR | S4 ex.5 | PARTIEL | Même chose : `([..]+[..]+[..])/3`. |
| A32 | Point défini par une relation vectorielle (AM = ⅔AB, MA + 2MB = 0) | S4 ex.3 c ; S4 ex.5 (GA+GB+GC = 0) | MANQUE | La forme explicite se tape à la main (`A+2/3*(B-A)`). La forme implicite (M inconnu) n'est pas résolue. |
| A33 | Coordonnées inconnues d'un point à partir de AB donné | S4 ex.6 (`enonce.md` p.2) | PARTIEL | Arithmétique de vec() (B = A + AB). Aucun outil dédié. |
| A34 | Système vectoriel 3x + y = a, x − ½y = 6b | S4 ex.7 (`corrige-exo07.md` p.1) | MANQUE | 6 inconnues : `systemeVect` ne gère pas des vecteurs inconnus. |
| A35 | B est-elle une base de R³ ? (nombre de vecteurs, indépendance) | T25 b-iii ; poly p.12 (Déf. 1.9) ; annotations-2025 §3 | OK | `vMixte` ≠ 0 donne « base ». Pour {QP, QR, k}, la variante de `problemeA` le fait. La phrase « 3 vecteurs, linéairement indépendants » est à écrire soi-même. |
| A36 | Base 2D {u, v} et composantes de w (exemple du poly) | poly p.16-17 ; annotations-2025 §3 (`08` p.14) | MANQUE | `vComposantes` est 3D seulement et plante en 2D (D1). Il faut aussi le test de non-colinéarité et le système 2×2 par combinaison de lignes. |
| A37 | Composantes dans une base non orthonormée de R³ (système 3×3) | S4 ex.8 b (`corrige-exo08.md` p.1, combinaison L2 − 3L3) ; T25 b-iii (substitution) | PARTIEL | `vComposantes` affiche le système puis `solve` ; les étapes manquent (D7). Le résultat n'est pas écrit avec l'indice de base (·)_B (annotations-2025 §3). |
| A38 | Composantes de QS dans {QP, QR, k} (k peut devenir i, j ou un autre vecteur) | T25 b-iii | PARTIEL | Variante de `problemeA` : k est fixé à (0;0;1) et la résolution passe par `solve` seul (D7). Pour une autre base, utiliser `vComposantes` à la main. |
| A39 | B est-elle orthonormée ? (contre-exemple) | T25 b-iv ; S6 ex.3 | PARTIEL | `vBON` est OK (✓/✗ par norme et par produit scalaire). La variante de `problemeA` est fausse dans certains cas (D6). |
| A40 | Base orthonormée directe : u ∥ QR, v = QS/‖QS‖ (observation QS ⊥ QR), w = u × v | T25 c ; blanc A d ; BAREME P2 c | OK | `problemeA` d) ; Gram-Schmidt si QS n'est pas ⊥ QR. |
| A41 | Base orthonormée directe avec v dans le plan (a, b) : méthode du prof v = λa + μb, ‖v‖ = 1, u·v = 0, λ = ±⅓ | S6 ex.4 a (`corrige-exo04.md` p.1-2) ; PERIMETRE (S6) | PARTIEL | `vConstruire` passe par une projection (Gram-Schmidt) et donne parfois le signe opposé à celui du prof. Les équations [1] ‖v‖² = 1 et [2] u·v = 0 manquent. |
| A42 | Base orthonormée directe avec u de sens contraire, u ∥ un autre vecteur, ou v tiré de QP | variantes de T25 c-i/ii | PARTIEL | `vConstruire` avec `-5,2,-1` tapé à la main. `problemeA` ne propose que QR et QS. |
| A43 | Composantes d'un vecteur (QP, QS, OP…) dans la base orthonormée construite | blanc A e ; S6 ex.4 b | PARTIEL | `problemeA` e) traite QP seulement, par produits scalaires (OK). Pour un autre vecteur, utiliser `vComposantes` (système, comme le prof en S6 ex.4 b). |
| A44 | Vérifier que des combinaisons (2a+b, …) forment une base orthonormée | S6 ex.3 (`corrige-exo03.md` p.1-2) | OK | `vBON` avec `2*[2/5,-1/5,0]+[…]` (vec() évalue). Les vecteurs a, b, c ne sont pas mémorisés. |
| A45 | Base directe ou indirecte (signe du produit mixte) | poly p.25 (Prop. 1.14) | OK | `vMixte`, `vBON`. |
| A46 | Produits vectoriels et mixtes « intelligents » (antisymétrie, linéarité, vecteur répété) | S6 ex.2 (`corrige-exo02.md`) | PARTIEL | Calcul brut seulement ; les propriétés ne sont pas citées. |
| A47 | Angle par bilinéarité (‖a‖ et ‖b‖ connus) | S5 ex.4 (`corrige-exo04.md` p.1) | OK | `bilin` : `(2a-b)*(a+b)=0`, 3, 4. |
| A48 | Angle dans une figure 3D en littéral (centre d'un parallélépipède) | S5 ex.7 (`corrige-exo07.md` p.1) | PARTIEL | `vScalaire` avec `a/2,-b/2,-c/2` ; le placement du repère n'est pas fait. |
| A49 | S à deux paramètres et deux conditions (QS ⊥ QR et QS ⊥ QP, ou QS ⊥ QR et ‖QS‖ = d) | extension de T25 b-i et de S5 ex.2 | PARTIEL | `systemeVect` avec u = `[x-7,y-2,-4]`, etc. `problemeA` n'accepte qu'un seul paramètre. |
| A50 | Vecteurs par cap (avion, vent) | S5 ex.8 | MANQUE | Hors problème A probable (absent de PERIMETRE). Priorité basse. |

## 2. Problème B : figure, Chasles, combinaisons linéaires

| # | Question type | Source (fichier, page) | Statut | Fonction et saisie, ou ce qui manque |
|---|---|---|---|---|
| B1 | « Exprimer le plus simplement possible » avec des points quelconques (pas de figure) | S4 ex.1 a-e (`enonce.md` p.1) ; poly p.10-11 (exemples) ; annotations-2025 §1-2 | MANQUE | 5 points quelconques ne tiennent pas dans un repère 3D : l'approche par coordonnées échoue. Il faut un Chasles formel (somme de « Y − X »). |
| B2 | Chasles dans un parallélépipède ou un cube | S4 ex.2 (`corrige-exo02.md`) ; PERIMETRE « type attendu » | PARTIEL | `problemeB` > Parallélépipède : `AB+FG;AG+CD;…` donne le bon résultat. Il manque la rédaction en chaîne du prof (remplacer par un vecteur égal, puis enchaîner). |
| B3 | Chasles dans un parallélogramme avec centre et milieux | blanc B a | PARTIEL | `problemeB` > Parallélogramme : `DA+BC+MN;AM-AN+DO`. Résultat juste, chaîne absente (comme B2). |
| B4 | Chasles dans un triangle avec milieux et centre de gravité | S4 ex.5 ; préréglage | PARTIEL | `problemeB` > Triangle. Chaîne absente. |
| B5 | Chasles dans une figure composite (logo Renault, deux parallélogrammes et deux parallélogrammes tronqués) | T25 P3 a (`enonce.md` p.2 ; `corrige-prof.md` p.2 : AI, CD, 4GA, FD) | PARTIEL | Figure libre en coordonnées du quadrillage, tapées en 3D (D4). Il faut placer chaque point à la main (D2). Résultat reconnu, chaîne absente. |
| B6 | Exprimer en u = AB, v = AD (w = AE) : origine au départ des vecteurs de base | S4 ex.3 a-b ; blanc B b | OK | `problemeB` : `AM;AN;MN` donne u + ½v, etc. Le prof écrit AM = AB + BM = u + ½v : la chaîne vaudrait un plus (voir l'ajout 1). |
| B7 | Exprimer en u, v avec une base qui n'est pas celle de la figure : u = GF, v = GA (logo), u = SA, v = SB, w = SC (pyramide), t = AF au lieu de w | T25 P3 b ; S4 ex.4 ; S4 ex.3 c | MANQUE | Il n'y a pas de changement de base des sommes. Contournement : définir la figure à la main dans cette base (D2), ou `vComposantes(total, b1, b2, [0,0,1])`. |
| B8 | Pyramide à base parallélogramme | S4 ex.4 (`corrige-exo04.md` p.1 : SD = u − v + w) | PARTIEL | Figure libre `S=0;A=u;B=v;C=w;D=u-v+w`, mais D est à calculer soi-même. |
| B9 | Points définis à partir d'autres points (M milieu de [FG], N milieu de [HG], P centre de ABCD) | S4 ex.3 b (`corrige-exo03.md` p.1-2) | PARTIEL | D2 : il faut taper `M=u+w+v/2` au lieu de `M=(F+G)/2`. |
| B10 | Point défini par BJ = ½BC + ½BF | S4 ex.3 c | PARTIEL | D2, plus l'expression en u, v, t (B7). |
| B11 | Point défini par un rapport (AM = ⅓AB, AG = ⅔AI) | S4 ex.5 b ; poly p.11 (Déf. 1.8) | PARTIEL | À la main (D2). |
| B12 | Point défini par une relation implicite (GA + GB + GC = 0, MA + 2MB = 0) | S4 ex.5 a (`corrige-exo05.md` p.1) | MANQUE | Il faudrait résoudre en M inconnu, avec la rédaction « on insère O par Chasles ». |
| B13 | Démonstration du centre de gravité : OG = ⅓(OA + OB + OC), puis AG = ⅔AI | S4 ex.5 a-b | PARTIEL | Préréglage Triangle : `AG;AJ`, mais le multiple ⅔ est caché par D3. Pas de version littérale avec une origine O. |
| B14 | « En déduire MN = ½BD » | blanc B c | PARTIEL | D3. Contournement : taper `MN-1/2*BD`, qui doit donner le vecteur nul. |
| B15 | Démontrer un alignement par colinéarité dans la figure (A, G, J alignés ; E, P… alignés) | poly p.16 (Prop. 1.8 a) ; S4 ex.5 b | MANQUE | Pas de requête « XY ∥ ZT ? ». Seuls 10 multiples sont reconnus, et ils peuvent être masqués (D3). |
| B16 | Démontrer un parallélisme ou un parallélogramme (IMNK parallélogramme : IM = KN) | poly p.9 et p.16 | MANQUE | Même ajout que B15 (égalité ou colinéarité de deux vecteurs nommés). |
| B17 | Hexagone régulier de centre O | figure plausible (consigne) | PARTIEL | Pas de préréglage. Figure libre `O=0;A=u;B=v;C=v-u;D=-u;E=-v;F=u-v` si l'on connaît la construction. |
| B18 | Trapèze (AB ∥ DC, AB = k·DC) | figure plausible (consigne) | PARTIEL | Pas de préréglage. Figure libre `A=0;B=u;D=v;C=v+u/2`. |
| B19 | Cube | S4 ex.2 (même figure) | OK | Préréglage Parallélépipède. |
| B20 | Somme avec un coefficient mis en facteur : 2(AB − CD), ½(AB + AC), −(GA + FB) | poly p.11 (Prop. 1.6) ; S4 ex.3 b (½(u − v)) | MANQUE | `gmatch` ne lit que `±k*XY` : les parenthèses sont ignorées en silence. |
| B21 | Résultat qui n'est pas un vecteur unique (CD + ED, AC + BC) | poly p.10-11 (exemples remplis) ; annotations-2025 §1-2 | PARTIEL | Résultat en u, v seulement. Pas de somme de deux vecteurs nommés (lié à B1). |
| B22 | Multiples quelconques (3GA, 4GA, −3/2, 5/2) | T25 P3 a-iii (4GA) | PARTIEL | Liste fermée de 10 coefficients ; 4GA n'est pas reconnu (k = 4 absent de la liste). |
| B23 | Aire d'une figure sur un quadrillage (4 parallélogrammes − 2 triangles, en u.a.) | T25 P3 c (`corrige-prof.md` p.2) ; BAREME (unité, R12) | MANQUE | Rien. Il faut une aire par décomposition (‖AB×AG‖, ½‖AB×BE‖) et une aire de polygone en contrôle. |
| B24 | Vérifier une égalité donnée (« Montrer que AJ = ½(u + v + t) ») | S4 ex.3 c ; blanc B c | PARTIEL | Taper la différence : `AJ-…`, qui doit donner 0. Pas de mode « montrer ». |
| B25 | Soustraction : retourner le vecteur soustrait (−XY = +YX) | poly p.11 (Prop. 1.5) ; annotations-2025 §2 | PARTIEL | Le calcul gère le signe ; la ligne de rédaction « −CB = +BC » n'est pas affichée. |

### Décompte

| | OK | PARTIEL | MANQUE | Total |
|---|---|---|---|---|
| Problème A | 17 | 23 | 10 | 50 |
| Problème B | 2 | 17 | 6 | 25 |
| **Total** | **19** | **40** | **16** | **75** |

Défauts de code : 8 (D1-D8).

## 3. Ajouts priorisés (spécifications implémentables)

Ordre de priorité : points au test (BAREME : A 18 pts, B 6 pts ; T25 : P2 21, P3 10), puis probabilité de la variante, puis coût. Chaque ajout suit la rédaction du prof et ses étapes notées (R2, R9, R10 de `BAREME.md` §2).

### 1. Chaîne de Chasles rédigée dans `problemeB` (B2-B5, B6, B25)

- **Signature** : `chaineChasles(P, termes)`, appelée par `problemeB` pour chaque somme. `P` est la table nom → coordonnées. `termes` est une liste de `{signe, k, X, Y}`.
- **Étapes affichées** (rédaction `corrige-prof.md` p.2 P3 a ; annotations-2025 §1-2, `08` p.10-11) :
  1. Retournement : chaque `−XY` devient `+YX`, avec la ligne « −JH = +HJ ».
  2. Chaînage : on part du 1er terme (cur = Y). On cherche parmi les termes restants celui qui commence en cur. S'il y en a un, on enchaîne (« AG + GH = AH »). Sinon, on prend le terme suivant VW et on cherche un point Z de la figure tel que Z − cur = W − V : on remplace VW par cur Z, avec la ligne « AB = HI (figure) », puis on enchaîne.
  3. Si tous les termes sont égaux, on regroupe : « GA + FB + HD + IC = 4GA ».
  4. Si une chaîne revient au départ : « = 0 ».
  5. S'il reste plusieurs chaînes : le résultat est leur somme (« CD + ED »).
- **Sortie** : le texte de la chaîne, puis le contrôle par les coordonnées (déjà existant).
- **CAS** : `P[Z]-P[cur]-(P[W]-P[V])` doit valoir `[0,0,0]` (test d'égalité de deux vecteurs). C'est déjà fait avec `C(...)`.

### 2. Points définis par d'autres points dans `problemeB` (D2, B5, B8-B11, A30-A32)

- **Saisie** : `M=milieu(F,G)`, `M=(F+G)/2`, `J=B+1/2*(C-B)+1/2*(F-B)`, `D=A+C-B`, `G=grav(A,B,C)`, `M=A+2/3*(B-A)`.
- **Implémentation** : reprendre la boucle de substitution de `chasles` l.1874 (`for m, val in pairs(P) … gsub("%f[%u]"..m.."%f[^%w]", "("..val..")")`). Attention : substituer les noms les plus longs d'abord, et ne pas toucher u, v, w. Ajouter une macro `milieu(X,Y)`, qui devient `((X)+(Y))/2`, et `grav(X,Y,Z)`, qui devient `((X)+(Y)+(Z))/3`.
- **Coordonnées numériques 2D** (D4) : si un point a 2 composantes, compléter avec `,0`.
- **Étapes affichées** : « M milieu de [FG] : AM = AF + ½FG = u + w + ½v » (rédaction `corrige-exo03.md` p.1-2).

### 3. Expression dans une base choisie (B7, T25 P3 b, S4 ex.3 c, S4 ex.4)

- **Saisie** : un 3e champ de `problemeB`, `base = GF,GA` (ou `SA,SB,SC`, ou `AB,AD,AF`), vide par défaut (base naturelle).
- **Calcul** : pour chaque somme, `solve(total=α*(P[F]-P[G])+β*(P[A]-P[G])(+γ*…),{α,β,γ})` avec la commande CAS `solve(... ,{α,β,γ})`. Vérifier d'abord l'indépendance : en 2D, `crossP(b1,b2)≠0` ; en 3D, `det(augment(augment(b1,b2),b3))≠0` (forme colonne via `colAugment`, ou `dotP(b1,crossP(b2,b3))`).
- **Sortie** : « HF = −u + v » ; « AI = 3u − 2v ».
- **Étapes** : la chaîne de l'ajout 1 en vecteurs nommés, puis le remplacement de chaque maillon par un multiple de u ou de v. Le prof écrit, pour T25 b-iii : AI = AB + BF + FD + DH + HI = GF − GA + GF − GA + GF = 3u − 2v.

### 4. Rédaction et robustesse de `problemeA` (D5, D6, D7, A21, A37-A39)

- c) Afficher la formule dans l'ordre du prof, V = |[QP;QS;QR]| = |QP·(QS×QR)| (`corrige-prof.md` p.2), avec QS×QR intermédiaire. Si m = 0, ajouter `A("V = 0 : QP, QR, QS coplanaires (pas de parallélépipède, pas une base)")`.
- Composantes dans B = {QP, QR, b3} : choix de b3 au lancement (défaut k = `0,0,1`). Afficher L1, L2, L3, puis résoudre comme le prof par substitution :
  - α := `solve(L1,α)` ;
  - β := `solve(L2|α=…,β)` ;
  - γ := `solve(L3|α=…andβ=…,γ)` ;
  - résultat noté `(α;β;γ)_B`.
  Commandes : `solve(eq,α)`, opérateur `|`.
- B orthonormée ? : tester les 3 normes et les 3 produits scalaires, puis citer le premier contre-exemple (« QP·k = 2 ≠ 0 : pas orthogonale ; ‖QR‖ = √30 ≠ 1 : pas normée »).
- Même affichage par étapes dans `vComposantes` (S4 ex.8 b, S6 ex.4 b).

### 5. Condition de S au choix : `pointParam(Ps,Qs,Rs,Ss,cond)` (A7-A9, A16, A20, A23, A49)

- **Conditions** (menu) :
  - `QS⊥QR` (défaut) ;
  - `XY⊥ZT`, deux vecteurs quelconques entre P, Q, R, S ;
  - `XY∥ZT` ;
  - `S∈(QR)` : S = Q + t·QR, plus une seconde condition ;
  - `‖QS‖=d` ;
  - `aire(QRS)=a` ;
  - `angle(QS,QR)=θ` ;
  - `PQRS coplanaires` ;
  - `volume=V`.
- **Étapes et CAS** :
  - ⊥ : `expand(dotP(u,v))=0`, puis `solve` ;
  - ∥ : rédaction par λ, `solve(u[1]=λ*v[1],λ)` reporté dans les autres lignes (`corrige-exo08-2025.md` p.1). Contrôle : `crossP(u,v)=[0,0,0]` ;
  - norme : `norm(u)^2=d^2` (élevé au carré, on n'a pas besoin de racine) ;
  - aire : `norm(crossP(u,v))^2=(2a)^2`, ou en 2D la discussion ±, cas [1] et [1′] comme `corrige-exo05.md` p.1 ;
  - angle : `dotP(u,v)=cos(θ)*norm(u)*norm(v)`. Mettre au carré, puis rejeter les solutions où `sign(dotP)≠sign(cos θ)` ;
  - coplanarité ou volume : `solve(m=V or m=-V,p)`.
- **Deux inconnues** : condition supplémentaire, puis `solve(... and ...,{x,y})`.
- Brancher dans `problemeA` b) à la place de la condition fixe.

### 6. Aires 2D et aire de figure (D1, A19, B23)

- Corriger `vVectoriel`, `vComposantes` et `comp` : si une composante manque, compléter avec `0`. En 2D, afficher seulement la composante z : AB×AC = (0;0;x₁y₂ − y₁x₂).
- **Nouvel outil** : `aireFigure(points, pieces)`. `points` est `A=-1,4;B=1,4;…`. `pieces` est `4*par(A,B,G)-2*tri(A,B,E)`, où `par(X,Y,Z)` = ‖XY×XZ‖ et `tri` = ½‖…‖.
- **Étapes** : composantes de chaque vecteur, produit vectoriel, aire de chaque morceau, puis total en u.a. (`corrige-prof.md` p.2 P3 c ; R12).
- **Contrôle** : formule des lacets, `½|Σ(xᵢyᵢ₊₁ − xᵢ₊₁yᵢ)|`, sur le contour s'il est saisi.

### 7. Outil « points » : `vPoint(op, …)` (A3, A29-A33, B12)

- **Opérations** :
  - milieu `(A+B)/2` ;
  - centre de gravité `(A+B+C)/3` ;
  - D tel que ABCD soit un parallélogramme : `D=A+C-B`, justifié par AB = DC (poly p.9) ;
  - symétrique de P par rapport à un point ou à une droite (2T − P) ;
  - point par rapport : AM = k·AB ;
  - point par relation implicite αMA + βMB (+γMC) = 0 : on pose M = [m1,m2,m3], on calcule `solve(α*(A-M)+β*(B-M)=[0,0,0],{m1,m2,m3})` ; rédaction « on insère O : (α+β)OM = αOA + βOB » (`corrige-exo05.md` p.1) ;
  - A ou B inconnu à partir de AB (S4 ex.6).
- **Sortie** : les coordonnées, plus la ligne de rédaction (« OM = OA + AM »). Mémoriser le point dans `HIST`.

### 8. Colinéarité, alignement et parallélisme rédigés : `vColin(u, v)` (A9, A10, A27, A28, B15, B16)

- **Entrées** : deux vecteurs (ou 3 points pour un alignement, ou 4 points pour un parallélisme), avec ou sans paramètre, en 2D ou en 3D.
- **Étapes** (poly p.15-16, Déf. 1.15 et Prop. 1.8 ; annotations-2025 §5) :
  1. « u et v colinéaires ⇔ ∃λ, v = λu » ;
  2. on écrit les lignes ;
  3. λ tiré de la 1re ligne non nulle ;
  4. report dans les autres lignes : « ×(−2) sur les deux lignes ⇒ colinéaires », ou « ×3 puis ×4 ≠ 3 ⇒ non colinéaires ».
  
  Avec un paramètre m, on obtient une équation en m (résolue par Δ si elle est du 2e degré). Commandes : `solve(v[i]=λ*u[i],λ)`, `solve((v[j]=λ*u[j])|λ=…,m)`.
- **Dans `problemeB`** : une requête `XY//ZT` dans la liste des sommes affiche « XY = k·ZT, donc (XY) ∥ (ZT) », et « alignés » si les deux vecteurs ont un point commun.
- Corriger D3 : afficher les égaux **et** les multiples. Accepter tout k rationnel (`C(ct[i]/ca[i])` constant sur les composantes non nulles), pas seulement la liste fermée (B22).

### 9. Vecteur unitaire orthogonal, vecteur de norme donnée : `vUnitOrtho(a, b)` et une option de `vNorme` (A12, A13)

- **Étapes** : n = a×b (méthode du prof : recopier les 2 premières lignes et croiser, poly p.23), contrôles n·a = 0 et n·b = 0, ‖n‖, puis **deux** réponses ±n/‖n‖. Option « norme d » : d·û ou −d·û selon le sens demandé.
- **CAS** : `crossP`, `norm`, `unitV`.

### 10. Base orthonormée par la méthode du prof : `vConstruire` en mode λ, μ (A41, A42)

- **Entrées** : a (direction de u), sens (+ ou −), b (plan de v), option « v = vecteur donné ⊥ ».
- **Étapes** (`corrige-exo04.md` p.1-2) :
  1. u = ±a/‖a‖ ;
  2. v = λa + μb ;
  3. [1] ‖v‖² = 1 développé : `expand(norm(λ*a+μ*b)^2)=1` ;
  4. [2] u·v = 0 : `expand(dotP(u,λ*a+μ*b))=0` ;
  5. [2] dans [1] donne λ = ±… On garde λ > 0 et on signale que l'autre signe est aussi juste ;
  6. w = u × v.
  
  Commande : `solve(eq1 and eq2,{λ,μ})`.

### Suivants (priorité plus basse)

11. **Base 2D et composantes** (A36) : `vComposantes2(w, b1, b2)`. Justifier « 2 vecteurs non colinéaires », puis résoudre le système 2×2 par combinaison (1)+(2), et écrire le résultat avec l'indice de base (annotations-2025 §3 ; poly p.16-17).
12. **Chasles formel avec des points quelconques** (B1, B21) : chaque vecteur XY est représenté par la somme formelle {Y:+1, X:−1}, en Lua pur, sans CAS. Si le total vaut {Y:+1, X:−1}, la réponse est XY. Sinon, on apparie les + et les − en chaînes et on affiche « AC + BC » (S4 ex.1 ; poly p.10-11).
13. **Parenthèses et facteurs dans les sommes** (B20) : passer chaque somme au parseur `arbre()` existant, ou développer `k(…)` avant `gmatch`.
14. **Distance au plan et hauteur** (A26) : h = |[a;b;c]| / ‖b×c‖ dans `vMixte` et `problemeA`. **Symétrique** (A3) et **valeur algébrique de la projection** (A5) : une ligne chacun.
15. **Préréglages de figures** (B8, B17, B18) : pyramide `S=0;A=u;B=v;C=w;D=A+C-B`, hexagone régulier, trapèze (k demandé), logo T25 (points du quadrillage). Ces préréglages passent par l'ajout 2.
16. **Système vectoriel 3x + y = a, x − ½y = 6b** (A34) : inconnues x = [x1,x2,x3] et y = [y1,y2,y3]. Résolution composante par composante, avec `solve(3*x1+y1=25 and x1-y1/2=-54,{x1,y1})` sur chaque couple de lignes, comme le prof (accolades de couleur, `corrige-exo07.md` p.1).
17. **Propriétés des produits** (A46) : mémoriser a, b, c et annoncer la propriété utilisée (antisymétrie, vecteur répété donc 0, linéarité).
18. **Vecteurs par cap** (A50) : hors périmètre probable.
