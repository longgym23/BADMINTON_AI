import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Các biến môi trường sẽ được Supabase Cloud tự cung cấp
const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
// Lấy Token xác thực của sePay mà bạn đã setup trên Cloud
const SEPAY_API_TOKEN = Deno.env.get('SEPAY_API_TOKEN') ?? ''

serve(async (req) => {
  // Bảo mật: sePay không gửi Authorization header theo mặc định.
  // URL Webhook đã là bí mật. Nếu cần bảo mật cao hơn, cấu hình thêm Custom Header trong Dashboard sePay.


  try {
    // 2. Lấy dữ liệu Webhook từ sePay gửi qua
    const payload = await req.json()
    // DEBUG: Log toàn bộ payload để xem sePay gửi field tên gì
    console.log('FULL PAYLOAD:', JSON.stringify(payload))

    // sePay dùng field "content" (không phải "transferContent")
    // và field "amount" (không phải "transferAmount")
    const amount = payload.amount ?? payload.transferAmount
    const transferContent = payload.content ?? payload.transferContent ?? payload.description

    // 3. Admin Client để vượt qua phần RLS Database
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 4. Log nội dung nhận được để debug
    console.log('transferContent received:', transferContent)

    // Regex đơn giản: Lấy từ đầu tiên (chỉ chữ và số) ngay sau "DATSAN "
    // Ngân hàng hay xóa ký tự đặc biệt (_), nên transactionId phải là alphanumeric thuần túy
    // VD: "DATSAN 1b8ed55807 FT260873..." → lấy "1b8ed55807"
    const match = transferContent?.match(/DATSAN\s+([A-Za-z0-9]+)/i)
    const bookingRef = match ? match[1].trim() : null

    console.log('Extracted bookingRef:', bookingRef)
    
    if (bookingRef) {
      // Thử 2 format: format mới (không có _) và format cũ (có _ sau 5 ký tự đầu)
      const refWithUnderscore = bookingRef.length > 5
        ? `${bookingRef.substring(0, 5)}_${bookingRef.substring(5)}`
        : bookingRef

      console.log('Trying bookingRef (no underscore):', bookingRef)
      console.log('Trying bookingRef (with underscore):', refWithUnderscore)

      // Cập nhật với filter OR giữa 2 format
      const { data, error } = await supabase
        .from('bookings')
        .update({ status: 'PAID' })
        .or(`transaction_id.eq.${bookingRef},transaction_id.eq.${refWithUnderscore}`)
        .select()

      if (error) throw error

      console.log('Rows updated:', data?.length ?? 0)

      if (!data || data.length === 0) {
        return new Response(
          JSON.stringify({ error: `Không tìm thấy booking với ref: ${bookingRef} hoặc ${refWithUnderscore}` }),
          { status: 404 }
        )
      }

      return new Response(JSON.stringify({ success: true, message: `Cập nhật ${data.length} booking thành PAID` }), { status: 200 })
    }

    return new Response(JSON.stringify({ error: 'Không tìm thấy Booking ID' }), { status: 400 })
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), { status: 500 })
  }
})
