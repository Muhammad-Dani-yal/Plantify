import 'package:flutter/material.dart';

import '../components/shades.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width2 = constraints.maxWidth * 0.8;

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Image.asset('assets/images/arrow-left.png'),
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/Logo-1.png',
                    height: 30,
                    width: 200,
                  ),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/Signup.png'),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/text6.png'),
                  const SizedBox(height: 60),
                  const TextField(
                    decoration: const InputDecoration(
                      hintText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 30),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Password',
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(AppColors.greenLight),
                        minimumSize: MaterialStateProperty.all(
                          Size(width2, 50),
                        ),
                      ),
                      child: const Text(
                        "Create An Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(AppColors.greenLight),
                        minimumSize: MaterialStateProperty.all(
                          Size(width2, 50),
                        ),
                      ),
                      child: const Text(
                        "Already Have An Account!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
