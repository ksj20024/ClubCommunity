// lib/features/club_workspace/widgets/board_free_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class BoardFreeView extends ConsumerStatefulWidget {
  const BoardFreeView({super.key});

  @override
  ConsumerState<BoardFreeView> createState() => _BoardFreeViewState();
}

class _BoardFreeViewState extends ConsumerState<BoardFreeView> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final activeClub = ref.read(activeClubProvider);
    if (activeClub == null || activeClub.clubInfo == null) return;

    setState(() => _isLoading = true);

    final result = await ApiService.getPosts(
      clubId: activeClub.clubInfo!.id!,
      boardType: 'FREE',
      page: 0,
      size: 20,
    );

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _posts = result['data']['content'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(result['message'] ?? '게시글 목록을 불러오지 못했습니다.', isError: true);
      }
    }
  }

  // 🎯 [신규]: 게시글 삭제 비즈니스 로직 및 컨펌 모달 격발
  void _confirmDelete(int postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('정말로 이 게시글을 영구 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.', style: TextStyle(fontSize: 13)),
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
                _showSnackBar('게시글이 성공적으로 삭제되었습니다.');
                _fetchPosts(); // 목록 대청소 리프레시
              } else {
                _showSnackBar(result['message'] ?? '삭제 처리 중 오류 발생', isError: true);
              }
            },
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );
  }

  // 🎯 [신규]: 수정 모드로 글쓰기 폼 네비게이션 가방 조립
  void _navigateToEditForm(Map<String, dynamic> post) async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {
        'boardType': 'FREE',
        'post': post, // 🚀 기존 게시글 데이터를 통째로 토스하여 폼에 initialValue 바인딩 유도
      },
    ) as bool?;

    if (isRefreshed == true) {
      _fetchPosts();
    }
  }

  void _handleVote(int postId, String voteType) async {
    final activeClub = ref.read(activeClubProvider);
    if (activeClub == null || activeClub.clubInfo == null) return;

    final result = await ApiService.votePost(
      clubId: activeClub.clubInfo!.id!,
      postId: postId,
      voteType: voteType,
    );

    if (result['success'] == true) {
      _showSnackBar(result['message'] ?? '투표가 반영되었습니다.', isError: false);
      _fetchPosts();
    } else {
      _showSnackBar(result['message'] ?? '투표 처리 중 오류가 발생했습니다.', isError: true);
    }
  }

  void _navigateToPostForm() async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {'boardType': 'FREE'},
    ) as bool?;

    if (isRefreshed == true) {
      _fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);
    final bool isPresident = activeClub?.clubRole == 'CLUBPRESIDENT' || activeClub?.isManager == true;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }

    if (_posts.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('첫 번째 게시글을 작성해 보세요!', style: TextStyle(color: Colors.grey, fontSize: 14))),
        floatingActionButton: _buildFab(),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];

            final int postId = post['id'] ?? 0;
            final String title = post['title'] ?? '제목 없음';
            final String writer = post['writerName'] ?? '익명';
            final int commentCount = post['commentCount'] ?? 0;
            final int likeCount = post['likeCount'] ?? post['voteCount'] ?? 0;

            final String rawDate = post['createdDate']?.toString() ?? '';
            final String date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

            // 🛡️ 권한 검증 라인: 내가 쓴 글이거나 또는 동아리 마스터 권한인가?
            final bool isAuthor = activeClub?.realName == writer;
            final bool canManage = isAuthor || isPresident;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey[200]!)),
              child: InkWell(
                onTap: () async {
                  final bool? isRefreshed = await Navigator.pushNamed(
                    context,
                    '/club/board/detail',
                    arguments: {'postId': postId},
                  ) as bool?;

                  if (isRefreshed == true) {
                    _fetchPosts();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                            child: const Icon(Icons.person, size: 12, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 8),
                          Text(writer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                          const SizedBox(width: 8),
                          Text('• $date', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const Spacer(),

                          // 🎯 [수정/삭제 팝업 트리거 주입]
                          if (canManage)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 80),
                              onSelected: (value) {
                                if (value == 'edit') _navigateToEditForm(post);
                                if (value == 'delete') _confirmDelete(postId);
                              },
                              itemBuilder: (ctx) => [
                                if (isAuthor) // 수정은 원본 작성자 본인만 가능 가드
                                  const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 12))),
                                const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatIcon(Icons.chat_bubble_outline, commentCount, color: Colors.blue),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _handleVote(postId, 'UPVOTE'),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: _buildStatIcon(Icons.thumb_up_alt_outlined, likeCount, color: Colors.orange),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
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
      heroTag: 'free_board_fab',
      onPressed: _navigateToPostForm,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.create_outlined),
    );
  }

  Widget _buildStatIcon(IconData icon, int count, {required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}