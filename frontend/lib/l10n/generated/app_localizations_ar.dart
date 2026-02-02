// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get helloWorld => 'مرحباً بالعالم';

  @override
  String get title => 'MediSync';

  @override
  String get welcomeToMediSync => 'مرحبًا بك في MediSync';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailRequiredError => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordRequiredError => 'يرجى إدخال كلمة المرور';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get actionAdd => 'إضافة';

  @override
  String get actionEdit => 'تعديل';

  @override
  String get actionCreate => 'إنشاء';

  @override
  String get actionDelete => 'حذف';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get signUpPrompt => 'ليس لديك حساب؟ سجل الآن';

  @override
  String get createAccountTitle => 'إنشاء حساب';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get requiredError => 'مطلوب';

  @override
  String get invalidEmailError => 'البريد الإلكتروني غير صالح';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get invalidPhoneError => 'رقم هاتف غير صالح (11 رقمًا يبدأ بـ 01)';

  @override
  String get passwordMinLengthError => 'قصير جدًا (8 أحرف كحد أدنى)';

  @override
  String get signUpButton => 'سجل الآن';

  @override
  String get registrationFailed => 'فشل التسجيل';

  @override
  String get onboardingTitle => 'التهيئة';

  @override
  String get welcomeMessage => 'مرحبًا بك في MediSync!';

  @override
  String get linkPharmacyInstructions =>
      'لبدء استخدام المنصة، تحتاج إلى ربط صيدليتك وتقديم الوثائق.';

  @override
  String get addNewPharmacyButton => 'إضافة صيدلية جديدة';

  @override
  String get awaitingApprovalTitle => 'في انتظار الموافقة';

  @override
  String get awaitingApprovalMessage =>
      'تم تقديم وثائقك وهي قيد المراجعة من قبل المسؤول. سنخطرك بمجرد تفعيل حسابك.';

  @override
  String get checkStatusButton => 'تحقق من الحالة الآن';

  @override
  String get pendingCartPlaceholder => 'العربة المعلقة (قريباً)';

  @override
  String balanceDisplay(String amount) {
    return 'الرصيد: $amount عملة';
  }

  @override
  String get reloadTooltip => 'إعادة تحميل التبويب الحالي';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navOrderHistory => 'سجل الطلبات';

  @override
  String get navPendingCart => 'العربة المعلقة';

  @override
  String get navAccount => 'الحساب';

  @override
  String get urgentShortages => 'نواقص عاجلة';

  @override
  String get noShortages => 'لا توجد نواقص حالية';

  @override
  String get adSpace => 'مساحة إعلانية\n(عروض وترويج)';

  @override
  String get menuRequestsHistory => 'سجل الطلبات';

  @override
  String get menuShoppingTour => 'جولة تسوق';

  @override
  String get menuAddShortage => 'إضافة نواقص';

  @override
  String get menuAddExcess => 'إضافة وفرة';

  @override
  String get menuStartTransactions => 'بدء المعاملات';

  @override
  String get menuViewTransactions => 'عرض المعاملات';

  @override
  String get menuSuggestProduct => 'اقتراح منتج';

  @override
  String get menuSuggestionsComplaints => 'اقتراحات/شكاوى';

  @override
  String get menuBalanceHistory => 'سجل الرصيد';

  @override
  String get menuManageUsers => 'إدارة المستخدمين';

  @override
  String get adminDashboardTitle => 'لوحة تحكم المشرف';

  @override
  String get menuFollowUpExcesses => 'متابعة الوفرة';

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
  String get tabActiveUsers => 'المستخدمين النشطين';

  @override
  String get searchUsersHint => 'البحث عن مستخدمين (* للكل)...';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين.';

  @override
  String get noMatchesFound => 'لم يتم العثور على نتائج.';

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
  String get labelPharmacistCard => 'كارنية الصيدلي';

  @override
  String get labelCommercialRegistry => 'السجل التجاري';

  @override
  String get labelTaxCard => 'البطاقة الضريبية';

  @override
  String get labelLicense => 'الترخيص';

  @override
  String get dialogRejectRequest => 'رفض الطلب';

  @override
  String get dialogRejectMessage =>
      'هل أنت متأكد أنك تريد رفض تسجيل هذا المستخدم؟';

  @override
  String get actionReject => 'رفض';

  @override
  String get dialogApproveUser => 'موافقة المستخدم';

  @override
  String get dialogApproveMessage =>
      'هل أنت متأكد أنك تريد الموافقة على هذا المستخدم وتفعيل حسابه؟';

  @override
  String get actionApprove => 'موافقة';

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
  String get dialogActivateUserMessage =>
      'هل أنت متأكد أنك تريد تفعيل هذا الحساب؟';

  @override
  String get dialogSuspendUserMessage =>
      'هل أنت متأكد أنك تريد إيقاف هذا الحساب؟';

  @override
  String get actionResetPass => 'إعادة تعين كلمة المرور';

  @override
  String get dialogResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get dialogResetPasswordMessage =>
      'هل أنت متأكد أنك تريد إعادة تعيين كلمة مرور هذا المستخدم إلى \"00000000\"؟';

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
  String get msgDeliveryUserCreated =>
      'تم إنشاء مستخدم التوصيل وهو في انتظار الموافقة';

  @override
  String get msgFailedCreateUser => 'فشل إنشاء المستخدم';

  @override
  String get errorLoadingImage => 'خطأ في تحميل الصورة';

  @override
  String get noImage => 'لا توجد صورة';

  @override
  String get matchableProductsTitle => 'منتجات قابلة للمطابقة';

  @override
  String get searchProductsHint => 'بحث عن منتجات (* للكل)...';

  @override
  String get noMatchableItemsFound => 'لم يتم العثور على عناصر قابلة للمطابقة.';

  @override
  String get shortageFulfillment => 'تلبية العجز';

  @override
  String matchingAvailableInVolumes(int count) {
    return 'مطابقة متاحة في $count أحجام';
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
  String get labelCustomerPrice => 'سعر المستهلك';

  @override
  String get dialogAddPrice => 'إضافة سعر';

  @override
  String get actionAddNewPrice => 'إضافة سعر جديد';

  @override
  String get actionDone => 'تم';

  @override
  String get dialogEditProductInfo => 'تعديل معلومات المنتج';

  @override
  String get labelProductName => 'اسم المنتج';

  @override
  String get actionUpdate => 'تحديث';

  @override
  String get actionLoadMore => 'تحميل المزيد';

  @override
  String get noPricesSet => 'لم يتم تحديد أسعار';

  @override
  String get coinsSuffix => 'عملات';

  @override
  String get tooltipDeactivate => 'إلغاء التفعيل';

  @override
  String get tooltipActivate => 'تفعيل';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusInactive => 'غير نشط';

  @override
  String get statusPending => 'معلق';

  @override
  String get statusAvailable => 'متاح';

  @override
  String get statusFulfilled => 'مكتمل';

  @override
  String get statusPartiallyFulfilled => 'مكتمل جزئياً';

  @override
  String get statusSold => 'تم البيع';

  @override
  String get statusExpired => 'منتهي الصلاحية';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get managePharmaciesTitle => 'إدارة الصيدليات';

  @override
  String get searchPharmaciesHint => 'البحث في الصيدليات...';

  @override
  String get noPharmaciesFound => 'لم يتم العثور على صيدليات.';

  @override
  String get labelAddress => 'العنوان';

  @override
  String get labelBalance => 'الرصيد';

  @override
  String get editBalanceTitle => 'تعديل الرصيد';

  @override
  String get actionSave => 'حفظ';

  @override
  String get accountUpdatesTitle => 'تحديثات الحساب';

  @override
  String get tabPendingReversals => 'عمليات الإلغاء المعلقة';

  @override
  String get tabManualAdjustments => 'تعديلات يدوية';

  @override
  String get noReversalTickets => 'لا توجد تذاكر إلغاء معلقة';

  @override
  String ticketTitle(String id) {
    return 'تذكرة رقم $id';
  }

  @override
  String transactionSerial(String serial) {
    return 'مسلسل المعاملة: $serial';
  }

  @override
  String get expensesLabel => 'مصروفات';

  @override
  String get userLabel => 'مستخدم';

  @override
  String get amountLabel => 'القيمة';

  @override
  String get resolveTicket => 'حل التذكرة';

  @override
  String get dialogResolveTicket => 'تأكيد الحل';

  @override
  String get dialogResolveTicketMsg =>
      'هل أنت متأكد أنك تريد حل هذه التذكرة؟ هذا سيفعل التعديلات المالية.';

  @override
  String get adjustBalanceTitle => 'تعديل الرصيد';

  @override
  String get selectPharmacyHint => 'اختر الصيدلية';

  @override
  String get adjustmentAmountLabel => 'قيمة التعديل (+/-)';

  @override
  String get reasonLabel => 'السبب';

  @override
  String get actionDirectAdjustment => 'تطبيق التعديل';

  @override
  String get adjustmentSuccess => 'تم تعديل الرصيد بنجاح';

  @override
  String get menuRefresh => 'تحديث';

  @override
  String get refreshing => 'جاري التحديث...';

  @override
  String get tabPending => 'معلق';

  @override
  String get tabAvailable => 'متاح';

  @override
  String get tabFulfilled => 'تم التنفيذ';

  @override
  String get tabActive => 'نشط';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionSubmit => 'إرسال';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionLogout => 'تسجيل خروج';

  @override
  String get labelVolume => 'الحجم';

  @override
  String get labelQuantity => 'الكمية';

  @override
  String get labelPrice => 'السعر';

  @override
  String get labelNotes => 'ملاحظات';

  @override
  String get labelExpiry => 'تاريخ الانتهاء';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get msgDeletedSuccessfully => 'تم الحذف بنجاح';

  @override
  String get msgSubmittedSuccessfully => 'تم الإرسال بنجاح';

  @override
  String get titleSuggestProduct => 'اقتراح منتج جديد';

  @override
  String get titleSuggestionsComplaints => 'اقتراحات وشكاوى';

  @override
  String get titleSubscriptionPlans => 'خطط الاشتراك';

  @override
  String get titleNotifications => 'التنبيهات';

  @override
  String get labelArabic => 'العربية';

  @override
  String get labelEnglish => 'الإنجليزية';

  @override
  String get labelAppLanguage => 'لغة التطبيق';

  @override
  String labelPriceWithAmount(String amount) {
    return 'السعر: $amount';
  }

  @override
  String get tooltipMarkAllAsSeen => 'تحديد الكل كمقروء';

  @override
  String get msgNoNotifications => 'لا توجد تنبيهات بعد';

  @override
  String get titlePharmacyDetails => 'تفاصيل الصيدلية';

  @override
  String get labelSubmitDocumentation => 'تقديم الوثائق';

  @override
  String get msgProvideInformation =>
      'يرجى تقديم المعلومات التالية كما هي مدونة في وثائقك الرسمية.';

  @override
  String get labelPharmacyNameWithHint => 'اسم الصيدلية';

  @override
  String get labelOwnerNameWithHint => 'اسم المالك (كما هو مدون في الرخصة)';

  @override
  String get labelNationalIdWithHint => 'الرقم القومي (بطاقة رقم قومي)';

  @override
  String get msgMustBe14Digits => 'يجب أن يكون 14 رقمًا بالضبط';

  @override
  String get errorNationalIdRequired => 'الرقم القومي مطلوب';

  @override
  String get errorNationalIdInvalid =>
      'يجب أن يكون الرقم القومي 14 رقمًا بالضبط';

  @override
  String get labelDetailedAddress => 'العنوان بالتفصيل';

  @override
  String get labelDetailedAddressWithHint => 'العنوان بالتفصيل';

  @override
  String get hintDetailedAddress => 'مثال: 123 مدينة نصر، القاهرة، مصر';

  @override
  String get actionSubmitForApproval => 'إرسال للموافقة';

  @override
  String get actionChange => 'تغيير';

  @override
  String get actionUpload => 'رفع';

  @override
  String get msgSubmissionFailed => 'فشل التقديم';

  @override
  String get dialogConfirmLogout => 'تأكيد تسجيل الخروج';

  @override
  String get dialogConfirmLogoutMsg => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get msgPleaseEnterValidPrice => 'يرجى إدخال سعر صالح';

  @override
  String get msgPleaseUploadAllDocs => 'يرجى رفع المستندات الأربعة جميعها';

  @override
  String get labelFeedbackDescription =>
      'نحن نقدر رأيك. يرجى إخبارنا إذا كان لديك أي اقتراحات للتحسين أو أي شكاوى بخصوص النظام.';

  @override
  String get labelFeedbackPlaceholder => 'اكتب رسالتك هنا...';

  @override
  String get labelFeedbackTitle => 'رأيك';

  @override
  String get msgFeedbackSuccess => 'شكراً لك على رأيك!';

  @override
  String get msgGenericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get labelRequired => 'مطلوب';

  @override
  String get msgComingSoon => 'قريباً!';

  @override
  String get msgSubscriptionDescription =>
      'نحن نعمل على ميزات متميزة حصرية وخطط اشتراك لمساعدتك على تنمية أعمال صيدليتك.';

  @override
  String get labelUserName => 'اسم المستخدم';

  @override
  String get labelUserEmailPlaceholder => 'email@example.com';

  @override
  String get menuMyAccount => 'حسابي';

  @override
  String get subtitleMyAccount => 'عرض وتعديل بياناتك الشخصية';

  @override
  String get menuHelp => 'مساعدة';

  @override
  String get subtitleHelp => 'الأسئلة الشائعة ودليل استخدام التطبيق';

  @override
  String get subtitleSubscription => 'استكشاف الميزات المتميزة';

  @override
  String get menuResetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get subtitleResetPassword => 'تحديث كلمة مرورك بشكل آمن';

  @override
  String get dialogLogoutMsg => 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟';

  @override
  String get titleShortageFollowup => 'متابعة النواقص';

  @override
  String get titleRequestsHistory => 'سجل الطلبات';

  @override
  String get dialogConfirmDelete => 'تأكيد الحذف';

  @override
  String get dialogConfirmDeleteMsg => 'هل أنت متأكد أنك تريد حذف هذا العنصر؟';

  @override
  String get msgNoActiveShortages => 'لا توجد نواقص نشطة';

  @override
  String get msgNoFulfilledShortages => 'لا توجد نواقص مكتملة';

  @override
  String get msgNoHistoryFound => 'لم يتم العثور على سجل';

  @override
  String labelPharmacy(String name) {
    return 'الصيدلية: $name';
  }

  @override
  String labelQuantityNeeded(int count) {
    return 'الكمية المطلوبة: $count';
  }

  @override
  String labelRemainingQuantity(int count) {
    return 'الكمية المتبقية: $count';
  }

  @override
  String labelQuantityFulfilled(int count) {
    return 'الكمية المنفذة: $count';
  }

  @override
  String get msgCannotDeleteFulfilledShortage =>
      'لا يمكن حذف نواقص تم تنفيذها جزئياً بالفعل.';

  @override
  String get dialogConfirmDeleteShortage =>
      'هل أنت متأكد أنك تريد حذف هذا النقص؟';

  @override
  String get msgShortageRequirementCompleted => 'هذا الطلب مكتمل.';

  @override
  String get labelExcessOffer => 'عرض وفرة';

  @override
  String get labelShortageRequest => 'طلب نقص';

  @override
  String get labelType => 'النوع';

  @override
  String get labelTotalQuantity => 'إجمالي الكمية:';

  @override
  String get labelRemaining => 'المتبقي';

  @override
  String get labelDiscount => 'الخصم';

  @override
  String get labelDiscountAmount => 'قيمة الخصم';

  @override
  String get labelFinalPrice => 'السعر النهائي';

  @override
  String get labelRejectionReason => 'سبب الرفض:';

  @override
  String labelCreated(String date) {
    return 'تاريخ الإنشاء: $date';
  }

  @override
  String msgCannotDeleteFulfilledItem(String item, String action) {
    return 'لا يمكن حذف $item الذي تم $action بالفعل.';
  }

  @override
  String get labelExcess => 'وفرة';

  @override
  String get labelShortage => 'نقص';

  @override
  String get labelTaken => 'أُخذ';

  @override
  String get labelFulfilled => 'تم تنفيذه';

  @override
  String get labelOffer => 'عرض';

  @override
  String get labelRequest => 'طلب';

  @override
  String titleMatchProduct(String product) {
    return 'تطابق: $product';
  }

  @override
  String get labelShortages => 'النواقص';

  @override
  String get labelExcesses => 'الوفرة';

  @override
  String get labelTime => 'الوقت';

  @override
  String get labelSalePercentage => 'نسبة البيع %';

  @override
  String get msgSelectShortageFirst => 'يرجى اختيار نقص أولاً';

  @override
  String get msgShortageFulfilled => 'كمية النقص مكتملة بالفعل';

  @override
  String get labelShortageFulfillment => 'تلبية النواقص';

  @override
  String labelVol(String name) {
    return 'حجم: $name';
  }

  @override
  String labelNeeded(int count) {
    return 'مطلوب: $count';
  }

  @override
  String labelSaleRatio(num ratio) {
    return 'نسبة البيع: $ratio%';
  }

  @override
  String labelAllocated(int current, int total) {
    return 'مخصص: $current / $total';
  }

  @override
  String get msgOverLimit => 'تجاوز الحد!';

  @override
  String get labelAdminOverrides => 'تجاوزات المشرف (اختياري)';

  @override
  String get labelBuyerComm => 'عمولة المشتري %';

  @override
  String get labelSellerRew => 'مكافأة البائع %';

  @override
  String get hintShFulfill => 'تلبية النقص';

  @override
  String get actionSubmitTransaction => 'إرسال المعاملة';

  @override
  String get msgTransactionCreated => 'تم إنشاء المعاملة بنجاح';

  @override
  String get labelPersonalInformation => 'المعلومات الشخصية';

  @override
  String get labelFullName => 'الاسم الكامل';

  @override
  String get labelEmailAddress => 'البريد الإلكتروني';

  @override
  String get labelPhoneNumber => 'رقم الهاتف';

  @override
  String get labelPharmacyInformation => 'معلومات الصيدلية';

  @override
  String get labelPharmacyPhone => 'هاتف الصيدلية';

  @override
  String get actionSaveChanges => 'حفظ التغييرات';

  @override
  String get msgUpdateRequested => 'تم إرسال طلب التحديث للمشرف!';

  @override
  String get msgUpdateFailed => 'فشل إرسال الطلب';

  @override
  String get msgPendingUpdateInfo =>
      'في انتظار الموافقة على طلب التحديث السابق. التعديلات الجديدة ستحل محل الطلب المعلق.';

  @override
  String get labelPharmacyInfo => 'معلومات الصيدلية';

  @override
  String get msgNoAddress => 'لم يتم تقديم عنوان';

  @override
  String get msgNoPhone => 'لم يتم تقديم هاتف';

  @override
  String labelOwner(String name) {
    return 'المالك: $name';
  }

  @override
  String get titleShoppingTour => 'جولة تسوق';

  @override
  String get labelSelectQuantitiesByPrice => 'اختر الكميات حسب السعر:';

  @override
  String labelAvailableCount(int count) {
    return 'متاح: $count';
  }

  @override
  String labelSubtotalAmount(String amount) {
    return 'المجموع الفرعي: $amount عملة';
  }

  @override
  String get labelTotalCost => 'إجمالي التكلفة:';

  @override
  String labelUnitsCount(int count) {
    return '$count وحدات';
  }

  @override
  String get actionUpdateCart => 'تحديث العربة';

  @override
  String get msgRemovedFromCart => 'تم الحذف من العربة';

  @override
  String get msgCartUpdated => 'تم تحديث العربة!';

  @override
  String get titleShoppingCart => 'عربة التسوق';

  @override
  String get msgCartEmpty => 'عربتك فارغة';

  @override
  String get labelOrderNotesOptional => 'ملاحظات الطلب (اختياري)';

  @override
  String get hintAddSpecialInstructions => 'إضافة تعليمات خاصة...';

  @override
  String get actionPlaceOrder => 'إتمام الطلب';

  @override
  String get msgPlacingOrder => 'جاري تنفيذ الطلب...';

  @override
  String get msgOrderPlaced => 'تم تنفيذ الطلب بنجاح!';

  @override
  String get msgOrderFailed => 'فشل في تنفيذ الطلب';

  @override
  String get hintSearchProducts => 'بحث عن منتجات...';

  @override
  String get msgNoMarketItems => 'لا توجد عناصر متاحة في السوق';

  @override
  String get msgNoSearchMatches => 'لم يتم العثور على عناصر تطابق بحثك';

  @override
  String labelAvailableUnits(int count) {
    return '$count متاح';
  }

  @override
  String labelPriceOptions(int count) {
    return '$count أسعار';
  }

  @override
  String get titleEditExcess => 'تعديل وفرة المخزون';

  @override
  String get titleAddExcess => 'إضافة وفرة مخزون';

  @override
  String get labelSelectExpiryMonthYear => 'اختر الانتهاء (شهر/سنة)';

  @override
  String get msgSelectExpiryDate => 'يرجى اختيار تاريخ الانتهاء';

  @override
  String get msgSelectProductVolume => 'يرجى اختيار المنتج والحجم';

  @override
  String get msgInvalidSalePercentage => 'نسبة بيع غير صالحة';

  @override
  String get msgEnterValidQuantity => 'يرجى إدخال كمية صالحة';

  @override
  String labelProductWithName(String name) {
    return 'المنتج: $name';
  }

  @override
  String labelVolumeWithName(String name) {
    return 'الحجم: $name';
  }

  @override
  String get hintLoading => 'جاري التحميل...';

  @override
  String get hintSelectVolume => 'اختر الحجم';

  @override
  String get labelPriceCoins => 'السعر (عملات)';

  @override
  String get labelSelectPrice => 'اختر السعر';

  @override
  String get actionEnterManualPrice => 'إدخال سعر يدوي';

  @override
  String get labelManualPrice => 'سعر يدوي';

  @override
  String get msgInvalidQuantity => 'كمية غير صالحة';

  @override
  String get msgTooHigh => 'عالي جداً';

  @override
  String get msgTooLow => 'منخفض جداً';

  @override
  String get labelExpiryDateMMYY => 'تاريخ الانتهاء (شهر/سنة)';

  @override
  String get hintSelectExpiryDate => 'اختر تاريخ الانتهاء';

  @override
  String get labelRequestType => 'نوع الطلب';

  @override
  String get labelRealExcess => 'وفرة حقيقية';

  @override
  String get labelPercentageValue => 'قيمة النسبة (%)';

  @override
  String get actionUpdateExcess => 'تحديث الوفرة';

  @override
  String get actionSubmitExcess => 'إرسال الوفرة';

  @override
  String get msgErrorLoadingVolumes => 'خطأ في تحميل الأحجام';

  @override
  String get titleEditShortage => 'تعديل النواقص';

  @override
  String get titleAddShortage => 'إضافة نواقص';

  @override
  String get msgShortageUpdated => 'تم تحديث النواقص بنجاح';

  @override
  String get msgShortageAdded => 'تم إضافة النواقص بنجاح';

  @override
  String get msgErrorProcessingRequest => 'خطأ في معالجة الطلب';

  @override
  String get labelQuantityNeededField => 'الكمية المطلوبة';

  @override
  String get msgQuantityDecreaseOnly => 'يمكن تقليل الكمية فقط';

  @override
  String msgCannotBeLessThan(int count) {
    return 'لا يمكن أن يكون أقل من $count';
  }

  @override
  String get actionUpdateShortage => 'تحديث النواقص';

  @override
  String get actionSubmitShortage => 'إرسال النواقص';

  @override
  String get labelUpdateSecurityDetails => 'تحديث تفاصيل الأمان الخاصة بك';

  @override
  String get labelPasswordLengthHint =>
      'تأكد من أن كلمة مرورك الجديدة تزيد عن 8 أحرف.';

  @override
  String get labelCurrentPassword => 'كلمة المرور الحالية';

  @override
  String get labelNewPassword => 'كلمة المرور الجديدة';

  @override
  String get labelConfirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get msgPasswordChangedSuccess => 'تم تغيير كلمة المرور بنجاح!';

  @override
  String get msgPasswordChangeFailed => 'فشل في تغيير كلمة المرور';

  @override
  String get msgPasswordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get msgNoBalanceHistory => 'لم يتم العثور على سجل رصيد.';

  @override
  String get labelBalanceUpdate => 'تحديث الرصيد';

  @override
  String get labelDate => 'التاريخ';

  @override
  String get labelPrevBalance => 'الرصيد السابق';

  @override
  String get labelNewBalance => 'الرصيد الجديد';

  @override
  String get labelBreakdown => 'التفصيل:';

  @override
  String get labelNotAvailable => 'غير متوفر';

  @override
  String get manageOrdersTitle => 'إدارة الطلبات';

  @override
  String get labelActiveUsers => 'المستخدمين النشطين';

  @override
  String get labelAccountStatus => 'حالة الحساب';

  @override
  String get labelUnknown => 'غير معروف';

  @override
  String get actionSimulate => 'محاكاة';

  @override
  String get actionCompensation => 'تعويض';

  @override
  String get actionHistory => 'السجل';

  @override
  String get actionPayment => 'دفع';

  @override
  String get actionPayments => 'مدفوعات';

  @override
  String get dialogConfirmDeleteAdjustment => 'تأكيد الحذف';

  @override
  String get msgConfirmDeleteAdjustment => 'هل أنت متأكد؟ هذا سيلغي التعديل.';

  @override
  String get actionDeleteRevert => 'حذف وإلغاء';

  @override
  String get msgAdjustmentReverted => 'تم إلغاء التعديل بنجاح';

  @override
  String get dialogEditPayment => 'تعديل الدفعة';

  @override
  String dialogRecordPayment(String name) {
    return 'تسجيل دفعة - $name';
  }

  @override
  String get labelPaymentType => 'النوع';

  @override
  String get labelDeposit => '💰 إيداع';

  @override
  String get labelWithdrawal => '💸 سحب';

  @override
  String get labelAdjustmentAmount => 'القيمة';

  @override
  String get labelPaymentMethod => 'الطريقة';

  @override
  String get labelCash => 'كاش';

  @override
  String get labelBankTransfer => 'تحويل بنكي';

  @override
  String get labelCheque => 'شيك';

  @override
  String get labelOther => 'آخر';

  @override
  String get labelReferenceNumber => 'رقم المرجع';

  @override
  String get labelAdminNote => 'ملاحظة المسؤول';

  @override
  String get msgInvalidAmount => 'قيمة غير صالحة';

  @override
  String get msgPaymentUpdated => 'تم تحديث الدفعة';

  @override
  String get msgPaymentRecorded => 'تم تسجيل الدفعة';

  @override
  String get labelNewPayment => 'دفعة جديدة';

  @override
  String labelOrderNumber(String number) {
    return 'طلب رقم $number';
  }

  @override
  String get labelPharmacyPrefix => 'الصيدلية:';

  @override
  String labelTotalAmountPrefix(String amount) {
    return 'إجمالي المبلغ: $amount عملة';
  }

  @override
  String get labelStatusPrefix => 'الحالة:';

  @override
  String labelProgressPrefix(int fulfilled, int total) {
    return 'التقدم: $fulfilled / $total عناصر';
  }

  @override
  String get msgSelectExcessToFulfill =>
      'يرجى اختيار وفرة واحدة على الأقل لتنفيذها';

  @override
  String msgFulfillSuccess(int count) {
    return 'تم تنفيذ $count عنصر بنجاح';
  }

  @override
  String msgFulfillPartialFail(int success, int fail) {
    return 'تم تنفيذ $success عنصر بنجاح، وفشل $fail';
  }

  @override
  String get msgAllFulfillmentsFailed => 'فشلت جميع عمليات التنفيذ';

  @override
  String labelSelectedUnits(int count) {
    return 'مختار: $count وحدات';
  }

  @override
  String labelItemsCount(Object count) {
    return '$count عناصر';
  }

  @override
  String get labelVolumePrefix => 'الحجم:';

  @override
  String get labelPricePrefix => 'السعر:';

  @override
  String labelNeed(int count) {
    return 'احتياج: $count';
  }

  @override
  String get msgNoMatchingExcesses => 'لا توجد وفرة مطابقة متاحة';

  @override
  String get labelSaleRatioPrefix => 'نسبة البيع:';

  @override
  String get labelExpiryPrefix => 'الانتهاء:';

  @override
  String get actionMax => 'الأقصى';

  @override
  String actionSubmitFulfillment(int count) {
    return 'إرسال تنفيذ الطلب ($count وحدات)';
  }

  @override
  String get msgAssignmentFailed =>
      'فشل التعيين. تحقق مما إذا كان لا يزال متاحًا.';

  @override
  String get msgNoAvailableTransactions => 'لا توجد معاملات متاحة.';

  @override
  String get msgNoTasksAssigned => 'لا توجد مهام معينة لك.';

  @override
  String labelSelectedUnitsShort(int count) {
    return 'تم اختيار: $count';
  }

  @override
  String get labelAvailableUnitsPrefix => 'متاح:';

  @override
  String get msgProcessing => 'جاري المعالجة...';

  @override
  String get labelOrderHash => 'طلب رقم ';

  @override
  String get labelTransactionHash => 'المعاملة: ';

  @override
  String get labelUnitsSuffix => 'وحدات';

  @override
  String get labelExcessPharmacy => 'الوفرة:';

  @override
  String get labelShortagePharmacy => 'النقص:';

  @override
  String get actionAssignToMe => 'تعيين لي';

  @override
  String get actionRequestAcceptance => 'طلب قبول';

  @override
  String get actionRequestCompletion => 'طلب إكمال';

  @override
  String get labelRequestPending => 'الطلب قيد الانتظار...';

  @override
  String get labelStatus => 'الحالة';

  @override
  String labelTransactionNumber(String id) {
    return 'معاملة رقم $id';
  }

  @override
  String get labelOrderPrefix => 'طلب رقم ';

  @override
  String get helpSupportTitle => 'المساعدة والدعم';

  @override
  String get catStockInventory => '📦 المخزون والوفرة';

  @override
  String get qHowToAddExcess => 'كيف يمكنني إضافة وفرة؟';

  @override
  String get aHowToAddExcess =>
      'اذهب إلى التبويب الرئيسي واضغط على \"إضافة منتج وفرة\". املأ تفاصيل المنتج، تاريخ الانتهاء، والخصم. بمجرد الإرسال، ستتمكن الصيدليات الأخرى من رؤيته وطلبه.';

  @override
  String get qWhatIsShortage => 'ما هو \"طلب النقص\"؟';

  @override
  String get aWhatIsShortage =>
      'إذا كنت بحاجة إلى منتج غير متاح في مخزونك، يمكنك إنشاء \"طلب نقص\". الصيدليات الأخرى التي لديها وفرة من هذا المنتج يمكنها تلبية طلبك.';

  @override
  String get catBalanceFinance => '💰 الرصيد والمالية';

  @override
  String get qHowToGetBalance => 'كيف يمكنني الحصول على رصيدي؟';

  @override
  String get aHowToGetBalance =>
      'يتم عرض رصيدك الحالي في أعلى التبويب الرئيسي. يمكنك أيضاً عرض تفاصيل دقيقة في \"سجل المعاملات\".';

  @override
  String get qHowCommissionWorks => 'كيف تعمل العمولة؟';

  @override
  String get aHowCommissionWorks =>
      'تفرض MediSync عمولة صغيرة على عمليات المطابقة الناجحة بين الصيدليات. هذا يساعدنا في صيانة المنصة وتقديم خدمات التوصيل.';

  @override
  String get catTransactionsHistory => '🔄 المعاملات والسجل';

  @override
  String get qWhereIsHistory => 'أين سجل طلباتي؟';

  @override
  String get aWhereIsHistory =>
      'يمكن العثور على جميع معاملاتك السابقة وطلبات المخزون الحالية في تبويب \"السجل\" في أسفل لوحة التحكم.';

  @override
  String get qHowToTrackDelivery => 'كيف أتتبع التوصيل؟';

  @override
  String get aHowToTrackDelivery =>
      'بمجرد تأكيد المطابقة وتعيين عامل توصيل، يمكنك عرض الحالة المباشرة في قسم \"تتبع التوصيل\" لطلبك النشط.';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabRequests => 'الطلبات';

  @override
  String get tabLedger => 'دفتر الأستاذ';

  @override
  String get labelCurrentBalance => 'الرصيد الحالي';

  @override
  String get labelOwnerInformation => 'معلومات المالك';

  @override
  String get msgFailedToLoadDetails => 'فشل تحميل التفاصيل';

  @override
  String get msgNoRequestHistoryFound => 'لم يتم العثور على سجل طلبات.';

  @override
  String get msgNoFinancialHistoryFound => 'لم يتم العثور على سجل مالي.';

  @override
  String get deliveryDashboardTitle => 'لوحة تحكم التوصيل';

  @override
  String get tabMyTasks => 'مهامي';

  @override
  String get tabHistory => 'السجل';

  @override
  String get msgAssigningToYou => 'جاري التعيين لك...';

  @override
  String get msgAssignmentSuccess => 'نجاح! تم تعيين المعاملة.';

  @override
  String get msgRequestSent => 'تم إرسال الطلب!';

  @override
  String get catAccountManagement => '⚙️ إدارة الحساب';

  @override
  String get qHowToEditProfile => 'كيف يمكنني تعديل بيانات صيدليتي؟';

  @override
  String get aHowToEditProfile =>
      'اذهب إلى \"الحساب\" -> \"حسابي\" واضغط على زر \"تعديل\". قم بتحديث معلوماتك وأرسلها. سيتم معالجة طلبك قريباً.';

  @override
  String get qCanIChangePassword => 'هل يمكنني تغيير كلمة المرور؟';

  @override
  String get aCanIChangePassword =>
      'نعم! استخدم خيار \"إعادة تعيين كلمة المرور\" في قائمة الحساب. ستحتاج إلى كلمة مرورك الحالية لتعيين كلمة مرور جديدة.';

  @override
  String get labelAdminDeliveryRequests => 'طلبات التوصيل';

  @override
  String get actionSaveSettings => 'حفظ الإعدادات';

  @override
  String get statusUnknown => 'غير معروف';

  @override
  String get labelProduct => 'المنتج';

  @override
  String get labelUnitsShort => 'وحدات';

  @override
  String get labelCoins => 'عملة';

  @override
  String get actionUpdateTransaction => 'تحديث المعاملة';

  @override
  String get msgFailedUpdateTransaction => 'فشل في تحديث المعاملة';

  @override
  String get msgRequestApproved => 'تمت الموافقة على الطلب';

  @override
  String get msgRequestRejected => 'تم رفض الطلب';

  @override
  String get msgFailedReviewRequest => 'فشل في مراجعة الطلب';

  @override
  String get msgCleanupOldRequests => 'تم تنظيف الطلبات القديمة (أقدم من شهر)';

  @override
  String get msgCleanupFailed => 'فشل التنظيف';

  @override
  String get labelCleanup => 'تنظيف';

  @override
  String get msgConfirmCleanup =>
      'هل تريد حذف جميع الطلبات المعتمدة/المرفوضة التي مضى عليها أكثر من شهر؟';

  @override
  String get msgNoPendingDeliveryRequests => 'لا توجد طلبات توصيل معلقة.';

  @override
  String titleEditTransaction(String serial) {
    return 'تعديل المعاملة #$serial';
  }

  @override
  String get labelOrderBadge => 'طلب';

  @override
  String get labelTotalOriginalNeeded => 'إجمالي الاحتياج الأصلي:';

  @override
  String get labelAvailableOriginal => 'المتاح (المتاح الأصلي):';

  @override
  String get labelTotalDistribution => 'إجمالي التوزيع:';

  @override
  String get msgTotalQtyCannotBeZero => 'إجمالي الكمية لا يمكن أن يكون صفراً';

  @override
  String get msgTransactionUpdated => 'تم تحديث المعاملة بنجاح';

  @override
  String get msgExecuting => 'جاري التنفيذ...';

  @override
  String labelPortionInTx(int count) {
    return 'الجزء في هذه المعاملة: $count';
  }

  @override
  String get labelCommissionRatios => 'نسب العمولة (%)';

  @override
  String get labelMinComm => 'العمولة الدنيا (%)';

  @override
  String get helperMinComm =>
      'العمولة الافتراضية لإعادة توازن الوفرة الحقيقية.';

  @override
  String get labelShortageComm => 'عمولة النقص (%)';

  @override
  String get helperShortageComm => 'العمولة الافتراضية لتلبية طلبات النقص.';

  @override
  String get labelShortageSellerRewardField => 'مكافأة البائع في النقص (%)';

  @override
  String get helperShortageSellerReward =>
      'المكافأة الافتراضية لموفر تلبية النقص.';

  @override
  String get msgSettingsUpdated => 'تم تحديث الإعدادات بنجاح';

  @override
  String get msgFailedUpdateSettings => 'فشل في تحديث الإعدادات';

  @override
  String get msgPleaseEnterValue => 'يرجى إدخال قيمة';

  @override
  String get msgEnterNumberBetween0And20 => 'أدخل رقماً بين 0 و 20';

  @override
  String get msgEnterPositiveNumber => 'أدخل رقماً موجباً';

  @override
  String get titleFeedbackComplaints => 'الآراء والشكاوى';

  @override
  String get msgNoSuggestionsFound => 'لم يتم العثور على اقتراحات.';

  @override
  String get labelUnknownPharmacy => 'صيدلية غير معروفة';

  @override
  String labelUserPrefix(String name) {
    return 'المستخدم: $name';
  }

  @override
  String labelFromPrefix(String name) {
    return 'من: $name';
  }

  @override
  String get titleFeedbackDetails => 'تفاصيل الرأي';

  @override
  String get msgNoContentProvided => 'لم يتم تقديم محتوى';

  @override
  String get titleProductSuggestions => 'اقتراحات المنتجات الجديدة';

  @override
  String titleSuggestionAction(String status) {
    return '$status اقتراح';
  }

  @override
  String msgConfirmSuggestionAction(String status) {
    return 'هل أنت متأكد أنك تريد $status هذا الاقتراح؟';
  }

  @override
  String get labelReviewerNotesOptional => 'ملاحظات المراجع (اختياري)';

  @override
  String get labelProposedPrice => 'السعر المقترح';

  @override
  String get labelSuggestedBy => 'مقترح بواسطة';

  @override
  String labelReviewerNotes(String notes) {
    return 'ملاحظات المراجع: $notes';
  }

  @override
  String get hintSearchSuggestions => 'البحث في الاقتراحات (* للكل)...';

  @override
  String titleBuyProduct(String name, String volume) {
    return 'شراء $name ($volume)';
  }

  @override
  String labelTotalCoins(String amount) {
    return 'الإجمالي: $amount عملة';
  }

  @override
  String get titleExcessFollowUp => 'متابعة الزيادات';

  @override
  String get msgNoFulfilledExcesses => 'لا توجد زيادات مكتملة';

  @override
  String get msgNoPendingExcesses => 'لا توجد زيادات معلقة';

  @override
  String get msgNoAvailableExcesses => 'لا توجد زيادات متاحة';

  @override
  String get msgActionCompletedLocked => 'هذا الإجراء مكتمل ومغلق.';

  @override
  String get msgCannotDeleteTakenExcess =>
      'لا يمكن حذف الزيادة التي تم سحب مخزون منها بالفعل.';

  @override
  String get labelConfirmDelete => 'تأكيد الحذف';

  @override
  String get msgConfirmDeleteExcess => 'هل أنت متأكد أنك تريد حذف هذه الزيادة؟';

  @override
  String get msgConfirmDeleteExcessAvailable =>
      'هل أنت متأكد أنك تريد حذف هذه الزيادة المتاحة؟';

  @override
  String get labelRejectExcessOffer => 'رفض عرض الزيادة';

  @override
  String get hintRejectionReason =>
      'مثال: السعر مرتفع جداً، تاريخ الانتهاء قريب جداً';

  @override
  String get labelConfirmApproval => 'تأكيد الموافقة';

  @override
  String get msgConfirmApproveExcess =>
      'هل أنت متأكد أنك تريد الموافقة على هذه الزيادة وجعلها متاحة للمطابقة؟';

  @override
  String get labelNewPrice => 'سعر جديد';

  @override
  String get labelOff => 'خصم';
}
