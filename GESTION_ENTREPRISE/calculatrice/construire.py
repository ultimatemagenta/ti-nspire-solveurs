"""Assemble et fabrique compta.tns : tools/nspire/socle + lua/*.lua (ordre alphabétique : 00_commun … 99_menu)."""
import subprocess, sys
from pathlib import Path
ICI = Path(__file__).resolve().parent
mods = sorted(str(p) for p in (ICI / "lua").glob("*.lua"))
sys.exit(subprocess.call([sys.executable, str(ICI.parents[1] / "tools" / "nspire" / "construire_app.py"), str(ICI / "compta.tns")] + mods))
