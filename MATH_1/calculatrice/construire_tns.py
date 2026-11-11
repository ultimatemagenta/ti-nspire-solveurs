"""Fabrique un classeur TI-Nspire (.tns) contenant des scripts Python.

Portage Python de la partie « Python » de Luna 2.1 (ndless-nspire/Luna, MPL 1.1) :
zip TI (en-tete *TIMLP0500, fin TIPD), Document.xml par defaut, Problem1.xml
(XML TI compresse, deflate brut, chiffrement 3DES « doccrypt »), puis les .py deflates.

Usage : python construire_tns.py SORTIE.tns premier.py [autres.py ...]
Le premier script est celui qui s'ouvre avec le classeur.
"""
import struct
import sys
import zlib
from pathlib import Path

try:
    from cryptography.hazmat.decrepit.ciphers.algorithms import TripleDES
except ImportError:  # anciennes versions de cryptography
    from cryptography.hazmat.primitives.ciphers.algorithms import TripleDES
from cryptography.hazmat.primitives.ciphers import Cipher, modes

K1 = bytes([0x16, 0xA7, 0xA7, 0x32, 0x68, 0xA7, 0xBA, 0x73])
K2 = bytes([0xD9, 0xA8, 0x86, 0xA4, 0x34, 0x45, 0x94, 0x10])
K3 = bytes([0x3D, 0x80, 0x8C, 0xB5, 0xDF, 0xB3, 0x80, 0x6B])
IVEC_BASE = 0x6FE21307

TIEN_HEADER = bytes.fromhex(
    "0FCED8D28106865B99DDA23DD9E94BD431BB50B64DB32924706049381C30F899004B9264E458E6BC")

DEFAULT_DOCUMENT = bytes.fromhex(
    "0FCED8D28106865B4A4AC5CEA916F2D51DA82F6E0022F2F0C1A606774D7EA6C03AF05C74BAAA4460"
    "CD58E670D740F69C17DCF09477BFCADEF70209C962B15DEF22FA5137A0819148E1834DAD08312DD0"
    "D3E32D60AB13C2982BED395B092439922F0C7A4C9574913B0CF460CC7327CB077E7FA91787E2ACA2"
    "3BCCA0C4E38E89F0C0519FC2BECE2845C3D41190A6EC53A0FB5B466B41ADE953BB97DBB1D268E2F6"
    "360F2636759BE91F48ADE92967005819C3C01276A04A73F3B1D30918D606DD9724533E22A4FB8250"
    "7B7C12884E7D4180FE72922987E85C5672FF29168C425B8B9BA7D2086DD398FF91A99EF393A82E1C"
    "B2A96B6ADFF6CE2D1517CE6EC04F9A9C0EDF198D2DFA699F11D22012E07914044E628F0A2A18725A"
    "8B80B33C9BD567594B514DE0C33828C3DCCD3922128C4055")

PY_HEADER = (b'TIXC0100-1.0?><prob xmlns="urn:TI.Problem" ver="1.0" pbname="">'
             b'<sym>\x0E\x01<card clay="0" h1="10000" h2="10000" w1="10000" '
             b'w2="10000"><isDummyCard>0\x0E\x03<flag>0\x0E\x04<wdgt xmlns:py="urn:'
             b'TI.PythonEditor" type="TI.PythonEditor" ver="1.0"><py:data><py:name>')
PY_FOOTER = (b'\x0E\x07<py:dirf>-10000000\x0E\x08\x0E\x06<py:mFlags>1024\x0E\x09'
             b'<py:value>10\x0E\x0A\x0E\x05\x0E\x02\x0E\x00')


def doccrypt(data: bytes) -> bytes:
    """Chiffrement TI : XOR avec 3DES-EDE(ivec) ; ivec = 4 octets nuls + compteur LE (modulo 1024)."""
    enc = Cipher(TripleDES(K1 + K2 + K3), modes.ECB()).encryptor()
    out = bytearray(data)
    incr = 0
    for off in range(0, len(out), 8):
        cur = (IVEC_BASE + incr) & 0xFFFFFFFF
        incr = (incr + 1) % 1024
        ks = enc.update(b"\0\0\0\0" + struct.pack("<I", cur))
        for i in range(min(8, len(out) - off)):
            out[off + i] ^= ks[i]
    return bytes(out)


def deflate_brut(data: bytes) -> bytes:
    c = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, -15, 8)
    return c.compress(data) + c.flush()


def xml_chiffre(xmlc: bytes) -> bytes:
    return TIEN_HEADER + doccrypt(deflate_brut(xmlc))


def ecrire_tns(sortie: Path, entrees: list[tuple[str, bytes, int, int]]) -> None:
    """entrees : (nom, donnees_ecrites, methode, taille_non_compressee, crc)."""
    out = bytearray()
    central = bytearray()
    for idx, (nom, donnees, methode, taille, crc) in enumerate(entrees):
        offset = len(out)
        nb = nom.encode()
        magic = b"*TIMLP0500" if idx == 0 else struct.pack("<I", 0x04034B50)
        out += magic
        out += struct.pack("<HHHIIIIHH", 20, 0, methode, 0, crc, len(donnees), taille, len(nb), 0)
        out += nb + donnees
        central += struct.pack("<IHHHHIIIIHHHHHII", 0x02014B50, 0, 20, 0, methode, 0, crc,
                               len(donnees), taille, len(nb), 0, 0, 0, 0, 0, offset)
        central += nb
    debut_central = len(out)
    out += central
    out += struct.pack("<IHHHHIIH", 0x44504954, 0, 0, len(entrees), len(entrees),
                       len(central), debut_central, 0)
    sortie.write_bytes(bytes(out))


def construire(sortie: Path, scripts: list[Path]) -> None:
    entrees = [("Document.xml", DEFAULT_DOCUMENT, 0x0D, len(DEFAULT_DOCUMENT),
                zlib.crc32(DEFAULT_DOCUMENT))]
    pb = xml_chiffre(PY_HEADER + scripts[0].name.encode() + PY_FOOTER)
    entrees.append(("Problem1.xml", pb, 0x0D, len(pb), zlib.crc32(pb)))
    for s in scripts:
        brut = s.read_bytes()
        entrees.append((s.name, deflate_brut(brut), 8, len(brut), zlib.crc32(brut)))
    ecrire_tns(sortie, entrees)


LUA_HEADER = bytes.fromhex(
    "54495843303130302D312E303F3E3C70726F6220786D6C6E733D2275726E3A54492E50A85F5B1F0A"
    "22207665723D22312E30222070626E616D653D22223E3C73796D3E0E013C6361726420636C61793D"
    "2230222068313D22F10000FF222068323D22F10000FF222077313D22F10000FF222077323D22F100"
    "00FF223E3C697344756D6D79436172643E300E033C666C61673E300E043C7764677420786D6C6E73"
    "3A73633D2275726E3A54492E53AC84F22A4170702220747970653D2254492E53AC84F22A41707022"
    "207665723D22312E30223E3C73633A6D466C6167733E300E063C73633A76616C75653E2D310E073C"
    "73633A7363726970742076657273696F6E3D22353132222069643D2230223E3C215B43444154415B")
LUA_FOOTER = bytes.fromhex("5D5D3E0E080E050E020E00")


def construire_lua(sortie: Path, script: Path) -> None:
    """Classeur Lua (une page script), comme `luna script.lua sortie.tns`."""
    corps = script.read_bytes()
    if corps.startswith(b"\xef\xbb\xbf"):
        corps = corps[3:]
    corps = corps.replace(b"]]>", b"]]]]><![CDATA[>")
    pb = xml_chiffre(LUA_HEADER + corps + LUA_FOOTER)
    entrees = [("Document.xml", DEFAULT_DOCUMENT, 0x0D, len(DEFAULT_DOCUMENT), zlib.crc32(DEFAULT_DOCUMENT)),
               ("Problem1.xml", pb, 0x0D, len(pb), zlib.crc32(pb))]
    ecrire_tns(sortie, entrees)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    if sys.argv[2].endswith(".lua"):
        construire_lua(Path(sys.argv[1]), Path(sys.argv[2]))
        print("ecrit :", sys.argv[1])
        sys.exit(0)
    construire(Path(sys.argv[1]), [Path(p) for p in sys.argv[2:]])
    print("ecrit :", sys.argv[1])
