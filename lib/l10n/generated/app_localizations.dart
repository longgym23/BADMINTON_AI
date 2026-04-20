import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// App name
  ///
  /// In vi, this message translates to:
  /// **'Đặt Sân Cầu Lông'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In vi, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @success.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get success;

  /// No description provided for @detail.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get detail;

  /// No description provided for @filter.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get all;

  /// No description provided for @yes.
  ///
  /// In vi, this message translates to:
  /// **'Có'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get no;

  /// No description provided for @search.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noData;

  /// No description provided for @pleaseLogin.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đăng nhập'**
  String get pleaseLogin;

  /// No description provided for @comingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đang được phát triển'**
  String get comingSoon;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get languageEnglish;

  /// No description provided for @selectLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get selectLanguage;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @loginSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại'**
  String get loginFailed;

  /// No description provided for @registerSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công'**
  String get registerSuccess;

  /// No description provided for @registerFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thất bại'**
  String get registerFailed;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản?'**
  String get hasAccount;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get editProfile;

  /// No description provided for @activity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get activity;

  /// No description provided for @system.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get system;

  /// No description provided for @bookedCourts.
  ///
  /// In vi, this message translates to:
  /// **'Lịch đã đặt'**
  String get bookedCourts;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @courses.
  ///
  /// In vi, this message translates to:
  /// **'Khoá học'**
  String get courses;

  /// No description provided for @offers.
  ///
  /// In vi, this message translates to:
  /// **'Ưu đãi'**
  String get offers;

  /// No description provided for @favoriteCourts.
  ///
  /// In vi, this message translates to:
  /// **'Sân yêu thích'**
  String get favoriteCourts;

  /// No description provided for @courseList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách khóa học'**
  String get courseList;

  /// No description provided for @membershipPackage.
  ///
  /// In vi, this message translates to:
  /// **'Gói hội viên'**
  String get membershipPackage;

  /// No description provided for @statistics.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get statistics;

  /// No description provided for @statisticalFilter.
  ///
  /// In vi, this message translates to:
  /// **'Lọc thống kê'**
  String get statisticalFilter;

  /// No description provided for @pieChartTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phân bổ loại sân'**
  String get pieChartTitle;

  /// No description provided for @football.
  ///
  /// In vi, this message translates to:
  /// **'Bóng đá'**
  String get football;

  /// No description provided for @pickleball.
  ///
  /// In vi, this message translates to:
  /// **'Pickleball'**
  String get pickleball;

  /// No description provided for @otherSports.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get otherSports;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @appVersion.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin phiên bản'**
  String get appVersion;

  /// No description provided for @uploadingAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ảnh lên...'**
  String get uploadingAvatar;

  /// No description provided for @avatarUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ảnh đại diện thành công!'**
  String get avatarUpdateSuccess;

  /// No description provided for @avatarUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại khi cập nhật ảnh đại diện.'**
  String get avatarUpdateFailed;

  /// No description provided for @noName.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật tên'**
  String get noName;

  /// No description provided for @noEmail.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật email'**
  String get noEmail;

  /// No description provided for @bookingHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử đặt sân'**
  String get bookingHistory;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get viewAll;

  /// No description provided for @filterByDateRange.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khoảng ngày'**
  String get filterByDateRange;

  /// No description provided for @filterByMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng'**
  String get filterByMonth;

  /// No description provided for @filterByYear.
  ///
  /// In vi, this message translates to:
  /// **'Chọn năm'**
  String get filterByYear;

  /// No description provided for @totalSpend.
  ///
  /// In vi, this message translates to:
  /// **'Tổng chi tiêu'**
  String get totalSpend;

  /// No description provided for @courtsBooked.
  ///
  /// In vi, this message translates to:
  /// **'Sân đã đặt'**
  String get courtsBooked;

  /// No description provided for @times.
  ///
  /// In vi, this message translates to:
  /// **'Lượt'**
  String get times;

  /// No description provided for @sectionAll.
  ///
  /// In vi, this message translates to:
  /// **'TẤT CẢ'**
  String get sectionAll;

  /// No description provided for @filterResults.
  ///
  /// In vi, this message translates to:
  /// **'KẾT QUẢ LỌC'**
  String get filterResults;

  /// No description provided for @statusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get statusCompleted;

  /// No description provided for @statusUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get statusUpcoming;

  /// No description provided for @statusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy'**
  String get statusCancelled;

  /// No description provided for @statusPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ thanh toán'**
  String get statusPending;

  /// No description provided for @noBookings.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử đặt sân'**
  String get noBookings;

  /// No description provided for @noBookingsInRange.
  ///
  /// In vi, this message translates to:
  /// **'Không có lịch đặt trong khoảng thời gian này'**
  String get noBookingsInRange;

  /// No description provided for @getDirections.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường đến sân'**
  String get getDirections;

  /// No description provided for @rebook.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại sân này'**
  String get rebook;

  /// No description provided for @rebookComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng đặt lại đang được phát triển'**
  String get rebookComingSoon;

  /// No description provided for @gettingLocation.
  ///
  /// In vi, this message translates to:
  /// **'Đang lấy vị trí...'**
  String get gettingLocation;

  /// No description provided for @locationNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy vị trí sân'**
  String get locationNotFound;

  /// No description provided for @selectMonth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tháng'**
  String get selectMonth;

  /// No description provided for @selectYear.
  ///
  /// In vi, this message translates to:
  /// **'Chọn năm'**
  String get selectYear;

  /// No description provided for @court.
  ///
  /// In vi, this message translates to:
  /// **'Sân'**
  String get court;

  /// No description provided for @hours.
  ///
  /// In vi, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @bookingDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get bookingDate;

  /// No description provided for @bookingTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get bookingTime;

  /// No description provided for @bookingCourt.
  ///
  /// In vi, this message translates to:
  /// **'Sân'**
  String get bookingCourt;

  /// No description provided for @bookingStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get bookingStatus;

  /// No description provided for @courtSelection.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lịch trực tuyến'**
  String get courtSelection;

  /// No description provided for @totalHours.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giờ'**
  String get totalHours;

  /// No description provided for @totalPrice.
  ///
  /// In vi, this message translates to:
  /// **'Tổng tiền'**
  String get totalPrice;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'TIẾP THEO'**
  String get next;

  /// No description provided for @slotEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Trống'**
  String get slotEmpty;

  /// No description provided for @slotBooked.
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt'**
  String get slotBooked;

  /// No description provided for @slotLocked.
  ///
  /// In vi, this message translates to:
  /// **'Khoá'**
  String get slotLocked;

  /// No description provided for @slotEvent.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện'**
  String get slotEvent;

  /// No description provided for @checkoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận thanh toán'**
  String get checkoutTitle;

  /// No description provided for @courtInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin sân'**
  String get courtInfo;

  /// No description provided for @bookingInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin lịch đặt'**
  String get bookingInfo;

  /// No description provided for @clubName.
  ///
  /// In vi, this message translates to:
  /// **'Tên CLB:'**
  String get clubName;

  /// No description provided for @address.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ:'**
  String get address;

  /// No description provided for @date.
  ///
  /// In vi, this message translates to:
  /// **'Ngày:'**
  String get date;

  /// No description provided for @sport.
  ///
  /// In vi, this message translates to:
  /// **'Đối tượng:'**
  String get sport;

  /// No description provided for @badminton.
  ///
  /// In vi, this message translates to:
  /// **'Cầu lông'**
  String get badminton;

  /// No description provided for @customerName.
  ///
  /// In vi, this message translates to:
  /// **'TÊN CỦA BẠN'**
  String get customerName;

  /// No description provided for @customerNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên của bạn'**
  String get customerNameHint;

  /// No description provided for @customerPhone.
  ///
  /// In vi, this message translates to:
  /// **'SỐ ĐIỆN THOẠI'**
  String get customerPhone;

  /// No description provided for @customerPhoneHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại'**
  String get customerPhoneHint;

  /// No description provided for @noteForOwner.
  ///
  /// In vi, this message translates to:
  /// **'GHI CHÚ CHO CHỦ SÂN'**
  String get noteForOwner;

  /// No description provided for @noteHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập ghi chú'**
  String get noteHint;

  /// No description provided for @scanVietQR.
  ///
  /// In vi, this message translates to:
  /// **'Quét VietQR để thanh toán'**
  String get scanVietQR;

  /// No description provided for @waitingPayment.
  ///
  /// In vi, this message translates to:
  /// **'Đơn hàng đang chờ thanh toán. Đang tự động kiểm tra trạng thái...'**
  String get waitingPayment;

  /// No description provided for @createPayment.
  ///
  /// In vi, this message translates to:
  /// **'TẠO ĐƠN THANH TOÁN'**
  String get createPayment;

  /// No description provided for @fillNameAndPhone.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng điền đủ Tên và Số điện thoại'**
  String get fillNameAndPhone;

  /// No description provided for @creatingOrder.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo đơn hàng...'**
  String get creatingOrder;

  /// No description provided for @orderError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tạo đơn hàng, vui lòng thử lại!'**
  String get orderError;

  /// No description provided for @paymentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán và Đặt sân thành công!'**
  String get paymentSuccess;

  /// No description provided for @paymentExpired.
  ///
  /// In vi, this message translates to:
  /// **'⏰ Hết thời gian thanh toán. Đơn đặt sân đã bị huỷ.'**
  String get paymentExpired;

  /// No description provided for @expiresIn.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau:'**
  String get expiresIn;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @map.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get map;

  /// No description provided for @booking.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân'**
  String get booking;

  /// No description provided for @chat.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện'**
  String get chat;

  /// No description provided for @community.
  ///
  /// In vi, this message translates to:
  /// **'Cộng đồng'**
  String get community;

  /// No description provided for @account.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get account;

  /// No description provided for @bookingNow.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân ngay'**
  String get bookingNow;

  /// No description provided for @smartBooking.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân cầu lông thông minh'**
  String get smartBooking;

  /// No description provided for @searchCourtsAroundYou.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm sân quanh đây'**
  String get searchCourtsAroundYou;

  /// No description provided for @findCourts.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm sân'**
  String get findCourts;

  /// No description provided for @fastBooking.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân cực nhanh'**
  String get fastBooking;

  /// No description provided for @searchUsersOrGroups.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm người dùng hoặc nhóm...'**
  String get searchUsersOrGroups;

  /// No description provided for @searchNameOrPhone.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm tên hoặc số điện thoại...'**
  String get searchNameOrPhone;

  /// No description provided for @searchLocation.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm sân, địa điểm...'**
  String get searchLocation;

  /// No description provided for @searchNameEmailPhone.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm tên, email, sđt...'**
  String get searchNameEmailPhone;

  /// No description provided for @bookingSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân thành công!'**
  String get bookingSuccess;

  /// No description provided for @bookingFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đặt sân thất bại'**
  String get bookingFailed;

  /// No description provided for @noDataAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get noDataAvailable;

  /// No description provided for @active.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get active;

  /// No description provided for @activeTimeAgo.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động {time}'**
  String activeTimeAgo(String time);

  /// No description provided for @appNameKloo.
  ///
  /// In vi, this message translates to:
  /// **'KLOO'**
  String get appNameKloo;

  /// No description provided for @notificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notificationTitle;

  /// No description provided for @noNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Không có thông báo nào'**
  String get noNotifications;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @darkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ tối'**
  String get darkMode;

  /// No description provided for @pushNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo đẩy'**
  String get pushNotifications;

  /// No description provided for @updateUser.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật người dùng'**
  String get updateUser;

  /// No description provided for @displayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get displayName;

  /// No description provided for @cannotBeEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không được bỏ trống'**
  String get cannotBeEmpty;

  /// No description provided for @phoneNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get phoneNumber;

  /// No description provided for @role.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò'**
  String get role;

  /// No description provided for @roleUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get roleUser;

  /// No description provided for @roleCourtOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ sân'**
  String get roleCourtOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên'**
  String get roleAdmin;

  /// No description provided for @updateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thành công!'**
  String get updateSuccess;

  /// No description provided for @errorWithDetails.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @confirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get confirmDelete;

  /// No description provided for @deleteUserConfirmText.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa người dùng \"{name}\" không?'**
  String deleteUserConfirmText(String name);

  /// No description provided for @userDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa người dùng.'**
  String get userDeleted;

  /// No description provided for @adminOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Admin mới có quyền truy cập trang này.'**
  String get adminOnly;

  /// No description provided for @manageUsers.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý Người dùng'**
  String get manageUsers;

  /// No description provided for @admin.
  ///
  /// In vi, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @user.
  ///
  /// In vi, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @noUsersFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng nào.'**
  String get noUsersFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
