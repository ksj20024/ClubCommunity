// lib/features/home/widgets/joined_club_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../club/models/club_info_response.dart';
import 'welcome_header_widget.dart';

class JoinedClubView extends ConsumerWidget {
  final List<ClubInfoResponse> myClubs;
  final Function(String) onActionMessage;

  const JoinedClubView({
    super.key,
    required this.myClubs,
    required this.onActionMessage,
  });

  // 🎯 [UX 혁신]: 추가 가입 혹은 개설을 정밀 분기해주는 고유 선택 모달 창
  void _showActionChoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('어떤 작업을 진행할까요?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 갈래길 1: 동아리 탐색 및 가입
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.search, color: Colors.white, size: 20)),
              title: const Text('새로운 동아리 탐색 및 가입', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('교내/연합 동아리를 검색하고 신청서를 씁니다.', style: TextStyle(fontSize: 11)),
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                Navigator.pop(ctx); // 모달 닫기
                onActionMessage('동아리 조회 화면으로 이동합니다.');
                // 🚀 앞서 완공한 조회 스크린으로 완벽하게 라우팅 체결
                Navigator.pushNamed(context, '/club/search');
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // 갈래길 2: 새로운 동아리 개설
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.add_box_outlined, color: Colors.white, size: 20)),
              title: const Text('새로운 동아리 개설 (회장 선임)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('내가 회장이 되어 새로운 동아리를 창설합니다.', style: TextStyle(fontSize: 11)),
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () {
                Navigator.pop(ctx); // 모달 닫기
                onActionMessage('동아리 생성 화면으로 이동합니다.');
                Navigator.pushNamed(context, '/club/create');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '내 동아리 워크스페이스',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  // 🎯 버튼 클릭 시 통합 분기형 팝업 모달 격발
                  ElevatedButton.icon(
                    onPressed: () => _showActionChoiceDialog(context),
                    icon: const Icon(Icons.swap_calls_rounded, size: 18),
                    label: const Text('추가 가입 / 개설'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: myClubs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWebOrTablet ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.0,
                ),
                itemBuilder: (context, index) {
                  final club = myClubs[index];

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () {
                        // 🚀 [구조 마이그레이션]: ClubHubScreen 내부의 /my-auth 파이프라인 완공에 입각하여
                        // 불필요한 이름, 권한 등의 아규먼트 가방을 모두 폭파하고 순수 고유 clubId만 담백하게 패싱합니다.
                        Navigator.pushNamed(
                          context,
                          '/club/hub',
                          arguments: {
                            'clubId': club.id,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.class_, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    club.clubName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildTypeBadge(club.clubType),
                                const SizedBox(width: 8),
                                if (club.schoolName != null)
                                  Expanded(
                                    child: Text(
                                      club.schoolName!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color badgeColor;
    String typeKor;

    switch (type) {
      case 'SCHOOL':
        badgeColor = Colors.teal;
        typeKor = '교내 동아리';
        break;
      case 'UNION':
        badgeColor = Colors.purple;
        typeKor = '연합 동아리';
        break;
      case 'GENERAL':
      default:
        badgeColor = Colors.orange;
        typeKor = '일반 동아리';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        typeKor,
        style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}