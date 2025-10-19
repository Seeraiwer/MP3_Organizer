#!/usr/bin/env bash
#
# organize-mp3.sh — Classe les MP3 par Artiste/Album en se basant sur les tags ID3.
# Dépendances : exiftool (package Arch: perl-image-exiftool)
#
# Usage :
#   ./organize-mp3.sh [-n] [-v] [--extensions "mp3|m4a|flac"] [SOURCE_DIR] [DEST_DIR]
#   -n : dry-run (ne fait qu'afficher ce qui serait fait)
#   -v : verbose (détaillé)
#
# Exemples :
#   ./organize-mp3.sh ./Musique ./Bibliotheque
#   ./organize-mp3.sh -n -v .
#
set -euo pipefail

DRY_RUN=0
VERBOSE=0
EXT_REGEX="mp3"   # modifiable via --extensions "mp3|m4a|flac"
SRC_DIR="."
DST_DIR="."

log() { echo "[$(date +'%H:%M:%S')] $*" >&2; }
vlog() { [[ "$VERBOSE" -eq 1 ]] && log "$@"; }

abort() { log "ERREUR: $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || abort "Commande manquante: $1"
}

sanitize() {
  # Nettoie un nom pour en faire un chemin sûr: supprime/convertit caractères problématiques
  # - remplace / et \ par tiret
  # - supprime les caractères de contrôle
  # - compacte espaces
  # - coupe à ~200 chars pour éviter des chemins trop longs
  local s="$1"
  s="${s//\//-}"
  s="${s//\\/-}"
  # supprime caractères non imprimables
  s="$(printf '%s' "$s" | tr -cd '[:print:]\n')"
  # remplace deux-points et autres
  s="$(printf '%s' "$s" | sed -E 's/[:*?"<>|]/-/g')"
  # trim
  s="$(printf '%s' "$s" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  # spaces multiples -> espace
  s="$(printf '%s' "$s" | tr -s ' ')"
  # si vide -> Unknown
  [[ -z "$s" ]] && s="Inconnu"
  # coupe
  echo "${s:0:200}"
}

move_file() {
  local src="$1" dst="$2"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[DRY] mv -- '$src' '$dst'"
  else
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" ]]; then
      # évite d'écraser: ajoute suffixe unique
      local base ext n=1
      base="${dst%.*}"
      ext="${dst##*.}"
      [[ "$ext" == "$dst" ]] && ext="" || ext=".$ext"
      while [[ -e "${base} (${n})${ext}" ]]; do n=$((n+1)); done
      dst="${base} (${n})${ext}"
    fi
    mv -- "$src" "$dst"
  fi
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    --extensions) EXT_REGEX="$2"; shift 2 ;;
    --) shift; break ;;
    -*)
      abort "Option inconnue: $1"
      ;;
    *)
      if [[ "$SRC_DIR" == "." ]]; then
        SRC_DIR="$1"
      elif [[ "$DST_DIR" == "." ]]; then
        DST_DIR="$1"
      else
        abort "Trop d'arguments. Voir --help."
      fi
      shift
      ;;
  esac
done

# Si un seul chemin fourni, on classe sur place
if [[ "$DST_DIR" == "." && "$SRC_DIR" != "." ]]; then
  DST_DIR="$SRC_DIR"
fi

# Vérifs
need_cmd exiftool
need_cmd find
[[ -d "$SRC_DIR" ]] || abort "Dossier source introuvable: $SRC_DIR"
[[ -d "$DST_DIR" ]] || { [[ "$DRY_RUN" -eq 1 ]] || mkdir -p "$DST_DIR"; }

log "Source: $SRC_DIR"
log "Destination: $DST_DIR"
log "Extensions: $EXT_REGEX"
[[ "$DRY_RUN" -eq 1 ]] && log "Mode: DRY-RUN (aucun fichier déplacé)"
[[ "$VERBOSE" -eq 1 ]] && log "Mode: VERBOSE"

# Fonction pour extraire tag via exiftool (renvoie vide si absent)
get_tag() {
  local tag="$1" file="$2"
  exiftool -s3 "-${tag}" -- "$file" 2>/dev/null || true
}

# Itération sûre (NUL-delimited)
# On capture les extensions choisies (regex insensitive)
while IFS= read -r -d '' f; do
  # Récupère tags — on tente plusieurs clés pour compat ID3/MP4/FLAC (si tu actives d'autres extensions)
  ARTIST="$(get_tag Artist "$f")"
  [[ -z "$ARTIST" ]] && ARTIST="$(get_tag AlbumArtist "$f")"
  ALBUM="$(get_tag Album "$f")"
  TITLE="$(get_tag Title "$f")"
  TRACK="$(get_tag Track "$f")"  # format "7" ou "7/12"

  # Nettoyage / défauts
  ARTIST="$(sanitize "${ARTIST:-Inconnu}")"
  ALBUM="$(sanitize "${ALBUM:-Inconnu}")"
  TITLE="$(sanitize "${TITLE:-$(basename "${f%.*}")}")"

  # Normalise N° de piste (garde nombre avant /, zero-pad 2)
  if [[ -n "$TRACK" ]]; then
    TRACK="${TRACK%%/*}"
    if [[ "$TRACK" =~ ^[0-9]+$ ]]; then
      printf -v TRACK "%02d" "$TRACK"
    else
      TRACK=""
    fi
  fi

  ext="${f##*.}"
  ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

  # Compose nom de fichier final: "NN - Titre.ext" si track dispo, sinon "Titre.ext"
  if [[ -n "$TRACK" ]]; then
    newname="${TRACK} - ${TITLE}.${ext}"
  else
    newname="${TITLE}.${ext}"
  fi

  # Dossier cible: DEST/Artiste/Album/
  target_dir="${DST_DIR}/${ARTIST}/${ALBUM}"
  target_path="${target_dir}/${newname}"

  vlog "Fichier: $f"
  vlog "  -> Artiste: $ARTIST | Album: $ALBUM | Piste: ${TRACK:---} | Titre: $TITLE"
  vlog "  -> ${target_path}"

  move_file "$f" "$target_path"

done < <(find "$SRC_DIR" -type f -regextype posix-extended -iregex ".*\.(${EXT_REGEX})$" -print0)

log "Terminé."

