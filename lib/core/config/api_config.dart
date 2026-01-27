class ApiConfig {
  // Updated to current system IP: 172.20.10.3
  // If using Android Emulator, use: http://10.0.2.2:5001/api
  static const String baseUrl = 'http://172.20.10.3:5001/api';
  
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
  
  static const String getCampaigns = '/campaigns';
  static const String businessCampaigns = '/campaigns/business';
}
