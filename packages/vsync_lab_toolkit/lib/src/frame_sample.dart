class FrameSample {
  const FrameSample({
    required this.frameEndUs,
    required this.buildUs,
    required this.rasterUs,
    required this.totalUs,
  });

  final int frameEndUs;
  final int buildUs;
  final int rasterUs;
  final int totalUs;
}
