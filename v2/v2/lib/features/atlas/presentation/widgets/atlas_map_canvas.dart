import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jw_study_v2/features/atlas/domain/models/atlas_models.dart';

const double _atlasMinLat = 20;
const double _atlasMaxLat = 42;
const double _atlasMinLng = 29;
const double _atlasMaxLng = 46;

class AtlasMapCanvas extends StatelessWidget {
  final List<AtlasItem> items;
  final int? selectedItemId;
  final AtlasMapData? editingMapData;
  final AtlasItemType? editingItemType;
  final ValueChanged<AtlasMapData>? onEditingMapDataChanged;

  const AtlasMapCanvas({
    super.key,
    required this.items,
    this.selectedItemId,
    this.editingMapData,
    this.editingItemType,
    this.onEditingMapDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onTapUp: onEditingMapDataChanged == null || editingItemType == null
              ? null
              : (details) {
                  final coordinate = _offsetToCoordinate(details.localPosition, size);
                  final currentMapData =
                      editingMapData ?? AtlasMapData.empty(editingItemType!.defaultShapeType);
                  switch (currentMapData.type) {
                    case AtlasMapShapeType.point:
                      onEditingMapDataChanged!(
                        AtlasMapData(
                          type: AtlasMapShapeType.point,
                          points: [coordinate],
                        ),
                      );
                    case AtlasMapShapeType.polygon:
                      onEditingMapDataChanged!(
                        currentMapData.copyWith(
                          type: AtlasMapShapeType.polygon,
                          points: [...currentMapData.points, coordinate],
                        ),
                      );
                    case AtlasMapShapeType.polyline:
                      onEditingMapDataChanged!(
                        currentMapData.copyWith(
                          type: AtlasMapShapeType.polyline,
                          points: [...currentMapData.points, coordinate],
                        ),
                      );
                  }
                },
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF10243A),
                  Color(0xFF16304B),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _AtlasMapPainter(
                      items: items,
                      selectedItemId: selectedItemId,
                      editingMapData: editingMapData,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _MapBadge(
                      label: onEditingMapDataChanged == null
                          ? 'Carte d’étude'
                          : 'Clique pour ajouter des points',
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: const _MapBadge(
                      label: 'Bornes: Méditerranée / Sinaï / Mésopotamie',
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    bottom: 16,
                    child: Text(
                      'Mer Méditerranée',
                      style: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _MapBadge extends StatelessWidget {
  final String label;

  const _MapBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AtlasMapPainter extends CustomPainter {
  final List<AtlasItem> items;
  final int? selectedItemId;
  final AtlasMapData? editingMapData;

  _AtlasMapPainter({
    required this.items,
    required this.selectedItemId,
    required this.editingMapData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _paintGrid(canvas, size);

    for (final item in items) {
      _paintMapData(
        canvas,
        size,
        item.mapData,
        _colorForItem(item),
        selected: item.id == selectedItemId,
      );
    }

    if (editingMapData != null) {
      _paintMapData(
        canvas,
        size,
        editingMapData!,
        const Color(0xFFFBBF24),
        selected: true,
        editing: true,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridColumns = 8;
    const gridRows = 6;
    for (int i = 1; i < gridColumns; i++) {
      final dx = size.width * i / gridColumns;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (int i = 1; i < gridRows; i++) {
      final dy = size.height * i / gridRows;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  void _paintMapData(
    Canvas canvas,
    Size size,
    AtlasMapData mapData,
    Color color, {
    required bool selected,
    bool editing = false,
  }) {
    if (mapData.points.isEmpty) {
      return;
    }

    final projectedPoints = mapData.points
        .map((point) => _coordinateToOffset(point, size))
        .toList();

    final linePaint = Paint()
      ..color = color.withValues(alpha: selected ? 0.92 : 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3 : 2;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: selected ? 0.25 : 0.14)
      ..style = PaintingStyle.fill;

    switch (mapData.type) {
      case AtlasMapShapeType.point:
        for (final point in projectedPoints) {
          canvas.drawCircle(point, selected ? 9 : 7, fillPaint);
          canvas.drawCircle(point, selected ? 9 : 7, linePaint);
        }
      case AtlasMapShapeType.polygon:
        if (projectedPoints.length >= 3) {
          final path = Path()..addPolygon(projectedPoints, true);
          canvas.drawPath(path, fillPaint);
          canvas.drawPath(path, linePaint);
        }
        for (final point in projectedPoints) {
          canvas.drawCircle(point, editing ? 5 : 4, Paint()..color = color);
        }
      case AtlasMapShapeType.polyline:
        final path = Path()..moveTo(projectedPoints.first.dx, projectedPoints.first.dy);
        for (final point in projectedPoints.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, linePaint);
        for (final point in projectedPoints) {
          canvas.drawCircle(point, editing ? 5 : 4, Paint()..color = color);
        }
    }
  }

  Color _colorForItem(AtlasItem item) {
    if (item.colorHex != null && item.colorHex!.startsWith('#')) {
      return Color(int.parse(item.colorHex!.replaceFirst('#', '0xFF')));
    }

    switch (item.type) {
      case AtlasItemType.region:
        return const Color(0xFF34D399);
      case AtlasItemType.route:
        return const Color(0xFF60A5FA);
      case AtlasItemType.event:
        return const Color(0xFFF59E0B);
      case AtlasItemType.place:
        return const Color(0xFFF87171);
    }
  }

  @override
  bool shouldRepaint(covariant _AtlasMapPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.selectedItemId != selectedItemId ||
        oldDelegate.editingMapData != editingMapData;
  }
}

Offset _coordinateToOffset(AtlasCoordinate coordinate, Size size) {
  final normalizedX = (coordinate.lng - _atlasMinLng) / (_atlasMaxLng - _atlasMinLng);
  final normalizedY = 1 - (coordinate.lat - _atlasMinLat) / (_atlasMaxLat - _atlasMinLat);
  return Offset(
    normalizedX.clamp(0.0, 1.0) * size.width,
    normalizedY.clamp(0.0, 1.0) * size.height,
  );
}

AtlasCoordinate _offsetToCoordinate(Offset offset, Size size) {
  final normalizedX = (offset.dx / math.max(size.width, 1)).clamp(0.0, 1.0);
  final normalizedY = (offset.dy / math.max(size.height, 1)).clamp(0.0, 1.0);

  return AtlasCoordinate(
    lat: _atlasMinLat + (1 - normalizedY) * (_atlasMaxLat - _atlasMinLat),
    lng: _atlasMinLng + normalizedX * (_atlasMaxLng - _atlasMinLng),
  );
}
