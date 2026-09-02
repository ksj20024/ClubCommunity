// lib/features/club_workspace/widgets/club_manage_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_service.dart';
import '../../../core/providers/active_club_provider.dart';

class ClubManageView extends ConsumerStatefulWidget {
  const ClubManageView({super.key});

  @override
  ConsumerState<ClubManageView> createState() => _ClubManageViewState();
}

class _ClubManageViewState extends ConsumerState<ClubManageView> {
  bool _isInitialLoading = true;
  bool _isProcessing = false;

  List<dynamic> _pendingApplicants = [];
  List<dynamic> _activeMembers = [];

  @override
  void initState() {
    super.initState();
    _loadManagementData();
  }

  // 🔄 백엔드 데이터 동시 수급 동기화 파이프라인
  Future<void> _loadManagementData() async {
    final activeClub = ref.read(activeClubProvider);
    final int? clubId = activeClub?.clubInfo?.id;

    if (clubId == null) {
      setState(() => _isInitialLoading = false);
      return;
    }

    setState(() => _isInitialLoading = true);

    // print('🚀 [ClubManageView] 백엔드 API 호출 격발 시작 (clubId: $clubId)');
    final results = await Future.wait([
      ApiService.getPendingJoin(clubId),
      ApiService.getClubMembers(clubId),
    ]);

    final applicantResult = results[0];
    final memberResult = results[1];

    if (mounted) {
      setState(() {
        if (applicantResult['success'] == true) {
          _pendingApplicants = applicantResult['data'] ?? [];
        }
        if (memberResult['success'] == true) {
          _activeMembers = memberResult['data'] ?? [];
        }
        _isInitialLoading = false;
      });
    }
  }

  // 가입 승인 격발 처리
  void _handleApprove(int applicantId, String name) async {
    final activeClub = ref.read(activeClubProvider);
    final int? clubId = activeClub?.clubInfo?.id;
    if (clubId == null) return;

    setState(() => _isProcessing = true);
    final result = await ApiService.approveJoin(clubId: clubId, joinId: applicantId);
    setState(() => _isProcessing = false);

    if (result['success'] == true) {
      _showSnackBar('$name 님의 가입 신청을 정식 승인했습니다.', isError: false);
      _loadManagementData();
    } else {
      _showSnackBar(result['message'] ?? '승인 처리 중 오류 발생', isError: true);
    }
  }

  // 신청 반려 및 기존 부원 방출 통합 처리 다이얼로그
  void _handleRejectOrKick(int targetId, String name, bool isKick) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isKick ? '부원 강제 탈퇴 처리' : '가입 신청 서류 반려', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('정말로 $name 님을 ${isKick ? '동아리에서 강퇴 방출' : '가입 반려'}하시겠습니까?\n이 작업은 즉시 서버 데이터베이스에 영구 반영됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final activeClub = ref.read(activeClubProvider);
              final int? clubId = activeClub?.clubInfo?.id;
              if (clubId == null) return;

              Navigator.pop(context); // 모달 먼저 닫기
              setState(() => _isProcessing = true);

              Map<String, dynamic> result;
              if (isKick) {
                result = await ApiService.kickMember(clubId: clubId, memberId: targetId);
              } else {
                result = await ApiService.rejectJoin(clubId: clubId, joinId: targetId);
              }

              setState(() => _isProcessing = false);

              if (result['success'] == true) {
                _showSnackBar('$name 님의 정보 처리가 완료되었습니다.', isError: false);
                _loadManagementData();
              } else {
                _showSnackBar(result['message'] ?? '처리 중 오류 발생', isError: true);
              }
            },
            child: const Text('처분 확정'),
          ),
        ],
      ),
    );
  }

  // 🎯 가입 신청 대기자의 주관식 답변(formAnswers)을 시각화하는 상세 프로필 모달 창
  void _showApplicantDetailModal(Map<String, dynamic> applicant) {
    final String name = applicant['userName'] ?? '미기재';
    final String studentId = applicant['studentNo'] ?? '학번 없음';
    final String email = applicant['email'] ?? '이메일 미등록';
    final int appId = applicant['id'] ?? 0;

    final String rawDate = applicant['appliedAt']?.toString() ?? '';
    final String date = rawDate.length >= 16 ? rawDate.substring(0, 16).replaceAll('T', ' ') : rawDate;

    // 💡 백엔드 DTO 명세: Map<String, Object> formAnswers 파싱 추출
    final Map<String, dynamic> answers = applicant['formAnswers'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 바
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text('$name 님의 입부 원서 상세', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              // 알맹이 기본 정보 요약 구역
              Padding(
                padding: const EdgeInsets.all(20.0),
                // 🎯 [교정 완료]: 잘못 들어갔던 중복 오타 행을 완벽하게 제거했습니다.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow('신청자 학번', studentId),
                    _buildMetaRow('소통 이메일', email),
                    _buildMetaRow('원서 접수일', date),
                    const SizedBox(height: 12),
                    const Divider(thickness: 1.2),
                    const SizedBox(height: 8),
                    const Text('📄 작성한 동아리 폼 질문 답변지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                  ],
                ),
              ),
              // 동적 가입 폼 답변 리스트 스크롤 영역
              Expanded(
                child: answers.isEmpty
                    ? const Center(child: Text('제출된 서술형 가입 질문 답변 양식이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: answers.keys.length,
                  itemBuilder: (context, idx) {
                    final String key = answers.keys.elementAt(idx);
                    final String val = answers[key]?.toString() ?? '내용 없음';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• 매핑 식별키 [$key]', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
                            child: Text(val, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // 하단 액션 결정 제어바 구역
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기', style: TextStyle(color: Colors.grey))),
                    const Spacer(),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleRejectOrKick(appId, name, false);
                      },
                      child: const Text('가입 반려'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleApprove(appId, name);
                      },
                      child: const Text('즉시 승인'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blueAccent)));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: AppBar(
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_add_outlined, size: 18), SizedBox(width: 8), Text('신입 신청 명부')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_outlined, size: 18), SizedBox(width: 8), Text('정식 소속 부원')])),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildApplicantTab(),
                _buildMemberTab(),
              ],
            ),
            if (_isProcessing) const ColoredBox(color: Colors.black12, child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  // 📝 탭 컴포넌트 1: 신입 가입 신청 요약 피드 목록
  Widget _buildApplicantTab() {
    if (_pendingApplicants.isEmpty) {
      return const Center(child: Text('현재 대기 중인 신입 가입 신청서가 없습니다.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadManagementData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingApplicants.length,
        itemBuilder: (context, index) {
          final applicant = _pendingApplicants[index];

          // 🎯 백엔드 가입 신청 대기자 목록 DTO 명세 매핑 완료
          final int appId = applicant['id'] ?? 0;
          final String name = applicant['userName'] ?? '미기재';
          final String studentId = applicant['studentNo'] ?? '학번 정보 없음';

          final String rawDate = applicant['appliedAt']?.toString() ?? '';
          final String date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[100]!)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.assignment_outlined, color: Colors.white, size: 20)),
              title: Text('$name ($studentId)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('접수 시각: $date • 주관식 답변 포함', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () => _showApplicantDetailModal(applicant),
            ),
          );
        },
      ),
    );
  }

  // 📝 탭 컴포넌트 2: 정식 소속 부원 인덱스 관리 목록
  Widget _buildMemberTab() {
    final currentClubUser = ref.watch(activeClubProvider);

    if (_activeMembers.isEmpty) {
      return const Center(child: Text('동아리에 소속된 부원이 존재하지 않습니다.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadManagementData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeMembers.length,
        itemBuilder: (context, index) {
          final member = _activeMembers[index];

          // 🎯 백엔드 MemberListResponse DTO 명세 전면 매핑 동기화
          final int clubMemberId = member['clubMemberId'] ?? 0;
          final int userId = member['userId'] ?? 0;
          final String realName = member['realName'] ?? '익명 부원';
          final String studentNo = member['studentNo'] ?? '학번 미등록';
          final String email = member['email'] ?? '이메일 주소 정보 없음';
          final String clubRole = member['clubRole'] ?? 'MEMBER';

          final bool isMe = userId == currentClubUser?.uid;

          String roleLabel = '일반부원';
          Color badgeColor = Colors.grey;
          if (clubRole == 'CLUBPRESIDENT') { roleLabel = '회장'; badgeColor = Colors.redAccent; }
          if (clubRole == 'CLUBADMIN') { roleLabel = '운영진'; badgeColor = Colors.blueAccent; }

          return Card(
            elevation: 0.5,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: isMe ? Colors.blueAccent : Colors.blueGrey[50],
                child: Text(realName.substring(0, 1), style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              ),
              title: Row(
                children: [
                  Text(realName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                        isMe ? '$roleLabel(나)' : roleLabel,
                        style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('학번: $studentNo • 연락망: $email', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              trailing: isMe || clubRole == 'CLUBPRESIDENT'
                  ? null
                  : IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: Colors.grey, size: 20),
                tooltip: '부원 추방',
                onPressed: () => _handleRejectOrKick(clubMemberId, realName, true),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.blueAccent),
    );
  }
}