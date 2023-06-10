import 'package:flutter/material.dart';

import '../../data/project.dart';

import 'package:freshgio/realm_data/data/schemas.dart' as mrm;

class ProjectSchedulesMobile extends StatefulWidget {
  const ProjectSchedulesMobile({Key? key, required this.project}) : super(key: key);
  final mrm.Project project;
  @override
  ProjectSchedulesMobileState createState() => ProjectSchedulesMobileState();
}

class ProjectSchedulesMobileState extends State<ProjectSchedulesMobile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Project Schedules for ${widget.project.name}'),
    );
  }
}
