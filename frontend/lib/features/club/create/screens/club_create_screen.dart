// lib/features/club/screens/club_create_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 추가
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/club_creation_provider.dart'; // 💡 추가

class ClubCreateScreen extends ConsumerStatefulWidget {
  const ClubCreateScreen({super.key});

  @override
  ConsumerState<ClubCreateScreen> createState() => _ClubCreateScreenState();
}

class _ClubCreateScreenState extends ConsumerState<ClubCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clubNameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _domainController = TextEditingController();
  final _clubPasswordController = TextEditingController();

  String _selectedClubType = 'GENERAL';
  final Set<String> _selectedJoinTypes = {'FREE'};
  bool _useAutoDoc = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _clubNameController.dispose();
    _schoolNameController.dispose();
    _studentNoController.dispose();
    _domainController.dispose();
    _clubPasswordController.dispose();
    super.dispose();
  }

  void _handleJoinTypeChange(String type, bool checked) {
    setState(() {
      if (type == 'FREE') {
        if (checked) {
          _selectedJoinTypes.clear();
          _selectedJoinTypes.add('FREE');
        }
      } else {
        if (checked) {
          _selectedJoinTypes.remove('FREE');
          _selectedJoinTypes.add(type);
        } else {
          _selectedJoinTypes.remove(type);
          if (_selectedJoinTypes.isEmpty) {
            _selectedJoinTypes.add('FREE');
          }
        }
      }
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      Map<String, dynamic> clubPayload = {
        'clubName': _clubNameController.text.trim(),
        'clubType': _selectedClubType,
        'useAutoCreateApplicationDoc': _useAutoDoc,
        'joinType': _selectedJoinTypes.toList(),
        'schoolName': _selectedClubType == 'SCHOOL' ? _schoolNameController.text.trim() : null,
        'studentNo': _selectedClubType == 'SCHOOL' ? _studentNoController.text.trim() : null,
        'domainRestriction': _selectedJoinTypes.contains('EMAIL') ? _domainController.text.trim() : null,
        'clubPassword': _selectedJoinTypes.contains('CODE') ? _clubPasswordController.text.trim() : null,
      };

      final result = await ApiService.createClub(clubPayload);
      setState(() => _isProcessing = false);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message']), backgroundColor: Colors.blueAccent),
          );

          // 🎯 [핵심 패치]: 컴파일 호환성을 위해 num 파싱 후 임시 창고에 개설 데이터 기록
          final int clubId = (result['data'] as num).toInt();
          ref.read(clubCreationProvider.notifier).setCreationState(
            ClubCreationState(
              clubId: clubId,
              useAutoDoc: _useAutoDoc,
            ),
          );

          // 🚀 데이터 가방(arguments) 완전히 삭제! 몸만 깔끔하게 이동합니다.
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/club/form-setting',
                (route) => false,
          );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('새로운 동아리 개설 신청', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 650),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('동아리 이름'),
                      TextFormField(
                        controller: _clubNameController,
                        decoration: const InputDecoration(hintText: '개설할 동아리의 이름을 정확히 작성해 주세요.', border: OutlineInputBorder(), prefixIcon: Icon(Icons.edit_note)),
                        validator: (value) => value == null || value.trim().isEmpty ? '동아리 이름은 필수 입력 항목입니다.' : null,
                      ),
                      const SizedBox(height: 28),
                      _buildSectionTitle('동아리 소속 설정'),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'GENERAL', label: Text('일반 동아리'), icon: Icon(Icons.public)),
                            ButtonSegment(value: 'SCHOOL', label: Text('교내 동아리'), icon: Icon(Icons.school)),
                            ButtonSegment(value: 'UNION', label: Text('연합 동아리'), icon: Icon(Icons.diversity_3)),
                          ],
                          selected: {_selectedClubType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedClubType = newSelection.first;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedClubType == 'SCHOOL') ...[
                        Card(
                          color: Colors.blue[50],
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _schoolNameController,
                                  decoration: const InputDecoration(
                                      labelText: '소속 학교명',
                                      hintText: '예: 인하공업전문대학',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white
                                  ),
                                  validator: (value) => _selectedClubType == 'SCHOOL' && (value == null || value.trim().isEmpty) ? '학교 소속 동아리는 학교명 입력이 필수입니다.' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _studentNoController,
                                  decoration: const InputDecoration(
                                      labelText: '대표자(본인) 학번',
                                      hintText: '동아리 회장 본인의 학번을 입력해 주세요.',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Colors.white
                                  ),
                                  validator: (value) => _selectedClubType == 'SCHOOL' && (value == null || value.trim().isEmpty) ? '학교 소속 동아리는 대표의 학번 입력이 필수입니다.' : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionTitle('동아리 입부 가입 방식 설정 (중복 가능)'),
                      Card(
                        elevation: 1,
                        child: Column(
                          children: [
                            _buildCheckboxTile('자유 가입 (별도 조건 없음)', 'FREE'),
                            _buildCheckboxTile('특정 이메일 도메인 제한', 'EMAIL'),
                            _buildCheckboxTile('입부 비밀번호 입력 필수', 'CODE'),
                            _buildCheckboxTile('동아리 관리자 승인', 'APPROVAL'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedJoinTypes.contains('EMAIL')) ...[
                        TextFormField(
                          controller: _domainController,
                          decoration: const InputDecoration(labelText: '가입을 허용할 이메일 도메인 계정', hintText: '예: inhatc.ac.kr (@ 제외 입력)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.alternate_email)),
                          validator: (value) => _selectedJoinTypes.contains('EMAIL') && (value == null || value.trim().isEmpty) ? '이메일 제한 선택 시 도메인 주소 입력은 필수입니다.' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_selectedJoinTypes.contains('CODE')) ...[
                        TextFormField(
                          controller: _clubPasswordController,
                          decoration: const InputDecoration(labelText: '동아리 전용 가입 비밀번호', hintText: '부원들에게 공유할 가입 코드를 설정하세요.', border: OutlineInputBorder(), prefixIcon: Icon(Icons.vpn_key_outlined)),
                          validator: (value) => _selectedJoinTypes.contains('CODE') && (value == null || value.trim().isEmpty) ? '코드 가입 선택 시 비밀번호 설정은 필수입니다.' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        child: SwitchListTile(
                          title: const Text('신청서 양식 자동 생성 시스템 사용', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('동아리 가입 양식 설정 및 동아리 가입 문서 자동 생성을 활성화합니다.'),
                          value: _useAutoDoc,
                          onChanged: (bool value) => setState(() => _useAutoDoc = value),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('동아리 개설 완료 및 회장 등록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(bottom: 10.0, top: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCheckboxTile(String title, String type) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      value: _selectedJoinTypes.contains(type),
      onChanged: (bool? checked) => _handleJoinTypeChange(type, checked ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}