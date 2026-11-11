# Étude — transformer la TI-Nspire CX II-T CAS en « solutionneur complet » (test MATH_1 du 16.11.2026)

Étude du 10.11.2026 (recherche et analyse, aucune implémentation). Machine : TI-Nspire CX II-T CAS, OS 6.3 ; PC Windows avec *TI-Nspire CX CAS Student Software* 6.3.0.119.
Convention : **[V]** = vérifié (source citée ou essai local) ; **[S]** = supposé (raisonnable, à tester avant de s'y fier) ; **[C]** = connaissance courante de la plateforme, non revérifiée ce jour.

---

## 1. Synthèse en 10 lignes

1. Trois plateformes sont utilisables sans jailbreak : **Python** (l'existant), **TI-Basic CAS** et **Lua**. Les deux dernières ont un accès natif au calcul formel ; Lua a en plus une vraie interface graphique.
2. **Le shell n'est obligatoire qu'en Python.** Un script Lua s'exécute dans sa page dès l'ouverture du classeur : ni éditeur, ni console, ni ctrl+R [V].
3. **Lua appelle le CAS** : `math.evalStr("factor(x^3+x^2-8x-12)")` renvoie le résultat formel sous forme de chaîne (API niveau 2.0, donc tout OS ≥ 3.2) [V doc TI].
4. **Lua sait faire de « jolis menus »** : polices serif/sans-serif, gras/italique, tailles 7 à 24, couleurs RVB, événements clavier/pavé tactile, menu natif de la touche `menu` (`toolpalette`), boîtes mathématiques 2D (`D2Editor`) [V doc TI] ; le rendu 2D d'un résultat calculé reste à confirmer sur machine [S].
5. **Surprise côté Python** : contrairement au constat « Python ≠ CAS », `ti_system` contient deux fonctions non documentées, `writeST`/`readST`, qui évaluent une expression TI-Basic quelconque et renvoient le résultat **formel** en chaîne (bibliothèque `eval_expr` de TI-Planet) ; ces deux symboles sont bien présents dans le `ti_system.mpy` 6.3.0.119 installé sur le PC [V essai local], leur comportement sur OS 6.3 reste à tester [S].
6. **TI-Basic** est le plus court chemin vers un affichage 2D natif (`Disp` dans Calculs, boîtes mathématiques dans Notes), mais sans couleur, sans menu, et sans chaîne de fabrication automatique depuis le PC.
7. **Ndless est écarté** : OS 6.3 non pris en charge directement (il faudrait passer en 6.4.0.74), manipulation à risque à six jours du test, et rien de ce qui est demandé n'en a besoin.
8. Le CAS ne donne que des **résultats** ; les **étapes « à la manière du prof »** (division en potence, identification, tableau de signes, rejets) doivent être programmées. L'existant Python le fait déjà pour le problème C et les outils ; c'est un acquis à ne pas jeter.
9. **Recommandation : hybride progressif.** Garder le classeur Python comme filet (gelé, il marche), et construire un classeur **Lua + CAS** comme interface cible (menus, mise en page, pas de shell, étapes exactes), après un essai de faisabilité d'une heure le 10.11 au soir. Si l'essai échoue : Python amélioré (menu plein écran + pont CAS) et une page Notes « tableau de bord ».
10. Gel du code le **samedi 14.11**, dimanche 15 réservé à un examen blanc avec l'outil figé. Le temps de révision passe avant l'outil : la copie reste manuscrite et justifiée (règle d'or du prof).

---

## 2. Capacités par plateforme

### 2.1 Python (MicroPython TI) — l'existant

| Point | Constat | Statut |
|---|---|---|
| Modules TI | `ti_system`, `ti_draw`, `ti_plotlib`, `ti_image`, `ti_hub`, `ti_rover` (fichiers `PyLib/*.tns` du logiciel PC) + `math`, `random`, `time`, `cmath`… | [V] essai local (extraction des `.mpy`) |
| `ti_draw` | `draw_text`, `draw_line`, `draw_rect`, `fill_rect`, `draw_circle`, `fill_circle`, `draw_arc`, `fill_arc`, `draw_poly`, `fill_poly`, `plot_xy`, `clear`, `clear_rect`, `set_color`, `set_pen`, `set_window`, `get_screen_dim`, `use_buffer`, `paint_buffer` (+ `string_size`, utilisé par `ecran.py`). **Aucune fonction de police ni de taille de texte** : une seule police, une seule taille ; le gras se simule (double tracé, déjà fait dans `ecran.py`). Zone 318 × 212. | [V] [menu ti_draw, eGuide TI](https://education.ti.com/html/eguides/nspire/eg_nspire/en/content/eg_python/m_menumap/mm_tidraw.HTML) |
| `ti_draw` hors calculatrice | « disponible sur la calculatrice et dans la vue calculatrice du logiciel » : pas en vue ordinateur | [V] même page (confirme le constat de l'existant) |
| `ti_system` documenté | `recall_value`, `store_value`, `recall_list`, `store_list`, `eval_function(nom, valeur)`, `get_platform`, `get_key([1])`, `get_mouse`, `clear_history`, `get_time_ms` | [V] [menu ti_system, eGuide TI](https://education.ti.com/html/eguides/nspire/eg_nspire/en/content/eg_python/m_menumap/mm_tisystem.HTML) |
| `ti_system` non documenté | symboles présents dans `ti_system.mpy` 6.3.0.119 : `writeST`, `readST`, `writeSTLst`, `readSTLst`, `disp_clr`, `escape`, `clock`, `wait` | [V] essai local |
| **Accès au CAS** | `eval_function` : fonction OS à **un** argument numérique, résultat numérique. **Contournement** : `writeST("tmp", 'string(factor(x^2-1))')` puis `readST("tmp")` renvoie la chaîne du résultat formel (ex. `eval_expr("sqrt(90)")` → `'3*sqrt(10)'`). 40 lignes, domaine public. | [V] source lue : [TI-Planet/eval_expr](https://github.com/TI-Planet/eval_expr) ; [S] fonctionnement sur OS 6.3 (un essai de 5 min tranche) |
| Persistance | variables et listes numériques du classeur (`store_value`/`store_list`, déjà utilisé pour la mémoire des saisies) ; pas d'accès fichier | [V] doc + existant |
| Exécution | toujours dans un **Shell** (page ajoutée par « Exécuter ») ; ctrl+R dans le Shell relance le dernier programme | [V] [Shell](https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Python/Content/m_workspaces/ws_shell.HTML), [menu Outils](https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Python/Content/m_menumap/mm_tools.HTML) |
| Mémoire, vitesse, limites | aucune limite chiffrée dans les sources consultées ; en pratique le classeur actuel (10 modules, 3 300 lignes, fractions exactes) tourne. Pas de `__float__`, pas de f-string selon l'existant. | [S] / existant |
| Fabrication depuis le PC | `construire.py` + `construire_tns.py` (portage de Luna) : en place | [V] existant |

**Bilan** : moteur d'étapes exact déjà écrit, visionneuse couleur déjà écrite. Limites structurelles : une seule police, shell au lancement et à chaque `input()`, pas de test possible en vue ordinateur dès qu'on dessine.

### 2.2 TI-Basic CAS (Func / Prgm, bibliothèques)

| Point | Constat | Statut |
|---|---|---|
| Calcul formel | accès direct et complet : `factor`, `expand`, `solve`, `zeros`, `propFrac`, `comDenom`, `polyQuotient`, `polyRemainder`, `polyCoeffs`, `limit`, `domain(expr,var)`, `dotP`, `crossP`, `unitV`, `norm`… | [V] `.claude/skills/cas/reference/tinspire-cas.md` ; `domain` : [base de connaissances TI 33591](https://education.ti.com/en/customer-support/knowledge-base/ti-nspire-family/product-usage/33591) |
| Affichage pas à pas | `Disp "texte", expr` écrit dans l'historique de Calculs ; les expressions y sont affichées en **2D natif** (fractions, puissances, racines) et l'historique **se remonte** avec les flèches. Pas de couleur, pas de gras, pas de menu. | [C] à confirmer en 1 min sur la machine |
| Saisie | appel `etude((x^2+1)/(2x^2-3))` avec l'éditeur mathématique natif (modèle de fraction) ; ou `Request`/`RequestStr` (boîtes de dialogue) | [C] |
| Graphisme CX II | `DrawText`, `SetColor`, `FillRect`, `UseBuffer`, `PaintBuffer`, `Clear`… : mode graphique 318 × 212, **police fixe**, uniquement depuis Calculs, pas en vue ordinateur ; `Request`/`Text` interdits dans ce mode ; **toute touche met fin au mode graphique** | [V] [commandes graphiques CX II, guide TI](https://education.ti.com/html/webhelp/eg_tinspire/en/Subsystems/EG_RefGuide/Content/M_RefGuide/RG_DrawCommand.HTML) |
| Bibliothèque | objet défini par `Define LibPub nom(...)=Prgm…`, dans le **premier problème** d'un classeur placé dans `MyLib`, puis `doc > Rafraîchir les bibliothèques` ; appel `classeur\nom(...)` ou via le catalogue (onglet bibliothèques) depuis n'importe quel classeur | [V] [Using Library Objects, eGuide TI](https://education.ti.com/html/webhelp/EG_TINspire/EN/content/m_libraries/lb_using_library_objects.HTML) |
| Notes interactives | une page Notes avec des boîtes mathématiques : on définit `f(x):=…` dans la première, les suivantes (`factor(f(x))`, `domain(f(x),x)`, `propFrac(f(x))`, `zeros(…)`, `limit(…)`, `solve(y=f(x),x)`) se **recalculent toutes seules**, en 2D natif. Zéro code. | [C] fonction standard de Notes, non revérifiée ce jour |
| Fabrication depuis le PC | pas d'outil équivalent à Luna pour un programme TI-Basic. Luna convertit bien un `Problem1.xml` quelconque, mais le XML d'un éditeur de programmes / d'une page Notes n'est pas documenté ; les `.tns` de TI (`MyLib/numtheory.tns`…) ne se déchiffrent pas avec la clé fixe de Luna (essai local : échec). Voie pratique : **coller le texte dans l'éditeur de programmes du logiciel PC**, puis « Enregistrer sur l'unité ». Autre voie : un script Lua exécute `math.eval("Define …")` et installe les fonctions dans le classeur. | [V] [README Luna](https://github.com/ndless-nspire/Luna) pour la conversion XML ; [V] essai local pour l'échec de déchiffrement ; [S] pour le collage et le `Define` depuis Lua |

**Bilan** : imbattable pour un contrôle rapide en 2D natif (surtout la page Notes), mais présentation austère, pas d'interface, et fabrication manuelle. Bon complément, mauvais socle pour « jolis menus ».

### 2.3 Lua (API TI-Nspire, OS ≥ 3.0)

| Point | Constat | Statut |
|---|---|---|
| Exécution sur CX II | « les documents contenant des scripts s'ouvrent sur les CX II ; le script s'y exécute, on ne peut ni le voir ni le modifier » ; il tourne tant que sa page est active. **Pas de shell, pas de touche à presser.** | [V] [Writing Lua Scripts, eGuide TI](https://education.ti.com/html/webhelp/eg_tinspire/en/Subsystems/EG_Lua/Content/m_scripteditor/m_scripteditor.HTML) |
| Accès au CAS | `math.evalStr(expr)` envoie l'expression au moteur mathématique et renvoie le **résultat en chaîne** ; `nil` + numéro d'erreur en cas d'erreur ; réglages par `math.setEvalSettings` (mode exact, angle). `math.eval` renvoie un type Lua (nombre, liste) et échoue sur un résultat formel (« incompatible data type »). Pièges documentés : le signe moins renvoyé est U+2212, le « E » scientifique est U+F000. | [V] [evalStr](https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/mathlibexten/evalstr.htm), [eval](https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/mathlibexten/eval.htm), [wiki Inspired-Lua](https://wiki.inspired-lua.org/math.evalStr) |
| Texte et graphisme | `gc:setFont(famille, style, taille)` : `"sansserif"`/`"serif"`, `"r"`/`"b"`/`"i"`/`"bi"`, tailles **7, 9, 10, 11, 12, 24** sur calculatrice ; `gc:drawString`, `getStringWidth/Height`, `setColorRGB`, `fillRect`, `drawLine`, `clipRect`, images | [V] [gc:setFont, doc TI](https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/graphicslib/setfont.htm) |
| Événements | `on.paint`, `on.arrowKey` (+Up/Down/Left/Right), `on.enterKey`, `on.escapeKey`, `on.tabKey`, `on.backspaceKey`, `on.charIn`, `on.mouseDown/Move/Up` (pavé tactile), `on.timer`, `on.resize`, `on.activate`, `on.varChange`… | [V] [Events, wiki Inspired-Lua](https://wiki.inspired-lua.org/Events) |
| Menu natif | `toolpalette.register{…}` : menu de la touche `menu`, à sous-menus, modifiable en cours d'exécution (API 2.0) | [V] [toolpalette.register, doc TI](https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/toolpalettelib/register.htm) |
| Maths 2D | `D2Editor:newRichText()` : éditeur riche avec boîtes mathématiques, balisage `"\0el {…}"` ; `setExpression`, `getExpression`, `setReadOnly`, `setFontSize`, `setTextColor`, `setWordWrapWidth`, `move`, `resize`. Utilisable en **saisie** (l'utilisateur tape f(x) avec le modèle de fraction) et en **affichage**. Un fil Omnimaga montre `setExpression('\\0el {'..résultat..'}')` pour afficher un résultat calculé. | [V] [bibliothèque 2D Editor, doc TI](https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/2deditorlib/2deditorlibrary.htm) ; [S] qualité du rendu d'une chaîne issue de `evalStr`, défilement d'un long texte ([fil Omnimaga](https://omnimaga.org/lua-language/creatingformating-an-evaluated-math-box-from-lua-script)) |
| Persistance | `on.save` renvoie une table rangée dans le classeur, `on.restore` la relit (historique des saisies, dernière fonction) ; `var.store/recall` pour échanger avec le reste du classeur | [V] [on.save](https://wiki.inspired-lua.org/on.save), [on.restore](https://wiki.inspired-lua.org/on.restore) |
| Test sur PC | « Lua est pleinement pris en charge dans les documents TI-Nspire et PublishView » : un script graphique tourne dans le logiciel PC, **vue ordinateur comprise** (contrairement à `ti_draw`) | [V] page « Writing Lua Scripts » ; [S] pour le détail du CAS dans le logiciel installé |
| Fabrication depuis le PC | **Luna** : `luna script.lua sortie.tns` (Lua : OS ≥ 3.0.2 ; version 2.1 de 2022). `construire_tns.py` ne porte aujourd'hui que la partie Python ; la partie Lua est un en-tête fixe + `<![CDATA[script]]>` + pied (lus dans `luna.c`, l. 289-306) : une trentaine de lignes à ajouter. Alternative sans outil : *Insertion > Éditeur de script* dans le logiciel PC, coller, « Définir le script ». | [V] [README et source de Luna](https://github.com/ndless-nspire/Luna) ; [S] présence de l'éditeur de script dans l'édition *Student* installée |
| Luna sur OS 6.3 | le classeur Python actuel, fabriqué par le même format Luna, s'ouvre sur la machine en 6.3 ; aucune source ne teste explicitement un `.tns` Lua de Luna sur 6.x | [V] existant pour Python ; [S] pour Lua |

**Bilan** : seule plateforme qui réunit CAS + interface + absence de shell + test sur PC. Coût : le moteur d'étapes est à réécrire en Lua (mais plus court qu'en Python, le CAS servant de noyau d'algèbre).

### 2.4 Combinaisons

| Combinaison | Intérêt | Statut |
|---|---|---|
| Python → CAS par `writeST`/`readST` | ajoute au classeur existant un contrôle croisé (« CAS : factor = … ») et les types hors moteur (racines, exp/ln, limites) sans rien réécrire | [S] à tester sur 6.3 |
| Lua → CAS par `math.evalStr` | voie officielle, documentée | [V] |
| Lua → TI-Basic (`math.eval("Define …")`) | installer des fonctions utilisables aussi dans Calculs/Notes | [S] |
| Notes + boîtes mathématiques | tableau de bord sans code, 2D natif | [C] |
| Lua et Python dans le même `.tns` | Luna accepte plusieurs problèmes ; non testé avec un mélange Lua + Python. Deux classeurs séparés au départ. | [S] |
| Widgets (`MyWidgets`) | une page de classeur réutilisable par insertion ; n'apporte rien ici | [C] |

### 2.5 Ndless — écarté

Ndless r2023 prend en charge les CX II en 6.2.0.333 et 6.4.0.74 ; en **6.3** l'installation directe est impossible, il faut d'abord passer en 6.4.0.74 [V] ([versions de Ndless](https://github.com/ndless-nspire/Ndless/releases)). Écarté : changement d'OS et jailbreak à six jours du test, risque de machine inutilisable ou réinitialisée, et aucun besoin fonctionnel (Lua donne déjà CAS + graphisme). KhiCAS (Xcas, avec mode pas à pas) dépend de Ndless : écarté pour la même raison.

---

## 3. Shell, menus, mise en page

### 3.1 « Le shell est-il obligatoire ? »

| Plateforme | Réponse | Ergonomie réelle |
|---|---|---|
| **Lua** | **Non.** La page du script est l'application. On ouvre le classeur, on est dans le menu. | Flèches + `enter` dans des menus dessinés ; touche `menu` pour le menu natif ; `esc` = retour ; saisie de f(x) dans une boîte mathématique 2D (ou une ligne de texte gérée par `on.charIn`) ; `ctrl+←/→` change de page si le classeur en a plusieurs. |
| **Python** | **Oui au lancement**, puis masquable. Le programme démarre dans le Shell (ctrl+R depuis l'éditeur, ou ctrl+R dans le Shell pour relancer). Il peut aussitôt prendre tout l'écran avec `ti_draw` et piloter menus et défilement par `get_key` : c'est déjà le cas de la visionneuse. Le shell réapparaît à chaque `input()`. Pour l'éviter, il faut écrire un éditeur de ligne en `get_key` (faisable : `get_key` renvoie les caractères). | Menus chiffrés aujourd'hui ; menu à flèches possible ; impossible de remonter dans la console ; pas de test en vue ordinateur. Ouverture directe d'un classeur sur la page Shell : [S], non documenté. |
| **TI-Basic** | Pas de shell, mais la page **Calculs** joue ce rôle : on tape `etude(…)`, les étapes s'empilent dans l'historique, qu'on remonte aux flèches. | Saisie 2D native excellente ; aucune navigation par menus (sauf boîtes `Request`). |
| **Notes** | Pas de shell, pas de programme : on modifie la boîte `f(x):=…`, tout se met à jour. | Le plus simple à l'usage ; aucune explication, seulement des résultats. |

### 3.2 Menus et mise en page — ce qui est faisable

| Besoin | Python `ti_draw` | TI-Basic | Lua |
|---|---|---|---|
| Menu à flèches, surbrillance | oui (à écrire, `get_key`) | non | oui (`on.arrowKey`) + menu natif `toolpalette` |
| Onglets / pages / fil d'Ariane | oui (dessin) | non | oui |
| Défilement | oui (fait) | historique de Calculs | oui (à écrire, ou natif dans `D2Editor` [S]) |
| Couleurs | oui (fait) | mode graphique seulement | oui |
| Gras, italique, tailles | **non** (gras simulé) | non | **oui** (6 tailles, serif/sans) |
| Fractions et puissances en 2D | à dessiner soi-même (`string_size` + trait) | **natif** (`Disp`, Notes) | natif par `D2Editor` [S], ou à dessiner (`getStringWidth`) |
| Symboles ⟺ ∪ ✓ ℝ | absents de la police (constat existant) | palette de symboles de l'OS | à vérifier pour `gc` ; les boîtes mathématiques ont la palette de l'OS [S] |
| Graphe de f | `ti_plotlib` (fait) | page Graphiques | tracé à la main (`gc:drawLine`) ou page Graphiques liée par `var.store` |
| Zoom | non | non | changement de taille de police |
| Test sur PC | non (dès qu'on dessine) | oui | **oui** |

Deux façons d'obtenir le 2D en Lua, à départager à l'essai :
- **`D2Editor` en lecture seule** : une étape = texte + `\0el {…}` ; rendu identique à Notes ; inconnues : défilement, vitesse, comportement du focus.
- **Rendu maison avec `gc`** : petite routine récursive (fraction = numérateur / trait / dénominateur, exposant en taille 7-9, racine) d'environ 150 lignes ; comportement entièrement maîtrisé, couleurs par élément. La même routine est transposable à `ti_draw` côté Python (sans les tailles).

### 3.3 Solveurs pas à pas existants dont s'inspirer

| Nom | Plateforme | Ce qu'il fait | Source | Statut |
|---|---|---|---|---|
| **SD2** (Xavier Andréani) | Lua, OS ≥ 3.2 | dérivation pas à pas en affichage naturel (2D) ; sans code source | [ticalc.org, fiche 45719](https://www.ticalc.org/archives/files/fileinfo/457/45719.html) | [V] existence et description |
| **TabVar v3** | Lua + CAS | étude de fonction, tableau de variations dessiné | [fil Omnimaga](https://www.omnimaga.org/lua-language/tabvar-v3-the-ultimate-function-analysis-program-!) (renvoie à l'archive TI-Planet 3751) | [V] existence ; page non lue (accès refusé) |
| **eval_expr** (Adriweb, TI-Planet) | Python | pont Python → CAS | [GitHub](https://github.com/TI-Planet/eval_expr) | [V] source lue |
| **Calculus Made Easy** et la série *Made Easy* | TI-Basic/Lua, payant | menus + étapes pour dérivées, intégrales, équations | [fiche TI](https://education.ti.com/en/activity/detail/differential-equations-made-easy@-trial-edition) | [V] existence ; non essayé |
| **FormulaPro / EEPro** (TI-Planet) | Lua | référence d'interface : menus, listes défilantes, boîte à outils d'écran | — | [C] non revérifié ce jour |
| **KhiCAS** | Ndless | Xcas avec mode pas à pas | — | écarté (Ndless) |

À retenir de ces exemples : tous les solveurs « jolis » de la Nspire sont en **Lua**, et ceux qui calculent s'appuient sur `math.eval`/`evalStr`. Aucun ne rédige à la manière d'un corrigé HEIG-VD : la valeur ajoutée du projet est la rédaction (formule énoncée, équivalences, rejets, « Donc… »), déjà capitalisée dans les scripts Python.

---

## 4. Catalogue des exercices du test → rédaction → plateforme

Sources : `examens/2026/PERIMETRE.md`, `examens/2026/BAREME.md`, `exercices/serie-07/corrige-exo07.md` (p.1-3), `corrige-exo05.md`, `corrige-exo08.md`. « Py » = déjà dans le classeur Python.

### 4.1 Problème C — analyse de fonction (S7 ex.7, un peu de l'ex.8)

| Question | Rédaction du prof à reproduire | Noyau CAS (Lua / TI-Basic) | Py | Plateforme conseillée |
|---|---|---|---|---|
| a) Domaine | « f existe ⟺ D(x) ≠ 0 », Δ ou factorisation, D_f encadré (corrigé ex.7 p.1) | `getDenom`, `zeros`, `domain(f,x)` en contrôle | oui (`e_domaine`) | Lua ; Notes en contrôle |
| b) Forme a + b/(…) | égalité posée, développement, « par identification des coefficients », système, a et b soulignés (p.1) | `expand(a·D+b)`, `polyCoeffs`, `solve({…},{a,b})` ; contrôle `propFrac(f)` | oui (`ident.py`, `e_forme`) | Lua (2D indispensable ici) |
| c) Asymptote | f = partie entière + reste « ≃ 0 pour x → ±∞ », phrase de conclusion (p.1) ; AV = pôle vérifié | `propFrac`, `limit(f,x,∞)`, `limit(f,x,p,±1)` | oui (`e_asymptotes`) | Lua |
| d) x en fonction de y | y = f(x), isolement ligne à ligne en ⟺, « ± » (p.1) | `solve(y=f(x),x)` donne le résultat ; les lignes intermédiaires se programment (forme b) → inversion → racine) | oui (`e_reciproque`) | Lua pour l'affichage ; logique reprise de Py |
| e) Image I_f = D_{f⁻¹} | condition « ≥ 0 et dénominateur ≠ 0 », **tableau de signes en y**, réunion d'intervalles (p.2) | `zeros` de chaque facteur, signe par valeur test, `solve(…≥0,y)` en contrôle | oui | Lua (tableau dessiné : traits, double barre) |
| f) Graphe | 3 étapes : asymptotes, quelques points, lissage (p.2) | valeurs `f(x)|x=k` exactes | oui (`graphe.py`, `e_points`) | Py (`ti_plotlib`) ou page Graphiques ; Lua : tracé simple |
| g) Bijection I → J | intervalles lus sur le graphe, 4 choix (p.2) | variations par `solve(d(f,x)>0,x)` en contrôle (le prof ne dérive pas) | oui (`e_bijection`) | Lua, logique reprise de Py |
| h) Courbe de f⁻¹ | un choix de g), asymptotes échangées, symétrie y = x (p.3) | — | partiel | Lua (texte + croquis) |
| ex.8 : factorisation degré 3 | racine évidente « car P(k)=0 », Q=(x−k)(ax²+bx+c) par identification ou division en potence, Δ | `polyQuotient`, `polyRemainder`, `factor` en contrôle | oui (`facto.py`) | Lua ou Py (la division en potence est déjà rédigée en Py) |
| ex.8 : zéros, pôles, ordres, AV/AH | lus sur la forme simplifiée, ordre = exposant ; valeur exclue du facteur simplifié à écrire | `factor(getNum)`, `factor(getDenom)`, `comDenom` | oui (`e_zeros`) | Lua |
| ex.5 : a, b, c de ax+b+c/(x²+1) | identification, puis AO | comme b) | oui (`ident.py`) | Lua |

### 4.2 Problèmes A et B — vecteurs

| Type (référence) | Rédaction attendue (barème 2025) | Noyau CAS | Py | Plateforme |
|---|---|---|---|---|
| Projection orthogonale, projeté d'un point (S5 ex.5, T25 P2 a) | schéma 1 pt, **formule énoncée** 1 pt, composantes, calcul, retour au point | `dotP`, `norm` | oui | Lua (formule en 2D, croquis) |
| Orthogonalité avec paramètre (S5 ex.2, T25 P2 b-i) | condition u·v = 0, équation développée, solution | `dotP`, `solve` | partiel | Lua + CAS (paramètre libre : le CAS apporte la généralité) |
| Angle (poly p.19) | deux calculs du même produit scalaire, cos θ, θ en rad et en ° | `dotP`, `norm`, `arccos` | oui | Lua |
| Angle par bilinéarité (S5 ex.4) | développement littéral de (2a−b)·(a+b)=0 avec normes données | `expand` sur symboles a·a, a·b | non | **Lua + CAS** (calcul littéral) |
| Produit vectoriel, aire (S6 ex.5) | méthode « recopier deux lignes et croiser », aire = ‖u×v‖/2, unité | `crossP`, `norm` | oui | Lua (dessin du croisement) |
| Produit mixte, volume, coplanarité avec paramètre (S6 ex.6, T25 P2 b-ii) | formule, produit vectoriel d'abord, **interprétation** | `dotP(a,crossP(b,c))`, `solve` | oui (sans paramètre) | Lua + CAS |
| Composantes dans une base (S4 ex.8, T25 P2 b-iii) | mise en équation, substitution (méthode du prof), résultat dans la base | `solve({…},{α,β,γ})` ; substitution rédigée à la main | non | **Lua + CAS** |
| BON directe (S6 ex.4, T25 P2 c) | u unitaire, v = λa+μb avec ‖v‖=1 et u·v=0, w = u×v | `unitV`, `solve`, `crossP` | oui (variante projection) | Lua + CAS pour suivre la méthode λ, μ du prof |
| Base orthonormée ? (T25 P2 b-iv) | contre-exemple : un produit scalaire ≠ 0, une norme ≠ 1 | `dotP`, `norm` | partiel | Lua |
| Chasles dans une figure, combinaisons de u, v (S4 ex.2-3, T25 P3) | simplifier une somme de vecteurs nommés par des points | réécriture de bipoints (pas de CAS : règle AB+BC=AC, −AB=BA) ; combinaisons : `solve` sur coordonnées lues | non | Lua (saisie « AB+CD−EB », règles appliquées une à une) ; utilité limitée : la figure n'est pas dans la machine |

### 4.3 Outils des séries 1-3 (plus de question isolée, mais présents dans les problèmes)

| Type | Rédaction attendue | Noyau CAS | Py | Plateforme |
|---|---|---|---|---|
| Inéquation, tableau de signes, valeur absolue (S2 ex.5, T25 P1 c) | tout ramener à « … ≥ 0 », factoriser, tableau une ligne par facteur, cas de la valeur absolue, réunion | `factor`, `zeros`, `solve(…≥0,x)` | oui (`degre2.py`) | Lua (tableau dessiné) |
| Équation à paramètre (S2 ex.1-2, T25 P1 a) | cas a(m)=0 isolé, Δ(m), signe de Δ, solutions par cas | `solve`, `zeros(a(m),m)`, signe de Δ(m) | oui (`parametre.py`) | Lua + CAS |
| Changement de variable (S2 ex.3, S3 ex.5) | poser u=…, résoudre en u, retour à x, **rejets justifiés** | `solve` en u puis en x, test du domaine | oui (5 formes) | Lua + CAS (formes exp/ln, racines : le CAS lève la limite du moteur Python) |
| Trinôme, Δ, forme canonique, extremum sur intervalle (S7 ex.6) | Δ, racines, sommet −b/2a, valeurs aux bornes | `zeros`, `completeSquare` | oui | Lua ou Py |
| Domaine avec racines, composition, parité (S7 ex.1, 3, 4) | conditions numérotées réunies, droite réelle ; f(−x) comparé à ±f(x) | `domain`, `solve(…≥0,x)`, `f(-x)-f(x)` | parité oui ; racines non | **Lua + CAS** |

**Lecture d'ensemble** : le moteur Python couvre déjà le problème C et les outils rationnels ; le CAS est nécessaire pour ce que ce moteur ne sait pas (racines, exp/ln, paramètres dans les vecteurs, calcul littéral). L'affichage 2D compte surtout pour l'identification, la réciproque et les tableaux de signes.

---

## 5. Architecture recommandée

### 5.1 Comparaison des trois options

| Critère | A. Python seul amélioré | B. Lua + CAS (réécriture) | C. Hybride progressif (**recommandé**) |
|---|---|---|---|
| Shell | visible au lancement, masquable ensuite | absent | absent côté Lua ; Python inchangé en secours |
| Menus, mise en page | menus à flèches, couleurs, une police | menus, 6 tailles, gras, 2D | ceux de B |
| Étapes exactes | moteur maison (rationnel uniquement) + pont CAS [S] | CAS natif + rédaction à écrire | CAS natif ; rédaction portée module par module depuis Python |
| Couverture des types | celle d'aujourd'hui | tous, si le temps suffit | celle d'aujourd'hui garantie + ce qui est porté |
| Test sur PC | non (dès qu'on dessine) | oui | oui pour la partie Lua |
| Risque à J-6 | faible | élevé si on jette Python | faible : rien n'est retiré tant que le remplaçant n'est pas validé |
| Effort | 0,5 à 1 jour | 3 à 4 jours | 2 à 3 jours, interruptible à chaque étape |

### 5.2 Architecture cible (option C)

```
maths1.tns   (Python, existant, GELÉ après deux retouches)      -> filet de sécurité
m1solveur.tns (Lua, nouveau)                                    -> interface principale
  ui.lua        écran, pile d'écrans, menu à flèches, visionneuse défilante, styles (titre/résultat/alerte/explication)
  rendu.lua     rendu 2D : fractions, puissances, racines, tableau de signes (gc), ou D2Editor selon l'essai
  cas.lua       cas(expr) = math.evalStr + nettoyage (U+2212, U+F000), mode exact, gestion de nil
  saisie.lua    saisie de f(x) (boîte D2Editor ou ligne on.charIn), mémoire des saisies (on.save / on.restore)
  ex_*.lua      un module par type : analyse (S7 ex.7), ident (ex.5), facto (ex.8), signes, parametre, chgtvar, vecteurs
page Notes « tableau de bord » (dans m1solveur.tns, page 2)     -> f(x):=… puis factor, domain, propFrac, zeros, limites, solve(y=f(x),x)
```

Principes :
- **Le CAS sert de noyau d'algèbre, la rédaction reste la nôtre.** Chaque module Lua reprend la trame du module Python correspondant (titres, « Pourquoi », équivalences, « Donc ») et remplace les calculs maison par des appels `cas(…)` ; les styles de `ecran.py` (titre, résultat, alerte, explication) sont repris tels quels.
- **Un seul fichier source par module, concaténés à la construction** : un script Lua de classeur est d'un seul tenant ; `construire.py` assemble les `.lua` puis appelle la partie Lua de `construire_tns.py` (à ajouter : en-tête, `<![CDATA[…]]>`, pied de `luna.c`).
- **Contrôle croisé gratuit** : chaque étape rédigée affiche, en gris, la ligne « CAS : … » correspondante ; un écart entre rédaction et CAS se voit immédiatement.
- **Python reste sur la machine** jusqu'au test ; il reçoit seulement (a) un menu plein écran à flèches, (b) si l'essai `writeST`/`readST` réussit, une ligne « CAS : … » de contrôle.

### 5.3 Transfert depuis le PC

| Contenu | Fabrication | Envoi |
|---|---|---|
| Python | `tools/py MATH_1/calculatrice/construire.py` (existant) | ouvrir le `.tns` dans le logiciel TI, *Fichier → Enregistrer sur l'unité* |
| Lua | même script, après ajout de la partie Lua (ou `luna.exe m1solveur.lua m1solveur.tns` ; ou collage dans *Insertion → Éditeur de script*) | idem ; le classeur peut d'abord être essayé dans le logiciel PC |
| TI-Basic | collage dans l'éditeur de programmes du logiciel PC, « Vérifier la syntaxe et enregistrer » ; pour une bibliothèque : classeur dans `MyLib`, puis rafraîchir les bibliothèques | idem (vérifier que le fichier arrive bien dans `MyLib`) |
| Page Notes | à construire à la main dans le logiciel PC (10 à 15 boîtes mathématiques), une fois | idem |

---

## 6. Plan par étapes (du mardi 10.11 au lundi 16.11)

Chaque étape laisse la machine dans un état utilisable. Temps « utilisateur » = essais sur la calculatrice ; le reste est du travail d'agent.

| Jour | Étape | Contenu | Critère de réussite | Temps utilisateur |
|---|---|---|---|---|
| Ma 10 (soir) | **0. Essai de faisabilité** | Un script Lua de 60 lignes qui teste : (1) ouverture sur 6.3 d'un `.tns` Lua fabriqué par Luna/`construire_tns.py` ; (2) `math.evalStr("factor(x^3+x^2-8x-12)")`, `solve(y=(x^2+1)/(2x^2-3),x)`, `domain(…)`, `propFrac(…)` ; (3) polices 7-24, gras, couleurs ; (4) `D2Editor` en lecture seule avec `\0el {…}` ; (5) flèches, `enter`, `esc`, menu `toolpalette` ; (6) `on.save`/`on.restore`. En parallèle, 5 lignes Python pour `writeST`/`readST`. | (1), (2), (3), (5) passent → on poursuit en Lua. (4) décide entre `D2Editor` et rendu maison. Échec de (1) ou (2) → repli option A. | 20 min |
| Ma 10 | 0 bis. Page Notes | tableau de bord CAS (f, factor, domain, propFrac, zéros, limites, réciproque) | les boîtes se recalculent quand on change f | 15 min |
| Me 11 | **1. Socle Lua** | `ui`, `cas`, `saisie`, `rendu` ; menu principal ; visionneuse ; premier module : **identification** (S7 ex.5 et ex.7 b) | S7 ex.5 et ex.7 b rendus à l'identique du corrigé | 20 min |
| Je 12 | **2. Problème C** | module analyse (a à h de l'ex.7), tableau de signes dessiné, zéros/pôles et factorisation de l'ex.8 | S7 ex.7 et ex.8 conformes aux corrigés (`corrige-exo07.md`, `corrige-exo08.md`) | 30 min |
| Ve 13 | **3. Vecteurs** | projection, angle, produits, volume/coplanarité avec paramètre, composantes dans une base, BON (méthode λ, μ du prof) | test 2025 P2 retrouvé : T(−3;−2;7), S(5;7;5), V=0, QS=(−1;2;0), w du corrigé | 30 min |
| Sa 14 | **4. Outils + gel** | inéquations/valeur absolue, paramètre, changement de variable (exp/ln compris) ; retouches Python (menu plein écran) ; **gel du code à midi** ; mise à jour de `README.md` | test 2025 P1 a, b, c retrouvés ; les deux classeurs sur la machine | 30 min |
| Di 15 | 5. Répétition | examen blanc de 90 min avec l'outil figé ; on ne corrige plus que des blocages | — | (révision) |
| Lu 16 | Test | batterie chargée, classeurs à la racine, page Notes prête | — | — |

Ordre de priorité si le temps manque : étapes 0, 1, 2 (le problème C vaut 12 points sur 36 et c'est la demande explicite), puis 3, puis 4. Les modules non portés restent servis par le classeur Python.

Repli (essai 0 négatif) : option A en une journée — menu à flèches plein écran, saisie sans shell, rendu 2D maison des fractions dans la visionneuse, pont CAS si `writeST`/`readST` répond — plus la page Notes.

---

## 7. Risques et questions ouvertes

### 7.1 Risques

| Risque | Gravité | Parade |
|---|---|---|
| Un `.tns` Lua fabriqué hors logiciel TI est refusé en 6.3 | bloquant pour B/C | testé à l'étape 0 ; sinon collage dans l'éditeur de script du logiciel PC ; sinon repli A |
| `evalStr` renvoie des chaînes difficiles à relire (U+2212, forme `or`/`and`, ordre des termes) | moyen | on renvoie la chaîne telle quelle au CAS pour la suite ; l'analyse de texte se limite à l'affichage |
| `D2Editor` capricieux (focus, défilement, lenteur) | moyen | rendu maison avec `gc` (150 lignes) |
| Rédaction différente de celle du prof (ordre des étapes, vocabulaire) | élevé pour les points | chaque module est comparé au corrigé du prof avant validation ; trame reprise des scripts Python déjà relus |
| Temps de révision mangé par l'outil | élevé | essais plafonnés à 30 min par jour, gel le 14 à midi |
| Dépendance à l'outil pendant le test (90 min, 2,5 min par point) | moyen | l'outil sert de contrôle après rédaction ; répétition du dimanche |
| Bug découvert le jour du test | moyen | classeur Python conservé, page Notes, commandes CAS de la fiche `/cas` |
| `writeST`/`readST` modifiés ou retirés dans une version future | faible | usage secondaire uniquement (ligne de contrôle) |
| Matériel autorisé | à lever | l'énoncé de mission dit « calculatrice et programmes autorisés, pas de mode examen » ; l'en-tête 2025 ne parle que de la calculatrice : une confirmation du prof lève le doute |

### 7.2 Questions pour l'utilisateur (à poser sous forme de choix)

1. **Architecture** — (a) hybride progressif Lua + CAS avec Python en secours *(recommandé)* ; (b) Python seul amélioré ; (c) tout réécrire en Lua et retirer Python.
2. **Rendu 2D** — (a) boîtes mathématiques natives `D2Editor` si l'essai est bon, sinon rendu maison *(recommandé)* ; (b) rendu maison d'emblée (plus prévisible, un peu moins beau) ; (c) texte en ligne comme aujourd'hui.
3. **Saisie de f(x)** — (a) boîte mathématique 2D (modèle de fraction natif) ; (b) ligne de texte `(x^2+1)/(2x^2-3)` comme aujourd'hui ; (c) les deux, au choix dans le menu.
4. **Priorité après le problème C** — (a) vecteurs (18 points sur 36) *(recommandé)* ; (b) outils des séries 1-3 ; (c) s'arrêter au problème C et réviser.
5. **Niveau de détail des étapes** — (a) copie complète prête à recopier (chaque ligne d'équivalence) ; (b) plan + résultats intermédiaires ; (c) réglable par la touche `menu`.
6. **Page Notes « tableau de bord »** — (a) oui, construite à la main dans le logiciel PC (15 min) ; (b) non.
7. **Chasles dans une figure** — (a) petit simplificateur de sommes de bipoints ; (b) laissé de côté (la figure n'est pas dans la machine).
8. **Autorisation des programmes** — (a) déjà confirmée par le prof ; (b) à confirmer avant le 16.

---

## 8. Sources

Officielles TI :
- Lua, `math.evalStr` : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/mathlibexten/evalstr.htm
- Lua, `math.eval` : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/mathlibexten/eval.htm
- Lua, bibliothèque 2D Editor : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/2deditorlib/2deditorlibrary.htm
- Lua, `createMathBox` : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/2deditorlib/createmathbox.htm
- Lua, `gc:setFont` : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/graphicslib/setfont.htm
- Lua, `toolpalette.register` : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/libraries/toolpalettelib/register.htm
- Lua, exécution sur CX II : https://education.ti.com/html/webhelp/eg_tinspire/en/Subsystems/EG_Lua/Content/m_scripteditor/m_scripteditor.HTML
- Guide de référence de l'API Lua v4.4 (PDF) : https://education.ti.com/html/webhelp/EG_TINspireLUA/EN/content/resources/pdf/ti-nspire(tm)%20lua%20scripting%20api%20reference%20guide%20v4.4.pdf
- Python, menu `ti_draw` : https://education.ti.com/html/eguides/nspire/eg_nspire/en/content/eg_python/m_menumap/mm_tidraw.HTML
- Python, menu `ti_system` : https://education.ti.com/html/eguides/nspire/eg_nspire/en/content/eg_python/m_menumap/mm_tisystem.HTML
- Python, Shell : https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Python/Content/m_workspaces/ws_shell.HTML
- Python, menu Outils (ctrl+R) : https://education.ti.com/html/webhelp/EG_TINspire/EN/Subsystems/EG_Python/Content/m_menumap/mm_tools.HTML
- TI-Basic, commandes graphiques CX II : https://education.ti.com/html/webhelp/eg_tinspire/en/Subsystems/EG_RefGuide/Content/M_RefGuide/RG_DrawCommand.HTML
- Bibliothèques (MyLib, LibPub) : https://education.ti.com/html/webhelp/EG_TINspire/EN/content/m_libraries/lb_using_library_objects.HTML
- Commande `domain` : https://education.ti.com/en/customer-support/knowledge-base/ti-nspire-family/product-usage/33591

Communauté :
- Luna (Lua/Python/XML → `.tns`) : https://github.com/ndless-nspire/Luna
- eval_expr (Python → CAS) : https://github.com/TI-Planet/eval_expr
- Wiki Inspired-Lua : https://wiki.inspired-lua.org/Events · https://wiki.inspired-lua.org/math.evalStr · https://wiki.inspired-lua.org/on.save · https://wiki.inspired-lua.org/on.restore · https://wiki.inspired-lua.org/D2Editor
- Boîte mathématique évaluée depuis Lua (Omnimaga) : https://omnimaga.org/lua-language/creatingformating-an-evaluated-math-box-from-lua-script
- SD2, dérivation pas à pas (ticalc.org) : https://www.ticalc.org/archives/files/fileinfo/457/45719.html
- TabVar v3 (Omnimaga) : https://www.omnimaga.org/lua-language/tabvar-v3-the-ultimate-function-analysis-program-!
- Ndless, versions : https://github.com/ndless-nspire/Ndless/releases

Essais locaux (10.11.2026, sans modification du logiciel TI ni de l'existant) :
- extraction des `PyLib/*.tns` du logiciel 6.3.0.119 et liste des symboles des `.mpy` (`ti_system`, `ti_plotlib`, `ti_image`) ;
- tentative de déchiffrement de `MyLib/numtheory.tns` avec la clé fixe de Luna : échec ;
- lecture de `luna.c` (en-tête et pied d'un script Lua) et de `eval_expr.py`.
