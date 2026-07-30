import 'package:flutter/material.dart';

import '../core/bank_catalog.dart';

class BankLogo extends StatelessWidget {
  const BankLogo({super.key, required this.bankCode, required this.size});

  final String bankCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: Transform.scale(
          scale: BankCatalog.logoScale(bankCode),
          child: Image.asset(
            BankCatalog.logoAsset(bankCode),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
