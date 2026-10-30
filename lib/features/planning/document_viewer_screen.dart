import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/planning.dart';
import '../../data/pdf_service.dart';
import '../../shared/shared.dart';

/// Visor del documento de instrucciones. Muestra lo que REALMENTE hay:
///
///  * PDF elegido en el dispositivo → sus páginas reales, dibujadas con
///    `Printing.raster`.
///  * Imagen elegida en el dispositivo → la imagen, con zoom.
///  * Word → la app no puede dibujarlo; lo dice y no ofrece descarga.
///  * Sin archivo en el dispositivo (el servidor aún no entrega el archivo) →
///    una REPRESENTACIÓN con los datos de la planificación, rotulada como tal.
class DocumentViewerScreen extends StatefulWidget {
  const DocumentViewerScreen({super.key, required this.planning});
  final Planning planning;

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

enum _Modo { pdfReal, imagen, word, representacion }

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int _page = 1;
  double _zoom = 1;
  bool _downloading = false;

  /// Páginas del PDF real ya dibujadas (PNG).
  final List<Uint8List> _paginas = [];
  bool _rendering = false;
  bool _renderFailed = false;

  PlanningDoc? get _doc => widget.planning.doc;

  _Modo get _modo {
    final d = _doc;
    if (d == null || !d.hasLocalFile) return _Modo.representacion;
    return switch (d.kind) {
      DocKind.pdf => _Modo.pdfReal,
      DocKind.imagen => _Modo.imagen,
      DocKind.word => _Modo.word,
    };
  }

  int get _pages => switch (_modo) {
        _Modo.pdfReal => _paginas.isEmpty ? 1 : _paginas.length,
        _Modo.imagen || _Modo.word => 1,
        _Modo.representacion => _doc?.pages ?? 1,
      };

  bool get _canDownload => PdfService.instance.canDownloadInstructions(widget.planning);

  @override
  void initState() {
    super.initState();
    if (_modo == _Modo.pdfReal) _renderPdf(_doc!.bytes!);
  }

  Future<void> _renderPdf(Uint8List bytes) async {
    setState(() => _rendering = true);
    try {
      await for (final pagina in Printing.raster(bytes, dpi: 110)) {
        final png = await pagina.toPng();
        if (!mounted) return;
        setState(() => _paginas.add(png)); // aparecen a medida que se dibujan
      }
    } catch (_) {
      if (mounted) setState(() => _renderFailed = true);
    } finally {
      if (mounted) setState(() => _rendering = false);
    }
  }

  Future<void> _download() async {
    if (_downloading || !_canDownload) return;
    setState(() => _downloading = true);
    try {
      await PdfService.instance.downloadInstructions(widget.planning);
    } catch (e) {
      if (mounted) {
        AppMessenger.error('No se pudo preparar el documento', message: 'Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    final multipagina = _pages > 1;
    final conZoom = _modo != _Modo.word;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimpleAppBar(
        title: 'Documento',
        actions: [
          if (_canDownload)
            AppIconButton(
              icon: Icons.download_outlined,
              tooltip: 'Descargar o compartir',
              onPressed: _downloading ? null : _download,
            ),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            if (doc != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.sm),
                child: DocumentCard(doc: doc),
              ),

            // --- Hoja del documento ---
            Expanded(
              child: Container(
                color: const Color(0xFF2B2B2B),
                width: double.infinity,
                child: _hoja(),
              ),
            ),

            // --- Controles del visor ---
            if (multipagina || conZoom)
              Container(
                color: const Color(0xFF1F1F1F),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (multipagina) ...[
                      AppIconButton(
                        icon: Icons.chevron_left,
                        tooltip: 'Página anterior',
                        color: Colors.white,
                        onPressed: _page > 1 ? () => setState(() => _page--) : null,
                      ),
                      Text('$_page / $_pages', style: AppText.onDarkBody),
                      AppIconButton(
                        icon: Icons.chevron_right,
                        tooltip: 'Página siguiente',
                        color: Colors.white,
                        onPressed: _page < _pages ? () => setState(() => _page++) : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    if (conZoom) ...[
                      AppIconButton(
                        icon: Icons.remove,
                        tooltip: 'Alejar',
                        color: Colors.white,
                        onPressed: _zoom > .6 ? () => setState(() => _zoom -= .2) : null,
                      ),
                      Text('${(_zoom * 100).round()} %', style: AppText.onDarkBody),
                      AppIconButton(
                        icon: Icons.add,
                        tooltip: 'Acercar',
                        color: Colors.white,
                        onPressed: _zoom < 1 ? () => setState(() => _zoom += .2) : null,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        if (_canDownload)
          PrimaryButton(
            label: _modo == _Modo.imagen ? 'Descargar como PDF' : 'Descargar documento',
            icon: Icons.download_outlined,
            isLoading: _downloading,
            loadingLabel: 'Preparando...',
            color: AppColors.primaryDark,
            onPressed: _download,
          ),
        SecondaryButton(label: 'Cerrar documento', onPressed: () => Navigator.of(context).pop()),
      ]),
    );
  }

  /// Contenido de la zona oscura según lo que haya realmente.
  Widget _hoja() {
    Widget pagina(Widget child) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: _zoom.clamp(.6, 1.0),
              child: child,
            ),
          ),
        );

    switch (_modo) {
      case _Modo.pdfReal:
        if (_renderFailed && _paginas.isEmpty) {
          return _avisoOscuro(
            Icons.error_outline,
            'No se pudo mostrar este PDF',
            'Puede estar protegido o dañado. Puedes descargarlo y abrirlo con otra aplicación.',
          );
        }
        if (_paginas.length < _page) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: AppSpacing.md),
                Text(_rendering ? 'Preparando la página $_page…' : 'Sin páginas',
                    style: AppText.onDarkMuted),
              ],
            ),
          );
        }
        return pagina(Container(
          decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.raised),
          child: Image.memory(_paginas[_page - 1], fit: BoxFit.contain, gaplessPlayback: true),
        ));

      case _Modo.imagen:
        return pagina(Image.memory(_doc!.bytes!, fit: BoxFit.contain));

      case _Modo.word:
        return _avisoOscuro(
          Icons.description_outlined,
          'Vista previa no disponible',
          'La app no puede mostrar documentos de Word. Cuando el servidor guarde el '
              'archivo, se podrá abrir con la aplicación de documentos del teléfono.',
        );

      case _Modo.representacion:
        return pagina(_DocumentPage(planning: widget.planning, page: _page, pages: _pages));
    }
  }

  Widget _avisoOscuro(IconData icono, String titulo, String mensaje) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 48, color: Colors.white70),
              const SizedBox(height: AppSpacing.md),
              Text(titulo, style: AppText.onDarkTitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(mensaje, style: AppText.onDarkMuted, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

/// Hoja del documento, con la identidad de la app.
class _DocumentPage extends StatelessWidget {
  const _DocumentPage({required this.planning, required this.page, required this.pages});

  final Planning planning;
  final int page;
  final int pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: AppShadows.raised),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandLogo(size: 60)),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              color: AppColors.primaryDark,
              child: Text(
                'INSTRUCCIONES',
                textAlign: TextAlign.center,
                style: AppText.h3.copyWith(color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(planning.activity, textAlign: TextAlign.center, style: AppText.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${planning.target.label} · ${Fmt.date(planning.startDate)}',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          if (page == 1) ...[
            const Text('OBSERVACIONES DEL AGRÓNOMO', style: AppText.overline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              planning.observations?.isNotEmpty == true
                  ? planning.observations!
                  : 'Sin observaciones registradas.',
              style: AppText.bodySm,
            ),
            if (planning.lotNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text('LOTES INCLUIDOS', style: AppText.overline),
              const SizedBox(height: AppSpacing.sm),
              Text(planning.lotNames.join(' · '), style: AppText.bodySm),
            ],
          ] else ...[
            Text('Página $page de $pages', style: AppText.secondary),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'El contenido completo del documento estará disponible cuando el '
              'servidor entregue el archivo cargado por el agrónomo.',
              style: AppText.bodySm,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            color: AppColors.surface,
            child: Text(
              'Representación generada por la app · no es el archivo original · ${Fmt.date(planning.createdAt)}',
              textAlign: TextAlign.center,
              style: AppText.micro,
            ),
          ),
        ],
      ),
    );
  }
}
