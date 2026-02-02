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
  String get actionAdd => 'Add';

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
  String get tabAvailable => 'Available';

  @override
  String get tabFulfilled => 'Fulfilled';

  @override
  String get tabActive => 'Active';
}
