import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../services/user_service.dart';
import '../../../utils/utils.dart';
import '../widgets/desktop_dialog_wrapper.dart';

/// 桌面端登录 / 注册 / 用户中心 对话框
class DesktopAuthDialog extends StatefulWidget {
  const DesktopAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => const DesktopDialogWrapper(
        width: 420,
        child: DesktopAuthDialog(),
      ),
    );
  }

  @override
  State<DesktopAuthDialog> createState() => _DesktopAuthDialogState();
}

class _DesktopAuthDialogState extends State<DesktopAuthDialog> {
  final UserService _userService = Get.find<UserService>();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.showSnackbar('error'.tr, 'email_invalid'.tr);
      return;
    }
    if (password.length < 6) {
      Utils.showSnackbar('error'.tr, 'password_min_length'.tr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _userService.login(email, password);
      if (res['success'] == true) {
        Utils.showSnackbar('success'.tr, 'login_success'.tr);
        if (mounted) Navigator.of(context).pop();
      } else {
        Utils.showSnackbar('error'.tr, res['message'] ?? 'login_failed'.tr, isError: true);
      }
    } catch (e) {
      Utils.showSnackbar('error'.tr, 'login_failed'.tr, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.showSnackbar('error'.tr, 'email_invalid'.tr);
      return;
    }
    if (password.length < 6) {
      Utils.showSnackbar('error'.tr, 'password_min_length'.tr);
      return;
    }
    if (name.isEmpty) {
      Utils.showSnackbar('error'.tr, 'please_enter_username'.tr);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _userService.register(email, password, name);
      if (res['success'] == true) {
        Utils.showSnackbar('success'.tr, 'register_success'.tr);
        if (mounted) Navigator.of(context).pop();
      } else {
        Utils.showSnackbar('error'.tr, res['message'] ?? 'register_failed'.tr, isError: true);
      }
    } catch (e) {
      Utils.showSnackbar('error'.tr, 'register_failed'.tr, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggedIn = _userService.isLoggedIn.value;
      final user = _userService.currentUser.value;

      if (isLoggedIn && user != null) {
        return _buildUserProfileView(context, user);
      } else {
        return _buildLoginForm(context);
      }
    });
  }

  Widget _buildUserProfileView(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: primaryColor.withOpacity(0.12),
            backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                ? NetworkImage(user.avatar!)
                : null,
            child: (user.avatar == null || user.avatar!.isEmpty)
                ? Icon(Icons.person, size: 36, color: primaryColor)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.username ?? user.email ?? 'user'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (user.email != null && user.username != null) ...[
            const SizedBox(height: 4),
            Text(
              user.email!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // 会员/积分信息卡片
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${user.credits}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'my_points'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: theme.dividerColor.withOpacity(0.3)),
                Column(
                  children: [
                    Text(
                      user.membershipExpiry != null && user.membershipExpiry!.isAfter(DateTime.now())
                          ? 'vip_member'.tr
                          : 'free_user'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'membership_status'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 退出登录按钮
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                await _userService.logout();
                Utils.showSnackbar('success'.tr, 'logout_success'.tr);
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(
                'logout'.tr,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/ic_logo.png', width: 28, height: 28),
              const SizedBox(width: 8),
              Text(
                _isRegisterMode ? 'register'.tr : 'login'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_isRegisterMode) ...[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'username'.tr,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'email'.tr,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'password'.tr,
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (_) => _isRegisterMode ? _handleRegister() : _handleLogin(),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading
                  ? null
                  : (_isRegisterMode ? _handleRegister : _handleLogin),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isRegisterMode ? 'register_button'.tr : 'login_button'.tr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isRegisterMode ? 'already_have_account'.tr : 'dont_have_account'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                  });
                },
                child: Text(
                  _isRegisterMode ? 'login_now'.tr : 'register_now'.tr,
                  style: TextStyle(fontSize: 12, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
