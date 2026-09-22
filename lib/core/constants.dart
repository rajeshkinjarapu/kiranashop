class AppConstants {
  static const String usersCollection = 'users';
  static const String adminsCollection = 'admins';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String orderItemsCollection = 'order_items';
  static const String addressesCollection = 'addresses';
  static const String offersCollection = 'offers';
  static const String notificationsCollection = 'notifications';
  static const String settingsDoc = 'settings/shop';

  static const String roleAdmin = 'admin';
  static const String roleMember = 'member';

  static const List<String> orderStatusFlow = [
    'new',
    'accepted',
    'preparing',
    'ready',
    'delivered',
  ];

  static const List<String> paymentMethods = ['Cash', 'UPI', 'Card'];
  static const List<String> fulfillmentTypes = ['Delivery', 'Pickup'];
}

String orderStatusLabel(String status) {
  switch (status) {
    case 'new':
      return 'New';
    case 'accepted':
      return 'Accepted';
    case 'preparing':
      return 'Preparing';
    case 'ready':
      return 'Ready';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}
