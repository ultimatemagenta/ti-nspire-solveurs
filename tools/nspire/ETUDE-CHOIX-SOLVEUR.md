# Étude : trouver le bon solveur à partir de la consigne

> Étude du 11.11.2026, sans implémentation. Classeurs étudiés : compta (`GESTION_ENTREPRISE/calculatrice/lua/NN_*.lua`, assemblé avec
> `tools/nspire/socle_debut.lua` et `socle_fin.lua`) et maths (`MATH_1/calculatrice/lua/solveur.lua`).
> Tout ce qui est écrit ici vient de la lecture du code et des énoncés. Rien n'a été essayé sur la calculatrice ni dans le logiciel TI.
> Le seul essai exécuté est un prototype Python du moteur de recherche (section 4.7), sur PC.
> Pendant l'étude, `socle_debut.lua`, `socle_fin.lua` et `test_pc.py` ont été modifiés par une autre session (grilles compactes) :
> les numéros de ligne cités pour le socle peuvent avoir bougé de quelques lignes.

## 1. Résumé

**Constat.** Le problème n'est pas le nombre de touches. Sur 56 consignes réelles qui ont un solveur, il faut en moyenne **2,25 touches**
pour l'ouvrir, et 49 sur 56 s'ouvrent en 2 touches ou moins. Le problème est le choix : **41 consignes sur 56 (73 %)** ont au moins deux
solveurs plausibles, ou un solveur dont le libellé ne reprend aucun mot de la consigne. S'y ajoutent 12 consignes sur 56 dont le solveur
n'est pas affiché à l'ouverture du menu (rang 9 ou plus, alors que l'écran montre 8 lignes).

**Recommandation.** Une **recherche par mots-clés incrémentale** dans le socle : dans n'importe quel menu, taper une lettre ouvre l'écran
« Trouver un solveur » ; la liste se met à jour à chaque lettre et affiche, sous chaque solveur, **à quelle condition le choisir**
(« un seul poste », « plusieurs entreprises », « données unitaires »). Elle s'appuie sur un index déclaré à côté des menus.
Deux compléments peu coûteux : renommer une douzaine de libellés avec les mots des consignes, et produire une fiche « consigne → touches »
à partir du même index.

**Résultat du prototype** (index de 98 entrées, écrit pour cette étude) : avec une saisie de 3 à 12 lettres, le bon solveur est en tête
53 fois sur 56 et dans les trois premiers 56 fois sur 56. L'index a été écrit en connaissant l'échantillon : ces taux sont un plafond,
à remesurer sur des consignes que l'index n'a jamais vues (blanc 2, séries à venir).

**Effort estimé.** Environ 1 jour pour le classeur compta (moteur, écran, index, test), 0,5 jour de plus pour le classeur maths
(il n'utilise pas encore le socle, voir 4.5), 0,5 jour pour les renommages et la fiche. Total : environ 2 jours.

**Solveurs manquants révélés par l'échantillon** : aire d'une figure sur quadrillage (test maths 2025, P3 c), minimum et maximum d'un
trinôme sur un intervalle (série 7), répartition du bénéfice et bilan interne (chap. 37), lecture inverse du graphique du seuil (chap. 44).
Détail en section 5.

---

## 2. Inventaire des solveurs et des consignes qui y mènent

Notation des chemins : `3·7` = touche `3` dans le menu principal, puis `7` dans le sous-menu. Les consignes citées sont celles des énoncés
réels (`GESTION_ENTREPRISE/examens/*/txt/enonce.md`, `GESTION_ENTREPRISE/exercices/chap-*/txt/enonce-*.md`,
`MATH_1/exercices/serie-*/enonce.md`, `MATH_1/examens/2025/txt/enonce.md`, `MATH_1/examens/2026/_src/blanc-1-enonce.html`).

### 2.1 Classeur compta : 61 solveurs, 42 écrans d'aide

Menu principal (`99_menu.lua`, trié par `ordre`) : 1 Aide-mémoire, 2 Réserves latentes (37), 3 Compte de résultat, seuil (44),
4 Analyse de bilan (51), 5 Trésorerie (57), 6 Coûts (59), 7 Finance (hors cours), 8 Historique.

**2 · Réserves latentes, évaluation (37)** — `37_reserves.lua`, 14 entrées

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 2·1 | Tableau des RL → BN, FP réels | « Veuillez créer un tableau de réserves latentes », « Déterminer le bénéfice réel », « Déterminer les fonds propres réels », « calculer la valeur interne des fonds propres » |
| 2·2 | Résultat réel (un poste) | « Calculer le résultat net réel en 2026 » (une seule RL, sur le stock), « Calculer la valeur du stock au bilan publié dans cette éventualité » |
| 2·3 | Ducroire | énoncés avec ducroire ajusté à x % des créances et risque réel estimé |
| 2·4 | Stock à une fraction (PRAMV) | « L'entreprise estime son stock aux 2/3 de sa valeur réelle », « Calculer le bénéfice net réel pour 2012 » |
| 2·5 | Stock externe / interne | « À quel montant s'élèvent les réserves latentes constituées ou dissoutes », « Expliquer la différence entre la marge brute externe et la marge brute interne » |
| 2·6 | Valeur max. du stock (960c) | « Compléter le tableau… afin de déterminer la valeur maximale à laquelle l'entreprise peut faire figurer… son stock au bilan » |
| 2·7 | Titres cotés / non cotés | « Déterminer la valeur maximale à laquelle tous ces titres peuvent figurer au bilan » |
| 2·8 | Coût d'acquisition, amort. | « À quel prix maximum pouvez-vous évaluer cet objet lors de la première comptabilisation », « À quel montant maximum Gauss SA peut-il inscrire son terrain », « Quel est le taux d'amortissement… en vertu d'une évaluation prudente » |
| 2·9 | Reprise fiscale (stock) | « Calculer le montant de la reprise fiscale et le bénéfice fiscal en N1 », « Calculer quelle aurait dû être la valeur réelle du stock pour que le fisc admette… » |
| 2·10 | Reprises fiscales (postes) | « Calculer le bénéfice net fiscal minimal admissible pour 2012 » |
| 2·11 | Plusieurs années | « Calculer le bénéfice net réel pour 2012 », « … pour 2013 » (même entreprise) |
| 2·12 | Fonds propres sur 3 ans | « Compléter le tableau, sachant qu'il n'y a pas eu d'augmentation de capital… » |
| 2·13 | Dissolution : écritures, CR | « Journaliser les écritures de dissolution des réserves latentes », « Établir le Compte de résultat… internes » |
| 2·14 | Théorie, V/F, catégories | « Indiquer par le signe V ou F si les affirmations suivantes sont vraies ou fausses » |

**3 · Compte de résultat, seuil (44)** — `44_seuil.lua`, 14 entrées

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 3·1 | CR à 2 degrés, PRAMA, PRAMV, CAN | « Dresser le Compte de résultat à deux degrés en mettant en évidence la marge brute et le résultat net d'exploitation », « Calculer le PRAMA et le PRAMV », « Calculer le CAN » |
| 3·2 | Seuil en quantité, bénéfice visé | « Calculer combien de paquets… pour atteindre le point mort quotidien », « Déterminer le nombre de poulets à vendre pour réaliser un bénéfice quotidien de CHF 250 », « Calculer leur bénéfice net s'ils vendent tous les sapins » |
| 3·3 | Seuil en valeur (taux de marge) | « Calculer le chiffre d'affaires au point mort », « Calculer le chiffre d'affaires qui permettrait de réaliser un bénéfice net de CHF 800'000 », « Déterminer le chiffre d'affaire à réaliser pour rentabiliser les fonds propres de CHF 2'400'000 » |
| 3·4 | Base du taux, CAN depuis la MB | « Déterminer le taux de marge brute en % du chiffre d'affaires net » (taux donné en % du PRAMV) |
| 3·5 | Budget : PM, résultat, prévisions | « Calculer le nouveau point mort », « Calculer le bénéfice net si le chiffre d'affaires reste à CHF 800'000 », « … maintenir le bénéfice net à la même valeur » |
| 3·6 | CR prévisionnel, date du PM | « Présenter le Compte de résultat prévisionnel à deux degrés pour l'année prochaine » |
| 3·7 | Graphique du seuil | « Montrer, graphiquement, le chiffre d'affaires à réaliser », « Représenter graphiquement le point mort » |
| 3·8 | Licence : quantité, prix min., baisse | « Déterminez le nombre de synthétiseurs qu'il faut vendre à 8'000 CHF pour obtenir un bénéfice net de 50'000 », « À quel prix, minimum, peut-on vendre la totalité d'une commande minimum… », « Calculer le pourcentage d'augmentation du volume de ventes… » |
| 3·9 | Test 2025 ex. 10 (prof + livre) | même exercice, données du test |
| 3·10 | Lot : changement de prix | énoncé des sapins (44.12) : prix modifié en cours de vente |
| 3·11 | Taux de remplissage | « Déterminer par un calcul combien de personnes doit transporter la compagnie… » |
| 3·12 | Marge contributive (théorie) | « Citer au moins 3 coûts fixes », « Citer deux éléments entrant dans le coût variable » |
| 3·13 | Marge de sécurité, levier (hors cours) | aucune consigne du cours |
| 3·14 | Seuil multiproduits (hors cours) | aucune consigne du cours |

**4 · Analyse de bilan et résultat (51)** — `51_analyse.lua`, 12 entrées, plus 26 ratios un par un

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 4·1 | Analyse complète, 26 ratios | « Analyse de l'entreprise Yolanda SA », « Calculer et commenter, pour l'année 2014, les ratios suivants » |
| 4·2 | Ratios du bilan, 1 année | « En vous servant du bilan ci-après, veuillez calculer les ratios suivants pour l'année 2026 » (liquidité 1-3, couverture 1-2), « Expliquez ce que ceux-ci signifient pour l'entreprise » |
| 4·3 | Comparer 1 à 5 bilans | « Calculer les ratios pour les trois entreprises », « Veuillez apprécier le niveau de liquidités de ces trois entreprises » |
| 4·4 | Comparer X entreprises (ratios) | « Comparer les différentes structures de financement de ces entreprises », « Comparer et commenter les chiffres obtenus » |
| 4·5 | Bilan analytique (liste) | « Établir le bilan analytique, après répartition du bénéfice, de l'entreprise Xénon SA » |
| 4·6 | CR à degrés (balance) | « Présenter le Compte de résultat en mettant en évidence les résultats suivants », « Déterminer l'EBIT », « Déterminer la marge économique » |
| 4·7 | Chiffres clés (années) | « Calculer les chiffres clés suivants » (chiffre d'affaires par employé, au m²) |
| 4·8 | Rotations et durées | « Analyse du cycle des liquidités et des taux de marge » |
| 4·9 | ROI, ROE (+ levier, hors test) | « Calculer la rentabilité des fonds propres », « Calculer la rentabilité des capitaux investis », « Analyser le ROI (RCI) en décomposant la formule » |
| 4·10 | Fonds de roulement net | pas de consigne isolée relevée |
| 4·11 | Ratios un par un (26) | « Calculer encore le degré d'autofinancement et trouver une explication » |
| 4·12 | Vrai / faux (51.15) | « … indique toujours une situation… » (affirmations à juger) |

**5 · Trésorerie (57)** — `57_tresorerie.lua`, 7 entrées

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 5·1 | Tableau des liquidités | « Établir le tableau des liquidités » |
| 5·2 | Cash flow direct / indirect | « Présenter le calcul du cash-flow par la méthode indirecte », « Calculer l'augmentation des liquidités du secteur Exploitation » |
| 5·3 | Tableau des flux complet | « Tableau de flux de trésorerie (méthode directe) » |
| 5·4 | Effets des opérations | « Indiquer les effets des opérations suivantes sur le résultat (RN) ou les liquidités (LIQ) » |
| 5·5 | Ratios de cash flow, free cash flow | « Calculer l'endettement effectif, le cash flow et le facteur d'endettement », « Calculer les investissements nets… », « Évaluer la qualité des cash flow réalisés » |
| 5·6, 5·7 | BFR ; budget de trésorerie (hors cours) | aucune consigne du cours |

**6 · Coûts (59)** — `59_couts.lua`, 8 entrées

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 6·1 | Compte de stock au CMP | « Établir le compte de stock du slime », « Présenter le compte de stock de la matière première achetée ainsi que le CMP » |
| 6·2 | Répartition des charges indirectes | « Établir le tableau de répartition des charges indirectes » |
| 6·3 | Coûts complets en cascade | « Calculer le coût d'approvisionnement des matières premières achetées », « Déterminer le coût de transformation », « Calculer le prix de revient des paquets… distribués », « Calculer le résultat du mois de février » |
| 6·4 | Prix de revient d'une commande | « Calculer les prix de revient de X et Y ainsi que le résultat par produit » |
| 6·5 | Charges incorporables | « Déterminer le montant des charges incorporables du mois de décembre » |
| 6·6 | Résultat analytique → CG | « Détermination du résultat » (passage au résultat de la comptabilité générale) |
| 6·7 | Résultat par département | résultat par produit ou département avec frais généraux répartis |
| 6·8 | Coût de l'unité d'œuvre | « Compléter le tableau… afin de déterminer le coût par profil et par classe » |

**7 · Finance (hors cours)** — `70_finance.lua`, 6 entrées : intérêts et escompte, emprunt, VAN et TRI, amortissements, TVA, marge et marque.
Aucune consigne du cours n'y mène.

**1 · Aide-mémoire** — `10_aide.lua`, 10 entrées dont 5 sous-menus, 42 écrans : Révision du 12.11, Tableaux vides (12), Schémas (4),
Ratios (9), Formules par chapitre (5), Définitions (4), Articles du CO, Pièges et barème (4), Phrases de commentaire, Sources.
Consignes qui y mènent : « Nommer les quatre droites », « Indiquer ce que mesurent les 3 accolades » (1·3·3), « Sur quelle base légale
repose votre choix » (1·7), « Expliquez ce que ceux-ci signifient » (1·9).

### 2.2 Classeur maths : 48 solveurs dans un menu principal à 14 entrées

Source : `MATH_1/calculatrice/lua/solveur.lua`, lignes 2530-2600 (menu principal), 1453 (vecteurs), 2508 (outils).

| Chemin | Libellé | Consignes réelles qui y mènent |
|---|---|---|
| 1 | Résoudre (automatique) | « Résoudre les équations et inéquations suivantes », « Résoudre les équations pour x ∈ ℝ », « Résoudre l'inéquation \|−x+4\| > −3/x » |
| 2 | Problème A complet (vecteurs, blanc/test) | problème entier : « On considère les points P, Q et R… » |
| 3 | Problème B complet (figure, Chasles) : 3 figures + figure libre | « Exprimer le plus simplement possible les vecteurs suivants », « Exprimez les vecteurs suivants uniquement en fonction de u et de v » |
| 4 | Analyse de fonction (S7 ex.7-8) | « Donner les zéros et les pôles de f en précisant leurs multiplicités, puis dresser le tableau de signes », « Déterminer toutes les asymptotes de Cf », « On pose y = f(x). Exprimer x en fonction de y », « Représenter sur un graphique la courbe de f » |
| 5 | Identifier des réels a, b, c (S7 ex.5) | « Déterminer les réels a, b et c tels que ∀x, f(x) = ax + b + … », « Trouver deux nombres a et b tels que f(x) = a + … » |
| 6 | Factoriser un polynôme (détail) | « Factoriser chacun de ces polynômes (dans ℝ) » |
| 7·1 | Résoudre une équation (Δ, paramètre…) | « Soient {a, λ, m} ⊂ ℝ. Résoudre les équations pour u ou x » |
| 7·2 | Inéquation, valeur absolue | « Résoudre les inéquations suivantes » |
| 7·3 | Changement de variable | équations bicarrées, en x^(1/3), en eˣ |
| 7·4 | Division en potence A ÷ B | « Calculer le quotient et le reste de la division du polynôme f par le polynôme g » |
| 7·5 | Simplifier une fraction / expression | « Simplifier les fractions suivantes », « Simplifier chaque expression » |
| 7·6 | Factoriser et étudier le signe | « Décomposez en un produit de facteurs les polynômes suivants et étudiez leurs signes » |
| 8·1 | Norme, vecteur unitaire | « Calculer la norme des vecteurs a, b et c, puis donner des vecteurs unitaires de même direction » |
| 8·2 | Produit scalaire, angle | « Calculer l'angle formé par les vecteurs » |
| 8·3 | Projection d'un point sur une droite (AB) | « Trouver les coordonnées du point T, projection orthogonale de P sur la droite (QR) » |
| 8·4 | Projection d'un vecteur v sur u | « Donner la projection du vecteur a… », « Calculez la valeur de la projection orthogonale du vecteur b sur un axe » |
| 8·5 | Produit vectoriel, aire | « Calculer les produits vectoriels suivants » |
| 8·6 | Produit mixte, volume, coplanarité | « Calculer le volume du parallélépipède », « Montrez que les quatre points… sont coplanaires », « Calculez z de manière à ce que les quatre points soient coplanaires » |
| 8·7 | Paramètre : u ⊥ v | « Soit S(x; x+2; x)… tel que QS soit perpendiculaire à QR. Trouver les coordonnées de S », « Déterminer a et b pour que… soit orthogonal à… » |
| 8·8 | Paramètre : u, v colinéaires | « Déterminer m pour que les vecteurs suivants soient colinéaires » |
| 8·9 | Composantes dans une base | « Calculer les composantes du vecteur QS dans la base B », « Donner les coordonnées de P dans la base B′ » |
| 8·10 | Base orthonormée directe ? | « Déterminer si B est orthonormée », « Vérifier que les vecteurs… forment une base orthonormée de ℝ³ » |
| 8·11 | Construire une BON directe | « Construire une base orthonormée directe B₀ = {u, v, w} » |
| 9·1 | Domaine (racines, fractions) | « Déterminer le domaine de définition des fonctions suivantes » |
| 9·2 | Bijection sur I, f⁻¹ et courbes | « Trouver l'ensemble J tel que f soit une bijection de I vers J, puis donner l'expression de sa réciproque » |
| 9·3 | Parité | étude de parité (demandée dans l'analyse) |
| 9·4 | Composition f∘g et g∘f | « Calculer les fonctions f∘g et g∘f et déterminer leurs ensembles de définition » |
| 10 | Figure : Chasles, combinaisons : 3 figures + figure libre | mêmes consignes que 3, une somme à la fois |
| 11·1 | Angle par bilinéarité | « Calculer l'angle entre a et b sachant que ‖a‖ = 3, ‖b‖ = 4 et que 2a − b et a + b sont orthogonaux » |
| 11·2 | Points : milieu, gravité, parallélogramme… (6 outils) | « Soit ABC un triangle, son centre de gravité… », « Trouver l'inconnue dans les cas suivants » |
| 11·3 | Colinéarité / alignement par λ | « montrer que A, B, C sont alignés » (formulation donnée par l'étudiant ; pas retrouvée mot pour mot dans les séries 4 à 6) |
| 11·4 | Vecteur unitaire ⊥ à deux vecteurs | vecteur unitaire orthogonal à deux vecteurs donnés |
| 11·5 | Vecteur de norme donnée | vecteur de même direction et de norme imposée |
| 11·6 | Composantes dans une base (2D ou 3D) | doublon de 8·9 |
| 11·7 | Système de conditions (u.v=0 and …) | « Déterminer x et y tels que… », « Trouver C tel que le triangle ABC soit rectangle en A et d'aire 25 » |
| 12·1 | Factoriser une expression (lettres) | « Exprimez les réels suivants sous forme factorisée » |
| 12·2 | Isoler une lettre | « Résoudre les équations pour x, y, h ou v » |
| 13, 14 | Historique des résultats ; Aide à la saisie | — |

---

## 3. Mesure du problème

### 3.1 Méthode

- **Touches** : nombre de pressions depuis le menu principal du classeur jusqu'au premier écran de saisie du solveur. Les chiffres `1` à `9`
  ouvrent directement une entrée (`on.charIn`, `socle_fin.lua`). Au-delà du rang 9, il faut les flèches ; `▲` depuis la première ligne
  saute à la dernière, ce qui donne le chemin le plus court compté ici.
- **Affiché à l'ouverture** : `dessinerMenu` calcule `nvis = floor((h − 44) / 20)`, soit **8 lignes** sur un écran de 212 px. Une entrée de
  rang 9 ou plus n'apparaît qu'après défilement. Seul indice de sa présence : le compteur « 1/14 » en bas à droite. Ce chiffre vient du
  code, il n'a pas été observé sur la calculatrice.
- **Ambiguïté** : *faible* = un seul solveur plausible et le libellé reprend un mot de la consigne ; *moyenne* = deux solveurs plausibles,
  ou libellé sans mot commun avec la consigne ; *forte* = trois solveurs plausibles ou plus, ou le bon solveur porte le nom d'un exercice
  modèle et non celui de la tâche.
- Sources de l'échantillon : T25 = test compta de novembre 2025 ; F26 = examen compta de février 2026 ; 37, 44, 51, 57, 59 = séries du
  chapitre ; TM25 = test maths 2025 ; B1 = blanc 1 maths 2026 ; S1 à S7 = séries maths.

### 3.2 Échantillon compta (34 consignes)

| # | Source | Consigne | Solveur | Touches | Affiché | Ambiguïté | Où est le piège |
|---|---|---|---|---|---|---|---|
| C1 | T25 ex.1 | Calculer le résultat net réel en 2026 | 2·2 | 2 | oui | forte | 6 solveurs calculent un bénéfice réel (2·1, 2·2, 2·3, 2·4, 2·9, 2·11) ; le choix dépend du nombre de postes |
| C2 | T25 ex.2a | Dresser le Compte de résultat à deux degrés… | 3·1 | 2 | oui | moyenne | 4 solveurs « compte de résultat » : 3·1, 3·6, 4·6, 2·13 |
| C3 | T25 ex.2b | Calculer le PRAMA et le PRAMV | 3·1 | 2 | oui | faible | |
| C4 | T25 ex.2c | Calculer le CAN | 3·1 | 2 | oui | moyenne | « CAN » figure aussi dans 3·4 |
| C5 | T25 ex.3 | … calculer les ratios suivants pour l'année 2026 | 4·2 | 2 | oui | forte | 5 entrées « ratios » : 4·1, 4·2, 4·3, 4·11, 1·4 |
| C6 | T25 ex.4 | … valeur maximale à laquelle l'entreprise peut faire figurer… son stock au bilan | 2·6 | 2 | oui | moyenne | « valeur maximale » : 2·6, 2·7, 2·8 ; « 960c » ne parle qu'à qui connaît l'article |
| C7 | T25 ex.5 | Veuillez calculer les ratios suivants (3 entreprises) | 4·3 | 2 | oui | forte | 4·2 répété trois fois, 4·3 ou 4·4 |
| C8 | T25 ex.5 | Veuillez apprécier le niveau de liquidités de ces trois entreprises | 4·3 | 2 | oui | forte | « liquidités » renvoie aussi à 5·1 Tableau des liquidités |
| C9 | T25 ex.6a | Calculer combien de paquets… pour atteindre le point mort quotidien | 3·2 | 2 | oui | moyenne | « point mort » absent du libellé ; 9 entrées traitent du seuil |
| C10 | T25 ex.6b | Déterminer combien de paquets… pour faire un bénéfice de 500 CHF par jour | 3·2 | 2 | oui | faible | |
| C11 | T25 ex.7a | Veuillez créer un tableau de réserves latentes | 2·1 | 2 | oui | faible | |
| C12 | T25 ex.7b | Déterminer le bénéfice réel | 2·1 | 2 | oui | forte | même piège que C1 |
| C13 | T25 ex.7c | Déterminer les fonds propres réels | 2·1 | 2 | oui | moyenne | 2·12 « Fonds propres sur 3 ans » |
| C14 | T25 ex.8 | Montrer, graphiquement, le chiffre d'affaires à réaliser… | 3·7 | 2 | oui | moyenne | « chiffre d'affaires à réaliser » attire vers 3·3 |
| C15 | T25 ex.9 | Déterminer la valeur maximale à laquelle tous ces titres peuvent figurer au bilan | 2·7 | 2 | oui | faible | |
| C16 | T25 ex.10a | Déterminez le nombre de synthétiseurs qu'il faut vendre… pour obtenir un bénéfice net de 50'000 | 3·8 | 2 | oui | forte | « Licence » est le nom de l'exercice 44.16 ; 3·2 répond aussi |
| C17 | T25 ex.10b | À quel prix, minimum, peut-on vendre la totalité d'une commande minimum… | 3·8 | 2 | oui | forte | aucun autre solveur ne calcule un prix ; rien ne le dit dans « seuil » |
| C18 | T25 ex.10c | Calculer le pourcentage d'augmentation du volume de ventes… | 3·8 | 2 | oui | forte | 3·10 « Lot : changement de prix » paraît plus proche |
| C19 | F26 ex.1 | Établir le compte de stock du slime | 6·1 | 2 | oui | moyenne | « stock » figure dans 5 libellés du chap. 37 |
| C20 | F26 ex.2a | Établir le tableau des liquidités | 5·1 | 2 | oui | moyenne | liquidité 1-2-3 (chap. 51) |
| C21 | F26 ex.2b | Présenter le calcul du cash-flow par la méthode indirecte | 5·2 | 2 | oui | moyenne | 5·3 le contient aussi ; 5·5 « Ratios de cash flow » |
| C22 | F26 ex.2c | Tableau de flux de trésorerie (méthode directe) | 5·3 | 2 | oui | faible | |
| C23 | F26 ex.3a | Établir le tableau de répartition des charges indirectes | 6·2 | 2 | oui | faible | |
| C24 | F26 ex.3b, d, f, h | Calculer le coût d'approvisionnement… / de transformation… / le prix de revient des paquets distribués | 6·3 | 2 | oui | forte | « cascade » n'apparaît dans aucune consigne ; 6·4 porte les mots « prix de revient » |
| C25 | F26 ex.3i | Calculer le résultat du mois de février | 6·3 | 2 | oui | forte | 6·6 et 6·7 commencent par « Résultat » |
| C26 | 37 | Calculer le montant de la reprise fiscale et le bénéfice fiscal en N1 | 2·9 | 2 | non | moyenne | deux entrées (2·9 stock, 2·10 postes) |
| C27 | 37 | Journaliser les écritures de dissolution des réserves latentes | 2·13 | 4 | non | faible | |
| C28 | 37 | À quel prix maximum pouvez-vous évaluer cet objet lors de la première comptabilisation ? | 2·8 | 2 | oui | moyenne | « prix maximum » ≠ « coût d'acquisition » |
| C29 | 44 | Déterminer le chiffre d'affaire à réaliser pour rentabiliser les fonds propres de CHF 2'400'000 | 3·3 | 2 | oui | forte | évoque le ROE (4·9) ; le champ « fonds propres à rémunérer » est caché dans 3·3 |
| C30 | 44 | Déterminer par un calcul combien de personnes doit transporter la compagnie… | 3·11 | 6 | non | moyenne | 3·2 répond en partie |
| C31 | 51 | Calculer la rentabilité des fonds propres | 4·9 | 2 | non | moyenne | libellé en sigles (ROI, ROE) ; « rentabilité » évoque le seuil |
| C32 | 51 | Présenter le Compte de résultat en mettant en évidence les résultats suivants | 4·6 | 2 | oui | moyenne | même tournure que C2, autre solveur |
| C33 | 57 | Calculer l'endettement effectif, le cash flow et le facteur d'endettement | 5·5 | 2 | oui | moyenne | « endettement » évoque le degré d'endettement (4·2) |
| C34 | 59 | Déterminer le montant des charges incorporables du mois de décembre | 6·5 | 2 | oui | faible | |

### 3.3 Échantillon maths (24 consignes)

| # | Source | Consigne | Solveur | Touches | Affiché | Ambiguïté | Où est le piège |
|---|---|---|---|---|---|---|---|
| M1 | TM25 P1a | Résoudre (mx)² − 2mx − 3 = 0 où m est un paramètre | 1 | 1 | oui | faible | |
| M2 | TM25 P1b | Résoudre 6e³ˣ + 5e²ˣ − 2eˣ − 1 = 0 | 1 | 1 | oui | faible | |
| M3 | TM25 P1c | Résoudre \|x − 1\| / (x + 2) ≥ 1/2 | 1 | 1 | oui | faible | |
| M4 | TM25 P2a | Trouver les coordonnées du point T, projection orthogonale de P sur la droite (QR) | 8·3 | 2 | oui | moyenne | 8·4 « Projection d'un vecteur » ; 2 le fait aussi |
| M5 | TM25 P2b-i | Soit S(x; x+2; x) tel que QS soit perpendiculaire à QR. Trouver les coordonnées de S | 8·7 | 2 | oui | moyenne | libellé « Paramètre : u ⊥ v », la consigne parle d'un point |
| M6 | TM25 P2b-ii | Calculer le volume du parallélépipède | 8·6 | 2 | oui | faible | |
| M7 | TM25 P2b-iii | Calculer les composantes du vecteur QS dans la base B | 8·9 | 2 | non | moyenne | doublon 8·9 et 11·6 |
| M8 | TM25 P2b-iv | Déterminer si B est orthonormée | 8·10 | 4 | non | faible | |
| M9 | TM25 P2c | Construire une base orthonormée directe | 8·11 | 3 | non | faible | |
| M10 | TM25 P3a | Exprimer le plus simplement possible les vecteurs suivants | 3·4 | 2 | oui | forte | 3 et 10 font presque la même chose ; la figure du test n'est pas préréglée |
| M11 | TM25 P3b | Exprimez les vecteurs suivants uniquement en fonction de u et de v | 3·4 | 2 | oui | moyenne | même piège |
| M12 | TM25 P3c | En s'aidant du quadrillage, calculer la surface du logo | **aucun** | — | — | — | manque (section 5) |
| M13 | S7 ex.1 | Déterminer le domaine de définition des fonctions suivantes | 9·1 | 2 | non | moyenne | 3 chemins (9·1, 4, 1) ; le libellé de 4 ne dit pas « domaine » |
| M14 | B1 | Donner les zéros et les pôles de f…, puis dresser le tableau de signes | 4 | 1 | oui | moyenne | « Analyse de fonction (S7 ex.7-8) » ne cite ni zéros, ni pôles, ni signes |
| M15 | B1 | Trouver deux nombres réels a et b tels que f(x) = a + b/(x² − 4) | 5 | 1 | oui | moyenne | « Identifier » n'est pas le verbe du prof |
| M16 | B1, S7 | Déterminer toutes les asymptotes de Cf | 4 | 1 | oui | forte | le mot « asymptote » n'est dans aucun libellé |
| M17 | B1 | Trouver l'ensemble J tel que f soit une bijection de I vers J, puis… sa réciproque | 9·2 | 2 | non | moyenne | 4 traite aussi la bijection |
| M18 | S7 ex.6 | Déterminer les minima et maxima de f(x) = x² + x + 2 sur les intervalles… | **aucun** | — | — | — | manque (section 5) |
| M19 | S3 ex.1 | Calculer le quotient et le reste de la division du polynôme f par le polynôme g | 7·4 | 2 | oui | faible | |
| M20 | S3 ex.3 | Décomposez en un produit de facteurs les polynômes suivants et étudiez leurs signes | 7·6 | 2 | oui | forte | 3 entrées « factoriser » (6, 7·6, 12·1), plus 1 |
| M21 | S1 ex.8 | Résoudre les équations pour x, y, h ou v | 12·2 | 5 | non | forte | « Résoudre » mène à 1, qui ne reconnaît ni y, ni h, ni v (`COUVERTURE.md`, pièges de saisie) |
| M22 | S5, S6 | Déterminer m pour que les vecteurs suivants soient colinéaires | 8·8 | 2 | oui | moyenne | deux entrées « colinéarité » dans deux menus |
| M23 | étudiant | Montrer que A, B, C sont alignés | 11·3 | 6 | non | forte | rangé sous « Vecteurs sans composantes, systèmes » |
| M24 | S5 ex.4 | Calculer l'angle entre a et b sachant que ‖a‖ = 3, ‖b‖ = 4… | 11·1 | 6 | non | moyenne | 8·2 « Produit scalaire, angle » exige des composantes |

### 3.4 Chiffres

| | Compta | Maths | Total |
|---|---|---|---|
| Consignes de l'échantillon | 34 | 24 | 58 |
| Avec un solveur | 34 | 22 | 56 |
| Touches, moyenne | 2,18 | 2,36 | 2,25 |
| Ouvertes en 2 touches ou moins | 32 | 17 | 49 |
| Non affichées à l'ouverture du menu | 4 | 8 | 12 |
| Ambiguïté forte | 11 | 5 | 16 |
| Ambiguïté moyenne | 15 | 10 | 25 |
| Ambiguïté faible | 8 | 7 | 15 |
| Ambiguïté moyenne ou forte | 26 (76 %) | 15 (68 %) | 41 (73 %) |

### 3.5 Les douze familles d'ambiguïté

| Mots de la consigne | Solveurs candidats | Ce qui tranche |
|---|---|---|
| bénéfice réel, résultat réel | 2·1, 2·2, 2·3, 2·4, 2·9, 2·11 | un poste ou plusieurs ; nature de la donnée (ducroire, fraction du stock) ; une année ou plusieurs |
| valeur maximale, prix maximum au bilan | 2·6, 2·7, 2·8 | stock (article par article), titres, première inscription d'un actif |
| point mort, seuil de rentabilité | 3·2, 3·3, 3·5, 3·6, 3·7, 3·8, 3·10, 3·11 | réponse en quantité ou en CHF ; données unitaires ou compte de résultat ; « graphiquement » ; prix qui change |
| chiffre d'affaires à réaliser pour un bénéfice de | 3·3, 3·7, 3·2 | calcul ou graphique ; taux de marge ou prix et coût unitaires |
| calculer les ratios | 4·1, 4·2, 4·3, 4·4, 4·11, 5·5, 1·4 | une entreprise ou plusieurs ; bilans ou ratios déjà calculés ; un seul ratio |
| compte de résultat | 3·1, 3·6, 4·6, 2·13 | deux degrés sur marchandises ; prévisionnel ; à degrés avec EBIT ; interne et externe |
| liquidité, liquidités | 4·2, 4·3, 5·1 | ratio (liquidité 1-2-3) ou tableau des liquidités (chap. 57) |
| rentabilité | 4·9, 3·2, 3·3 | rentabilité des fonds propres (ROE) ou seuil de rentabilité |
| stock | 2·4, 2·5, 2·6, 2·9, 6·1, 4·8 | évaluation (37), compte de stock au CMP (59), rotation (51) |
| prix de revient, coût de revient | 6·3, 6·4, 3·8 | production en cascade, commande, prix de revient d'achat d'une marchandise |
| factoriser, décomposer en facteurs | maths 6, 7·6, 12·1, 1 | un polynôme en x ; avec le signe ; plusieurs lettres |
| colinéaires, alignés, parallèles | maths 8·8, 11·3 | paramètre à trouver ou démonstration sur des points |

### 3.6 Autres défauts d'accès relevés dans le code

1. **Entrées hors écran.** Menus de 14 entrées (2 · Réserves, 3 · Seuil, menu principal maths) : 6 entrées sur 14 sont invisibles à
   l'ouverture. Le rang 9 s'ouvre avec la touche `9` mais n'est pas affiché ; les rangs 10 à 14 n'ont pas de chiffre.
2. **Libellés qui nomment l'exercice modèle au lieu de la tâche** : « Licence : quantité, prix min., baisse », « Lot : changement de prix »,
   « Test 2025 ex. 10 (prof + livre) », « Coûts complets en cascade », « Base du taux, CAN depuis la MB », « Analyse de fonction (S7 ex.7-8) ».
3. **Libellés en sigles ou en numéros d'article** : « ROI, ROE », « (960c) », « FRN », alors que le prof écrit « rentabilité des fonds
   propres », « valeur maximale », « fonds de roulement ».
4. **Doublons maths** : 8·9 et 11·6 (composantes dans une base), 3 et 10 (Chasles), 1 et 7·1 et 7·2 (résoudre), 6 et 7·6 et 12·1 (factoriser).
5. **Maths : `esc` revient toujours au menu principal** (`on.escapeKey`, `solveur.lua` l.3012). Une erreur de choix au troisième niveau
   (11 › Points › Milieu) coûte tout le chemin. Le socle compta a une pile (`PILE_MENUS`) et revient d'un seul niveau.
6. **Libellés longs** : « Points : milieu, gravité, parallélogramme, symétrique, rapport, relation » (73 caractères) et « Fonctions :
   domaine, parité, composition, bijection sur I » (56 caractères) dépassent probablement les 318 px en police 10. À vérifier sur l'écran :
   la largeur n'a pas été mesurée.

---

## 4. Solutions

### 4.1 Comparaison

| | Solution | Effort | Poids dans le script | Au clavier TI | Ce qu'elle règle | Limite |
|---|---|---|---|---|---|---|
| A | Arbre « Que demande la consigne ? » (questions courtes à choix) | 1 jour : environ 60 nœuds à rédiger et à tester | environ 6 Ko | 3 à 4 chiffres, aucune lettre | tranche les familles de 3.5 | déplace le problème : il faut reconnaître la bonne branche dès la première question ; un arbre par classeur, à maintenir à part |
| B | **Recherche incrémentale par mots-clés** avec index de synonymes et ligne « à choisir si… » | 1 jour compta, 0,5 jour maths | moteur 130 lignes (4 Ko), index 8 Ko pour 98 entrées, 13 Ko environ avec les lignes « si » | 3 à 8 lettres puis `enter` | vocabulaire (sigles, mots du prof), entrées hors écran, familles ambiguës | index à tenir à jour ; plus de touches que le chemin direct |
| C | Taper la consigne entière, 3 solveurs proposés | 0 en plus de B (même moteur) | 0 | 60 à 150 lettres sur un petit clavier, sans accents | rien de plus que B | trop long à saisir ; pas de copier-coller depuis une feuille |
| D | Renommer les libellés avec les verbes et les noms des consignes | 2 h | 0 | inchangé | défauts 2 et 3 de la section 3.6 | 22 caractères utiles par libellé ; ne tranche pas les familles |
| E | Fiche papier « consigne → touches », produite depuis l'index | 2 h (script Python) | 0 | aucune | révision loin de la calculatrice | à réimprimer quand les menus changent ; inutilisable au test de compta (aucun résumé autorisé, `10_aide.lua` l.35) |
| F | Index alphabétique dans l'aide (mot → chemin) | 3 h | 5 Ko | défilement d'une liste de 150 lignes | vocabulaire | lent sans recherche ; B le remplace |
| G | Neuf entrées au plus par menu, regroupement des doublons | 3 h | 0 | chaque solveur en 2 chiffres, tout affiché | entrées hors écran, doublons maths | change les chemins appris ; à faire en même temps que D |

### 4.2 Recommandation

**B, avec D et G légers, puis E.**

- B est la seule option qui traite la cause mesurée (73 % d'ambiguïté) et qui sert aux deux classeurs avec le même code.
- L'arbre A n'est pas retenu comme écran à part. Son contenu utile, la question qui tranche, est repris dans B sous forme d'une ligne grise
  « si : … » sous chaque résultat. Taper un mot de famille (`seuil`, `ratio`, `stock`, `reel`) affiche donc la famille avec ses critères :
  c'est le deuxième niveau de l'arbre, sans arbre à maintenir.
- C vient gratuitement avec B : si l'étudiant tape plus de mots, le score s'affine. Aucun écran en plus.
- B ne fait pas gagner de touches : `duc` + `enter` coûte 4 touches contre 2 pour `2` `3`. Le gain est sur l'hésitation. Chaque résultat
  affiche son chemin (`2·3`) pour que le raccourci direct s'apprenne à l'usage.
- La fiche E reprend les mêmes lignes « si : … ». Pour la compta, où la calculatrice programmable n'est pas autorisée au test, c'est cette
  correspondance consigne → méthode que l'étudiant doit savoir par cœur ; l'écran de recherche la lui fait réviser.

### 4.3 Structure de données

L'index est porté par l'entrée de menu elle-même, pour ne pas dériver quand un menu est réordonné :

```lua
-- entrée de menu aujourd'hui : {"Ducroire", function() … end}
-- entrée de menu indexée (champs nommés en plus, ignorés par dessinerMenu) :
{"Ducroire", function() formu("Ducroire", CH_DUC, ducroire) end,
  forts = "ducroire",                                             -- mots propres à ce solveur : 3 points
  mots  = "creance client provision risque perte reel benefice",   -- mots partagés : 1 point
  si    = "un seul poste : le ducroire (x % des créances)"},       -- ligne grise affichée sous le résultat
```

Règles de rédaction de l'index :

- **Tout en minuscules ASCII, sans accent, au singulier, sous forme de radical** : `maxim` couvre « maximale » et « maximum », `fisc` couvre
  « fiscal » et « fisc », `graph` couvre « graphique » et « graphiquement ». L'index n'est donc jamais normalisé à l'exécution.
- **`forts`** : 1 à 5 mots qui ne désignent que ce solveur (ou sa petite famille). **`mots`** : les mots de la consigne partagés avec
  d'autres solveurs (`benefice`, `stock`, `tableau`), et les sigles (`pm`, `rl`, `fp`, `can`, `cr`, `tft`, `cmp`, `roi`).
- **Verbes** : « calculer », « déterminer », « trouver », « donner » ne distinguent rien et vont dans la liste des mots ignorés. Les verbes
  qui orientent restent dans l'index : `dresser`, `etablir`, `presenter` (tableau à produire), `journaliser` (écritures), `montrer` et
  `representer` (graphique), `comparer`, `apprecier`, `commenter` (plusieurs entreprises), `exprimer`, `construire`, `factoriser`.
- **`si`** : 45 caractères au plus, rédigé comme la réponse à « je choisis celui-ci quand… ».

Construction de l'index au démarrage : le socle parcourt l'arbre des menus à partir de `menuPrincipal()` et note, pour chaque entrée qui a
un champ `forts`, son chemin (`2·3`), son libellé et sa fonction. Pour la compta, `MENUS_COMPTA` est déjà une table de données, le parcours
est direct. Pour les maths, les sous-menus sont construits dans des fermetures : soit on en fait des tables nommées (petit remaniement),
soit l'index maths est déclaré à part avec le chemin écrit en clair et lancé par « rejeu du chemin » :

```lua
-- lance le solveur de chemin {8, 3} : rejoue les choix de menu, sans rien dupliquer
local function ouvrirChemin(ch)
  menuPrincipal()
  for _, i in ipairs(ch) do sel = i; MENU.items[i][2]() end
end
```

Dans ce second cas, un test PC doit vérifier que chaque chemin de l'index mène bien au libellé enregistré (section 4.7).

### 4.4 Normalisation, clavier TI, score

**Clavier.** Le clavier de la TI-Nspire CX II a les 26 lettres en accès direct, l'espace et l'effacement. Les lettres accentuées demandent
une combinaison de touches. La saisie se fait donc **sans accent et sans majuscule**, et c'est la saisie qui est normalisée, pas l'index.
Les menus n'utilisent que les chiffres : une lettre tapée dans un menu est libre et peut ouvrir la recherche sans changer aucune habitude.

**Normalisation de la saisie** (Lua 5.1, pas de bibliothèque UTF-8 : remplacement des séquences d'octets) :

```lua
local ACC = {["\195\169"]="e", ["\195\168"]="e", ["\195\170"]="e", ["\195\171"]="e", ["\195\160"]="a", ["\195\162"]="a",
  ["\195\167"]="c", ["\195\185"]="u", ["\195\187"]="u", ["\195\174"]="i", ["\195\175"]="i", ["\195\180"]="o", ["\197\147"]="oe",
  ["\195\137"]="e", ["\195\136"]="e", ["\195\128"]="a"}
local STOP = {le=1, la=1, les=1, de=1, du=1, des=1, un=1, une=1, et=1, a=1, au=1, en=1, pour=1, que=1, sur=1, par=1,
  calculer=1, determiner=1, trouver=1, donner=1, veuillez=1}
local function motsDe(s)
  s = s:gsub("[\195\197][\128-\191]", ACC):lower():gsub("[^a-z0-9/]+", " ")
  local t = {}
  for m in s:gmatch("%S+") do if not STOP[m] then t[#t + 1] = m end end
  return t
end
```

**Correspondance d'un mot tapé `t` avec un mot d'index `w`** :

```lua
local function colle(t, w)
  if #t <= 2 or #w <= 2 then return t == w end                    -- sigles : égalité stricte (pm, rl, fp, ca)
  return w:sub(1, #t) == t                                         -- début de mot tapé : « duc » → « ducroire »
      or (#w >= 4 and t:sub(1, #w) == w)                           -- mot fléchi : « titres » → « titre », « graphiquement » → « graph »
end
```

**Score d'une entrée** : pour chaque mot tapé distinct, 3 points s'il colle à un mot `forts`, sinon 1 point s'il colle à un mot `mots`.
Classement par score décroissant ; à égalité, ordre des menus. Les entrées à 0 point ne sont pas affichées.

**Coût à l'exécution** : 98 entrées, 12 mots en moyenne, 1 à 3 mots tapés, soit moins de 4 000 comparaisons de préfixes par frappe.
Les listes de mots sont découpées une seule fois, à la première recherche. Le temps réel sur la calculatrice reste à mesurer.

### 4.5 Insertion dans le socle

| Fichier | Ajout |
|---|---|
| `tools/nspire/socle_debut.lua`, après `demander` (l.326) | un bloc `do … end` qui expose une seule table globale `CHERCHE` : `motsDe`, `colle`, `indexer(menuRacine)`, `chercher(texte)` → liste triée `{ch, lib, si, fn, score}`. Un seul nom global : le script a déjà 72 variables locales de premier niveau, la limite Lua est de 200 |
| `tools/nspire/socle_fin.lua`, `on.paint` | un quatrième écran `ecran == "cherche"` et sa fonction `dessinerCherche` |
| `socle_fin.lua`, `on.charIn` | dans un menu, un caractère qui n'est pas un chiffre ouvre la recherche avec ce caractère ; dans l'écran de recherche, il s'ajoute à la saisie et relance `chercher` |
| `socle_fin.lua`, `on.backspaceKey`, `on.clearKey`, flèches, `on.enterKey`, `on.escapeKey` | effacer ; `▲▼` changent de résultat ; `enter` lance la fonction du résultat choisi ; `esc` revient au menu d'où l'on vient |
| `socle_fin.lua`, `dessinerMenu` | pied de menu : « ▲▼ choisir   enter : ouvrir   lettres : chercher » |
| `GESTION_ENTREPRISE/calculatrice/lua/NN_*.lua` | champs `forts`, `mots`, `si` sur les entrées de `MENUS_COMPTA` |
| `99_menu.lua` | appel de `CHERCHE.indexer` après le tri des menus |
| `tools/nspire/test_pc.py` | option `--cherche "mots"` qui imprime les 3 premiers résultats (section 4.7) |

**Classeur maths : il n'utilise pas le socle.** `MATH_1/calculatrice/lua/solveur.lua` est un script d'un seul tenant de 3 021 lignes, avec
sa propre copie des menus et des touches. Le socle en a été extrait, puis modifié à la main depuis le 11.11.2026 (`extraire_socle.py`
refuse désormais de le régénérer). Deux voies :

1. **Court terme** : recopier le bloc `CHERCHE` et les six points d'accroche dans `solveur.lua`. Le code des menus y est identique à celui
   du socle, la recopie est mécanique. Marge de variables locales : 156 utilisées sur 200, d'où le bloc `do … end`.
2. **Propre** : passer le classeur maths sur `construire_app.py` (socle + modules). Les fichiers non suivis `MATH_1/calculatrice/lua/_*.lua`
   ressemblent à un découpage de `solveur.lua` en modules déjà commencé ; s'il aboutit, la recherche arrive sans recopie, avec la pile de
   menus (`esc` remonte d'un niveau) en prime.

### 4.6 Écrans (318 × 212 px ; bandeau 20 px, pied 16 px)

**Menu principal** : rien ne bouge, seul le pied change.

```
┌────────────────────────────────────────────────────┐
│ Compta – solveur                                   │ bandeau
│ 1  Aide-mémoire                                    │
│ 2  Réserves latentes, évaluation (37)              │
│ 3  Compte de résultat, seuil (44)                  │
│ 4  Analyse de bilan et résultat (51)               │
│ 5  Trésorerie (57)                                 │
│ 6  Coûts (59)                                      │
│ 7  Finance (hors cours)                            │
│ 8  Historique des résultats                        │
│ ▲▼ choisir   enter : ouvrir   lettres : chercher   │ pied
└────────────────────────────────────────────────────┘
```

**Recherche, après avoir tapé `ben reel`** : zone de saisie de 24 px, puis 4 résultats de 36 px (libellé en gras, critère en gris).

```
┌────────────────────────────────────────────────────┐
│ Trouver un solveur                          1 / 13 │ bandeau
│ ┌────────────────────────────────────────────────┐ │
│ │ ben reel▏                                      │ │ saisie
│ └────────────────────────────────────────────────┘ │
│▌2·2  Résultat réel (un poste)                      │ sélection
│▌     si : une seule RL (stock), RL initiale donnée │
│ 2·1  Tableau des RL → BN, FP réels                 │
│      si : plusieurs postes, ou FP réels demandés   │
│ 2·3  Ducroire                                      │
│      si : le seul poste est le ducroire            │
│ 2·4  Stock à une fraction (PRAMV)                  │
│      si : « stock évalué aux 2/3 de sa valeur »    │
│ ▲▼ choisir  enter : ouvrir  esc : menu  clear      │ pied
└────────────────────────────────────────────────────┘
```

**Recherche d'une famille, `seuil`** : c'est l'arbre de questions, à plat. Écran visé : dans l'index du prototype, `seuil` ne touche
que 5 entrées (3·2, 3·3, 3·10, 3·11, 3·14), parce que 3·5 à 3·8 ne portent que « point mort ». Le mot de famille est à ajouter à ces
quatre entrées.

```
┌────────────────────────────────────────────────────┐
│ Trouver un solveur                           1 / 9 │
│ ┌────────────────────────────────────────────────┐ │
│ │ seuil▏                                         │ │
│ └────────────────────────────────────────────────┘ │
│▌3·2  Seuil en quantité, bénéfice visé              │
│▌     si : prix et coût unitaires, réponse en unités│
│ 3·3  Seuil en valeur (taux de marge)               │
│      si : CA et PRAMV donnés, réponse en CHF       │
│ 3·7  Graphique du seuil                            │
│      si : « montrer graphiquement », 4 droites     │
│ 3·8  Licence : quantité, prix min., baisse         │
│      si : prix minimum, ou baisse de prix en %     │
│ ▲▼ choisir  enter : ouvrir  esc : menu  clear      │
└────────────────────────────────────────────────────┘
```

**Aucun résultat** : la saisie reste, l'écran propose les mots de famille.

```
┌────────────────────────────────────────────────────┐
│ Trouver un solveur                           0 / 0 │
│ ┌────────────────────────────────────────────────┐ │
│ │ dividende▏                                     │ │
│ └────────────────────────────────────────────────┘ │
│ Aucun solveur pour « dividende ».                  │
│ Essayer un mot de la consigne, sans accent :       │
│   reel  max  seuil  graph  ratio  comparer  cr     │
│   stock  cash  flux  cout  repart  fisc  titre     │
│ Sigles : pm  rl  fp  can  pramv  roi  roe  cmp     │
│                                                    │
│ esc : menu   clear : effacer                       │
└────────────────────────────────────────────────────┘
```

**Fiche papier (option E), extrait** : une ligne par entrée d'index, triée par mot de consigne.

```
MOT DE LA CONSIGNE        SI…                                  TOUCHES   SOLVEUR
bénéfice réel             un seul poste (stock)                2 2       Résultat réel (un poste)
bénéfice réel             plusieurs postes, FP réels           2 1       Tableau des RL
valeur maximale           stock, article par article           2 6       Valeur max. du stock
valeur maximale           titres cotés / non cotés             2 7       Titres
point mort                en unités (prix, coût unitaires)     3 2       Seuil en quantité
point mort                en CHF (taux de marge brute)         3 3       Seuil en valeur
point mort                « graphiquement »                    3 7       Graphique du seuil
```

### 4.7 Exemple d'index rempli et résultat du prototype

L'index complet du prototype (98 entrées : 61 compta, 37 maths) est en annexe A. Extrait pour 15 consignes réelles : la saisie indiquée
est la plus courte qui a été essayée, les trois résultats sont ceux que le prototype a rendus, avec leur score.

| Consigne réelle | Saisie | Mots d'index touchés | 1er | 2e | 3e |
|---|---|---|---|---|---|
| Calculer le résultat net réel en 2026 | `reel` | `reel` (fort de 2·2) | **2·2** (3) | 2·1 (1) | 2·3 (1) |
| Déterminer la valeur maximale à laquelle… son stock au bilan | `max stock` | `maxim` (fort), `stock` | **2·6** (4) | 2·1 (1) | 2·2 (1) |
| Déterminer la valeur maximale à laquelle tous ces titres… | `titr` | `titre` (fort) | **2·7** (3) | 2·1 (1) | |
| Veuillez créer un tableau de réserves latentes | `tab rl` | `tableau`, `rl` (forts) | **2·1** (6) | 2·12 (1) | 5·1 (1) |
| Dresser le Compte de résultat à deux degrés… | `cr deg` | `cr`, `degres` (fort) | **3·1** (4) | 7·4 (3) | 3·6 (2) |
| Calculer combien de paquets… point mort quotidien | `pm comb` | `pm`, `combien` (fort) | **3·2** (4) | 3·3 (1) | 3·5 (1) |
| Montrer, graphiquement, le chiffre d'affaires à réaliser | `graph` | `graphique` (fort) | **3·7** (3) | | |
| À quel prix, minimum, peut-on vendre la totalité… | `prix min` | `prix`, `minimum` (fort) | **3·8** (4) | 2·8 (1) | 3·10 (1) |
| Calculer le pourcentage d'augmentation du volume de ventes… | `pourc` | `pourcentage` (fort) | **3·8** (3) | | |
| … calculer les ratios suivants pour l'année 2026 (liquidité 1…) | `rat liq` | `ratio`, `liquidite` (forts) | **4·2** (6) | 4·11 (4) | 5·1 (3) |
| Établir le tableau des liquidités | `tab liq` | `tableau`, `liquidite` (fort) | **5·1** (4) | 2·1 (3) | 4·2 (3) |
| Calculer le coût d'approvisionnement des matières premières | `cout appro` | `cout`, `approvisionnement` (fort) | **6·3** (4) | 2·8 (1) | 3·12 (1) |
| Déterminer toutes les asymptotes de Cf | `asym` | `asymptote` (fort) | **4** (3) | | |
| Montrer que A, B, C sont alignés | `align` | `aligne` (fort) | **11·3** (3) | | |
| Décomposez en un produit de facteurs… et étudiez leurs signes | `fact signe` | `factoriser`, `signe` (fort) | **7·6** (4) | 6 (3) | 12·1 (3) |

Lignes d'index correspondantes (format de l'annexe A) :

```lua
IDX("2·2", "reel poste",                  "resultat benefice net perte publier stock inventaire")
IDX("2·6", "maxim 960c venale",           "stock article marchandise valeur bilan figurer evaluation pra completer")
IDX("3·7", "graphique graphe droite",     "montrer representer point mort chiffre affaires perte benefice tracer")
IDX("3·8", "licence minimum pourcentage", "prix commande reduction baisse augmentation volume ventes couvrir nombre vendre benefice point mort importation")
IDX("5·1", "liquidite tresorerie",        "tableau etablir caisse poste banque variation")
```

**Résultat sur les 56 consignes de l'échantillon** (prototype Python des règles de 4.4, exécuté sur PC le 11.11.2026) :

| Saisie | Bon solveur en tête | Dans les trois premiers |
|---|---|---|
| Courte (1 ou 2 débuts de mots, 3 à 12 lettres) | 53 / 56 | 56 / 56 |
| Consigne entière | 53 / 56 | 55 / 56 |

Ce que ces chiffres ne prouvent pas :

- **L'index a été rédigé en connaissant les 56 consignes.** Le taux réel sur des consignes nouvelles sera plus bas. Il faut le remesurer
  sur le blanc 2 et les séries suivantes avant de s'y fier.
- Les saisies courtes ont été choisies par quelqu'un qui connaît l'index. Un étudiant tapera d'autres débuts de mots.
- Le prototype est en Python ; le moteur Lua n'existe pas encore.

Ratés et faux amis observés, à corriger dans l'index :

- `comp` seul (pour « comparer ») touche aussi `comptabilisation` (2·8) et `complete` (4·1) : 4·3 n'arrive que troisième. `compar` règle le cas.
- Les mots de famille manquent sur une partie des entrées : `seuil` ne liste ni 3·7 ni 3·8 (voir 4.6). Chaque entrée d'une famille
  de la section 3.5 doit porter le mot de la famille.
- `cr deg` fait remonter 7·4 « Amortissements… dégressif » en deuxième.
- `fp reel` et la consigne entière « Déterminer les fonds propres réels » placent 2·2 ou 2·12 avant 2·1 : il faut `fp` et `propres` en
  mots forts de 2·1.
- `prix max` place 2·6 (stock) avant 2·8 (coût d'acquisition) : `prix` doit devenir un mot fort de 2·8.
- « Montrer, graphiquement, le chiffre d'affaires à réaliser… » tapée en entier place 3·3 (10 points) devant 3·7 (9 points) : les mots
  partagés finissent par peser plus qu'un mot fort. Remède : donner 5 points au lieu de 3 aux mots forts, ou plafonner les points de `mots`.
- « Résoudre les équations pour x, y, h ou v » tapée en entier ne trouve pas 12·2 : rien dans la phrase ne dit « isoler ». C'est la ligne
  « si : » de « Résoudre (automatique) » qui doit le dire (« inconnue x, u, t ou a ; sinon Isoler une lettre »).

### 4.8 Test de non-régression proposé

Un fichier `tools/nspire/consignes-test.txt` reprend les tableaux 3.2 et 3.3 : `classeur ; saisie ; chemin attendu`.
`test_pc.py APP.lua --cherche-tout consignes-test.txt` échoue si un chemin attendu sort des trois premiers résultats, ou si un chemin
d'index ne mène plus au libellé enregistré. À lancer par `construire.py` avant d'écrire le `.tns`.

### 4.9 Compléments D et G : renommages et regroupements proposés

| Chemin | Libellé actuel | Libellé proposé (22 caractères utiles) | Raison |
|---|---|---|---|
| 2·2 | Résultat réel (un poste) | Bénéfice réel, 1 poste | mot du prof : « bénéfice réel » |
| 2·6 | Valeur max. du stock (960c) | Stock : valeur maximale | « 960c » passe dans le corps du solveur |
| 2·8 | Coût d'acquisition, amort. | Prix max. 1re inscription | consigne : « à quel prix maximum… première comptabilisation » |
| 3·2 | Seuil en quantité, bénéfice visé | Point mort en quantité | « point mort » est le mot du test 2025 |
| 3·3 | Seuil en valeur (taux de marge) | Point mort en CHF (CA) | même raison ; « chiffre d'affaires à réaliser » |
| 3·8 | Licence : quantité, prix min., baisse | Prix minimum, baisse en % | la tâche, pas l'exercice 44.16 |
| 3·10 | Lot : changement de prix | Prix changé en cours | |
| 4·9 | ROI, ROE (+ levier, hors test) | Rentabilité : ROI, ROE | consigne : « rentabilité des fonds propres » |
| 6·3 | Coûts complets en cascade | Coûts : appro → revient | consignes : coût d'approvisionnement, de transformation, prix de revient |
| maths 4 | Analyse de fonction (S7 ex.7-8) | Fonction : zéros, asymptotes | mots des consignes du blanc 1 |
| maths 5 | Identifier des réels a, b, c (S7 ex.5) | a, b tels que f = a + b/… | consigne : « trouver a et b tels que » |
| maths 11 | Vecteurs sans composantes, systèmes | Alignés, milieu, systèmes | « alignés » devient visible |

Regroupements pour tenir en 9 entrées par menu :

- **2 · Réserves (14 → 9)** : 2·9 et 2·10 fusionnent en « Reprises fiscales » ; 2·11 et 2·12 passent dans un sous-menu « Plusieurs années » ;
  2·13 et 2·14 dans « Dissolution, théorie ».
- **3 · Seuil (14 → 9)** : 3·9 devient un jeu de données par défaut de 3·8 ; 3·12 à 3·14 passent dans un sous-menu « Théorie, hors cours » ;
  3·10 et 3·11 dans « Cas particuliers ».
- **Maths, menu principal (14 → 9)** : 10 rejoint 3 ; 12 rejoint 7 ; 11·6 est supprimé (doublon de 8·9) ; 11 rejoint 8 comme sous-menu ;
  Historique et Aide restent en 8 et 9.

Ces regroupements changent des chemins déjà appris. À ne faire qu'une fois, en même temps que les renommages, et après le test du 12.11.

---

## 5. Solveurs manquants révélés par l'échantillon

| Consigne réelle | Source | État | Remarque |
|---|---|---|---|
| En s'aidant du quadrillage, calculer la surface du logo | test maths 2025, P3 c | **manque** | prévu dans `VARIANTES-AB.md` § 3.6 (`aireFigure`), absent de `solveur.lua` |
| Déterminer les minima et maxima de f(x) = x² + x + 2 sur les intervalles… | série 7, ex.6 | **manque** | le commentaire l.1765 annonce « sommet », aucune fonction ne suit |
| Résoudre cette égalité par rapport à t. Esquisser le graphe I(t) | série 3 | à vérifier | l'analyse et le tracé visent les fonctions rationnelles ; courbe exponentielle non vue dans le code |
| Trouver C tel que le triangle ABC soit rectangle en A et d'aire 25 | série 6 | partiel | 11·7 Système de conditions, avec la saisie détournée du défaut D8 de `VARIANTES-AB.md` |
| Journaliser la répartition du bénéfice ; Dresser le bilan publié après répartition du bénéfice | chap. 37 | **manque** | aucun de ces mots dans `37_reserves.lua` ; l'aide-mémoire en parle |
| Établir le Compte de résultat et le bilan internes | chap. 37 | partiel | 2·13 donne le compte de résultat interne ; pas de bilan interne trouvé dans le code |
| Journaliser et comptabiliser la variation de stocks | chap. 37 | à vérifier | 2·4 et 2·5 calculent la variation ; écriture non vue |
| Calculer, à partir du graphique, le prix de vente unitaire / le chiffre d'affaires au point mort | chap. 44 | **manque** | 3·7 trace le graphique à partir des données ; rien ne fait la lecture inverse |
| Déterminer le nouveau ROI de l'entreprise Beta si elle diminue de moitié son stock | chap. 51 | partiel | relancer 4·9 avec les données modifiées ; pas de mode « avant / après » |
| Compléter les deux Comptes de résultat sachant que le taux d'intérêt sur les dettes est de 6 % | chap. 51 | à vérifier | effet de levier dans 4·9 (« hors test ») |

Les lignes « à vérifier » n'ont pas été testées : le code a seulement été parcouru par mots-clés.

---

## 6. Ordre de réalisation proposé

| Étape | Contenu | Effort |
|---|---|---|
| 1 | Bloc `CHERCHE` dans `socle_debut.lua`, écran et touches dans `socle_fin.lua`, option `--cherche` de `test_pc.py` | 4 h |
| 2 | Index compta : champs `forts`, `mots`, `si` sur les 61 entrées (annexe A comme base, corrections de 4.7), fichier de consignes de test | 3 h |
| 3 | Essai sur la calculatrice : temps de réponse à la frappe, lisibilité des deux lignes par résultat | 1 h |
| 4 | Classeur maths : recopie du bloc ou passage au socle ; index des 37 entrées | 3 à 4 h |
| 5 | Renommages et regroupements (4.9), après le test du 12.11 | 3 h |
| 6 | Fiche « consigne → touches » produite depuis l'index (Python, sortie Markdown ou HTML) | 2 h |
| 7 | Mesure sur des consignes nouvelles (blanc 2, séries suivantes) et correction de l'index | 1 h par série |

Solveurs manquants de la section 5 : hors de cette étude, à chiffrer à part.

---

## Annexe A. Index du prototype (98 entrées)

Format : `IDX(chemin, mots forts, mots partagés)`, le libellé en commentaire. Les lignes « si : … » restent à rédiger.
Les chemins sont ceux des menus au 11.11.2026.

### Compta

```lua
IDX("2·1", "tableau rl latente", "reserve benefice reel fonds propres fp interne creer poste ducroire titre stock installation variation")  -- Tableau des RL → BN, FP réels
IDX("2·2", "reel poste", "resultat benefice net perte publier stock inventaire")  -- Résultat réel (un poste)
IDX("2·3", "ducroire", "creance client provision risque perte reel benefice")  -- Ducroire
IDX("2·4", "fraction tiers", "stock sous evalue 2/3 pramv reel benefice latente")  -- Stock à une fraction (PRAMV)
IDX("2·5", "externe interne", "stock pramv marge brute constituee dissoute latente variation")  -- Stock externe / interne
IDX("2·6", "maxim 960c venale", "stock article marchandise valeur bilan figurer evaluation pra completer")  -- Valeur max. du stock (960c)
IDX("2·7", "titre cote action cours", "maxim valeur bilan figurer portefeuille boursiere")  -- Titres cotés / non cotés
IDX("2·8", "acquisition comptabilisation inscription", "prix maxim cout amortissement taux prudent terrain machine objet premiere evaluer")  -- Coût d'acquisition, amort.
IDX("2·9", "fiscal fisc reprise", "stock benefice admis admissible impot")  -- Reprise fiscale (stock)
IDX("2·10", "fiscal fisc reprise", "poste provision amortissement benefice admis")  -- Reprises fiscales (postes)
IDX("2·11", "annees exercices", "plusieurs reel benefice latente")  -- Plusieurs années
IDX("2·12", "propres", "fonds fp trois ans tableau completer capital")  -- Fonds propres sur 3 ans
IDX("2·13", "dissolution journal ecriture", "journaliser interne externe cr compte resultat latente bilan")  -- Dissolution : écritures, CR
IDX("2·14", "vrai faux theorie", "categorie affirmation latente")  -- Théorie, V/F, catégories
IDX("3·1", "degres prama pramv can", "compte resultat cr dresser marge brute exploitation net achats ventes deductions")  -- CR à 2 degrés, PRAMA, PRAMV, CAN
IDX("3·2", "combien quantite nombre", "seuil point mort pm rentabilite benefice vise vendre vendus unite paquet article")  -- Seuil en quantité, bénéfice visé
IDX("3·3", "chiffre affaires ca", "seuil point mort pm taux marge brute benefice realiser rentabiliser fonds propres valeur formule")  -- Seuil en valeur (taux de marge)
IDX("3·4", "base", "taux marge pramv can mb brute")  -- Base du taux, CAN depuis la MB
IDX("3·5", "budget prevision", "pm point mort resultat nouveau maintenir benefice hausse baisse")  -- Budget : PM, résultat, prévisions
IDX("3·6", "previsionnel date", "compte resultat cr degres point mort annee prochaine budgete")  -- CR prévisionnel, date du PM
IDX("3·7", "graphique graphe droite", "montrer representer point mort chiffre affaires perte benefice tracer")  -- Graphique du seuil
IDX("3·8", "licence minimum pourcentage", "prix commande reduction baisse augmentation volume ventes couvrir nombre vendre benefice point mort importation")  -- Licence : quantité, prix min., baisse
IDX("3·9", "2025", "test licence synthetiseur")  -- Test 2025 ex. 10 (prof + livre)
IDX("3·10", "lot", "changement prix solde nouveau seuil deja vendu")  -- Lot : changement de prix
IDX("3·11", "remplissage occupation passager personne", "transporter compagnie avion capacite taux seuil")  -- Taux de remplissage
IDX("3·12", "contributive", "theorie cout fixe variable citer definition")  -- Marge contributive (théorie)
IDX("3·13", "securite levier", "marge operationnel")  -- Marge de sécurité, levier (hors cours)
IDX("3·14", "multiproduit mix", "plusieurs produits seuil")  -- Seuil multiproduits (hors cours)
IDX("4·1", "complete", "analyse ratio 26 bilan resultat")  -- Analyse complète, 26 ratios
IDX("4·2", "ratio liquidite couverture", "bilan annee degre endettement intensite financement expliquer signifie")  -- Ratios du bilan, 1 année
IDX("4·3", "comparer entreprises", "bilan ratio trois plusieurs liquidite apprecier structure financement")  -- Comparer 1 à 5 bilans
IDX("4·4", "comparer entreprises", "ratio deja commenter apprecier structure")  -- Comparer X entreprises (ratios)
IDX("4·5", "analytique", "bilan etablir structure repartition benefice")  -- Bilan analytique (liste)
IDX("4·6", "ebit ebitda balance", "compte resultat cr degres evidence presenter etablir")  -- CR à degrés (balance)
IDX("4·7", "cles employe", "chiffre m2 annees evolution")  -- Chiffres clés (années)
IDX("4·8", "rotation duree delai", "stock creance client fournisseur credit jour cycle")  -- Rotations et durées
IDX("4·9", "roi roe rentabilite rci rfp", "rendement fonds propres capitaux investis levier decomposer")  -- ROI, ROE (+ levier, hors test)
IDX("4·10", "frn roulement", "fonds net")  -- Fonds de roulement net
IDX("4·11", "ratio", "seul formule liquidite couverture endettement marge rotation")  -- Ratios un par un (26)
IDX("4·12", "vrai faux", "affirmation analyse")  -- Vrai / faux (51.15)
IDX("5·1", "liquidite tresorerie", "tableau etablir caisse poste banque variation")  -- Tableau des liquidités
IDX("5·2", "cash flow indirect", "direct methode calcul presenter")  -- Cash flow direct / indirect
IDX("5·3", "flux tft", "tableau tresorerie secteur exploitation investissement financement direct complet")  -- Tableau des flux complet
IDX("5·4", "effet operation", "indiquer resultat liquidite rn liq")  -- Effets des opérations
IDX("5·5", "facteur free", "cash flow ratio endettement effectif investissement net qualite evaluer marge")  -- Ratios de cash flow, free cash flow
IDX("5·6", "bfr", "besoin fonds roulement cycle")  -- BFR, cycle de trésorerie (hors cours)
IDX("5·7", "encaissement decaissement", "budget tresorerie mois")  -- Budget de trésorerie (hors cours)
IDX("6·1", "cmp", "compte stock entree sortie etablir presenter cout moyen pondere")  -- Compte de stock au CMP
IDX("6·2", "repartition indirecte", "charge tableau section auxiliaire principale unite oeuvre etablir primaire secondaire")  -- Répartition des charges indirectes
IDX("6·3", "cascade approvisionnement transformation", "cout complet prix revient production matiere premiere resultat mois distribue")  -- Coûts complets en cascade
IDX("6·4", "commande devis", "prix revient remise mod")  -- Prix de revient d'une commande
IDX("6·5", "incorporable incorporee", "charge cae periode")  -- Charges incorporables
IDX("6·6", "generale cg concordance", "resultat analytique correction")  -- Résultat analytique → CG
IDX("6·7", "departement", "resultat produit frais generaux")  -- Résultat par département
IDX("6·8", "oeuvre uo", "cout unite heure classe profil")  -- Coût de l'unité d'œuvre
IDX("7·1", "interet escompte", "capital taux jours")  -- Intérêts, escompte
IDX("7·2", "emprunt annuite remboursement", "plan")  -- Emprunt, plan de remboursement
IDX("7·3", "van tri actualisation", "investissement recuperation")  -- VAN, TRI, délai de récupération
IDX("7·4", "lineaire degressif", "amortissement valeur residuelle")  -- Amortissements linéaire, dégressif
IDX("7·5", "tva ht ttc", "decompte impot prealable")  -- TVA : HT/TTC, décompte
IDX("7·6", "marque coefficient majoration", "marge prix achat vente")  -- Marge, marque, coefficients
```

### Maths

```lua
IDX("1", "resoudre equation inequation", "parametre exponentielle valeur absolue solution")  -- Résoudre (automatique)
IDX("2", "probleme", "points projection volume base complet vecteur espace")  -- Problème A complet
IDX("3", "exprimer chasles simplement", "figure fonction somme parallelogramme vecteur uniquement")  -- Problème B complet (figure, Chasles)
IDX("4", "asymptote pole zero analyse", "domaine signe tableau fonction rationnelle reciproque image variation graphe multiplicite")  -- Analyse de fonction (S7 ex.7-8)
IDX("5", "identifier reels tels", "nombres forme")  -- Identifier des réels a, b, c
IDX("6", "factoriser", "polynome racine evidente detail produit facteur")  -- Factoriser un polynôme (détail)
IDX("7·1", "equation delta", "resoudre parametre discriminant")  -- Résoudre une équation (Δ, paramètre…)
IDX("7·2", "inequation absolue", "resoudre signe tableau")  -- Inéquation, valeur absolue
IDX("7·3", "changement variable", "poser bicarree exponentielle")  -- Changement de variable
IDX("7·4", "division quotient reste potence", "polynome")  -- Division en potence A ÷ B
IDX("7·5", "simplifier", "fraction expression")  -- Simplifier une fraction / expression
IDX("7·6", "signe decomposer", "factoriser produit facteur polynome etudier")  -- Factoriser et étudier le signe
IDX("8·1", "norme unitaire", "vecteur longueur direction")  -- Norme, vecteur unitaire
IDX("8·2", "scalaire angle", "vecteur forme")  -- Produit scalaire, angle
IDX("8·3", "projection", "orthogonale point droite coordonnee")  -- Projection d'un point sur une droite
IDX("8·4", "projection", "vecteur axe valeur")  -- Projection d'un vecteur v sur u
IDX("8·5", "vectoriel aire surface", "triangle parallelogramme")  -- Produit vectoriel, aire
IDX("8·6", "mixte volume coplanaire", "parallelepipede points")  -- Produit mixte, volume, coplanarité
IDX("8·7", "perpendiculaire orthogonal", "parametre point tel")  -- Paramètre : u ⊥ v
IDX("8·8", "colineaire", "parametre parallele")  -- Paramètre : u, v colinéaires
IDX("8·9", "composante base", "vecteur coordonnee")  -- Composantes dans une base
IDX("8·10", "orthonormee", "base directe verifier")  -- Base orthonormée directe ?
IDX("8·11", "construire bon", "base orthonormee directe")  -- Construire une BON directe
IDX("9·1", "domaine definition", "racine fraction ensemble")  -- Domaine (racines, fractions)
IDX("9·2", "bijection reciproque", "intervalle inverse ensemble expression")  -- Bijection sur I, f⁻¹ et courbes
IDX("9·3", "parite paire impaire", "fonction")  -- Parité
IDX("9·4", "composition composee rond", "fonctions ensemble definition")  -- Composition f∘g et g∘f
IDX("10", "chasles", "exprimer simplement figure somme combinaison")  -- Figure : Chasles, combinaisons
IDX("11·1", "bilinearite sachant", "angle norme orthogonaux")  -- Angle par bilinéarité
IDX("11·2", "milieu gravite symetrique", "parallelogramme point rapport")  -- Points : milieu, gravité, symétrique…
IDX("11·3", "aligne colineaire", "lambda points parallele montrer")  -- Colinéarité / alignement par λ
IDX("11·4", "unitaire", "orthogonal deux perpendiculaire")  -- Vecteur unitaire ⊥ à deux vecteurs
IDX("11·5", "norme donnee", "vecteur")  -- Vecteur de norme donnée
IDX("11·6", "composante base", "vecteur coordonnee")  -- Composantes dans une base (2D/3D)
IDX("11·7", "systeme condition", "vecteur inconnues")  -- Système de conditions
IDX("12·1", "factoriser", "lettres expression plusieurs factorisee")  -- Factoriser une expression (lettres)
IDX("12·2", "isoler", "lettre resoudre formule exprimer")  -- Isoler une lettre
```
