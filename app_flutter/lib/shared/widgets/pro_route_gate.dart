import 'package:flutter/material.dart';
import '../../core/services/pro_service.dart';
import '../../shared/theme/app_theme.dart';
import 'pro_gate_dialog.dart';

class ProRouteGate extends StatefulWidget {
  final String feature;
  final Widget child;

  const ProRouteGate({required this.feature, required this.child, super.key});

  @override
  State<ProRouteGate> createState() => _ProRouteGateState();
}

class _ProRouteGateState extends State<ProRouteGate> {
  late Future<bool> _access;

  @override
  void initState() {
    super.initState();
    _access = ProService.canAccess(widget.feature);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _access,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          );
        }
        if (snapshot.data == true) return widget.child;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium, color: AppTheme.accent, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Este recurso faz parte do BuildFit Pro.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ProGate.show(context),
                    child: const Text('Inserir código Pro'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
