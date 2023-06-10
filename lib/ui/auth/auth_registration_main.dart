import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freshgio/ui/auth/auth_email_registration_tablet_portrait.dart';
import 'package:freshgio/ui/auth/auth_phone_registration_mobile.dart';
import 'package:freshgio/ui/auth/auth_phone_signin.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../../library/api/data_api_og.dart';
import '../../library/api/prefs_og.dart';
import '../../library/cache_manager.dart';
import 'auth_email_registration_tablet_landscape.dart';
import '../../../realm_data/data/schemas.dart' as mrm;

class AuthRegistrationMain extends StatelessWidget {
  const AuthRegistrationMain(
      {Key? key,
      required this.prefsOGx,
      required this.dataApiDog,
      required this.cacheManager,
      required this.firebaseAuth, required this.onUserRegistered})
      : super(key: key);
  final PrefsOGx prefsOGx;
  final DataApiDog dataApiDog;
  final CacheManager cacheManager;
  final FirebaseAuth firebaseAuth;
  final Function(mrm.User) onUserRegistered;
  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout(
      mobile: AuthPhoneRegistrationMobile(
        prefsOGx: prefsOGx,
        dataApiDog: dataApiDog,
        cacheManager: cacheManager,
        firebaseAuth: firebaseAuth, onUserRegistered: (u ) {
          onUserRegistered(u);
      },
      ),
      tablet: OrientationLayoutBuilder(
        portrait: (context) {
          return const AuthEmailRegistrationPortrait(
            amInsideLandscape: false,
          );
        },
        landscape: (context) {
          return const AuthEmailRegistrationLandscape();
        },
      ),
    );
  }
}
