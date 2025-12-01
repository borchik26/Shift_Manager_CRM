import 'package:flutter/widgets.dart';
import 'package:my_app/core/utils/navigation/route_information_parser.dart';
import 'package:my_app/core/utils/navigation/router_delegate.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';

class BestRouterConfig extends RouterConfig<Object> {
  BestRouterConfig({required RouterService routerService})
    : super(
        routerDelegate: AppRouterDelegate(routerService: routerService),
        routeInformationProvider: PlatformRouteInformationProvider(
          initialRouteInformation: RouteInformation(
            uri: Uri.parse(
              routerService.navigationStack.value.last.uri.toString(),
            ),
          ),
        ),
        backButtonDispatcher: RootBackButtonDispatcher(),
        routeInformationParser: AppRouteInformationParser(
          routes: routerService.supportedRoutes,
        ),
      );
}
