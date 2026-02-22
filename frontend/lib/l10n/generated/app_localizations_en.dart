// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World';

  @override
  String get title => 'MediSync';

  @override
  String get welcomeToMediSync => 'Welcome to MediSync';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailRequiredError => 'Please enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordRequiredError => 'Please enter your password';

  @override
  String get loginButton => 'Login';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionAddToHub => 'Add to Hub';

  @override
  String get titleAddToHub => 'Move to Hub';

  @override
  String get labelSelectHub => 'Select Hub';

  @override
  String get labelHubQuantity => 'Quantity to Move';

  @override
  String get msgMoveToHubSuccess => 'Successfully moved to hub';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDelete => 'Delete';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get signUpPrompt => 'Don\'t have an account? Sign up';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get requiredError => 'Required';

  @override
  String get invalidEmailError => 'Invalid email';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get invalidPhoneError =>
      'Invalid phone number (11 digits starting with 01)';

  @override
  String get passwordMinLengthError => 'Too short (min 8 chars)';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get welcomeMessage => 'Welcome to MediSync!';

  @override
  String get linkPharmacyInstructions =>
      'To start using the platform, you need to link your pharmacy and provide documentation.';

  @override
  String get addNewPharmacyButton => 'Adding New Pharmacy';

  @override
  String get awaitingApprovalTitle => 'Awaiting Approval';

  @override
  String get awaitingApprovalMessage =>
      'Your documents have been submitted and are currently being reviewed by the admin. We will notify you once your account is active.';

  @override
  String get checkStatusButton => 'Check Status Now';

  @override
  String get pendingCartPlaceholder => 'Pending Cart (Coming Soon)';

  @override
  String balanceDisplay(String amount) {
    return 'Balance: $amount coins';
  }

  @override
  String get reloadTooltip => 'Reload Current Tab';

  @override
  String get navHome => 'Home';

  @override
  String get navOrderHistory => 'Order History';

  @override
  String get navPendingCart => 'Pending Cart';

  @override
  String get navAccount => 'Account';

  @override
  String get urgentShortages => 'URGENT SHORTAGES';

  @override
  String get noShortages => 'No current shortages reported';

  @override
  String get adSpace => 'Advertisement Space\n(Promotions & Offers)';

  @override
  String get menuRequestsHistory => 'Requests History';

  @override
  String get menuShoppingTour => 'Shopping Tour';

  @override
  String get menuAddShortage => 'Add Shortage';

  @override
  String get menuAddExcess => 'Add Excess';

  @override
  String get menuStartTransactions => 'Start Transactions';

  @override
  String get menuViewTransactions => 'View Transactions';

  @override
  String get menuSuggestProduct => 'Suggest Product';

  @override
  String get menuSuggestionsComplaints => 'Suggestions/Complaints';

  @override
  String get menuBalanceHistory => 'Balance History';

  @override
  String get menuManageUsers => 'Manage Users';

  @override
  String get adminDashboardTitle => 'Admin Dashboard';

  @override
  String get menuFollowUpExcesses => 'Follow-up Excesses';

  @override
  String get menuFollowUpShortages => 'Follow-up Shortages';

  @override
  String get menuManageOrders => 'Manage Orders';

  @override
  String get menuDeliveryRequests => 'Delivery Requests';

  @override
  String get menuManageProducts => 'Manage Products';

  @override
  String get menuProductSuggestions => 'Product Suggestions';

  @override
  String get menuManagePharmacies => 'Manage Pharmacies';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortBalanceAsc => 'Balance (Low to High)';

  @override
  String get sortBalanceDesc => 'Balance (High to Low)';

  @override
  String get sortDefault => 'Default (Newest First)';

  @override
  String get menuAppSuggestions => 'App Suggestions';

  @override
  String get menuAccountUpdates => 'Account Updates';

  @override
  String get menuSystemSettings => 'System Settings';

  @override
  String get manageUsersTitle => 'Manage Users';

  @override
  String get tabNewRequests => 'New Requests';

  @override
  String get tabActiveUsers => 'Active Users';

  @override
  String get searchUsersHint => 'Search users (* for wildcard)...';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get noMatchesFound => 'No matches found.';

  @override
  String get noPharmacyLinked => 'No Pharmacy Linked';

  @override
  String get userInformation => 'User Information';

  @override
  String get labelName => 'Name';

  @override
  String get labelPhone => 'Phone';

  @override
  String get pharmacyDocumentation => 'Pharmacy Documentation';

  @override
  String get labelPharmacyName => 'Pharmacy Name';

  @override
  String get labelOwnerName => 'Owner Name';

  @override
  String get labelNationalId => 'National ID';

  @override
  String get labelPharmacyAddress => 'Pharmacy Address';

  @override
  String get labelPharmacistCard => 'Pharmacist Card';

  @override
  String get labelCommercialRegistry => 'Commercial Registry';

  @override
  String get labelTaxCard => 'Tax Card';

  @override
  String get labelLicense => 'License';

  @override
  String get dialogRejectRequest => 'Reject Request';

  @override
  String get dialogRejectMessage =>
      'Are you sure you want to reject this user registration?';

  @override
  String get actionReject => 'Reject';

  @override
  String get dialogApproveUser => 'Approve User';

  @override
  String get dialogApproveMessage =>
      'Are you sure you want to approve this user and activate their account?';

  @override
  String get actionApprove => 'Approve';

  @override
  String get managementActions => 'Management Actions';

  @override
  String get actionActivate => 'Activate';

  @override
  String get actionSuspend => 'Suspend';

  @override
  String get dialogActivateUser => 'Activate User';

  @override
  String get dialogSuspendUser => 'Suspend User';

  @override
  String get dialogActivateUserMessage =>
      'Are you sure you want to activate this account?';

  @override
  String get dialogSuspendUserMessage =>
      'Are you sure you want to suspend this account?';

  @override
  String get actionResetPass => 'Reset Pass';

  @override
  String get dialogResetPassword => 'Reset Password';

  @override
  String get dialogResetPasswordMessage =>
      'Are you sure you want to reset this user\'s password to \"00000000\"?';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSuccessful => 'Action successful';

  @override
  String get dialogCreateDeliveryAccount => 'Create Delivery Account';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelPassword => 'Password';

  @override
  String get errorRequired => 'Required';

  @override
  String get errorMin6Chars => 'Min 6 chars';

  @override
  String get msgDeliveryUserCreated =>
      'Delivery user created and pending approval';

  @override
  String get msgFailedCreateUser => 'Failed to create user';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String get noImage => 'No Image';

  @override
  String get matchableProductsTitle => 'Matchable Products';

  @override
  String get searchProductsHint => 'Search products (* for wildcard)...';

  @override
  String get noMatchableItemsFound => 'No matchable items found.';

  @override
  String get shortageFulfillment => 'Shortage Fulfillment';

  @override
  String matchingAvailableInVolumes(int count) {
    return 'Matching available in $count volumes';
  }

  @override
  String get manageProductsTitle => 'Manage Products';

  @override
  String get managePricesTitle => 'Manage Prices';

  @override
  String priceCoins(String price) {
    return '$price coins';
  }

  @override
  String get labelCustomerPrice => 'Customer Price';

  @override
  String get dialogAddPrice => 'Add Price';

  @override
  String get actionAddNewPrice => 'Add New Price';

  @override
  String get actionDone => 'Done';

  @override
  String get dialogEditProductInfo => 'Edit Product Info';

  @override
  String get labelProductName => 'Product Name';

  @override
  String get actionUpdate => 'Update';

  @override
  String get actionLoadMore => 'Load More';

  @override
  String get noPricesSet => 'No prices set';

  @override
  String get coinsSuffix => 'coins';

  @override
  String get tooltipDeactivate => 'Deactivate';

  @override
  String get tooltipActivate => 'Activate';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusInactive => 'INACTIVE';

  @override
  String get statusPending => 'PENDING';

  @override
  String get statusAvailable => 'AVAILABLE';

  @override
  String get statusFulfilled => 'FULFILLED';

  @override
  String get statusPartiallyFulfilled => 'PARTIALLY FULFILLED';

  @override
  String get statusSold => 'SOLD';

  @override
  String get statusExpired => 'EXPIRED';

  @override
  String get statusCancelled => 'CANCELLED';

  @override
  String get statusRejected => 'REJECTED';

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
  String get menuRefresh => 'Refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get tabPending => 'Pending';

  @override
  String get tabAvailable => 'AVAILABLE';

  @override
  String get tabFulfilled => 'Fulfilled';

  @override
  String get tabActive => 'Active';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionBack => 'Back';

  @override
  String get actionLogout => 'Log out';

  @override
  String get labelVolume => 'Volume';

  @override
  String get labelQuantity => 'Quantity';

  @override
  String get labelPrice => 'Price';

  @override
  String get labelNotes => 'Notes';

  @override
  String get labelExpiry => 'Expiry';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get msgDeletedSuccessfully => 'Deleted successfully';

  @override
  String get msgSubmittedSuccessfully => 'Submitted successfully';

  @override
  String get titleSuggestProduct => 'Suggest New Product';

  @override
  String get titleSuggestionsComplaints => 'Suggestions & Complaints';

  @override
  String get titleSubscriptionPlans => 'Subscription Plans';

  @override
  String get titleNotifications => 'Notifications';

  @override
  String get labelArabic => 'Arabic';

  @override
  String get labelEnglish => 'English';

  @override
  String get labelAppLanguage => 'App Language';

  @override
  String labelPriceWithAmount(String amount) {
    return 'Price: $amount';
  }

  @override
  String get tooltipMarkAllAsSeen => 'Mark all as seen';

  @override
  String get msgNoNotifications => 'No notifications yet';

  @override
  String get titlePharmacyDetails => 'Pharmacy Details';

  @override
  String get labelSubmitDocumentation => 'Submit Documentation';

  @override
  String get msgProvideInformation =>
      'Please provide the following information as written in your official documents.';

  @override
  String get labelPharmacyNameWithHint => 'Pharmacy Name (اسم الصيدلية)';

  @override
  String get labelOwnerNameWithHint =>
      'Owner\'s Name (اسم صاحب الصيدلية كما مدون في الرخصه)';

  @override
  String get labelNationalIdWithHint => 'National ID (بطاقة رقم قومي)';

  @override
  String get msgMustBe14Digits => 'Must be exactly 14 digits';

  @override
  String get errorNationalIdRequired => 'National ID is required';

  @override
  String get errorNationalIdInvalid => 'National ID must be exactly 14 digits';

  @override
  String get labelDetailedAddress => 'Detailed Address';

  @override
  String get labelDetailedAddressWithHint =>
      'Detailed Address (العنوان بالتفصيل)';

  @override
  String get hintDetailedAddress => 'e.g. 123 Madinet Nasr, Cairo, Egypt';

  @override
  String get actionSubmitForApproval => 'Submit for Approval';

  @override
  String get actionChange => 'Change';

  @override
  String get actionUpload => 'Upload';

  @override
  String get msgSubmissionFailed => 'Submission failed';

  @override
  String get dialogConfirmLogout => 'Confirm Log out';

  @override
  String get dialogConfirmLogoutMsg => 'Are you sure you want to log out?';

  @override
  String get msgPleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get msgPleaseUploadAllDocs => 'Please upload all 4 documents';

  @override
  String get labelFeedbackDescription =>
      'We value your feedback. Please let us know if you have any suggestions for improvement or any complaints regarding the system.';

  @override
  String get labelFeedbackPlaceholder => 'Type your message here...';

  @override
  String get labelFeedbackTitle => 'Your Feedback';

  @override
  String get msgFeedbackSuccess => 'Thank you for your feedback!';

  @override
  String get msgGenericError => 'An error occurred. Please try again.';

  @override
  String get labelRequired => 'Required';

  @override
  String get msgComingSoon => 'Coming Soon!';

  @override
  String get msgSubscriptionDescription =>
      'We are working on exclusive premium features and subscription plans to help you grow your pharmacy business.';

  @override
  String get labelUserName => 'User Name';

  @override
  String get labelUserEmailPlaceholder => 'email@example.com';

  @override
  String get menuMyAccount => 'My Account';

  @override
  String get subtitleMyAccount => 'View and edit your personal data';

  @override
  String get menuHelp => 'Help';

  @override
  String get subtitleHelp => 'FAQs and app usage guide';

  @override
  String get subtitleSubscription => 'Explore premium features';

  @override
  String get menuResetPassword => 'Reset My Password';

  @override
  String get subtitleResetPassword => 'Securely update your password';

  @override
  String get dialogLogoutMsg =>
      'Are you sure you want to log out of your account?';

  @override
  String get titleShortageFollowup => 'Follow-up Shortages';

  @override
  String get titleRequestsHistory => 'Requests History';

  @override
  String get dialogConfirmDelete => 'Confirm Delete';

  @override
  String get dialogConfirmDeleteMsg =>
      'Are you sure you want to delete this item?';

  @override
  String get msgNoActiveShortages => 'No active shortages';

  @override
  String get msgNoFulfilledShortages => 'No fulfilled shortages';

  @override
  String get msgNoHistoryFound => 'No history found';

  @override
  String labelPharmacy(String name) {
    return 'Pharmacy: $name';
  }

  @override
  String labelQuantityNeeded(int count) {
    return 'Quantity Needed: $count';
  }

  @override
  String labelRemainingQuantity(int count) {
    return 'Remaining Quantity: $count';
  }

  @override
  String labelQuantityFulfilled(int count) {
    return 'Quantity Fulfilled: $count';
  }

  @override
  String get msgCannotDeleteFulfilledShortage =>
      'Cannot delete shortage that has already been partially fulfilled.';

  @override
  String get dialogConfirmDeleteShortage =>
      'Are you sure you want to delete this shortage?';

  @override
  String get msgShortageRequirementCompleted =>
      'This requirement is completed.';

  @override
  String get labelExcessOffer => 'Excess Offer';

  @override
  String get labelShortageRequest => 'Shortage Request';

  @override
  String get labelMarketOrder => 'Shopping Tour Item';

  @override
  String get labelMarketInsight => 'Competitive Market Insight';

  @override
  String get labelCompetitorExpiry => 'Expiry';

  @override
  String get labelCompetitorSale => 'Sale %';

  @override
  String get labelCompetitorQuantity => 'Quantity';

  @override
  String get msgNoMarketInsight =>
      'No existing offers found for those criteria.';

  @override
  String get labelType => 'Type';

  @override
  String get labelTotalQuantity => 'Total Quantity:';

  @override
  String get labelRemaining => 'Remaining';

  @override
  String get labelDiscount => 'Discount';

  @override
  String get labelDiscountAmount => 'Discount Amount';

  @override
  String get labelFinalPrice => 'Final Price';

  @override
  String get labelRejectionReason => 'REJECTION REASON:';

  @override
  String labelCreated(String date) {
    return 'Created: $date';
  }

  @override
  String msgCannotDeleteFulfilledItem(String item, String action) {
    return 'Cannot delete $item that has already been $action.';
  }

  @override
  String get labelExcess => 'Excess';

  @override
  String get labelShortage => 'Shortage';

  @override
  String get labelTaken => 'taken';

  @override
  String get labelFulfilled => 'fulfilled';

  @override
  String get labelOffer => 'offer';

  @override
  String get labelRequest => 'request';

  @override
  String titleMatchProduct(String product) {
    return 'Match: $product';
  }

  @override
  String get labelShortages => 'Shortages';

  @override
  String get labelExcesses => 'Excesses';

  @override
  String get labelTime => 'Time';

  @override
  String get labelSalePercentage => 'Sale %';

  @override
  String get msgSelectShortageFirst => 'Please select a shortage first';

  @override
  String get msgShortageFulfilled => 'Shortage quantity already fulfilled';

  @override
  String get labelShortageFulfillment => 'Shortage Fulfillment';

  @override
  String labelVol(String name) {
    return 'Vol: $name';
  }

  @override
  String labelNeeded(int count) {
    return 'Needed: $count';
  }

  @override
  String labelSaleRatio(num ratio) {
    return 'Sale Ratio: $ratio%';
  }

  @override
  String labelAllocated(int current, int total) {
    return 'Allocated: $current / $total';
  }

  @override
  String get msgOverLimit => 'OVER LIMIT!';

  @override
  String get labelAdminOverrides => 'Admin Overrides (Optional)';

  @override
  String get labelBuyerComm => 'Buyer Comm %';

  @override
  String get labelSellerRew => 'Seller Rew %';

  @override
  String get hintShFulfill => 'Sh. Fulfill';

  @override
  String get actionSubmitTransaction => 'SUBMIT TRANSACTION';

  @override
  String get msgTransactionCreated => 'Transaction created successfully';

  @override
  String get labelPersonalInformation => 'Personal Information';

  @override
  String get labelFullName => 'Full Name';

  @override
  String get labelEmailAddress => 'Email Address';

  @override
  String get labelPhoneNumber => 'Phone Number';

  @override
  String get labelPharmacyInformation => 'Pharmacy Information';

  @override
  String get labelPharmacyPhone => 'Pharmacy Phone';

  @override
  String get actionSaveChanges => 'Save Changes';

  @override
  String get msgUpdateRequested => 'Update request sent to Admin!';

  @override
  String get msgUpdateFailed => 'Failed to send request';

  @override
  String get msgPendingUpdateInfo =>
      'Awaiting approval for your previous update request. New edits will replace the pending one.';

  @override
  String get labelPharmacyInfo => 'Pharmacy Info';

  @override
  String get msgNoAddress => 'No address provided';

  @override
  String get msgNoPhone => 'No phone provided';

  @override
  String labelOwner(String name) {
    return 'Owner: $name';
  }

  @override
  String get titleShoppingTour => 'Shopping Tour';

  @override
  String get labelSelectQuantitiesByPrice => 'Select quantities by price:';

  @override
  String labelAvailableCount(int count) {
    return 'Available: $count';
  }

  @override
  String labelSubtotalAmount(String amount) {
    return 'Subtotal: $amount coins';
  }

  @override
  String get labelTotalCost => 'Total Cost:';

  @override
  String labelUnitsCount(int count) {
    return '$count units';
  }

  @override
  String get actionUpdateCart => 'Update Cart';

  @override
  String get msgRemovedFromCart => 'Removed from cart';

  @override
  String get msgCartUpdated => 'Cart updated!';

  @override
  String get titleShoppingCart => 'Shopping Cart';

  @override
  String get msgCartEmpty => 'Your cart is empty';

  @override
  String get labelOrderNotesOptional => 'Order Notes (Optional)';

  @override
  String get hintAddSpecialInstructions => 'Add special instructions...';

  @override
  String get actionPlaceOrder => 'Place Order';

  @override
  String get msgPlacingOrder => 'Placing Order...';

  @override
  String get msgOrderPlaced => 'Order placed successfully!';

  @override
  String get msgOrderFailed => 'Failed to place order';

  @override
  String get hintSearchProducts => 'Search products...';

  @override
  String get msgNoMarketItems => 'No items available in the market';

  @override
  String get msgNoSearchMatches => 'No items match your search';

  @override
  String labelAvailableUnits(int count) {
    return '$count available';
  }

  @override
  String labelPriceOptions(int count) {
    return '$count prices';
  }

  @override
  String get titleEditExcess => 'Edit Excess Stock';

  @override
  String get titleAddExcess => 'Add Excess Stock';

  @override
  String get labelSelectExpiryMonthYear => 'Select Expiry (Month/Year)';

  @override
  String get msgSelectExpiryDate => 'Please select expiry date';

  @override
  String get msgSelectProductVolume => 'Please select product and volume';

  @override
  String get msgInvalidSalePercentage => 'Invalid sale percentage';

  @override
  String get msgEnterValidQuantity => 'Please enter a valid quantity';

  @override
  String labelProductWithName(String name) {
    return 'Product: $name';
  }

  @override
  String labelVolumeWithName(String name) {
    return 'Volume: $name';
  }

  @override
  String get hintLoading => 'Loading...';

  @override
  String get hintSelectVolume => 'Select volume';

  @override
  String get labelPriceCoins => 'Price (coins)';

  @override
  String get labelSelectPrice => 'Select Price';

  @override
  String get actionEnterManualPrice => 'Enter Manual Price';

  @override
  String get labelManualPrice => 'Manual Price';

  @override
  String get msgInvalidQuantity => 'Invalid quantity';

  @override
  String get msgTooHigh => 'Too high';

  @override
  String get msgTooLow => 'Too low';

  @override
  String get labelExpiryDateMMYY => 'Expiry Date (MM/YY)';

  @override
  String get hintSelectExpiryDate => 'Select Expiry Date';

  @override
  String get labelRequestType => 'Request Type';

  @override
  String get labelRealExcess => 'Real Excess';

  @override
  String get labelPercentageValue => 'Sale Percentage (%)';

  @override
  String msgSystemCommissionInfo(String percentage) {
    return 'The current system commission is $percentage%, using higher sales can accelerate your transactions';
  }

  @override
  String get actionUpdateExcess => 'Update Excess';

  @override
  String get actionSubmitExcess => 'Submit Excess';

  @override
  String get msgErrorLoadingVolumes => 'Error loading volumes';

  @override
  String get titleEditShortage => 'Edit Shortage';

  @override
  String get titleAddShortage => 'Add Shortage';

  @override
  String get msgShortageUpdated => 'Shortage updated successfully';

  @override
  String get msgShortageAdded => 'Shortage added successfully';

  @override
  String get msgErrorProcessingRequest => 'Error processing request';

  @override
  String get labelQuantityNeededField => 'Quantity Needed';

  @override
  String get msgQuantityDecreaseOnly => 'Quantity can only be decreased';

  @override
  String msgCannotBeLessThan(int count) {
    return 'Cannot be less than $count';
  }

  @override
  String get actionUpdateShortage => 'Update Shortage';

  @override
  String get actionSubmitShortage => 'Submit Shortage';

  @override
  String get labelUpdateSecurityDetails => 'Update your security details';

  @override
  String get labelPasswordLengthHint =>
      'Ensure your new password is at least 8 characters long.';

  @override
  String get labelCurrentPassword => 'Current Password';

  @override
  String get labelNewPassword => 'New Password';

  @override
  String get labelConfirmNewPassword => 'Confirm New Password';

  @override
  String get msgPasswordChangedSuccess => 'Password changed successfully!';

  @override
  String get msgPasswordChangeFailed => 'Failed to change password';

  @override
  String get msgPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get msgNoBalanceHistory => 'No balance history found.';

  @override
  String get labelBalanceUpdate => 'Balance Update';

  @override
  String get labelDate => 'Date';

  @override
  String get labelPrevBalance => 'Prev Balance';

  @override
  String get labelNewBalance => 'New Balance';

  @override
  String get labelBreakdown => 'Breakdown:';

  @override
  String get labelNotAvailable => 'N/A';

  @override
  String get manageOrdersTitle => 'Manage Orders';

  @override
  String get labelActiveUsers => 'Active Users';

  @override
  String get labelAccountStatus => 'Account Status';

  @override
  String get labelUnknown => 'UNKNOWN';

  @override
  String get actionSimulate => 'Simulate';

  @override
  String get actionCompensation => 'Compensation';

  @override
  String get actionHistory => 'History';

  @override
  String get actionPayment => 'Payment';

  @override
  String get actionPayments => 'Payments';

  @override
  String get dialogConfirmDeleteAdjustment => 'Confirm Delete';

  @override
  String get msgConfirmDeleteAdjustment =>
      'Are you sure? This will REVERT the adjustment.';

  @override
  String get actionDeleteRevert => 'Delete & Revert';

  @override
  String get msgAdjustmentReverted => 'Adjustment reverted successfully';

  @override
  String get dialogEditPayment => 'Edit Payment';

  @override
  String dialogRecordPayment(String name) {
    return 'Record Payment - $name';
  }

  @override
  String get labelPaymentType => 'Type';

  @override
  String get labelDeposit => '💰 Deposit';

  @override
  String get labelWithdrawal => '💸 Withdrawal';

  @override
  String get labelAdjustmentAmount => 'Amount';

  @override
  String get labelPaymentMethod => 'Method';

  @override
  String get labelCash => 'Cash';

  @override
  String get labelBankTransfer => 'Bank Transfer';

  @override
  String get labelCheque => 'Cheque';

  @override
  String get labelOther => 'Other';

  @override
  String get labelReferenceNumber => 'Reference Number';

  @override
  String get labelAdminNote => 'Admin Note';

  @override
  String get msgInvalidAmount => 'Invalid amount';

  @override
  String get msgPaymentUpdated => 'Payment updated';

  @override
  String get msgPaymentRecorded => 'Payment recorded';

  @override
  String get labelNewPayment => 'New Payment';

  @override
  String labelOrderNumber(String number) {
    return 'Order #$number';
  }

  @override
  String get labelPharmacyPrefix => 'Pharmacy:';

  @override
  String labelTotalAmountPrefix(String amount) {
    return 'Total Amount: $amount coins';
  }

  @override
  String get labelStatusPrefix => 'Status:';

  @override
  String labelProgressPrefix(int fulfilled, int total) {
    return 'Progress: $fulfilled / $total items';
  }

  @override
  String get msgSelectExcessToFulfill =>
      'Please select at least one excess to fulfill';

  @override
  String msgFulfillSuccess(int count) {
    return 'Successfully fulfilled $count item(s)';
  }

  @override
  String msgFulfillPartialFail(int success, int fail) {
    return 'Successfully fulfilled $success item(s), $fail failed';
  }

  @override
  String get msgAllFulfillmentsFailed => 'All fulfillments failed';

  @override
  String labelSelectedUnits(int count) {
    return 'Selected: $count units';
  }

  @override
  String labelItemsCount(Object count) {
    return '$count Items';
  }

  @override
  String get labelVolumePrefix => 'Volume:';

  @override
  String get labelPricePrefix => 'Price:';

  @override
  String labelNeed(int count) {
    return 'Need: $count';
  }

  @override
  String get msgNoMatchingExcesses => 'No matching excesses available';

  @override
  String get labelSaleRatioPrefix => 'Sale Ratio:';

  @override
  String get labelExpiryPrefix => 'Expiry:';

  @override
  String get actionMax => 'Max';

  @override
  String actionSubmitFulfillment(int count) {
    return 'Submit Order Fulfillment ($count units)';
  }

  @override
  String get msgAssignmentFailed =>
      'Assignment failed. Check if it\'s still available.';

  @override
  String get msgNoAvailableTransactions => 'No available transactions.';

  @override
  String get msgNoTasksAssigned => 'No tasks assigned to you.';

  @override
  String labelSelectedUnitsShort(int count) {
    return 'Selected: $count';
  }

  @override
  String get labelAvailableUnitsPrefix => 'Available:';

  @override
  String get msgProcessing => 'Processing...';

  @override
  String get labelOrderHash => 'Order #';

  @override
  String get labelTransactionHash => 'Transaction: ';

  @override
  String get labelUnitsSuffix => 'UNITS';

  @override
  String get labelExcessPharmacy => 'Excess:';

  @override
  String get labelShortagePharmacy => 'Shortage:';

  @override
  String get actionAssignToMe => 'Assign to Me';

  @override
  String get actionRequestAcceptance => 'Request Acceptance';

  @override
  String get actionRequestCompletion => 'Request Completion';

  @override
  String get labelRequestPending => 'Request Pending...';

  @override
  String get labelStatus => 'Status';

  @override
  String labelTransactionNumber(String id) {
    return 'Transaction #$id';
  }

  @override
  String get labelOrderPrefix => 'Order #';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get catStockInventory => '📦 Stock & Inventory';

  @override
  String get qHowToAddExcess => 'How can I add an excess?';

  @override
  String get aHowToAddExcess =>
      'Go to the Home tab and click on \"Add Excess Product\". Fill in the product details, expiry date, and discount. Once submitted, other pharmacies can see and request it.';

  @override
  String get qWhatIsShortage => 'What is a \"Shortage Request\"?';

  @override
  String get aWhatIsShortage =>
      'If you need a product that is not available in your stock, you can create a \"Shortage Request\". Other pharmacies with excess of that product can then fulfill your request.';

  @override
  String get catBalanceFinance => '💰 Balance & Financials';

  @override
  String get qHowToGetBalance => 'How can I get my balance?';

  @override
  String get aHowToGetBalance =>
      'Your current balance is displayed at the top of the Home tab. You can also view a detailed breakdown in your \"Transaction History\".';

  @override
  String get qHowCommissionWorks => 'How does the commission work?';

  @override
  String get aHowCommissionWorks =>
      'MediSync charges a small commission on successful matches between pharmacies. This helps us maintain the platform and provide delivery services.';

  @override
  String get catTransactionsHistory => '🔄 Transactions & History';

  @override
  String get qWhereIsHistory => 'Where is my requests history?';

  @override
  String get aWhereIsHistory =>
      'All your past transactions and current stock requests can be found in the \"History\" tab at the bottom of the dashboard.';

  @override
  String get qHowToTrackDelivery => 'How do I track a delivery?';

  @override
  String get aHowToTrackDelivery =>
      'Once a match is confirmed and a delivery person is assigned, you can view the live status in the \"Delivery Tracking\" section of your active order.';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabRequests => 'Requests';

  @override
  String get tabLedger => 'Ledger';

  @override
  String get labelCurrentBalance => 'Current Balance';

  @override
  String get labelOwnerInformation => 'Owner Information';

  @override
  String get msgFailedToLoadDetails => 'Failed to load details';

  @override
  String get msgNoRequestHistoryFound => 'No request history found.';

  @override
  String get msgNoFinancialHistoryFound => 'No financial history found.';

  @override
  String get deliveryDashboardTitle => 'Delivery Dashboard';

  @override
  String get tabMyTasks => 'MY TASKS';

  @override
  String get tabHistory => 'HISTORY';

  @override
  String get msgAssigningToYou => 'Assigning to you...';

  @override
  String get msgAssignmentSuccess => 'Success! Transaction assigned.';

  @override
  String get msgRequestSent => 'Request sent!';

  @override
  String get catAccountManagement => '⚙️ Account Management';

  @override
  String get qHowToEditProfile => 'How do I edit my pharmacy data?';

  @override
  String get aHowToEditProfile =>
      'Go to \"Account\" -> \"My Account\" and click the \"Edit\" button. Update your info and submit. Your request will be processed shortly.';

  @override
  String get qCanIChangePassword => 'Can I change my password?';

  @override
  String get aCanIChangePassword =>
      'Yes! Use the \"Reset My Password\" option in the Account menu. You will need your current password to set a new one.';

  @override
  String get labelAdminDeliveryRequests => 'Delivery Requests';

  @override
  String get actionSaveSettings => 'Save Settings';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get labelProduct => 'Product';

  @override
  String get labelUnitsShort => 'units';

  @override
  String get labelCoins => 'coins';

  @override
  String get actionUpdateTransaction => 'Update Transaction';

  @override
  String get msgFailedUpdateTransaction => 'Failed to update transaction';

  @override
  String get msgRequestApproved => 'Request Approved';

  @override
  String get msgRequestRejected => 'Request Rejected';

  @override
  String get msgFailedReviewRequest => 'Failed to review request';

  @override
  String get msgCleanupOldRequests =>
      'Old requests cleaned up (older than 1 month)';

  @override
  String get msgCleanupFailed => 'Cleanup failed';

  @override
  String get labelCleanup => 'Cleanup';

  @override
  String get msgConfirmCleanup =>
      'Delete all approved/rejected requests older than 1 month?';

  @override
  String get msgNoPendingDeliveryRequests => 'No pending delivery requests.';

  @override
  String titleEditTransaction(String serial) {
    return 'Edit Transaction #$serial';
  }

  @override
  String get labelOrderBadge => 'ORDER';

  @override
  String get labelTotalOriginalNeeded => 'Total Original Needed:';

  @override
  String get labelAvailableOriginal => 'Available (Original Available):';

  @override
  String get labelTotalDistribution => 'Total Distribution:';

  @override
  String get msgTotalQtyCannotBeZero => 'Total quantity cannot be zero';

  @override
  String get msgTransactionUpdated => 'Transaction updated successfully';

  @override
  String get msgExecuting => 'Executing...';

  @override
  String labelPortionInTx(int count) {
    return 'Portion in this transaction: $count';
  }

  @override
  String get labelSaleUpTo => 'Sale up to';

  @override
  String get labelSale => 'Sale';

  @override
  String get labelQty => 'Qty';

  @override
  String get actionBuy => 'Buy';

  @override
  String get labelStartsFrom => 'Starts from';

  @override
  String get msgConfirmDeleteExcessAvailable =>
      'Are you sure you want to delete this available excess?';

  @override
  String get labelRejectExcessOffer => 'Reject Excess Offer';

  @override
  String get hintRejectionReason => 'e.g., Price too high, Expiry too near';

  @override
  String get labelConfirmApproval => 'Confirm Approval';

  @override
  String get msgConfirmApproveExcess =>
      'Are you sure you want to approve this excess and make it available for matches?';

  @override
  String get labelNewPrice => 'New Price';

  @override
  String get priceLabel => 'Price';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get expiryLabel => 'Expiry';

  @override
  String get labelOff => 'Off';

  @override
  String get titleConfirmDelete => 'Confirm Delete';

  @override
  String get msgConfirmReversePayment =>
      'Are you sure? This will REVERSE the payment.';

  @override
  String get actionRecord => 'Record';

  @override
  String get msgPaymentDeleted => 'Payment deleted and reversed';

  @override
  String get titleFollowUpTransactions => 'Follow-up Transactions';

  @override
  String get labelAll => 'All';

  @override
  String labelBuyer(Object name) {
    return 'Buyer: $name';
  }

  @override
  String labelSeller(Object name) {
    return 'Seller: $name';
  }

  @override
  String get labelSellers => 'Sellers:';

  @override
  String labelTotalQty(Object count) {
    return 'Total Qty: $count';
  }

  @override
  String labelTotalValue(Object amount) {
    return 'Total Value: $amount coins';
  }

  @override
  String labelDelivery(Object name) {
    return 'Delivery: $name';
  }

  @override
  String get dialogConfirmAccept => 'Confirm Accept';

  @override
  String get msgConfirmAcceptTransaction =>
      'Are you sure you want to accept this transaction?';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionYesAccept => 'Yes, Accept';

  @override
  String get dialogConfirmComplete => 'Confirm Complete';

  @override
  String get msgConfirmCompleteTransaction =>
      'Are you sure you want to mark this transaction as completed?';

  @override
  String get actionComplete => 'Complete';

  @override
  String get actionYesComplete => 'Yes, Complete';

  @override
  String get dialogConfirmCancel => 'Confirm Cancel';

  @override
  String get msgConfirmCancelTransaction =>
      'Are you sure you want to cancel this transaction? All quantities will be returned to their respective pharmacies.';

  @override
  String get actionYesCancel => 'Yes, Cancel';

  @override
  String get labelEdit => 'Edit';

  @override
  String get labelEditRatios => 'Edit Ratios';

  @override
  String get dialogDetachDelivery => 'Detach Delivery';

  @override
  String get msgDetachDelivery =>
      'This will remove the assigned delivery person. The transaction will become available for assignment again.';

  @override
  String get actionDetach => 'Detach';

  @override
  String get msgDeliveryDetached => 'Delivery person detached';

  @override
  String get actionRevertTransaction => 'Revert Transaction';

  @override
  String get actionViewEditTicket => 'View/Edit Ticket';

  @override
  String labelRefundStatus(Object status) {
    return 'Status updated to $status';
  }

  @override
  String labelRef(Object ref) {
    return 'Ref: $ref';
  }

  @override
  String get labelBuyerCommPercentage => 'Buyer Commission % (Sh. Fulfill)';

  @override
  String get labelSellerRewardPercentage => 'Seller Reward % (Sh. Fulfill)';

  @override
  String get labelDescriptionReason => 'Description / Reason';

  @override
  String get actionUpdateTicket => 'Update Ticket';

  @override
  String get actionConfirmReversion => 'Confirm Reversion';

  @override
  String get titleReversalExpenses => 'Revert Transaction & Expenses';

  @override
  String get titleEditReversalTicket => 'Edit Reversal Ticket';

  @override
  String get labelAutomaticReversalSummary => 'AUTOMATIC REVERSAL SUMMARY:';

  @override
  String get labelInvolvedParties =>
      'INVOLVED PARTIES (Select to Add Expense):';

  @override
  String get labelAddExpense => 'Add Expense';

  @override
  String get labelAmountEgp => 'Amount (EGP):';

  @override
  String get actionNo => 'No';

  @override
  String get actionYes => 'Yes';

  @override
  String get msgNoData => 'No data found.';

  @override
  String get titleProductSuggestions => 'Product Suggestions';

  @override
  String get hintSearchSuggestions => 'Search suggestions...';

  @override
  String get msgNoSuggestionsFound => 'No product suggestions found.';

  @override
  String get labelProposedPrice => 'Proposed Price';

  @override
  String get labelSuggestedBy => 'Suggested By';

  @override
  String labelReviewerNotes(String notes) {
    return 'Reviewer Notes: $notes';
  }

  @override
  String get msgSettingsUpdated => 'Settings updated successfully!';

  @override
  String get msgFailedUpdateSettings => 'Failed to update settings.';

  @override
  String get labelCommissionRatios => 'Commission Ratios';

  @override
  String get labelMinComm => 'Minimum Commission (%)';

  @override
  String get helperMinComm => 'Minimum percentage deducted from transactions';

  @override
  String get msgPleaseEnterValue => 'Please enter a value';

  @override
  String get msgEnterNumberBetween0And20 =>
      'Please enter a number between 0 and 20';

  @override
  String get labelShortageComm => 'Shortage Commission (Coins)';

  @override
  String get helperShortageComm =>
      'Coins deducted per unit for shortage fulfillment';

  @override
  String get msgEnterPositiveNumber => 'Please enter a positive number';

  @override
  String get labelShortageSellerRewardField => 'Shortage Seller Reward (Coins)';

  @override
  String get helperShortageSellerReward => 'Coins rewarded to seller per unit';

  @override
  String get titleFeedbackComplaints => 'Feedback & Complaints';

  @override
  String get labelUnknownPharmacy => 'Unknown Pharmacy';

  @override
  String labelUserPrefix(String user) {
    return 'User: $user';
  }

  @override
  String get titleFeedbackDetails => 'Feedback Details';

  @override
  String labelFromPrefix(String from) {
    return 'From: $from';
  }

  @override
  String get msgConfirmDeleteExcess =>
      'Are you sure you want to delete this excess stock?';

  @override
  String get msgNoAvailableExcesses => 'No available excess stock found.';

  @override
  String get msgCannotDeleteTakenExcess =>
      'Cannot delete an excess that is already being used for a transaction.';

  @override
  String get labelConfirmDelete => 'Confirm Delete';

  @override
  String titleSuggestionAction(String action) {
    return '$action Suggestion';
  }

  @override
  String msgConfirmSuggestionAction(String action) {
    return 'Are you sure you want to $action this suggestion?';
  }

  @override
  String get labelReviewerNotesOptional => 'Reviewer Notes (Optional)';

  @override
  String titleBuyProduct(String product, String volume) {
    return 'Buy $product ($volume)';
  }

  @override
  String labelTotalCoins(String coins) {
    return 'Total: $coins Coins';
  }

  @override
  String get msgNoContentProvided => 'No content provided.';

  @override
  String get titleExcessFollowUp => 'Excess Stock Follow-up';

  @override
  String get msgNoFulfilledExcesses => 'No fulfilled excesses found.';

  @override
  String get msgActionCompletedLocked =>
      'This action is locked because the transaction is already completed.';

  @override
  String get msgNoPendingExcesses => 'No pending excesses found.';

  @override
  String get hubOwnersTitle => 'Hub Owners';

  @override
  String get addOwner => 'Add Owner';

  @override
  String get editOwner => 'Edit Owner';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get cashBalance => 'Cash Balance';

  @override
  String get optimisticValue => 'Optimistic Value';

  @override
  String get makePayment => 'Make Payment';

  @override
  String get paymentValue => 'Payment Value';

  @override
  String get purchaseInvoice => 'Purchase Invoice';

  @override
  String get salesInvoice => 'Sales Invoice';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get negativeCommissions => 'Negative Commissions';

  @override
  String get hubExcessRevenue => 'Hub Excess Revenue';

  @override
  String get salesInvoiceRevenue => 'Sales Invoice Revenue';

  @override
  String get menuHubOwners => 'Hub Owners';

  @override
  String get menuHubPayments => 'Hub Payments';

  @override
  String get menuHubPurchaseInvoice => 'Purchase Invoice';

  @override
  String get menuHubSalesInvoice => 'Hub Sales Invoice';

  @override
  String get menuAdminTransactionsSummary => 'Transactions Summary';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get noOwnersFound => 'No owners found';

  @override
  String get balance => 'Balance';

  @override
  String get transactionRevenue => 'Transaction Revenue';

  @override
  String get menuHubCalculations => 'Calculations Widget';

  @override
  String get hubCalculationsTitle => 'Hub Calculations';

  @override
  String get selectPharmacy => 'Select Pharmacy';

  @override
  String get noExcessesFound => 'No excesses found for this pharmacy';

  @override
  String get calculate => 'Calculate';

  @override
  String get calculationType => 'Calculation Type';

  @override
  String get revenueRatio => 'Needed Revenue Percentage';

  @override
  String get lossRatio => 'Loss Percentage';

  @override
  String get seldinafilRatio => 'Sildenafil Ratio';

  @override
  String get alpha => 'Alpha (Sildenafil Purchase Sale)';

  @override
  String get beta => 'Beta (Min Sale)';

  @override
  String get supposedSale => 'Supposed Sale';

  @override
  String get totalRevenueRatio => 'Total Needed Revenue Percentage';

  @override
  String get totalSeldinafilRatio => 'Total Sildenafil Ratio';

  @override
  String get results => 'Results';

  @override
  String get confirmSelection => 'Confirm Selection';

  @override
  String get selectedItems => 'Selected Items';

  @override
  String get quantityPerItem => 'Qty';

  @override
  String get calculateR => 'Calculate Revenue';

  @override
  String get calculateZ => 'Calculate Sildenafil Ratio';

  @override
  String get calculateY => 'Calculate Loss Percentage';

  @override
  String get zValue => 'Sildenafil Ratio';

  @override
  String get rValue => 'Needed Revenue Percentage';

  @override
  String get quickMode => 'Quick Calculator';

  @override
  String get pharmacyMode => 'Pharmacy (Multi-item)';

  @override
  String get gammaValue => 'gamma (Sale %)';

  @override
  String get totalLossRatio => 'Total Loss Percentage';

  @override
  String get notes => 'Notes';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get salePercentage => 'Sale %';

  @override
  String get viewAll => 'View All';

  @override
  String get menuCashBalanceHistory => 'Cash Balance History';

  @override
  String get labelSelectProduct => 'Select Product';

  @override
  String get labelSellingPrice => 'Selling Price';

  @override
  String get btnSave => 'Save';

  @override
  String get errorRequiredField => 'Required field';

  @override
  String get btnAdd => 'Add';

  @override
  String get deletePurchaseInvoice => 'Delete Purchase Invoice';

  @override
  String get deleteSalesInvoice => 'Delete Sales Invoice';

  @override
  String get deleteInvoiceConfirmation =>
      'Are you sure you want to delete this invoice? This will reverse the stock and cash balance.';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get salesInvoiceProfit => 'Hub Sales Profit';

  @override
  String get punishmentRevenueLabel => 'Ticket Expenses';

  @override
  String get compensationRevenueLabel => 'Compensations Revenue';

  @override
  String get labelMaxQuantity => 'Max Qty';

  @override
  String get labelInvoiceSalePercentage => 'Invoice Sale %';

  @override
  String get labelLossPercentage => 'Y (Loss %)';
}
