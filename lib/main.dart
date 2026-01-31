import 'package:flutter/material.dart';
// import 'package:journal_app/viewmodels/home_viewmodel.dart';
// import 'package:journal_app/views/home_view.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
      MultiProvider(
        providers: [
          // ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ],
        child: const MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.outfitTextTheme(),
          primaryColor: Colors.orangeAccent,
        ),
        // home: const HomeView()
    );
  }
}
