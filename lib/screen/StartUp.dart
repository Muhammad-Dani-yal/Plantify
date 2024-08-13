import 'package:flutter/material.dart';
import 'package:myapp/components/shades.dart';
import 'package:myapp/screen/Login.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              color: AppColors.greenLight,
            ),
            height: MediaQuery.of(context).size.height * .7,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo.png",
                  height: 200,
                ),
                const SizedBox(
                  height: 50,
                ),
                Image.asset("assets/images/Logo5.png"),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 25.0)),
              Image.asset("assets/images/Logo6.png"),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 25.0)),
              Image.asset("assets/images/Logo7.png"),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
            ),
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width * .9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.greenLight // Text color
                    ),
                child: const Text(
                  'MASUK',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
