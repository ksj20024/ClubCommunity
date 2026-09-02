// lib/features/club_workspace/widgets/club_my_profile_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';
import '../../auth/models/user_context_response.dart';
import '../models/club_application_form.dart';

class ClubMyProfileView extends ConsumerStatefulWidget {
  const ClubMyProfileView({super.key});

  @override
  ConsumerState<ClubMyProfileView> createState() => _ClubMyProfileViewState();
}

class _ClubMyProfileViewState extends ConsumerState<ClubMyProfileView> {
  bool _isLazyLoading = true;
  bool _isProcessing = false;
  bool _isDownloading = false;

  // 백엔드 formSettings 문자열에서 파싱해 낸 가입 질문 리스트 적재 가방
  List<ClubApplicationForm> _questionFormList = [];

  @override
  void initState() {
    super.initState();
    _loadFullMembership();
  }

  // 동아리 상세 정보 및 서류 세션 원격 패치
  void _loadFullMembership() async {
    final activeClub = ref.read(activeClubProvider);
    final int? currentClubId = activeClub?.clubInfo?.id;

    if (currentClubId == null) {
      setState(() => _isLazyLoading = false);
      return;
    }

    // 🎯 [완치 가드]: 역직렬화 도중 타입 에러나 공백 크래시가 나더라도 무한 로딩에 빠지지 않도록 안전망 결합
    try {
      final result = await ApiService.getMyClubMembership(currentClubId);

      if (mounted && result['success'] == true && result['data'] != null) {
        final rawData = result['data'];
        final richSession = UserContextResponse.fromJson(rawData);
        ref.read(activeClubProvider.notifier).setClubSession(richSession);

        // 🎯 [명세 조준]: 확정한 루트 레벨의 'formSettings' 데이터를 다이렉트로 추적하여 안전하게 파싱합니다.
        final rawFormSettings = rawData['formSettings'];
        Map<String, dynamic> formSettingsMap = {};

        if (rawFormSettings is String && rawFormSettings.trim().isNotEmpty) {
          formSettingsMap = jsonDecode(rawFormSettings) as Map<String, dynamic>;
        } else if (rawFormSettings is Map<String, dynamic>) {
          formSettingsMap = rawFormSettings;
        }

        final List<dynamic> rawQuestions = formSettingsMap['questions'] ?? [];

        setState(() {
          _questionFormList = rawQuestions
              .map((jsonItem) => ClubApplicationForm.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e, stack) {
      debugPrint('❌ [치명적 에러] 프로필 가입 양식 데이터 파싱 중 실패: $e');
      debugPrint('🔎 상세 스택 트레이스:\n$stack');
      if (mounted) {
        _showSnackBar('가입 서류 서식을 가져오는 데 실패했습니다.', isError: true);
      }
    } finally {
      // 🚀 통신이 터지든 성공하든 무한 백레이어 로딩 인디케이터는 100% 강제 해제 종료합니다.
      if (mounted) {
        setState(() => _isLazyLoading = false);
      }
    }
  }

  // 운영진 전용 텔레그램 연동 및 실시간 스위치 설정 팝업
  void _showEditTelegramModal(UserContextResponse activeClub) {
    final formKey = GlobalKey<FormState>();
    final chatIdController = TextEditingController(text: activeClub.telegramChatId);
    bool localAlertEnabled = activeClub.isAlertEnabled;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('AI 보안 관제 알림 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI 에이전트가 게시판의 부적절한 글을 자동 감지하면 운영진 텔레그램으로 즉시 경고 메시지를 격발합니다.',
                          style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4)),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber[200]!, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.help_center_outlined, size: 16, color: Colors.amber[900]),
                                const SizedBox(width: 6),
                                Text('💡 내 텔레그램 Chat ID 확인 방법',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('1️⃣ 텔레그램 앱 검색창에 @userinfobot 을 검색합니다.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3)),
                            const SizedBox(height: 3),
                            Text('2️⃣ 봇 채팅방에 진입하여 [시작] 또는 /start 를 보냅니다.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3)),
                            const SizedBox(height: 3),
                            Text('3️⃣ 봇이 답장으로 보내주는 숫자 형태의 Id 값을 복사하여 아래에 입력하세요.',
                                style: TextStyle(fontSize: 11, color: Colors.grey[800], height: 1.3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: chatIdController,
                        decoration: const InputDecoration(
                          labelText: '텔레그램 Chat ID',
                          hintText: '숫자 ID를 입력하세요 (예: 12345678)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pin),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.trim().isEmpty ? '알림을 수신할 Chat ID를 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('실시간 보안 알림 수신', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: const Text('탐지 즉시 텔레그램 DM 송신', style: TextStyle(fontSize: 11)),
                        value: localAlertEnabled,
                        activeThumbColor: Colors.blueAccent,
                        onChanged: (bool value) {
                          setModalState(() {
                            localAlertEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      setState(() => _isProcessing = true);

                      final Map<String, dynamic> telegramPayload = {
                        'telegramChatId': chatIdController.text.trim(),
                        'isAlertEnabled': localAlertEnabled,
                      };

                      final result = await ApiService.updateTelegramSettings(
                        clubId: activeClub.clubInfo!.id!,
                        telegramData: telegramPayload,
                      );

                      if (mounted) {
                        setState(() => _isProcessing = false);
                      }

                      if (result['success'] == true) {
                        _showSnackBar('AI 관제 알림 설정이 반영되었습니다.');
                        _loadFullMembership();
                      } else {
                        _showSnackBar(result['message'] ?? '설정 저장 실패', isError: true);
                      }
                    }
                  },
                  child: const Text('설정 저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 동아리 고유 정보 수정 모달 팝업
  void _showEditClubInfoModal(UserContextResponse activeClub) {
    final formKey = GlobalKey<FormState>();
    final studentNoController = TextEditingController(text: activeClub.studentNo);
    final emailController = TextEditingController(text: activeClub.email);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('동아리 가입 정보 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: studentNoController,
                    decoration: const InputDecoration(labelText: '학번 변경', border: OutlineInputBorder()),
                    validator: (value) => value!.trim().isEmpty ? '학번을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '동아리 가입 이메일', border: OutlineInputBorder()),
                    validator: (value) => value!.trim().isEmpty ? '이메일을 입력해주세요.' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  setState(() => _isProcessing = true);

                  final Map<String, dynamic> updateData = {
                    'studentNo': studentNoController.text.trim(),
                    'email': emailController.text.trim(),
                  };

                  final result = await ApiService.updateMemberBasicInfo(
                    clubId: activeClub.clubInfo!.id!,
                    updateData: updateData,
                  );

                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }

                  if (result['success'] == true) {
                    _showSnackBar('동아리 가입 기본 정보가 수정되었습니다.');
                    _loadFullMembership();
                  } else {
                    _showSnackBar(result['message'] ?? '정보 수정에 실패했습니다.', isError: true);
                  }
                }
              },
              child: const Text('변경 저장'),
            ),
          ],
        );
      },
    );
  }

  void _downloadApplicationPdf(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.trim().isEmpty) {
      _showSnackBar('다운로드 가능한 서류 파일 경로가 존재하지 않습니다.', isError: true);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final String cleanPath = pdfUrl.startsWith('/') ? pdfUrl : '/$pdfUrl';
      final String fullPdfUrl = pdfUrl.startsWith('http') ? pdfUrl : '${ApiService.baseUrl}$cleanPath';

      final Uri uri = Uri.parse(fullPdfUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('내 입부원서 서류 다운로드 창으로 연동되었습니다.');
      } else {
        throw '원서 주소 호출 불가능: $fullPdfUrl';
      }
    } catch (e) {
      _showSnackBar('서류 다운로드 프로세스 오류: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLazyLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }

    final activeClub = ref.watch(activeClubProvider);
    if (activeClub == null) {
      return const Center(child: Text('사용자 권한 명세 오류'));
    }

    final String name = activeClub.realName ?? '익명';
    final String studentId = activeClub.studentNo ?? '학번 미등록';
    final String phone = activeClub.phoneNumber ?? '전화번호 미등록';
    final String email = activeClub.email ?? '이메일 미등록';

    String roleLabel = '동아리원';
    if (activeClub.clubRole == 'CLUBPRESIDENT') roleLabel = '회장';
    if (activeClub.clubRole == 'CLUBADMIN') roleLabel = '운영진';
    if (activeClub.clubRole == 'NONE') roleLabel = '비회원/방문자';

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Column(
                  children: [
                    _buildProfileCard(
                      name: name,
                      studentNum: studentId,
                      phone: phone,
                      roleLabel: roleLabel,
                      onEditTap: () => _showEditClubInfoModal(activeClub),
                    ),

                    if (activeClub.isManager) ...[
                      const SizedBox(height: 24),
                      _buildTelegramNotificationCard(activeClub),
                    ],

                    const SizedBox(height: 24),
                    _buildMembershipStatusBanner(activeClub.joinStatus),
                    const SizedBox(height: 24),
                    _buildApplicationArchiveCard(activeClub.submittedDoc, clubEmail: email),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTelegramNotificationCard(UserContextResponse activeClub) {
    final bool isLinked = activeClub.telegramChatId != null && activeClub.telegramChatId!.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isLinked ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.grey[300]!, width: 1.5),
      ),
      color: isLinked ? Colors.blue[50]!.withValues(alpha: 0.3) : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: isLinked ? Colors.blueAccent : Colors.grey),
                const SizedBox(width: 8),
                const Text('AI 보안 관제 시스템 제어 (운영진)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_suggest_outlined, color: Colors.blueAccent),
                  tooltip: '관제 정보 설정 변경',
                  onPressed: () => _showEditTelegramModal(activeClub),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('텔레그램 봇 연동 상태: ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLinked ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLinked ? '연동 완료 [ID: ${activeClub.telegramChatId}]' : '미연동 (관제 중단)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLinked ? Colors.green[800] : Colors.red[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('위반 게시글 실시간 관제: ', style: TextStyle(fontSize: 13, color: Colors.black54)),
                Text(
                  activeClub.isAlertEnabled && isLinked ? '🔔 실시간 알림 가동 중' : '🔕 알림 수신 꺼짐',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: activeClub.isAlertEnabled && isLinked ? Colors.blueAccent : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String studentNum,
    required String phone,
    required String roleLabel,
    required VoidCallback onEditTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.badge_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(12)),
                        child: Text(roleLabel, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('학번 명세: $studentNum', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('연락처: $phone', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note, color: Colors.blueGrey, size: 28),
              tooltip: '가입 정보 수정',
              onPressed: onEditTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipStatusBanner(String? joinStatus) {
    Color bannerColor;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    switch (joinStatus) {
      case 'APPROVED':
        bannerColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusTitle = '최종 가입 승인 완료';
        statusDesc = '동아리 정식 부원 승인이 완료되었습니다.';
        break;
      case 'PENDING':
        bannerColor = Colors.amber;
        statusIcon = Icons.hourglass_empty_rounded;
        statusTitle = '가입 서류 심사 대기 중';
        statusDesc = '제출하신 입부 서류를 동아리 운영진이 검토하고 있습니다. 잠시만 기다려 주세요.';
        break;
      case 'REJECTED':
        bannerColor = Colors.redAccent;
        statusIcon = Icons.error_outline_rounded;
        statusTitle = '가입 신청 반려됨';
        statusDesc = '동아리 가입 신청이 반려되었습니다. 상세 사유는 동아리 관리자에게 문의해 주세요.';
        break;
      default:
        bannerColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusTitle = '가입 기록 없음';
        statusDesc = '이 동아리의 가입 이력을 확인할 수 없는 게스트 상태입니다.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: bannerColor, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: bannerColor)),
                const SizedBox(height: 4),
                Text(statusDesc, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildApplicationArchiveCard(SubmittedDocResponse? doc, {required String clubEmail}) {
    if (doc == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('자유가입 동아리이거나 제출된 신청 서류 내역이 없습니다.', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final Map<String, dynamic> answers = doc.formAnswers;

    // 🎯 [완치 조준]: 원본 백엔드 확장자 명세인 '.docx'에 대응하여 UI 테마 속성 분기 처리
    final String fileUrl = doc.docPdfUrl ?? '';
    final bool isDocx = fileUrl.toLowerCase().endsWith('.docx');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_shared_outlined, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('내가 제출한 가입 신청 서류', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            _buildStaticDocRow('동아리에 등록된 이메일', clubEmail),
            const SizedBox(height: 16),

            // 🚀 매핑 수선 완료: 복원된 질문 템플릿의 고유 키를 기반으로 정렬 노출
            if (_questionFormList.isEmpty)
              const Text('가입 서류 문항 데이터 템플릿 정보가 부재합니다.', style: TextStyle(fontSize: 13, color: Colors.grey))
            else
              ..._questionFormList.map((q) {
                final String answerText = (answers[q.key] ?? '기재된 답변이 없습니다.').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildStaticDocRow(q.question, answerText),
                );
              }),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  // 🚀 확장자 상태에 따라 알맞은 아이콘으로 가변 전환
                  Icon(
                      isDocx ? Icons.description : Icons.picture_as_pdf,
                      color: isDocx ? Colors.blue[700] : Colors.redAccent,
                      size: 28
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isDocx ? '자동 치환된 정식 입부원서.docx' : '자동 치환된 정식 입부원서.pdf',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                        const SizedBox(height: 2),
                        Text(fileUrl.isNotEmpty ? '치환 원서 아카이브 경로 확보됨' : '증빙 파일 미생성 상태', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  _isDownloading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : IconButton(
                    icon: const Icon(Icons.file_download, color: Colors.blue),
                    tooltip: '원서 다운로드',
                    onPressed: () => _downloadApplicationPdf(doc.docPdfUrl),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStaticDocRow(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Text(content, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}