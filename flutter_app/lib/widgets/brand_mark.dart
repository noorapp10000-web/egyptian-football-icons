// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xff78dfa6), Color(0xff197049)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff5fce93).withOpacity(.22),
          blurRadius: size * .35,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Image.asset('assets/images/team_crest.png'),
  );
}
