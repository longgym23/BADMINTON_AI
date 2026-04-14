-- 1. Giải quyết lỗi không thể chọn ảnh: Thiếu cột cất giữ thông tin hình ảnh
ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_path TEXT;

-- 2. Cấp lại quyền cho báo cáo thời gian thực đối với Bảng thông báo.
-- Lệnh này giúp Supabase đẩy thông tin Realtime về app, khiến số Badge (Dấu chấm đỏ trên chuông)
-- lập tức biết tắt đi khi ta vừa bấm "Đọc", tránh bị kẹt con số trên đầu.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
    END IF;
END $$;

-- 3. [TÍNH NĂNG MỚI] Gắn thêm cột để phân chia thể loại cộng đồng (Cầu lông, Bóng đá, Pickleball)
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS sport_type TEXT;
