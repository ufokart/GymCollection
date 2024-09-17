import 'package:flutter/material.dart';
import 'screens/Dashboard/dashboard.dart';
import 'screens/splashscreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaccounted/Networking/membership_api.dart';
import 'package:provider/provider.dart';
import 'package:gymaccounted/screens/Setting.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp();
//   await Firebase.initializeApp(name: "Gym Collection",options: FirebaseOptions(
//       apiKey: "AIzaSyCgZ51OertjAHcRhhr7Y55-eJF1QVUo784",
//       authDomain: "gym-collection.firebaseapp.com",
//       projectId: "gym-collection",
//       storageBucket: "gym-collection.appspot.com",
//       messagingSenderId: "1093148006415",
//       appId: "1:1093148006415:web:49a11e8134daf9a455eb7a",
//       measurementId: "G-NHFRW1JKJD"
//   ),);
  // const firebaseConfig = {
  //   apiKey: "AIzaSyCgZ51OertjAHcRhhr7Y55-eJF1QVUo784",
  //   authDomain: "gym-collection.firebaseapp.com",
  //   projectId: "gym-collection",
  //   storageBucket: "gym-collection.appspot.com",
  //   messagingSenderId: "1093148006415",
  //   appId: "1:1093148006415:web:49a11e8134daf9a455eb7a",
  //   measurementId: "G-NHFRW1JKJD"
  // };
  final themeProvider = ThemeProvider(ThemeData.light());
  await themeProvider.loadTheme();
  await Supabase.initialize(
    url: 'https://fnuegwcttzpqksvkswwf.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZudWVnd2N0dHpwcWtzdmtzd3dmIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzMzMzE4MjgsImV4cCI6MTk4ODkwNzgyOH0.2p7XY67oF66-vDZ4dAo_wPTE0IoNAmiVW6q-8V0BezU',
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: themeProvider.themeData,
          home: SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
    // return FutureBuilder(
    //   // Initialize FlutterFire
    //   future: Firebase.initializeApp(),
    //   builder: (context, snapshot) {
    //     // Check for errors
    //     if (snapshot.hasError) {
    //       return Center();//SomethingWentWrong();
    //     }
    //
    //     // Once complete, show your application
    //     if (snapshot.connectionState == ConnectionState.done) {
    //       return  Consumer<ThemeProvider>(
    //         builder: (context, themeProvider, child) {
    //           return MaterialApp(
    //             theme: themeProvider.themeData,
    //             home: SplashScreen(),
    //             debugShowCheckedModeBanner: false,
    //           );
    //         },
    //       );
    //     }
    //
    //     // Otherwise, show something whilst waiting for initialization to complete
    //     return Center();
    //   },
    // );



  }
}