"""Assemble une application Lua TI-Nspire : socle_debut + modules de l'app + socle_fin, puis fabrique le .tns.

Usage : tools/py tools/nspire/construire_app.py SORTIE.tns module1.lua [module2.lua ...]
Les modules definissent leurs fonctions, TITRE_APP et menuPrincipal (sans « local »).
Le script assemble est aussi ecrit a cote du .tns (meme nom, .lua) pour relecture.
"""
import sys
from pathlib import Path

ICI = Path(__file__).resolve().parent
sys.path.insert(0, str(ICI.parents[1] / "MATH_1" / "calculatrice"))
from construire_tns import construire_lua  # noqa: E402


def assembler(modules):
    parts = [(ICI / "socle_debut.lua").read_text(encoding="utf-8")]
    for m in modules:
        parts.append("-- ===== module " + Path(m).name + "\n" + Path(m).read_text(encoding="utf-8"))
    parts.append((ICI / "socle_fin.lua").read_text(encoding="utf-8"))
    return "\n".join(parts)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    sortie = Path(sys.argv[1])
    script = assembler(sys.argv[2:])
    lua = sortie.with_suffix(".lua")
    lua.write_text(script, encoding="utf-8", newline="\n")
    construire_lua(sortie, lua)
    print("ecrit :", sortie, "(", script.count("\n"), "lignes )")
