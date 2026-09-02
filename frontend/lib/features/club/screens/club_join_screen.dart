// lib/features/club_workspace/screens/club_join_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../models/club_application_form.dart';
import '../../../core/providers/club_join_provider.dart';

class ClubJoinScreen extends ConsumerStatefulWidget {
  const ClubJoinScreen({super.key});

  @override
  ConsumerState<ClubJoinScreen> createState() => _ClubJoinScreenState();
}

class _ClubJoinScreenState extends ConsumerState<ClubJoinScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;

  late int _clubId;
  late String _clubName;
  late String _clubType;
  late List<dynamic> _clubJoinMethods;

  List<ClubApplicationForm> _questionFormList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clubJoinProvider.notifier).clear();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _clubId = args['clubId'] as int;
    _clubName = args['clubName'] as String;
    _clubType = args['clubType']?.toString() ?? 'GENERAL';
    _clubJoinMethods = args['clubJoinMethod'] as List<dynamic>? ?? [];

    _loadClubQuestions();
  }

  void _loadClubQuestions() async {
    final result = await ApiService.getClubForm(_clubId);

    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          final rawData = result['data'];
          Map<String, dynamic> rootMap = {};

          if (rawData is String) {
            rootMap = jsonDecode(rawData) as Map<String, dynamic>;
          } else if (rawData is Map<String, dynamic>) {
            rootMap = rawData;
          }

          final rawFormSettings = rootMap['formSettings'];
          Map<String, dynamic> formSettingsMap = {};

          if (rawFormSettings is String) {
            formSettingsMap = jsonDecode(rawFormSettings) as Map<String, dynamic>;
          } else if (rawFormSettings is Map<String, dynamic>) {
            formSettingsMap = rawFormSettings;
          }

          final List<dynamic> rawQuestions = formSettingsMap['questions'] ?? [];
          _questionFormList = rawQuestions
              .map((jsonItem) => ClubApplicationForm.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
        } else {
          _questionFormList = [];
        }
        _isLoading = false;
      });
    }
  }

  void _handleSubmitApplication(bool isSchoolClub, bool isCodeRequired) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);

      final joinState = ref.read(clubJoinProvider);
      final Map<String, dynamic> requestPayload = joinState.toJson(
        isSchoolClub: isSchoolClub,
        isCodeRequired: isCodeRequired,
      );

      final result = await ApiService.submitApplication(_clubId, requestPayload);
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        if (mounted) {
          _showSuccessDialog('가입 신청 완료', '[$_clubName] 동아리에 가입 신청 서류를 정상 접수했습니다.\n운영진 승인이 완료되면 워크스페이스가 활성화됩니다.');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? '신청서 제출 실패'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSchoolClub = _clubType == 'SCHOOL';
    final bool isCodeRequired = _clubJoinMethods.contains('CODE');

    final joinState = ref.watch(clubJoinProvider);
    final notifier = ref.read(clubJoinProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('$_clubName 입부 서류 작성', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📌 가입 기본 자격 증명 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                          const SizedBox(height: 12),

                          // ① 이메일 필드
                          TextFormField(
                            // 🎯 [완치 구역]: 동적 상태 문자열을 지우고 고정상수 Key 배치로 포커스 아웃 크래시 차단!
                            key: const ValueKey('club_join_email_field'),
                            initialValue: joinState.email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: '소통용 이메일 주소 *', border: OutlineInputBorder(), isDense: true),
                            validator: (v) => v == null || v.trim().isEmpty ? '이메일 주소는 필수입니다.' : null,
                            onChanged: notifier.updateEmail,
                          ),
                          const SizedBox(height: 12),

                          // ② 학번 필드
                          if (isSchoolClub) ...[
                            TextFormField(
                              // 🎯 [완치 구역]: 정적 고유식별자 키로 락(Lock) 결합
                              key: const ValueKey('club_join_student_no_field'),
                              initialValue: joinState.studentNo,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: '교내 등록 학번 *', border: OutlineInputBorder(), isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? '교내 동아리는 학번 입력이 필수입니다.' : null,
                              onChanged: notifier.updateStudentNo,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // ③ 비밀번호 필드
                          if (isCodeRequired) ...[
                            TextFormField(
                              // 🎯 [완치 구역]: 고정 패치 키 적용
                              key: const ValueKey('club_join_password_field'),
                              initialValue: joinState.clubPassword,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: '동아리 개설 가입 암호 *', border: OutlineInputBorder(), isDense: true),
                              validator: (v) => v == null || v.trim().isEmpty ? '이 동아리는 가입을 위한 고유 암호 기재가 필수입니다.' : null,
                              onChanged: notifier.updateClubPassword,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text('📝 동아리 커스텀 심사 문항 답변 기재', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                    const SizedBox(height: 16),

                    Expanded(
                      child: _questionFormList.isEmpty
                          ? const Center(child: Text('이 동아리는 추가 심사 질문 양식이 없습니다.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)))
                          : ListView.builder(
                        itemCount: _questionFormList.length,
                        itemBuilder: (context, index) {
                          final ClubApplicationForm q = _questionFormList[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: TextFormField(
                              // 🎯 [완치 구역]: 질문 문항 역시 실시간 타이핑 내용(_currentAnswer)을 키에 엮지 말고,
                              // 동아리가 설계한 질문 고유 키값('q.key')만 단독 매핑해야 타이핑 중 에디터가 파괴되지 않습니다!
                              key: ValueKey('club_question_${q.key}'),
                              initialValue: (joinState.answers[q.key] ?? '').toString(),
                              maxLines: q.maxLines,
                              minLines: q.minLines,
                              decoration: InputDecoration(
                                labelText: q.question,
                                alignLabelWithHint: true,
                                border: const OutlineInputBorder(),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? '이 문항은 필수 기재 항목입니다.' : null,
                              onChanged: (value) {
                                notifier.updateAnswer(q.key, value.trim());
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _handleSubmitApplication(isSchoolClub, isCodeRequired),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('가입 신청 서류 서버 최종 제출', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
          if (_isSubmitting)
            const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.read(clubJoinProvider.notifier).clear();
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text('메인 허브로 이동'),
          )
        ],
      ),
    );
  }
}