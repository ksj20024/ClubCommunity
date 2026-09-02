// lib/features/club_workspace/screens/club_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';
import '../../auth/models/user_context_response.dart';
import '../widgets/board_free_view.dart';
import '../widgets/board_gallary_view.dart';
import '../widgets/board_notice_view.dart';
import '../widgets/club_home_view.dart';
import '../widgets/club_manage_view.dart';
import '../widgets/club_my_profile_view.dart';

class ClubHubScreen extends ConsumerStatefulWidget {
  const ClubHubScreen({super.key});

  @override
  ConsumerState<ClubHubScreen> createState() => _ClubHubScreenState();
}

class _ClubHubScreenState extends ConsumerState<ClubHubScreen> {
  int _selectedIndex = 0;
  bool _isLoadingSession = true;
  bool _isInit = false; // 💡 [수정]: 중복 초기화 가드 플래그 선언

  // 🎯 [수명 주기 교정]: initState를 삭제하고 didChangeDependencies를 개설합니다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // 🎯 [안전 가드]: arguments를 바로 Map으로 캐스팅하지 말고 null 체크를 먼저 수행합니다.
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        final int clubId = args['clubId'] as int;
        _initializeClubWorkspace(clubId);
      } else {
        // 💡 웹 브라우저 F5 새로고침 등으로 인자가 유실된 경우,
        // 에러를 뿜지 않고 부드럽게 메인 화면으로 리다이렉트 시킵니다.
        setState(() => _isLoadingSession = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/');
        });
      }
      _isInit = true;
    }
  }

  // 🎯 [구조 개선]: 추출된 clubId를 파라미터로 직접 수급받도록 개조
  void _initializeClubWorkspace(int clubId) async {
    final result = await ApiService.getMyClubAuth(clubId);

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        final authSession = UserContextResponse.fromJson(result['data']);

        // Riverpod 전역 세션 보관소에 안전하게 안착
        ref.read(activeClubProvider.notifier).setClubSession(authSession);
        setState(() => _isLoadingSession = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '동아리 권한 인증 실패')),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeClub = ref.watch(activeClubProvider);

    if (activeClub == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final bool isPresident = activeClub.clubRole == 'CLUBPRESIDENT' || activeClub.isManager == true;
    final bool isWebOrTablet = kIsWeb || MediaQuery.of(context).size.width > 700;

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': '홈'},
      {'icon': Icons.campaign_outlined, 'activeIcon': Icons.campaign, 'label': '공지사항'},
      {'icon': Icons.photo_library_outlined, 'activeIcon': Icons.photo_library, 'label': '활동 갤러리'},
      {'icon': Icons.forum_outlined, 'activeIcon': Icons.forum, 'label': '자유게시판'},
      {'icon': Icons.badge_outlined, 'activeIcon': Icons.badge, 'label': '내 정보'},
      if (isPresident) {'icon': Icons.settings_suggest_outlined, 'activeIcon': Icons.settings_suggest, 'label': '동아리 관리'},
    ];

    final List<Widget> subViews = [
      const ClubHomeView(),
      const BoardNoticeView(),
      const BoardGalleryView(),
      const BoardFreeView(),
      const ClubMyProfileView(),
      if (isPresident) const ClubManageView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(activeClub.clubInfo?.clubName ?? '동아리 룸', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(activeClubProvider.notifier).clear();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
        elevation: 1,
      ),
      body: isWebOrTablet
          ? Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            destinations: menuItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item['icon']),
                selectedIcon: Icon(item['activeIcon']),
                label: Text(item['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: IndexedStack(index: _selectedIndex, children: subViews)),
        ],
      )
          : IndexedStack(index: _selectedIndex, children: subViews),

      bottomNavigationBar: isWebOrTablet ? null : BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: (index) => setState(() => _selectedIndex = index),
        items: menuItems.map((item) {
          return BottomNavigationBarItem(icon: Icon(item['icon']), activeIcon: Icon(item['activeIcon']), label: item['label']);
        }).toList(),
      ),
    );
  }
}