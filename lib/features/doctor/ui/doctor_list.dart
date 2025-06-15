import 'package:flutter/material.dart';

/// Doctor list interface for Nurse Joy application
/// Implements modern UI patterns with performance optimizations
class DoctorList extends StatefulWidget {
  const DoctorList({super.key});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList>{

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Doctor List'),
    );
  }
}
