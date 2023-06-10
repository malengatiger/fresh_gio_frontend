import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshgio/device_location/device_location_bloc.dart';
import 'package:freshgio/library/api/data_api_og.dart';
import 'package:freshgio/library/bloc/cloud_storage_bloc.dart';
import 'package:freshgio/library/bloc/ios_polling_control.dart';
import 'package:freshgio/library/bloc/isolate_handler.dart';
import 'package:freshgio/library/bloc/location_request_handler.dart';
import 'package:freshgio/library/bloc/organization_bloc.dart';
import 'package:freshgio/library/errors/error_handler.dart';
import 'package:freshgio/realm_data/data/app_services.dart';
import 'package:freshgio/realm_data/data/realm_sync_api.dart';
import 'package:freshgio/stitch/stitch_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;

import 'library/api/prefs_og.dart';
import 'library/auth/app_auth.dart';
import 'library/bloc/data_refresher.dart';
import 'library/bloc/fcm_bloc.dart';
import 'library/bloc/geo_uploader.dart';
import 'library/bloc/project_bloc.dart';
import 'library/bloc/user_bloc.dart';
import 'library/cache_manager.dart';
import 'library/functions.dart';
import 'library/geofence/the_great_geofencer.dart';

int themeIndex = 0;
late FirebaseApp firebaseApp;
fb.User? fbAuthedUser;
final Initializer initializer = Initializer();

class Initializer {
  final mx = '✅✅✅✅✅ Initializer: ✅';

  Future setupGio() async {
    pp('\n\n$mx setupGio: ... setting up resources and blocs etc .............. ');

    await initializeGioServices();
    await heavyLifting();
    return 0;
  }

  Future<void> initializeGioServices() async {
    pp('\n\n$mx initializeGioServices: ... setting up resources and blocs etc .............. ');

    await GetStorage.init(cacheName);
    prefsOGx = PrefsOGx();
    locationBloc = DeviceLocationBloc();
    await Hive.initFlutter(hiveName);
    cacheManager = CacheManager();

    final client = http.Client();
    appAuth = AppAuth(fb.FirebaseAuth.instance);

    stitchService = StitchService(http.Client());

    errorHandler = ErrorHandler(locationBloc, prefsOGx);
    dataApiDog =
        DataApiDog(client, appAuth, cacheManager, prefsOGx, errorHandler);
    dataRefresher =
        DataRefresher(appAuth, errorHandler, dataApiDog, client, cacheManager);
    geoUploader = GeoUploader(errorHandler, cacheManager, dataApiDog);

    organizationBloc = OrganizationBloc(dataApiDog, cacheManager);
    locationRequestHandler = LocationRequestHandler(dataApiDog);

    realmSyncApi = RealmSyncApi();
    final sett = await prefsOGx.getSettings();
    var ok = await realmSyncApi.initialize();



    if (sett.organizationId != null) {
      var m = getStartEndDatesFromDays(numberOfDays: sett.numberOfDays!);
      if (ok) {
        await realmSyncApi.setSubscriptions(
            organizationId: sett.organizationId!, countryId: null, startDate: m.$1, projectId: null);
      }
      theGreatGeofencer = TheGreatGeofencer( prefsOGx, realmSyncApi,dataApiDog);

    } else {
      if (ok) {
        await realmSyncApi.setSubscriptions(
            organizationId: 'null', countryId: null, startDate: null, projectId: null);
        final list = realmSyncApi.getCountries();
        list.sort((a,b) => a.name!.compareTo(b.name!));
        pp('\n$mx COUNTRIES LOADED: 🔵🔵🔵🔵🔵🔵🔵🔵🔵 ${list.length}');
      }
    }

    //todo - dataHandler might not be needed
    dataHandler =
        IsolateDataHandler(prefsOGx, appAuth, cacheManager, realmSyncApi);
    pollingControl = IosPollingControl(dataHandler);

    //todo - dataHandler might not be needed
    projectBloc = ProjectBloc(dataApiDog, cacheManager, dataHandler);
    userBloc = UserBloc(dataApiDog, cacheManager, dataHandler);

    fcmBloc = FCMBloc(FirebaseMessaging.instance, cacheManager,
        locationRequestHandler, realmAppServices);

    pp('$mx initializeGioServices: ...resources and blocs etc set up ok!  \n\n');
    //testRealmJson();
  }

  Future heavyLifting() async {
    pp('$mx Heavy lifting starting ....');

    final start = DateTime.now();
    final settings = await prefsOGx.getSettings();

    FirebaseMessaging.instance.requestPermission();

    pp('$mx heavyLifting: ✅;cacheManager initialization starting .................');
    await cacheManager.initialize();
    pp('$mx heavyLifting: ✅; fcm initialization starting .................');
    await fcmBloc.initialize();

    final token = await appAuth.getAuthToken();
    pp('$mx heavyLifting: ✅;Firebase auth token:\n$token\n');

    if (settings.organizationId != null) {
      pp('$mx heavyLifting ✅; _buildGeofences starting ..................');
      theGreatGeofencer.buildGeofences();
    }

    pp('$mx organizationDataRefresh starting ........................');
    pp('$mx start with delay of 5 seconds before data refresh ..............');


    if (settings.organizationId != null) {
      pp('$mx heavyLifting: cloudStorageBloc.uploadEverything starting ...............');
      //geoUploader.manageMediaUploads();
      cloudStorageBloc.uploadEverything();
    }
    pp('\n\n$mx  '
        'initializeGeo: Hive initialized Gio services. '
        '💜💜 Ready to rumble! Ali Bomaye!!');
    final end = DateTime.now();
    pp('$mx initializeGeo, heavyLifting: Time Elapsed: ${end.difference(start).inMilliseconds} '
        'milliseconds\n\n');
    final sett = await prefsOGx.getSettings();

    pp('$mx initializeGeo, heavyLifting: realmSyncApi to be initialized ...');

  }
}
