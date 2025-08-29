import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SaudiRiyalSymbol extends StatelessWidget {
  final double size;
  final Color? color;
  final String? amount;

  const SaudiRiyalSymbol({
    super.key,
    this.size = 16.0,
    this.color,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    if (amount != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/Saudi_Riyal_Symbol.svg',
            width: size,
            height: size,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(width: 2),
          Text(
            amount!,
            style: TextStyle(
              fontSize: size * 0.8,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return SvgPicture.asset(
      'assets/icons/Saudi_Riyal_Symbol.svg',
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}
