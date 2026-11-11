# Plan — classeur TI-Nspire « compta » (GESTION_ENTREPRISE)

Étude du 10.11.2026 : inventaire et plan, **aucune implémentation**. Machine : TI-Nspire CX II-T CAS (OS 6.3), même chaîne que MATH_1
(`MATH_1/calculatrice/lua/solveur.lua`, `construire_tns.py`, `ETUDE-SOLVEUR.md`).

> **Ce classeur ne va pas au test.** Au test de Gestion d'entreprise, le matériel autorisé est « matériel d'écriture et calculatrice » :
> calculatrice simple, pas de CAS, pas de feuille de résumé (`GESTION_ENTREPRISE/CLAUDE.md`, « Fiche » ;
> `examens/2025-11-intermediaire/txt/enonce.md`, en-tête ; `examens/2026-11-intermediaire/BAREME.md`, S5).
> Le classeur sert à **réviser** (tableaux vides, schémas, formules, étapes du prof), à **vérifier ses exercices**, puis à
> **travailler après les études** (mode « usage pro »). Tout ce qu'il affiche doit donc être su par cœur le jeudi 12.11.2026.

Conventions de ce document :

- **[COURS]** = couvert par le cours, source citée ; **[HORS 12.11]** = dans le manuel mais hors du test du 12.11 (décisions D1, D2
  de `examens/2026-11-intermediaire/PERIMETRE.md`) ; **[EXT]** = extension utile, **hors programme**, absente des sources du cours.
- **[37 p.N]**, **[44 p.N]**, **[51 p.N]**, **[57 p.N]**, **[59 p.N]** = `exercices/chap-NN/enonce.md`, page PDF N.
  **[c37 p.N]** etc. = `exercices/chap-NN/corrige-prof.pdf`, page N (texte : `exercices/chap-NN/txt/corrige-NN-MM.md`).
- **[T25]** / **[C25]** = `examens/2025-11-intermediaire/txt/enonce.md` / `corrige-prof.md`. **[R]** = `sources/txt/Liste des ratios 2018 Profil M.md`.
- **[V]** vérifié dans le dépôt ; **[S]** supposé, à tester sur la machine avant de s'y fier.

---

## 1. Synthèse

1. **43 types d'exercices** recensés : 13 au chap. 37, 10 au chap. 44, 9 au chap. 51 (périmètre du 12.11 : 32 types), puis 6 au
   chap. 57 et 5 au chap. 59 (test du 14.01.2027 et suite). Les 10 exercices du test 2025 correspondent à 10 de ces types.
2. Le classeur a **deux faces** : un **aide-mémoire** (tableaux vides, schémas, formulaire des 26 ratios avec valeurs indicatives,
   définitions, pièges) et un **solveur** par type d'exercice, chacun en deux modes : **Révision** (rédaction du prof, étape par étape,
   avec tableau vide puis rempli) et **Pro** (saisie éclair, tableau de bord, enregistrement, export).
3. Le socle Lua de MATH_1 se réutilise à environ 60 % (menus, saisie, visionneuse, historique, sauvegarde, fabrication du `.tns`).
   Ce qui change : **plus de CAS** (arithmétique pure, donc testable et portable), et **trois composants nouveaux** : formulaire de
   saisie de montants, tableau comptable dessiné (en T, à totaux, à colonnes figées), graphique du seuil.
4. Taille estimée : **≈ 3 200 lignes** pour la version utile avant le test (chap. 37-44-51), **≈ 7 000 lignes** pour le classeur
   complet (57, 59, finance, mode pro).
5. Ordre : socle + aide-mémoire, puis les 4 solveurs qui pèsent le plus au barème 2025 (ratios commentés, tableau des RL, CR à
   2 degrés, seuil), puis le reste du périmètre, puis 57 / 59 pour janvier, puis les extensions pro.
6. **Avertissement de calendrier** : le test est dans deux jours et le classeur n'y entre pas. Avant jeudi, seuls les lots 0 à 2
   (§8) ont un intérêt ; le temps de révision sur papier (blanc 1, `exercices-test.html`) reste prioritaire.

---

## 2. Inventaire des types d'exercices

Colonnes : **Entrées** (ce que donne l'énoncé) · **Rédaction attendue** (étapes du prof, dans l'ordre) · **Tableau / schéma** ·
**Pièges** · **Variantes**. La colonne « Test » donne l'exercice 2025 et ses points (`BAREME.md` §1), ou la probabilité estimée de
`PERIMETRE.md` §3.

### 2.1 Chapitre 37 — principes d'évaluation, réserves latentes (13 types)

| # | Type | Test | Entrées | Rédaction attendue (source) | Tableau / schéma | Pièges | Variantes |
|---|---|---|---|---|---|---|---|
| A1 | Résultat réel depuis la RL d'un seul poste | ex. 1, 3 pts | valeur réelle et valeur publiée du poste au 31.12, RL au 01.01, résultat publié | 1. RL 31.12 = réelle − comptable ; 2. variation = RL finale − RL initiale ; 3. résultat réel = résultat publié + variation [C25, ex. 1 : 160 → 120, −40 − 40 = −80] ; [37 p.18] ; modèle 37.28 [c37 p.35] | 3 lignes « RL au 01.01 / RL au 31.12 / variation », puis 3 lignes « résultat comptable / variation / résultat réel » | c'est la **variation** qui compte, pas la RL ; résultat publié négatif (perte) ; sens du signe | bénéfice ou perte publiés ; RL donnée ou à calculer aux deux dates |
| A2 | Tableau des RL à plusieurs postes → bénéfice réel, fonds propres réels | ex. 7, 8 pts | par poste : valeurs comptable / réelle (ou RL) au bilan initial et final ; bénéfice et fonds propres publiés | tableau ligne par ligne (2 pts pour ducroire et stock, 1 pt pour titres et installations), ligne Totaux ; « Bénéfice réel = bénéfice publié + variation des RL » ; « Fonds propres réels = fonds propres publiés + RL au 31.12 » [C25, ex. 7 : 140 → 143, 503, 1'643] ; modèle 37.11 [c37 p.11-12] ; [37 p.18] | tableau du prof : comptes × (initial : comptable, réelle, RL ; final : comptable, réelle, RL ; variation), Totaux | **ducroire en négatif** (passif surévalué : RL = comptable − réelle en valeur absolue) ; stock « aux 2/3 » : réelle = comptable × 3/2 ; RL « augmentée de 10 » ; FP réels avec la RL **finale**, pas la variation | 37.7-37.9 (tableau donné, il reste BR et FP), 37.12, 37.13 |
| A3 | Ducroire seul → RL → résultat réel | 50 % | créances aux deux dates, taux de provision (5 %), risque réel, résultat publié | provision comptable = taux × créances **commerciales** ; RL = comptable − risque réel aux deux dates ; variation ; résultat réel + phrase [37.21, c37 p.24-25 : 7'000 / 8'000, RL 2'000 → 5'000, +3'000, bénéfice réel 1'000] | 3 colonnes : valeur comptable, risque réel, RL ; lignes 01.01, 31.12, variation | exclure les créances AFC du calcul des 5 % ; perte publiée qui devient bénéfice réel | taux 5 % suisses / 10 % étrangers [37 p.41] |
| A4 | Stock évalué à une fraction de sa valeur réelle, sur deux dates | 45 % | stock comptable ou réel aux deux dates, fraction (2/3, « RL = 1/3 de la valeur réelle »), CA, achats, autres charges | a) RL initiale, finale, variation ; b) variation de stock réelle et comptable → PRAMV réel et comptable ; c) bénéfice comptable et réel [37.14, c37 p.15-16 : RL 200'000 → 250'000] | 2 colonnes comptable / réel : stock 01.01, stock 31.12, variation, PRAMV, bénéfice | comptable = 2/3 du réel ⇒ RL = comptable ÷ 2 ; RL = 1/3 du réel ⇒ comptable = réel × 2/3 | 37.13 (dans un tableau complet) |
| A5 | Valeurs externes / internes d'un stock → PRAMV et marge brute internes | 35 % | stocks initial et final externes et internes, PRAMA, CAN | PRAMV externe ; RL aux deux dates et variation ; PRAMV interne ; MB externe ; MB interne et phrase d'explication [37.10, c37 p.10-11] | 2 colonnes externe / interne | diminution de RL ⇒ marge publiée « améliorée » | — |
| A6 | Valeur maximale d'un stock au bilan (CO 960c) | ex. 4, 1 pt | par article : quantité, PRA unitaire, valeur vénale nette | par article : évaluation = min(PRA, valeur vénale nette) ; total = quantité × évaluation ; somme [C25, ex. 4 : 110 + 120 = 230] ; [37 p.37] ; modèle 37.20 [c37 p.23-24] | marchandises × (quantité, PRA, VVN, évaluation, total), ligne Total | **article par article**, jamais sur le total | coût de production pour les produits finis |
| A7 | Titres cotés et non cotés au bilan | ex. 9, 3 pts | par titre : nombre, cours d'achat, cours au 31.12, coté ou non | cotés : cours du 31.12 (CO 960b), même au-dessus du prix d'achat ; non cotés : min(achat, valeur au 31.12) (CO 960a) ; valeur = nombre × prix retenu [C25, ex. 9] ; [37 p.3, p.35] ; modèle 37.19 [c37 p.22-23] | deux tableaux : titres × (nombre, prix unitaire, valeur au bilan) | coté en baisse : le cours s'impose ; non coté en hausse : on reste au prix d'achat | — |
| A8 | Coût d'acquisition d'une immobilisation, amortissement prudent, article du CO | 35 % | prix d'achat, frais de transport et d'installation, remise ; durée de vie | prix d'achat + frais − remise = valeur maximale à la première inscription, CO 960a al. 1 [37.18, c37 p.21 : 770'000] ; taux prudent : 25 % constant ou 50 % dégressif pour 4-5 ans, CO 960 al. 2 et 960a al. 3 [37.17, c37 p.21] ; terrain : jamais au-dessus du coût d'acquisition (37.16, sans corrigé) | colonne de calcul | remise en % du prix d'achat seul ; le manuel [37 p.41] et le corrigé 37.17 divergent sur le dégressif : suivre le corrigé (`entrainement/couverture-test-12-11.md` §3) | — |
| A9 | RL fiscale, reprise fiscale, bénéfice fiscal | 25 % | RL initiale, stock au bilan et au PRA, part admise par le fisc (1/3), bénéfice comptable | bénéfice réel (tableau à une ligne) ; RL admise = 1/3 du PRA ; reprise = RL comptabilisée − RL admise ; bénéfice fiscal = comptable + reprise ; valeur du stock pour que tout soit admis [37.24, c37 p.26-27 : 58'700 − 45'500 = 13'200 ; 71'100] ; [37 p.41] | tableau des RL à une ligne + calcul | 33 1/3 % de la valeur **réelle** | 37.26 (provisions + stock) |
| A10 | Bilans publiés sur plusieurs années → RL et bénéfice réel par année | 30 % | par année : stock au bilan, au PRA, au prix du jour ; immobilisations et FAC ; créances et ducroire | par poste et par année : valeur réelle (stock : min(PRA, prix du jour)), RL ; variation d'une année à l'autre ; bénéfice réel par année [37.25, c37 p.28-31 ; 37.27] | tableau années × postes | la valeur réelle du stock est déjà un minimum légal | 37.26, 37.27 |
| A11 | Tableau des fonds propres sur 3 exercices | 25 % | fonds propres comptables, variations de RL, bénéfices | même tableau que A2 avec une ligne par année ; le bilan final d'une année est le bilan initial de la suivante [37.22, c37 p.25] | tableau des RL, lignes = années | pas d'augmentation de capital, bénéfices virés aux réserves | — |
| A12 | Écritures et comptes internes (variation de stock, dissolution de RL, CR et bilan internes) | 20 % / 15 % | inventaire final, éléments d'évaluation, balance | journal (débit, crédit, libellé, montant) ; CR externe et interne côte à côte ; bilan interne [37.4-37.6, c37 p.5-7 ; 37.15] | journal ; CR externe \| interne | sens de l'écriture « Stock à Charges de marchandises » | 37.15 : CR interne à 3 degrés (très long) |
| A13 | Théorie : vrai / faux, postes sous- ou surévaluables, catégories de RL | 30 % | affirmations | réponse + justification [37.1-37.3] ; RL forcées / d'appréciation / arbitraires [37 p.40] | liste | actifs : valeurs plafonds ; passifs : valeurs planchers [37 p.3] | — |

### 2.2 Chapitre 44 — seuil de rentabilité, marge contributive (10 types)

| # | Type | Test | Entrées | Rédaction attendue (source) | Tableau / schéma | Pièges | Variantes |
|---|---|---|---|---|---|---|---|
| B1 | Compte de résultat à 2 degrés, PRAMA, PRAMV, CAN | ex. 2, 7 pts | ventes brutes, achats bruts, déductions obtenues et accordées, frais d'achats, ACE, inventaires initial et final | formules écrites avant le calcul (`CLAUDE.md` du cours, « Corrigés ») : CAN = ventes − déductions accordées ; PRAMA = achats + frais d'achats − déductions obtenues ; PRAMV = PRAMA ± variation de stock ; MB = CAN − PRAMV ; BN = MB − ACE [44 p.3] ; [C25, ex. 2 : MB 920, BN 520, PRAMA 1'150, PRAMV 1'050, CAN 1'970] ; modèle 44.1 [c44 p.1-2] | CR en T à 2 étages : charges \| produits, totaux égaux, la marge brute équilibre le 1er degré et ouvre le 2e | augmentation de stock **côté produits** (diminue le PRAMV) ; déductions accordées côté charges ; 1er degré = 3 pts sur 4 | présentation en liste (./. PRAMV) : 44.3 ; avec pertes sur créances, frais de vente [44 p.3] |
| B2 | CA au point mort par le taux de marge brute ; CA pour un bénéfice visé | 55 % | CA, PRAMV (ou MB), charges fixes | taux MB = MB × 100 ÷ CAN ; CA au point mort = CF × 100 ÷ taux MB, et seconde formule CA × CF ÷ MB ; CA visé = (CF + BN visé) × 100 ÷ taux MB [44 p.8, p.10] ; [44.3, c44 p.4 : 35 %, 8'274'285.70, 13'988'571.45] | CR en liste + deux fractions | arrondi **aux 5 centimes** dans les corrigés du recueil ; deux formules demandées | 44.4, 44.5 |
| B3 | Point mort en quantité ; quantité pour un bénéfice visé | ex. 6, 2 pts | prix de vente, coût variable, charges fixes (par jour, par an), bénéfice visé | MB unitaire = PV − CV ; quantité = CF ÷ MB unitaire ; quantité visée = (CF + BN) ÷ MB unitaire, **arrondie à l'unité supérieure** [C25, ex. 6 : 80 ; 142,5 → 143] ; [44 p.9] ; modèles 44.2, 44.6 | 2 lignes de calcul par question | arrondi vers le haut (R9 du barème) ; période des charges fixes (jour / mois / an) | seuil par jour, par semaine |
| B4 | Point mort en quantité **et** en valeur avec données indirectes ; résultat à un volume donné | 50 % | coût variable, prix ou taux de marge (en % du PVN, ou en % des coûts variables), charges fixes, quantité ou résultat | MB unitaire (directe, ou CV × taux ÷ (100 − taux) si le taux est en % du PVN, ou CV × taux si en % du coût) ; quantité au PM ; CAN au PM = quantité × PV ; BN = quantité × MB unitaire − CF ; quantité vendue = (CF − perte) ÷ MB unitaire [44.7, c44 p.8 ; 44.8, c44 p.9-10] | lignes de calcul | **base du taux** : 33 1/3 % du PVN ≠ 50 % du PRAMV | 44.8 c) CAN depuis le bénéfice brut |
| B5 | Graphique du seuil : construire les 4 droites, lire les CA | ex. 8, 5 pts ; lecture 35 % | PV, CV, CF ; résultats visés (BN, PN) | droites CAN, marge brute, prix de revient (= FV + FF), frais fixes ; point mort à l'intersection CAN / prix de revient (ou MB / FF) ; CA lus et annotés [C25, ex. 8 : 375'000 / 450'000 / 225'000] ; [44 p.10] ; modèle 44.13 [c44 p.15] ; lecture : 44.14 [c44 p.16-17] | graphique : abscisse quantités, ordonnée CHF, 4 droites, accolades BN / PN | perte visée ⇒ CA sous le seuil ; nommer les droites | 44.15 d) (recettes annexes) |
| B6 | Licence d'importation : quantité pour un bénéfice, prix minimum, baisse de prix | ex. 10, 7 pts | coût de revient unitaire, commande minimale, PV, CF, BN visé, taux de baisse | a) à couvrir = CF + BN ; marge sur coût variable unitaire ; quantité ; b) marge nécessaire = CF ÷ commande minimale ; prix = coût + marge ; c) nouveau PV, nouvelle marge, seuils ancien et nouveau, augmentation en % (1 pt par étape) [44.16, c44 p.18-19 : 5'750 ; 116.00 ; 4'500 → 6'429, +42.9 %] | colonne d'étapes | **ex. 10 de 2025** : la référence reste le corrigé du prof (850, 6'750, +11,1 %), incohérent avec l'énoncé ; méthode du livre en regard : 200, 6'750, +114 % (`CLAUDE.md` du cours, décision du 03.11.2026) | — |
| B7 | CR ou budget : PRAMV, taux de marge, seuil, résultat au budget, date du point mort | 35 % | CAN, achats, variation de stock, charges fixes détaillées, taux de marge | PRAMV ; MB et taux ; CA au PM ; BN à un autre CA = taux × CA − CF ; CR prévisionnel à 2 degrés ; date du PM = CA au PM × 360 ÷ CA annuel [44.9, c44 p.10-11 ; 44.11, c44 p.13 ; 44.10] ; [44 p.9] | CR en T à 2 degrés | année de 360 jours, ventes régulières | effet d'un changement de prix ou de charges (44.10) |
| B8 | Lot acheté puis changement de prix en cours de vente | 25 % | quantité achetée, PA, PV, charges générales, quantité déjà vendue, nouveau PV | seuil initial ; BN si tout est vendu ; frais fixes déjà couverts = déjà vendus × ancienne marge ; reste ÷ nouvelle marge ; nouveau seuil = déjà vendus + supplément ; commentaire [44.12, c44 p.14-15] | lignes de calcul | le seuil se calcule sur le solde des frais fixes | invendus |
| B9 | Taux de remplissage (seuil en places), recettes annexes | 25 % | capacité, CF par vol, CV par passager, prix, recettes de fret | CF nets = CF − recettes annexes ; MB unitaire ; passagers au PM ; conclusion (96 = perte, 97 = bénéfice) ; taux d'occupation = PM × 100 ÷ capacité [44.15, c44 p.17-18 : 96.15 ; 80.125 %] | lignes de calcul + graphique | recettes annexes déduites des frais fixes | — |
| B10 | Marge contributive (théorie) | 15 % | — | marge sur coût variable (charges proportionnelles) vs marge contributive (charges directes) [44 p.4] | — | le manuel emploie aussi « marge contributive » pour la marge brute | — |

### 2.3 Chapitre 51 — analyse de bilan et du résultat (9 types)

| # | Type | Test | Entrées | Rédaction attendue (source) | Tableau / schéma | Pièges | Variantes |
|---|---|---|---|---|---|---|---|
| C1 | Liquidités 1-2-3 et couverture 1-2 sur un bilan à deux années, **commentaires** | ex. 3, 6,5 pts | bilan structuré (AC, AI, CE c.t., CE l.t., FP), colonnes N−1 et N | pour chaque ratio : formule [R], fraction numérique, résultat ; puis commentaire = valeur, norme, conséquence [C25, ex. 3 : 14.44 %, 118.89 %, 216.67 %, 1.28, 1.75] ; normes [51 p.11-13] ; 0,5 pt par ratio, **2 pts par commentaire** (`BAREME.md` §3) | tableau ratio \| calcul \| résultat | prendre la **bonne année** ; garder le classement du bilan donné (dividendes en CE l.t. en 2025) ; % ou décimal comme le prof | 51.10, 51.11 b, 51.14 |
| C2 | Six ratios sur trois bilans simplifiés, appréciation de la liquidité et du financement | ex. 5, 9 pts | 3 bilans à 7 postes | tableau 6 ratios × 3 entreprises en décimal ; une à deux phrases par entreprise et par question : norme, hypothèse, conséquence [C25, ex. 5] ; modèle 51.8 [c51 p.1-2 : « nettement en excédent de liquidités », « dans la norme », « surendettée et très vulnérable »] | tableau des 18 valeurs | 3 pts de calculs pour **6 pts de commentaires** ; couverture 2 élevée seulement parce que les immobilisations sont faibles | 51.14 (2 coopératives) |
| C3 | Bilan analytique depuis une liste alphabétique de postes, puis tous les ratios du bilan | 45 % | liste de postes et montants ; informations (répartition du bénéfice, nature des provisions et des titres) | classer chaque poste : liquidités, créances, stocks, AI ; CE c.t., CE l.t. ; capital social, capital de croissance ; règles : ducroire et FAC en déduction, actifs de régularisation → créances, passifs de régularisation → CE c.t., actionnaires en déduction du capital, pertes reportées en déduction, dividende décidé → CE c.t. [51 p.4] ; [51.10, c51 p.3-5 : 160'000 ./. 60'000 ; IAC 23.59 % ; autofinancement 16.67 %] ; [51.11, c51 p.5-7] | bilan analytique en T avec sous-totaux AC, AI, CE c.t., CE l.t., CP | répartition du bénéfice **avant** de classer ; titres de placement = liquidités, participations = AI ; provision à long terme = CE l.t. | — |
| C4 | Compte de résultat à plusieurs degrés depuis une balance | 40 % (avec C5) | balance alphabétique : ventes, retours, déductions, pertes sur créances, frais de vente, achats, frais d'achats, stocks, salaires, ACE, amortissements, charges et produits financiers | CAB = ventes − retours des clients ; CAN = CAB − déductions accordées − pertes sur créances − frais directs de vente ; PRAMA = achats − retours − déductions obtenues + frais d'achats ; PRAMV ; MB ; EBITDA ; EBIT ; bénéfice net [51 p.31-33] ; [51.19, c51 p.23-24 : 2'629, 2'261, 1'445, 1'415] | CR en liste à degrés | EBIT = avant charges et produits financiers (et impôts) | 51.20 |
| C5 | Chiffres clés du compte de résultat | 40 % | CA, MB, EBIT, BN sur plusieurs années ; effectif ; surface | évolution du CA = (CA − CA précédent) × 100 ÷ CA précédent ; taux de marge brute, économique, nette ; CA par employé ; CA au m² [51 p.35] ; [51.21, c51 p.25 ; 51.23, c51 p.26-27] | tableau années × ratios | base = année précédente ; arrondi au % | 51.22 |
| C6 | Rotations et durées (créances, fournisseurs, stocks) | 35 % | bilans N−1 et N, CA (à crédit), PRAMA, PRAMV | moyenne = (N−1 + N) ÷ 2 ; rotation = flux ÷ moyenne ; durée = 360 ÷ rotation ; commentaire par rapport aux délais [R] ; [51 p.27-30] ; [51.24, c51 p.27-29] | tableau ratio \| calcul \| résultat par entreprise | CA total si le CA à crédit est inconnu ; PRAMA (fournisseurs) ≠ PRAMV (stocks) | **cycle des liquidités** complet 51.16-51.18 [c51 p.18-20] : **[HORS 12.11]** (D2) |
| C7 | Rentabilités ROI et ROE | 25 % | bilans N−1 et N, compte de résultat | EBIT = BN + charges financières − produits financiers (+ impôts) ; ROI = EBIT × 100 ÷ total moyen du bilan ; ROE = BN × 100 ÷ fonds propres moyens [R] ; [51 p.41-42] ; [51.25, c51 p.29-30] | 2 fractions | moyennes sur 2 bilans | décomposition du ROI (marge × rotation de l'actif), effet de levier 51.26-51.33 : **[HORS 12.11]** (D1), mais le chap. 51 revient au test du 14.01.2027 |
| C8 | Fonds de roulement net | 25 % | bilan structuré | FRN = AC − CE c.t. = (CP + CE l.t.) − AI ; positif = favorable [51 p.12] | schéma du bilan en blocs | absent de [R] | — |
| C9 | Vrai / faux sur les ratios | 25 % | affirmations | réponse + brève justification si faux [51.15] | liste | — | — |

### 2.4 Chapitre 57 — flux de trésorerie (6 types) — test du 14.01.2027

Inventaire fait sur les titres des énoncés, le test de février 2026 et son corrigé Excel ; à affiner avant le lot 5 (§8).

| # | Type | Référence | Entrées | Rédaction attendue (source) | Tableau | Pièges |
|---|---|---|---|---|---|---|
| D1 | Tableau des liquidités (variation du fonds) | 2026-02, ex. 2 a), 3 pts ; 57.2, 57.3 [c57 p.2] | 2 bilans, définition du fonds | fonds × (N−1, N, variation), ligne Total (`examens/2026-02-fin/corrige-prof-xlsx/txt/002_57_06.md`, feuille « corrigé » : 185 → 180, −5) | fonds \| N−1 \| N \| variation | composition du fonds (avec ou sans banque c/c, titres) |
| D2 | Cash flow, méthodes directe et indirecte | 2026-02, ex. 2 b), 2 pts ; 57.4-57.7 | compte de résultat | indirecte : bénéfice net + charges sans effet monétaire − produits sans effet monétaire ; directe : produits − charges à effet monétaire [57 p.9] ; (200 + 90 = 290, même corrigé Excel) | 2 colonnes directe \| indirecte | amortissements et provisions sans effet monétaire |
| D3 | Tableau des flux de trésorerie complet (exploitation, investissement, financement) | 2026-02, ex. 2 c), 11 pts ; 57.11-57.17 [57.12 : c57 p.20-22] | 2 bilans, CR, informations | exploitation (directe) → cash flow ; investissement ; financement ; variation du fonds = contrôle avec D1 (290 − 140 − 155 = −5), 1 pt par ligne | TFT en liste à 3 secteurs | investissement = variation de la valeur nette + amortissements ; dividende de l'année précédente payé ; ventes et achats à crédit (57.13 et suivants) |
| D4 | Effets d'opérations sur le résultat et les liquidités ; sur les ratios | 57.1, 57.9, 57.10, 57.27 | liste d'opérations | + / − / 0 par opération | grille | — |
| D5 | Ratios de cash flow, free cash flow, commentaires | 57.22-57.26 [57.22 : c57 p.45-46] | TFT, bilans | marge de cash flow, ratio d'investissement, facteur d'endettement (endettement effectif = CE − liquidités − créances), free cash flow = cash flow − investissements nets [R] | ratio \| calcul \| résultat | investissements nets à reconstituer |
| D6 | Lecture de TFT publiés (Swiss, Nestlé, Swatch, Leclanché) | 57.18-57.21 | rapport annuel | questions de lecture | — | aide-mémoire seulement |

### 2.5 Chapitre 59 — comptabilité analytique (5 types) — hors des deux tests 2026-2027 selon le planning (« 59 ? » à demander au prof)

| # | Type | Référence | Entrées | Rédaction attendue (source) | Tableau |
|---|---|---|---|---|---|
| E1 | Charges incorporables : charges supplétives, non incorporables | 59.1-59.4 | charges de la comptabilité générale, corrections | charges de la CAE = charges de la comptabilité générale + supplétives − non incorporables (section 3 du chap. 59) | tableau de passage |
| E2 | Coûts totaux et unitaires par produit ou département, coût de l'unité d'œuvre | 59.5-59.7 | charges directes et indirectes, clés | répartition, coût unitaire | tableau produits × charges |
| E3 | Tableau de répartition des charges indirectes (primaire, secondaire, unités d'œuvre) | 2026-02, ex. 3 a), 6 pts ; 59.9, 59.10 [c59 p.9-11] | charges par section, clés en %, unités d'œuvre | totaux primaires ; répartition des sections auxiliaires ; totaux secondaires ; coût de l'unité d'œuvre (section 5 du chap. 59) | tableau charges × sections |
| E4 | Compte de stock au coût moyen pondéré | 2026-02, ex. 1, 4 pts ; 59.13, 59.14 [c59 p.19] | entrées datées (quantité, coût), bons de sortie | CMP après chaque entrée ; sorties au CMP ; stock final [59 p.33] ; arrondi à 4 décimales (énoncé de février 2026) | compte en T : entrées \| sorties (date, libellé, quantité, coût unitaire, coût total) |
| E5 | Coûts complets en cascade : approvisionnement, production, revient, résultat analytique | 2026-02, ex. 3 (30 pts avec E3) ; 59.11, 59.12, 59.15-59.20 [59.15 : c59 p.21-24] | stocks, achats, heures, charges indirectes réparties, ventes | coût d'approvisionnement → stock de matières (CMP) → coût de production → stock de produits (CMP) → coût de revient → résultat | tableaux en cascade |

### 2.6 Extensions hors programme **[EXT]** (aucune source dans le cours)

Recherche faite dans `exercices/chap-*/enonce.md` : ni « marge de sécurité », ni « levier opérationnel » dans le chap. 44 ; le cours
ne contient aucun chapitre de calcul financier (chapitres : 37, 44, 51, 57, 59).

| # | Outil | Contenu |
|---|---|---|
| X1 | Marge de sécurité, levier opérationnel | marge de sécurité = CA − CA au point mort (en CHF, en %) ; levier opérationnel = marge sur coût variable ÷ résultat |
| X2 | Besoin en fonds de roulement, cycle de trésorerie | durée de stockage + durée clients − durée fournisseurs ; proche du « cycle des liquidités » du manuel (section 3.4, **[HORS 12.11]**) |
| X3 | Décomposition du ROI, effet de levier financier | ROI = taux de marge économique × rotation de l'actif ; effet de levier [R] : **[HORS 12.11]** plutôt que [EXT] |
| X4 | Intérêts simples et composés, escompte, taux équivalents | capital, taux, durée ; coût annuel d'un escompte non utilisé |
| X5 | Emprunts : annuité constante, plan de remboursement | tableau période × (intérêt, amortissement, solde) |
| X6 | Choix d'investissement : VAN, TRI, délai de récupération | flux saisis en liste ; TRI par dichotomie |
| X7 | Plans d'amortissement linéaire et dégressif | lié à A8 [COURS] pour les taux prudents |
| X8 | Budget de trésorerie, plan de financement | tableau mois × (encaissements, décaissements, solde) |
| X9 | TVA, marges et coefficients de vente | taux paramétrables dans les réglages (ne pas figer les taux légaux dans le code) |

---

## 3. Classeur proposé : vue d'ensemble

- **Nom** : `compta.tns`, source `GESTION_ENTREPRISE/calculatrice/lua/compta.lua`, une page Lua (comme `solveur.tns`).
- **Deux modes**, basculés par la touche `tab` dans un résultat et réglables par défaut :
  - **Révision** : formule du prof, application numérique, résultat, commentaire modèle, tableau **vide** puis **rempli** ; option
    « pas à pas masqué » (chaque `enter` dévoile l'étape suivante, pour se tester avant de regarder).
  - **Pro** : saisie éclair, tableau de bord sans les étapes, enregistrement du dossier, export.
- **Chaque solveur garde la source** en pied d'étape (ex. « 44 p.8 », « modèle 44.3 ») et un bouton « exemple du prof » qui préremplit
  les données d'un exercice corrigé (test 2025, 37.11, 44.13, 51.8…) : utile pour réviser et pour l'autotest (§7).
- **Marquage** : les entrées de menu hors programme portent le suffixe « (hors cours) » ; celles hors du 12.11 « (janvier) ».

### 3.1 Arborescence des menus

Menu principal (9 entrées, accessibles par les chiffres comme dans `solveur.lua`) :

```
compta
1 Aide-mémoire
    1 Tableaux vides        bilan analytique · CR à 2 degrés · CR à degrés (EBITDA, EBIT) · tableau des RL ·
                            évaluation du stock · titres · tableau des ratios · seuil (colonne d'étapes) ·
                            tableau des liquidités · TFT à 3 secteurs · compte de stock · répartition des charges
    2 Schémas               bilan en blocs (AC/AI | CE ct/CE lt/CP, FRN, règle d'or) · cascade ventes → CAN → MB → EBIT → BN ·
                            cascade achats → PRAMA → PRAMV · graphique du seuil (4 droites nommées) · RL interne / externe
    3 Formulaire des ratios les 26 ratios de [R] par famille : formule, valeur indicative, lecture, source
    4 Formules par chapitre 37 · 44 · 51 · 57 · 59
    5 Définitions           glossaire abrégé (recherche par première lettre)
    6 Articles du CO        960, 960a, 960b, 960c, 960d, 960e : une ligne chacun
    7 Pièges et barème      pièges par type ; règles R1-R10 du barème ; « 2 pts par commentaire »
    8 Phrases de commentaire  modèles du prof (test 2025, 51.8, 51.10, 57.22)
2 Réserves latentes, évaluation (37)
    1 Tableau des RL → bénéfice réel, fonds propres réels      A2, A11
    2 Résultat réel depuis un seul poste                        A1
    3 Ducroire                                                  A3
    4 Stock à une fraction, PRAMV réel et comptable             A4, A5
    5 Valeur maximale du stock (CO 960c)                        A6
    6 Titres cotés / non cotés                                  A7
    7 Coût d'acquisition, amortissement prudent                 A8
    8 Reprise fiscale                                           A9
    9 Plusieurs années                                          A10
3 Compte de résultat, seuil (44)
    1 CR à 2 degrés, PRAMA, PRAMV, CAN                          B1
    2 Seuil en quantité, bénéfice visé                          B3, B4, B9
    3 Seuil en valeur par le taux de marge                      B2, B7
    4 Graphique du seuil                                        B5
    5 Prix minimum, baisse de prix (licence)                    B6
    6 Changement de prix en cours de vente (lot)                B8
    7 Date du point mort, résultat à un autre CA                B7
    8 Marge de sécurité, levier opérationnel (hors cours)       X1
4 Analyse de bilan et du résultat (51)
    1 Analyse complète d'un bilan (1 à 3 colonnes)              C1, C2, C8
    2 Bilan analytique depuis une liste de postes               C3
    3 CR à degrés depuis une balance                            C4
    4 Chiffres clés du CR (marges, évolution, par employé, m²)  C5
    5 Rotations et durées                                       C6
    6 ROI, ROE                                                  C7
    7 Cycle des liquidités, BFR (janvier / hors cours)          X2
    8 Décomposition du ROI, effet de levier (janvier)           X3
5 Trésorerie (57) (janvier)
    1 Tableau des liquidités · 2 Cash flow direct / indirect · 3 Tableau des flux complet · 4 Ratios de cash flow, free cash flow
6 Coûts (59)
    1 Compte de stock au CMP · 2 Répartition des charges indirectes · 3 Coûts en cascade · 4 Charges incorporables
7 Finance (hors cours)
    1 Intérêts, escompte · 2 Emprunt, plan de remboursement · 3 VAN, TRI, délai · 4 Amortissements · 5 Budget de trésorerie · 6 TVA, coefficients
8 Dossiers
    1 Reprendre le dernier · 2 Dossiers enregistrés · 3 Historique des résultats · 4 Exemples du prof · 5 Exporter
9 Réglages, aide
    mode par défaut (Révision / Pro) · résultats en % ou en décimal · arrondi (unité, centime, 5 centimes) ·
    pas à pas masqué · aide à la saisie · autotest · à propos (rappel : interdit au test)
```

### 3.2 Aide-mémoire (face a)

- **Tableaux vides** : le même composant que les tableaux remplis, sans valeurs ; `enter` remplit avec l'exemple du prof, `enter`
  revide. Contenu repris de `par-coeur.json` (cartes `cr-squelette`, `tableau-rl`, `bilan-analytique-regles`…), des tableaux à
  compléter de [T25] (ex. 4, 7, 9) et de `examens/2026-11-intermediaire/_src/exercices_test.py` (constante d'en-tête du tableau des RL).
- **Formulaire des ratios** : une fiche par ratio = formule en fraction, valeur indicative, lecture, source. Valeurs indicatives
  (`glossaire.md` §1, vérifiées la nuit du 09.11) : liquidité 1 : 20 à 30 % · liquidité 2 : ≥ 100 % · liquidité 3 : > 150 % ·
  couverture 1 : 60 à 80 % · couverture 2 : > 100 % (règle d'or) [51 p.11-13] ; endettement : pas de norme chiffrée dans le
  manuel, repères tirés des corrigés (40 % et 43,78 % « faible », 56-58 % « dans la norme », 82 % « surendettée » ; 51.8 et
  51.10, `BAREME.md` §3). Les repères tirés des corrigés sont affichés comme tels, pas comme des normes.
- **Organisation pour la révision** : entrée « Révision du 12.11 » en tête de l'aide-mémoire, qui enchaîne les 10 types du test 2025
  dans l'ordre (tableau vide → formules → pièges), avec les points du barème.

### 3.3 Solveurs (face b) : écrans

Chaque solveur suit le même enchaînement de 3 écrans :

1. **Saisie** (formulaire, §4) : champs nommés comme dans l'énoncé du prof, valeurs par défaut = exemple du prof.
2. **Résultat**, visionneuse à défilement (celle de MATH_1) composée de blocs : titre · formule (fraction littérale) ·
   application numérique · résultat en vert · tableau · commentaire · alerte de piège · source en gris.
3. **Synthèse** (`tab`) : le tableau de bord sans les étapes (mode Pro), ou le seul tableau à recopier (mode Révision).

Exemple, solveur 4.1 « Analyse complète d'un bilan » sur les données de [T25] ex. 3 :

```
┌ Analyse du bilan — 2026 ───────────────────────────┐
│ Liquidité 1 = Liquidités × 100 / CE à court terme   │   formule [R]
│            = 65 × 100 / 450 = 14.44 %               │   application numérique
│ Norme : 20 à 30 %  →  insuffisante                  │   comparaison
│ … Liquidité 2 = 535 × 100 / 450 = 118.89 %  ≥ 100 % │
│ Commentaire (2 pts) : la liquidité 1 (14 %) est     │   modèle : valeur, norme, conséquence
│ sous la norme de 20-30 %, mais avec les créances    │
│ la liquidité 2 (119 %) dépasse 100 % : l'entreprise │
│ peut payer ses dettes à court terme.                │
│ 51 p.11-12 · modèle : test 2025 ex. 3               │
└ ▲▼ défiler  tab : synthèse  enter : étape  esc ─────┘
```

**Moteur de commentaires** (types C1, C2, C6, C7, D5) : pour chaque ratio, une table de seuils et trois gabarits de phrase
(sous la norme / dans la norme / au-dessus), assemblés en « constat chiffré + norme + conséquence », puis une conclusion par
famille (liquidité, financement, couverture). Les gabarits reprennent les tournures du prof ([C25] ex. 3 ; 51.8, c51 p.2).
Le texte produit est un **modèle** : le barème des commentaires est une hypothèse (`BAREME.md` §3), et le prof note une réponse
rédigée, pas une phrase type.

---

## 4. Saisie des montants sur la calculatrice

Problème central : un bilan à deux colonnes représente 15 à 30 montants, un tableau des RL 16, trois bilans 21. La saisie champ par
champ de `solveur.lua` (`demander` en cascade) ne suffit pas. Trois modes de saisie, du plus guidé au plus rapide :

| Mode | Principe | Quand | Coût |
|---|---|---|---|
| **Formulaire** (nouveau composant) | liste de champs « libellé : valeur », 1 à 3 colonnes ; ▲▼ change de ligne, ◄► de colonne, les chiffres écrivent directement dans la case, `enter` valide et descend, `tab` saute au bloc suivant, `esc` annule ; totaux et contrôles recalculés en direct en bas d'écran (« Actif 1'675 = Passif 1'675 ✓ ») | Révision ; tout tableau de montants | ≈ 350 lignes |
| **Saisie éclair** (socle existant) | une seule ligne, valeurs séparées par des espaces, dans l'ordre affiché au-dessus : `18 3 29 50 22 18 60` pour un bilan simplifié ; `;` change de colonne | Pro ; bilans simplifiés, seuil | ≈ 40 lignes (réutilise `demander`) |
| **Tableur** (option) | une page Tableur dans le classeur ; le script lit les colonnes par `var.recall` | très gros tableaux (balance complète, flux sur 10 ans) | à tester [S] ; la page doit être ajoutée à la main dans le logiciel TI, `construire_tns.py` ne fabrique qu'une page Lua [V] |

Règles communes aux champs :

- **Calcul dans la case** : `35+30`, `400*5/100`, `210*2/3`, `2/3` sont évalués (petit évaluateur maison + − × ÷ parenthèses, 40 lignes,
  plutôt que `math.eval`, pour rester testable hors calculatrice). C'est ce qui rend la saisie d'un énoncé fluide (« ducroire ajusté à
  5 % des créances de 400 »).
- **Formats** : apostrophes et espaces ignorés (`1'500`), point ou virgule décimale, signe moins de la touche (−) accepté, suffixe `%`,
  suffixe `k` (milliers) en mode Pro. Case vide = 0 ; `?` = inconnue (le solveur calcule la valeur manquante quand la relation le
  permet : stock initial depuis la RL, valeur réelle depuis la fraction).
- **Lignes libres** : pour le bilan analytique (C3) et les tableaux de RL, on ajoute une ligne en choisissant le poste dans une liste
  (plan comptable PME, `sources/txt/plan_comptable.md`) ; le classement proposé (liquidités, créances, CE c.t.…) se corrige par ◄►.
- **Niveaux de détail** pour un bilan : « simplifié » (7 agrégats : liquidités, créances, stocks, AI, CE c.t., CE l.t., CP), « structuré »
  (postes saisis sous chaque rubrique) ou « liste de postes » (C3). L'analyse 4.1 accepte les trois.
- **Mémoire** : chaque formulaire rouvre avec les dernières valeurs ; les dossiers nommés sont rangés par `on.save` dans le classeur
  (comme `HIST` dans `solveur.lua`, fonctions `on.save` / `on.restore`).
- **Contrôles** : total actif = total passif ; CR en T équilibré ; variation du fonds = somme des trois secteurs (D3) ; avertissement
  plutôt que blocage.

**Export (mode Pro)** : (1) historique des résultats dans le classeur (existant : `ARCH`) ; (2) variables du classeur par `var.store`
(ratios et listes, réutilisables dans une page Calculs ou Tableur) [S] ; (3) presse-papiers par `clipboard.addText` (texte tabulé à
coller dans Notes ou, via le logiciel TI, sur le PC) [S]. Pas d'accès fichier depuis Lua (`ETUDE-SOLVEUR.md` §2.3).

---

## 5. Réutilisation du socle Lua de MATH_1

| Élément de `MATH_1/calculatrice/lua/solveur.lua` | Sort | Remarque |
|---|---|---|
| Menus à flèches et raccourcis chiffres (`MENU`, `dessinerMenu`, `on.arrow*`, `on.charIn`) | **tel quel** | ajouter une **pile de menus** : aujourd'hui `esc` revient toujours au menu principal ; avec 3 niveaux et des formulaires remplis, `esc` doit remonter d'un seul niveau |
| Saisie ligne avec historique (`demander`, `saisie`, `memoriser`, `HIST`) | **tel quel** | sert à la saisie éclair ; retirer l'aperçu 2D |
| Visionneuse à défilement (`DOC`, `T X G A M R`, `montrer`, `dessinerVue`, `couper`, `hauteurElt`) | **tel quel** + 3 types de blocs | nouveaux blocs : `tab` comptable, `frac` (fraction littérale), `seuil` (graphique) |
| Bandeau, pied, couleurs (`bandeau`, `pied`, `BLEU`) | tel quel | autre couleur de bandeau pour distinguer les deux classeurs |
| Historique des résultats (`ARCH`, `historiqueResultats`) | tel quel | devient « Dossiers › Historique » |
| Sauvegarde (`on.save`, `on.restore`) | tel quel, étendu | y ranger aussi les dossiers et les réglages |
| Graduations d'axes (`pas`) | tel quel | pour le graphique du seuil |
| Fabrication du `.tns` (`construire_tns.py`, fonction `construire_lua`) | **tel quel** | `tools/py MATH_1/calculatrice/construire_tns.py <sortie.tns> <script.lua>` ; à déplacer dans `tools/` si les deux cours s'en servent (question Q7) |
| CAS (`cas`, `cas1`, `math.evalStr`) et tout le calcul formel (`racines`, `facteurs`, `analyse`, `vec…`) | **abandonné** | arithmétique en nombres Lua ; le classeur marcherait aussi sur une Nspire non CAS |
| Rendu 2D par analyse d'expression (`tokens`, `arbre`, `mise`, ≈ 280 lignes) | **remplacé** | les formules comptables sont des fractions de **libellés** (« Liquidités + Créances ») que l'analyseur ne sait pas lire ; un bloc `frac(numérateur, dénominateur)` de ≈ 50 lignes suffit |
| Tableau de signes, courbes (`dessinerTab`, `dessinerCourbes`, `dessinerGraphe`) | **non repris** | remplacés par le tableau comptable et le graphique du seuil |

Composants nouveaux :

| Composant | Rôle | Lignes |
|---|---|---|
| `formulaire` | saisie de montants en grille (§4) | ≈ 350 |
| `tableau` | tableau dessiné : largeurs calculées (`getStringWidth`), nombres alignés à droite, lignes de total en gras avec filet, **forme en T** (charges \| produits, actif \| passif) avec filet central, cellules vides (aide-mémoire), cellule mise en évidence | ≈ 250 |
| `nombres` | format du prof : `1'234`, point décimal, `14.44 %`, décimal `0.82`, signe ; arrondis (unité supérieure, centime, 5 centimes) ; évaluateur de cases | ≈ 120 |
| `seuil` | graphique à 4 droites, point mort, accolades BN / PN, lecture d'un CA | ≈ 150 |
| `commentaires` | seuils et gabarits de phrases par ratio | ≈ 250 (surtout des données) |
| `moteur` | fonctions de calcul pures, une par type d'exercice, sans dessin | ≈ 40 par type |

**Contrainte d'écran** : 318 × 212 px. Tableaux de 4 à 5 colonnes : police 9. Tableau des RL (8 colonnes) : police 7, libellés
abrégés (« Stock », « Install. »), première colonne de 70 px + 7 × 35 px ; si un montant dépasse 6 chiffres, **première colonne figée
et défilement horizontal** par ◄►, ou découpage en deux volets (bilan initial / bilan final + variation). Bilan en T : 2 × (libellé
100 px + montant 55 px). Les tailles de police disponibles sont 7, 9, 10, 11, 12, 24 (`ETUDE-SOLVEUR.md` §2.3).

**Organisation du code** : sources par module dans `lua/src/` (`socle`, `nombres`, `tableau`, `formulaire`, `aide`, `c37`, `c44`,
`c51`, `c57`, `c59`, `finance`, `dossiers`), assemblées en un seul `compta.lua` par un petit script de construction. Regrouper les
fonctions dans des tables (`C37.tableauRL`, `UI.menu`) plutôt qu'en `local function` au niveau du fichier : Lua limite à 200 le
nombre de variables locales par fonction, et `solveur.lua` en compte déjà beaucoup au niveau principal.

---

## 6. Taille estimée

| Lot | Contenu | Lignes Lua | Cumul |
|---|---|---|---|
| Socle repris et adapté | menus avec pile, saisie, visionneuse, sauvegarde | 450 | 450 |
| Composants nouveaux | formulaire, tableau, nombres, fraction | 770 | 1 220 |
| Aide-mémoire | tableaux vides, schémas, 26 ratios, formules, définitions, pièges (surtout des données) | 600 | 1 820 |
| Solveurs 37 | A1-A11 | 450 | 2 270 |
| Solveurs 44 + graphique | B1-B9 | 500 | 2 770 |
| Solveurs 51 + commentaires | C1-C8 | 650 | 3 420 |
| Solveurs 57 | D1-D3, D5 | 550 | 3 970 |
| Solveurs 59 | E1-E5 | 700 | 4 670 |
| Finance (hors cours) | X1-X9 | 800 | 5 470 |
| Dossiers, export, réglages, autotest, exemples du prof | | 600 | 6 070 |
| Marge (mise au point, cas limites) | ≈ 15 % | 900 | ≈ 7 000 |

Repère : `solveur.lua` fait 2 642 lignes, 123 Ko, et donne un `.tns` de 35 Ko [V]. Le classeur compta complet ferait ≈ 300 Ko de
source et un `.tns` de l'ordre de 90 Ko ; la version du 12.11 (jusqu'au cumul 3 420) ≈ 150 Ko et ≈ 45 Ko. Aucune limite de taille de
script n'est documentée dans `ETUDE-SOLVEUR.md` : à surveiller au fil des lots [S].

---

## 7. Risques

| Risque | Gravité | Parade |
|---|---|---|
| **Temps avant le test** : deux jours, et le classeur n'y entre pas ; le test MATH_1 suit le 16.11 | forte | ne viser que les lots 0 à 2 avant jeudi ; le reste après le 12.11 ; le blanc 1 sur papier passe avant |
| **Dépendance** : réviser avec un outil qui calcule et commente à la place de l'étudiant, alors que 8 pts sur 15,5 du chap. 51 sont des commentaires rédigés à la main | forte | « pas à pas masqué » par défaut en mode Révision ; tableaux vides d'abord ; le commentaire n'apparaît qu'après un `enter` |
| Erreur de calcul ou de convention dans le solveur, apprise comme juste | forte | **autotest** intégré (menu 9) : chaque solveur rejoue les exemples du prof et compare aux valeurs des corrigés ([C25] ex. 1-9, 37.11, 37.14, 37.21, 37.24, 44.3, 44.16, 51.8, 51.10, 51.21, 57.6) ; moteur de calcul séparé du dessin |
| Pas d'interprète Lua sur le PC [V] : les essais se font dans le logiciel TI, à la main | moyenne | autotest dans le classeur ; en option, installer un Lua 5.1 ou `lupa` dans `tools/.venv` pour tester `moteur` et `nombres` en ligne de commande |
| Ex. 10 de 2025 : corrigé du prof incohérent avec l'énoncé | moyenne | le solveur B6 applique la méthode du livre (44.16) ; l'exemple « test 2025 ex. 10 » affiche les chiffres du prof comme référence et la méthode du livre en regard, sans substitution (`CLAUDE.md` du cours) |
| Conventions variables du prof : % ou décimal, couverture en décimal, dividendes en CE l.t., signe des variations | moyenne | réglage % / décimal ; le classement saisi par l'utilisateur prime toujours ; jamais de reclassement automatique silencieux |
| Tableaux trop larges pour 318 px | moyenne | police 7, abréviations, colonne figée, volets |
| Commentaires automatiques trop affirmatifs (normes « à prendre avec prudence » [51 p.11-12] ; pas de norme d'endettement dans le manuel) | moyenne | distinguer norme du manuel et repère tiré d'un corrigé ; en mode Pro, seuils modifiables dans les réglages |
| `var.store`, `clipboard.addText`, page Tableur liée : non essayés sur l'OS 6.3 | faible | export en dernier lot ; l'historique dans le classeur suffit sinon |
| Limite de 200 variables locales par fonction, taille du script, temps de chargement | faible à moyenne | fonctions rangées dans des tables ; mesurer à chaque lot |
| Extensions hors programme sans source du cours (VAN, TRI, TVA…) : formules et taux à ma charge | moyenne | marquage « (hors cours) » ; taux saisis par l'utilisateur ; cas de test tirés d'exemples calculés à la main |
| Inventaire des chap. 57 et 59 fait sur les titres et le test de février 2026, pas sur chaque corrigé | faible | relire les corrigés 57.11-57.17 et 59.9-59.20 avant le lot 5 |

---

## 8. Ordre de réalisation

Critère avant le 12.11 : points du barème 2025 × utilité pour réviser (tableau vide + vérification d'un exercice fait à la main).

| Lot | Contenu | Types | Enjeu au test | Quand |
|---|---|---|---|---|
| **0. Socle** | reprise du socle, pile de menus, `nombres`, `tableau`, `formulaire`, construction du `.tns`, essai sur la machine (un tableau en T, un formulaire à 2 colonnes) | — | — | mardi 10.11 soir |
| **1. Aide-mémoire** | tableaux vides (CR à 2 degrés, tableau des RL, bilan analytique, tableau des ratios, évaluation du stock, titres), formulaire des ratios avec valeurs indicatives, formules 37 / 44 / 51, pièges, phrases de commentaire, « Révision du 12.11 » | tous | 51,5 pts | mardi 10.11 soir - mercredi 11.11 matin |
| **2. Quatre solveurs majeurs** | 4.1 analyse de bilan avec commentaires (C1, C2, C8 : 15,5 pts) · 2.1 tableau des RL + 2.2 résultat réel (A1, A2 : 11 pts) · 3.1 CR à 2 degrés (B1 : 7 pts) · 3.2 seuil en quantité + 3.5 licence (B3, B6 : 9 pts) | 8 | ≈ 42 pts | mercredi 11.11 |
| *— test du jeudi 12.11.2026 —* | | | | |
| **3. Reste du périmètre 37-44-51** | 3.3 seuil en valeur (B2, 55 %) · 3.4 graphique (B5, 5 pts) · 2.5-2.6 stock et titres (A6, A7, 4 pts) · 2.3-2.4 ducroire, stock à fraction (A3-A5) · 4.2 bilan analytique (C3) · 4.3-4.6 CR à degrés, chiffres clés, rotations, ROI / ROE (C4-C7) · 2.7-2.9, 3.6-3.7 (A8-A11, B7-B9) ; les 4 types de théorie (A12, A13, B10, C9) restent dans l'aide-mémoire | 20 | — | après le test MATH_1 du 16.11 |
| **4. Mode Pro** | saisie éclair, synthèse, dossiers nommés, exemples du prof, autotest complet, réglages | — | — | fin novembre |
| **5. Chapitre 57** | D1-D3, D5 ; aide-mémoire 57 ; 4.7-4.8 (cycle des liquidités, décomposition du ROI, effet de levier, si confirmés au programme de janvier) | 4 + 2 | test du 14.01.2027 (51 + 57) | au fil du cours (19.11 → 26.11), prêt pour la révision du 17.12 |
| **6. Chapitre 59** | E1-E5 | 5 | hors test selon le planning (« 59 ? ») | décembre, après le cours (03.12 → 10.12) |
| **7. Finance, export** | X1-X9, `var.store`, presse-papiers, page Tableur liée | 9 | hors programme | après le 14.01.2027 |

Ce qui peut attendre sans regret pour jeudi : tout à partir du lot 3. Si le temps manque dès mercredi, s'arrêter après le lot 1 :
les tableaux vides et le formulaire des ratios sont ce que l'étudiant a demandé en premier, et ils ne demandent aucun moteur de calcul.

Vérification de chaque lot : autotest contre les corrigés du prof, puis un exercice de `examens/2026-11-intermediaire/exercices-test.html`
refait à la main et comparé au solveur.

---

## 9. Questions ouvertes (à poser par AskUserQuestion)

| # | Question | Choix |
|---|---|---|
| Q1 | **Jusqu'où aller avant jeudi 12.11 ?** | (a) lots 0-1 seulement : aide-mémoire, tableaux vides *(recommandé : le reste du temps va au blanc 1 sur papier)* · (b) lots 0-2 : aide-mémoire + 4 solveurs majeurs · (c) rien avant le test, tout après le 16.11 |
| Q2 | **Mode Révision : comment dévoiler les étapes ?** | (a) pas à pas masqué, un `enter` par étape *(recommandé)* · (b) tout affiché d'un coup, comme dans le solveur MATH_1 · (c) choix à chaque lancement |
| Q3 | **Commentaires des ratios** | (a) phrase modèle complète, à reformuler *(recommandé)* · (b) seulement les éléments attendus en liste (valeur, norme, conséquence), sans phrase · (c) les deux, la phrase après un `enter` |
| Q4 | **Format des ratios par défaut** | (a) comme le prof : liquidités en %, couvertures en décimal *(recommandé)* · (b) tout en % (formulaire [R]) · (c) tout en décimal (corrigé 2025, ex. 5) |
| Q5 | **Saisie des grands tableaux** | (a) formulaire en grille + saisie éclair *(recommandé)* · (b) ajouter aussi une page Tableur liée au script (à tester, ajout manuel de la page dans le logiciel TI) · (c) saisie éclair seule, plus vite développée |
| Q6 | **Extensions hors programme à retenir** | choix multiples : marge de sécurité et levier opérationnel · BFR et cycle de trésorerie · intérêts et emprunts · VAN / TRI · amortissements · budget de trésorerie · TVA et coefficients |
| Q7 | **Un classeur ou deux ?** | (a) deux classeurs, `solveur.tns` (maths) et `compta.tns`, socle commun déplacé dans `tools/` *(recommandé)* · (b) deux classeurs, socle recopié (plus rapide, double maintenance) · (c) un seul classeur à deux menus |
| Q8 | **Chapitre 59** | (a) attendre la réponse du prof sur « 59 ? » avant le lot 6 *(recommandé)* · (b) le faire de toute façon, pour l'usage professionnel · (c) l'écarter |
| Q9 | **Ex. 10 du test 2025 dans les exemples** | (a) chiffres du prof en référence, méthode du livre en regard, comme dans le reste du dépôt *(recommandé)* · (b) ne pas inclure cet exemple, prendre 44.16 à la place |
| Q10 | **Essais sur PC** | (a) autotest dans le classeur seulement *(recommandé pour jeudi)* · (b) installer en plus un interprète Lua 5.1 (ou `lupa` dans `tools/.venv`) pour des tests automatiques du moteur |

---

## 10. Sources consultées

- `GESTION_ENTREPRISE/CLAUDE.md` ; `examens/2026-11-intermediaire/PERIMETRE.md`, `BAREME.md`, `_src/exercices_test.py` (13 cartes, modèles 37.28 … 51.25).
- `examens/2025-11-intermediaire/txt/enonce.md`, `corrige-prof.md` ; `examens/2026-02-fin/txt/enonce.md`, `corrige-prof.md`, `corrige-prof-xlsx/txt/002_57_06.md`.
- `entrainement/couverture-test-12-11.md`, `controle-nuit-2026-11-09.md` ; `glossaire.md` ; `sources/txt/Liste des ratios 2018 Profil M.md`.
- `exercices/chap-{37,44,51,57,59}/txt/enonce-*.md` (tous les intitulés) ; corrigés lus : 37.5, 37.10, 37.14, 37.17, 37.18, 37.21, 37.22,
  37.24, 37.25, 44.3, 44.7, 44.8, 44.9, 44.11, 44.12, 44.15, 44.16, 51.10, 51.11, 51.16, 51.19, 51.21, 51.23, 51.24, 51.25, 57.22.
  Non relus un par un : les autres corrigés des chap. 57 et 59, et le contenu des 8 pages de `artefacts/` (connu par la matrice de couverture).
- `MATH_1/calculatrice/lua/solveur.lua` (socle, menus, visionneuse, événements), `construire_tns.py`, `ETUDE-SOLVEUR.md`, `COUVERTURE.md`, `README.md`.
