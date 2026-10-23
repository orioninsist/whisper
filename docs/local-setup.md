# Yerel Whisper ve Kokoro Kurulumu

## Ortam

- Isletim sistemi: Fedora Linux
- Calisma ortami: Docker
- SELinux: Enforcing
- Whisper: CPU
- Kokoro TTS: CPU
- Python Docker tabani: 3.11-slim-bookworm
- uv: 0.12.24

## Git tarafindan izlenen dosyalar

- Dockerfile
- Dockerfile.kokoro
- compose.yaml
- scripts/whisper-cli
- scripts/kokoro-tts.py
- Whisper kaynak kodlari ve testleri

## Yerel Docker imajlari

- orioninsist/whisper:cpu-test
- orioninsist/kokoro:rebuild-test

Bu imajlar yerel ortamda dogrulanmistir.
Temiz ortamda yeniden olusturma testi henuz belgelenmemistir.

## Dogrulanan Kokoro bagimliliklari

| Paket | Surum |
| --- | --- |
| kokoro | 0.9.4 |
| misaki | 0.9.4 |
| spacy | 3.8.16 |
| en-core-web-sm | 3.8.0 |
| torch | 2.14.1+cpu |
| numpy | 2.4.6 |

## Resmi Kokoro modeli

Kaynak:
https://huggingface.co/hexgrad/Kokoro-82M

Dogrulanan model deposu commit'i:

f3ff3571791e39611d31c381e3a41a3af07b4987

Yerel config.json dosyasi bu commit'teki resmi
config.json dosyasiyla SHA256 olarak eslesmistir.

## Yerel model dosyalari

Tum dosyalar orioninsist/ altinda saklanir.

| Dosya | SHA256 |
| --- | --- |
| kokoro/config.json | 5abb01e2403b072bf03d04fde160443e209d7a0dad49a423be15196b9b43c17f |
| kokoro/kokoro-v1_0.pth | 496dba118d1a58f5f3db2efc88dbdc216e0483fc89fe6e47ee1f2c53f18ad1e4 |
| kokoro/voices/af_heart.pt | 0ab5709b8ffab19bfd849cd11d98f75b60af7733253ad0d67b12382a102cb4ff |
| kokoro/voices/am_michael.pt | 9a443b79a4b22489a5b0ab7c651a0bcd1a30bef675c28333f06971abbd47bd37 |
| kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl | 1932429db727d4bff3deed6b34cfc05df17794f4a52eeb26cf8928f7c1a0fb85 |

## Mevcut CLI kullanimi

Metinden ses uretimi:

    whisper tts "Hello world" female speech.wav

Erkek sesi:

    whisper tts "Hello world" male speech.wav

Ciktilar yerel orioninsist/ klasorunde saklanir.

Mevcut CLI, yerel Kokoro Docker imajini kullanir.
Ag baglantisi kapali olarak calistirilir.

## Guvenlik

- SELinux Enforcing olarak kalmalidir.
- orioninsist/ Git tarafindan izlenmemelidir.
- Kisisel sesler, videolar ve ciktilar GitHub'a yuklenmemelidir.
- Buyuk model agirliklari yerelde saklanmalidir.
- Docker konteynerleri ile Fedora terminali ayri degerlendirilmelidir.
- Mevcut dosyalar onaysiz degistirilmemelidir.

## Henuz tamamlanmayan dogrulamalar

- Temiz ortamda Docker imajlarini yeniden olusturma
- Tum bagimliliklari kesin surumlere sabitleme
- Model dosyalarinin yeniden edinilme adimlarini belgeleme
- spaCy wheel dosyasinin yeniden edinilmesini dogrulama
- Yeni kurulumda CLI calisma testleri

Bu belge mevcut dogrulanmis ortami kaydeder.
Tam otomatik yeniden kurulum garantisi vermez.

## Temiz kurulum icin model edinme adimlari

Asagidaki komutlar Fedora terminalinde, proje kok dizininde
calistirilmak uzere hazirlanmistir.

Model dosyalari GitHub deposuna eklenmez.
Dosyalar orioninsist/ altinda saklanir.

### Model kaynaklari

Whisper base modeli:

https://openaipublic.azureedge.net/main/whisper/models/ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt

Kokoro model deposu:

https://huggingface.co/hexgrad/Kokoro-82M

Kokoro sabit commit:

f3ff3571791e39611d31c381e3a41a3af07b4987

spaCy en_core_web_sm 3.8.0:

https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl

Bu kaynaklardan alinan dosyalarin SHA256 degerleri
mevcut yerel dosyalarla karsilastirilarak dogrulanmistir.

### Dosyalari yeniden edinme

Asagidaki komutlar yalnizca bos bir kurulum dizininde
kullanilmalidir. Mevcut dosyalarin uzerine yazabilir.

    PROJECT="/home/murat/Project/whisper"
    REV="f3ff3571791e39611d31c381e3a41a3af07b4987"
    BASE="https://huggingface.co/hexgrad/Kokoro-82M/resolve/$REV"

    mkdir -p "$PROJECT/orioninsist/models"
    mkdir -p "$PROJECT/orioninsist/kokoro/voices"
    mkdir -p "$PROJECT/orioninsist/kokoro/spacy"

    curl --fail --location \
        --output "$PROJECT/orioninsist/models/base.pt" \
        "https://openaipublic.azureedge.net/main/whisper/models/ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt"

    curl --fail --location \
        --output "$PROJECT/orioninsist/kokoro/config.json" \
        "$BASE/config.json"

    curl --fail --location \
        --output "$PROJECT/orioninsist/kokoro/kokoro-v1_0.pth" \
        "$BASE/kokoro-v1_0.pth"

    curl --fail --location \
        --output "$PROJECT/orioninsist/kokoro/voices/af_heart.pt" \
        "$BASE/voices/af_heart.pt"

    curl --fail --location \
        --output "$PROJECT/orioninsist/kokoro/voices/am_michael.pt" \
        "$BASE/voices/am_michael.pt"

    curl --fail --location \
        --output "$PROJECT/orioninsist/kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl" \
        "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"

DIKKAT: Yukaridaki curl komutlari mevcut dosyalarin uzerine
yazabilir. Yalnizca bos bir kurulum dizininde kullanilmalidir.
Mevcut kurulumda calistirilmamalidir.

### SHA256 dogrulamasi

Indirme sonrasinda su komutla tum dosyalar kontrol edilir:

    cd /home/murat/Project/whisper
    sha256sum orioninsist/models/base.pt
    sha256sum orioninsist/kokoro/config.json
    sha256sum orioninsist/kokoro/kokoro-v1_0.pth
    sha256sum orioninsist/kokoro/voices/af_heart.pt
    sha256sum orioninsist/kokoro/voices/am_michael.pt
    sha256sum orioninsist/kokoro/spacy/en_core_web_sm-3.8.0-py3-none-any.whl

Beklenen SHA256 degerleri bu belgenin
"Yerel model dosyalari" bolumunde listelenmistir.

Whisper base.pt beklenen SHA256:

ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e

### Docker imajlarini yeniden olusturma

Once Whisper CPU imaji:

    docker build \
        -f Dockerfile \
        -t orioninsist/whisper:cpu-test \
        .

Ardindan Kokoro CPU imaji:

    docker buildx build \
        --build-context spacywheel=./orioninsist/kokoro/spacy \
        -f Dockerfile.kokoro \
        -t orioninsist/kokoro:rebuild-test \
        --load \
        .

Bu komutlar mevcut imajlari degistirebileceginden,
calisan sistemde yeniden derleme onaysiz yapilmamalidir.

Temiz ortamda yeniden derleme ve CLI testi henuz yapilmamistir.
