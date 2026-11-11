"""Assemble et fabrique le solveur maths sur le socle commun : tools/nspire/socle + lua/modules/*.lua
(ordre alphabetique : 00_commun … 90_menu) -> lua/solveur_socle.lua + lua/solveur_socle.tns.

lua/solveur.lua (version d'un seul tenant, envoyee sur la calculatrice) n'est PAS touche : la version sur socle vit a cote
jusqu'a validation. Non-regression : tools/py MATH_1/calculatrice/test_solveur_socle.py (python avec lupa).
"""
import subprocess
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
mods = sorted(str(p) for p in (ICI / "lua" / "modules").glob("[0-9][0-9]_*.lua"))
sys.exit(subprocess.call([sys.executable, str(ICI.parents[1] / "tools" / "nspire" / "construire_app.py"),
                          str(ICI / "lua" / "solveur_socle.tns")] + mods))
