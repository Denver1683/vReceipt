# 📜 vReceipt – Secure & Fraud-Proof Digital Receipt System

**vReceipt** is a **digital receipt system** designed to eliminate fraud, prevent unauthorized modifications, and enhance consumer protection. Built with **advanced encryption, intelligent QR security, and real-time verification**, vReceipt ensures **tamper-proof transactions** for both merchants and customers.

🚨 **Commercial use, redistribution, or unauthorized replication of this project is strictly prohibited.** 🚨

---

## 🔒 Why vReceipt is Different  
Unlike standard receipt apps, **vReceipt is built with advanced anti-fraud mechanisms** to prevent receipt duplication, unauthorized voiding, and fake merchant activities.

### 🛡 Key Anti-Fraud Features  
- **🔐 Secure QR Code System**  
  - QR codes are **generated with encryption, data encapsulation, and Firebase security keys**.  
  - Once scanned, the **QR code expires instantly**, preventing hijacking or unauthorized access.  
  - Receipts are permanently assigned to the scanning customer, preventing **fraudulent duplication**.  

- **⛔ Receipt Voiding Security**  
  - Merchants **cannot void receipts unless the customer deletes them first**.  
  - Eliminates **secret voiding scams** where merchants cancel purchases behind customers’ backs.  

- **📍 Merchant Verification & Dynamic Updates**  
  - **ID/passport verification is required** to register a merchant account (**one ID per shop**).  
  - **Shops cannot be duplicated** under the same ID, preventing fraud.  
  - If a merchant **changes their shop details**, the **receipt in the customer’s app remains unchanged**.  
  - A **capsule UI (like Apple’s Dynamic Island)** updates **real-time merchant info**, while maintaining historical accuracy.  

- **🗺️ Merchant Finder Feature**  
  - Customers can **locate the nearest vReceipt merchants**, ensuring they shop at **verified stores**.  
  - Provides **operating hours, address, phone number, email, and navigation assistance**.  

- **🛑 Admin Control & Fraud Monitoring**  
  - **Admins can suspend/unsuspend merchant and customer accounts** if fraudulent activity is detected.  
  - Ensures a **secure and scam-free environment** for all users.  

---

## 🛒 The vReceipt Ecosystem  
vReceipt consists of **three interconnected apps**, each designed for a specific role:

### 📌 1️⃣ vReceipt Merchant (Full POS System)  
For business owners, this app **acts as a complete POS (Point of Sale) system** with full transaction and stock control.

💰 **Key Features**:  
- **Stock Management** – Manage inventory in real-time.  
- **Product Barcode Scanning** – Automates product entry for quick checkout.  
- **Secure Transaction Processing** – Generates tamper-proof receipts via vReceipt’s QR system.  
- **Sales Reports & Analytics** – Provides revenue tracking and product performance insights, and also top spender ranking.  
- **Fraud-Proof Receipt Voiding** – Ensures merchants cannot void receipts without customer action.  
- **Business Profile Management** – Merchants can update **profile details, contact details, operating hours, tax and/or service charge, and descriptions** (but **cannot modify ID verification**).  

---

### 📌 2️⃣ vReceipt Customer App  
For consumers, this app **manages all digital receipts securely** while offering spending insights.

🛍 **Key Features**:  
- **Search, Sort, & Filter** – Quickly find receipts by **date, merchant, product, or price range**.  
- **Favorite Receipts** – Mark important receipts for quick access, bringing them to the first page regardless of the sort implemented.  
- **Expense Analytics** – Get a breakdown of monthly spending habits.  
- **Warranty Reminders** – **Hybrid notification system** ensures users don’t miss warranty periods while it still can sync when it's online. This ensures that all the customer's device can sync their reminder while also delivering the reminder in time, even when the device is offline.  
- **Merchant Finder** – Locate **verified** vReceipt merchants near you, and help you to fetch details and navigation in case needed.  

---

### 📌 3️⃣ vReceipt Admin App  
The **Admin App** ensures the security and integrity of the vReceipt platform.

🔍 **Admin Control Features**:  
- **Merchant Verification** – Confirms business legitimacy before approval.  
- **Fraud Detection & Moderation** – Allows **blocking/unblocking** of suspicious accounts.  

---

## 📥 How to Use vReceipt  
### **Option 1: Install the APK (Easiest Method)**  
- Download the APK from the `apk-files` branch and install it on your device.

### **Option 2: Compile the Flutter Projects Manually**  
1. Clone the repository and download the respective branches:

| Branch Name       | Folder Name          |
|------------------|---------------------|
| `admin-app`      | `vreceipt_admin`     |
| `customer-app`   | `vreceipt_customer`  |
| `merchant-app`   | `vreceipt_merchant`  |

2. Open the folders in **Android Studio** and run them using Flutter.

🚨 **Note:** To build the app manually, you must set up your **own Firebase credentials** due to security reasons. Installing the prebuilt APK is recommended.

---

## 📌 Future Enhancements (Planned Improvements)  
We are constantly improving vReceipt to provide even **stronger security, smoother user experience, and better integrations**.

### 🔹 End-to-End Encryption (E2EE) for Offline Transactions  
- **Replacing Firebase key fetching with true E2EE**, making transactions **even more secure**.  
- **Receipts can be transferred and stored offline securely** without an internet connection.  

### 🔹 NFC Support for Faster & Safer Transactions  
- Instead of scanning QR codes, **vReceipt will support NFC tap-to-receive receipts**.  
- **Eliminates the risk of QR code hijacking** and makes transactions **even faster and more secure**.  

### 🔹 UI/UX Enhancements  
- Improved design, better navigation, and smoother animations. While ensuring to maintain the current UI goal of clean and functional. 

### 🔹 Integration with Payment Systems (QR & NFC Payments)  
- **Direct integration with payment platforms** like:  
  - **SGQR** (Singapore’s unified QR payment system)  
  - **QRIS** (Indonesia’s QR payment standard)  
  - **Other international payment standards**  
- This means **users won’t need to scan twice** (once for payment and once for receipt).  
- vReceipt will **automatically fetch transaction details from payment QR scans**.  

---

## 📜 Terms of Use – No Commercial Use Allowed  
🚨 **vReceipt is strictly for educational and personal portfolio use.** 🚨  

- **Commercial use, resale, or redistribution of this project is strictly prohibited.**  
- **Unauthorized modifications for financial gain are not allowed.**  
- **Any attempts to bypass security mechanisms or exploit vulnerabilities will result in legal action.**  

---

## 💡 Why vReceipt Stands Out  
- ✅ **Tamper-Proof Receipts** – Advanced encryption ensures receipts **cannot be modified or forged**.  
- ✅ **No Secret Voiding** – Prevents merchants from canceling receipts behind a customer’s back.  
- ✅ **Merchant Accountability** – Stops scam shops from gaming the system.  
- ✅ **User-Friendly & Secure** – A **single platform** for businesses and consumers to transact safely.  
- ✅ **Eco-Friendly** – Reduces paper waste (SDG 13), promoting digital transactions.  

---

## 📜 Conclusion  
vReceipt is **not just another receipt storage app**—it’s a **fraud-resistant, encrypted transaction system** that ensures **secure, transparent, and verifiable** receipts. With upcoming **E2EE, NFC support, and direct payment system integration**, vReceipt will make **fraud-proof digital transactions the new standard**.  

🚀 **Join the future of secure receipts with vReceipt today!**  
