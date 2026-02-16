class ApiConfig {
  // Updated to current system IP: 192.168.1.7
  // If using Android Emulator, use: http://10.0.2.2:5001/api
  static const String baseUrl = 'http://16.16.255.118:5000/api';
  
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  
  // Specific Business routes can remain if needed
  static const String createTerminal = '/business/terminals';
  static const String getTerminals = '/business/terminals';
  static const String terminalTransaction = '/terminal/transaction';

  // Wallet / My Firms routes
  static const String getMyFirms = '/wallet/my';
  static const String reorderWallet = '/wallet/reorder';
  static const String removeBusiness = '/wallet/remove';
  
  static const String getTransactions = '/customer/transactions';
  static const String createReview = '/customer/reviews';
  static const String getReviews = '/customer/reviews';
  static const String getPendingReviews = '/customer/reviews/pending';
  
  static const String getCampaigns = '/campaigns';
  static const String businessCampaigns = '/campaigns/business';
}
