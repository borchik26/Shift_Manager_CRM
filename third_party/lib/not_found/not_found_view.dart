import 'package:flutter/material.dart';
import 'package:my_app/core/ui/app_theme.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/not_found/not_found_view_model.dart';

class NotFoundView extends StatefulWidget {
  const NotFoundView({super.key});

  @override
  State<NotFoundView> createState() => _NotFoundViewState();
}

class _NotFoundViewState extends State<NotFoundView> {
  late final NotFoundViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotFoundViewModel(routerService: locator<RouterService>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '404',
                style: context.textStyles.xxxl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                'Page not found',
                style: context.textStyles.standard,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.xl),
              OutlinedButton(
                onPressed: _viewModel.navigateToHome,
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
