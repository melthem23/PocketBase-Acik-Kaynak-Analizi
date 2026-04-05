# Açık Kaynak Proje Analizi: PocketBase (SecOps & Systems)

**Öğrenci Adı:** Meltem Eser  
**Seçilen Repo:** PocketBase (Kategori 4 - Platformlar ve Hizmet Olarak Backend)

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
