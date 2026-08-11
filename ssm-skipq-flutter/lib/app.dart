import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/app_services.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/ordering_window_provider.dart';
import 'router/app_router.dart';

class SkipQApp extends StatefulWidget {
  const SkipQApp({super.key, required this.services});

  final AppServices services;

  @override
  State<SkipQApp> createState() => _SkipQAppState();
}

class _SkipQAppState extends State<SkipQApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(
      apiClient: widget.services.apiClient,
      authService: widget.services.authService,
      socketService: widget.services.socketService,
    );
    _router = createRouter(widget.services, _authProvider);
    _authProvider.bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) => OrderingWindowProvider(
            settingsService: widget.services.settingsService,
            socketService: widget.services.socketService,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'SkipQ@SSM',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
