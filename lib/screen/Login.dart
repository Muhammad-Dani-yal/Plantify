import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/components/shades.dart';
import 'package:myapp/screen/Forget_Passord.dart';
import 'package:myapp/screen/SignUp_Page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(237, 255, 255, 255),
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
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/images/Logo-1.png',
                    height: 50,
                    width: 200,
                  ),
                  const SizedBox(height: 10),
                  Image.asset('assets/images/Login.png'),
                  const SizedBox(height: 10),
                  Image.asset('assets/images/text5.png'),
                  const SizedBox(height: 30),
                  const Text(
                    "UserName/ Email",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock_rounded,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        hintText: 'MASUKKAN EMAIL',
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Password",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock_rounded,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        hintText: 'MASUKKAN PASSWORD',
                      ),
                    ),
                  ),
                  Container(
                      child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgetScreen(),
                              ),
                            );
                          },
                          child: Text("Lupa password"))),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(AppColors.greenLight),
                        minimumSize: MaterialStateProperty.all(
                          Size(width2, 50),
                        ),
                      ),
                      child: const Text(
                        "MULAI BELAJAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
