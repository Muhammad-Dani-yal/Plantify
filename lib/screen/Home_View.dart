// ignore_for_file: unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("PLANTIFY"),
          leading: IconButton(
            onPressed: () {},
            icon: Image.asset(
              'assets/images/Logo-3.png',
            ),
          ),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          double width = constraints.maxWidth * 1;
          double height = constraints.maxHeight * 0.4;
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Image.asset('assets/images/Group 73.png'),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 62.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/plant1.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 63.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/sage.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Stack(
                  children: [Image.asset('assets/images/Group 81.png')],
                ),
                SizedBox(
                  height: 10,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 64.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/interior medium light.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 67.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/Layer 8.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                Stack(children: [
                  Image.asset(
                    'assets/images/Group755.png',
                  )
                ]),
                SizedBox(
                  height: 200,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 79.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/Mask Group.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/Group 80.png',
                      width: 300,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Image.asset(
                        'assets/images/Layer 27.png',
                        height: 150,
                        width: 150,
                      ),
                    )
                  ],
                ),
                Stack(children: [
                  Text(
                    "Plant A Life",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 70),
                  ),
                ]),
              ],
            ),
          );
        }));
  }
}
