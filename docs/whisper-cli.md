# Whisper CLI Kullanımı

Fedora Linux üzerinde Docker ile çalışan yerel Whisper STT ve Kokoro TTS arayüzü.

## Yardım

    whisper --help

## TTS: Metinden ses oluşturma

    whisper tts "Merhaba dünya"
    whisper tts "Merhaba dünya" female
    whisper tts "Merhaba dünya" male ornek.wav

- Metin zorunludur.
- Ses seçenekleri: female ve male. Varsayılan female.
- Varsayılan dosya adı: speech.wav.
- Yalnızca .wav uzantılı dosya adı kabul edilir.
- Dosya adında / karakteri kullanılamaz.
- Mevcut çıktı dosyalarının üzerine yazılmaz.
- Başarılı işlemde çıktı dosyasının tam yolu gösterilir.

TTS çıktı dizini:

    /home/murat/Project/whisper/.local/outputs/

## STT: Ses ve videodan metin oluşturma

    whisper stt /dosya/yolu/ses.mp3
    whisper stt /dosya/yolu/ses.mp3 tr
    whisper stt /dosya/yolu/video.mp4 tr

- Giriş dosyası mevcut ve okunabilir olmalıdır.
- Dil isteğe bağlıdır; belirtilmezse Whisper dil algılar.
- Model: base (yerel base.pt).
- İşlemci: CPU.
- FP16: Kapalı.
- Çıktı biçimi: TXT.
- Her işlem için ayrı stt-XXXXXXXX dizini oluşturulur.
- Giriş dosyası çalışma dizinine kopyalanır.
- Metin sonucu input.txt dosyasına kaydedilir.
- Sonuç dosyasının yolu ve içeriği terminalde gösterilir.
- Çalışma dizini otomatik silinmez.

STT çıktı örneği:

    .local/outputs/stt-XXXXXXXX/input.txt

## Docker güvenliği

- Docker ağı kapalıdır.
- Konteyner kök dosya sistemi salt okunurdur.
- Linux yetenekleri kaldırılır.
- Yeni ayrıcalık kazanımı engellenir.
- SELinux güvenlik etiketi kullanılır.
- Modeller salt okunur bağlanır.
- Hugging Face çevrimdışı modu etkinleştirilir.
- İşlemler mevcut kullanıcı UID/GID ile çalışır.
- Geçici /tmp alanı tmpfs kullanır.

## Docker imajları

- TTS: orioninsist/kokoro:rebuild-test
- STT: orioninsist/whisper:local

## Yerel dizinler

- Whisper modelleri: .local/models/
- Kokoro modelleri: .local/kokoro/
- Çıktılar: .local/outputs/
- Kişisel dosyalar: orioninsist/

.local/ ve orioninsist/ Git tarafından yok sayılır.

## CLI konumu

- Kaynak: scripts/whisper-cli
- Komut bağlantısı: ~/.local/bin/whisper

## Mevcut sınırlamalar

- Proje yolu kaynak kodda sabittir.
- Docker imaj etiketleri sabittir.
- STT yalnızca base modelini kullanır.
- STT CPU üzerinde çalışır.
- STT çalışma dosyaları otomatik temizlenmez.
- CLI bağımsız ikili değil, Docker kullanan Bash arayüzüdür.
