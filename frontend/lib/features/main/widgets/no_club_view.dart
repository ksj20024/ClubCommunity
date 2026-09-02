// lib/features/home/widgets/no_club_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import 'welcome_header_widget.dart';

class NoClubView extends ConsumerWidget {
  final Function(String) onActionMessage;

  const NoClubView({
    super.key,
    required this.onActionMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWebOrTablet = kIsWeb || MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeHeaderWidget(),
              const SizedBox(height: 32),
              Text('시작하기', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              isWebOrTablet ? _buildGridMenu(context, ref) : _buildListMenu(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context, WidgetRef ref) {
    final cards = _getMenuCards(context, ref);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 💡 [디자인 패치]: 보유한 카드 개수(2개 또는 3개)에 맞춰 대시보드 열 개수를 동적으로 조절하여 여백을 방어합니다.
      crossAxisCount: cards.length,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: cards.length == 2 ? 1.6 : 1.3,
      children: cards,
    );
  }

  Widget _buildListMenu(BuildContext context, WidgetRef ref) {
    final cards = _getMenuCards(context, ref);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => cards[index],
    );
  }

  List<Widget> _getMenuCards(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final String userRole = currentUser?.role ?? 'USER';

    // 🎯 최고 관리자 엔티티 판별 플래그 수립
    final bool isAdmin = userRole == 'SYSADMIN';

    return [
      _buildMenuCard(
        icon: Icons.search,
        title: '동아리 탐색 및 가입',
        description: '교내 활성화된 다양한 동아리를 검색하고 가입 신청서를 제출합니다.',
        onTap: () {
          onActionMessage('동아리 조회 화면으로 이동합니다.');
          // 🎯 [라우팅 연동 완공]: 앞서 구축한 동아리 검색 룸으로 바인딩 유도
          Navigator.pushNamed(context, '/club/search');
        },
      ),
      _buildMenuCard(
        icon: Icons.add_circle_outline,
        title: '새로운 동아리 개설',
        description: '새로운 동아리를 만들고 회원들과 소통하세요.',
        color: Colors.blue,
        onTap: () {
          onActionMessage('동아리 생성 화면으로 이동합니다.');
          Navigator.pushNamed(context, '/club/create');
        },
      ),
      // 🎯 [권한 노출 제어 가드]: 사이트 전체 총괄 관리자(ADMIN) 세션일 때만 어레이에 적재
      if (isAdmin)
        _buildMenuCard(
          icon: Icons.admin_panel_settings_outlined,
          title: '사이트 관리',
          description: '플랫폼 전체 회원 제어, 시스템 로그 및 중앙 환경 설정을 관리합니다.',
          color: Colors.redAccent, // 최고 권한을 상징하는 레드 오렌지 계열 인테리어
          onTap: () {
            onActionMessage('사이트 시스템 관리 화면으로 이동합니다.');
            // TODO: 추후 사이트 어드민 전용 화면 완공 시 라우터 연결 구역
            // Navigator.pushNamed(context, '/admin/dashboard');
          },
        ),
    ];
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}