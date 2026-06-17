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

### 本地生產環境部署（本地部署）
若您想在本地以生產環境（Production）模式運行並測試網頁，可選擇以下方式：

#### 方法一：使用 Docker 本地運行
1. **編譯網頁並建立 Docker 映像檔**：
   ```bash
   flutter build web
   docker build -t vroom-web:local .
   ```
2. **在本地執行容器**：
   ```bash
   docker run -d -p 8080:80 --name vroom-web vroom-web:local
   ```
   執行後，即可在瀏覽器開啟 [http://localhost:8080](http://localhost:8080) 訪問您的網頁。

#### 方法二：使用輕量級靜態伺服器
1. **編譯網頁**：
   ```bash
   flutter build web
   ```
2. **使用 Node.js 或 Python 啟動伺服器**：
   * **Python 3**：
     ```bash
     cd build/web
     python3 -m http.server 8080
     ```
   * **Node.js (npx)**：
     ```bash
     cd build/web
     npx http-server -p 8080
     ```
   啟動後，即可在瀏覽器開啟 [http://localhost:8080](http://localhost:8080) 進行測試。

### 💾 完全地端/離線部署（資料保存至本地資料夾）
如果您希望**完全在地端運行（不依賴 Firebase 雲端資料庫）**，且在**服務終止/關閉時將資料自動保存至地端資料夾**中，請依循以下步驟部署：

#### 1. 安裝 Firebase CLI 工具
本地資料庫與帳號驗證服務需要依靠 Firebase 本地模擬器（Firebase Emulator Suite）。請確保您的系統已安裝 Node.js，然後執行以下指令安裝工具：
```bash
npm install -g firebase-tools
```

#### 2. 啟動地端模擬伺服器並設定「自動存檔」
專案根目錄下已預先配置好模擬器設定檔 [firebase.json](file:///Users/gaoyouhan/Downloads/vroom_final/firebase.json)。使用以下指令啟動地端資料庫，並設定在終止時自動匯出資料：
```bash
firebase emulators:start --import=./emulator_data --export-on-exit=./emulator_data
```
* **`--import=./emulator_data`**：啟動服務時，自動從地端的 `emulator_data` 資料夾中載入上一次儲存的資料。
* **`--export-on-exit=./emulator_data`**：**核心設定**。當您在終端機按下 `Ctrl+C` 關閉/終止服務時，模擬器會自動將最新資料完整導出並寫入地端的 `emulator_data` 資料夾中。

#### 3. 運行前端網頁
您可以選擇以 Docker 或靜態伺服器等任何上述方法在本地啟動網頁（例如訪問 `http://localhost:8080`）。本專案的 `lib/main.dart` 中已寫入偵測邏輯：**當網頁運行在 `localhost` 時，會自動將資料庫及驗證的請求導向本地的模擬器服務**，無需手動更改程式設定。

#### 4. 管理與查看地端資料
啟動模擬器後，您可以在瀏覽器開啟 [http://localhost:4000](http://localhost:4000) 進入 Firebase Emulator Suite 的網頁後台，視覺化管理與檢視本地儲存的所有資料。

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

### ☁️ AWS ECS (Elastic Container Service) 部署
專案已打包成 Docker 映像檔並推送至 Docker Hub。您可以在 AWS ECS 服務（如 Fargate）中直接進行無伺服器容器託管部署：

1. **容器映像檔來源 (Image URL)**：
   ```text
   docker.io/halion0329/lemon:latest
   ```
2. **重要連接埠 (Port) 設定**：
   * **容器連接埠 (Container Port)**：請務必將 Container Port 設定為 **`80`** (以對應 Dockerfile 中的 Nginx Port)。
   * **負載平衡器 (ALB)**：設定 ALB 監聽器將流量導向 ECS 容器的 Port 80，以確保網頁能正常被外部存取。

### ☁️ Google Cloud Run 部署
專案亦支援直接部署至 Google Cloud Run。當您的 GCP 帳戶完成帳單（Billing）啟用與入帳後，可執行以下指令進行一鍵部署：

1. **確認已切換至目標專案**：
   ```bash
   gcloud config set project cke101-07
   ```
2. **執行部署指令**：
   ```bash
   gcloud run deploy lemon --source . --region asia-east1 --port 80 --allow-unauthenticated
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
