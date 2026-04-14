-- Chạy lần lượt các lệnh này trong mục SQL Editor của Supabase
-- Lệnh 1: Xóa chính sách cũ nếu có (tránh lỗi trùng lặp khi chạy lại do nhầm lẫn)
DROP POLICY IF EXISTS "Allow Authenticated Uploads" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Allow Public Uploads" ON storage.objects;

-- Lệnh 2: Bật lại chính sách chuẩn thiết lập cho phép mọi user đã đăng nhập được TẢI ẢNH lên thông qua Supabase Client
CREATE POLICY "Allow Authenticated Uploads" 
ON storage.objects 
FOR INSERT 
TO authenticated 
WITH CHECK (
    bucket_id = 'chat_images'
);

-- Lệnh 3: Đảm bảo Public (Mọi người) hiển nhiên có thể ĐỌC (TẢI XUỐNG XEM ẢNH) từ bucket này
CREATE POLICY "Allow Public Access" 
ON storage.objects 
FOR SELECT 
USING (
    bucket_id = 'chat_images'
);
