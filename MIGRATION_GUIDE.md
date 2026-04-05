# Clean Architecture + MVVM Migration Guide

## Cấu trúc mới

```
lib/
├── core/                    # Constants, errors, utils, theme
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── theme/
├── domain/                 # Business logic layer
│   ├── entities/           # Business objects (pure, no serialization)
│   │   ├── user.dart
│   │   ├── court.dart
│   │   ├── booking.dart
│   │   └── course.dart
│   └── repositories/       # Repository interfaces (contracts)
│       ├── user_repository.dart
│       ├── court_repository.dart
│       ├── booking_repository.dart
│       └── course_repository.dart
├── data/                   # Data layer
│   ├── models/             # DTOs (Data Transfer Objects)
│   ├── datasources/         # Data source interfaces
│   └── repositories/       # Repository implementations
├── presentation/           # Presentation layer
│   ├── screens/            # UI screens
│   ├── viewmodels/         # ViewModels (MVVM pattern)
│   └── widgets/           # Reusable widgets
├── services/              # External services
└── providers/            # State management (Provider)
```

## Nguyên tắc

### 1. Domain Layer
- **Entities**: Objects thuần business, không serialization
- **Repository Interfaces**: Contracts định nghĩa behavior

### 2. Data Layer
- **Models**: DTOs với serialization logic (fromSupabase, toSupabase)
- **Repository Implementations**: Implement các interfaces từ domain

### 3. Presentation Layer
- **ViewModels**: Business logic cho UI (dùng ChangeNotifier)
- **Screens**: UI thuần túy, không logic nghiệp vụ
- **Widgets**: Components tái sử dụng

## Cách migrate

### Bước 1: Di chuyển entities
- Copy models hiện tại sang `domain/entities/`
- Loại bỏ logic serialization
- Dùng Equatable cho comparison

### Bước 2: Tạo repository interfaces
- Tạo interfaces trong `domain/repositories/`
- Định nghĩa các method cần thiết

### Bước 3: Tách datasource
- Tạo datasource interface trong `data/datasources/`
- Giữ nguyên SupabaseRepository là implementation

### Bước 4: Di chuyển viewmodels
- Di chuyển từ `lib/viewmodels/` sang `lib/presentation/viewmodels/`
- Kế thừa base ViewModel

### Bước 5: Di chuyển screens
- Di chuyển từ `lib/screens/` sang `lib/presentation/screens/`
- Giữ nguyên cấu trúc thư mục

## Ví dụ

### Trước (code hiện tại)
```dart
// lib/data/models/booking_model.dart
class BookingModel {
  final String id;
  factory BookingModel.fromSupabase(Map<String, dynamic> data) {...}
  Map<String, dynamic> toSupabase() {...}
}
```

### Sau (Clean Architecture)
```dart
// lib/domain/entities/booking.dart (entity - pure)
class Booking extends Equatable {
  final String id;
  // Không có serialization
}

// lib/data/models/booking_model.dart (DTO - with serialization)
class BookingModel {
  final String id;
  factory BookingModel.fromSupabase(Map<String, dynamic> data) {...}
  Map<String, dynamic> toSupabase() {...}
  
  // Convert entity <-> model
  Booking toEntity() => Booking(id: id, ...);
  factory BookingModel.fromEntity(Booking entity) => ...
}
```

## Lưu ý
- Để backward compatibility, có thể giữ code cũ và tạo thêm code mới
- Migrate từ từ theo feature, không nên migrate toàn bộ một lần
- Chạy test sau mỗi lần migration