# Couverture du solveur Lua (`lua/solveur.lua`) — séries 1-7, examen blanc 1, test 2025

> Inventaire du 10.11.2026, établi en lisant le code de `solveur.lua` (commit 46059ab) : les sorties n'ont pas été testées sur la calculatrice.
> **OK** : la fonction donne la rédaction attendue. **PARTIEL** : le résultat est juste mais il manque des étapes du prof, ou il faut une saisie détournée. **MANQUE** : aucune fonction adaptée.
> Notations : `auto` = menu « Résoudre (automatique) » ; `Outils >` = menu « Outils séries 1 à 3 » ; `Vecteurs >` = menu « Vecteurs ».
> Pièges de saisie relevés dans le code :
> - `auto` envoie toute expression qui contient `/` et `x` vers `analyse`. Pour simplifier une fraction, passer par `Outils > Simplifier`.
> - `variable()` ne reconnaît que x, u, t et a. Une équation en y, h ou v n'est pas reconnue.
> - Le paramètre de `vMixte` n'est cherché que parmi m, t, k, λ et x : il faut renommer z en x.
> - `vec()` n'évalue pas les sommes de vecteurs : il faut taper les composantes déjà calculées.

## 0. Mise à jour du 10.11.2026 (après implémentation)

Les 8 manques de la section 2 et les manques « hors périmètre » sont implémentés dans `lua/solveur.lua` et testés dans le logiciel TI (vue calculatrice) :

| Manque (section 2) | Où dans le solveur | Test |
|---|---|---|
| 1. Valeur absolue par cas | Résoudre (auto) : `abs(x-1)/(x+2)>=1/2` | ✓ S = ]−2 ; 0] ∪ [4 ; +∞[ |
| 2. Bijection sur I imposé, f⁻¹, vérification, courbes ; variations par la forme a+b/… | 7 Fonctions → Bijection sur I ; 2 Analyse h) | ✓ exo 7 : J = ]1/2 ; +∞[, f⁻¹ = √((3x+1)/(2x−1)) ; cadrage des courbes à revoir |
| 3. Chasles sur figure | 8 Figure (parallélogramme, parallélépipède, triangle, figure libre) | ✓ AG+GH+AB = AG |
| 4. Domaine avec racines | Résoudre (auto) : `sqrt((x-2)/(x+2))` ; 7 → Domaine | ✓ ]−∞ ; −2[ ∪ [2 ; +∞[ |
| 5. Systèmes vectoriels | 9 → Système (`u=[a,b,1];v=…` puis `u.v=0 and u.w=0`) | ✓ équations affichées et résolues |
| 6. Vecteurs par expression | toute saisie de vecteur : `[7,2,5]-[-1,-7,7]` | non testé visuellement |
| 7. Angle par bilinéarité | 9 → Bilinéarité | ✓ a·b = 1, cos θ = 1/6 |
| 8. Équations irrationnelles | Résoudre (auto) : `3+sqrt(3x+1)=x` | ✓ x = 1 rejetée, S = {8} |
| Hors périmètre : logarithmes, parité, composition, factorisation littérale, isoler une lettre | auto (`ln(…)`), 7 → Parité / Composition, 10 Calcul littéral | ✓ tous testés une fois |

Restent : la mise en page des étapes de la bilinéarité (ligne « Développé » brute), le cadrage du tracé f / f⁻¹ près d'une asymptote, les inéquations bicarrées sans étape « X = x² » explicite (le tableau de signes reste juste), les vecteurs par cap (S5 ex.8) et le centre de gravité (S4 ex.5) qui se traitent avec la figure libre.

## 1. Tableau exercice → statut

### Série 1

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a) 2a³b−4ab³ | MANQUE | Factorisation à plusieurs lettres. `factor(2a^3*b-4a*b^3)` dans Calculs suffit, mais sans étapes (mise en évidence, a²−b²). |
| 1 b) a³b+ab³−2a²b² | MANQUE | Même cas (ab(a−b)²). |
| 1 c) a²−2a−3 | OK | `auto` : `a^2-2a-3` → `signePoly` (variable a), Δ puis factorisation. |
| 1 d) a⁴b+ab⁴ | MANQUE | Plusieurs lettres (ab(a+b)(a²−ab+b²)). |
| 1 e) a²b⁶−0,25 | MANQUE | Plusieurs lettres (différence de carrés). |
| 1 f) a⁸−1 | OK | `auto` : `a^8-1` (factorisation dans ℝ, avec le signe en prime). |
| 1 g) h) i) j) | OK | `auto` : `1+a+a^2+a^3`, `1+a-a^2-a^3`, `1-a+a^2-a^3`, `-2a^2-a+1` → racine évidente puis division. Le prof factorise par groupement, ce que le solveur ne montre pas. |
| 1 k) a²+ac+ab+bc | MANQUE | Plusieurs lettres, groupement. |
| 1 l) 7a−7a⁵ | OK | `auto` : `7a-7a^5`. |
| 1 m) a²−1+ab+b | MANQUE | Plusieurs lettres, groupement. |
| 2 a) | PARTIEL | `Outils > Simplifier` : `(14b^4*5a*y)/(15a^2*x*7b^3*y)`. Le résultat est juste, mais les conditions ne portent pas sur les monômes. |
| 2 b) c) d) | OK | `Outils > Simplifier` : `(a*x*y-b*x*y)/(a*b-b^2)`, `(a-3)/(2a^2-18)`, `((a+b)^2*(a^3-b^3))/((a^2-b^2)^2)`. |
| 3 a) c) d) | PARTIEL | `Outils > Simplifier` avec l'expression entière (`comDenom`). Les étapes intermédiaires du prof (fraction de fraction, dénominateur commun écrit) ne sont pas montrées. |
| 3 b) (8ⁿ⁺¹+8ⁿ)²/(4ⁿ−4ⁿ⁻¹)³ | MANQUE | Simplification de puissances : écrire en base 2 et mettre en évidence. Le CAS ne simplifie pas toujours les exposants symboliques n. |
| 4 a-g (radicaux) | PARTIEL | `auto` (branche « Calcul ») : `(sqrt(3)+sqrt(2))^2`. Résultat seul, sans identité remarquable ni conjugué. |
| 5 a-f | OK | `auto` (Calcul) : `2^4*3^4`, `(-7a)^3*(-b)^3*(-2c)^3`. La règle aⁿbⁿ=(ab)ⁿ n'est pas affichée. |
| 6 | PARTIEL | Vérification : `auto` (Calcul) `expand((2^(2n+1)-2^(n+1)+1)*(2^(2n+1)+2^(n+1)+1))`. La déduction n=14 pour 2⁵⁸+1 est MANQUE. |
| 7 a-m | OK | `auto` : `(x-2)(x+3)=0`, …, `25-9x^2-(3x+5)^2=0` → `equation` (factorisation, produit nul) ; i) donne S=∅. |
| 8 a) qx=1−px, d) qx+1=q²+x | PARTIEL | `auto` passe par `parametre` (paramètre p ou q, 1er degré). La discussion « coefficient nul » est faite. Le cas de q n'est pas sûr, car q n'est pas dans la liste des paramètres (m, λ, k, a, p, b). |
| 8 b) c) e-k (inconnue y, v, h) | MANQUE | Résolution littérale pour une lettre choisie : `solve(eq,y)` avec les conditions d'existence. |
| 9 a) b) c) | OK | `auto` : `1/(x+1)<=-1`, `(1-2x)/(x+1)<=1`, `(x+2)/(2x-4)<=(5-2x)/(x-2)+3` → tableau de signes. |
| 10 a-h | MANQUE | Isoler chaque lettre d'une formule (résolution littérale avec contraintes de signe : r>0, √). |

### Série 2

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a-h | OK | `auto` : `x^2-3x+2=0`, `x^2/2+x+6=0`, `x^2=x+6`… (Δ et solutions). |
| 1 i) j) (variable u) | OK | `auto` : `u^2+7u-3=0` (u est renommé en x pour le calcul puis réaffiché en u). |
| 1 k) l) m) n) | OK | `auto` : `x^2-2m*x+m^2-1=0`, `-4x^2+9λx-2λ^2=0`, `a*x^2+(a^2-1)x-a=0`, `(m^2-1)x^2-2m*x+1=0` → `parametre` (cas a=0, signe de Δ). |
| 2 a-e (coefficients en √) | PARTIEL | `auto` : `sqrt(3)x^2-4x+2sqrt(3)=0`. Le résultat est juste ; la factorisation détaillée avec des radicaux n'est pas fiable (racine évidente). |
| 2 f) g) | OK | `auto` : `9x^2+3(2m+1)x+m(m+1)=0`, `3m*x^2-(m+3)x+1=0`. |
| 2 h) i) (deux lettres a, b) | PARTIEL | `parametre` prend a, mais b reste symbolique. Δ=(a−b)² est affiché ; le tableau de signes de Δ échoue. Solutions justes via le contrôle CAS. |
| 3 a) x^(2/3)+x^(1/3)−6=0 | OK | `Outils > Changement de variable` : équation `x^(2/3)+x^(1/3)-6=0`, puis `X = x^(1/3)`. |
| 3 b) (t/(t+1))²−2t/(t+1)−8=0 | PARTIEL | `Outils > Changement` avec `X = t/(t+1)`. Il manque la condition t≠−1 et le refus explicite de X=1. |
| 3 c) 3+√(3x+1)=x | MANQUE | Équation irrationnelle : condition d'existence, isoler la racine, condition de signe, élever au carré, éliminer les solutions parasites. |
| 3 d) √(2x−3)−√(x+7)+2=0 | MANQUE | Même cas, avec deux mises au carré. |
| 4 a-k | OK | `auto` : `(x-3)/(x-5)=5`, `1/(x-1)-1/x+1/(x+1)=1/(x^3-x)`… → valeurs interdites, numérateur nul, rejet. |
| 5 a-d | OK | `auto` : `-3x+7>0`, `-x^2+x<-2`, `x^2<=0`, `x^2-8x+12>0`. |
| 5 e) f) | PARTIEL | `auto` : `x^4-8x^2+12>0`, `x^6-8x^3+12>0`. Tableau juste, mais sans l'étape du prof « on pose X=x² (x³) ». |
| 6 \|−x+4\| > −3/x | PARTIEL | `auto` : `abs(-x+4)>-3/x`. Les deux cas sont posés, mais chacun est résolu directement par `solve`, sans tableau de signes par cas (le prof en dresse un). |

### Série 3

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a) b) | OK | `Outils > Division` : A=`x^3+2x^2-3`, B=`x^2+x+1` ; A=`x^6-1`, B=`x+1`. |
| 2 a-g | OK | `auto` : `2x^3-3x^2+1=0`… → racine évidente, division, Δ. |
| 2 h) i) j) l) (bicarrées, a⁶/a³) | OK | `auto` : `x^4-2x^2+1=0`, `4a^4-4a^2+3=0`, `u^4+2u^2-24=0`, `7a^6-48a^3-7=0` → changement X=x² (X=a³). |
| 2 k) m) | OK | `auto` : `a^4-a^3-6a^2=0`, `u^4+u^3-u^2-u=0`. |
| 3 a-m | OK | `auto` : `x^2-3x+2`, …, `x^3-7x^2-4x+28` → `signePoly` (factorisation et tableau de signes). |
| 4 a-c (ln, log) | PARTIEL | `auto` (Calcul) : `ln(18)-ln(6)+2ln(3)`. Résultat seul, sans les propriétés des logarithmes. |
| 5 a) e^(4x)=76 | PARTIEL | `auto` : `e^(4x)=76` → X=eˣ, X⁴=76. C'est juste mais lourd ; le prof prend directement ln. |
| 5 b) c) | OK | `auto` : `e^(2x)+4e^(x)-21=0`, `e^(3x)-7e^(x)+6=0`. |
| 5 d) log(x²−10x+121)=2 ; e) log₂(x²−3x)=2 | MANQUE | Équation logarithmique : domaine (argument > 0), passage 10² / 2², puis équation du 2nd degré. |
| 6 I(t) → t | MANQUE | Résolution littérale (ln) et esquisse de I(t). |

### Série 4

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a-e, 2 a-f | MANQUE | Chasles symbolique (simplifier une somme de vecteurs nommés par des points, avec les égalités de la figure). |
| 3 a-c, 4 | MANQUE | Combinaison linéaire dans une base (u, v, w) d'après une figure (milieux, centres). |
| 5 a) b) | MANQUE | Centre de gravité : démonstration vectorielle littérale. |
| 6 a-d | PARTIEL | `auto` (Calcul) : `[8,-2]-[5,3]`, `[3/4,-2/3]+[3,5/3]`… Calcul brut sans l'équation coordonnée par coordonnée. |
| 7 système vectoriel | MANQUE | Système 2×2 en vecteurs (3x+y=a, x−y/2=6b) résolu composante par composante. |
| 8 a) | OK | `Vecteurs > Norme` : `8,-5,4`, `-5,9,3`, `3,12,4`. |
| 8 b) | OK | `Vecteurs > Composantes` : w=`8,-13,7`, b1=`8,-5,4`, b2=`-5,9,3`, b3=`3,12,4`. |

### Série 5

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a-d | OK | `Vecteurs > Norme` : `3,4` ; `sqrt(7)/3,-sqrt(2)/3` ; `2/sqrt(2),-2sqrt(3),2/sqrt(6)` ; `3/2,2,6`. |
| 2 (a, b : ⊥ à deux vecteurs) | MANQUE | `vParam` ne traite qu'une condition et un paramètre. Il faut un système de deux produits scalaires nuls d'inconnues a et b : `solve(28+3a+8b=0 and -35+20a+9b=0,{a,b})`. |
| 3 a) b) | OK | `Vecteurs > Produit scalaire, angle` : `1,2` / `1,4` ; `1,2,1` / `1,4,1`. |
| 3 c) | OK | Même menu, 3 fois : `3,-1,2` avec `1,0,0`, `0,1,0`, `0,0,1`. |
| 4 (‖a‖=3, ‖b‖=4, bilinéarité) | MANQUE | Développer (2a−b)·(a+b)=0 → 2‖a‖²+a·b−‖b‖²=0 → a·b, puis cos θ. Calcul littéral sans composantes. |
| 5 | OK | `Vecteurs > Projection v sur u` : v=`1,-2,1`, u=`4,-2,3`. |
| 6 a-c (valeur algébrique) | PARTIEL | `Vecteurs > Produit scalaire` donne a·b et ‖a‖, mais la valeur b·a/‖a‖ n'est pas affichée en résultat (`vProjVect` donne le vecteur). |
| 7 (angle APB littéral) | PARTIEL | `Vecteurs > Produit scalaire` : `a/2,-b/2,-c/2` / `-a/2,b/2,-c/2`. Probablement le cos littéral, mais la mise en place du repère n'est pas faite (non testé). |
| 8 (avion, vent) | MANQUE | Vecteurs par cap (cos/sin), somme, norme et cap résultant. |

### Série 6

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a-c | OK | `Vecteurs > Produit vectoriel` : `3,-1,2` / `4,1,0`, etc. |
| 2 a) | PARTIEL | `Produit vectoriel`, en tapant les combinaisons déjà calculées (a+b = `2,4,5`). Les propriétés (antisymétrie, linéarité) que le prof veut voir ne sont pas montrées. |
| 2 b) | PARTIEL | `Produit mixte` sur des vecteurs calculés à la main. Même manque : [a;c;a]=0 parce qu'un vecteur est répété, multilinéarité. |
| 3 | PARTIEL | `Vecteurs > Base orthonormée directe ?` avec 2a+b, −a+2b, b−c calculés à la main (vec() n'évalue pas les sommes). |
| 4 a) | OK | `Vecteurs > Construire une BON` : a=`1,2,2`, b=`1,0,1` (Gram-Schmidt : v=(2;−2;1)/3, l'autre signe que le prof, aussi juste). |
| 4 b) | OK | `Vecteurs > Composantes` : w=`4,-1,2`, base u, v, w obtenue en a). |
| 5 (C : rectangle en A, aire 25/4) | MANQUE | Point inconnu sous deux conditions (AC·AB=0 et ½\|det(AB,AC)\|=25/4), deux solutions. |
| 6 a) | OK | `Produit mixte` : AB=`1,-3,-1`, AC=`-8,0,-3`, AD=`-6,-6,-5` (différences tapées à la main). |
| 6 b) (z) | PARTIEL | `Produit mixte`, en renommant z en x : AD=`-11/3,-11/3,x-9` (z n'est pas reconnu comme paramètre). |

### Série 7

| Exo | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| 1 a) b) | OK | `auto` : `1/(x^2-1)`, `1/(x^2+1)` → `analyse` partie a) (le reste de l'analyse s'affiche aussi). |
| 1 c-g (racines) | PARTIEL | Pas de domaine avec √. Il faut se ramener à une inéquation : `auto` `x^2-1>=0`, `1-x^2>0`, `x(x^2-5x-6)>=0`, `(x-2)/(x+2)>=0`, `-x^2+4x-3>=0`. Il manque la rédaction « f existe ⇔ … [*] ». |
| 2 a) 3x+5 | MANQUE | `auto` envoie vers `signePoly` (pas de fraction) : il manque l'injectivité/surjectivité d'une fonction affine (ou analyse de `(3x+5)/1`, à tester). |
| 2 b) c) d) | PARTIEL | `Analyse` : `1/x`, `(x-2)/(x-3)`, `(1-2x)/(x-2)`. La réciproque et I_f sont donnés ; la bijection n'est pas vérifiée sur les ensembles imposés (ℝ*₊, ℝ∖{3}→ℝ∖{1}). |
| 3 f∘g, g∘f | MANQUE | Composition et domaine (conditions croisées). |
| 4 a-f parité | MANQUE | Calcul de f(−x) comparé à f(x) et −f(x). |
| 5 | OK | `Identifier` : f=`(x^3-x^2+x+1)/(x^2+1)`, forme `a*x+b+c/(x^2+1)` → identification et asymptote oblique. |
| 6 a-c extremums | MANQUE | Parabole : sommet −b/(2a), signe de a, comparaison aux bornes de l'intervalle. |
| 7 a-g | OK | `auto` : `(x^2+1)/(2x^2-3)` → `analyse` a)…j) (domaine, a+b/…, AH, ± réciproque, I_f par tableau en y, cadres I×J, graphe). |
| 7 h) courbe de f⁻¹ | PARTIEL | Le graphe ne trace pas f⁻¹ (symétrie par rapport à y=x). |
| 8 a) | OK | `Factoriser un polynôme (détail)` : `x^3-3x^2`, `x^3+x^2-8x-12`. |
| 8 b) c) | OK | `auto` : `(x^3-3x^2)/(x^3+x^2-8x-12)` → zéros/pôles avec ordre, asymptotes. |

### Examen blanc 1 (`examens/2026/blancs/blanc-1/enonce.html`)

| Question | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| A a) projection de P sur (QR) | OK | `Vecteurs > Projection d'un point` : `P(7;2;0)`, `Q(1;2;3)`, `R(3;3;1)`. |
| A b) S(x;2x;1), QS ⊥ QR | OK | `Vecteurs > Paramètre u ⊥ v` : `x-1,2x-2,-2` / `2,1,-2`. |
| A c) volume | OK | `Produit mixte` : QP=`6,0,-3`, QR=`2,1,-2`, QS=(valeurs trouvées en b). |
| A d) BON directe | OK | `Construire une BON` : a=`2,1,-2`, b=QS. |
| A e) composantes de QP | OK | `Composantes` : w=`6,0,-3`, b1, b2, b3 = u, v, w de d). |
| B a) b) c) Chasles, parallélogramme | MANQUE | Chasles symbolique et combinaisons linéaires (milieux, centre). |
| C a-e | OK | `auto` : `(2x^2-2)/(x^2-4)` → domaine, zéros et pôles d'ordre 1, tableau, a=2, b=6, AH y=2, AV x=±2, x=±√((4y−2)/(y−2)), I_f. |
| C f) variations justifiées | PARTIEL | Le tableau vient de f', que le prof n'attend pas (avant le chapitre des dérivées) : il manque la justification par la forme a+b/(x²−4). |
| C g) J, f⁻¹ sur I=[0;2[, vérification, courbe de f⁻¹ | PARTIEL | Cadre I×J listé et ± choisi par le texte, mais il manque la restriction à un I saisi, la vérification f(f⁻¹(x))=x et le tracé de f⁻¹. |

### Test 2025 (`examens/2025/txt/enonce.md`)

| Question | Statut | Fonction / saisie, ou ce qui manque |
|---|---|---|
| P1 a) (mx)²−2mx−3=0 | OK | `auto` : `(m*x)^2-2m*x-3=0` → `parametre`. |
| P1 b) 6e^(3x)+5e^(2x)−2eˣ−1=0 | OK | `auto` : `6e^(3x)+5e^(2x)-2e^(x)-1=0` → X=eˣ, degré 3 (racine évidente −1), rejets X≤0. |
| P1 c) \|x−1\|/(x+2) ≥ 1/2 | PARTIEL | `auto` : `abs(x-1)/(x+2)>=1/2`. Deux cas, mais chaque cas est résolu par `solve`, sans « tout à gauche, même dénominateur, tableau » (1 pt de tableau au barème). |
| P2 a) | OK | `Projection d'un point` : `P(-1;-7;7)`, `Q(7;2;5)`, `R(2;0;6)`. |
| P2 b-i) | OK | `Paramètre u ⊥ v` : `x-7,x,x-5` / `-5,-2,1`. |
| P2 b-ii) | OK | `Produit mixte` : QP, QR, QS. |
| P2 b-iii) | OK | `Composantes` (valeurs par défaut du menu). |
| P2 b-iv) | OK | `Base orthonormée directe ?` : QP, QR, k. |
| P2 c) | OK | `Construire une BON` : a=QR=`-5,-2,1`, b=QS=`-1,2,0`. |
| P3 a) b) | MANQUE | Chasles et combinaisons linéaires sur figure. |
| P3 c) surface | MANQUE | Aire par décomposition sur quadrillage (det 2×2 possible via `Produit vectoriel` avec z=0, sans rédaction). |

**Bilan** (une ligne du tableau = une unité, sous-questions regroupées quand le traitement est identique) : **OK 52, PARTIEL 25, MANQUE 26**.

## 2. Fonctionnalités manquantes, triées par rentabilité pour le test du 16.11

Périmètre (`examens/2026/PERIMETRE.md`) : problème A vecteurs (S4 ex.8, S5, S6), problème B Chasles (S4 ex.2-3), problème C analyse de fonction (S7 ex.7 et un peu de l'ex.8). Les séries 1-3 ne servent que d'outils.

### 1. Inéquation avec valeur absolue : tableau de signes dans chaque cas (test 2025 P1 c, S2 ex.6)
- **Rédaction du prof** : poser « si A ≥ 0, |A| = A ; si A < 0, |A| = −A ». Dans chaque cas, tout passer à gauche, mettre au même dénominateur, factoriser, dresser le tableau de signes (double barre sous la valeur interdite), puis **intersecter** avec la condition du cas. S = réunion des deux cas.
- **CAS** : `comDenom(g-d,x)`, `factor(getNum(…))`, `zeros(…,x)`, `solve(… and x>=1,x)` en contrôle.
- **Implémentation** : dans la branche `abs` de `inequation`, appeler la branche « rationnelle » (tableau) sur c1 et c2, puis intersecter les intervalles avec la condition du cas.
- Couvre : test 2025 P1 c, S2 ex.6.

### 2. Variations sans dérivée, choix de I, f⁻¹ restreinte et vérifiée, tracé de f⁻¹ (blanc 1 C f-g, S7 ex.7 g-h)
- **Rédaction du prof** : variations lues sur la forme a + b/(x²−4) (x² croît sur [0;+∞[, donc x²−4 croît, donc 1/… décroît, et le signe de b conclut), extremums par le tableau. Bijection : I donné (ou choisi parmi les 4 cadres), J=f(I) aux bornes (limites), f⁻¹ avec le bon signe du ±, vérification f(f⁻¹(x))=x, puis courbe de f⁻¹ symétrique par rapport à y=x, asymptotes échangées.
- **CAS** : `limit(f,x,2,-1)`, `f(x)|x=0`, `solve(y=f(x),x) | x>=0 and x<2`, `simplify(f(g(x)))`.
- **Implémentation** : demander I dans `analyse` i), sélectionner la branche de f⁻¹ par un point test ; ajouter au graphe la courbe miroir (échange x↔y) et la droite y=x.
- Couvre : blanc 1 C f, g ; S7 ex.7 g, h ; S7 ex.2 b-d.

### 3. Chasles et combinaisons linéaires par coordonnées (problème B : S4 ex.1-4, blanc 1 B, test 2025 P3)
- **Rédaction du prof** : remplacer les vecteurs égaux de la figure (parallélogramme : DA = CB…), enchaîner par Chasles (XY + YZ = XZ), écrire le résultat le plus court. Pour une base : AM = AB + BM = u + ½v, etc.
- **CAS** : aucune commande symbolique de Chasles. Contournement : placer la figure dans un repère (A=0, u=[1,0,0], v=[0,1,0], w=[0,0,1], points en coordonnées), calculer la somme et la reconnaître (`solve(s=α*u+β*v+γ*w,{α,β,γ})`).
- **Implémentation** : un menu « Figure » (parallélogramme ABCD de centre O, parallélépipède ABCDEFGH avec milieux) où l'on tape une somme `AB+FG-CD`. Le solveur l'exprime en (u,v,w) et cherche le point X tel que la somme vaille AX (vecteur nommé). Cela vaut 6 à 10 points au test.
- Couvre : S4 ex.1, 2, 3, 4 ; blanc 1 B ; test 2025 P3 a, b.

### 4. Domaine avec racines carrées « f existe ⇔ … » (S7 ex.1 c-g, ex.3)
- **Rédaction du prof** : conditions numérotées [*] (radicande ≥ 0), [1] (dénominateur ≠ 0), [2] (radicande > 0 sous un dénominateur) ; chaque condition est factorisée et étudiée par Δ et tableau de signes, puis les conditions sont croisées sur une droite réelle.
- **CAS** : `solve(x^2-1>=0,x)`, `domain(sqrt((x-2)/(x+2)),x)` en contrôle, `factor`.
- **Implémentation** : dans `auto`, si `sqrt` est présent sans `=`/`<`, extraire chaque radicande et chaque dénominateur et appeler `inequation` (>=0 ou >0), puis faire l'intersection.
- Couvre : S7 ex.1 c-g ; S7 ex.3 (avec la composition) ; utile pour C a) si la fonction contient une racine.

### 5. Système de deux conditions vectorielles (S5 ex.2, S6 ex.5)
- **Rédaction du prof** : écrire chaque produit scalaire nul (et l'aire ½‖AB×AC‖ = valeur), poser le système et le résoudre (substitution), donner toutes les solutions.
- **CAS** : `solve(dotP(u,v1)=0 and dotP(u,v2)=0,{a,b})` ; `solve(dotP(ac,ab)=0 and abs(det)=25/2,{x,y})`.
- **Implémentation** : généraliser `vParam` à 2 inconnues, sur n'importe quelles lettres (a, b, x, y, z), avec n conditions.
- Couvre : S5 ex.2 ; S6 ex.5 ; S6 ex.6 b (paramètre z).

### 6. Produits vectoriel et mixte « intelligents » et vecteurs donnés par expression (S6 ex.2-3)
- **Rédaction du prof** : (a+b)×c = a×c + b×c, b×a = −a×b, (2a)×(−3b) = −6(a×b), [a;c;a] = 0 (vecteur répété), [a;c;b] = −[a;b;c] ; réutiliser les résultats déjà calculés.
- **CAS** : `crossP`, `dotP` sur des expressions `[2,0,3]+[0,4,2]` ; stocker a, b, c (`a:=[2,0,3]`).
- **Implémentation** : `vec()` doit évaluer une expression vectorielle (`cas1(...)`) ; ajouter des variables a, b, c mémorisées et une ligne « propriété utilisée ».
- Couvre : S6 ex.2 a-b, ex.3 ; plus de confort pour A b-e (taper `Q-P` au lieu de calculer à la main).

### 7. Angle par bilinéarité, sans composantes (S5 ex.4, ex.7)
- **Rédaction du prof** : (2a−b)·(a+b) = 0 ⇔ 2‖a‖² + a·b − ‖b‖² = 0 ⇒ a·b = 16 − 18 = −2 ; cos θ = a·b/(‖a‖‖b‖) = −1/6.
- **CAS** : `expand((2a-b)*(a+b))` en scalaires (a² → ‖a‖², ab → a·b), puis `solve`, puis `arccos`.
- **Implémentation** : petit module « bilinéarité » : développer le produit avec des lettres, remplacer a·a et b·b par les normes données, isoler a·b.
- Couvre : S5 ex.4 ; S5 ex.7 en partie.

### 8. Étapes de « changement de variable » dans les inéquations bicarrées et les équations irrationnelles (S2 ex.3 c-d, ex.5 e-f)
- **Rédaction du prof** : poser X = x² (ou x³), étudier le signe en X puis revenir à x ; pour √ : condition d'existence, isoler la racine, condition de signe du membre droit, élever au carré, éliminer les solutions parasites par vérification.
- **CAS** : `solve(3+sqrt(3x+1)=x,x)` en contrôle, `expand((x-3)^2)`, `solve(… and x>=3,x)`.
- **Implémentation** : mode « irrationnelle » dans `equation` si `sqrt` est présent.
- Couvre : S2 ex.3 c, d ; S2 ex.5 e, f.

### Hors périmètre du test (à faire après le 16.11)
- **Factorisation à plusieurs lettres** (S1 ex.1 a, b, d, e, k, m) : mise en évidence, identités, groupement. CAS : `factor(expr)`. Utile seulement comme outil (S2 ex.2 h-i).
- **Résolution littérale pour une lettre choisie** (S1 ex.8, ex.10, S3 ex.6) : `solve(eq,v)` avec les conditions d'existence et de signe.
- **Équations logarithmiques** (S3 ex.5 d-e) : domaine, puis `solve`. Simplification de logs et de puissances (S1 ex.3 b, S3 ex.4) : `expand(ln(…))`, `tExpand`.
- **Parité** (S7 ex.4) : `f(-x)` comparé à `f(x)` et `-f(x)`. **Composition** (S7 ex.3) : `f(g(x))` et domaine (s'appuie sur le point 4). **Extremums d'une parabole** (S7 ex.6) : sommet −b/(2a). Le prof les donne comme outils de l'ex.7.
- **Fonction affine bijective** (S7 ex.2 a) ; **vecteurs par cap** (S5 ex.8) ; **système vectoriel** (S4 ex.7) ; **centre de gravité** (S4 ex.5).
