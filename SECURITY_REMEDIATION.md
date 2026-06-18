# Güvenlik Giderme Runbook'u — Sızdırılmış Kimlik Bilgileri

`example/lib/env/env.dart`, TTLock `clientId` / `clientSecret` ve hesap
`username` / `password` değerlerini yalnızca XOR (`^ 0x42`) ile gizlenmiş
şekilde tutuyordu. XOR önemsiz biçimde geri çevrilebilir; bu değerler
**git geçmişinde hâlâ mevcut** ve repo'yu klonlayan herkes çözebilir.

Dosya artık takipten çıkarıldı ve `.gitignore`'a eklendi (commit `a0a2a15`),
ancak bu **geçmişi temizlemez**. Tam giderme için aşağıdaki adımlar gerekir.

> ⚠️ **Bu adımları yalnızca repo sahibi çalıştırmalı.** 2. ve 3. adım git
> geçmişini yeniden yazar ve `--force` push gerektirir — geri alınamaz.

---

## Adım 1 — Kimlik bilgilerini YENİLE (en önemli, atlanamaz)

Geçmişte ifşa olan her şey "yanmış" sayılır; silmek yetmez, döndürmek şart.

1. **TTLock Open Platform konsolu** → uygulamanın `clientSecret`'ını yeniden
   üret (regenerate). Eski secret'ı iptal et.
2. **TTLock hesabının şifresini** değiştir (env.dart'taki hesap).
3. Yeni değerleri yerelde `example/lib/env/env.dart` dosyasına yaz
   (artık gitignore'da, commit'lenmez). Şablon: `example/lib/env/env.dart.example`.

Bu adım tamamlanmadan 2–3 yapmak yarım çözüm olur.

## Adım 2 — Dosyayı tüm geçmişten kaldır

İki seçenekten birini kullan. **git-filter-repo önerilir.**

### Seçenek A — git-filter-repo (önerilen)

```bash
# Kurulum (bir kez): brew install git-filter-repo   (veya pip install git-filter-repo)

# TEMİZ bir ayna klon üzerinde çalış (orijinali yedek olarak sakla):
cd /tmp
git clone --mirror https://github.com/KayraYavuz/Smart-Home-App.git
cd Smart-Home-App.git

# Dosyayı tüm commit'lerden sil:
git filter-repo --path example/lib/env/env.dart --invert-paths

# Uzak remote'u tekrar ekle (filter-repo onu kaldırır):
git remote add origin https://github.com/KayraYavuz/Smart-Home-App.git
```

### Seçenek B — BFG Repo-Cleaner

```bash
# bfg.jar indir: https://rtyley.github.io/bfg-repo-cleaner/
cd /tmp
git clone --mirror https://github.com/KayraYavuz/Smart-Home-App.git
cd Smart-Home-App.git
java -jar bfg.jar --delete-files env.dart
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Adım 3 — Yeniden yazılan geçmişi push'la

```bash
git push --force --all
git push --force --tags
```

> Bu, uzak geçmişi yeniden yazar. Repoyu klonlamış herkesin (CI dahil)
> eski klonu silip **yeniden klonlaması** gerekir; aksi halde silinen
> commit'leri geri push edebilirler.

## Adım 4 — Doğrula

```bash
# Dosya geçmişte hiç görünmemeli (boş çıktı = temiz):
git log --all --oneline -- example/lib/env/env.dart

# Secret string'i hiçbir commit'te kalmamalı:
git rev-list --all | xargs -I{} git grep -I "ttlockClientSecret" {} 2>/dev/null | head
```

## Sonrası — tekrar etmemesi için

- Gerçek sırlar için XOR yerine **build-time injection** (`--dart-define` /
  `--dart-define-from-file`) ya da bir secrets manager kullan.
- `git secrets` veya `gitleaks` gibi bir pre-commit kancası ekle.
- `env.dart` kalıcı olarak `.gitignore`'da — orada bırak.

---

*Bu runbook bir kılavuzdur; komutları sahibi çalıştırmalıdır. `--force` push
ve geçmiş yeniden yazımı geri alınamaz işlemlerdir.*
