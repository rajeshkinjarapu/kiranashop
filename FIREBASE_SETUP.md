# Firebase Setup Guide — Kirana Shop

App backend: **Cloud Firestore + Firebase Storage** (Firebase Auth వాడటం లేదు — simple login).

## Login System (OTP లేదు)

- **Admin**: Login page → Admin tab → username `rajeshkinjarapu` / password `kallu0305`
  (మార్చాలంటే `lib/providers/auth_provider.dart` లో `_adminUsername`, `_adminPassword`)
- **Member**: Login page → mobile number → Login. Number register కాకపోతే
  Register page కి వెళ్తుంది (Full Name + Mobile Number మాత్రమే).
- Login session device లో save అవుతుంది (మళ్ళీ open చేసినా logout అవ్వదు).

## Console Setup (2 పనులు మాత్రమే)

### 1. Firestore Database

1. https://console.firebase.google.com/project/kirana-shop-f2406/firestore → **Create database**
2. **Production mode** → Location: `asia-south1 (Mumbai)` → Enable
3. **Rules** tab → `firestore.rules` (repo root) content paste → **Publish**

### 2. Storage

1. https://console.firebase.google.com/project/kirana-shop-f2406/storage → **Get started** → Production mode → Done
2. **Rules** tab → `storage.rules` content paste → **Publish**

## Run

```bash
flutter run -d chrome        # web (ఇప్పుడు ఇదే వాడుతున్నాం)
```

Android APK కావాలంటే Android Studio install చేసి `flutter build apk` —
`android/app/google-services.json` + gradle wiring ఇప్పుడే ready ఉంది.

## Security Note

Mobile-number-only login లో Firebase Auth లేదు కాబట్టి Firestore/Storage rules
open గా ఉన్నాయి (`if true`). Testing మరియు చిన్న shop కు సరిపోతుంది; పెద్దగా
వాడాలంటే తర్వాత Firebase Auth add చేయాలి.

## Firestore Structure

```
users/{id}               — { name, phone, role: "member", createdAt }
  └─ addresses/{id}      — { label, line1, line2, landmark, pincode, isDefault }
products/{id}            — { name, description, categoryId, categoryName, price,
                             unit, imageUrl, stockQty, inStock, isFeatured, isActive, createdAt }
categories/{id}          — { name, imageUrl, sortOrder, isActive }
orders/{id}              — { userId, customerName, customerPhone, address,
                             fulfillmentType, paymentMethod, items[], subtotal,
                             deliveryCharge, total, status, createdAt }
offers/{id}              — { title, subtitle, imageUrl, isActive }
settings/shop            — { shopName, logoUrl, address, phone, deliveryCharge,
                             minimumOrder, upiId, isOpen }
```

## Seed Data (Admin login తర్వాత)

**Products → Categories icon**: Grocery(0), Rice & Grains(1), Dairy(2), Snacks(3),
Beverages(4), Personal Care(5), Household(6). తర్వాత products add చేసి,
**Settings** లో shop details fill చేయండి.
