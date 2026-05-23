import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/subject.dart';

final subjectsProvider = Provider<List<Subject>>((ref) {
  return const [
    Subject(id: 'korean', name: '국어', color: Color(0xFFE5989B)),
    Subject(id: 'math', name: '수학', color: Color(0xFFA9D6E5)),
  ];
});
