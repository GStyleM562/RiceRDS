// Generador de gráficos para Google Play (ícono 512, master 1024, gráfico de
// funciones 1024x500) con la estética del juego (terminal cian/verde).
// Ejecutar:  flutter test tool/gen_store_graphics.dart
// Salida en: nodehack_app/store_assets/
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const bg = Color(0xFF06080D);
const bg2 = Color(0xFF0B1018);
const cyan = Color(0xFF3FC7EC); // CORTAFUEGOS / firewall
const red = Color(0xFFFF4068); // EXPLOIT
const green = Color(0xFF26E6A4); // PULSO / signal
const purple = Color(0xFFB061FF); // NULL
const white = Color(0xFFEAF7FF);

Color a(Color c, double o) => c.withValues(alpha: o);

Path _hex(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final ang = (-90 + 60 * i) * pi / 180;
    final pt = Offset(c.dx + r * cos(ang), c.dy + r * sin(ang));
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

List<Offset> _hexVerts(Offset c, double r) =>
    [for (var i = 0; i < 6; i++) Offset(c.dx + r * cos((-90 + 60 * i) * pi / 180), c.dy + r * sin((-90 + 60 * i) * pi / 180))];

void _bgGrid(Canvas canvas, double w, double h, {double step = 28}) {
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [bg2, bg]));
  final g = Paint()
    ..color = a(cyan, .05)
    ..strokeWidth = 1;
  for (double x = 0; x < w; x += step) {
    canvas.drawLine(Offset(x, 0), Offset(x, h), g);
  }
  for (double y = 0; y < h; y += step) {
    canvas.drawLine(Offset(0, y), Offset(w, y), g);
  }
}

void _node(Canvas canvas, Offset o, double r, Color c) {
  canvas.drawCircle(o, r * 2.2, Paint()..color = a(c, .35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  canvas.drawCircle(o, r, Paint()..color = c);
  canvas.drawCircle(o, r * .45, Paint()..color = white);
}

void drawIcon(Canvas canvas, double s) {
  _bgGrid(canvas, s, s, step: s / 13);
  final c = Offset(s / 2, s / 2);

  // Vignette + aro exterior (como la familia Node Protocol).
  canvas.drawCircle(c, s * .46, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * .012
    ..color = a(cyan, .55)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

  final R = s * .33;
  // Hexágono externo (sígilo firewall) con glow.
  canvas.drawPath(_hex(c, R), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * .02
    ..strokeJoin = StrokeJoin.round
    ..color = cyan
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  // Hexágono interno + radios (web).
  canvas.drawPath(_hex(c, R * .58), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * .009
    ..color = a(cyan, .7));
  final verts = _hexVerts(c, R);
  final spoke = Paint()
    ..strokeWidth = s * .007
    ..color = a(cyan, .55);
  for (final v in verts) {
    canvas.drawLine(c, v, spoke);
  }
  // Nodos en los vértices con el ritmo de la tríada (cian/rojo/verde) + null.
  const triad = [cyan, red, green, cyan, purple, green];
  for (var i = 0; i < 6; i++) {
    _node(canvas, verts[i], s * .022, triad[i]);
  }
  // Núcleo central.
  _node(canvas, c, s * .05, cyan);

  // Línea de escaneo sutil.
  canvas.drawRect(Rect.fromLTWH(0, s * .5 - s * .004, s, s * .008), Paint()..color = a(cyan, .12));
}

Future<void> _save(String path, ui.Picture pic, int w, int h) async {
  final img = await pic.toImage(w, h);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(data!.buffer.asUint8List());
}

ui.Picture _record(void Function(Canvas) draw) {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  return rec.endRecording();
}

void _text(Canvas canvas, String s, double cx, double y, double size, Color color,
    {FontWeight w = FontWeight.w700, double spacing = 0, double glow = 0}) {
  final tp = TextPainter(
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: 'Gen',
        fontSize: size,
        height: 1,
        color: color,
        fontWeight: w,
        letterSpacing: spacing,
        shadows: glow > 0 ? [Shadow(color: a(color, .7), blurRadius: glow)] : null,
      ),
    ),
  )..layout();
  tp.paint(canvas, Offset(cx - tp.width / 2, y));
}

void drawFeature(Canvas canvas, double w, double h) {
  _bgGrid(canvas, w, h, step: 34);

  // Red de nodos (evita la banda central de texto).
  final rnd = Random(7);
  const cols = [cyan, red, green, purple, cyan, green, red, white];
  final pts = <Offset>[];
  for (var i = 0; i < 14; i++) {
    final x = 30 + rnd.nextDouble() * (w - 60);
    var y = 30 + rnd.nextDouble() * (h - 60);
    if (y > 150 && y < 360) y = y < 255 ? 110 : 400; // despeja el centro
    pts.add(Offset(x, y));
  }
  final link = Paint()
    ..strokeWidth = 1
    ..color = a(cyan, .18);
  for (var i = 0; i < pts.length; i++) {
    final j = (i + 3) % pts.length;
    canvas.drawLine(pts[i], pts[j], link);
  }
  for (var i = 0; i < pts.length; i++) {
    _node(canvas, pts[i], 6.5, cols[i % cols.length]);
  }

  // Líneas que enmarcan el texto.
  final bar = Paint()
    ..color = a(cyan, .55)
    ..strokeWidth = 2
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  canvas.drawLine(const Offset(60, 150), Offset(w - 60, 150), bar);
  canvas.drawLine(const Offset(60, 360), Offset(w - 60, 360), bar);

  final cx = w / 2;
  _text(canvas, 'NODEHACK', cx, 168, 88, white, spacing: 6, glow: 22);
  _text(canvas, ':: PROGRAM_NULL', cx, 262, 26, cyan, w: FontWeight.w700, spacing: 10, glow: 10);
  _text(canvas, 'Duelo 1v1  ·  piedra-papel-tijera táctico', cx, 300, 26, white, w: FontWeight.w400, spacing: 1);
  _text(canvas, 'CORTAFUEGOS   |   EXPLOIT   |   PULSO', cx, 334, 16, a(cyan, .85), w: FontWeight.w700, spacing: 3);
}

void main() {
  testWidgets('genera gráficos de tienda', (t) async {
    // Carga una fuente del sistema (flutter_test no trae glifos reales).
    String? fp;
    for (final p in [
      r'C:\Windows\Fonts\consolab.ttf',
      r'C:\Windows\Fonts\segoeuib.ttf',
      r'C:\Windows\Fonts\arialbd.ttf',
    ]) {
      if (File(p).existsSync()) {
        fp = p;
        break;
      }
    }
    final loader = FontLoader('Gen');
    loader.addFont(Future.value(File(fp!).readAsBytesSync().buffer.asByteData()));
    await loader.load();

    // toImage/toByteData son async del engine: deben correr en runAsync.
    await t.runAsync(() async {
      await _save('store_assets/icon_512.png', _record((c) => drawIcon(c, 512)), 512, 512);
      await _save('store_assets/icon_1024.png', _record((c) => drawIcon(c, 1024)), 1024, 1024);
      await _save('store_assets/feature_1024x500.png', _record((c) => drawFeature(c, 1024, 500)), 1024, 500);
    });

    expect(File('store_assets/icon_512.png').existsSync(), isTrue);
    expect(File('store_assets/feature_1024x500.png').existsSync(), isTrue);
  });
}
