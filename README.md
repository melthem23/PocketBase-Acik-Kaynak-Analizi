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
