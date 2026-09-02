// lib/features/club/screens/club_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';

class ClubSearchScreen extends ConsumerStatefulWidget {
  const ClubSearchScreen({super.key});

  @override
  ConsumerState<ClubSearchScreen> createState() => _ClubSearchScreenState();
}

class _ClubSearchScreenState extends ConsumerState<ClubSearchScreen> {
  List<dynamic> _allClubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getAllClubs();
    if (mounted) {
      setState(() {
        _allClubs = result['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  // 🎯 [핵심 교정 ①]: 네 번째 인자로 백엔드 EnumSet인 clubJoinMethods 리스트를 명확하게 수집합니다.
  void _handleClubClick(int clubId, String clubName, String clubType, List<dynamic> clubJoinMethods) async {
    final result = await ApiService.getMyClubAuth(clubId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      final String joinStatus = result['data']['joinStatus'] ?? 'NONE';

      if (joinStatus == 'APPROVED') {
        Navigator.pushNamed(context, '/club/hub', arguments: {'clubId': clubId});
      } else if (joinStatus == 'PENDING') {
        _showStatusDialog('심사 대기 중', '"$clubName" 동아리에 제출하신 가입 신청서가 현재 운영진 심사 중에 있습니다.\n결과가 나올 때까지 잠시만 기다려 주세요.');
      } else if (joinStatus == 'REJECTED') {
        _showStatusDialog('가입 반려 안내', '죄송합니다. 해당 동아리 가입 신청이 반려된 상태입니다.\n자세한 사유는 관리자에게 문의하세요.');
      } else {
        // 🎯 [라우팅 가방 업그레이드]: 리버팟 가드가 켜진 가입 폼 화면으로 가입 방식 세트 통째로 토스!
        Navigator.pushNamed(
            context,
            '/club/join',
            arguments: {
              'clubId': clubId,
              'clubName': clubName,
              'clubType': clubType,
              'clubJoinMethod': clubJoinMethods, // 🚀 여기로 바인딩 배달 완료!
            }
        );
      }
    } else {
      // API 통신 실패 가드 상황에서도 데이터 유실 없도록 원타깃 토스 방어선 구축
      Navigator.pushNamed(
          context,
          '/club/join',
          arguments: {
            'clubId': clubId,
            'clubName': clubName,
            'clubType': clubType,
            'clubJoinMethod': clubJoinMethods,
          }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동아리 개척 및 탐색', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allClubs.isEmpty
          ? const Center(child: Text('현재 등록된 동아리가 없습니다.', style: TextStyle(color: Colors.grey)))
          : Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3, // 하단 가입방식 인테리어 추가로 비율 살짝 조정
            ),
            itemCount: _allClubs.length,
            itemBuilder: (context, index) {
              final club = _allClubs[index];
              final int id = club['id'] ?? 0;
              final String name = club['clubName'] ?? '이름 없음';
              final String school = club['schoolName'] ?? '소속 대학 없음 (연합/일반)';
              final String rawType = club['clubType']?.toString() ?? 'GENERAL';

              // 🎯 [신규 DTO 연동]: 백엔드 EnumSet<ClubJoinMethodRole> 리스트 추출
              final List<dynamic> rawMethods = club['clubJoinMethod'] as List<dynamic>? ?? [];

              String typeLabel = '일반';
              Color badgeBg = Colors.green[50]!;
              Color badgeText = Colors.green;

              switch (rawType) {
                case 'UNION':
                  typeLabel = '연합';
                  badgeBg = Colors.purple[50]!;
                  badgeText = Colors.purple;
                  break;
                case 'SCHOOL':
                  typeLabel = '학교';
                  badgeBg = Colors.blue[50]!;
                  badgeText = Colors.blue;
                  break;
                case 'GENERAL':
                default:
                  typeLabel = '일반';
                  badgeBg = Colors.orange[50]!;
                  badgeText = Colors.orange[800]!;
                  break;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  // 🎯 [핵심 교정 ②]: 탭 격발 시점에 해당 동아리의 전용 가입 방식 리스트(rawMethods)까지 함께 묶어 보냅니다.
                  onTap: () => _handleClubClick(id, name, rawType, rawMethods),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Text(school, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                        const Spacer(),

                        // 🎯 [UI 인테리어 업그레이드]: 백엔드가 준 가입 방식 EnumSet 조건들을 카드가 직관적으로 표출합니다.
                        Row(
                          children: [
                            Text('#식별번호 $id', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            if (rawMethods.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                children: rawMethods.map((method) {
                                  String methodKor = '자유';
                                  Color mColor = Colors.teal;

                                  switch (method.toString()) {
                                    case 'FREE': methodKor = '자유'; mColor = Colors.teal; break;
                                    case 'EMAIL': methodKor = '이메일'; mColor = Colors.indigo; break;
                                    case 'CODE': methodKor = '암호'; mColor = Colors.amber[800]!; break;
                                    case 'APPROVAL': methodKor = '승인제'; mColor = Colors.redAccent; break;
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: mColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                    child: Text(methodKor, style: TextStyle(fontSize: 10, color: mColor, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }
}