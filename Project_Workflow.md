# Tổng quan Workflow Dự án Badminton AI

Dưới đây là sơ đồ workflow (luồng hoạt động) và kiến trúc tổng quan của dự án, giúp bạn có cái nhìn toàn cảnh để dễ dàng lên kế hoạch phát triển các tính năng trong tương lai.

## 1. Kiến trúc Hệ thống (System Architecture)

Dự án hiện đang áp dụng mô hình kiến trúc phân lớp (gần với Clean Architecture / MVVM) với `BLoC` và `Provider` để quản lý trạng thái, kết nối với Backend là **Supabase**.

```mermaid
graph TD
    subgraph UI_Layer ["UI Layer (Screens & Widgets)"]
        UserUI[User Screens]
        AdminUI[Admin Screens]
    end

    subgraph State_Management ["State Management (BLoC / Provider)"]
        HBloc[HomeFilterBloc]
        CBloc[ChatBloc / ChatRoomBloc]
        NProv[NotificationProvider]
        AProv[AuthProvider]
    end

    subgraph Data_Layer ["Data Layer (Repositories)"]
        SRepo[SupabaseRepository\n- Courts, Bookings, Users]
        ARepo[AuthRepository]
        CRepo[ChatRepository\nFriendRepository]
    end

    subgraph Backend ["Backend & External Services"]
        SBase[(Supabase\nDatabase, Auth, Storage)]
        Realtime[Supabase Realtime]
        FCM[Firebase Cloud Messaging\nPush Notifications]
        GMap[Google Maps API]
    end

    %% Mối quan hệ bổ sung
    UserUI --> State_Management
    AdminUI --> State_Management
    UserUI --> GMap
    AdminUI --> GMap

    State_Management --> Data_Layer
    Data_Layer --> SBase
    Data_Layer --> Realtime
    Data_Layer --> FCM
```

---

## 2. Luồng Người dùng (User Flow)

Đây là hành trình chính của một người dùng bình thường (Player) trong ứng dụng:

```mermaid
stateDiagram-v2
    [*] --> Splash
    Splash --> Auth: Chưa đăng nhập
    Splash --> MainNavigation: Đã đăng nhập

    state Auth {
        Login --> Register
        Register --> Login
    }
    Auth --> MainNavigation: Thành công

    state MainNavigation {
        HomeTab
        MapTab
        HighlightsTab
        ProfileTab
        ScannerTab
    }

    %% Chi tiết Home Tab
    HomeTab --> CourtDetails: Bấm chọn sân
    CourtDetails --> BookingFlow: Đặt sân
    state BookingFlow {
        SelectTime --> ConfirmBooking: Thanh toán / Chốt
    }
    ConfirmBooking --> Notifications: Nhận thông báo (Realtime)

    %% Map Tab
    MapTab --> CourtDetails: Tìm sân gần đây / Map Link

    %% Group Chat & Social
    HighlightsTab --> GroupChat: View Chat
    HighlightsTab --> AI_Chatbot: Hỏi đáp AI
    
    %% Friends
    ProfileTab --> FriendsList: Quản lý bạn bè
    ProfileTab --> EditProfile: Sửa thông tin
```

---

## 3. Luồng Quản trị viên (Admin Flow)

Hành trình của Admin quản lý hệ thống và sân bãi:

```mermaid
flowchart TD
    A[Admin Login] --> B{Admin Dashboard}
    
    B --> C[Manage Courts]
    C --> C1[Add New Court]
    C --> C2[Edit Court Details]
    C1 --> C3[Location Picker / Google Map Link]
    C2 --> C3
    
    B --> D[Manage Bookings]
    D --> D1[View All Bookings]
    D --> D2[Approve / Reject Bookings]
    D2 --> Event[Trigger Notifications to User]
    
    B --> E[Manage Users]
    E --> E1[View Users / Change Roles]
```

---

## 4. Gợi ý Phát triển trong Tương lai (Future Roadmap)

Dựa trên cấu trúc hiện tại, dưới đây là một số hướng đi có thể mở rộng tính năng dễ dàng:

1. **Thanh toán trực tuyến (Online Payment):** 
   - Tích hợp cổng thanh toán (VNPay, Momo, ZaloPay) vào `BookingFlow` trước bước `ConfirmBooking`.
   - Cần thêm `PaymentRepository` bên phần Data Layer.

2. **Hệ thống AI nâng cao:**
   - Hiện đã có AI Chatbot ở màn Highlights, có thể tích hợp AI vào `HomeFilterBloc` để gợi ý sân (Recommendation System) dựa trên lịch sử đặt sân của user.

3. **Mạng xã hội & Tìm người chơi ghép (Matchmaking):**
   - Mở rộng chức năng `Group Chat` và `Friends` để cho phép tạo các "Trận đấu mở" (Open Matches) để người khác có thể xin tham gia (Join).

4. **Chấm công / Check-in QR:**
   - Module `ScannerTab` có thể kết hợp với hệ thống điểm danh (Attendance Architecture) mà bạn đã thiết kế trước đó, liên kết với màn `Manage Bookings` của Admin để check-in người đến ráo sân.
