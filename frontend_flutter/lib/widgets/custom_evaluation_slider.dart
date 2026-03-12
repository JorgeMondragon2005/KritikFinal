// lib/widgets/custom_evaluation_slider.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomEvaluationSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const CustomEvaluationSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomEvaluationSlider> createState() => _CustomEvaluationSliderState();
}

class _CustomEvaluationSliderState extends State<CustomEvaluationSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            '${widget.value.toInt()}/10',
            key: ValueKey<int>(widget.value.toInt()),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: AppColors.primaryYellow,
              fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: Theme.of(context).sliderTheme,
          child: Slider(
            value: widget.value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
