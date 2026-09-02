// lib/features/club_workspace/screens/post_form_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class PostFormScreen extends ConsumerStatefulWidget {
  const PostFormScreen({super.key});

  @override
  ConsumerState<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends ConsumerState<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isInit = false;
  bool _isProcessing = false;
  bool _isEditMode = false;

  late int _clubId;
  late String _boardType;
  int? _postId;

  final List<XFile> _pickedFiles = [];
  final List<Uint8List> _imagesBytesList = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _boardType = args['boardType'] as String;

      final activeClub = ref.read(activeClubProvider);
      _clubId = activeClub?.clubInfo?.id ?? 0;

      if (args.containsKey('post') || args.containsKey('postData')) {
        _isEditMode = true;
        final post = args['post'] ?? args['postData'];
        _postId = post['id'] ?? post['postId'] as int?;
        _titleController.text = post['title'] ?? '';
        _contentController.text = post['content'] ?? '';
      }

      _isInit = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePickMultiImages() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        List<Uint8List> newBytesList = [];
        for (var image in images) {
          final bytes = await image.readAsBytes();
          newBytesList.add(bytes);
        }

        setState(() {
          _pickedFiles.addAll(images);
          _imagesBytesList.addAll(newBytesList);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _handleSubmit() async {
    if (_clubId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동아리 세션 정보가 누적되지 않았습니다.')),
      );
      return;
    }

    if (_boardType == 'ACTIVITY' && _pickedFiles.isEmpty && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('활동 갤러리는 증빙 이미지 파일이 필수입니다.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    if (_isEditMode && _postId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정할 게시글 식별 번호가 누락되었습니다.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      // 🚀 [완치 인프라]: 서버 불안정이나 예외 파열 시 무한 로딩을 깨부수기 위한 안전망 작동
      try {
        Map<String, dynamic> payload = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'boardType': _boardType,
        };

        Map<String, dynamic> result;

        if (_isEditMode) {
          result = await ApiService.updatePost(
            clubId: _clubId,
            postId: _postId!,
            updateData: payload,
          );
        } else {
          List<PlatformFile>? filesPayload;

          if (_pickedFiles.isNotEmpty) {
            filesPayload = [];
            for (int i = 0; i < _pickedFiles.length; i++) {
              filesPayload.add(
                PlatformFile(
                  name: _pickedFiles[i].name,
                  size: _imagesBytesList[i].length,
                  bytes: _imagesBytesList[i],
                  path: kIsWeb ? null : _pickedFiles[i].path,
                ),
              );
            }
          }

          result = await ApiService.createPost(
            clubId: _clubId,
            postData: payload,
            files: filesPayload,
          );
        }

        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? '게시글이 저장되었습니다.'), backgroundColor: Colors.blueAccent),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? '저장에 실패했습니다.'), backgroundColor: Colors.redAccent),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('시스템 통신 처리 오류: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        // 🚀 통신 성공 사유든 예외 크래시든 최종 단계에서는 로딩 인디케이터 서클을 100% 영구 종료 해제!
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> boardNames = {'NOTICE': '공지사항', 'ACTIVITY': '활동 갤러리', 'FREE': '자유게시판'};
    final String currentBoardName = boardNames[_boardType] ?? '게시판';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? '$currentBoardName 글 수정' : '$currentBoardName 새 글 쓰기',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: '제목을 입력해 주세요.',
                          border: UnderlineInputBorder(),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? '제목은 비워둘 수 없습니다.' : null,
                      ),
                      const SizedBox(height: 24),

                      if (_boardType == 'ACTIVITY') ...[
                        _buildGalleryMultiFileBox(),
                        const SizedBox(height: 24),
                      ],

                      TextFormField(
                        controller: _contentController,
                        maxLines: 12,
                        minLines: 6,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          hintText: _boardType == 'NOTICE'
                              ? '부원들에게 공지할 내용을 상세히 작성해 주세요.'
                              : '동아리원들과 나누고 싶은 이야기를 자유롭게 적어주세요.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? '본문 내용을 작성해 주세요.' : null,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: _handleSubmit,
                        icon: Icon(_isEditMode ? Icons.save_as_outlined : Icons.rate_review_outlined),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(_isEditMode ? '수정 내용 반영하기' : '게시글 등록 완료', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black12,
              child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryMultiFileBox() {
    final bool hasImages = _imagesBytesList.isNotEmpty;

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasImages ? Colors.blueAccent : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _handlePickMultiImages,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: Container(
              width: 100,
              height: double.infinity,
              color: Colors.blueAccent.withValues(alpha: 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: Colors.blueAccent, size: 26),
                  const SizedBox(height: 6),
                  Text('사진 추가\n(${_pickedFiles.length}장)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),

          Expanded(
            child: hasImages
                ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: _imagesBytesList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.memory(_imagesBytesList[index], fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 11,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, color: Colors.white, size: 12),
                            onPressed: () {
                              setState(() {
                                _pickedFiles.removeAt(index);
                                _imagesBytesList.removeAt(index);
                              });
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            )
                : const Center(
              child: Text('첨부된 활동 증빙 이미지가 없습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}