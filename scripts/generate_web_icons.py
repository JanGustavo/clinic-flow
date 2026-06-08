#!/usr/bin/env python3
"""
Gera ícones para web a partir de um PNG em frontend/assets/branding/sorriso_perfeito.png

Uso:
  python3 scripts/generate_web_icons.py

Requisitos:
  pip install Pillow
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'frontend' / 'assets' / 'branding' / 'sorriso_perfeito.png'
OUT_DIR = ROOT / 'frontend' / 'web' / 'icons'

SIZES = {
    'Icon-192.png': 192,
    'Icon-512.png': 512,
    'Icon-maskable-192.png': 192,
    'Icon-maskable-512.png': 512,
    'favicon.png': 48,
}


def ensure_dir(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)


def main():
    if not SRC.exists():
        print(f"Arquivo fonte não encontrado: {SRC}")
        print("Coloque o PNG do ícone em frontend/assets/branding/sorriso_perfeito.png")
        return

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    img = Image.open(SRC).convert('RGBA')

    for name, size in SIZES.items():
        out_path = OUT_DIR / name
        # Cria fundo transparente ou redimensiona mantendo proporção
        resized = img.copy()
        resized.thumbnail((size, size), Image.LANCZOS)

        # Criar canvaz quadrado
        canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        x = (size - resized.width) // 2
        y = (size - resized.height) // 2
        canvas.paste(resized, (x, y), resized)
        canvas.save(out_path, format='PNG')
        print(f'Gerado: {out_path}')


if __name__ == '__main__':
    main()
