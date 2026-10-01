import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/payment_model.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/storage_provider.dart';
import '../data/models/user_model.dart';
import '../utils/logger.dart';

/// Hosted checkout uses server prices and server-confirmed order status.
class PaymentService extends GetxService {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<Map<String, dynamic>> availableMethods =
      <Map<String, dynamic>>[].obs;
  final Rx<OrderModel?> currentOrder = Rx<OrderModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isApplePayAvailable = false.obs;
  final RxBool isStripeAvailable = false.obs;

  Future<PaymentService> init() async {
    loadProducts();
    return this;
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.getCreditsPackages();
      final body = response.body;
      if (!response.status.isOk ||
          body is! Map ||
          body['code'] != 200 ||
          body['data'] is! List) {
        throw StateError('Credit packages are temporarily unavailable');
      }
      products.assignAll((body['data'] as List).map(
          (entry) => ProductModel.fromJson(Map<String, dynamic>.from(entry))));
      final methods = await _apiProvider.getPaymentMethods();
      final methodsBody = methods.body;
      if (methods.status.isOk &&
          methodsBody is Map &&
          methodsBody['code'] == 200 &&
          methodsBody['data'] is List) {
        availableMethods.assignAll((methodsBody['data'] as List)
            .map((entry) => Map<String, dynamic>.from(entry)));
        isStripeAvailable.value =
            availableMethods.any((method) => method['id'] == 'stripe');
      } else {
        availableMethods.clear();
      }
    } catch (error) {
      products.clear();
      availableMethods.clear();
      Logger.e(
          'Unable to load server payment configuration: ${error.runtimeType}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<OrderModel?> createOrder(String productId, PaymentMethod method,
      {String currency = 'CNY'}) async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.createOrder(productId, method.name,
          currency: currency);
      final body = response.body;
      if (!response.status.isOk ||
          body is! Map ||
          body['code'] != 200 ||
          body['data'] is! Map) return null;
      final data = Map<String, dynamic>.from(body['data']);
      final order = OrderModel.fromJson({
        ...data,
        'product_id': productId,
        'payment_method': method.name,
        'currency': currency
      });
      currentOrder.value = order;
      return order;
    } catch (error) {
      Logger.e('Unable to create payment order: ${error.runtimeType}');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Launching checkout does not prove payment. Only the backend may confirm it.
  Future<bool> processPayment(OrderModel order) async {
    final uri = Uri.tryParse(order.paymentUrl ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    isLoading.value = true;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        return false;
      for (var attempt = 0; attempt < 45; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final response = await _apiProvider.getOrderStatus(order.id);
        final body = response.body;
        if (!response.status.isOk ||
            body is! Map ||
            body['code'] != 200 ||
            body['data'] is! Map) continue;
        final data = Map<String, dynamic>.from(body['data']);
        final updated = OrderModel.fromJson({...order.toJson(), ...data});
        currentOrder.value = updated;
        if (updated.status == 'completed') {
          final profile = await _apiProvider.getUserInfo();
          final profileBody = profile.body;
          if (profile.status.isOk &&
              profileBody is Map &&
              profileBody['code'] == 200 &&
              profileBody['data'] is Map) {
            await _storageProvider.saveUserInfo(UserModel.fromJson(
                Map<String, dynamic>.from(profileBody['data'])));
          }
          return true;
        }
        if (['failed', 'cancelled', 'canceled'].contains(updated.status))
          return false;
      }
      return false;
    } catch (error) {
      Logger.e('Unable to confirm payment: ${error.runtimeType}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
