import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';

void main() {
  group('Payment Model Tests', () {
    test('Server credit tiers retain IDs and both currency prices', () {
      final product = ProductModel.fromJson(
          {'id': 4, 'credits': 2000, 'amount_cny': 59.99, 'amount_usd': 59.99});
      expect(product.id, '4');
      expect(product.metadata?['credits'], 2000);
      expect(product.price, 59.99);
      expect(product.forCurrency('USD').currency, 'USD');
      expect(product.forCurrency('USD').price, 59.99);
    });

    test('Hosted checkout accepts numeric amounts and provider order IDs', () {
      final order = OrderModel.fromJson({
        'id': 42,
        'order_id': 'TS-fixture',
        'credit_amount_id': 1,
        'user_id': 7,
        'amount': 9.99,
        'currency': 'USD',
        'payment_method': 'creem',
        'status': 'pending',
        'payment_url': 'https://www.creem.io/payment/fixture'
      });
      expect(order.id, 'TS-fixture');
      expect(order.productId, '1');
      expect(order.amount, 9.99);
      expect(order.paymentMethod, PaymentMethod.creem);
      expect(order.status, 'pending');
    });
    test('ProductModel should be created correctly', () {
      // 准备测试数据
      final product = ProductModel(
        id: 'product_1',
        title: 'Test Product',
        description: 'Test Description',
        price: 9.99,
        currency: 'USD',
        type: ProductType.credit,
        metadata: {'credits': 100},
      );

      // 验证结果
      expect(product.id, 'product_1');
      expect(product.title, 'Test Product');
      expect(product.description, 'Test Description');
      expect(product.price, 9.99);
      expect(product.currency, 'USD');
      expect(product.type, ProductType.credit);
      expect(product.metadata?['credits'], 100);
    });

    test('OrderModel should be created correctly', () {
      // 准备测试数据
      final now = DateTime.now();
      final order = OrderModel(
        id: 'order_1',
        productId: 'product_1',
        userId: 'user_1',
        amount: 9.99,
        currency: 'USD',
        status: 'pending',
        paymentMethod: PaymentMethod.stripe,
        createdAt: now,
      );

      // 验证结果
      expect(order.id, 'order_1');
      expect(order.productId, 'product_1');
      expect(order.userId, 'user_1');
      expect(order.amount, 9.99);
      expect(order.currency, 'USD');
      expect(order.status, 'pending');
      expect(order.paymentMethod, PaymentMethod.stripe);
      expect(order.createdAt, now);
    });

    test('PaymentMethod enum should have correct values', () {
      expect(PaymentMethod.stripe.toString(), 'PaymentMethod.stripe');
      expect(PaymentMethod.applePay.toString(), 'PaymentMethod.applePay');
      expect(PaymentMethod.googlePay.toString(), 'PaymentMethod.googlePay');
    });

    test('ProductType enum should have correct values', () {
      expect(ProductType.credit.toString(), 'ProductType.credit');
      expect(ProductType.membership.toString(), 'ProductType.membership');
    });
  });
}
