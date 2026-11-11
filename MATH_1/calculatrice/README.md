# Programmes TI-Nspire CX II (Python) — MATH_1

Classeur `maths1.tns` envoyé sur la calculatrice le 10.11.2026 (racine de l'unité). Ouvrir `maths1`, puis **ctrl+R** pour lancer le menu.

Rôle : **contrôle de copie**. Au test, chaque étape reste à écrire à la main (règle d'or du prof, `MATH_1/CLAUDE.md`).
Tous les calculs sont exacts (fractions, racines `√6/2`), avec une valeur approchée à côté.

| Menu | Script | Contenu |
|---|---|---|
| 1 | `fonction.py` | Analyse d'une fonction rationnelle (S7 ex.7-8) : domaine, simplification, parité, zéros/pôles et ordre, tableau de signes, forme a+b/… par division, asymptotes V/H/O et position, réciproque et image I_f, variations (contrôle par f'), bijection I→J, points du graphe |
| 2 | `vecteurs.py` | Norme et unitaire, produit scalaire et angle (valeurs remarquables), projection orthogonale, produit vectoriel et aires, produit mixte et volumes, BON directe, colinéarité |
| 3 | `degre2.py` | Trinôme (Δ, racines, sommet, forme canonique), factorisation (racine évidente), division en potence, inéquation par tableau de signes, \|x−a\| op r, équation rationnelle avec rejets |
| 4 | `parametre.py` | Équation a(m)x²+b(m)x+c(m)=0 (cas a(m)=0, Δ(m), tableau de signes en m, solutions), changement de variable (x², √x, x^(1/3), 1/x, homographique) |

## Saisie
- `2x^2-3`, `2xx-3` (multiplication implicite), `(x-1)(x+2)^2`, `(x^2+1)/(2x^2-3)`, `x²` ; `3/2x` se lit (3/2)·x.
- Vecteurs : `2,-1,3` (2 ou 3 composantes, fractions admises).

## Reconstruire et renvoyer
1. Modifier les `.py` (sources lisibles ; pas de f-string, et jamais `float()` sur les nombres exacts : utiliser `fl()`, le Python TI n'appelle pas `__float__`).
2. `python MATH_1/calculatrice/construire.py` : remplace les symboles absents de la police TI (⟺, ∪, ✓…), vérifie la compilation, écrit `maths1.tns` (`construire_tns.py` = portage Python de Luna 2.1, MPL 1.1 ; dépend de `cryptography`).
3. Ouvrir `maths1.tns` dans *TI-Nspire CX CAS Student Software*, puis **Fichier → Enregistrer sur l'unité…** (calculatrice branchée en USB).

Testé le 10.11.2026 : tests scriptés sur PC (S7 ex.7-8, vecteurs, inéquations, paramètre) et exécution dans le Python du logiciel TI (trinôme, analyse S7 ex.8, angle).
