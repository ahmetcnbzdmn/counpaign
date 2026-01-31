# iOS Build Çözüm Adımları

## Durum
- Xcode 26.2 kullanılıyor
- Flutter 3.38.7 kullanılıyor  
- **Sorun:** gRPC-Core ve BoringSSL-GRPC paketleri Xcode 26.2 ile uyumsuz

## Önerilen Çözüm: Firebase Paketlerini Güncelle

Firebase paketleri çok eski (2.x versiyonları). Xcode 26 için yeni versiyonlar gerekiyor.

### Adım 1: pubspec.yaml'ı Güncelle

```yaml
# Eski versiyonlar (ŞU AN)
firebase_core: ^2.32.0
firebase_auth: ^4.16.1
cloud_firestore: ^4.17.5

# Yeni versiyonlar (GÜNCEL)
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
```

### Adım 2: Komutları Çalıştır

```bash
# 1. Paketleri güncelle
flutter pub upgrade

# 2. iOS bağımlılıklarını temizle
cd ios
rm -rf Pods Podfile.lock
pod install
./fix_pods.sh

# 3. Build et
cd ..
flutter clean
flutter run --device-id 00008110-001A55223C39801E
```

## Alternatif: Xcode Downgrade (Daha Uzun Sürer)

Eğer Firebase güncellemesi işe yaramazsa:
1. https://developer.apple.com/download/all/ adresinden Xcode 15.4 indir
2. Xcode.app'i Xcode-15.4.app olarak yeniden adlandır
3. `sudo xcode-select -s /Applications/Xcode-15.4.app/Contents/Developer`
