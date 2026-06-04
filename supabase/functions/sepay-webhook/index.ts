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

    if (contentUpper.includes('DATSAN')) {
      const originalContent = transferContent ?? ''
      const match = originalContent.match(/DATSAN\s+([a-zA-Z0-9_-]+)/i)
      const bookingRef = match ? match[1].trim() : null

      console.log('Extracted bookingRef:', bookingRef)
      
      if (bookingRef) {
        const refUpper = bookingRef.toUpperCase()
        const refLower = bookingRef.toLowerCase()

        const refWithUnderscore = bookingRef.length > 5
          ? `${bookingRef.substring(0, 5)}_${bookingRef.substring(5)}`
          : bookingRef
        const refWithUnderscoreUpper = refWithUnderscore.toUpperCase()
        const refWithUnderscoreLower = refWithUnderscore.toLowerCase()

        const { data, error } = await supabase
          .from('bookings')
          .update({ status: 'PAID' })
          .or(`transaction_id.eq.${bookingRef},transaction_id.eq.${refUpper},transaction_id.eq.${refLower},transaction_id.eq.${refWithUnderscore},transaction_id.eq.${refWithUnderscoreUpper},transaction_id.eq.${refWithUnderscoreLower}`)
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
          // Lấy 8 ký tự đầu để tạo khoảng tìm kiếm UUID hợp lệ
          const prefix = userIdShort.substring(0, 8)
          const startUuid = `${prefix}-0000-0000-0000-000000000000`
          const endUuid = `${prefix}-ffff-ffff-ffff-ffffffffffff`

          // Tìm user ID thực tế từ Supabase bằng cách so sánh chuỗi UUID
          const { data: users, error: userError } = await supabase
            .from('profiles')
            .select('id')
            .gte('id', startUuid)
            .lte('id', endUuid)
            .limit(1)

          if (userError) throw userError

          if (users && users.length > 0) {
            const fullUserId = users[0].id
            const refId = payload.referenceCode || payload.id?.toString()

            // Kiểm tra xem mã giao dịch này đã được xử lý chưa (Idempotency)
            const { data: existingTx } = await supabase
              .from('wallet_transactions')
              .select('id')
              .eq('reference_id', refId)
              .limit(1)

            if (existingTx && existingTx.length > 0) {
               console.log(`Giao dịch ${refId} đã tồn tại. Bỏ qua.`)
               return new Response(JSON.stringify({ success: true, message: 'Giao dịch đã tồn tại' }), { status: 200 })
            }

            // Ghi nhận trực tiếp thành công!
            const { error: insertError } = await supabase
              .from('wallet_transactions')
              .insert({
                user_id: fullUserId,
                amount: amount,
                type: 'TOPUP',
                status: 'SUCCESS',
                reference_id: refId,
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
