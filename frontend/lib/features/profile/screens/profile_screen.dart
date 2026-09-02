// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/models/user_info_response.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/api/api_service.dart';

// 🎯 [리팩터링]: StatefulWidget ➔ ConsumerStatefulWidget으로 변경하여 창고 접근 권한 획득
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

// 🎯 [리팩터링]: State ➔ ConsumerState로 변경
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isProcessing = false;

  // 💡 [대폭 다이어트]: _localUser, _isInit, didChangeDependencies가 완전히 제거되었습니다.
  // 실시간 원본 저장소인 authProvider를 직접 바라보기 때문입니다.

  // [모달 1] 일반 정보 수정 (실명, 전화번호)
  // 💡 [수정]: 최신 유저 정보를 인자로 받아 텍스트 필드 초기값으로 세팅합니다.
  void _showGeneralInfoEditModal(UserInfoResponse user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.realName);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('프로필 정보 수정', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '실명', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: '전화번호', border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isProcessing = true);

                Map<String, dynamic> updateData = {
                  'realName': nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                };

                final result = await ApiService.updateProfile(updateData);
                setState(() => _isProcessing = false);

                if (result['success'] == true) {
                  final newUser = UserInfoResponse.fromJson(result['data']);

                  // 🎯 [핵심 패치]: 최신 Notifier 저장소에 유저 세션 원본 주입
                  // 이 한 줄로 마이페이지와 뒤에 깔려있는 메인 화면이 실시간 동시 새로고침됩니다.
                  ref.read(authProvider.notifier).setUser(newUser);

                  _showSnackBar(result['message'], isError: false);
                } else {
                  _showSnackBar(result['message'], isError: true);
                }
              },
              child: const Text('변경 저장'),
            ),
          ],
        );
      },
    );
  }

  // [모달 2] 비밀번호 변경
  void _showPasswordChangeModal() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? '현재 비밀번호를 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '새 비밀번호 (6자리 이상)', border: OutlineInputBorder()),
                    validator: (value) => value!.length < 6 ? '비밀번호는 6자리 이상이어야 합니다.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '새 비밀번호 확인', border: OutlineInputBorder()),
                    validator: (value) => value != newPasswordController.text ? '새 비밀번호가 일치하지 않습니다.' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  setState(() => _isProcessing = true);

                  final result = await ApiService.updatePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );

                  setState(() => _isProcessing = false);

                  if (result['success'] == true) {
                    _showSnackBar(result['message'] ?? '비밀번호가 안전하게 변경되었습니다.', isError: false);
                  } else {
                    _showSnackBar(result['message'] ?? '비밀번호 변경에 실패했습니다.', isError: true);
                  }
                }
              },
              child: const Text('비밀번호 수정'),
            ),
          ],
        );
      },
    );
  }

  // [모달 3] 이메일 변경 및 인증 프로세스
  void _showEmailChangeModal() {
    final emailController = TextEditingController();
    final codeController = TextEditingController();

    bool isEmailValid = false;
    bool isCodeSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void validateEmail(String value) {
              final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
              setModalState(() {
                isEmailValid = emailRegex.hasMatch(value.trim());
              });
            }

            return AlertDialog(
              title: const Text('이메일 주소 변경', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: '새로운 이메일 주소',
                        border: const OutlineInputBorder(),
                        suffixIcon: isEmailValid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      ),
                      enabled: !isCodeSent,
                      onChanged: validateEmail,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isEmailValid
                          ? () async {
                        final result = await ApiService.sendEmailVerification(emailController.text.trim());
                        if (result['success'] == true) {
                          setModalState(() => isCodeSent = true);
                          _showSnackBar(result['message'], isError: false);
                        } else {
                          _showSnackBar(result['message'], isError: true);
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(backgroundColor: isEmailValid ? Colors.blue : Colors.grey[300]),
                      child: Text(isCodeSent ? '인증 코드 재발송' : '인증 코드 받기'),
                    ),
                    if (isCodeSent) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        onChanged: (value) {
                          setModalState(() {});
                        },
                        decoration: const InputDecoration(
                          labelText: '인증 번호 6자리 입력',
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: (isCodeSent && codeController.text.trim().length == 6)
                      ? () async {
                    Navigator.pop(context);
                    setState(() => _isProcessing = true);

                    final result = await ApiService.updateEmail(
                      email: emailController.text.trim(),
                      verificationCode: codeController.text.trim(),
                    );

                    setState(() => _isProcessing = false);

                    if (result['success'] == true) {
                      final newUser = UserInfoResponse.fromJson(result['data']);

                      // 🎯 [핵심 패치]: 최신 Notifier 저장소에 인증된 이메일 세션 동기화
                      ref.read(authProvider.notifier).setUser(newUser);

                      _showSnackBar(result['message'], isError: false);
                    } else {
                      _showSnackBar(result['message'], isError: true);
                    }
                  }
                      : null,
                  child: const Text('이메일 변경'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 회원 탈퇴 처리 시퀀스
  void _handleWithdrawal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('회원 탈퇴 안내', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('정말로 플랫폼을 탈퇴하시겠습니까?\n탈퇴 시 본인의 모든 가입 기록 및 동아리 서류 정보가 즉시 영구 삭제되며, 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isProcessing = true);
                final result = await ApiService.withdrawAccount();
                setState(() => _isProcessing = false);

                if (result['success'] == true) {
                  // 🎯 [핵심 패치]: 회원 탈퇴 성공 시 전역 세션 즉시 완전 초기화(null)
                  ref.read(authProvider.notifier).clearUser();

                  _showSnackBar(result['message'], isError: false);
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                } else {
                  _showSnackBar(result['message'], isError: true);
                }
              },
              child: const Text('네, 탈퇴합니다', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 [핵심 패치]: 최신 Notifier 기반 전역 유저 인증 세션 실시간 구독 감시
    final currentUser = ref.watch(authProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('사용자 정보를 찾을 수 없습니다.')));
    }

    final String displayName = currentUser.realName ?? currentUser.userId;
    final String avatarLetter = currentUser.realName?.isNotEmpty == true
        ? currentUser.realName!.substring(0, 1)
        : currentUser.userId.substring(0, 1).toUpperCase();

    // 🎯 [청소 완료]: 지저분하게 수동 배달 데이터 팝을 발생시키던 PopScope 장치를 완전히 걷어내고 순수 원복했습니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: kIsWeb ? false : true,
      ),
      body: Stack(
        children: [
          ResponsiveCenter(
            maxWidth: 650.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.blueAccent,
                      child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                    child: Text(currentUser.role, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),

                  // 개인 정보 대시 패널
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(icon: Icons.account_box, label: '회원 고유 식별 번호 (ID)', value: '# ${currentUser.id}'),
                          const Divider(height: 24),
                          _buildInfoRow(icon: Icons.person_outline, label: '로그인 계정 아이디', value: currentUser.userId),
                          const Divider(height: 24),
                          _buildInfoRow(icon: Icons.email_outlined, label: '이메일 주소', value: currentUser.email),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.badge_outlined,
                            label: '사용자 실명',
                            value: currentUser.realName ?? '등록된 실명이 없습니다.',
                            valueColor: currentUser.realName == null ? Colors.grey : Colors.black87,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.phone_android_outlined,
                            label: '전화번호',
                            value: currentUser.phoneNumber ?? '등록된 전화번호가 없습니다.',
                            valueColor: currentUser.phoneNumber == null ? Colors.grey : Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 제어 버튼 매트릭스
                  Card(
                    elevation: 1,
                    color: Colors.grey[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit, color: Colors.blue),
                          title: const Text('기본 회원 정보 수정', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('실명 및 개인 연락처 정보를 변경합니다.'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _showGeneralInfoEditModal(currentUser), // 💡 원본 유저 데이터 주입
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.lock_reset, color: Colors.orange),
                          title: const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('계정 보안 유지를 위해 정기적인 변경을 권장합니다.'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: _showPasswordChangeModal,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.mark_email_read_outlined, color: Colors.purple),
                          title: const Text('이메일 주소 변경', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text('새로운 이메일 입력 및 코드로 실시간 소유 인증을 수행합니다.'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: _showEmailChangeModal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 회원 탈퇴 앵커
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _handleWithdrawal,
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.no_accounts_outlined, size: 18),
                      label: const Text('서비스 회원 탈퇴', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value, Color valueColor = Colors.black87}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey[600], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, color: valueColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}