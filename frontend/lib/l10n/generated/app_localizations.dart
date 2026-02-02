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

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

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

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get statusPending;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE'**
  String get statusAvailable;

  /// No description provided for @statusFulfilled.
  ///
  /// In en, this message translates to:
  /// **'FULFILLED'**
  String get statusFulfilled;

  /// No description provided for @statusPartiallyFulfilled.
  ///
  /// In en, this message translates to:
  /// **'PARTIALLY FULFILLED'**
  String get statusPartiallyFulfilled;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'SOLD'**
  String get statusSold;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get statusExpired;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get statusRejected;

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
  /// **'AVAILABLE'**
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

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get actionLogout;

  /// No description provided for @labelVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get labelVolume;

  /// No description provided for @labelQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get labelQuantity;

  /// No description provided for @labelPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get labelPrice;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @labelExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get labelExpiry;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @msgDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get msgDeletedSuccessfully;

  /// No description provided for @msgSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Submitted successfully'**
  String get msgSubmittedSuccessfully;

  /// No description provided for @titleSuggestProduct.
  ///
  /// In en, this message translates to:
  /// **'Suggest New Product'**
  String get titleSuggestProduct;

  /// No description provided for @titleSuggestionsComplaints.
  ///
  /// In en, this message translates to:
  /// **'Suggestions & Complaints'**
  String get titleSuggestionsComplaints;

  /// No description provided for @titleSubscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get titleSubscriptionPlans;

  /// No description provided for @titleNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get titleNotifications;

  /// No description provided for @labelArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get labelArabic;

  /// No description provided for @labelEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get labelEnglish;

  /// No description provided for @labelAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get labelAppLanguage;

  /// No description provided for @labelPriceWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Price: {amount}'**
  String labelPriceWithAmount(String amount);

  /// No description provided for @tooltipMarkAllAsSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark all as seen'**
  String get tooltipMarkAllAsSeen;

  /// No description provided for @msgNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get msgNoNotifications;

  /// No description provided for @titlePharmacyDetails.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Details'**
  String get titlePharmacyDetails;

  /// No description provided for @labelSubmitDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Submit Documentation'**
  String get labelSubmitDocumentation;

  /// No description provided for @msgProvideInformation.
  ///
  /// In en, this message translates to:
  /// **'Please provide the following information as written in your official documents.'**
  String get msgProvideInformation;

  /// No description provided for @labelPharmacyNameWithHint.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Name (اسم الصيدلية)'**
  String get labelPharmacyNameWithHint;

  /// No description provided for @labelOwnerNameWithHint.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s Name (اسم صاحب الصيدلية كما مدون في الرخصه)'**
  String get labelOwnerNameWithHint;

  /// No description provided for @labelNationalIdWithHint.
  ///
  /// In en, this message translates to:
  /// **'National ID (بطاقة رقم قومي)'**
  String get labelNationalIdWithHint;

  /// No description provided for @msgMustBe14Digits.
  ///
  /// In en, this message translates to:
  /// **'Must be exactly 14 digits'**
  String get msgMustBe14Digits;

  /// No description provided for @errorNationalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'National ID is required'**
  String get errorNationalIdRequired;

  /// No description provided for @errorNationalIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'National ID must be exactly 14 digits'**
  String get errorNationalIdInvalid;

  /// No description provided for @labelDetailedAddress.
  ///
  /// In en, this message translates to:
  /// **'Detailed Address'**
  String get labelDetailedAddress;

  /// No description provided for @labelDetailedAddressWithHint.
  ///
  /// In en, this message translates to:
  /// **'Detailed Address (العنوان بالتفصيل)'**
  String get labelDetailedAddressWithHint;

  /// No description provided for @hintDetailedAddress.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123 Madinet Nasr, Cairo, Egypt'**
  String get hintDetailedAddress;

  /// No description provided for @actionSubmitForApproval.
  ///
  /// In en, this message translates to:
  /// **'Submit for Approval'**
  String get actionSubmitForApproval;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @actionUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get actionUpload;

  /// No description provided for @msgSubmissionFailed.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get msgSubmissionFailed;

  /// No description provided for @dialogConfirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Log out'**
  String get dialogConfirmLogout;

  /// No description provided for @dialogConfirmLogoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get dialogConfirmLogoutMsg;

  /// No description provided for @msgPleaseEnterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get msgPleaseEnterValidPrice;

  /// No description provided for @msgPleaseUploadAllDocs.
  ///
  /// In en, this message translates to:
  /// **'Please upload all 4 documents'**
  String get msgPleaseUploadAllDocs;

  /// No description provided for @labelFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback. Please let us know if you have any suggestions for improvement or any complaints regarding the system.'**
  String get labelFeedbackDescription;

  /// No description provided for @labelFeedbackPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type your message here...'**
  String get labelFeedbackPlaceholder;

  /// No description provided for @labelFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get labelFeedbackTitle;

  /// No description provided for @msgFeedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get msgFeedbackSuccess;

  /// No description provided for @msgGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get msgGenericError;

  /// No description provided for @labelRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get labelRequired;

  /// No description provided for @msgComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get msgComingSoon;

  /// No description provided for @msgSubscriptionDescription.
  ///
  /// In en, this message translates to:
  /// **'We are working on exclusive premium features and subscription plans to help you grow your pharmacy business.'**
  String get msgSubscriptionDescription;

  /// No description provided for @labelUserName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get labelUserName;

  /// No description provided for @labelUserEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'email@example.com'**
  String get labelUserEmailPlaceholder;

  /// No description provided for @menuMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get menuMyAccount;

  /// No description provided for @subtitleMyAccount.
  ///
  /// In en, this message translates to:
  /// **'View and edit your personal data'**
  String get subtitleMyAccount;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// No description provided for @subtitleHelp.
  ///
  /// In en, this message translates to:
  /// **'FAQs and app usage guide'**
  String get subtitleHelp;

  /// No description provided for @subtitleSubscription.
  ///
  /// In en, this message translates to:
  /// **'Explore premium features'**
  String get subtitleSubscription;

  /// No description provided for @menuResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset My Password'**
  String get menuResetPassword;

  /// No description provided for @subtitleResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Securely update your password'**
  String get subtitleResetPassword;

  /// No description provided for @dialogLogoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get dialogLogoutMsg;

  /// No description provided for @titleShortageFollowup.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Shortages'**
  String get titleShortageFollowup;

  /// No description provided for @titleRequestsHistory.
  ///
  /// In en, this message translates to:
  /// **'Requests History'**
  String get titleRequestsHistory;

  /// No description provided for @dialogConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get dialogConfirmDelete;

  /// No description provided for @dialogConfirmDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get dialogConfirmDeleteMsg;

  /// No description provided for @msgNoActiveShortages.
  ///
  /// In en, this message translates to:
  /// **'No active shortages'**
  String get msgNoActiveShortages;

  /// No description provided for @msgNoFulfilledShortages.
  ///
  /// In en, this message translates to:
  /// **'No fulfilled shortages'**
  String get msgNoFulfilledShortages;

  /// No description provided for @msgNoHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get msgNoHistoryFound;

  /// No description provided for @labelPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy: {name}'**
  String labelPharmacy(String name);

  /// No description provided for @labelQuantityNeeded.
  ///
  /// In en, this message translates to:
  /// **'Quantity Needed: {count}'**
  String labelQuantityNeeded(int count);

  /// No description provided for @labelRemainingQuantity.
  ///
  /// In en, this message translates to:
  /// **'Remaining Quantity: {count}'**
  String labelRemainingQuantity(int count);

  /// No description provided for @labelQuantityFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Quantity Fulfilled: {count}'**
  String labelQuantityFulfilled(int count);

  /// No description provided for @msgCannotDeleteFulfilledShortage.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete shortage that has already been partially fulfilled.'**
  String get msgCannotDeleteFulfilledShortage;

  /// No description provided for @dialogConfirmDeleteShortage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this shortage?'**
  String get dialogConfirmDeleteShortage;

  /// No description provided for @msgShortageRequirementCompleted.
  ///
  /// In en, this message translates to:
  /// **'This requirement is completed.'**
  String get msgShortageRequirementCompleted;

  /// No description provided for @labelExcessOffer.
  ///
  /// In en, this message translates to:
  /// **'Excess Offer'**
  String get labelExcessOffer;

  /// No description provided for @labelShortageRequest.
  ///
  /// In en, this message translates to:
  /// **'Shortage Request'**
  String get labelShortageRequest;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelTotalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity:'**
  String get labelTotalQuantity;

  /// No description provided for @labelRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get labelRemaining;

  /// No description provided for @labelDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get labelDiscount;

  /// No description provided for @labelDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get labelDiscountAmount;

  /// No description provided for @labelFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get labelFinalPrice;

  /// No description provided for @labelRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'REJECTION REASON:'**
  String get labelRejectionReason;

  /// No description provided for @labelCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String labelCreated(String date);

  /// No description provided for @msgCannotDeleteFulfilledItem.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete {item} that has already been {action}.'**
  String msgCannotDeleteFulfilledItem(String item, String action);

  /// No description provided for @labelExcess.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get labelExcess;

  /// No description provided for @labelShortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get labelShortage;

  /// No description provided for @labelTaken.
  ///
  /// In en, this message translates to:
  /// **'taken'**
  String get labelTaken;

  /// No description provided for @labelFulfilled.
  ///
  /// In en, this message translates to:
  /// **'fulfilled'**
  String get labelFulfilled;

  /// No description provided for @labelOffer.
  ///
  /// In en, this message translates to:
  /// **'offer'**
  String get labelOffer;

  /// No description provided for @labelRequest.
  ///
  /// In en, this message translates to:
  /// **'request'**
  String get labelRequest;

  /// No description provided for @titleMatchProduct.
  ///
  /// In en, this message translates to:
  /// **'Match: {product}'**
  String titleMatchProduct(String product);

  /// No description provided for @labelShortages.
  ///
  /// In en, this message translates to:
  /// **'Shortages'**
  String get labelShortages;

  /// No description provided for @labelExcesses.
  ///
  /// In en, this message translates to:
  /// **'Excesses'**
  String get labelExcesses;

  /// No description provided for @labelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// No description provided for @labelSalePercentage.
  ///
  /// In en, this message translates to:
  /// **'Sale %'**
  String get labelSalePercentage;

  /// No description provided for @msgSelectShortageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a shortage first'**
  String get msgSelectShortageFirst;

  /// No description provided for @msgShortageFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Shortage quantity already fulfilled'**
  String get msgShortageFulfilled;

  /// No description provided for @labelShortageFulfillment.
  ///
  /// In en, this message translates to:
  /// **'Shortage Fulfillment'**
  String get labelShortageFulfillment;

  /// No description provided for @labelVol.
  ///
  /// In en, this message translates to:
  /// **'Vol: {name}'**
  String labelVol(String name);

  /// No description provided for @labelNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needed: {count}'**
  String labelNeeded(int count);

  /// No description provided for @labelSaleRatio.
  ///
  /// In en, this message translates to:
  /// **'Sale Ratio: {ratio}%'**
  String labelSaleRatio(num ratio);

  /// No description provided for @labelAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated: {current} / {total}'**
  String labelAllocated(int current, int total);

  /// No description provided for @msgOverLimit.
  ///
  /// In en, this message translates to:
  /// **'OVER LIMIT!'**
  String get msgOverLimit;

  /// No description provided for @labelAdminOverrides.
  ///
  /// In en, this message translates to:
  /// **'Admin Overrides (Optional)'**
  String get labelAdminOverrides;

  /// No description provided for @labelBuyerComm.
  ///
  /// In en, this message translates to:
  /// **'Buyer Comm %'**
  String get labelBuyerComm;

  /// No description provided for @labelSellerRew.
  ///
  /// In en, this message translates to:
  /// **'Seller Rew %'**
  String get labelSellerRew;

  /// No description provided for @hintShFulfill.
  ///
  /// In en, this message translates to:
  /// **'Sh. Fulfill'**
  String get hintShFulfill;

  /// No description provided for @actionSubmitTransaction.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT TRANSACTION'**
  String get actionSubmitTransaction;

  /// No description provided for @msgTransactionCreated.
  ///
  /// In en, this message translates to:
  /// **'Transaction created successfully'**
  String get msgTransactionCreated;

  /// No description provided for @labelPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get labelPersonalInformation;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get labelFullName;

  /// No description provided for @labelEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get labelEmailAddress;

  /// No description provided for @labelPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get labelPhoneNumber;

  /// No description provided for @labelPharmacyInformation.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Information'**
  String get labelPharmacyInformation;

  /// No description provided for @labelPharmacyPhone.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Phone'**
  String get labelPharmacyPhone;

  /// No description provided for @actionSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get actionSaveChanges;

  /// No description provided for @msgUpdateRequested.
  ///
  /// In en, this message translates to:
  /// **'Update request sent to Admin!'**
  String get msgUpdateRequested;

  /// No description provided for @msgUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send request'**
  String get msgUpdateFailed;

  /// No description provided for @msgPendingUpdateInfo.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval for your previous update request. New edits will replace the pending one.'**
  String get msgPendingUpdateInfo;

  /// No description provided for @labelPharmacyInfo.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Info'**
  String get labelPharmacyInfo;

  /// No description provided for @msgNoAddress.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get msgNoAddress;

  /// No description provided for @msgNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone provided'**
  String get msgNoPhone;

  /// No description provided for @labelOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner: {name}'**
  String labelOwner(String name);

  /// No description provided for @titleShoppingTour.
  ///
  /// In en, this message translates to:
  /// **'Shopping Tour'**
  String get titleShoppingTour;

  /// No description provided for @labelSelectQuantitiesByPrice.
  ///
  /// In en, this message translates to:
  /// **'Select quantities by price:'**
  String get labelSelectQuantitiesByPrice;

  /// No description provided for @labelAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String labelAvailableCount(int count);

  /// No description provided for @labelSubtotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: {amount} coins'**
  String labelSubtotalAmount(String amount);

  /// No description provided for @labelTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost:'**
  String get labelTotalCost;

  /// No description provided for @labelUnitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String labelUnitsCount(int count);

  /// No description provided for @actionUpdateCart.
  ///
  /// In en, this message translates to:
  /// **'Update Cart'**
  String get actionUpdateCart;

  /// No description provided for @msgRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Removed from cart'**
  String get msgRemovedFromCart;

  /// No description provided for @msgCartUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cart updated!'**
  String get msgCartUpdated;

  /// No description provided for @titleShoppingCart.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get titleShoppingCart;

  /// No description provided for @msgCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get msgCartEmpty;

  /// No description provided for @labelOrderNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Order Notes (Optional)'**
  String get labelOrderNotesOptional;

  /// No description provided for @hintAddSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Add special instructions...'**
  String get hintAddSpecialInstructions;

  /// No description provided for @actionPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get actionPlaceOrder;

  /// No description provided for @msgPlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Placing Order...'**
  String get msgPlacingOrder;

  /// No description provided for @msgOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get msgOrderPlaced;

  /// No description provided for @msgOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get msgOrderFailed;

  /// No description provided for @hintSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get hintSearchProducts;

  /// No description provided for @msgNoMarketItems.
  ///
  /// In en, this message translates to:
  /// **'No items available in the market'**
  String get msgNoMarketItems;

  /// No description provided for @msgNoSearchMatches.
  ///
  /// In en, this message translates to:
  /// **'No items match your search'**
  String get msgNoSearchMatches;

  /// No description provided for @labelAvailableUnits.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String labelAvailableUnits(int count);

  /// No description provided for @labelPriceOptions.
  ///
  /// In en, this message translates to:
  /// **'{count} prices'**
  String labelPriceOptions(int count);

  /// No description provided for @titleEditExcess.
  ///
  /// In en, this message translates to:
  /// **'Edit Excess Stock'**
  String get titleEditExcess;

  /// No description provided for @titleAddExcess.
  ///
  /// In en, this message translates to:
  /// **'Add Excess Stock'**
  String get titleAddExcess;

  /// No description provided for @labelSelectExpiryMonthYear.
  ///
  /// In en, this message translates to:
  /// **'Select Expiry (Month/Year)'**
  String get labelSelectExpiryMonthYear;

  /// No description provided for @msgSelectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Please select expiry date'**
  String get msgSelectExpiryDate;

  /// No description provided for @msgSelectProductVolume.
  ///
  /// In en, this message translates to:
  /// **'Please select product and volume'**
  String get msgSelectProductVolume;

  /// No description provided for @msgInvalidSalePercentage.
  ///
  /// In en, this message translates to:
  /// **'Invalid sale percentage'**
  String get msgInvalidSalePercentage;

  /// No description provided for @msgEnterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
  String get msgEnterValidQuantity;

  /// No description provided for @labelProductWithName.
  ///
  /// In en, this message translates to:
  /// **'Product: {name}'**
  String labelProductWithName(String name);

  /// No description provided for @labelVolumeWithName.
  ///
  /// In en, this message translates to:
  /// **'Volume: {name}'**
  String labelVolumeWithName(String name);

  /// No description provided for @hintLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get hintLoading;

  /// No description provided for @hintSelectVolume.
  ///
  /// In en, this message translates to:
  /// **'Select volume'**
  String get hintSelectVolume;

  /// No description provided for @labelPriceCoins.
  ///
  /// In en, this message translates to:
  /// **'Price (coins)'**
  String get labelPriceCoins;

  /// No description provided for @labelSelectPrice.
  ///
  /// In en, this message translates to:
  /// **'Select Price'**
  String get labelSelectPrice;

  /// No description provided for @actionEnterManualPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter Manual Price'**
  String get actionEnterManualPrice;

  /// No description provided for @labelManualPrice.
  ///
  /// In en, this message translates to:
  /// **'Manual Price'**
  String get labelManualPrice;

  /// No description provided for @msgInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get msgInvalidQuantity;

  /// No description provided for @msgTooHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high'**
  String get msgTooHigh;

  /// No description provided for @msgTooLow.
  ///
  /// In en, this message translates to:
  /// **'Too low'**
  String get msgTooLow;

  /// No description provided for @labelExpiryDateMMYY.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date (MM/YY)'**
  String get labelExpiryDateMMYY;

  /// No description provided for @hintSelectExpiryDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expiry Date'**
  String get hintSelectExpiryDate;

  /// No description provided for @labelRequestType.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get labelRequestType;

  /// No description provided for @labelRealExcess.
  ///
  /// In en, this message translates to:
  /// **'Real Excess'**
  String get labelRealExcess;

  /// No description provided for @labelPercentageValue.
  ///
  /// In en, this message translates to:
  /// **'Percentage Value (%)'**
  String get labelPercentageValue;

  /// No description provided for @actionUpdateExcess.
  ///
  /// In en, this message translates to:
  /// **'Update Excess'**
  String get actionUpdateExcess;

  /// No description provided for @actionSubmitExcess.
  ///
  /// In en, this message translates to:
  /// **'Submit Excess'**
  String get actionSubmitExcess;

  /// No description provided for @msgErrorLoadingVolumes.
  ///
  /// In en, this message translates to:
  /// **'Error loading volumes'**
  String get msgErrorLoadingVolumes;

  /// No description provided for @titleEditShortage.
  ///
  /// In en, this message translates to:
  /// **'Edit Shortage'**
  String get titleEditShortage;

  /// No description provided for @titleAddShortage.
  ///
  /// In en, this message translates to:
  /// **'Add Shortage'**
  String get titleAddShortage;

  /// No description provided for @msgShortageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shortage updated successfully'**
  String get msgShortageUpdated;

  /// No description provided for @msgShortageAdded.
  ///
  /// In en, this message translates to:
  /// **'Shortage added successfully'**
  String get msgShortageAdded;

  /// No description provided for @msgErrorProcessingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error processing request'**
  String get msgErrorProcessingRequest;

  /// No description provided for @labelQuantityNeededField.
  ///
  /// In en, this message translates to:
  /// **'Quantity Needed'**
  String get labelQuantityNeededField;

  /// No description provided for @msgQuantityDecreaseOnly.
  ///
  /// In en, this message translates to:
  /// **'Quantity can only be decreased'**
  String get msgQuantityDecreaseOnly;

  /// No description provided for @msgCannotBeLessThan.
  ///
  /// In en, this message translates to:
  /// **'Cannot be less than {count}'**
  String msgCannotBeLessThan(int count);

  /// No description provided for @actionUpdateShortage.
  ///
  /// In en, this message translates to:
  /// **'Update Shortage'**
  String get actionUpdateShortage;

  /// No description provided for @actionSubmitShortage.
  ///
  /// In en, this message translates to:
  /// **'Submit Shortage'**
  String get actionSubmitShortage;

  /// No description provided for @labelUpdateSecurityDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your security details'**
  String get labelUpdateSecurityDetails;

  /// No description provided for @labelPasswordLengthHint.
  ///
  /// In en, this message translates to:
  /// **'Ensure your new password is at least 8 characters long.'**
  String get labelPasswordLengthHint;

  /// No description provided for @labelCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get labelCurrentPassword;

  /// No description provided for @labelNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get labelNewPassword;

  /// No description provided for @labelConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get labelConfirmNewPassword;

  /// No description provided for @msgPasswordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get msgPasswordChangedSuccess;

  /// No description provided for @msgPasswordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get msgPasswordChangeFailed;

  /// No description provided for @msgPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get msgPasswordsDoNotMatch;

  /// No description provided for @msgNoBalanceHistory.
  ///
  /// In en, this message translates to:
  /// **'No balance history found.'**
  String get msgNoBalanceHistory;

  /// No description provided for @labelBalanceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Balance Update'**
  String get labelBalanceUpdate;

  /// No description provided for @labelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get labelDate;

  /// No description provided for @labelPrevBalance.
  ///
  /// In en, this message translates to:
  /// **'Prev Balance'**
  String get labelPrevBalance;

  /// No description provided for @labelNewBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance'**
  String get labelNewBalance;

  /// No description provided for @labelBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown:'**
  String get labelBreakdown;

  /// No description provided for @labelNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get labelNotAvailable;

  /// No description provided for @manageOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get manageOrdersTitle;

  /// No description provided for @labelActiveUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get labelActiveUsers;

  /// No description provided for @labelAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get labelAccountStatus;

  /// No description provided for @labelUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get labelUnknown;

  /// No description provided for @actionSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get actionSimulate;

  /// No description provided for @actionCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get actionCompensation;

  /// No description provided for @actionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get actionHistory;

  /// No description provided for @actionPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get actionPayment;

  /// No description provided for @actionPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get actionPayments;

  /// No description provided for @dialogConfirmDeleteAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get dialogConfirmDeleteAdjustment;

  /// No description provided for @msgConfirmDeleteAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will REVERT the adjustment.'**
  String get msgConfirmDeleteAdjustment;

  /// No description provided for @actionDeleteRevert.
  ///
  /// In en, this message translates to:
  /// **'Delete & Revert'**
  String get actionDeleteRevert;

  /// No description provided for @msgAdjustmentReverted.
  ///
  /// In en, this message translates to:
  /// **'Adjustment reverted successfully'**
  String get msgAdjustmentReverted;

  /// No description provided for @dialogEditPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment'**
  String get dialogEditPayment;

  /// No description provided for @dialogRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment - {name}'**
  String dialogRecordPayment(String name);

  /// No description provided for @labelPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelPaymentType;

  /// No description provided for @labelDeposit.
  ///
  /// In en, this message translates to:
  /// **'💰 Deposit'**
  String get labelDeposit;

  /// No description provided for @labelWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'💸 Withdrawal'**
  String get labelWithdrawal;

  /// No description provided for @labelAdjustmentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get labelAdjustmentAmount;

  /// No description provided for @labelPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get labelPaymentMethod;

  /// No description provided for @labelCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get labelCash;

  /// No description provided for @labelBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get labelBankTransfer;

  /// No description provided for @labelCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get labelCheque;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @labelReferenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get labelReferenceNumber;

  /// No description provided for @labelAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get labelAdminNote;

  /// No description provided for @msgInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get msgInvalidAmount;

  /// No description provided for @msgPaymentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Payment updated'**
  String get msgPaymentUpdated;

  /// No description provided for @msgPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get msgPaymentRecorded;

  /// No description provided for @labelNewPayment.
  ///
  /// In en, this message translates to:
  /// **'New Payment'**
  String get labelNewPayment;

  /// No description provided for @labelOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String labelOrderNumber(String number);

  /// No description provided for @labelPharmacyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy:'**
  String get labelPharmacyPrefix;

  /// No description provided for @labelTotalAmountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Total Amount: {amount} coins'**
  String labelTotalAmountPrefix(String amount);

  /// No description provided for @labelStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get labelStatusPrefix;

  /// No description provided for @labelProgressPrefix.
  ///
  /// In en, this message translates to:
  /// **'Progress: {fulfilled} / {total} items'**
  String labelProgressPrefix(int fulfilled, int total);

  /// No description provided for @msgSelectExcessToFulfill.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one excess to fulfill'**
  String get msgSelectExcessToFulfill;

  /// No description provided for @msgFulfillSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully fulfilled {count} item(s)'**
  String msgFulfillSuccess(int count);

  /// No description provided for @msgFulfillPartialFail.
  ///
  /// In en, this message translates to:
  /// **'Successfully fulfilled {success} item(s), {fail} failed'**
  String msgFulfillPartialFail(int success, int fail);

  /// No description provided for @msgAllFulfillmentsFailed.
  ///
  /// In en, this message translates to:
  /// **'All fulfillments failed'**
  String get msgAllFulfillmentsFailed;

  /// No description provided for @labelSelectedUnits.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count} units'**
  String labelSelectedUnits(int count);

  /// No description provided for @labelItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String labelItemsCount(Object count);

  /// No description provided for @labelVolumePrefix.
  ///
  /// In en, this message translates to:
  /// **'Volume:'**
  String get labelVolumePrefix;

  /// No description provided for @labelPricePrefix.
  ///
  /// In en, this message translates to:
  /// **'Price:'**
  String get labelPricePrefix;

  /// No description provided for @labelNeed.
  ///
  /// In en, this message translates to:
  /// **'Need: {count}'**
  String labelNeed(int count);

  /// No description provided for @msgNoMatchingExcesses.
  ///
  /// In en, this message translates to:
  /// **'No matching excesses available'**
  String get msgNoMatchingExcesses;

  /// No description provided for @labelSaleRatioPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sale Ratio:'**
  String get labelSaleRatioPrefix;

  /// No description provided for @labelExpiryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Expiry:'**
  String get labelExpiryPrefix;

  /// No description provided for @actionMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get actionMax;

  /// No description provided for @actionSubmitFulfillment.
  ///
  /// In en, this message translates to:
  /// **'Submit Order Fulfillment ({count} units)'**
  String actionSubmitFulfillment(int count);

  /// No description provided for @msgAssignmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignment failed. Check if it\'s still available.'**
  String get msgAssignmentFailed;

  /// No description provided for @msgNoAvailableTransactions.
  ///
  /// In en, this message translates to:
  /// **'No available transactions.'**
  String get msgNoAvailableTransactions;

  /// No description provided for @msgNoTasksAssigned.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned to you.'**
  String get msgNoTasksAssigned;

  /// No description provided for @labelSelectedUnitsShort.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String labelSelectedUnitsShort(int count);

  /// No description provided for @labelAvailableUnitsPrefix.
  ///
  /// In en, this message translates to:
  /// **'Available:'**
  String get labelAvailableUnitsPrefix;

  /// No description provided for @msgProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get msgProcessing;

  /// No description provided for @labelOrderHash.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get labelOrderHash;

  /// No description provided for @labelTransactionHash.
  ///
  /// In en, this message translates to:
  /// **'Transaction: '**
  String get labelTransactionHash;

  /// No description provided for @labelUnitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'UNITS'**
  String get labelUnitsSuffix;

  /// No description provided for @labelExcessPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Excess:'**
  String get labelExcessPharmacy;

  /// No description provided for @labelShortagePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Shortage:'**
  String get labelShortagePharmacy;

  /// No description provided for @actionAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to Me'**
  String get actionAssignToMe;

  /// No description provided for @actionRequestAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Request Acceptance'**
  String get actionRequestAcceptance;

  /// No description provided for @actionRequestCompletion.
  ///
  /// In en, this message translates to:
  /// **'Request Completion'**
  String get actionRequestCompletion;

  /// No description provided for @labelRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request Pending...'**
  String get labelRequestPending;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelTransactionNumber.
  ///
  /// In en, this message translates to:
  /// **'Transaction #{id}'**
  String labelTransactionNumber(String id);

  /// No description provided for @labelOrderPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get labelOrderPrefix;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @catStockInventory.
  ///
  /// In en, this message translates to:
  /// **'📦 Stock & Inventory'**
  String get catStockInventory;

  /// No description provided for @qHowToAddExcess.
  ///
  /// In en, this message translates to:
  /// **'How can I add an excess?'**
  String get qHowToAddExcess;

  /// No description provided for @aHowToAddExcess.
  ///
  /// In en, this message translates to:
  /// **'Go to the Home tab and click on \"Add Excess Product\". Fill in the product details, expiry date, and discount. Once submitted, other pharmacies can see and request it.'**
  String get aHowToAddExcess;

  /// No description provided for @qWhatIsShortage.
  ///
  /// In en, this message translates to:
  /// **'What is a \"Shortage Request\"?'**
  String get qWhatIsShortage;

  /// No description provided for @aWhatIsShortage.
  ///
  /// In en, this message translates to:
  /// **'If you need a product that is not available in your stock, you can create a \"Shortage Request\". Other pharmacies with excess of that product can then fulfill your request.'**
  String get aWhatIsShortage;

  /// No description provided for @catBalanceFinance.
  ///
  /// In en, this message translates to:
  /// **'💰 Balance & Financials'**
  String get catBalanceFinance;

  /// No description provided for @qHowToGetBalance.
  ///
  /// In en, this message translates to:
  /// **'How can I get my balance?'**
  String get qHowToGetBalance;

  /// No description provided for @aHowToGetBalance.
  ///
  /// In en, this message translates to:
  /// **'Your current balance is displayed at the top of the Home tab. You can also view a detailed breakdown in your \"Transaction History\".'**
  String get aHowToGetBalance;

  /// No description provided for @qHowCommissionWorks.
  ///
  /// In en, this message translates to:
  /// **'How does the commission work?'**
  String get qHowCommissionWorks;

  /// No description provided for @aHowCommissionWorks.
  ///
  /// In en, this message translates to:
  /// **'MediSync charges a small commission on successful matches between pharmacies. This helps us maintain the platform and provide delivery services.'**
  String get aHowCommissionWorks;

  /// No description provided for @catTransactionsHistory.
  ///
  /// In en, this message translates to:
  /// **'🔄 Transactions & History'**
  String get catTransactionsHistory;

  /// No description provided for @qWhereIsHistory.
  ///
  /// In en, this message translates to:
  /// **'Where is my requests history?'**
  String get qWhereIsHistory;

  /// No description provided for @aWhereIsHistory.
  ///
  /// In en, this message translates to:
  /// **'All your past transactions and current stock requests can be found in the \"History\" tab at the bottom of the dashboard.'**
  String get aWhereIsHistory;

  /// No description provided for @qHowToTrackDelivery.
  ///
  /// In en, this message translates to:
  /// **'How do I track a delivery?'**
  String get qHowToTrackDelivery;

  /// No description provided for @aHowToTrackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Once a match is confirmed and a delivery person is assigned, you can view the live status in the \"Delivery Tracking\" section of your active order.'**
  String get aHowToTrackDelivery;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tabRequests;

  /// No description provided for @tabLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get tabLedger;

  /// No description provided for @labelCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get labelCurrentBalance;

  /// No description provided for @labelOwnerInformation.
  ///
  /// In en, this message translates to:
  /// **'Owner Information'**
  String get labelOwnerInformation;

  /// No description provided for @msgFailedToLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details'**
  String get msgFailedToLoadDetails;

  /// No description provided for @msgNoRequestHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No request history found.'**
  String get msgNoRequestHistoryFound;

  /// No description provided for @msgNoFinancialHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No financial history found.'**
  String get msgNoFinancialHistoryFound;

  /// No description provided for @deliveryDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Dashboard'**
  String get deliveryDashboardTitle;

  /// No description provided for @tabMyTasks.
  ///
  /// In en, this message translates to:
  /// **'MY TASKS'**
  String get tabMyTasks;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get tabHistory;

  /// No description provided for @msgAssigningToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigning to you...'**
  String get msgAssigningToYou;

  /// No description provided for @msgAssignmentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success! Transaction assigned.'**
  String get msgAssignmentSuccess;

  /// No description provided for @msgRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get msgRequestSent;

  /// No description provided for @catAccountManagement.
  ///
  /// In en, this message translates to:
  /// **'⚙️ Account Management'**
  String get catAccountManagement;

  /// No description provided for @qHowToEditProfile.
  ///
  /// In en, this message translates to:
  /// **'How do I edit my pharmacy data?'**
  String get qHowToEditProfile;

  /// No description provided for @aHowToEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to \"Account\" -> \"My Account\" and click the \"Edit\" button. Update your info and submit. Your request will be processed shortly.'**
  String get aHowToEditProfile;

  /// No description provided for @qCanIChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Can I change my password?'**
  String get qCanIChangePassword;

  /// No description provided for @aCanIChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Yes! Use the \"Reset My Password\" option in the Account menu. You will need your current password to set a new one.'**
  String get aCanIChangePassword;

  /// No description provided for @labelAdminDeliveryRequests.
  ///
  /// In en, this message translates to:
  /// **'Delivery Requests'**
  String get labelAdminDeliveryRequests;

  /// No description provided for @actionSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get actionSaveSettings;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @labelProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get labelProduct;

  /// No description provided for @labelUnitsShort.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get labelUnitsShort;

  /// No description provided for @labelCoins.
  ///
  /// In en, this message translates to:
  /// **'coins'**
  String get labelCoins;

  /// No description provided for @actionUpdateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get actionUpdateTransaction;

  /// No description provided for @msgFailedUpdateTransaction.
  ///
  /// In en, this message translates to:
  /// **'Failed to update transaction'**
  String get msgFailedUpdateTransaction;

  /// No description provided for @msgRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request Approved'**
  String get msgRequestApproved;

  /// No description provided for @msgRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request Rejected'**
  String get msgRequestRejected;

  /// No description provided for @msgFailedReviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to review request'**
  String get msgFailedReviewRequest;

  /// No description provided for @msgCleanupOldRequests.
  ///
  /// In en, this message translates to:
  /// **'Old requests cleaned up (older than 1 month)'**
  String get msgCleanupOldRequests;

  /// No description provided for @msgCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cleanup failed'**
  String get msgCleanupFailed;

  /// No description provided for @labelCleanup.
  ///
  /// In en, this message translates to:
  /// **'Cleanup'**
  String get labelCleanup;

  /// No description provided for @msgConfirmCleanup.
  ///
  /// In en, this message translates to:
  /// **'Delete all approved/rejected requests older than 1 month?'**
  String get msgConfirmCleanup;

  /// No description provided for @msgNoPendingDeliveryRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending delivery requests.'**
  String get msgNoPendingDeliveryRequests;

  /// No description provided for @titleEditTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction #{serial}'**
  String titleEditTransaction(String serial);

  /// No description provided for @labelOrderBadge.
  ///
  /// In en, this message translates to:
  /// **'ORDER'**
  String get labelOrderBadge;

  /// No description provided for @labelTotalOriginalNeeded.
  ///
  /// In en, this message translates to:
  /// **'Total Original Needed:'**
  String get labelTotalOriginalNeeded;

  /// No description provided for @labelAvailableOriginal.
  ///
  /// In en, this message translates to:
  /// **'Available (Original Available):'**
  String get labelAvailableOriginal;

  /// No description provided for @labelTotalDistribution.
  ///
  /// In en, this message translates to:
  /// **'Total Distribution:'**
  String get labelTotalDistribution;

  /// No description provided for @msgTotalQtyCannotBeZero.
  ///
  /// In en, this message translates to:
  /// **'Total quantity cannot be zero'**
  String get msgTotalQtyCannotBeZero;

  /// No description provided for @msgTransactionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Transaction updated successfully'**
  String get msgTransactionUpdated;

  /// No description provided for @msgExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing...'**
  String get msgExecuting;

  /// No description provided for @labelPortionInTx.
  ///
  /// In en, this message translates to:
  /// **'Portion in this transaction: {count}'**
  String labelPortionInTx(int count);

  /// No description provided for @msgConfirmDeleteExcessAvailable.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this available excess?'**
  String get msgConfirmDeleteExcessAvailable;

  /// No description provided for @labelRejectExcessOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject Excess Offer'**
  String get labelRejectExcessOffer;

  /// No description provided for @hintRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'e.g., Price too high, Expiry too near'**
  String get hintRejectionReason;

  /// No description provided for @labelConfirmApproval.
  ///
  /// In en, this message translates to:
  /// **'Confirm Approval'**
  String get labelConfirmApproval;

  /// No description provided for @msgConfirmApproveExcess.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this excess and make it available for matches?'**
  String get msgConfirmApproveExcess;

  /// No description provided for @labelNewPrice.
  ///
  /// In en, this message translates to:
  /// **'New Price'**
  String get labelNewPrice;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @expiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiryLabel;

  /// No description provided for @labelOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get labelOff;

  /// No description provided for @titleConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get titleConfirmDelete;

  /// No description provided for @msgConfirmReversePayment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This will REVERSE the payment.'**
  String get msgConfirmReversePayment;

  /// No description provided for @actionRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get actionRecord;

  /// No description provided for @msgPaymentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted and reversed'**
  String get msgPaymentDeleted;

  /// No description provided for @titleFollowUpTransactions.
  ///
  /// In en, this message translates to:
  /// **'Follow-up Transactions'**
  String get titleFollowUpTransactions;

  /// No description provided for @labelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// No description provided for @labelBuyer.
  ///
  /// In en, this message translates to:
  /// **'Buyer: {name}'**
  String labelBuyer(Object name);

  /// No description provided for @labelSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller: {name}'**
  String labelSeller(Object name);

  /// No description provided for @labelSellers.
  ///
  /// In en, this message translates to:
  /// **'Sellers:'**
  String get labelSellers;

  /// No description provided for @labelTotalQty.
  ///
  /// In en, this message translates to:
  /// **'Total Qty: {count}'**
  String labelTotalQty(Object count);

  /// No description provided for @labelTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value: {amount} coins'**
  String labelTotalValue(Object amount);

  /// No description provided for @labelDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery: {name}'**
  String labelDelivery(Object name);

  /// No description provided for @dialogConfirmAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm Accept'**
  String get dialogConfirmAccept;

  /// No description provided for @msgConfirmAcceptTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to accept this transaction?'**
  String get msgConfirmAcceptTransaction;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionYesAccept.
  ///
  /// In en, this message translates to:
  /// **'Yes, Accept'**
  String get actionYesAccept;

  /// No description provided for @dialogConfirmComplete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Complete'**
  String get dialogConfirmComplete;

  /// No description provided for @msgConfirmCompleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this transaction as completed?'**
  String get msgConfirmCompleteTransaction;

  /// No description provided for @actionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get actionComplete;

  /// No description provided for @actionYesComplete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Complete'**
  String get actionYesComplete;

  /// No description provided for @dialogConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel'**
  String get dialogConfirmCancel;

  /// No description provided for @msgConfirmCancelTransaction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this transaction? All quantities will be returned to their respective pharmacies.'**
  String get msgConfirmCancelTransaction;

  /// No description provided for @actionYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get actionYesCancel;

  /// No description provided for @labelEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get labelEdit;

  /// No description provided for @labelEditRatios.
  ///
  /// In en, this message translates to:
  /// **'Edit Ratios'**
  String get labelEditRatios;

  /// No description provided for @dialogDetachDelivery.
  ///
  /// In en, this message translates to:
  /// **'Detach Delivery'**
  String get dialogDetachDelivery;

  /// No description provided for @msgDetachDelivery.
  ///
  /// In en, this message translates to:
  /// **'This will remove the assigned delivery person. The transaction will become available for assignment again.'**
  String get msgDetachDelivery;

  /// No description provided for @actionDetach.
  ///
  /// In en, this message translates to:
  /// **'Detach'**
  String get actionDetach;

  /// No description provided for @msgDeliveryDetached.
  ///
  /// In en, this message translates to:
  /// **'Delivery person detached'**
  String get msgDeliveryDetached;

  /// No description provided for @actionRevertTransaction.
  ///
  /// In en, this message translates to:
  /// **'Revert Transaction'**
  String get actionRevertTransaction;

  /// No description provided for @actionViewEditTicket.
  ///
  /// In en, this message translates to:
  /// **'View/Edit Ticket'**
  String get actionViewEditTicket;

  /// No description provided for @labelRefundStatus.
  ///
  /// In en, this message translates to:
  /// **'Status updated to {status}'**
  String labelRefundStatus(Object status);

  /// No description provided for @labelRef.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String labelRef(Object ref);

  /// No description provided for @labelBuyerCommPercentage.
  ///
  /// In en, this message translates to:
  /// **'Buyer Commission % (Sh. Fulfill)'**
  String get labelBuyerCommPercentage;

  /// No description provided for @labelSellerRewardPercentage.
  ///
  /// In en, this message translates to:
  /// **'Seller Reward % (Sh. Fulfill)'**
  String get labelSellerRewardPercentage;

  /// No description provided for @labelDescriptionReason.
  ///
  /// In en, this message translates to:
  /// **'Description / Reason'**
  String get labelDescriptionReason;

  /// No description provided for @actionUpdateTicket.
  ///
  /// In en, this message translates to:
  /// **'Update Ticket'**
  String get actionUpdateTicket;

  /// No description provided for @actionConfirmReversion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reversion'**
  String get actionConfirmReversion;

  /// No description provided for @titleReversalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Revert Transaction & Expenses'**
  String get titleReversalExpenses;

  /// No description provided for @titleEditReversalTicket.
  ///
  /// In en, this message translates to:
  /// **'Edit Reversal Ticket'**
  String get titleEditReversalTicket;

  /// No description provided for @labelAutomaticReversalSummary.
  ///
  /// In en, this message translates to:
  /// **'AUTOMATIC REVERSAL SUMMARY:'**
  String get labelAutomaticReversalSummary;

  /// No description provided for @labelInvolvedParties.
  ///
  /// In en, this message translates to:
  /// **'INVOLVED PARTIES (Select to Add Expense):'**
  String get labelInvolvedParties;

  /// No description provided for @labelAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get labelAddExpense;

  /// No description provided for @labelAmountEgp.
  ///
  /// In en, this message translates to:
  /// **'Amount (EGP):'**
  String get labelAmountEgp;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @actionYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get actionYes;

  /// No description provided for @msgNoData.
  ///
  /// In en, this message translates to:
  /// **'No data found.'**
  String get msgNoData;

  /// No description provided for @titleProductSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Product Suggestions'**
  String get titleProductSuggestions;

  /// No description provided for @hintSearchSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Search suggestions...'**
  String get hintSearchSuggestions;

  /// No description provided for @msgNoSuggestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No product suggestions found.'**
  String get msgNoSuggestionsFound;

  /// No description provided for @labelProposedPrice.
  ///
  /// In en, this message translates to:
  /// **'Proposed Price'**
  String get labelProposedPrice;

  /// No description provided for @labelSuggestedBy.
  ///
  /// In en, this message translates to:
  /// **'Suggested By'**
  String get labelSuggestedBy;

  /// No description provided for @labelReviewerNotes.
  ///
  /// In en, this message translates to:
  /// **'Reviewer Notes: {notes}'**
  String labelReviewerNotes(String notes);

  /// No description provided for @msgSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated successfully!'**
  String get msgSettingsUpdated;

  /// No description provided for @msgFailedUpdateSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to update settings.'**
  String get msgFailedUpdateSettings;

  /// No description provided for @labelCommissionRatios.
  ///
  /// In en, this message translates to:
  /// **'Commission Ratios'**
  String get labelCommissionRatios;

  /// No description provided for @labelMinComm.
  ///
  /// In en, this message translates to:
  /// **'Minimum Commission (%)'**
  String get labelMinComm;

  /// No description provided for @helperMinComm.
  ///
  /// In en, this message translates to:
  /// **'Minimum percentage deducted from transactions'**
  String get helperMinComm;

  /// No description provided for @msgPleaseEnterValue.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get msgPleaseEnterValue;

  /// No description provided for @msgEnterNumberBetween0And20.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between 0 and 20'**
  String get msgEnterNumberBetween0And20;

  /// No description provided for @labelShortageComm.
  ///
  /// In en, this message translates to:
  /// **'Shortage Commission (Coins)'**
  String get labelShortageComm;

  /// No description provided for @helperShortageComm.
  ///
  /// In en, this message translates to:
  /// **'Coins deducted per unit for shortage fulfillment'**
  String get helperShortageComm;

  /// No description provided for @msgEnterPositiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a positive number'**
  String get msgEnterPositiveNumber;

  /// No description provided for @labelShortageSellerRewardField.
  ///
  /// In en, this message translates to:
  /// **'Shortage Seller Reward (Coins)'**
  String get labelShortageSellerRewardField;

  /// No description provided for @helperShortageSellerReward.
  ///
  /// In en, this message translates to:
  /// **'Coins rewarded to seller per unit'**
  String get helperShortageSellerReward;

  /// No description provided for @titleFeedbackComplaints.
  ///
  /// In en, this message translates to:
  /// **'Feedback & Complaints'**
  String get titleFeedbackComplaints;

  /// No description provided for @labelUnknownPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Unknown Pharmacy'**
  String get labelUnknownPharmacy;

  /// No description provided for @labelUserPrefix.
  ///
  /// In en, this message translates to:
  /// **'User: {user}'**
  String labelUserPrefix(String user);

  /// No description provided for @titleFeedbackDetails.
  ///
  /// In en, this message translates to:
  /// **'Feedback Details'**
  String get titleFeedbackDetails;

  /// No description provided for @labelFromPrefix.
  ///
  /// In en, this message translates to:
  /// **'From: {from}'**
  String labelFromPrefix(String from);

  /// No description provided for @msgConfirmDeleteExcess.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this excess stock?'**
  String get msgConfirmDeleteExcess;

  /// No description provided for @msgNoAvailableExcesses.
  ///
  /// In en, this message translates to:
  /// **'No available excess stock found.'**
  String get msgNoAvailableExcesses;

  /// No description provided for @msgCannotDeleteTakenExcess.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete an excess that is already being used for a transaction.'**
  String get msgCannotDeleteTakenExcess;

  /// No description provided for @labelConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get labelConfirmDelete;

  /// No description provided for @titleSuggestionAction.
  ///
  /// In en, this message translates to:
  /// **'{action} Suggestion'**
  String titleSuggestionAction(String action);

  /// No description provided for @msgConfirmSuggestionAction.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to {action} this suggestion?'**
  String msgConfirmSuggestionAction(String action);

  /// No description provided for @labelReviewerNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Reviewer Notes (Optional)'**
  String get labelReviewerNotesOptional;

  /// No description provided for @titleBuyProduct.
  ///
  /// In en, this message translates to:
  /// **'Buy {product} ({volume})'**
  String titleBuyProduct(String product, String volume);

  /// No description provided for @labelTotalCoins.
  ///
  /// In en, this message translates to:
  /// **'Total: {coins} Coins'**
  String labelTotalCoins(String coins);

  /// No description provided for @msgNoContentProvided.
  ///
  /// In en, this message translates to:
  /// **'No content provided.'**
  String get msgNoContentProvided;

  /// No description provided for @titleExcessFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Excess Stock Follow-up'**
  String get titleExcessFollowUp;

  /// No description provided for @msgNoFulfilledExcesses.
  ///
  /// In en, this message translates to:
  /// **'No fulfilled excesses found.'**
  String get msgNoFulfilledExcesses;

  /// No description provided for @msgActionCompletedLocked.
  ///
  /// In en, this message translates to:
  /// **'This action is locked because the transaction is already completed.'**
  String get msgActionCompletedLocked;

  /// No description provided for @msgNoPendingExcesses.
  ///
  /// In en, this message translates to:
  /// **'No pending excesses found.'**
  String get msgNoPendingExcesses;
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
