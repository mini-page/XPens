import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import 'accounts/tools_tab_widgets.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Tools', style: AppTextStyles.sectionHeading),
                  const SizedBox(height: 2),
                  const Text(
                    'Your financial utilities',
                    style: AppTextStyles.sectionSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const ToolsTabBar(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: const ToolsTabView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
