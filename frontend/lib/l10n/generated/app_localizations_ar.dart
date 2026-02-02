// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get helloWorld => 'مرحبا بكم';

  @override
  String get title => 'MediSync';

  @override
  String get welcomeToMediSync => 'مرحبا بكم في MediSync';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailRequiredError => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordRequiredError => 'يرجى إدخال كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get signUpPrompt => 'ليس لديك حساب؟ سجل الآن';

  @override
  String get createAccountTitle => 'إنشاء حساب جديد';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get requiredError => 'مطلوب';

  @override
  String get invalidEmailError => 'بريد إلكتروني غير صالح';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get invalidPhoneError => 'رقم هاتف غير صالح (١١ رقم تبدأ بـ ٠١)';

  @override
  String get passwordMinLengthError =>
      'كلمة المرور قصيرة جداً (٨ حروف على الأقل)';

  @override
  String get signUpButton => 'تسجيل';

  @override
  String get registrationFailed => 'فشل التسجيل';

  @override
  String get onboardingTitle => 'التهيئة';

  @override
  String get welcomeMessage => 'مرحباً بك في MediSync!';

  @override
  String get linkPharmacyInstructions =>
      'للبدء في استخدام المنصة، يجب ربط صيدليتك وتقديم المستندات المطلوبة.';

  @override
  String get addNewPharmacyButton => 'إضافة صيدلية جديدة';

  @override
  String get awaitingApprovalTitle => 'في انتظار الموافقة';

  @override
  String get awaitingApprovalMessage =>
      'تم تقديم مستنداتك وتجري مراجعتها من قبل الإدارة. سنقوم بإبلاغك بمجرد تفعيل حسابك.';

  @override
  String get checkStatusButton => 'تحقق من الحالة';

  @override
  String get pendingCartPlaceholder => 'عربة الانتظار (قريباً)';

  @override
  String balanceDisplay(String amount) {
    return 'الرصيد: $amount عملة';
  }

  @override
  String get reloadTooltip => 'تحديث علامة التبويب الحالية';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navOrderHistory => 'سجل الطلبات';

  @override
  String get navPendingCart => 'عربة الانتظار';

  @override
  String get navAccount => 'الحساب';

  @override
  String get urgentShortages => 'نواقص عاجلة';

  @override
  String get noShortages => 'لا توجد نواقص حالياً';

  @override
  String get adSpace => 'مساحة إعلانية\n(عروض وخصومات)';

  @override
  String get menuRequestsHistory => 'سجل الطلبات';

  @override
  String get menuShoppingTour => 'جولة التسوق';

  @override
  String get menuAddShortage => 'إضافة ناقص';

  @override
  String get menuAddExcess => 'إضافة راكد';

  @override
  String get menuStartTransactions => 'بدء المعاملات';

  @override
  String get menuViewTransactions => 'عرض المعاملات';

  @override
  String get menuSuggestProduct => 'اقتراح منتج';

  @override
  String get menuSuggestionsComplaints => 'الاقتراحات والشكاوى';

  @override
  String get menuBalanceHistory => 'سجل الرصيد';

  @override
  String get menuManageUsers => 'إدارة المستخدمين';

  @override
  String get adminDashboardTitle => 'لوحة تحكم المشرف';

  @override
  String get menuFollowUpExcesses => 'متابعة الزوائد';

  @override
  String get menuFollowUpShortages => 'متابعة النواقص';

  @override
  String get menuManageOrders => 'إدارة الطلبات';

  @override
  String get menuDeliveryRequests => 'طلبات التوصيل';

  @override
  String get menuManageProducts => 'إدارة المنتجات';

  @override
  String get menuProductSuggestions => 'اقتراحات المنتجات';

  @override
  String get menuManagePharmacies => 'إدارة الصيدليات';

  @override
  String get menuAppSuggestions => 'اقتراحات التطبيق';

  @override
  String get menuAccountUpdates => 'تحديثات الحساب';

  @override
  String get menuSystemSettings => 'إعدادات النظام';

  @override
  String get manageUsersTitle => 'إدارة المستخدمين';

  @override
  String get tabNewRequests => 'طلبات جديدة';

  @override
  String get tabActiveUsers => 'مستخدمون نشطون';

  @override
  String get searchUsersHint => 'بحث عن مستخدمين...';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين.';

  @override
  String get noMatchesFound => 'لا توجد نتائج مطابقة.';

  @override
  String get noPharmacyLinked => 'لا توجد صيدلية مرتبطة';

  @override
  String get userInformation => 'معلومات المستخدم';

  @override
  String get labelName => 'الاسم';

  @override
  String get labelPhone => 'الهاتف';

  @override
  String get pharmacyDocumentation => 'وثائق الصيدلية';

  @override
  String get labelPharmacyName => 'اسم الصيدلية';

  @override
  String get labelOwnerName => 'اسم المالك';

  @override
  String get labelNationalId => 'الرقم القومي';

  @override
  String get labelPharmacyAddress => 'عنوان الصيدلية';

  @override
  String get labelPharmacistCard => 'كارنيه النقابة';

  @override
  String get labelCommercialRegistry => 'السجل التجاري';

  @override
  String get labelTaxCard => 'البطاقة الضريبية';

  @override
  String get labelLicense => 'الترخيص';

  @override
  String get dialogRejectRequest => 'رفض الطلب';

  @override
  String get dialogRejectMessage => 'هل أنت متأكد من رفض تسجيل هذا المستخدم؟';

  @override
  String get actionReject => 'رفض';

  @override
  String get dialogApproveUser => 'قبول المستخدم';

  @override
  String get dialogApproveMessage =>
      'هل أنت متأكد من قبول هذا المستخدم وتفعيل حسابه؟';

  @override
  String get actionApprove => 'قبول';

  @override
  String get managementActions => 'إجراءات الإدارة';

  @override
  String get actionActivate => 'تفعيل';

  @override
  String get actionSuspend => 'إيقاف';

  @override
  String get dialogActivateUser => 'تفعيل المستخدم';

  @override
  String get dialogSuspendUser => 'إيقاف المستخدم';

  @override
  String get dialogActivateUserMessage => 'هل أنت متأكد من تفعيل هذا الحساب؟';

  @override
  String get dialogSuspendUserMessage => 'هل أنت متأكد من إيقاف هذا الحساب؟';

  @override
  String get actionResetPass => 'إعادة تعيين كلمة المرور';

  @override
  String get dialogResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get dialogResetPasswordMessage =>
      'هل أنت متأكد من إعادة تعيين كلمة المرور لهذا المستخدم إلى \"00000000\"؟';

  @override
  String get actionConfirm => 'تأكيد';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionSuccessful => 'تم الإجراء بنجاح';

  @override
  String get dialogCreateDeliveryAccount => 'إنشاء حساب توصيل';

  @override
  String get labelEmail => 'البريد الإلكتروني';

  @override
  String get labelPassword => 'كلمة المرور';

  @override
  String get errorRequired => 'مطلوب';

  @override
  String get errorMin6Chars => '6 أحرف كحد أدنى';

  @override
  String get msgDeliveryUserCreated => 'تم إنشاء حساب التوصيل وهو قيد الانتظار';

  @override
  String get msgFailedCreateUser => 'فشل إنشاء المستخدم';

  @override
  String get errorLoadingImage => 'خطأ في تحميل الصورة';

  @override
  String get noImage => 'لا توجد صورة';

  @override
  String get matchableProductsTitle => 'المنتجات القابلة للمطابقة';

  @override
  String get searchProductsHint => 'بحث عن منتجات...';

  @override
  String get noMatchableItemsFound => 'لا توجد عناصر قابلة للمطابقة.';

  @override
  String get shortageFulfillment => 'تلبية النواقص';

  @override
  String matchingAvailableInVolumes(int count) {
    return 'المطابقة متاحة في $count أحجام';
  }

  @override
  String get manageProductsTitle => 'إدارة المنتجات';

  @override
  String get managePricesTitle => 'إدارة الأسعار';

  @override
  String priceCoins(String price) {
    return '$price عملة';
  }

  @override
  String get labelCustomerPrice => 'سعر المستخدم';

  @override
  String get dialogAddPrice => 'إضافة سعر';

  @override
  String get actionAddNewPrice => 'إضافة سعر جديد';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionDone => 'تم';

  @override
  String get dialogEditProductInfo => 'تعديل بيانات المنتج';

  @override
  String get labelProductName => 'اسم المنتج';

  @override
  String get actionUpdate => 'تحديث';

  @override
  String get actionLoadMore => 'تحميل المزيد';

  @override
  String get noPricesSet => 'لم يتم تحديد أسعار';

  @override
  String get coinsSuffix => 'عملة';

  @override
  String get tooltipDeactivate => 'إلغاء التفعيل';

  @override
  String get tooltipActivate => 'تفعيل';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusInactive => 'غير نشط';

  @override
  String get managePharmaciesTitle => 'Manage Pharmacies';

  @override
  String get searchPharmaciesHint => 'Search pharmacies...';

  @override
  String get noPharmaciesFound => 'No pharmacies found.';

  @override
  String get labelAddress => 'Address';

  @override
  String get labelBalance => 'Balance';

  @override
  String get editBalanceTitle => 'Edit Balance';

  @override
  String get actionSave => 'Save';

  @override
  String get accountUpdatesTitle => 'Account Updates';

  @override
  String get tabPendingReversals => 'Pending Reversals';

  @override
  String get tabManualAdjustments => 'Manual Adjustments';

  @override
  String get noReversalTickets => 'No pending reversal tickets';

  @override
  String ticketTitle(String id) {
    return 'Ticket #$id';
  }

  @override
  String transactionSerial(String serial) {
    return 'Transaction Serial: $serial';
  }

  @override
  String get expensesLabel => 'Expenses';

  @override
  String get userLabel => 'User';

  @override
  String get amountLabel => 'Amount';

  @override
  String get resolveTicket => 'Resolve Ticket';

  @override
  String get dialogResolveTicket => 'Confirm Resolve';

  @override
  String get dialogResolveTicketMsg =>
      'Are you sure you want to resolve this ticket? This will finalize the financial adjustments.';

  @override
  String get adjustBalanceTitle => 'Adjust Balance';

  @override
  String get selectPharmacyHint => 'Select Pharmacy';

  @override
  String get adjustmentAmountLabel => 'Adjustment Amount (+/-)';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get actionDirectAdjustment => 'Apply Adjustment';

  @override
  String get adjustmentSuccess => 'Balance adjusted successfully';

  @override
  String get menuRefresh => 'تحديث';

  @override
  String get refreshing => 'جاري التحديث...';

  @override
  String get tabPending => 'قيد الانتظار';

  @override
  String get tabAvailable => 'متاح';

  @override
  String get tabFulfilled => 'مكتمل';

  @override
  String get tabActive => 'نشط';
}
