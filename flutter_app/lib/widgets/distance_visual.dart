import 'package:flutter/material.dart';

class DistanceVisual extends StatelessWidget {
  final String initial1;
  final String initial2;

  const DistanceVisual({
    super.key,
    required this.initial1,
    required this.initial2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _initialCircle(initial1),
        const SizedBox(width: 4),
        Flexible(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFff6b9d).withValues(alpha: 0.6),
                        const Color(0xFFff6b9d).withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('💕', style: TextStyle(fontSize: 20)),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFff6b9d).withValues(alpha: 0.2),
                        const Color(0xFFff6b9d).withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        _initialCircle(initial2),
      ],
    );
  }

  Widget _initialCircle(String letter) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFff6b9d), Color(0xFFc44569)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b9d).withValues(alpha: 0.4),
            blurRadius: 15,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
