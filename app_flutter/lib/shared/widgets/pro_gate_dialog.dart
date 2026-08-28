import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/pro_service.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// PRO GATE DIALOG + UPGRADE PAGE
// ═══════════════════════════════════════════════════════════════

class ProGate {
  /// Mostra dialog bloqueando feature Pro
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _ProGateDialog(),
    );
  }
}

class _ProGateDialog extends StatefulWidget {
  const _ProGateDialog();

  @override
  State<_ProGateDialog> createState() => _ProGateDialogState();
}

class _ProGateDialogState extends State<_ProGateDialog> {
  bool _redeeming = false;
  final _tokenController = TextEditingController();
  String? _tokenMessage;
  bool _tokenSuccess = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _redeemToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;

    setState(() {
      _redeeming = true;
      _tokenMessage = null;
      _tokenSuccess = false;
    });

    final result = await ProService.redeemProToken(token);

    if (mounted) {
      setState(() => _redeeming = false);
      if (result == 'success') {
        setState(() {
          _tokenSuccess = true;
          _tokenMessage = 'Pro ativado com sucesso! Feche e reabra esta tela.';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        setState(() => _tokenMessage = result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 48, color: AppTheme.accent),
              const SizedBox(height: 16),
              Text(
                'Recurso Pro',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Este recurso faz parte do plano Pro e inclui prescrição inteligente, progressão automática, analytics avançado e rotação semanal de exercícios.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // Lista de features Pro
              _featureRow(Icons.settings_suggest_outlined, 'Prescrição inteligente com DUP'),
              _featureRow(Icons.trending_up_outlined, 'Progressão automática por RIR'),
              _featureRow(Icons.bar_chart_outlined, 'Analytics avançado com gráficos'),
              _featureRow(Icons.auto_awesome, 'Rotação semanal de exercícios'),
              _featureRow(Icons.emoji_events_outlined, 'Sistema de recordes pessoais'),
              _featureRow(Icons.local_hospital_outlined, 'Deload automático'),
              const SizedBox(height: 24),

              // Seção: Resgatar token
              const Divider(color: Color(0xFF333344)),
              const SizedBox(height: 8),
              Text(
                'Código de ativação Pro',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: BETA2026',
                        border: OutlineInputBorder(),
                        fillColor: AppTheme.surfaceHighlight,
                        filled: true,
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _redeemToken(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _redeeming
                      ? const SizedBox(
                          width: 40, height: 40,
                          child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
                        )
                      : IconButton.filled(
                          onPressed: _redeemToken,
                          icon: const Icon(Icons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
              if (_tokenMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _tokenSuccess ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: _tokenSuccess ? AppTheme.success : AppTheme.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _tokenMessage!,
                        style: TextStyle(
                          color: _tokenSuccess ? AppTheme.success : AppTheme.danger,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Agora não', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
        ),
      ).animate().fade(duration: const Duration(milliseconds: 300)).scale(),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
