// lib/core/providers/club_dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_service.dart';
import '../../features/club/models/club_dashboard_response.dart';
import 'active_club_provider.dart';

// 🚀 [리버팟 고도화]: activeClub의 상태 변경에 기생하여 자동으로 최신 대시보드를 수급하는 미래형 프로바이더
final clubDashboardProvider = FutureProvider<ClubDashboardResponse?>((ref) async {
  final activeClub = ref.watch(activeClubProvider);
  final int? currentClubId = activeClub?.clubInfo?.id;

  // 현재 입장한 동아리가 없다면 비동기 버퍼에 null 반환
  if (currentClubId == null) return null;

  // ApiService 라인을 가동해 데이터 원격 아카이빙 후 리턴
  return await ApiService.getClubDashboard(currentClubId);
});