// lib/services/image_coordinate_mapper.dart
import 'dart:math';
import 'dart:ui';

class ImageCoordinateMapper {
  final double imageWidth;
  final double imageHeight;
  final double containerWidth;
  final double containerHeight;

  late final double scale;
  late final double renderedWidth;
  late final double renderedHeight;
  late final double offsetX;
  late final double offsetY;
  late final Rect renderedImageRect;

  ImageCoordinateMapper({
    required this.imageWidth,
    required this.imageHeight,
    required this.containerWidth,
    required this.containerHeight,
  }) {
    scale = min(containerWidth / imageWidth, containerHeight / imageHeight);
    renderedWidth = imageWidth * scale;
    renderedHeight = imageHeight * scale;
    offsetX = (containerWidth - renderedWidth) / 2.0;
    offsetY = (containerHeight - renderedHeight) / 2.0;

    renderedImageRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      renderedWidth,
      renderedHeight,
    );
  }

  /// Clamps touch points so rectangles cannot be drawn outside the photograph
  Offset clampToRenderedBounds(Offset point) {
    final double clampedX = point.dx.clamp(renderedImageRect.left, renderedImageRect.right);
    final double clampedY = point.dy.clamp(renderedImageRect.top, renderedImageRect.bottom);
    return Offset(clampedX, clampedY);
  }

  /// Converts screen display Rect to original camera image coordinates
  Rect displayToOriginalImage(Rect displayRect) {
    final double left = ((displayRect.left - offsetX) / scale).clamp(0.0, imageWidth);
    final double top = ((displayRect.top - offsetY) / scale).clamp(0.0, imageHeight);
    final double width = (displayRect.width / scale).clamp(1.0, imageWidth - left);
    final double height = (displayRect.height / scale).clamp(1.0, imageHeight - top);

    return Rect.fromLTWH(
      double.parse(left.toStringAsFixed(1)),
      double.parse(top.toStringAsFixed(1)),
      double.parse(width.toStringAsFixed(1)),
      double.parse(height.toStringAsFixed(1)),
    );
  }

  /// Projects stored original image coordinates to current screen widget Rect
  Rect originalImageToDisplay(Rect originalRect) {
    return Rect.fromLTWH(
      offsetX + (originalRect.left * scale),
      offsetY + (originalRect.top * scale),
      originalRect.width * scale,
      originalRect.height * scale,
    );
  }
}