# 🚀 Flutter Projesini VS Code'da Çalıştırma Kılavuzu

Bu kılavuz, Flutter projesini VS Code'da yükleyip çalıştırmak için gereken tüm adımları içerir.

---

## 📋 Gereksinimler

### 1. Flutter SDK Kurulumu

1. **Flutter'ı İndirin:**
   - https://flutter.dev/docs/get-started/install adresine gidin
   - İşletim sisteminize uygun Flutter SDK'yı indirin (Windows/Linux/macOS)

2. **Flutter'ı Kurun:**
   - İndirdiğiniz ZIP dosyasını açın
   - Flutter klasörünü istediğiniz bir yere taşıyın (örn: `C:\flutter` veya `~/flutter`)

3. **PATH'e Ekleyin:**
   - **Windows:**
     - Sistem değişkenlerine gidin
     - `Path` değişkenine Flutter'ın `bin` klasörünü ekleyin (örn: `C:\flutter\bin`)
   - **Linux/macOS:**
     - Terminal'de şu komutu çalıştırın:
     ```bash
     export PATH="$PATH:[FLUTTER_KLASORU]/bin"
     ```
     - Kalıcı yapmak için `~/.bashrc` veya `~/.zshrc` dosyasına ekleyin

4. **Kurulumu Kontrol Edin:**
   - Terminal/PowerShell'de şu komutu çalıştırın:
   ```bash
   flutter doctor
   ```
   - Tüm kontrollerin ✅ olması gerekiyor
   - Eksik olanları kurun (Android Studio, VS Code extension vb.)

---

## 🔧 VS Code Kurulumu

### 1. VS Code'u İndirin ve Kurun

- https://code.visualstudio.com/ adresinden VS Code'u indirin
- Kurulumu tamamlayın

### 2. Flutter Extension'ını Yükleyin

1. VS Code'u açın
2. Sol taraftaki **Extensions** (Uzantılar) ikonuna tıklayın (veya `Ctrl+Shift+X`)
3. Arama kutusuna **"Flutter"** yazın
4. **Flutter** extension'ını bulun (Google tarafından geliştirilmiş)
5. **Install** (Yükle) butonuna tıklayın
6. Yükleme tamamlandıktan sonra VS Code'u yeniden başlatın

**Not:** Flutter extension'ı Dart extension'ını da otomatik olarak yükler.

---

## 📥 Projeyi VS Code'da Açma

### 1. Projeyi İndirin

- Projeyi GitHub'dan ZIP olarak indirin veya Git ile klonlayın:
  ```bash
  git clone https://github.com/bukkitcraft/kutuphane_masaustu.git
  ```

### 2. VS Code'da Açın

1. VS Code'u açın
2. **File > Open Folder** (Dosya > Klasör Aç) menüsüne tıklayın
3. İndirdiğiniz proje klasörünü seçin
4. **Select Folder** (Klasör Seç) butonuna tıklayın

---

## 📦 Bağımlılıkları Yükleme

Projeyi açtıktan sonra, VS Code otomatik olarak bağımlılıkları yüklemenizi önerebilir. Eğer önermezse:

1. VS Code'da terminal açın:
   - **Terminal > New Terminal** (Terminal > Yeni Terminal) veya `Ctrl+`` (backtick)
   
2. Terminal'de şu komutu çalıştırın:
   ```bash
   flutter pub get
   ```
   
3. Bağımlılıklar yüklenene kadar bekleyin (birkaç dakika sürebilir)

---

## 🖥️ Projeyi Çalıştırma

### 1. Cihaz Seçimi

1. VS Code'un alt kısmındaki durum çubuğunda cihaz seçiciyi bulun
2. Tıklayın ve çalıştırmak istediğiniz platformu seçin:
   - **Windows** (Windows için)
   - **Linux** (Linux için)
   - **macOS** (macOS için)

**Not:** İlk kez desktop platformu için çalıştırıyorsanız, Flutter otomatik olarak gerekli ayarları yapacaktır.

### 2. Çalıştırma

**Yöntem 1: F5 Tuşu (En Kolay)**
- `F5` tuşuna basın
- VS Code otomatik olarak projeyi çalıştıracaktır

**Yöntem 2: Menüden**
- **Run > Start Debugging** (Çalıştır > Hata Ayıklamayı Başlat) menüsüne tıklayın

**Yöntem 3: Terminal'den**
- Terminal'de şu komutu çalıştırın:
  ```bash
  flutter run -d windows    # Windows için
  flutter run -d linux       # Linux için
  flutter run -d macos       # macOS için
  ```

### 3. İlk Çalıştırma

- İlk çalıştırmada Flutter bağımlılıkları indirecek ve build yapacak
- Bu işlem 5-10 dakika sürebilir (internet hızınıza bağlı)
- Sonraki çalıştırmalarda çok daha hızlı olacaktır

---

## 🔥 Hot Reload (Hızlı Yenileme)

Kod değişikliği yaptıktan sonra uygulamayı yeniden başlatmadan değişiklikleri görmek için:

1. **Terminal'de `r` tuşuna basın** (uygulama çalışırken)
2. Veya VS Code'un üst kısmındaki **Hot Reload** butonuna tıklayın

**Not:** Hot reload, state'i korur. Eğer uygulamayı sıfırdan başlatmak isterseniz terminal'de `R` (büyük R) tuşuna basın.

---

## 🐛 Hata Ayıklama (Debugging)

### Breakpoint Koyma

1. Kod satırının solundaki boşluğa tıklayın (kırmızı nokta görünecek)
2. `F5` ile çalıştırın
3. Kod o satıra geldiğinde durur
4. Değişkenlerin değerlerini görebilirsiniz

### Debug Console

- VS Code'un alt kısmındaki **Debug Console** sekmesinde hata mesajlarını görebilirsiniz
- `print()` ile yazdırdığınız mesajlar burada görünür

---

## ⚠️ Sık Karşılaşılan Sorunlar

### 1. "Flutter command not found" Hatası

**Çözüm:**
- Flutter'ın PATH'e eklendiğinden emin olun
- Terminal'i kapatıp yeniden açın
- VS Code'u kapatıp yeniden açın

### 2. "No devices found" Hatası

**Çözüm:**
- Desktop platform desteğini etkinleştirin:
  ```bash
  flutter config --enable-windows-desktop   # Windows için
  flutter config --enable-linux-desktop     # Linux için
  flutter config --enable-macos-desktop     # macOS için
  ```

### 3. "Pub get failed" Hatası

**Çözüm:**
- İnternet bağlantınızı kontrol edin
- Terminal'de şu komutları sırayla çalıştırın:
  ```bash
  flutter clean
  flutter pub get
  ```

### 4. Build Hataları

**Çözüm:**
- Flutter'ı güncelleyin:
  ```bash
  flutter upgrade
  ```
- Projeyi temizleyin:
  ```bash
  flutter clean
  flutter pub get
  ```

---

## 📝 Özet: Hızlı Başlangıç

1. ✅ Flutter SDK'yı kurun ve PATH'e ekleyin
2. ✅ VS Code'u kurun ve Flutter extension'ını yükleyin
3. ✅ Projeyi VS Code'da açın
4. ✅ Terminal'de `flutter pub get` çalıştırın
5. ✅ `F5` tuşuna basın ve uygulamayı çalıştırın

---

## 🎉 Başarılı!

Artık Flutter projenizi VS Code'da çalıştırabilirsiniz! 

**İpuçları:**
- Kod değişikliği yaptıktan sonra terminal'de `r` tuşuna basarak hot reload yapın
- Hata ayıklamak için breakpoint koyun ve `F5` ile çalıştırın
- VS Code'un sağ alt köşesindeki cihaz seçici ile platform değiştirebilirsiniz

**Sorun mu yaşıyorsunuz?**
- `flutter doctor` komutunu çalıştırıp eksikleri kontrol edin
- VS Code'un Output panelinde hata mesajlarını kontrol edin (View > Output)

---

**Not:** Bu kılavuz, projeyi çalıştırmak için gereken minimum bilgileri içerir. Daha fazla bilgi için [Flutter Resmi Dokümantasyonu](https://flutter.dev/docs)'na bakabilirsiniz.

