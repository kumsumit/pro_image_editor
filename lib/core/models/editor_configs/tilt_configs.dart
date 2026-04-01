/// Configuration options for the tilt editor.
class TiltConfigs {
  const TiltConfigs({
    this.showTiltButton = true,
    this.showTiltRotate = true,
    this.showTiltVertical = true,
    this.showTiltHorizontal = true,
    this.tiltRotateMin = -45.0,
    this.tiltRotateMax = 45.0,
    this.tiltVerticalMin = -30.0,
    this.tiltVerticalMax = 30.0,
    this.tiltHorizontalMin = -30.0,
    this.tiltHorizontalMax = 30.0,
  }) : assert(
         tiltRotateMin <= tiltRotateMax,
         '[tiltRotateMin] must be <= [tiltRotateMax]',
       ),
       assert(
         tiltVerticalMin <= tiltVerticalMax,
         '[tiltVerticalMin] must be <= [tiltVerticalMax]',
       ),
       assert(
         tiltHorizontalMin <= tiltHorizontalMax,
         '[tiltHorizontalMin] must be <= [tiltHorizontalMax]',
       );

  final bool showTiltButton;
  final bool showTiltRotate;
  final bool showTiltVertical;
  final bool showTiltHorizontal;
  final double tiltRotateMin;
  final double tiltRotateMax;
  final double tiltVerticalMin;
  final double tiltVerticalMax;
  final double tiltHorizontalMin;
  final double tiltHorizontalMax;

  TiltConfigs copyWith({
    bool? showTiltButton,
    bool? showTiltRotate,
    bool? showTiltVertical,
    bool? showTiltHorizontal,
    double? tiltRotateMin,
    double? tiltRotateMax,
    double? tiltVerticalMin,
    double? tiltVerticalMax,
    double? tiltHorizontalMin,
    double? tiltHorizontalMax,
  }) {
    return TiltConfigs(
      showTiltButton: showTiltButton ?? this.showTiltButton,
      showTiltRotate: showTiltRotate ?? this.showTiltRotate,
      showTiltVertical: showTiltVertical ?? this.showTiltVertical,
      showTiltHorizontal: showTiltHorizontal ?? this.showTiltHorizontal,
      tiltRotateMin: tiltRotateMin ?? this.tiltRotateMin,
      tiltRotateMax: tiltRotateMax ?? this.tiltRotateMax,
      tiltVerticalMin: tiltVerticalMin ?? this.tiltVerticalMin,
      tiltVerticalMax: tiltVerticalMax ?? this.tiltVerticalMax,
      tiltHorizontalMin: tiltHorizontalMin ?? this.tiltHorizontalMin,
      tiltHorizontalMax: tiltHorizontalMax ?? this.tiltHorizontalMax,
    );
  }
}
