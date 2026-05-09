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
    const contentUpper = transferContent ? transferContent.toUpperCase() : ''
    console.log('transferContent received:', contentUpper)
    console.log('amount received:', amount)

    // ==========================================
    // KỊCH BẢN 1: ĐẶT SÂN (DATSAN)
    // ==========================================
    if (contentUpper.includes('DATSAN')) {
      const match = contentUpper.match(/DATSAN\s+([A-Z0-9]+)/)
      const bookingRef = match ? match[1].trim() : null

      console.log('Extracted bookingRef:', bookingRef)
      
      if (bookingRef) {
        const refWithUnderscore = bookingRef.length > 5
          ? `${bookingRef.substring(0, 5)}_${bookingRef.substring(5)}`
          : bookingRef

        const { data, error } = await supabase
          .from('bookings')
          .update({ status: 'PAID' })
          .or(`transaction_id.eq.${bookingRef},transaction_id.eq.${refWithUnderscore}`)
          .select()

        if (error) throw error

        if (!data || data.length === 0) {
          // Trả về 200 kèm error message để SePay không gửi lại payload này mãi mãi
          return new Response(
            JSON.stringify({ error: `Không tìm thấy booking với ref: ${bookingRef}` }),
            { status: 200 }
          )
        }

        return new Response(JSON.stringify({ success: true, message: `Cập nhật ${data.length} booking thành PAID` }), { status: 200 })
      }
    }

    // ==========================================
    // KỊCH BẢN 2: NẠP TIỀN (NAPTIEN)
    // ==========================================
    if (contentUpper.includes('NAPTIEN')) {
      const match = contentUpper.match(/NAPTIEN\s*([A-Z0-9-]+)/)
      if (match && match[1]) {
        // userIdShort lúc này là chuỗi 8 ký tự
        const userIdShort = match[1].replace(/-/g, '').toLowerCase()

        console.log('Extracted userIdShort:', userIdShort)

        if (userIdShort.length >= 8) {
          // Tìm user ID thực tế từ Supabase bằng cách ép kiểu id sang text (id::text)
          const { data: users, error: userError } = await supabase
            .from('profiles')
            .select('id')
            .filter('id::text', 'ilike', `${userIdShort}%`)
            .limit(1)

          if (userError) throw userError

          if (users && users.length > 0) {
            const fullUserId = users[0].id
            
            // Ghi nhận trực tiếp thành công!
            const { error: insertError } = await supabase
              .from('wallet_transactions')
              .insert({
                user_id: fullUserId,
                amount: amount,
                type: 'TOPUP',
                status: 'SUCCESS',
                reference_id: payload.referenceCode || payload.id?.toString(),
                description: 'Nạp tiền tự động qua VietQR'
              })

            if (insertError) throw insertError

            return new Response(JSON.stringify({ success: true, message: `Nạp tiền thành công cho user ${userIdShort}` }), { status: 200 })
          } else {
            return new Response(
              JSON.stringify({ error: `Không tìm thấy user với mã UUID ngắn: ${userIdShort}` }),
              { status: 200 }
            )
          }
        } else {
          return new Response(
            JSON.stringify({ error: `Chuỗi NAPTIEN quá ngắn: ${userIdShort}` }),
            { status: 200 }
          )
        }
      }
    }

    // Không khớp bất kỳ kịch bản nào (Có thể là tiền chuyển nhầm, không phải của app)
    return new Response(JSON.stringify({ success: true, message: 'Giao dịch không khớp cú pháp hệ thống, bỏ qua.' }), { status: 200 })
  } catch (error) {
    // Trả về 200 kèm theo error để SePay không retry các lỗi logic
    return new Response(JSON.stringify({ error: (error as Error).message }), { status: 200 })
  }
})
