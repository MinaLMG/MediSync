import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World'**
  String get helloWorld;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'MediSync'**
  String get title;

  /// No description provided for @welcomeToMediSync.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MediSync'**
  String get welcomeToMediSync;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequiredError;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequiredError;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @signUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get signUpPrompt;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @invalidEmailError.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmailError;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @invalidPhoneError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number (11 digits starting with 01)'**
  String get invalidPhoneError;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Too short (min 8 chars)'**
  String get passwordMinLengthError;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to MediSync!'**
  String get welcomeMessage;

  /// No description provided for @linkPharmacyInstructions.
  ///
  /// In en, this message translates to:
  /// **'To start using the platform, you need to link your pharmacy and provide documentation.'**
  String get linkPharmacyInstructions;

  /// No description provided for @addNewPharmacyButton.
  ///
  /// In en, this message translates to:
  /// **'Adding New Pharmacy'**
  String get addNewPharmacyButton;

  /// No description provided for @awaitingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Approval'**
  String get awaitingApprovalTitle;

  /// No description provided for @awaitingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your documents have been submitted and are currently being reviewed by the admin. We will notify you once your account is active.'**
  String get awaitingApprovalMessage;

  /// No description provided for @checkStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Check Status Now'**
  String get checkStatusButton;

  /// No description provided for @pendingCartPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pending Cart (Coming Soon)'**
  String get pendingCartPlaceholder;

  /// No description provided for @balanceDisplay.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount} coins'**
  String balanceDisplay(String amount);

  /// No description provided for @reloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload Current Tab'**
  String get reloadTooltip;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get navOrderHistory;

  /// No description provided for @navPendingCart.
  ///
  /// In en, this message translates to:
  /// **'Pending Cart'**
  String get navPendingCart;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @urgentShortages.
  ///
  /// In en, this message translates to:
  /// **'URGENT SHORTAGES'**
  String get urgentShortages;

  /// No description provided for @noShortages.
  ///
  /// In en, this message translates to:
  /// **'No current shortages reported'**
  String get noShortages;

  /// No description provided for @adSpace.
  ///
  /// In en, this message translates to:
  /// **'Advertisement Space\n(Promotions & Offers)'**
  String get adSpace;

  /// No description provided for @menuRequestsHistory.
  ///
  /// In en, this message translates to:
  /// **'Requests History'**
  String get menuRequestsHistory;

  /// No description provided for @menuShoppingTour.
  ///
  /// In en, this message translates to:
  /// **'Shopping Tour'**
  String get menuShoppingTour;

  /// No description provided for @menuAddShortage.
  ///
  /// In en, this message translates to:
  /// **'Add Shortage'**
  String get menuAddShortage;

  /// No description provided for @menuAddExcess.
  ///
  /// In en, this message translates to:
  /// **'Add Excess'**
  String get menuAddExcess;

  /// No description provided for @menuStartTransactions.
  ///
  /// In en, this message translates to:
  /// **'Start Transactions'**
  String get menuStartTransactions;

  /// No description provided for @menuViewTransactions.
  ///
  /// In en, this message translates to:
  /// **'View Transactions'**
  String get menuViewTransactions;

  /// No description provided for @menuSuggestProduct.
  ///
  /// In en, this message translates to:
  /// **'Suggest Product'**
  String get menuSuggestProduct;

  /// No description provided for @menuSuggestionsComplaints.
  ///
  /// In en, this message translates to:
  /// **'Suggestions/Complaints'**
  String get menuSuggestionsComplaints;

  /// No description provided for @menuBalanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Balance History'**
  String get menuBalanceHistory;

  /// No description provided for @menuManageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get menuManageUsers;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @menuFollowUpExcesses.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Excesses'**
  String get menuFollowUpExcesses;

  /// No description provided for @menuFollowUpShortages.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Shortages'**
  String get menuFollowUpShortages;

  /// No description provided for @menuManageOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get menuManageOrders;

  /// No description provided for @menuDeliveryRequests.
  ///
  /// In en, this message translates to:
  /// **'Delivery Requests'**
  String get menuDeliveryRequests;

  /// No description provided for @menuManageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get menuManageProducts;

  /// No description provided for @menuProductSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Product Suggestions'**
  String get menuProductSuggestions;

  /// No description provided for @menuManagePharmacies.
  ///
  /// In en, this message translates to:
  /// **'Manage Pharmacies'**
  String get menuManagePharmacies;

  /// No description provided for @menuAppSuggestions.
  ///
  /// In en, this message translates to:
  /// **'App Suggestions'**
  String get menuAppSuggestions;

  /// No description provided for @menuAccountUpdates.
  ///
  /// In en, this message translates to:
  /// **'Account Updates'**
  String get menuAccountUpdates;

  /// No description provided for @menuSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get menuSystemSettings;

  /// No description provided for @manageUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsersTitle;

  /// No description provided for @tabNewRequests.
  ///
  /// In en, this message translates to:
  /// **'New Requests'**
  String get tabNewRequests;

  /// No description provided for @tabActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get tabActiveUsers;

  /// No description provided for @searchUsersHint.
  ///
  /// In en, this message translates to:
  /// **'Search users (* for wildcard)...'**
  String get searchUsersHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get noMatchesFound;

  /// No description provided for @noPharmacyLinked.
  ///
  /// In en, this message translates to:
  /// **'No Pharmacy Linked'**
  String get noPharmacyLinked;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get labelName;

  /// No description provided for @labelPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get labelPhone;

  /// No description provided for @pharmacyDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Documentation'**
  String get pharmacyDocumentation;

  /// No description provided for @labelPharmacyName.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Name'**
  String get labelPharmacyName;

  /// No description provided for @labelOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get labelOwnerName;

  /// No description provided for @labelNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get labelNationalId;

  /// No description provided for @labelPharmacyAddress.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Address'**
  String get labelPharmacyAddress;

  /// No description provided for @labelPharmacistCard.
  ///
  /// In en, this message translates to:
  /// **'Pharmacist Card'**
  String get labelPharmacistCard;

  /// No description provided for @labelCommercialRegistry.
  ///
  /// In en, this message translates to:
  /// **'Commercial Registry'**
  String get labelCommercialRegistry;

  /// No description provided for @labelTaxCard.
  ///
  /// In en, this message translates to:
  /// **'Tax Card'**
  String get labelTaxCard;

  /// No description provided for @labelLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get labelLicense;

  /// No description provided for @dialogRejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get dialogRejectRequest;

  /// No description provided for @dialogRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this user registration?'**
  String get dialogRejectMessage;

  /// No description provided for @actionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get actionReject;

  /// No description provided for @dialogApproveUser.
  ///
  /// In en, this message translates to:
  /// **'Approve User'**
  String get dialogApproveUser;

  /// No description provided for @dialogApproveMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this user and activate their account?'**
  String get dialogApproveMessage;

  /// No description provided for @actionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get actionApprove;

  /// No description provided for @managementActions.
  ///
  /// In en, this message translates to:
  /// **'Management Actions'**
  String get managementActions;

  /// No description provided for @actionActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get actionActivate;

  /// No description provided for @actionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get actionSuspend;

  /// No description provided for @dialogActivateUser.
  ///
  /// In en, this message translates to:
  /// **'Activate User'**
  String get dialogActivateUser;

  /// No description provided for @dialogSuspendUser.
  ///
  /// In en, this message translates to:
  /// **'Suspend User'**
  String get dialogSuspendUser;

  /// No description provided for @dialogActivateUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to activate this account?'**
  String get dialogActivateUserMessage;

  /// No description provided for @dialogSuspendUserMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this account?'**
  String get dialogSuspendUserMessage;

  /// No description provided for @actionResetPass.
  ///
  /// In en, this message translates to:
  /// **'Reset Pass'**
  String get actionResetPass;

  /// No description provided for @dialogResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get dialogResetPassword;

  /// No description provided for @dialogResetPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset this user\'s password to \"00000000\"?'**
  String get dialogResetPasswordMessage;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Action successful'**
  String get actionSuccessful;

  /// No description provided for @dialogCreateDeliveryAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Delivery Account'**
  String get dialogCreateDeliveryAccount;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @errorRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get errorRequired;

  /// No description provided for @errorMin6Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars'**
  String get errorMin6Chars;

  /// No description provided for @msgDeliveryUserCreated.
  ///
  /// In en, this message translates to:
  /// **'Delivery user created and pending approval'**
  String get msgDeliveryUserCreated;

  /// No description provided for @msgFailedCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user'**
  String get msgFailedCreateUser;

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get errorLoadingImage;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No Image'**
  String get noImage;

  /// No description provided for @matchableProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Matchable Products'**
  String get matchableProductsTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products (* for wildcard)...'**
  String get searchProductsHint;

  /// No description provided for @noMatchableItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No matchable items found.'**
  String get noMatchableItemsFound;

  /// No description provided for @shortageFulfillment.
  ///
  /// In en, this message translates to:
  /// **'Shortage Fulfillment'**
  String get shortageFulfillment;

  /// No description provided for @matchingAvailableInVolumes.
  ///
  /// In en, this message translates to:
  /// **'Matching available in {count} volumes'**
  String matchingAvailableInVolumes(int count);

  /// No description provided for @manageProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get manageProductsTitle;

  /// No description provided for @managePricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Prices'**
  String get managePricesTitle;

  /// No description provided for @priceCoins.
  ///
  /// In en, this message translates to:
  /// **'{price} coins'**
  String priceCoins(String price);

  /// No description provided for @labelCustomerPrice.
  ///
  /// In en, this message translates to:
  /// **'Customer Price'**
  String get labelCustomerPrice;

  /// No description provided for @dialogAddPrice.
  ///
  /// In en, this message translates to:
  /// **'Add Price'**
  String get dialogAddPrice;

  /// No description provided for @actionAddNewPrice.
  ///
  /// In en, this message translates to:
  /// **'Add New Price'**
  String get actionAddNewPrice;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @dialogEditProductInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit Product Info'**
  String get dialogEditProductInfo;

  /// No description provided for @labelProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get labelProductName;

  /// No description provided for @actionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// No description provided for @actionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get actionLoadMore;

  /// No description provided for @noPricesSet.
  ///
  /// In en, this message translates to:
  /// **'No prices set'**
  String get noPricesSet;

  /// No description provided for @coinsSuffix.
  ///
  /// In en, this message translates to:
  /// **'coins'**
  String get coinsSuffix;

  /// No description provided for @tooltipDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get tooltipDeactivate;

  /// No description provided for @tooltipActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get tooltipActivate;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get statusInactive;

  /// No description provided for @managePharmaciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Pharmacies'**
  String get managePharmaciesTitle;

  /// No description provided for @searchPharmaciesHint.
  ///
  /// In en, this message translates to:
  /// **'Search pharmacies...'**
  String get searchPharmaciesHint;

  /// No description provided for @noPharmaciesFound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies found.'**
  String get noPharmaciesFound;

  /// No description provided for @labelAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get labelAddress;

  /// No description provided for @labelBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get labelBalance;

  /// No description provided for @editBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Balance'**
  String get editBalanceTitle;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @accountUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Updates'**
  String get accountUpdatesTitle;

  /// No description provided for @tabPendingReversals.
  ///
  /// In en, this message translates to:
  /// **'Pending Reversals'**
  String get tabPendingReversals;

  /// No description provided for @tabManualAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Manual Adjustments'**
  String get tabManualAdjustments;

  /// No description provided for @noReversalTickets.
  ///
  /// In en, this message translates to:
  /// **'No pending reversal tickets'**
  String get noReversalTickets;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id}'**
  String ticketTitle(String id);

  /// No description provided for @transactionSerial.
  ///
  /// In en, this message translates to:
  /// **'Transaction Serial: {serial}'**
  String transactionSerial(String serial);

  /// No description provided for @expensesLabel.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesLabel;

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @resolveTicket.
  ///
  /// In en, this message translates to:
  /// **'Resolve Ticket'**
  String get resolveTicket;

  /// No description provided for @dialogResolveTicket.
  ///
  /// In en, this message translates to:
  /// **'Confirm Resolve'**
  String get dialogResolveTicket;

  /// No description provided for @dialogResolveTicketMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to resolve this ticket? This will finalize the financial adjustments.'**
  String get dialogResolveTicketMsg;

  /// No description provided for @adjustBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust Balance'**
  String get adjustBalanceTitle;

  /// No description provided for @selectPharmacyHint.
  ///
  /// In en, this message translates to:
  /// **'Select Pharmacy'**
  String get selectPharmacyHint;

  /// No description provided for @adjustmentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Amount (+/-)'**
  String get adjustmentAmountLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @actionDirectAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Apply Adjustment'**
  String get actionDirectAdjustment;

  /// No description provided for @adjustmentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Balance adjusted successfully'**
  String get adjustmentSuccess;

  /// No description provided for @menuRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get menuRefresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @tabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabPending;

  /// No description provided for @tabAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get tabAvailable;

  /// No description provided for @tabFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get tabFulfilled;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
