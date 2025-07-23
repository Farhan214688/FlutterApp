import 'package:firstt_project/SplashPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'DashBoard.dart';
import 'StartingPage1.dart';
import 'LoginPage.dart';
import 'ProfessionalServiceSelectionPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'IDCardVerificationPage.dart';
import 'SelfieVerificationPage.dart';
import 'LocationPickerPage.dart';
import 'CongratulationsPage.dart';
import 'admin_portal.dart';
import 'professional_screens/ProfessionalDashboard.dart';
import 'services/weekly_offers_service.dart';
import 'services/shared_prefs_service.dart';
import 'services/service_persistence_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Default Firebase options
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'AIzaSyA2fbRDdvbQY7VOQJWLOn6hVROAwvT3Spw',
    appId: '1:520281661100:android:d90ec076a50cc0c4f4c909',
    messagingSenderId: '520281661100',
    projectId: 'rapit-777d7',
    storageBucket: 'rapit-777d7.appspot.com',
  );
}

// Global Firebase app variable that can be checked throughout the app
FirebaseApp? firebaseApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPrefsService
  await SharedPrefsService.init();
  print("SharedPrefsService initialized");
  
  // We never want to clear login data on restart
  // await clearAllLoginDataOnRestart();

  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      firebaseApp = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized successfully with app: ${firebaseApp?.name}");
    } else {
      firebaseApp = Firebase.app();
      print("Using existing Firebase app: ${firebaseApp?.name}");
    }
    
    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      // Use debug provider for development
      webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    print("Firebase App Check initialized successfully");
    
    // Enable Firestore offline persistence
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    print("Firebase persistence enabled successfully");
    
    // Initialize the weekly offers service and sync any cached data
    await initWeeklyOffersService();
    
    // Initialize the admin services persistence service
    await initAdminServicesService();
  } catch (e) {
    print("Failed to initialize Firebase with options: $e");
    // Fallback initialization without options
    try {
      // Only try initializing if it's not already initialized
      if (Firebase.apps.isEmpty) {
        firebaseApp = await Firebase.initializeApp();
        print("Firebase initialized with default options");
      } else {
        firebaseApp = Firebase.app();
        print("Using existing Firebase app with default options");
      }
      
      // Try to initialize App Check even in fallback mode
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        print("Firebase App Check initialized in fallback mode");
      } catch (appCheckError) {
        print("Failed to initialize App Check in fallback mode: $appCheckError");
      }
      
      // Enable Firestore offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print("Firebase persistence enabled with default options");
      
      // Initialize the weekly offers service and sync any cached data
      await initWeeklyOffersService();
      
      // Initialize the admin services persistence service
      await initAdminServicesService();
    } catch (e) {
      print("All Firebase initialization attempts failed: $e");
      // Don't create a dummy FirebaseApp, just set to null
      firebaseApp = null;
    }
  }

  runApp(MyApp());
}

// Initialize and sync weekly offers data
Future<void> initWeeklyOffersService() async {
  try {
    print("Initializing weekly offers service...");
    final weeklyOffersService = WeeklyOffersService();
    
    // Attempt to sync any cached weekly offers to Firestore
    await weeklyOffersService.syncCachedOffersToFirestore();
    print("Weekly offers service initialized successfully");
  } catch (e) {
    print("Error initializing weekly offers service: $e");
  }
}

// Initialize and sync admin services
Future<void> initAdminServicesService() async {
  try {
    print("Initializing admin services persistence service...");
    final servicePersistenceService = ServicePersistenceService();
    
    // Check if this is a fresh install
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstRun = prefs.getBool('first_run') ?? true;
    
    // Set first_run flag to false but don't clear the cache
    if (isFirstRun) {
      print("First run detected, but preserving any existing service cache");
      await prefs.setBool('first_run', false);
      
      // Attempt to sync cached services to Firestore on reinstall
      await servicePersistenceService.syncCachedServicesToFirestore();
    }
    
    // Load admin services to ensure they're cached
    await servicePersistenceService.loadAdminServices();
    print("Admin services persistence service initialized successfully");
  } catch (e) {
    print("Error initializing admin services persistence service: $e");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rapit',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashPage(),
      routes: {
        '/dashboard': (context) => Dashboard(),
        '/admin': (context) => AdminPortal(),
        '/starting': (context) => StartingPage(),
        '/login': (context) => LoginPage(),
        '/professional-service': (context) => ProfessionalServiceSelectionPage(),
        '/home': (context) => Dashboard(), // Add dashboard as home route
        '/professional_dashboard': (context) => ProfessionalDashboard(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});



  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool? isChecked1 = false;
  bool? isChecked2 = false;


  void _incrementCounter() {
    setState(() {

      _counter++;
    });
  }

  var result1= "";

  @override
  Widget build(BuildContext context) {

    var FullName = TextEditingController();
    var PhoneNumber= TextEditingController();
    var Password= TextEditingController();
    var ConfirmPass= TextEditingController();
    bool _isVisisble = false;
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.greenAccent,

        title: Text(widget.title),
      ),
      body:SingleChildScrollView(
        child: Column(

          children: [
            Center(
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                  ),
                  Container(
                    height: 100,
                    width: 150,
                    child: Image.asset('Assets/Images/Start2.png'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text('Sign Up as Customer', style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                controller: FullName,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.lightGreenAccent,
                        width: 2,
                      )

                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black38,
                        width: 2,
                      )
                  ),
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.account_circle_sharp),
                ),

              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                keyboardType: TextInputType.phone,
                controller: PhoneNumber,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.lightGreenAccent,
                        width: 2,
                      )

                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black38,
                        width: 2,
                      )
                  ),
                  hintText: 'Phone Number',
                  prefixIcon: Icon(Icons.add_call),
                ),

              ),
            ),

            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                obscureText: !_isVisisble,
                controller: Password,
                decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.lightGreenAccent,
                          width: 2,
                        )
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.black38,
                          width: 2,
                        )
                    ),
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),

                    suffixIcon: IconButton(onPressed: (){
                      setState(() {
                        _isVisisble= !_isVisisble;
                      });
                    }, icon: Icon(
                      _isVisisble
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ))
                ),

              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              width: 380,
              child: TextField(
                obscureText: true,
                controller: ConfirmPass,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.lightGreenAccent,
                        width: 2,
                      )
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.black38,
                        width: 2,
                      )
                  ),
                  hintText: ' Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: Icon(Icons.remove_red_eye_outlined),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                    checkColor: Colors.lightGreenAccent,
                    value: isChecked1,
                    onChanged: (newBool){
                      setState(() {
                        isChecked1= newBool;
                      });
                    }
                ),
                Text('Remember Password', style: TextStyle(
                  fontSize: 16,
                ),),
              ],

            ),
            Row(
              children: [
                Checkbox(
                    checkColor: Colors.lightGreenAccent,
                    value: isChecked2,
                    onChanged: (newBool){
                      setState(() {
                        isChecked2= newBool;
                      });
                    }
                ),
                Expanded(
                  child: Text('I agree to Terms and Conditions and accept Privacy policy', style: TextStyle(
                    fontSize: 16,
                  ),),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),


            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(onPressed: (){
                String name = FullName.text.toString();
                String number= PhoneNumber.text.toString();
                String pass = Password.text.toString();
                String c_pass = ConfirmPass.text.toString();

              }, child: Text('SIGN UP'),
              ),
            ),
            SizedBox(
              height: 10,
            ),

            /*Text('Signup using social account', style: TextStyle(
              fontSize: 15,

            ),),*/
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.black, // Line color
                    thickness: 1, // Line thickness
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8), // Spacing between lines and text
                  child: Text(
                    'Signup using social account',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.black,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),


            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(onPressed: (){

              }, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.google),
                  SizedBox(
                    width: 8,
                  ),
                  Text('CONTINUE WITH GOOGLE'),
                ],
              ),
              ),
            ),
            SizedBox(
              height: 25,
            ),

            Container(
              width: 380,
              decoration: BoxDecoration(
                color: Colors.lightGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextButton(onPressed: (){

              }, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.facebook),
                  SizedBox(
                    width: 8,
                  ),
                  Text('CONTINUE WITH FACEBOOK'),
                ],
              ),
              ),
            ),
            TextButton(onPressed: (){

            }, child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Text('Already have an account?'),
                SizedBox(
                  width: 5,
                ),
                Text('Login', style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),)
              ],
            )),


          ],
        ),
      ),
    );
  }
}

// Remove or comment out the clearAllLoginDataOnRestart function to prevent data loss
// Future<void> clearAllLoginDataOnRestart() async {
//   try {
//     print("🔥 FORCE CLEARING ALL LOGIN DATA ON RESTART 🔥");
//     final prefs = await SharedPreferences.getInstance();
// 
//     // Clear ALL authentication related data
//     await prefs.setBool('isUserLoggedIn', false);
//     await prefs.setBool('isLoggedIn', false);
//     await prefs.setBool('userHasLoggedOut', true);
//     await prefs.remove('userType');
//     await prefs.remove('username');
// 
//     // Clear ALL types of credentials
//     await prefs.remove('professionalPhone');
//     await prefs.remove('professionalPassword');
//     await prefs.remove('professionalName');
//     await prefs.remove('adminPhone');
//     await prefs.remove('adminPassword');
//     await prefs.remove('customerPhone');
//     await prefs.remove('customerPassword');
// 
//     // Clear additional persistence flags
//     await prefs.remove('rememberPassword');
// 
//     print("✅ All login data forcibly cleared on app restart");
//   } catch (e) {
//     print("⚠️ Error clearing login data: $e");
//   }
// }
