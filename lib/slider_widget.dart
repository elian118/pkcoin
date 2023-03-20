import 'package:flutter/material.dart';

class SliderWidget extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final void Function(double)? onChangeValue;

  const SliderWidget({
    Key? key,
    required this.value,
    required this.onChangeValue,
    required this.min,
    required this.max,
  }) : super(key: key);

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  @override
  Widget build(BuildContext context) {
    return Slider(
      min: widget.min,
      max: widget.max,
      value: widget.value,
      divisions: 20,
      label: '\$${widget.value.toInt()}',
      onChanged: widget.onChangeValue,
    );
  }
}
