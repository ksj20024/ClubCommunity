import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 500.0, // 웹/태블릿에서 콘텐츠가 보일 최대 너비
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
    }
    return child; // 모바일에서는 전체 화면 사용
  }
}