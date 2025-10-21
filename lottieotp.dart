import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Lottieotp extends StatelessWidget {
  final double height;
  final double width;

  const Lottieotp({super.key, this.height = 200, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Lottie.asset(
        'assets/lottie/otp.json',
        fit: BoxFit.cover,
        repeat: true,
      ),
    );
  }
}