// lib/features/club_workspace/widgets/club_home_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart'; // 🎯 [추가]: ApiService.baseUrl 활용을 위해 임포트
import '../../../core/providers/active_club_provider.dart';
import '../../../core/providers/club_dashboard_provider.dart';
import '../models/club_dashboard_response.dart';

class ClubHomeView extends ConsumerStatefulWidget {
  const ClubHomeView({super.key});

  @override
  ConsumerState<ClubHomeView> createState() => _ClubHomeViewState();
}

class _ClubHomeViewState extends ConsumerState<ClubHomeView> {
  // 날짜 스트링 가독성 리포밍 헬퍼 (예시: 2026-06-14T23:05:58 -> 06-14 23:05)
  String _formatDateTime(String rawDate) {
    if (rawDate.length < 16) return rawDate;
    try {
      return rawDate.substring(5, 16).replaceAll('T', ' ');
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);
    final dashboardAsync = ref.watch(clubDashboardProvider);

    if (activeClub == null) {
      return const Center(child: Text('동아리 세션 정보를 불러올 수 없습니다.'));
    }

    return Scaffold(
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
                const SizedBox(height: 12),
                Text('대시보드 데이터를 불러오지 못했습니다.\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
        data: (dashboardData) {
          if (dashboardData == null) {
            return const Center(child: Text('활성화된 동아리 데이터가 존재하지 않습니다.'));
          }

          // 리스트 구조에 대응하여 최신 공지글 추출 (비어있으면 null)
          final LatestNoticeDto? latestNotice =
          dashboardData.notices.isNotEmpty ? dashboardData.notices.first : null;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(clubDashboardProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 웰컴 환영 배너 카드
                  _buildWelcomeBanner(activeClub.clubInfo?.clubName ?? '동아리'),
                  const SizedBox(height: 28),

                  // 2. 동아리 실시간 약식 스탯 현황판 (오늘 작성한 피드 수 매핑)
                  _buildQuickStats(dashboardData.memberCount, dashboardData.todayPostCount),
                  const SizedBox(height: 32),

                  // 3. 최신 공지사항 하이라이트
                  _buildSectionHeader(context, '최신 공지사항', icon: Icons.campaign),
                  const SizedBox(height: 12),
                  _buildNoticeSection(latestNotice),
                  const SizedBox(height: 32),

                  // 4. 최근 자유게시판 피드 (추천/비추천 반영 완공)
                  _buildSectionHeader(context, '자유게시판 최신 피드', icon: Icons.forum_outlined),
                  const SizedBox(height: 12),
                  _buildFreeBoardSection(dashboardData.frees),
                  const SizedBox(height: 32),

                  // 5. 최근 활동 갤러리 프리뷰
                  _buildSectionHeader(context, '최근 활동 하이라이트', icon: Icons.photo_library),
                  const SizedBox(height: 12),
                  _buildGallerySection(dashboardData.activities),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeBanner(String clubName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$clubName에 오신 것을 환영합니다! 🎉', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('동아리의 새로운 공지 및 활동 피드를 실시간으로 확인하고, 부원들과의 소통 프로세스에 참여해 보세요.', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int memberCount, int todayPostCount) {
    return Row(
      children: [
        _buildStatCard('전체 소속 부원', '$memberCount 명', Icons.groups, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('오늘 작성된 새 피드', '$todayPostCount 개', Icons.edit_note_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeSection(LatestNoticeDto? notice) {
    if (notice == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: const Center(child: Text('등록된 최신 공지사항이 존재하지 않습니다.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, '/club/board/detail', arguments: {'postId': notice.postId});
        },
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.push_pin, color: Colors.white, size: 20)),
        title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text('${notice.writerName} • ${_formatDateTime(notice.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildFreeBoardSection(List<LatestFreePostDto> frees) {
    if (frees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: const Center(child: Text('작성된 자유게시판 글이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: frees.length,
        separatorBuilder: (ctx, idx) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final post = frees[index];
          return ListTile(
            onTap: () {
              Navigator.pushNamed(context, '/club/board/detail', arguments: {'postId': post.postId});
            },
            title: Text(post.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(post.writerName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.thumb_up_alt_rounded, size: 14, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text('${post.upvoteCount}', style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                const SizedBox(width: 14),
                Icon(Icons.thumb_down_alt_rounded, size: 14, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text('${post.downvoteCount}', style: TextStyle(fontSize: 12, color: Colors.red[700], fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text(_formatDateTime(post.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🎨 컴포넌트: [완치 대개조] 원격 호스팅 이미지 정교 결합 및 이미지 로드 크래시 가드 가동
  Widget _buildGallerySection(List<LatestActivityDto> photos) {
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: const Center(child: Text('등록된 활동 하이라이트 사진이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    return Row(
      children: photos.map((photo) {
        // 🎯 [완치 핵심]: 상대 경로 앞에 ApiService.baseUrl 주소를 정밀 결합합니다.
        String fullImageUrl = '';
        if (photo.imageUrl.trim().isNotEmpty) {
          fullImageUrl = photo.imageUrl.startsWith('http')
              ? photo.imageUrl
              : '${ApiService.baseUrl}${photo.imageUrl}';
        } else {
          fullImageUrl = 'https://picsum.photos/id/102/400/300';
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // 🚀 ① 실제 다운로드 이미지 백그라운드 레이어 (errorBuilder 안전 가드 포함)
                  Positioned.fill(
                    child: Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
                    ),
                  ),

                  // 🚀 ② 가독성 확보용 그라데이션 및 타이틀 텍스트 오버레이 레이어
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                          photo.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey[700]),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}