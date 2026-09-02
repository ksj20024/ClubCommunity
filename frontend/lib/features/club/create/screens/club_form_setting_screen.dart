// lib/features/club/screens/club_form_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 추가
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/club_creation_provider.dart'; // 💡 추가

class QuestionInputItem {
  final TextEditingController questionController;
  final TextEditingController keyController;
  String type;

  QuestionInputItem({
    required String question,
    required String key,
    required this.type,
  })  : questionController = TextEditingController(text: question),
        keyController = TextEditingController(text: key);

  void dispose() {
    questionController.dispose();
    keyController.dispose();
  }

  Map<String, dynamic> toJson() => {
    'question': questionController.text.trim(),
    'key': keyController.text.trim(),
    'type': type,
  };
}

// 🎯 ConsumerStatefulWidget으로 변환
class ClubFormSettingScreen extends ConsumerStatefulWidget {
  const ClubFormSettingScreen({super.key});

  @override
  ConsumerState<ClubFormSettingScreen> createState() => _ClubFormSettingScreenState();
}

class _ClubFormSettingScreenState extends ConsumerState<ClubFormSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<QuestionInputItem> _questions = [];
  bool _isProcessing = false;

  // 💡 [대청소]: late 라우트 파라미터 백업 변수와 didChangeDependencies가 소멸되었습니다.

  @override
  void initState() {
    super.initState();
    // 🎯 [구조 개선]: 웰컴 7대 기본 질문 템플릿 빌드를 안전하게 initState 단계에서 격발합니다.
    _addNewQuestion(question: '동아리 명을 입력해주세요.', key: 'clubName', type: 'TEXT');
    _addNewQuestion(question: '학과를 입력해주세요.', key: 'department', type: 'TEXT');
    _addNewQuestion(question: '학번을 입력해주세요.', key: 'studentNum', type: 'TEXT');
    _addNewQuestion(question: '이름을 입력해주세요.', key: 'userName', type: 'TEXT');
    _addNewQuestion(question: '연락처를 입력해주세요.', key: 'phoneNumber', type: 'TEXT');
    _addNewQuestion(question: '자기 소개를 입력해주세요.', key: 'introduction', type: 'LONG_TEXT');
    _addNewQuestion(question: '지원동기를 입력해주세요.', key: 'reason', type: 'LONG_TEXT');
  }

  @override
  void dispose() {
    for (var item in _questions) {
      item.dispose();
    }
    super.dispose();
  }

  void _addNewQuestion({String question = '', String key = '', String type = 'TEXT'}) {
    setState(() {
      _questions.add(QuestionInputItem(question: question, key: key, type: type));
    });
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 이상의 입부 질문 항목이 존재해야 합니다.')),
      );
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  void _handleSave() async {
    // 🎯 [임시 창고 데이터 호출]: 현재 생성 단계의 스냅샷을 창고에서 안전하게 꺼내옵니다.
    final creationState = ref.read(clubCreationProvider);
    if (creationState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류: 개설 중인 동아리 세션 정보를 찾을 수 없습니다.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      List<Map<String, dynamic>> payload = _questions.map((item) => item.toJson()).toList();

      // 🎯 창고가 들고 있던 진짜 clubId 바인딩
      final result = await ApiService.setupQuestions(creationState.clubId, payload);
      setState(() => _isProcessing = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.blueAccent),
          );

          // 🎯 창고의 useAutoDoc 분기를 판단하여 다음 페이지로 라우팅 (가방 상자 제거)
          if (creationState.useAutoDoc) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/club/template-upload',
                  (route) => false,
            );
          } else {
            // 개설이 끝났으므로 임시 세션 상자 초기화(null) 후 홈으로 랜딩
            ref.read(clubCreationProvider.notifier).clear();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 상단 가이드 배너용 가볍고 안전한 ID 구독 처리
    final creationState = ref.watch(clubCreationProvider);
    final int displayClubId = creationState?.clubId ?? 0;
    final bool currentUseAutoDoc = creationState?.useAutoDoc ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('입부 신청 질문지 조립', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
            tooltip: '질문 항목 추가',
            onPressed: () => _addNewQuestion(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.withValues(alpha: 0.05),
                      child: Text(
                        '💡 동아리 고유 식별 번호 [#$displayClubId]의 기본 질문 세트입니다.\n매핑 키(key)는 향후 입부원서 파일(.docx)과 연동될 핵심 식별자이므로 영문 카멜케이스(camelCase) 작성을 권장합니다.',
                        style: TextStyle(fontSize: 13, color: Colors.blueGrey[800], height: 1.4),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final item = _questions[index];
                          return Card(
                            key: ValueKey(item),
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.blueGrey[100],
                                        child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _removeQuestion(index),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isCompact = constraints.maxWidth < 500;
                                      return Flex(
                                        direction: isCompact ? Axis.vertical : Axis.horizontal,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: isCompact ? 0 : 3,
                                            child: TextFormField(
                                              controller: item.questionController,
                                              decoration: const InputDecoration(labelText: '질문 내용 (question)', hintText: '예: 학과를 입력해 주세요.', border: OutlineInputBorder()),
                                              validator: (value) => value == null || value.trim().isEmpty ? '질문 내용을 입력해 주세요.' : null,
                                            ),
                                          ),
                                          if (!isCompact) const SizedBox(width: 12),
                                          if (isCompact) const SizedBox(height: 12),
                                          Expanded(
                                            flex: isCompact ? 0 : 2,
                                            child: TextFormField(
                                              controller: item.keyController,
                                              decoration: const InputDecoration(labelText: '매핑 연산자 (key)', hintText: '예: department', border: OutlineInputBorder()),
                                              validator: (value) => value == null || value.trim().isEmpty ? '매핑 키값은 필수입니다.' : null,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: item.type,
                                    decoration: const InputDecoration(labelText: '입력 문자열 허용 규격 (type)', border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'TEXT', child: Row(children: [Icon(Icons.text_fields, size: 18), SizedBox(width: 8), Text('일반 단답형 텍스트 (TEXT)')])),
                                      DropdownMenuItem(value: 'LONG_TEXT', child: Row(children: [Icon(Icons.article_outlined, size: 18), SizedBox(width: 8), Text('장문형 서술형 텍스트 (LONG_TEXT)')])),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        item.type = value!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _addNewQuestion(),
                              icon: const Icon(Icons.add),
                              label: const Text('새 질문 항목 추가'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleSave,
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: Text(currentUseAutoDoc ? '양식 저장 후 템플릿 업로드로 이동' : '질문 설정 완료 및 개설 확정'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            ),
                          ),
                        ],
                      ),
                    )
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
}