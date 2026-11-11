# maths1 : menu principal des programmes MATH_1 (TI-Nspire CX II)
# Ouvre ce script puis ctrl+R (Exécuter).
import fonction
import vecteurs
import degre2
import parametre
import facto
import ident
from ecran import voir, effacer, historique

def main():
    while True:
        effacer()
        print("MATH_1 - controle de copie")
        print("1 analyse de fonction")
        print("2 vecteurs")
        print("3 2nd degre, inequations")
        print("4 parametre, chgt de variable")
        print("5 factoriser un polynome")
        print("6 identifier des reels a,b,c")
        print("7 historique des resultats")
        print("0 quitter")
        c = input("Choix : ").strip()
        if c in ("0", "q"):
            return
        try:
            if c == "1":
                fonction.analyse()
            elif c == "2":
                vecteurs.menu()
            elif c == "3":
                degre2.menu()
            elif c == "4":
                parametre.menu()
            elif c == "5":
                facto.menu()
            elif c == "6":
                ident.menu()
            elif c == "7":
                historique()
            voir()
        except Exception as e:
            voir()
            print("Erreur : " + str(e))
            input("[enter]")

main()
