# 🎵 organize-mp3.sh

Un script Bash pour organiser automatiquement votre bibliothèque musicale en se basant sur les tags ID3.

## 📋 Description

`organize-mp3.sh` classe les fichiers audio (MP3, M4A, FLAC, etc.) par **Artiste/Album** en utilisant les métadonnées embarquées. Parfait pour transformer une pile chaotique de fichiers musicaux en une hiérarchie organisée et cohérente.

**Structure générée :**
```
Destination/
├── Artiste 1/
│   ├── Album 1/
│   │   ├── 01 - Titre 1.mp3
│   │   ├── 02 - Titre 2.mp3
│   │   └── ...
│   └── Album 2/
│       └── ...
└── Artiste 2/
    └── ...
```

## ⚙️ Prérequis

- **Bash** 4.0+
- **exiftool** (pour lire les tags ID3/MP4/FLAC)
- **find** (généralement inclus)

### Installation sur Arch Linux
```bash
sudo pacman -S perl-image-exiftool
```

### Installation sur Debian/Ubuntu
```bash
sudo apt-get install libimage-exiftool-perl
```

### Installation sur macOS
```bash
brew install exiftool
```

## 📦 Installation

```bash
# Cloner ou télécharger le script
wget https://example.com/organize_mp3.sh
# ou
git clone <repo-url>

# Rendre exécutable
chmod +x organize_mp3.sh
```

## 🚀 Usage

### Syntaxe
```bash
./organize_mp3.sh [-n] [-v] [--extensions "mp3|m4a|flac"] [SOURCE_DIR] [DEST_DIR]
```

### Options

| Option | Description |
|--------|-------------|
| `-n` / `--dry-run` | Mode simulation : affiche les actions sans rien déplacer |
| `-v` / `--verbose` | Mode détaillé : affiche chaque fichier traité |
| `--extensions "mp3\|m4a\|flac"` | Types de fichiers à traiter (regex, défaut: mp3) |
| `SOURCE_DIR` | Dossier contenant les fichiers à organiser (défaut: `.`) |
| `DEST_DIR` | Dossier de destination (défaut: SOURCE_DIR si un seul chemin) |

### Exemples

**Test avant de vraiment bouger les fichiers :**
```bash
./organize_mp3.sh -n -v ./Téléchargements ./Musique
```

**Organisation sur place :**
```bash
./organize_mp3.sh ./MonDossierMusique
```

**Organiser plusieurs formats :**
```bash
./organize_mp3.sh --extensions "mp3|m4a|flac" ./SourceAudio ./BibliothequeAudio
```

**Verbose + dry-run :**
```bash
./organize_mp3.sh -n -v .
```

## 🔧 Fonctionnalités

✅ **Lecture des métadonnées** : Extrait Artiste, Album, Titre, N° de piste  
✅ **Gestion des cas limites** :
   - Fichiers sans tags → dossier "Inconnu"
   - Caractères invalides → remplacés par des tirets
   - Espaces multiples → compactés
   - Noms trop longs (>200 chars) → tronqués

✅ **Prévention des écrasements** : Les fichiers en doublon reçoivent un suffixe `(1)`, `(2)`, etc.  
✅ **Sécurité** : Gestion correcte des noms de fichiers avec espaces/caractères spéciaux  
✅ **Mode simulation** : Testez avant d'agir  
✅ **Support multi-format** : MP3, M4A, FLAC, et autre formats supportés par exiftool

## 📝 Détails techniques

### Normalisation des noms
- `/` et `\` → `-`
- `:*?"<>|` → `-`
- Espaces multiples → espace simple
- Trim espaces début/fin
- Max 200 caractères

### Nommage des pistes
- Format avec piste : `01 - Titre.mp3`
- Format sans piste : `Titre.mp3`
- N° de piste zero-padded à 2 chiffres

### Ordre de priorité (Artiste)
1. Tag `Artist`
2. Tag `AlbumArtist`
3. "Inconnu" si absent

## ⚠️ Notes

- **Toujours tester en mode `-n` d'abord** sur un petit dossier !
- Les fichiers **ne sont pas supprimés**, ils sont **déplacés**
- Les permissions de fichiers sont conservées
- Utilise `set -euo pipefail` pour une sécurité maximale
- Gère les chemins avec espaces et caractères spéciaux

## 🐛 Dépannage

**Erreur : "Commande manquante: exiftool"**
```bash
# Installer exiftool selon votre OS (voir Prérequis)
```

**Aucun fichier ne s'est déplacé**
- Vérifiez que les tags ID3 sont présents : `exiftool monmorceau.mp3`
- Testez d'abord en mode `-v -n` pour voir ce qui se passe

**Certains fichiers restent en place**
- Ils peuvent être mal taggés ou sans extension reconnue
- Vérifiez les permissions d'accès

## 📄 Licence

Libre d'utilisation. Utilisez à vos risques. 🎵

## 💡 Améliorations futures

- [ ] Support de genres (créer sous-dossiers par genre)
- [ ] Interface interactive
- [ ] Compatibilité Windows (Git Bash / WSL)
- [ ] Logs sauvegardés dans un fichier

---

**Besoin d'aide ?** Ouvrez une issue ou consultez l'aide :
```bash
./organize_mp3.sh -h  # (à ajouter au script)
```
