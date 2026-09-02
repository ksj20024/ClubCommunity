// lib/features/club_workspace/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isInit = false;        // 💡 중복 호출 방지용 플래그
  bool _hasChanged = false;    // 🎯 목록 화면에 리프레시(true)를 전달할 변경 감지 배지
  Map<String, dynamic> _post = {};
  List<dynamic> _comments = [];

  final _commentController = TextEditingController();
  late int _postId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 💡 didChangeDependencies의 무분별한 중복 API 호출을 플래그로 가드합니다.
    if (!_isInit) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _postId = args['postId'] as int;

      _loadPostDetail();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 게시글 상세 데이터 수급
  Future<void> _loadPostDetail() async {
    final activeClub = ref.read(activeClubProvider);
    final int? clubId = activeClub?.clubInfo?.id;
    if (clubId == null) return;

    final result = await ApiService.getPostDetail(clubId, _postId);

    if (mounted) {
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _post = result['data'];
          _comments = result['data']['comments'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(result['message'] ?? '게시글을 불러오지 못했습니다.', isError: true);
        Navigator.pop(context);
      }
    }
  }

  // 본문 내 수정 버튼 클릭 시 폼 화면 이동 및 실시간 리로드
  Future<void> _handleEditPost() async {
    final bool? isEdited = await Navigator.pushNamed(
      context,
      '/club/board/form',
      arguments: {
        'boardType': _post['boardType'] ?? 'FREE',
        'post': _post,
      },
    ) as bool?;

    if (isEdited == true) {
      setState(() {
        _hasChanged = true; // 🎯 수정을 거쳐왔음을 기록하여 탈출 시 목록 리프레시 강제 유도
      });
      _loadPostDetail();
    }
  }

  // 게시글 전면 파기 격발
  void _handleDeletePost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('정말로 이 게시글을 영구 삭제하시겠습니까?\n첨부된 댓글과 미디어도 함께 파기됩니다.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isProcessing = true);

              final int clubId = ref.read(activeClubProvider)!.clubInfo!.id!;
              final result = await ApiService.deletePost(clubId: clubId, postId: _postId);

              setState(() => _isProcessing = false);

              if (result['success'] == true) {
                _showSnackBar('게시글이 삭제되었습니다.');
                if (mounted) Navigator.pop(context, true);
              } else {
                _showSnackBar(result['message'] ?? '삭제 처리에 실패했습니다.', isError: true);
              }
            },
            child: const Text('삭제 확정'),
          ),
        ],
      ),
    );
  }

  // 댓글 작성 API 트리거
  void _handleCreateComment() async {
    final String content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isProcessing = true);
    final int clubId = ref.read(activeClubProvider)!.clubInfo!.id!;

    final result = await ApiService.createComment(
      clubId: clubId,
      postId: _postId,
      commentData: {'content': content},
    );

    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      _commentController.clear();
      _loadPostDetail();
    } else {
      _showSnackBar(result['message'] ?? '댓글 등록 실패', isError: true);
    }
  }

  // 댓글 삭제 API 트리거
  void _handleDeleteComment(int commentId) async {
    setState(() => _isProcessing = true);
    final int clubId = ref.read(activeClubProvider)!.clubInfo!.id!;

    final result = await ApiService.deleteComment(clubId: clubId, commentId: commentId);
    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      _showSnackBar('댓글이 삭제되었습니다.');
      _loadPostDetail();
    } else {
      _showSnackBar(result['message'] ?? '댓글 삭제 실패', isError: true);
    }
  }

  String _formatDateTime(String rawDate) {
    if (rawDate.length < 16) return rawDate;
    return rawDate.substring(0, 16).replaceAll('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final mySession = ref.watch(activeClubProvider);
    final int postWriterUid = _post['writerId'] ?? 0;

    final bool isAuthor = (mySession?.uid == postWriterUid && postWriterUid != 0);
    final bool isManager = mySession?.clubRole == 'CLUBPRESIDENT' || mySession?.clubRole == 'CLUBADMIN' || mySession?.isManager == true;

    final String title = _post['title'] ?? '제목 없음';
    final String content = _post['content'] ?? '';
    final String writer = _post['writerName'] ?? '익명';
    final int views = _post['viewCount'] ?? 0;
    final String date = _formatDateTime(_post['createdAt']?.toString() ?? '');

    // 🎯 [완치 핵심구역 ③]: PopScope로 감싸 시스템 백버튼 및 앱 바 뒤로 가기 탈출 경로를 일원화 통제합니다.
    return PopScope(
      canPop: false, // 제어권을 플러터 엔진이 가로챕니다.
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 🚀 수정을 한 번이라도 했다면 _hasChanged가 true이므로 목록 화면이 이를 감지해 자동 리프레시를 격발합니다.
        Navigator.pop(context, _hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('게시글 상세', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
          // 🎯 [완치 핵심구역 ①]: 앱바 좌측 화살표 단추 클릭 시에도 수동 팝업으로 변경 결과 전파
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanged),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 750),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4, color: Colors.black87)),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                CircleAvatar(radius: 14, backgroundColor: Colors.blueAccent.withValues(alpha: 0.08), child: const Icon(Icons.person, size: 14, color: Colors.blueAccent)),
                                const SizedBox(width: 10),
                                Text(writer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                                const SizedBox(width: 12),
                                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),

                                const Spacer(),
                                Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[400]),
                                const SizedBox(width: 4),
                                Text('$views회 조회', style: TextStyle(fontSize: 12, color: Colors.grey[600])),

                                if (isAuthor) ...[
                                  const SizedBox(width: 6),
                                  Text('•', style: TextStyle(color: Colors.grey[300])),
                                  TextButton(
                                    onPressed: _handleEditPost,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('수정', style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],

                                if (isAuthor || isManager) ...[
                                  if (!isAuthor) ...[
                                    const SizedBox(width: 6),
                                    Text('•', style: TextStyle(color: Colors.grey[300])),
                                  ],
                                  TextButton(
                                    onPressed: _handleDeletePost,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.0),
                              child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                            ),

                            Container(
                              constraints: const BoxConstraints(minHeight: 220),
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                content,
                                style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87, letterSpacing: 0.2),
                              ),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                            ),

                            Row(
                              children: [
                                const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text('댓글', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(width: 4),
                                Text('${_comments.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent)),
                              ],
                            ),
                            const SizedBox(height: 18),

                            _buildCommentList(mySession?.uid, isManager),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildCommentInputBar(),
              ],
            ),
            if (_isProcessing) const ColoredBox(color: Colors.black26, child: Center(child: CircularProgressIndicator(color: Colors.blueAccent))),
          ],
        ),
      ),
    );
  }

  // 하위 컴포넌트: 댓글 리스트 뷰
  Widget _buildCommentList(int? myUid, bool isClubManager) {
    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text('아직 등록된 댓글이 없습니다. 첫 마디를 남겨보세요!', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final int commentId = comment['id'] ?? 0;
        final int commentWriterUid = comment['writerUid'] ?? comment['uid'] ?? -1;
        final String writerName = comment['writerName'] ?? '익명 부원';
        final String content = comment['content'] ?? '';

        final bool canDeleteComment = myUid == commentWriterUid || isClubManager;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[100]!)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(writerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 6),
                      Text(content, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
                    ],
                  ),
                ),
                if (canDeleteComment)
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 15, color: Colors.grey[400]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _handleDeleteComment(commentId),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  // 하위 컴포넌트: 댓글 입력 필드 바
  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, -3))],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: null,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '따뜻한 댓글을 남겨주세요.',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    fillColor: Colors.grey[50],
                    filled: true,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.08),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 16),
                  onPressed: _handleCreateComment,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}