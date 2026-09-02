// lib/features/home/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/models/user_info_response.dart';
import '../../../core/api/api_service.dart';
import '../../club/models/club_info_response.dart';
import '../widgets/joined_club_view.dart';
import '../widgets/no_club_view.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  bool _isLoadingClubs = false;
  List<ClubInfoResponse> _myClubs = [];

  @override
  void initState() {
    super.initState();
    // 첫 프레임 렌더링이 완료된 후 백엔드 동아리 조회를 가동합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserClubs();
    });
  }

  void _fetchUserClubs() async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    setState(() => _isLoadingClubs = true);
    final result = await ApiService.getUserClubs();

    setState(() {
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> rawList = result['data'] as List<dynamic>;
        _myClubs = rawList
            .map((json) => ClubInfoResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _myClubs = [];
      }
      _isLoadingClubs = false;
    });
  }

  void _handleLogout() async {
    await ApiService.clearSession();

    // Riverpod 최신 Notifier 세션 창고 청소
    ref.read(authProvider.notifier).clearUser();

    setState(() {
      _myClubs = [];
    });
    _showSnackBar('로그아웃 되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    // 최신 Notifier 기반 전역 세션 감시
    final currentUser = ref.watch(authProvider);

    return PopScope(
      canPop: currentUser == null, // 로그인 상태 시 시스템 뒤로가기 차단 가드
      child: Scaffold(
        appBar: _buildAppBar(currentUser),
        body: currentUser == null ? _buildGuestBody() : _buildUserDashboard(currentUser),
      ),
    );
  }

  AppBar _buildAppBar(UserInfoResponse? currentUser) {
    return AppBar(
      title: const Text('동아리 커뮤니티 플랫폼', style: TextStyle(fontWeight: FontWeight.bold)),
      automaticallyImplyLeading: false,
      actions: [
        if (currentUser == null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('로그인', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('로그아웃', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildGuestBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                '동아리 관리의 모든 것',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent
                ),
                textAlign: TextAlign.center
            ),
            const SizedBox(height: 16),
            const Text(
                '맞춤형 가입 신청서 자동 생성부터 운영진 승인까지 스마트하게 관리하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Text('로그인하고 시작하기', style: TextStyle(fontSize: 16))
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDashboard(UserInfoResponse currentUser) {
    if (_isLoadingClubs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myClubs.isNotEmpty) {
      return JoinedClubView(
        myClubs: _myClubs, // 💡 currentUser: currentUser 제거 완료!
        onActionMessage: _showSnackBar,
      );
    }

    return NoClubView(
      onActionMessage: _showSnackBar, // 💡 currentUser: currentUser 제거 완료!
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}