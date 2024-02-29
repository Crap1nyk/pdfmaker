import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/basic_page.dart';
import 'package:flutter_application_1/pages/custom_page.dart';
import 'package:flutter_application_1/pages/from_gallery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.indigo,
        scaffoldBackgroundColor: const Color.fromARGB(255, 13, 10, 10),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Color.fromARGB(255, 255, 232, 232), backgroundColor: Color.fromARGB(255, 104, 206, 234), // text color
            elevation: 5, // button shadow
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.tealAccent),
      ),
      title: 'Flutter Document Scanner',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Document Scanner'),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 4, 0, 4),
        ),
        body: Builder(
          builder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Basic example page
                  ElevatedButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => const BasicPage(),
                      ),
                    ),
                    child: const Text(
                      'Basic Scan',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  SizedBox(height: 16), // spacing between buttons

                  // Custom example page
                  ElevatedButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomPage(),
                      ),
                    ),
                    child: const Text(
                      'Custom Scan',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  SizedBox(height: 16), // spacing between buttons

                  // From gallery example page
                  ElevatedButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FromGalleryPage(),
                      ),
                    ),
                    child: const Text(
                      'From gallery',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
