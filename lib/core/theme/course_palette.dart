import 'package:flutter/material.dart';

const List<Color> _courseAccents = [
  Color(0xFF6F7F8C),
  Color(0xFF8A7C6B),
  Color(0xFF6F8A7A),
  Color(0xFF8A6F7A),
  Color(0xFF757A8A),
  Color(0xFF8A856F),
  Color(0xFF6F7A8A),
  Color(0xFF8A6F6F),
];

Color courseAccent(int courseId) {
  return _courseAccents[courseId.abs() % _courseAccents.length];
}
