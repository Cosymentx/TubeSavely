import 'package:get/get.dart';
import '../models/credit_model.dart';
import '../providers/api_provider.dart';
import '../../utils/logger.dart';

/// 积分仓库
///
/// 负责处理积分相关的业务逻辑
class CreditRepository {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// 获取用户积分
  Future<CreditModel?> getUserCredits() async {
    try {
      Logger.d('Getting user credits');
      
      final response = await _apiProvider.getUserCredits();
      
      if (response.status.isOk) {
        final Map<String, dynamic> data = response.body['data'] ?? {};
        return CreditModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.e('Error getting user credits: $e');
      return null;
    }
  }

  /// 获取用户积分历史
  ///
  /// [offset] 偏移量，默认为1
  /// [limit] 每页数量，默认为20
  Future<List<CreditHistoryModel>> getUserCreditsHistory({
    int offset = 1,
    int limit = 20,
  }) async {
    try {
      Logger.d('Getting user credits history');
      
      final response = await _apiProvider.getUserCreditsHistory(
        offset: offset,
        limit: limit,
      );
      
      if (response.status.isOk) {
        final List<dynamic> data = response.body['data'] ?? [];
        return data.map((item) => CreditHistoryModel.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.e('Error getting user credits history: $e');
      return [];
    }
  }

  /// 添加用户积分
  ///
  /// [credits] 积分数量
  /// [action] 操作类型
  /// [description] 描述
  Future<bool> addUserCredits(
    int credits,
    String action, {
    String? description,
  }) async {
    try {
      Logger.d('Adding user credits: $credits, $action');
      
      final response = await _apiProvider.addUserCredits(
        credits,
        action,
        description: description,
      );
      
      return response.status.isOk;
    } catch (e) {
      Logger.e('Error adding user credits: $e');
      return false;
    }
  }

  /// 扣除用户积分
  ///
  /// [credits] 积分数量
  /// [action] 操作类型
  /// [description] 描述
  Future<bool> deductUserCredits(
    int credits,
    String action, {
    String? description,
  }) async {
    try {
      Logger.d('Deducting user credits: $credits, $action');
      
      final response = await _apiProvider.deductUserCredits(
        credits,
        action,
        description: description,
      );
      
      return response.status.isOk;
    } catch (e) {
      Logger.e('Error deducting user credits: $e');
      return false;
    }
  }

  /// 获取积分套餐列表
  Future<List<CreditAmountModel>> getCreditAmounts() async {
    try {
      Logger.d('Getting credit amounts');
      
      final response = await _apiProvider.getCreditAmounts();
      
      if (response.status.isOk) {
        final List<dynamic> data = response.body['data'] ?? [];
        return data.map((item) => CreditAmountModel.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      Logger.e('Error getting credit amounts: $e');
      return [];
    }
  }

  /// 获取积分套餐详情
  ///
  /// [id] 积分套餐ID
  Future<CreditAmountModel?> getCreditAmount(int id) async {
    try {
      Logger.d('Getting credit amount: $id');
      
      final response = await _apiProvider.getCreditAmount(id);
      
      if (response.status.isOk) {
        final Map<String, dynamic> data = response.body['data'] ?? {};
        return CreditAmountModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      Logger.e('Error getting credit amount: $e');
      return null;
    }
  }
}
