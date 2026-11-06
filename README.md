# Oila Daraxti (Family Tree) — Flutter + Firebase

Oilangiz shajarasini yaratish, ko'rish va qarindoshlar bilan birga tahrirlash uchun mobil ilova.

## Imkoniyatlar

- **Kirish / ro'yxatdan o'tish** — Email va parol (Firebase Auth), parolni tiklash.
- **Bir nechta daraxt** — har bir foydalanuvchi o'z daraxtlarini yaratadi.
- **Ulashish** — daraxt kodini qarindoshlarga yuborasiz, ular qo'shilib birga tahrirlaydi.
- **Vizual daraxt** — avlodlar qator-qator, er-xotinlar qizil chiziq bilan, farzandlar ota-onasi ostida. Barmoq bilan surish va kattalashtirish mumkin.
- **Shaxs ma'lumotlari** — ism, familiya, jinsi, tug'ilgan/vafot sanasi, joyi, tarjimai hol.
- **Qarindoshlar avtomatik hisoblanadi** — ota-ona, turmush o'rtog'i, farzandlar, aka-uka/opa-singil, bobo-buvi, nevaralar.
- **Tez qo'shish** — shaxs sahifasidan bir tugma bilan ota, ona, turmush o'rtog'i yoki farzand qo'shish (bog'lanishlar o'zi o'rnatiladi).
- **Real vaqt** — Firestore orqali barcha qurilmalarda bir zumda yangilanadi.
- **Xavfsizlik** — Firestore qoidalari: faqat daraxt a'zolari ma'lumotni ko'radi va o'zgartiradi.

## Tez boshlash (avtomatik)

Kerak bo'ladi: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows), [Node.js](https://nodejs.org) va Google hisobi.

```bash
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Skript o'zi bajaradi:
1. `android/`, `ios/`, `web/` papkalarini yaratadi;
2. Android `minSdk` ni 23 ga qo'yadi;
3. paketlarni yuklaydi;
4. Firebase CLI va FlutterFire CLI ni o'rnatadi, Google hisobingizga kiradi;
5. `flutterfire configure` — Firebase loyihasini tanlaysiz/yaratasiz, `lib/firebase_options.dart` yoziladi;
6. Firestore bazasini yaratadi va `firestore.rules` ni joylaydi.

Yagona qo'lda qadam: Firebase konsolida **Authentication → Sign-in method → Email/Password → Enable**.

So'ng:

```bash
flutter run
```

## Loyiha tuzilmasi

```
lib/
  main.dart                      — Firebase ishga tushirish, mavzu
  firebase_options.dart          — flutterfire configure yozadi
  models/person.dart             — Shaxs modeli
  models/family_tree.dart        — Daraxt modeli
  services/auth_service.dart     — Kirish/ro'yxatdan o'tish
  services/tree_service.dart     — Firestore CRUD
  utils/relations.dart           — Qarindoshlikni hisoblash
  widgets/family_tree_view.dart  — Daraxtni joylashtirish va chizish
  widgets/person_card.dart       — Shaxs kartochkasi
  widgets/dialogs.dart           — Dialoglar, shaxs tanlash oynasi
  screens/                       — Ekranlar
firestore.rules                  — Xavfsizlik qoidalari
```

## Firestore ma'lumot tuzilmasi

```
trees/{treeId}
  name, description, ownerId, members: [uid...], createdAt
trees/{treeId}/persons/{personId}
  firstName, lastName, gender ('male'|'female'),
  birthDate, deathDate, birthPlace, bio,
  fatherId, motherId, spouseIds: [personId...]
```

## Testlar

```bash
flutter test
```
