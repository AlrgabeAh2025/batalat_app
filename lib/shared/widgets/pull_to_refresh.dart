/// سحب للتحديث — يغلف المحتوى القابل للتمرير
import 'package:flutter/material.dart';

import 'package:batalat_app/core/theme/app_colors.dart';

class PullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  /// لفّ المحتوى غير القابل للتمرير (EmptyState / Center) ليسمح بالسحب.
  /// لا تستخدمه مع GridView/ListView — استخدم AlwaysScrollableScrollPhysics بدلًا منه.
  final bool alwaysScrollable;

  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.alwaysScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = alwaysScrollable
        ? LayoutBuilder(
            builder: (context, constraints) {
              // ارتفاع ثابت (ليس minHeight فقط) حتى لا ينكسر أي ScrollView داخلي
              final height = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: height,
                  width: constraints.maxWidth,
                  child: child,
                ),
              );
            },
          )
        : child;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: content,
    );
  }
}

/// انتظار إعادة الجلب بعد invalidate (يتجاهل الخطأ حتى يكتمل مؤشر السحب)
Future<void> awaitRefresh(Future<void> Function() load) async {
  try {
    await load();
  } catch (_) {}
}
