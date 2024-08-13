import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/components/shades.dart';
import 'package:myapp/screen/StartUp.dart';

class Splash_Page extends StatefulWidget {
  const Splash_Page({super.key});

  @override
  State<Splash_Page> createState() => _Splash_Page();
}

class _Splash_Page extends State<Splash_Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Timer(const Duration(seconds: 10), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => StartPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          AppColors.greenLight,
          Color.fromARGB(255, 216, 214, 214),
          AppColors.greenLight,
        ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Image.asset("assets/images/log2.png", fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
