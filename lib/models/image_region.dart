// lib/models/image_region.dart

class ImageRegion {
  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final double confidence;

  const ImageRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    this.confidence = 1.0,
  });

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toJson() => {
        'label': label,
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'confidence': confidence,
      };

  @override
  String toString() =>
      '$label(x: ${left.toStringAsFixed(1)}, y: ${top.toStringAsFixed(1)}, w: ${width.toStringAsFixed(1)}, h: ${height.toStringAsFixed(1)}, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}