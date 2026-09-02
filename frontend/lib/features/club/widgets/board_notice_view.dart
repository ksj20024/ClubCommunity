// lib/features/club_workspace/widgets/board_notice_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class BoardNoticeView extends ConsumerStatefulWidget {
  const BoardNoticeView({super.key});

  @override
  ConsumerState<BoardNoticeView> createState() => _BoardNoticeViewState();
}

class _BoardNoticeViewState extends ConsumerState<BoardNoticeView> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    final activeClub = ref.read(activeClubProvider);
    if (activeClub == null || activeClub.clubInfo == null) return;

    setState(() => _isLoading = true);

    final result = await ApiService.getPosts(
      clubId: activeClub.clubInfo!.id!,
      boardType: 'NOTICE',
      page: 0,
      size: 20,
    );

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _notices = result['data']['content'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '공지사항을 불러오지 못했습니다.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 🎯 [신규]: 마스터용 공지사항 파기 컨펌 모달
  void _confirmDelete(int postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('공지사항 파기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('이 공식 공지사항을 전면 파기 격리하시겠습니까?', style: TextStyle(fontSize: 13)),
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
                _fetchNotices();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? '공지 파기 실패'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('파기하기'),
          ),
        ],
      ),
    );
  }

  // 🎯 [신규]: 공지사항 수정 분기 패키지 조립
  void _navigateToEditForm(Map<String, dynamic> notice) async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {
        'boardType': 'NOTICE',
        'post': notice,
      },
    ) as bool?;

    if (isRefreshed == true) {
      _fetchNotices();
    }
  }

  void _navigateToPostForm() async {
    final bool? isRefreshed = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {'boardType': 'NOTICE'},
    ) as bool?;

    if (isRefreshed == true) {
      _fetchNotices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClub = ref.watch(activeClubProvider);
    final bool isPresident = activeClub?.clubRole == 'CLUBPRESIDENT' || activeClub?.isManager == true;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }

    if (_notices.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('등록된 공지사항이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 14))),
        floatingActionButton: isPresident ? _buildFab() : null,
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchNotices,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _notices.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final notice = _notices[index];

            final int postId = notice['id'] ?? 0;
            final String title = notice['title'] ?? '제목 없음';
            final String writer = notice['writerName'] ?? notice['author'] ?? '알 수 없음';
            final String date = notice['createdDate'] != null ? notice['createdDate'].toString().substring(0, 10) : '';
            final int views = notice['viewCount'] ?? 0;
            final bool isPinned = notice['isPinned'] ?? false;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tileColor: isPinned ? Colors.orange.withValues(alpha: 0.03) : null,
              leading: isPinned
                  ? const Icon(Icons.push_pin, color: Colors.orange, size: 20)
                  : const Icon(Icons.description_outlined, color: Colors.grey, size: 20),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: isPinned ? FontWeight.bold : FontWeight.w500,
                  color: isPinned ? Colors.orange[900] : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Row(
                  children: [
                    Text(writer, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 12),
                    Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('$views', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),

                  // 🎯 [운영진 전용 공지 제어용 메뉴단 설치]
                  if (isPresident) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.blueGrey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 80),
                      onSelected: (val) {
                        if (val == 'edit') _navigateToEditForm(notice);
                        if (val == 'delete') _confirmDelete(postId);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('수정', style: TextStyle(fontSize: 12))),
                        const PopupMenuItem(value: 'delete', child: Text('파기', style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                      ],
                    ),
                  ],
                ],
              ),
              onTap: () async {
                final bool? isRefreshed = await Navigator.pushNamed(
                  context,
                  '/club/board/detail',
                  arguments: {'postId': postId},
                ) as bool?;

                if (isRefreshed == true) {
                  _fetchNotices();
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: isPresident ? _buildFab() : null,
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      heroTag: 'notice_board_fab',
      onPressed: _navigateToPostForm,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      child: const Icon(Icons.edit),
    );
  }
}