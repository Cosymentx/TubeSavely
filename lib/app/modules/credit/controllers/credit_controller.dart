import 'package:get/get.dart';
import '../../../data/models/credit_model.dart';
import '../../../data/repositories/credit_repository.dart';
import '../../../utils/logger.dart';

/// 积分控制器
class CreditController extends GetxController {
  final CreditRepository _creditRepository = Get.find<CreditRepository>();
  
  // 用户积分
  final Rx<CreditModel?> userCredits = Rx<CreditModel?>(null);
  
  // 积分历史
  final RxList<CreditHistoryModel> creditsHistory = <CreditHistoryModel>[].obs;
  
  // 积分套餐
  final RxList<CreditAmountModel> creditAmounts = <CreditAmountModel>[].obs;
  
  // 加载状态
  final RxBool isLoading = false.obs;
  
  // 是否有更多数据
  final RxBool hasMore = true.obs;
  
  // 当前页码
  final RxInt currentPage = 1.obs;
  
  // 每页数量
  final int pageSize = 20;
  
  @override
  void onInit() {
    super.onInit();
    loadUserCredits();
    loadCreditsHistory();
    loadCreditAmounts();
  }
  
  /// 加载用户积分
  Future<void> loadUserCredits() async {
    try {
      isLoading.value = true;
      
      final credits = await _creditRepository.getUserCredits();
      
      if (credits != null) {
        userCredits.value = credits;
      }
    } catch (e) {
      Logger.e('Error loading user credits: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 加载积分历史
  Future<void> loadCreditsHistory({bool refresh = false}) async {
    if (isLoading.value) return;
    
    try {
      isLoading.value = true;
      
      if (refresh) {
        currentPage.value = 1;
        creditsHistory.clear();
      }
      
      final history = await _creditRepository.getUserCreditsHistory(
        offset: currentPage.value,
        limit: pageSize,
      );
      
      if (history.isEmpty) {
        hasMore.value = false;
      } else {
        creditsHistory.addAll(history);
        currentPage.value++;
        hasMore.value = history.length >= pageSize;
      }
    } catch (e) {
      Logger.e('Error loading credits history: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 刷新积分历史
  Future<void> refreshCreditsHistory() async {
    await loadCreditsHistory(refresh: true);
  }
  
  /// 加载更多积分历史
  Future<void> loadMoreCreditsHistory() async {
    if (isLoading.value || !hasMore.value) return;
    await loadCreditsHistory();
  }
  
  /// 加载积分套餐
  Future<void> loadCreditAmounts() async {
    try {
      isLoading.value = true;
      
      final amounts = await _creditRepository.getCreditAmounts();
      
      if (amounts.isNotEmpty) {
        creditAmounts.value = amounts;
      }
    } catch (e) {
      Logger.e('Error loading credit amounts: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 添加积分
  Future<bool> addCredits(int credits, String action, {String? description}) async {
    try {
      isLoading.value = true;
      
      final success = await _creditRepository.addUserCredits(
        credits,
        action,
        description: description,
      );
      
      if (success) {
        await loadUserCredits();
        await refreshCreditsHistory();
      }
      
      return success;
    } catch (e) {
      Logger.e('Error adding credits: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 扣除积分
  Future<bool> deductCredits(int credits, String action, {String? description}) async {
    try {
      isLoading.value = true;
      
      final success = await _creditRepository.deductUserCredits(
        credits,
        action,
        description: description,
      );
      
      if (success) {
        await loadUserCredits();
        await refreshCreditsHistory();
      }
      
      return success;
    } catch (e) {
      Logger.e('Error deducting credits: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  /// 获取积分套餐详情
  Future<CreditAmountModel?> getCreditAmount(int id) async {
    try {
      isLoading.value = true;
      return await _creditRepository.getCreditAmount(id);
    } catch (e) {
      Logger.e('Error getting credit amount: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
