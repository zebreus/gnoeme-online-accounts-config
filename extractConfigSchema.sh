#!/usr/bin/env bash
# shellcheck disable=SC2002

# Use the version of gnome-online-accounts matching the version of the script
VERSION="${version:-"master"}"

GOA_REF=${1:-"$VERSION"}

# Find the directory of the script
# Copied without understanding from https://stackoverflow.com/a/246128
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
    SOURCE=$(readlink "$SOURCE")
    [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

ORIGINAL_WORK_DIR=$(pwd)

WORK_DIR=$(mktemp -d)
CACHE_DIR=~/.cache/gnome-online-accounts-config/repo-cache

echo "Fetching gnome-online-accounts to $WORK_DIR"
if [ ! -d "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR"
    git clone --bare https://gitlab.gnome.org/GNOME/gnome-online-accounts.git "$CACHE_DIR"
fi
git -C "$CACHE_DIR" fetch origin "$GOA_REF"
git clone --local "$CACHE_DIR" "$WORK_DIR"
cd "$WORK_DIR" || exit 1
git checkout "$GOA_REF"

declare -a PROVIDERS
declare -a OPTIONS
declare -a DESCRIPTIONS
declare -a MAYBE_OPTIONS

function findKeyFileEntries {
    local file=$1

    mapfile -t keys < <(cat $file | tr -d "\n " | grep -Pzo '(?s)(g_key_file_[gs]et_|goa_util_lookup_keyfile_|goa_utils_keyfile_[gs]et_)[a-z_]+\s*\([^)]+\)' | xargs -0 -n1 echo | sed 's/ //g' | sed -E 's|^[a-z_]*_([a-z_]+)\s*\([^)"]+"([^"]+)"[^)]*\)|{"method":"key_file_get","file":"'"$file"'","type":"\1","value":"\2"}|' | sed '/^$/d')

    MAYBE_OPTIONS+=("${keys[@]}")

    printf '%s\n' "${keys[@]}"
}

function listAvailableProviders {
    mapfile -t PROVIDERS < <(cat meson.build | grep -Po 'config_h.set[a-z_]*[(]'\''GOA_[A-Z_]+_NAME'\'', '\''[^'\'']+'\' | sed -E 's/.*'\''([^'\'']+)'\''$/"\1"/g')
}

function findDescriptions {
    local symbol=$1

    mapfile -t descriptions < <(cat data/dbus-interfaces.xml | tr "\n" "\2" | grep -Pzo '\s*<!--(.(?!->))*-->[ \2]*<property name="'"$symbol"'"[^>]*\/?>' | tr "\0" "\n" | sed 's/<!--/    /' | sed 's/\s*-->\s*//' | sed $'s/\2\\s*/\2/g' | sed $'s/\2+/\2/g' | sed 's/^\s*//' | sed $'s/'"$symbol"$':\2//g' | sed $'s/@since:[^\2]*\2//g' | sed -E $'s/\2?(.*)<property name=\"('"$symbol"$')\" type=\"([^)]+)\" access=\"([^)]+)\"\\/?>/{änameä:ä\\2ä,ädescriptionä:ä\\1ä,ätypeä:ä\\3ä,äaccessä:ä\\4ä}/g' | sed 's/"/\\"/g' | sed 's/ä/"/g' | sed -E $'s/\2/\\\\n/g' | sed -E 's/(\\n)+\",/\",/g' | sed -E 's/": "(\\n)+/": "/g' | sort | uniq)

    DESCRIPTIONS+=("${descriptions[@]}")
}

for source in $(echo src/*/* | tr " " "\n" | grep -v "src/examples" | grep -v "src/goabackend/goautils.c"); do
    echo "Processing $source"
    findKeyFileEntries "$source"
done

declare -a OPTIONS
mapfile -t OPTIONS < <(printf '%s\n' "${MAYBE_OPTIONS[@]}" | grep '^{' | sort | uniq)

listAvailableProviders

for option in "${OPTIONS[@]}"; do
    option=$(echo "$option" | jq -r '.value')
    echo "Finding descriptions for $option"
    findDescriptions "$option"
done

printf '%s\n' "${OPTIONS[@]}"
printf '%s\n' "${PROVIDERS[@]}"
printf '%s\n' "${DESCRIPTIONS[@]}"

function join_by {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

function toJson {
    printf '{"providers":['
    join_by , "${PROVIDERS[@]}"
    printf '],"options":['
    join_by , "${OPTIONS[@]}"
    printf '],"descriptions":['
    join_by , "${DESCRIPTIONS[@]}"
    printf ']}'
}

echo "Writing to extractedConfig.json"

toJson | tr -d $'\0\2\1' | tr -d '\0\2\1' | jq . >extractedConfig.json

cp extractedConfig.json "$ORIGINAL_WORK_DIR"

# The script loads extractedConfig.json relative to its own location, so we need to copy it to the same directory
cp "$DIR/processSchema.ts" "$WORK_DIR"
deno run -A "$WORK_DIR/processSchema.ts"
nixpkgs-fmt fixedConfig.nix

cp cleanedConfig.json "$ORIGINAL_WORK_DIR"
cp extractedConfig.json "$ORIGINAL_WORK_DIR"
cp fixedConfig.json "$ORIGINAL_WORK_DIR"
cp fixedConfig.nix "$ORIGINAL_WORK_DIR"
