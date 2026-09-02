// lib/features/home/widgets/welcome_header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

// 🎯 StatelessWidget ➔ ConsumerWidget 변경
class WelcomeHeaderWidget extends ConsumerWidget {
  const WelcomeHeaderWidget({super.key}); // 💡 currentUser 생성자 제거

  @override
  // 🎯 WidgetRef ref 빨대 장착
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 전역 세션에서 유저 정보 직접 실시간 호출
    final currentUser = ref.watch(authProvider);

    if (currentUser == null) return const SizedBox.shrink();

    final String avatarLetter = currentUser.realName?.isNotEmpty == true
        ? currentUser.realName!.substring(0, 1)
        : currentUser.userId.substring(0, 1).toUpperCase();

    final String displayName = currentUser.realName ?? currentUser.userId;

    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        // 🎯 [핵심 패치]: ProfileScreen이 창고를 직접 보므로 arguments 가방을 완전히 삭제합니다.
        onTap: () => Navigator.pushNamed(context, '/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName님, 반갑습니다!',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(currentUser.email, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentUser.role,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}