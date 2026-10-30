import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/routes.dart';
import '../../core/widgets/widgets.dart';
import 'trap_flow.dart';

enum _ScanState { scanning, validating, illegible, notFound }

/// S07 — Escanear trampa (cámara real). Estados: S07 normal, S07a QR ilegible, S07b no encontrada.
class ScanTrapScreen extends StatefulWidget {
  const ScanTrapScreen({super.key});

  @override
  State<ScanTrapScreen> createState() => _ScanTrapScreenState();
}

class _ScanTrapScreenState extends State<ScanTrapScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  _ScanState _state = _ScanState.scanning;
  String? _lastCode;
  bool _torchOn = false;
  Timer? _illegibleTimer;

  /// Si en este tiempo no se lee nada, se muestra la ayuda de "QR ilegible".
  static const _illegibleAfter = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _armIllegibleTimer();
  }

  @override
  void dispose() {
    _illegibleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _armIllegibleTimer() {
    _illegibleTimer?.cancel();
    _illegibleTimer = Timer(_illegibleAfter, () {
      if (mounted && _state == _ScanState.scanning) setState(() => _state = _ScanState.illegible);
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_state == _ScanState.validating || _state == _ScanState.notFound) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null || raw.trim().isEmpty) return;

    _illegibleTimer?.cancel();
    setState(() {
      _state = _ScanState.validating;
      _lastCode = raw.trim();
    });
    await _controller.stop();

    final lookup = await lookupTrap(_lastCode!);
    if (!mounted) return;
    if (lookup == null) {
      setState(() => _state = _ScanState.notFound);
    } else {
      openTrapIdentified(context, lookup, replace: true);
    }
  }

  Future<void> _retry() async {
    setState(() {
      _state = _ScanState.scanning;
      _lastCode = null;
    });
    await _controller.start();
    _armIllegibleTimer();
  }

  Color get _frameColor => switch (_state) {
        _ScanState.illegible => AppColors.warningStrong,
        _ScanState.notFound => AppColors.error,
        _ => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => const _CameraError(),
          ),
          // Marco de escaneo
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(painter: _CornersPainter(_frameColor)),
            ),
          ),
          Align(
            alignment: const Alignment(0, .42),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.overlayDark, borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
              child: const Text('Coloque el código QR de la trampa dentro del área',
                  style: AppText.onDarkBody),
            ),
          ),
          // Barra superior
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Atrás',
                    variant: AppIconButtonVariant.overlay,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Text('Escanear trampa',
                      style: AppText.onDarkTitle),
                  const Spacer(),
                  AppIconButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    tooltip: 'Linterna',
                    variant: AppIconButtonVariant.overlay,
                    onPressed: () async {
                      await _controller.toggleTorch();
                      if (mounted) setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Panel inferior
          Align(alignment: Alignment.bottomCenter, child: _bottomPanel()),
        ],
      ),
    );
  }

  Widget _bottomPanel() {
    final (AlertType type, String title, String msg) = switch (_state) {
      _ScanState.scanning => (
          AlertType.info,
          'El QR es una ayuda de captura',
          'La trampa se identifica con su código ICA oficial (ej. 54518-602-5).'
        ),
      _ScanState.validating => (AlertType.info, 'Validando código...', _lastCode ?? ''),
      _ScanState.illegible => (
          AlertType.warning,
          'QR ilegible',
          'No pudimos leer el código. Acerque la cámara o ingrese el código manualmente.'
        ),
      _ScanState.notFound => (
          AlertType.error,
          'Trampa no encontrada',
          'El código ${_lastCode ?? ''} no está en el catálogo descargado del predio. Ingrese la trampa manualmente; el dato no se descarta.'
        ),
    };

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlertBanner(type: type, title: title, message: msg),
              const SizedBox(height: 14),
              if (_state == _ScanState.validating)
                const PrimaryButton(label: 'Validando...', isLoading: true, onPressed: null)
              else if (_state == _ScanState.scanning)
                SecondaryButton(
                  label: 'Ingresar código ICA',
                  icon: Icons.tag,
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.identifyTrap),
                )
              else ...[
                PrimaryButton(label: 'Reintentar escaneo', onPressed: _retry),
                const SizedBox(height: 10),
                SecondaryButton(
                  label: 'Ingresar código ICA',
                  icon: Icons.tag,
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.identifyTrap, arguments: _lastCode),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                'No se pudo abrir la cámara',
                style: AppText.onDarkTitle,
              ),
              SizedBox(height: 4),
              Text(
                'Revise el permiso de cámara en los ajustes del dispositivo.',
                textAlign: TextAlign.center,
                style: AppText.onDarkMuted,
              ),
            ],
          ),
        ),
      );
}

/// Esquinas del marco del escáner.
class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, l)
      ..lineTo(0, 0)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w, 0)
      ..lineTo(w, l)
      ..moveTo(w, h - l)
      ..lineTo(w, h)
      ..lineTo(w - l, h)
      ..moveTo(l, h)
      ..lineTo(0, h)
      ..lineTo(0, h - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) => old.color != color;
}