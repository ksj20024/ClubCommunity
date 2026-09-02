// lib/features/club/screens/club_template_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 추가
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/club_creation_provider.dart'; // 💡 추가

// 🎯 ConsumerStatefulWidget으로 변환
class ClubTemplateUploadScreen extends ConsumerStatefulWidget {
  const ClubTemplateUploadScreen({super.key});

  @override
  ConsumerState<ClubTemplateUploadScreen> createState() => _ClubTemplateUploadScreenState();
}

class _ClubTemplateUploadScreenState extends ConsumerState<ClubTemplateUploadScreen> {
  bool _isProcessing = false;
  PlatformFile? _selectedFile;

  // 💡 [대청소]: didChangeDependencies 및 late _clubId가 완전히 청소되었습니다.

  void _pickTemplateFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      _showSnackBar('파일을 선택하는 중 오류가 발생했습니다.', isError: true);
    }
  }

  void _handleUpload() async {
    // 🎯 [임시 창고 데이터 호출]: 업로드에 필요한 진짜 clubId를 조달합니다.
    final creationState = ref.read(clubCreationProvider);
    if (creationState == null) {
      _showSnackBar('오류: 만료된 동아리 개설 세션입니다.', isError: true);
      return;
    }

    if (_selectedFile == null || _selectedFile!.bytes == null) {
      _showSnackBar('업로드할 워드 템플릿 파일을 선택해 주세요.', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    final result = await ApiService.setupTemplate(
      clubId: creationState.clubId, // 🎯 안전하게 데이터 추출 연동
      fileBytes: _selectedFile!.bytes!,
      filename: _selectedFile!.name,
    );

    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      if (mounted) {
        _showSnackBar(result['message'], isError: false);

        //개설 완료 후 provider 삭제
        ref.read(clubCreationProvider.notifier).clear();

        // 메인 대문 화면으로 랜딩 복원
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } else {
      if (mounted) {
        _showSnackBar(result['message'], isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('입부원서 파일 템플릿 등록', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 750),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('📌 MS Word(.docx) 파일 작성법 안내'),
                    const Text(
                      '이전 단계에서 설정한 [매핑 연산자(key)]를 워드 파일 내에 아래 예시처럼 중괄호 2개 {{ }} 로 감싸서 배치해 주세요. 부원이 가입 신청 시 입력한 알맹이 데이터로 문서가 자동 치환되어 PDF/Word로 뽑혀 나옵니다.',
                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _buildVirtualWordPreview(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('📂 템플릿 파일 업로드'),
                    _buildUploadDropZone(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedFile != null ? _handleUpload : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('템플릿 등록 완료 및 개설 최종 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildVirtualWordPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.blue[800],
            child: const Row(
              children: [
                Icon(Icons.description, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('입부원서_템플릿_매핑예시.docx - MS Word', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('동 아 리  입 부 원 서', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4))),
                const SizedBox(height: 24),
                _buildWordGridRow('신청 동아리', '{{clubName}}'),
                _buildWordGridRow('소속 학과', '{{department}}'),
                _buildWordGridRow('성명 / 학번', '{{userName}} / {{studentNum}}'),
                _buildWordGridRow('연락처', '{{phoneNumber}}'),
                const SizedBox(height: 12),
                const Text('[자기소개 및 지원동기]', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text('{{introduction}}\n\n{{reason}}', style: TextStyle(fontSize: 12, color: Colors.blueAccent, height: 1.4)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWordGridRow(String label, String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 90, padding: const EdgeInsets.all(6), color: Colors.grey[100], child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Container(padding: const EdgeInsets.all(6), child: Text(key, style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildUploadDropZone() {
    final bool hasFile = _selectedFile != null;

    return InkWell(
      onTap: _pickTemplateFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: hasFile ? Colors.blue.withValues(alpha: 0.02) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? Colors.blueAccent : Colors.grey[400]!,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFile ? Icons.insert_drive_file : Icons.cloud_upload_outlined,
              size: 48,
              color: hasFile ? Colors.blueAccent : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            if (hasFile) ...[
              Text(_selectedFile!.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Text('${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextButton(onPressed: _pickTemplateFile, child: const Text('파일 변경하기', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
            ] else ...[
              const Text('이곳을 클릭하여 .docx 파일을 선택하세요.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 6),
              const Text('Microsoft Word 파일만 업로드 가능합니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
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