## vReceipt

**Secure. Transparent. Tamper-Proof.**
*The Land Cruiser 70 of fraud prevention platforms — overbuilt, field-tested, and designed for real-world deployment.*

**🚨 Commercial use, redistribution, or unauthorized replication of this project is strictly prohibited. 🚨**

---

## What is vReceipt?

**vReceipt** is a security-first, fraud-resistant receipt infrastructure designed for environments where integrity, traceability, and auditability are non-negotiable.

Originally built as a final year project, vReceipt exceeds academic expectations with:

* **AES encryption**
* **Cross-device syncing**
* **Mutual-consent voiding logic**
* **Offline usability**
* **Built-in moderation tools**

Ideal for **fintech**, **point-of-sale**, **government tax tracking**, and **public-sector transparency**, vReceipt wasn't built for the classroom.

> It was built for the wild.

---

## 🏦 The vReceipt Ecosystem

vReceipt is built on **three integrated apps**, each with a specialized role:

### 1️⃣ vReceipt Merchant (Full POS System)

For business owners, this app functions as a complete POS with full transaction and inventory control.

#### 💰 Key Features:

* **Stock Management** — Real-time inventory control
* **Barcode Scanning** — Quick product entry and checkout
* **Secure Transactions** — Tamper-proof QR-based receipts
* **Sales Analytics** — Revenue insights, top spender reports
* **Receipt Voiding Control** — Requires customer initiation
* **Business Profile Control** — Editable metadata (non-ID fields only)
* **Manual Receipt Delivery via Email Lookup** - Deliver receipt right into customer's app by inputting customer's registered email

### 2️⃣ vReceipt Customer App

Secure digital receipt management and spending insights for consumers.

#### 🍪 Key Features:

* **Smart Filters** — Search receipts by date, merchant, or price
* **Favorites** — Pin important receipts for quick access
* **Expense Analytics** — Monthly spending trends
* **Warranty Reminders** — Offline-tolerant sync with notifications
* **Merchant Finder** — Nearby merchant lookup with navigation

### 3️⃣ vReceipt Admin App

Ensures integrity, trust, and regulatory compliance platform-wide.

#### 🔍 Key Features:

* **Merchant Verification** — ID/passport validation
* **Moderation Controls** — Ban/unban accounts, detect fraud

---

## Core Features

### 1. Encrypted Receipt Storage

* **Benefit:** Protects transaction data from unauthorized access.
* **Tech:** AES-256 with per-user key isolation; tamper-resistant by design.
* * **Why It’s Important:**
	•	Ensures safe receipt transfer
	•	Maintains data integrity

### 2. Fraud Prevention Architecture

* **Benefit:** Detects duplicate or manipulated transactions.
* **Tech:** UUID chains link receipts and prevent unauthorized edits. Receipts are merchant-generated and immutable.
* * **Why It’s Important:**
	• Ensures data credibility of both customer and merchant

### 3. Mutual Consent Voiding

* **Benefit:** Prevents secret cancellation; builds trust.
* **Tech:** Customer must delete first before merchant can void; voided receipts are kept for audits.
* * **Why It’s Important:**
	• Ensures that merchant can't silently void transactions
	• Prevents warranty claim dismiss by false claiming purchase date


### 4. Cross-Device Notification Sync

* **Benefit:** Full multi-device awareness with accurate sync.
* **Tech:** Offline queuing with eventual consistency; ensures reliable delivery.
* * **Why It’s Important:**
	•	Ensures that customers won't miss their warranty reminder, even when offline
	• Increases app's consistency through devices

### 5. Built-In Moderation

* **Benefit:** Keeps the ecosystem clean and compliant.
* **Tech:** Admins can take direct action against violations.
* * **Why It’s Important:**
	• Prevents fraud happening in the platform
	• Gives legal authorities a control

### 6. Merchant Discovery

* **Benefit:** Boosts user convenience & merchant exposure.
* **Tech:** GPS-based discovery of verified shops.
* * **Why It’s Important:**
	• Gives publication benefit for merchants
	• Helps customers to locate merchants
	•	Increases customers' trust to merchants

### 7. Merchant Verification & Dynamic Updates

* One merchant/shop per unique ID
* Real-time info updates via capsule UI without altering receipt history
* * **Why It’s Important:**
	•	Prevents fake merchants to popup
	• Prevents scam / enhancing transaction safety

### 8. Manual Receipt Delivery via Email Lookup
* **Benefit:** Allows merchants to deliver receipts even if the customer isn’t physically present — great for phone orders, late entry, or follow-ups.
* **How It Works:** The merchant can manually enter a customer’s registered email, and the receipt will appear directly in the vReceipt Customer App, not the inbox.
* **Why It’s Important:**
	•	Supports remote or non-synchronous purchases
	•	Maintains privacy (no sending sensitive data via email)
	•	Ensures that customer can get receipt even without having their phone in hand
---

## ✨ Why It’s Different

* Tamper-proof by design
* Fraud-resistant by architecture
* Auditor-friendly by principle

It assumes:

* Users might collude
* Merchants might lie
* Systems might go offline

And it's **built to survive all three**.

---

## 📊 Use Cases

* Fintech platforms
* POS terminals with offline mode
* Government-led transparency platforms
* Expense tracking and anti-fraud systems

---

## 🛂 How to Use vReceipt

### Option 1: Prebuilt APK

* Download from `apk-files` branch

### Option 2: Compile via Flutter

| Branch         | Folder Name         |
| -------------- | ------------------- |
| `admin-app`    | `vreceipt_admin`    |
| `customer-app` | `vreceipt_customer` |
| `merchant-app` | `vreceipt_merchant` |

> ⚠️ **Note:** You'll need your own Firebase credentials to build manually. Use the APK for simplicity.

---

## 🚀 Future Enhancements

* **End-to-End Encryption (E2EE):** Offline-safe secure syncing
* **NFC Tap Support:** Faster, more secure receipt exchange
* **Integrated Payment Support:** QRIS / SGQR / Contactless syncing
* **Improved UI/UX:** Functional, responsive, clean
* **Analytics Dashboard:** Merchant insights
* **Tax Reporting Integration:** For government portals
* **Multi-language Support:** Global-ready
* **3rd Party API:** Connect vReceipt to other platforms

---

## 📃 Terms of Use

This is a **non-commercial, personal portfolio project only.**

* No resale, redistribution, or modification for profit
* Do not bypass or tamper with security systems

---

## 🌟 Why vReceipt Stands Out

* ✅ **Tamper-Proof**: Advanced encryption prevents forgeries
* ✅ **No Secret Voiding**: Voiding requires user consent
* ✅ **Auditor-Ready**: Historical traceability built-in
* ✅ **User-Friendly**: Clear UI for both sides of the transaction
* ✅ **Eco-Friendly**: Paperless receipt system

---

## 📆 Conclusion

**vReceipt** isn’t just a digital receipt system. It’s a production-ready, real-world fraud prevention framework. With E2EE, NFC, and integrated payment flows on the roadmap, it aims to make **secure, traceable digital transactions the standard.**

> 🚀 Join the future of secure receipts with **vReceipt**.

---

## Author

**Built by Denver Alfito Anggada**
*A builder who doesn’t check boxes — he writes them.*
