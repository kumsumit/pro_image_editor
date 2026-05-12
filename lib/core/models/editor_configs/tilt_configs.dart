/// Configuration options for the tilt editor.
class TiltConfigs {
  /// Creates a new instance of [TiltConfigs].
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

  /// Whether to show the tilt button.
  final bool showTiltButton;

  /// Whether to show the tilt rotate option.
  final bool showTiltRotate;

  /// Whether to show the tilt vertical option.
  final bool showTiltVertical;

  /// Whether to show the tilt horizontal option.
  final bool showTiltHorizontal;

  /// The minimum tilt rotate value.
  final double tiltRotateMin;

  /// The maximum tilt rotate value.
  final double tiltRotateMax;

  /// The minimum tilt vertical value.
  final double tiltVerticalMin;

  /// The maximum tilt vertical value.
  final double tiltVerticalMax;

  /// The minimum tilt horizontal value.
  final double tiltHorizontalMin;

  /// The maximum tilt horizontal value.
  final double tiltHorizontalMax;

  /// Creates a copy of this [TiltConfigs] with optional overrides.
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
