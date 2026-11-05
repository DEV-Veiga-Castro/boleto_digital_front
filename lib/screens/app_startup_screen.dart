import 'dart:io';

import 'package:boleto_digital/services/app_version_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  AppVersionPolicy? _policy;
  String? _installedVersion;
  String? _error;
  bool _checking = false;
  bool _blocked = false;
  bool _downloading = false;
  double? _downloadProgress;

  static const _installer = MethodChannel(
    'com.veigacastro.boleto_digital/apk_installer',
  );

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final result = await AppVersionService().checkVersion();
      if (!mounted) return;
      if (result.isBlocked) {
        setState(() {
          _policy = result.policy;
          _installedVersion = result.installedVersion;
          _blocked = true;
          _checking = false;
        });
        return;
      }
      Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Não foi possível verificar a versão. Confira sua conexão e tente novamente.';
        _checking = false;
      });
    }
  }

  Future<void> _openUpdate() async {
    if (_downloading) return;
    final isAndroid = Platform.isAndroid;
    final url = Uri.tryParse(
      isAndroid ? (_policy?.androidUrl ?? '') : (_policy?.iosUrl ?? ''),
    );
    if (url == null || !url.hasScheme) {
      _showMessage('Link de atualização indisponível para este dispositivo.');
      return;
    }

    if (!isAndroid) {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showMessage('Não foi possível abrir o link de atualização.');
      }
      return;
    }

    try {
      final canInstall = await _installer.invokeMethod<bool>('canInstallApk') ?? false;
      if (!canInstall) {
        await _installer.invokeMethod('openInstallPermissionSettings');
        _showMessage(
          'Autorize “Instalar apps desconhecidos” para o Boleto Digital e toque em Atualizar agora novamente.',
        );
        return;
      }

      setState(() {
        _downloading = true;
        _downloadProgress = null;
      });
      final request = http.Request('GET', url);
      final client = http.Client();
      try {
        final response = await client.send(request).timeout(
          const Duration(minutes: 3),
        );
        if (response.statusCode != 200) {
          throw Exception('Servidor retornou HTTP ${response.statusCode}.');
        }

        final directory = await getTemporaryDirectory();
        final apkDirectory = Directory('${directory.path}/apk_updates');
        await apkDirectory.create(recursive: true);
        final apkFile = File('${apkDirectory.path}/boleto-digital-update.apk');
        final sink = apkFile.openWrite();
        var received = 0;
        final total = response.contentLength;
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            received += chunk.length;
            if (mounted && total != null && total > 0) {
              setState(() => _downloadProgress = received / total);
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        await _installer.invokeMethod('installApk', {'path': apkFile.path});
      } finally {
        client.close();
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Falha ao baixar ou abrir a atualização: $error');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_blocked) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Atualização necessária',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _policy?.message ?? 'Atualize o aplicativo para continuar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versão instalada: ${_installedVersion ?? ""}  •  Mínima: ${_policy?.minimumVersion ?? ""}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _downloading ? null : _openUpdate,
                    icon: _downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _downloading
                          ? _downloadProgress == null
                                ? 'Baixando atualização...'
                                : 'Baixando ${(_downloadProgress! * 100).round()}%'
                          : 'Atualizar agora',
                    ),
                  ),
                  TextButton(
                    onPressed: _checking ? null : _checkVersion,
                    child: const Text('Já atualizei / Verificar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Verificando versão...',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _checkVersion,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
