# Açık Kaynak Proje Analizi: PocketBase (SecOps & Systems)

---

## GİRİŞ VE HEDEF
Bu çalışmada, "SecOps" ve "Sistem Mimarı" gözüyle gerçek dünya standartlarında bir açık kaynak projesi olan **PocketBase** incelenmiştir. Analiz; kurulumdan imha sürecine, CI/CD süreçlerinden kaynak kod analizine kadar hocamızın istediği 5 temel aşamada gerçekleştirilmiştir.

---

## 🛠️ Adım 1: Kurulum ve install.sh Analizi (Reverse Engineering)

PocketBase projesinin otomatik kurulum betiği (`install.sh`) incelenmiş ve sistemde gerçekleştirdiği işlemler analiz edilmiştir.

* **Bu dosya ne yapıyor?** Betik, Linux sistem mimarisini kontrol eder, uygun PocketBase sürümünü tespit eder ve dosyayı `/tmp` dizinine indirir.
* **Hangi dizinleri oluşturuyor ve yetki istiyor?** `/usr/local/bin` dizinine erişim talep eder ve kopyalama işlemi için `sudo` yetkisi ister. Çekilen binary dosyasına `chmod +x` ile çalıştırma yetkisi verir.

**Kritik Soru Cevabı:**
Yazılımın indirdiği kaynaklar (Resmi GitHub Releases) güvenlidir. Ancak betik içerisinde çekilen dosyanın **SHA-256 hash (imza) kontrolünün yapılmadığı** tespit edilmiştir. Yazılım doğrudan `curl | bash` mantığına yakın çalışmaktadır. Güvenlik açısından bu durum risklidir ve manuel hash kontrolü eklenmesi önerilir.

---

## 🧹 Adım 2: İzolasyon ve İz Bırakmadan Temizlik (Forensics & Cleanup)

**Görev:**
Kurulan PocketBase aracının sistemden hiçbir iz kalmayacak şekilde kaldırılması süreci simüle edilmiştir.

* **Sistemden Kaldırma Adımları:**
  1. Arka planda çalışan servis durdurulur: `sudo systemctl stop pocketbase`
  2. Ana binary dosyası silinir: `sudo rm /usr/local/bin/pocketbase`
  3. Veritabanı ve logların tutulduğu veri dizini temizlenir: `rm -rf ./pb_data`

**Kritik Soru Cevabı:**
Herhangi bir kayıt (log, kalıntı dosya, port vb.) kalmadığından emin olmak için şu adımlar uygulanarak ispat edilmiştir:
* **Port Kontrolü:** `netstat -tulnp | grep 8090` komutuyla PocketBase'in kullandığı varsayılan portun tamamen kapandığı doğrulanmıştır.
* **Log ve Kalıntı Kontrolü:** `/var/log` dizininde ve sistem servislerinde (`systemctl status pocketbase`) hiçbir kalıntı kalmadığı gözlemlenmiştir.
* **Tavsiye:** Bu işlemler sistem güvenliği ve izolasyon açısından sanal bir makinede (VM) gerçekleştirilmiştir.

---

## 🚀 Adım 3: İş Akışları ve CI/CD Pipeline Analizi (.github/workflows)

**Görev:**
PocketBase reposunda yer alan GitHub Actions (`release.yml`) CI/CD paketi incelenmiştir.

* **Adım Adım Ne Yapıyor?**
  1. Repo içerisindeki Go kodlarını derler ve testleri çalıştırır.
  2. Linux, Windows ve macOS için ayrı ayrı çalışabilir (binary) dosyalar üretir.
  3. Üretilen bu dosyaları otomatik olarak GitHub Releases kısmına yükler.

**Kritik Soru Cevabı:**
* **Webhook Nedir?** Webhook, bir sistemde (örneğin GitHub'da) bir olay gerçekleştiğinde (örneğin koda yeni bir güncelleme geldiğinde), başka bir sisteme (örneğin bizim sunucumuza) otomatik olarak gerçek zamanlı veri (HTTP POST isteği) gönderen bir mekanizmadır.
* **Bu Proje Özelinde Ne İşe Yarar?** Geliştirici ana koda yeni bir özellik ekleyip "push" yaptığında veya yeni bir versiyon etiketi (tag) oluşturduğunda, Webhook bu durumu CI/CD sistemine haber verir. Sistem de hiçbir insan müdahalesi olmadan otomatik olarak yeni sürümü derleyip yayına alır.


---

## 🐳 Adım 4: Docker Mimarisi ve Konteyner Güvenliği

**Görev:**
PocketBase projesinin Docker yapısı ve izolasyon mekanizmaları incelenmiştir.

**Kritik Soruların Cevapları:**
* **Docker İmajı Nedir ve Katmanları Nelerdir?** Docker imajı, bir uygulamanın çalışması için gereken her şeyi (kod, kütüphaneler, ortam değişkenleri) paketleyen hafif, bağımsız bir dosyadır. PocketBase imajı, resmi `alpine` Linux dağıtımı katmanının üzerine PocketBase binary dosyasının eklenmesiyle (katmanlandırılmasıyla) inşa edilir.
* **Konteyner Sistem İçinde Nerelere Erişebilir?** Konteynerler varsayılan olarak izoledir. PocketBase konteyneri sadece kendi içine bağlanan `/pb_data` dizinine ve dışarıya açtığı `8090` portuna erişebilir. Ana işletim sisteminin diğer kritik dosyalarına erişemez.
* **Ortamı En Güvenli Hale Nasıl Getirebiliriz?** PocketBase çalıştırılırken `root` kullanıcısı yerine yetkisiz bir kullanıcı (Non-root user) tanımlanarak güvenlik artırılabilir.
* **Kubernetes ve VM ile Farkı Nedir?** Sanal Makineler (VM) koca bir işletim sistemini simüle ettiği için çok ağırdır. Docker ise ana makinenin çekirdeğini (kernel) ortak kullanır, çok hafiftir. Kubernetes ise binlerce Docker konteynerini aynı anda yöneten, orkestra eden devasa bir sistemdir.

---

## 🕵️‍♂️ Adım 5: Kaynak Kod ve Akış Analizi (Threat Modeling)

**Görev:**
PocketBase uygulamasının başlangıç noktası (entrypoint) ve kimlik doğrulama (Authentication) yapısı kaynak kod seviyesinde incelenmiştir.

* **Başlangıç Noktası (Entrypoint):** Uygulamanın giriş noktası Go dilinde yazılmış olan `main.go` dosyasıdır.
* **Kimlik Doğrulama (Auth) Mekanizması:** PocketBase, kullanıcı ve admin doğrulamaları için **JWT (JSON Web Token)** mimarisini kullanmaktadır.

**Kritik Soruların Cevapları:**
* **Bir Hacker Verileri Nasıl Çalacağını Nasıl Bilir?** Hackerlar açık kaynaklı projelerin kodlarını inceleyerek veritabanı bağlantı şemalarını (schema), API endpoint'lerini ve zayıf yazılmış SQL sorgularını ararlar. PocketBase'de tüm endpoint'ler ve yetkilendirme kuralları (Rules) açıkça kodda yer alır.
* **Bu Auth Mekanizmasına D


---

## eXTRA  : Web Yazılım Güvenliği Analizi (#L1: The Broken Door)

Dersimizin kapsamı olan "Güvenli Web Yazılımı" çerçevesinde, 100.000 satırlık dev bir projede yapılabilecek tek satırlık bir kod hatasının (The Broken Door) nelere yol açabileceği simüle edilmiştir.

### 1. Güvensiz Kod Bloğu (Zafiyetli Durum)
Aşağıdaki backend kodunda, kullanıcının siparişlerini çeken endpoint'te token doğrulayan `if` bloğunun unutulduğu veya silindiği varsayılmıştır:

```javascript
// ZAFİYETLİ ENDPOINT (GÜVENSİZ YAZILIM)
app.get('/api/orders', (req, res) => {
    // KRİTİK HATA: Burada 'if (!isValidToken(req))' kontrolü unutulmuştur!
    const orders = database.getAllOrders(); 
    res.json(orders); // Herkese tüm veriyi döner!
});---

## 🛠️ Kurulum ve Test Süreci

Bu proje analiz edilirken aşağıdaki adımlar uygulanmıştır:

```bash
./pocketbase serve
```

* Sistem ayağa kaldırıldı
* Port 8090 aktif olarak gözlemlendi
* API endpoint’leri test edildi

---

## 🧹 Forensic Kanıtlar

Aşağıdaki komutlarla sistemde iz kalmadığı doğrulanmıştır:

```bash
netstat -tulnp | grep 8090
systemctl status pocketbase
```

Sonuç: Aktif port veya servis bulunmamıştır.

---

## 🐳 Docker Güvenlik Notları

* Container izolasyonu sağlanır
* Ancak root çalıştırılırsa risk oluşur

Öneri:

* Non-root user kullanılmalı
* Volume erişimleri sınırlandırılmalı

---

## 🧨 Threat Senaryosu

Eğer authentication kontrolü kaldırılırsa:

* Tüm kullanıcı verileri açığa çıkar
* API herkese açık hale gelir
* Veri ihlali oluşur

---

## 🔐 Güvenli Kod Örneği

```js
app.get('/api/orders', (req, res) => {
    if (!isValidToken(req)) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const userId = getUserFromToken(req);
    const orders = database.getOrdersByUser(userId);

    res.json(orders);
});
```

---



