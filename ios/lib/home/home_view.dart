import 'package:flutter/material.dart';
import 'package:my_app/core/ui/app_theme.dart';
import 'package:my_app/core/utils/internal_notification/notify_service.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/home/home_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel = HomeViewModel(
    notifyService: locator<NotifyService>(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MVVM Counter')),
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: _viewModel.counter,
          builder: (context, count, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Counter',
                  textAlign: TextAlign.center,
                  style: context.textStyles.standard,
                ),
                Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: context.textStyles.xxxl,
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _viewModel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
