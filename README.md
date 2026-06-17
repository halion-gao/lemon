# Vroom 管理系統

一個基於 Flutter 與 Firebase 的跨平台管理系統，主要提供**賽車機板維修管理**、**餐飲與零件庫存管理（含二維碼掃描）**，以及**營運與維修報表分析**。

本專案已支援 **Flutter Web (網頁版)**，可在瀏覽器上流暢運行，並針對網頁端的使用場景進行了深度效能與介面優化。

---

## 🚀 功能特點

### 1. 🔧 機板維修管理
* 追蹤所有賽車機板的維修歷史與妥善率。
* 登記機板送修、完修更換零件、延長保固與報廢流程。

### 2. 📦 庫存管理（支援 QR Code 與條碼）
* 商品與零件的即時庫存清單。
* 透過裝置相機或手動輸入/外接掃描槍，快速為特定條碼執行進貨（+1）或出貨（-1）操作。
* 自動產生各品項專屬的 QR Code 條碼圖案供貼紙列印。

### 3. 📈 營運與維修報表
* 機板妥善率分析圖表（圓餅圖，即時呈現正常與維修中比例）。
* 庫存變動趨勢圖表（折線圖，可切換查看每週或每月之每日進出貨淨變動量）。

---

## 🛠️ Web 版專屬優化項目

1. **Firestore 串流複用 (Stream Multiplexing)**: 
   優化了機板列表頁面，將原本三個頁籤獨立建立的 Firestore 監聽器合併為單一資料流，在記憶體中進行分流篩選，**大幅減少 66% 的 Firestore 讀取次數**，節省資料庫成本。
2. **響應式網頁佈局 (RWD)**:
   主選單採用自適應網格卡片設計。在寬螢幕（電腦/平板）下呈現精美並排的三欄式資訊看板，在窄螢幕（手機）下自動切換為好點擊的垂直卡片。
3. **輸入備援與外接掃描槍支援**:
   在掃描頁面底部新增了「手動輸入/掃描槍」欄位，方便在沒有相機的桌機上直接打字，或者使用 USB/藍牙條碼掃描槍直接刷條碼輸入。
4. **記憶體洩漏防護**:
   全面修復並重構了文字輸入控制器（`TextEditingController`），確保在頁面與對話框關閉時確實調用 `dispose()` 釋放資源。
5. **資料覆蓋防護**:
   在庫存管理新增商品時，加入條碼重疊檢查機制，防止因輸入相同條碼而誤將已存在的庫存品項數量清空重置。

---

## 📦 網頁版執行與部署指南

### 本地開發與測試
在專案根目錄下，使用 Chrome 執行開發伺服器：
```bash
flutter run -d chrome --web-port 8080
```

### 生產環境編譯
將專案打包成最佳化後的靜態網頁資源：
```bash
flutter build web
```
編譯完成後，請將 `build/web/` 資料夾內的所有檔案上傳至您的網頁代管空間（例如 Firebase Hosting, Github Pages, Netlify 等）。

### 🐳 Docker 容器化與部署
專案內已提供 [Dockerfile](file:///Users/gaoyouhan/Downloads/vroom_final/Dockerfile)，您可透過 Docker 將專案打包成網頁伺服器，並快速部署至雲端虛擬機 (VM)：

1. **打包 Docker 映像檔**：
   ```bash
   docker build -t halion0329/lemon:latest .
   ```
2. **推送至 Docker Hub**：
   ```bash
   docker push halion0329/lemon:latest
   ```
3. **在目標虛擬主機上部署並啟動**：
   ```bash
   docker run -d -p 80:80 --name lemon halion0329/lemon:latest
   ```

### ⚠️ Firebase Web 設定步驟
網頁版需要特定的 Web 端 SDK 設定。
1. 開啟 [Firebase Console](https://console.firebase.google.com/)。
2. 進入專案「vroom-app-6a2df」，於專案設定中新增 **Web 應用程式** (</>)。
3. 取得您的 Web 設定參數後，開啟 `lib/main.dart`。
4. 將 `kIsWeb` 區塊中的 `YOUR_WEB_API_KEY` 與 `YOUR_WEB_APP_ID` 替換成您的真實金鑰即可：
   ```dart
   if (kIsWeb) {
     await Firebase.initializeApp(
       options: const FirebaseOptions(
         apiKey: '您的_WEB_API_KEY',
         appId: '您的_WEB_APP_ID',
         // ... 其它欄位已預先帶入
       ),
     );
   }
   ```
