

import 'dart:async';

// import 'package:device_preview/device_preview.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshgio/initializer.dart';
import 'package:freshgio/library/bloc/isolate_handler.dart';
import 'package:freshgio/library/bloc/organization_bloc.dart';
import 'package:freshgio/library/bloc/project_bloc.dart';
import 'package:freshgio/library/functions.dart';
import 'package:freshgio/realm_data/data/realm_sync_api.dart';
import 'package:freshgio/splash/splash_page.dart';
import 'package:freshgio/stitch/stitch_service.dart';
import 'package:freshgio/ui/dashboard/dashboard_main.dart';
import 'package:freshgio/ui/intro/intro_main.dart';
import 'package:freshgio/utilities/sync_util.dart';
import 'package:page_transition/page_transition.dart';
import 'package:universal_platform/universal_platform.dart';

import 'firebase_options.dart';
import 'library/api/data_api_og.dart';
import 'library/api/prefs_og.dart';
import 'library/bloc/cloud_storage_bloc.dart';
import 'library/bloc/fcm_bloc.dart';
import 'library/bloc/geo_uploader.dart';
import 'library/bloc/refresh_bloc.dart';
import 'library/bloc/theme_bloc.dart';
import 'library/cache_manager.dart';
import 'library/emojis.dart';

int themeIndex = 0;
var locale = const Locale('en');
late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
final mx =
    '${E.heartGreen}${E.heartGreen}${E.heartGreen}${E.heartGreen} main: ';
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firebaseApp = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  pp('\n\n$mx main: 🍎'
      ' Firebase App has been initialized: ${firebaseApp.name}, checking for authed current user\n');
  fbAuthedUser = fb.FirebaseAuth.instance.currentUser;

  // runApp(ProviderScope(
  //     child: DevicePreview(
  //   enabled: !kReleaseMode,
  //   builder: (BuildContext context) {
  //     return const GeoApp();
  //   },
  // )));
  runApp(const ProviderScope(child: GeoApp()));
}

class GeoApp extends ConsumerWidget {
  const GeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        pp('$mx 🌀🌀🌀🌀 Tap detected; should dismiss keyboard ...');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<LocaleAndTheme>(
        stream: themeBloc.localeAndThemeStream,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            pp('${E.check}${E.check}${E.check}'
                'build: theme index has changed to ${snapshot.data!.themeIndex}'
                '  and locale is ${snapshot.data!.locale.toString()}');
            themeIndex = snapshot.data!.themeIndex;
            locale = snapshot.data!.locale;
            pp('${E.check}${E.check}${E.check} GeoApp: build: locale object received from stream: $locale');
          }

          return MaterialApp(
            // useInheritedMediaQuery: true,
            // locale: DevicePreview.locale(context),
            // builder: DevicePreview.appBuilder,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            title: 'Gio',
            theme: themeBloc.getTheme(themeIndex).lightTheme,
            darkTheme: themeBloc.getTheme(themeIndex).darkTheme,
            themeMode: ThemeMode.system,
            // home:  const TestRealmSync(),
            home: AnimatedSplashScreen(
              duration: 3000,
              splash: const SplashWidget(),
              animationDuration: const Duration(milliseconds: 2000),
              curve: Curves.easeInCirc,
              splashIconSize: 160.0,
              nextScreen: LandingPage(prefsOGx: PrefsOGx()),
              splashTransition: SplashTransition.fadeTransition,
              pageTransitionType: PageTransitionType.leftToRight,
              backgroundColor: Colors.pink.shade900,
            ),
          );
        },
      ),
    );
  }
}

late StreamSubscription killSubscriptionFCM;

void showKillDialog({required String message, required BuildContext context}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        "Critical App Message",
        style: myTextStyleLarge(ctx),
      ),
      content: Text(
        message,
        style: myTextStyleMedium(ctx),
      ),
      shape: getRoundedBorder(radius: 16),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            pp(' Navigator popping for the last time, Sucker! 🔵🔵🔵');
            var android = UniversalPlatform.isAndroid;
            var ios = UniversalPlatform.isIOS;
            if (android) {
              SystemNavigator.pop();
            }
            if (ios) {
              Navigator.of(ctx).pop();
              Navigator.of(ctx).pop();
            }
          },
          child: const Text("Exit the App"),
        ),
      ],
    ),
  );
}

StreamSubscription<String> listenForKill({required BuildContext context}) {
  pp('\n$mx Kill message; listen for KILL message ...... 🍎🍎🍎🍎 ......');

  var sub = fcmBloc.killStream.listen((event) {
    pp('Kill message arrived: 🍎🍎🍎🍎 $event 🍎🍎🍎🍎');
    try {
      showKillDialog(message: event, context: context);
    } catch (e) {
      pp(e);
    }
  });

  return sub;
}

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key, required this.prefsOGx}) : super(key: key);

  final PrefsOGx prefsOGx;

  @override
  State<LandingPage> createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  final mx = '🔵🔵🔵🔵🔵🔵 LandingPage 🔵🔵';
  bool busy = false;



  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future initialize() async {
    pp('$mx ...................... initialize ............. 🍎🍎🍎');
    final start = DateTime.now();
    setState(() {
      busy = true;
    });
    await initializer.setupGio();
    try {
      final user = await widget.prefsOGx.getUser();
      if (user == null) {
        fbAuthedUser = null;
      } else {
        readShit(realmSyncApi, user.organizationId!);
      }
    } catch (e) {
      pp(e);
      if (mounted) {
        showSnackBar(message: 'Initialization failed', context: context);
      }
    }

    setState(() {
      busy = false;
    });
  }

  Widget getWidget() {
    if (busy) {
      pp('$mx getWidget: BUSY! returning empty sizeBox because initialization is still going on ...');
      return const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(),
          ));
    }
    if (fbAuthedUser == null) {
      pp('$mx getWidget returning widget IntroMain ..(fbAuthedUser == null)');
      return IntroMain(
        prefsOGx: getIt<PrefsOGx>(),
        dataApiDog: dataApiDog,
        cacheManager: cacheManager,
        fcmBloc: fcmBloc,
        realmSyncApi: realmSyncApi,
        refreshBloc: refreshBloc,
        organizationBloc: organizationBloc,
        projectBloc: projectBloc,
        geoUploader: geoUploader,
        stitchService: stitchService,
        cloudStorageBloc: cloudStorageBloc,
        firebaseAuth: FirebaseAuth.instance,
      );
    } else {
      pp('$mx getWidget returning widget DashboardMain ..(fbAuthedUser == ✅)');
      return DashboardMain(
        // dataHandler: dataHandler,
        dataApiDog: dataApiDog,
        fcmBloc: fcmBloc,
        projectBloc: projectBloc,
        prefsOGx: getIt<PrefsOGx>(),
        realmSyncApi: realmSyncApi,
        refreshBloc: refreshBloc,
        firebaseAuth: FirebaseAuth.instance,
        cloudStorageBloc: cloudStorageBloc,
        stitchService: stitchService,
        geoUploader: geoUploader,
        organizationBloc: organizationBloc,
        cacheManager: cacheManager,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    pp('$mx build method starting ....');
    return SafeArea(
        child: Scaffold(
          body: busy
              ? Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.asset(
                      'assets/gio.png',
                      height: 120,
                      width: 100,
                    ),
                  ),
                  const SizedBox(height: 48,),
                  const SizedBox(
                    height: 24, width: 24, child: CircularProgressIndicator(
                    strokeWidth: 6, backgroundColor: Colors.pink,
                  ),
                  ),
                  const SizedBox(height: 24,),
                  const Text('🔵 🔵 🔵 🔵 🔵 🔵 🍎 🔵 🔵 🔵 🔵 🔵 🔵'),
                ],
              ),
            ),
          )
              : getWidget(),
        ));
  }
}

