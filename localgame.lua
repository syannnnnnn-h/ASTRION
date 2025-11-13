-- ============================================================
-- ASTRIONHUB ROUTES DATABASE
-- File: localgame.lua
-- Purpose: Central database untuk semua game routes
-- ============================================================

return {
    -- ========================================
    -- KOTA BUKAN GUNUNG
    -- ========================================
    ["108523862114142"] = {
        name = "KOTA BUKAN GUNUNG",
        url = "https://raw.githubusercontent.com/syannnnnnn-h/ASTRION/refs/heads/main/JSON/KBG.json",
        description = "Auto route untuk Kota Bukan Gunung",
        lastUpdated = "2025-01-15",
        author = "Astrion Team"
    },
    
    -- ========================================
    -- MOUNT YAGESYA
    -- ========================================
    ["82748630433642"] = {
        name = "MOUNT YAGESYA",
        url = "https://raw.githubusercontent.com/syannnnnnn-h/ASTRION/refs/heads/main/JSON/YAGESYA.json",
        description = "Auto route untuk Mount Yagesya",
        lastUpdated = "2025-01-15",
        author = "Astrion Team"
    },
    
    -- ========================================
    -- TEMPLATE UNTUK MENAMBAH GAME BARU
    -- ========================================
    -- Copy template dibawah dan ganti dengan data game baru:
    --
    -- ["PLACE_ID_GAME"] = {
    --     name = "NAMA GAME",
    --     url = "https://raw.githubusercontent.com/USERNAME/REPO/main/JSON/FILENAME.json",
    --     description = "Deskripsi singkat route ini",
    --     lastUpdated = "YYYY-MM-DD",
    --     author = "Nama Author"
    -- },
    
    -- ========================================
    -- CONTOH GAME BARU (TEMPLATE)
    -- ========================================
    -- ["123456789"] = {
    --     name = "GAME BARU EXAMPLE",
    --     url = "https://raw.githubusercontent.com/syannnnnnn-h/ASTRION/refs/heads/main/JSON/EXAMPLE.json",
    --     description = "Auto route untuk game example",
    --     lastUpdated = "2025-01-15",
    --     author = "Your Name"
    -- },
    
    -- ========================================
    -- NOTES UNTUK DEVELOPER
    -- ========================================
    -- 1. PlaceId harus dalam format STRING (pakai quotes "")
    -- 2. URL harus mengarah ke raw JSON file
    -- 3. JSON route file harus berisi array of frames dengan struktur:
    --    {
    --      time = number,
    --      position = {x = number, y = number, z = number},
    --      velocity = {x = number, y = number, z = number},
    --      rotation = number,
    --      moveDirection = {x = number, y = number, z = number},
    --      jumping = boolean,
    --      state = string,
    --      hipHeight = number
    --    }
    -- 4. Untuk menambah game baru, cukup tambahkan entry baru
    --    dengan format yang sama seperti contoh diatas
    -- 5. Setelah update file ini, script akan auto-detect
    --    game baru tanpa perlu update script utama
    
    -- ========================================
    -- CARA MENDAPATKAN PLACEID
    -- ========================================
    -- 1. Join game yang ingin ditambahkan
    -- 2. Buka Developer Console (F9)
    -- 3. Ketik: print(game.PlaceId)
    -- 4. Copy angka yang muncul
    -- 5. Gunakan angka tersebut sebagai key (dalam quotes)
    
    -- ========================================
    -- CARA MEMBUAT ROUTE JSON
    -- ========================================
    -- 1. Gunakan recorder script untuk merekam movement
    -- 2. Export hasil recording ke JSON format
    -- 3. Upload JSON file ke GitHub repository
    -- 4. Gunakan raw URL dari GitHub sebagai value "url"
    -- 5. Format raw URL:
    --    https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/PATH/FILE.json
}

-- ============================================================
-- END OF DATABASE
-- ============================================================

--[[
    CHANGELOG:
    
    v1.0.0 (2025-01-15)
    - Initial database creation
    - Added KOTA BUKAN GUNUNG route
    - Added MOUNT YAGESYA route
    
    FUTURE UPDATES:
    - Tambahkan game baru disini
    - Update URL jika ada perubahan
    - Update lastUpdated date setiap kali edit
    
    SUPPORT:
    - Discord: discord.gg/KZHQJBHwG
    - GitHub: github.com/syannnnnnn-h/ASTRION
]]
