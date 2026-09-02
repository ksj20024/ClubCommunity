// lib/features/club_workspace/widgets/board_gallery_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class BoardGalleryView extends ConsumerStatefulWidget {
  const BoardGalleryView({super.key});

  @override
  ConsumerState<BoardGalleryView> createState() => _BoardGalleryViewState();
}

class _BoardGalleryViewState extends ConsumerState<BoardGalleryView> {
  List<dynamic> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    final activeClub = ref.read(activeClubProvider);
    if (activeClub == null || activeClub.clubInfo == null) return;

    setState(() => _isLoading = true);

    final result = await ApiService.getPosts(
      clubId: activeClub.clubInfo!.id!,
      boardType: 'ACTIVITY',
      page: 0,
      size: 20,
    );

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _activities = result['data']['content'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(result['message'] ?? '활동 사진을 불러오지 못했습니다.', isError: true);
      }
    }
  }

  // 포토 아카이브 원격 삭제 다이얼로그 콘텍스트
  void _confirmDelete(int postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('추억 피드 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('갤러리에 등록된 사진과 게시글을 아예 파기하시겠습니까?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final activeClub = ref.read(activeClubProvider);
              if (activeClub == null) return;

              final result = await ApiService.deletePost(
                clubId: activeClub.clubInfo!.id!,
                postId: postId,
              );

              if (result['success'] == true) {
                _showSnackBar('성공적으로 삭제되었습니다.');
                _fetchActivities();
              } else {
                _showSnackBar(result['message'] ?? '삭제 작업 중 서버 에러', isError: true);
              }
            },
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }

  // 갤러리 수정 모드 토스 가방 빌딩
  void _navigateToEditForm(Map<String, dynamic> activity) async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {
        'boardType': 'ACTIVITY',
        'post': activity,
      },
    ) as bool?;

    if (isRefreshed == true) {
      _fetchActivities();
    }
  }

  void _handleLikeVote(int postId) async {
    final activeClub = ref.read(activeClubProvider);
    if (activeClub == null || activeClub.clubInfo == null) return;

    final result = await ApiService.votePost(
      clubId: activeClub.clubInfo!.id!,
      postId: postId,
      voteType: 'UPVOTE',
    );

    if (result['success'] == true) {
      _showSnackBar(result['message'] ?? '좋아요가 반영되었습니다.', isError: false);
      _fetchActivities();
    } else {
      _showSnackBar(result['message'] ?? '처리 중 오류가 발생했습니다.', isError: true);
    }
  }

  void _navigateToPostForm() async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {'boardType': 'ACTIVITY'},
    ) as bool?;

    if (isRefreshed == true) {
      _fetchActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);
    final bool isPresident = activeClub?.clubRole == 'CLUBPRESIDENT' || activeClub?.isManager == true;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }

    if (_activities.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('등록된 활동 추억 사진이 없습니다.\n첫 번째 포토를 업로드해 보세요!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5))),
        floatingActionButton: _buildFab(),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchActivities,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 350,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final act = _activities[index];

            final int postId = act['id'] ?? 0;
            final String title = act['title'] ?? '제목 없음';
            final String writer = act['writerName'] ?? '익명';
            final int likes = act['likeCount'] ?? act['voteCount'] ?? 0;

            // 🎯 [완치 구역]: 존재하지 않는 구형 'imageUrls' 대신 'thumbnailResponse' 연동 안착
            final String? rawThumbnail = act['thumbnailResponse'];
            String imageUrl = '';

            if (rawThumbnail != null && rawThumbnail.trim().isNotEmpty) {
              final String cleanPath = rawThumbnail.startsWith('/') ? rawThumbnail : '/$rawThumbnail';
              imageUrl = '${ApiService.baseUrl}$cleanPath';
            } else {
              imageUrl = 'https://picsum.photos/id/$postId/400/300';
            }

            final bool isAuthor = activeClub?.realName == writer;
            final bool canManage = isAuthor || isPresident;

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () async {
                  final bool? isRefreshed = await Navigator.pushNamed(
                    context,
                    '/club/board/detail',
                    arguments: {'postId': postId},
                  ) as bool?;

                  if (isRefreshed == true) {
                    _fetchActivities();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[100],
                          width: double.infinity,
                          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 28),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // 🚀 [인라인 제어 활성화]: 매니저나 작성자일 때 수정/삭제 팝업 트리거 가동
                              if (canManage)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 70),
                                  onSelected: (val) {
                                    if (val == 'edit') _navigateToEditForm(act);
                                    if (val == 'delete') _confirmDelete(postId);
                                  },
                                  itemBuilder: (ctx) => [
                                    if (isAuthor)
                                      const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 11))),
                                    const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(fontSize: 11, color: Colors.redAccent))),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(writer, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const Spacer(),
                              InkWell(
                                onTap: () => _handleLikeVote(postId),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text('$likes', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      heroTag: 'gallery_board_fab',
      onPressed: _navigateToPostForm,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.add_a_photo_outlined),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}