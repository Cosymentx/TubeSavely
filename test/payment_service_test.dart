import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/data/models/payment_model.dart';

void main() {
  group('Payment Model Tests', () {
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
