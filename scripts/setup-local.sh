#!/usr/bin/env bash

main() {

# Yerel Whisper ve Kokoro kurulumu.
# Ana depodan ayrı test klonunda çalıştırılmalıdır.

PROJECT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)" || {
    printf 'HATA: Proje dizini belirlenemedi.\n'
    return 1
}

cd "$PROJECT" || {
    printf 'HATA: Proje dizinine geçilemedi.\n'
    return 1
}

fail() {
    printf 'HATA: %s\n' "$1" >&2
    return 1
}

if [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$PROJECT" ]; then
    fail "Git depo kökü doğrulanamadı." || :
    return 1
fi

if [ "$(getenforce 2>/dev/null)" != "Enforcing" ]; then
    fail "SELinux Enforcing değil; işlem durduruldu." || :
    return 1
fi

if [ -n "$(git ls-files -- orioninsist/)" ]; then
    fail "orioninsist/ Git tarafından izleniyor." || :
    return 1
fi

if ! git check-ignore --quiet --no-index orioninsist/; then
    fail "orioninsist/ için Git ignore kuralı doğrulanamadı." || :
    return 1
fi

for COMMAND in curl sha256sum docker; do
    if ! command -v "$COMMAND" >/dev/null 2>&1; then
        fail "Gerekli komut bulunamadı: $COMMAND" || :
        return 1
    fi
done

if ! docker buildx version >/dev/null 2>&1; then
    fail "Docker Buildx kullanılamıyor." || :
    return 1
fi


if [ "$#" -gt 1 ] || {
    [ "$#" -eq 1 ] && [ "$1" != "--preflight-only" ];
}; then
    printf 'HATA: Geçersiz argüman.\n' >&2
    return 1
fi

if [ "${1:-}" = "--preflight-only" ]; then
    printf 'Ön kontrol başarılı; indirme ve derleme yapılmadı.\n'
    return 0
fi

REV="f3ff3571791e39611d31c381e3a41a3af07b4987"
BASE="https://huggingface.co/hexgrad/Kokoro-82M/resolve/$REV"
WHISPER_URL="https://openaipublic.azureedge.net/main/whisper/models/ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt"
SPACY_URL="https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"

download_checked() {
    local file="$1"
    local url="$2"
    local expected="$3"

    if [ -e "$file" ] || [ -L "$file" ]; then
        if [ ! -f "$file" ] || [ -L "$file" ]; then
            fail "Mevcut hedef normal bir dosya değil: $file" || :
            return 1
        fi

        if ! printf '%s  %s\n' "$expected" "$file" |
            sha256sum --check --status -; then
            fail "Mevcut dosyanın SHA-256 değeri uyuşmuyor; üzerine yazılmadı: $file" || :
            return 1
        fi

        printf 'DOĞRULANDI, mevcut dosya korundu: %s\n' "$file"
        return 0
    fi

    # Hedefi yalnızca yoksa, atomik olmayan ancak exclusive
    # oluşturma ile sahiplen. Başka bir dosyanın üzerine yazma.
    if ! (set -o noclobber; : > "$file") 2>/dev/null; then
        fail "Hedef oluşturulamadı veya başka bir dosya mevcut: $file" || :
        return 1
    fi

    printf 'İndiriliyor: %s\n' "$file"

    if ! curl --fail --location --retry 3 \
        --output "$file" "$url"; then
        rm -f -- "$file"
        fail "İndirme başarısız: $file" || :
        return 1
    fi

    if ! printf '%s  %s\n' "$expected" "$file" |
        sha256sum --check --status -; then
        rm -f -- "$file"
        fail "SHA-256 doğrulaması başarısız: $file" || :
        return 1
    fi

    printf 'SHA-256 doğrulandı: %s\n' "$file"
    return 0
}

printf '\n=== DİZİNLER ===\n'

if ! mkdir -p \
    .local/models \
    .local/kokoro/voices \
    .local/kokoro/spacy; then
    fail "Yerel model dizinleri oluşturulamadı." || :
    return 1
fi

printf '\n=== WHISPER MODELİ ===\n'
download_checked \
    .local/models/base.pt \
    "$WHISPER_URL" \
    ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e || {
        return 1
    }

printf '\n=== KOKORO MODELLERİ ===\n'

download_checked \
    .local/kokoro/config.json \
    "$BASE/config.json" \
    5abb01e2403b072bf03d04fde160443e209d7a0dad49a423be15196b9b43c17f || {
        return 1
    }

download_checked \
    .local/kokoro/kokoro-v1_0.pth \
    "$BASE/kokoro-v1_0.pth" \
    496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4 || {
        return 1
    }

download_checked \
    .local/kokoro/voices/af_heart.pt \
    "$BASE/voices/af_heart.pt" \
    0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff || {
        return 1
    }

download_checked \
    .local/kokoro/voices/am_michael.pt \
    "$BASE/voices/am_michael.pt" \
    9a443b79a4b22489a5b0ab7c651a0bcd1a30bef675c28333f06971abbd47bd37 || {
        return 1
    }

download_checked \
    .local/kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl \
    "$SPACY_URL" \
    1932429db727d4bff3deed6b34cfc05df17794f4a52eeb26cf8928f7c1a0fb85 || {
        return 1
    }

printf '\n=== TÜM DOSYALARIN SON SHA-256 KONTROLÜ ===\n'

if ! sha256sum --check <<'HASHES'
ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e  .local/models/base.pt
5abb01e2403b072bf03d04fde160443e209d7a0dad49a423be15196b9b43c17f  .local/kokoro/config.json
496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4  .local/kokoro/kokoro-v1_0.pth
0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff  .local/kokoro/voices/af_heart.pt
9a443b79a4b22489a5b0ab7c651a0bcd1a30bef675c28333f06971abbd47bd37  .local/kokoro/voices/am_michael.pt
1932429db727d4bff3deed6b34cfc05df17794f4a52eeb26cf8928f7c1a0fb85  .local/kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl
HASHES
then
    fail "Son model doğrulaması başarısız." || :
    return 1
fi

if [ "$(getenforce 2>/dev/null)" != "Enforcing" ]; then
    fail "SELinux durumu değişti; derleme başlatılmadı." || :
    return 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SUFFIX="${STAMP}-$$"
WHISPER_IMAGE="orioninsist/whisper:setup-${SUFFIX}"
KOKORO_IMAGE="orioninsist/kokoro:setup-${SUFFIX}"

for IMAGE in "$WHISPER_IMAGE" "$KOKORO_IMAGE"; do
    if docker image inspect "$IMAGE" >/dev/null 2>&1; then
        fail "Benzersiz test etiketi zaten mevcut: $IMAGE" || :
        return 1
    fi
done

printf '\n=== WHISPER İMAJI OLUŞTURULUYOR ===\n'
printf 'Etiket: %s\n' "$WHISPER_IMAGE"

if ! docker build -f Dockerfile -t "$WHISPER_IMAGE" .; then
    fail "Whisper imajı oluşturulamadı; Kokoro derlemesi başlatılmadı." || :
    return 1
fi

printf '\n=== KOKORO İMAJI OLUŞTURULUYOR ===\n'
printf 'Etiket: %s\n' "$KOKORO_IMAGE"

# Mevcut Dockerfile.kokoro değiştirilmez.
# FROM satırı, yeni ve benzersiz Whisper etiketini kullanır.
if ! docker buildx build \
    --build-context spacywheel=./.local/kokoro/spacy \
    --file - \
    --tag "$KOKORO_IMAGE" \
    --load \
    . <<DOCKERFILE
# syntax=docker/dockerfile:1.7
FROM ${WHISPER_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_NO_CACHE=1

RUN uv pip install --system \
    --index-url https://pypi.org/simple \
    "kokoro==0.9.4" \
    "misaki[en]==0.9.4"

RUN --mount=type=bind,from=spacywheel,source=/en_core_web_sm-3.8.0-py3-none-any.whl,target=/tmp/en_core_web_sm-3.8.0-py3-none-any.whl,readonly \
    uv pip install --system --offline --no-deps \
    /tmp/en_core_web_sm-3.8.0-py3-none-any.whl

CMD ["python", "-c", "import kokoro; print('Kokoro import OK')"]
DOCKERFILE
then
    fail "Kokoro imajı oluşturulamadı." || :
    return 1
fi

printf '\n=== SON İMAJ DOĞRULAMASI ===\n'

if ! docker image inspect "$WHISPER_IMAGE" >/dev/null 2>&1; then
    fail "Whisper test imajı bulunamadı." || :
    return 1
fi

if ! docker image inspect "$KOKORO_IMAGE" >/dev/null 2>&1; then
    fail "Kokoro test imajı bulunamadı." || :
    return 1
fi

printf 'Whisper: %s\n' "$WHISPER_IMAGE"
printf 'Kokoro:  %s\n' "$KOKORO_IMAGE"

printf '\n=== GÜVENLİK SON KONTROLÜ ===\n'
git status --short
git ls-files -- orioninsist/
getenforce

printf '\nKurulum tamamlandı; test imajları korundu.\n'

}

main "$@"
