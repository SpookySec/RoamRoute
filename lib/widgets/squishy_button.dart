import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SquishyButton extends StatefulWidget {
  final Widget? child;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final double width;

  const SquishyButton({
    Key? key,
    this.child,
    this.icon,
    required this.color,
    required this.onTap,
    this.height = 60,
    this.width = 60,
  }) : super(key: key);

  @override
  State<SquishyButton> createState() => _SquishyButtonState();
}

class _SquishyButtonState extends State<SquishyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        DuoSoundService.playClick();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.child ?? Icon(widget.icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
