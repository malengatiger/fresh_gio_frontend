import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freshgio/device_location/device_location_bloc.dart';
import 'package:freshgio/library/api/prefs_og.dart';
import 'package:freshgio/library/bloc/geo_exception.dart';
import 'package:freshgio/library/bloc/old_to_realm.dart';
import 'package:freshgio/library/cache_manager.dart';
import 'package:freshgio/library/emojis.dart';
import 'package:freshgio/library/errors/error_handler.dart';
import 'package:freshgio/library/functions.dart';
import 'package:freshgio/realm_data/data/schemas.dart' as mrm;
import 'package:realm/realm.dart' as rm;
import 'package:realm/realm.dart';
import 'package:realm/realm.dart';

import '../../generic_utils/functions.dart';
import '../../library/api/data_api_og.dart';

const realmAppId = 'application-0-rmusa';
const realmPublicKey = 'xtffryvl';
const privateKey = 'ff87d3e1-6366-4a9c-9ae0-8065540a8483';

late RealmSyncApi realmSyncApi;
late rm.User realmUser;
late rm.App app;
final schemas = [
  mrm.City.schema,
  mrm.Position.schema,
  mrm.AppError.schema,
  mrm.Organization.schema,
  mrm.Project.schema,
  mrm.ProjectPolygon.schema,
  mrm.ProjectPosition.schema,
  mrm.User.schema,
  mrm.Photo.schema,
  mrm.Video.schema,
  mrm.Audio.schema,
  mrm.GeofenceEvent.schema,
  mrm.LocationRequest.schema,
  mrm.LocationResponse.schema,
  mrm.SettingsModel.schema,
  mrm.Country.schema,
  mrm.ActivityModel.schema,
  mrm.OrgMessage.schema,
  mrm.FieldMonitorSchedule.schema,
  mrm.Rating.schema,
  mrm.Pricing.schema,
  mrm.GioSubscription.schema,
  mrm.GioPaymentRequest.schema,
  mrm.State.schema,
];
late rm.Realm realmRemote;

void initialDataCallback(rm.Realm realm) {
  px('🍎🍎🍎🍎🍎 initialDataCallback ... 🍎do something on initial start up!');
}

class RealmSyncApi with ChangeNotifier {
  final mm = '🌎🌎🌎🌎🌎🌎 RealmSyncApi 🌎';

  late rm.Realm realmCities;

  final StreamController<List<mrm.User>> _userCont =
      StreamController.broadcast();

  Stream<List<mrm.User>> get userStream => _userCont.stream;

  final StreamController<List<mrm.Project>> _projectCont =
      StreamController.broadcast();

  Stream<List<mrm.Project>> get projectStream => _projectCont.stream;

  final StreamController<List<mrm.ActivityModel>> _activityCont =
      StreamController.broadcast();

  Stream<List<mrm.ActivityModel>> get activityStream => _activityCont.stream;

  final StreamController<List<mrm.ActivityModel>> _orgActivityCont =
      StreamController.broadcast();

  Stream<List<mrm.ActivityModel>> get orgActivityStream =>
      _orgActivityCont.stream;

  final StreamController<List<mrm.Photo>> _photoCont =
      StreamController.broadcast();

  Stream<List<mrm.Photo>> get photoStream => _photoCont.stream;

  final StreamController<List<mrm.Photo>> _orgPhotoCont =
      StreamController.broadcast();

  Stream<List<mrm.Photo>> get organizationPhotoStream => _orgPhotoCont.stream;

  final StreamController<List<mrm.Video>> _videoCont =
      StreamController.broadcast();

  Stream<List<mrm.Video>> get videoStream => _videoCont.stream;

  final StreamController<List<mrm.Video>> _orgVideoCont =
      StreamController.broadcast();

  Stream<List<mrm.Video>> get organizationVideoStream => _orgVideoCont.stream;

  final StreamController<List<mrm.Audio>> _audioCont =
      StreamController.broadcast();

  Stream<List<mrm.Audio>> get audioStream => _audioCont.stream;

  final StreamController<List<mrm.Audio>> _orgAudioCont =
      StreamController.broadcast();

  Stream<List<mrm.Audio>> get organizationAudioStream => _orgAudioCont.stream;

  final StreamController<List<mrm.User>> _orgUserStreamController =
      StreamController.broadcast();

  Stream<List<mrm.User>> get organizationUserStream => _orgUserStreamController.stream;

  final StreamController<List<mrm.SettingsModel>> _settingsCont =
      StreamController.broadcast();

  Stream<List<mrm.SettingsModel>> get settingsStream => _settingsCont.stream;

  final StreamController<List<mrm.Organization>> _orgsCont =
      StreamController.broadcast();

  Stream<List<mrm.Organization>> get organizationStream => _orgsCont.stream;

  final StreamController<List<mrm.ProjectPosition>> _positionsCont =
      StreamController.broadcast();

  Stream<List<mrm.ProjectPosition>> get projectPositionStream =>
      _positionsCont.stream;

  final StreamController<List<mrm.ProjectPosition>> _orgPositionsCont =
      StreamController.broadcast();

  Stream<List<mrm.ProjectPosition>> get organizationPositionStream =>
      _orgPositionsCont.stream;

  final StreamController<List<mrm.ProjectPolygon>> _polCont =
      StreamController.broadcast();

  Stream<List<mrm.ProjectPolygon>> get projectPolygonStream => _polCont.stream;

  final StreamController<List<mrm.ProjectPolygon>> _orgPolCont =
      StreamController.broadcast();

  Stream<List<mrm.ProjectPolygon>> get organizationPolygonStream =>
      _orgPolCont.stream;

  final StreamController<List<mrm.Country>> _countryCont =
      StreamController.broadcast();

  Stream<List<mrm.Country>> get countryStream => _countryCont.stream;

  final StreamController<List<mrm.GeofenceEvent>> _geoCont =
      StreamController.broadcast();

  Stream<List<mrm.GeofenceEvent>> get geofenceStream => _geoCont.stream;

  final StreamController<List<mrm.GeofenceEvent>> _orgGeoCont =
      StreamController.broadcast();

  Stream<List<mrm.GeofenceEvent>> get organizationGeofenceStream =>
      _orgGeoCont.stream;

  //
  final StreamController<List<mrm.GioSubscription>> _subsCont =
      StreamController.broadcast();

  Stream<List<mrm.GioSubscription>> get organizationSubscriptionStream =>
      _subsCont.stream;

  //
  final StreamController<List<mrm.City>> _cityCont =
      StreamController.broadcast();

  Stream<List<mrm.City>> get cityStream => _cityCont.stream;
  //queries
  late RealmResults<mrm.SettingsModel> settingsQuery;
  late RealmResults<mrm.User> orgUsersQuery;
  late RealmResults<mrm.ActivityModel> orgActivitiesQuery;
  late RealmResults<mrm.Project> orgProjectsQuery;
  late RealmResults<mrm.Photo> photosQuery;
  late RealmResults<mrm.Audio> audiosQuery;
  late RealmResults<mrm.Video> videosQuery;
  late RealmResults<mrm.ProjectPosition> positionsQuery;
  late RealmResults<mrm.ProjectPolygon> polygonsQuery;
  late RealmResults<mrm.City> countryCitiesQuery;
  late RealmResults<mrm.Country> allCountriesQuery;
  late RealmResults<mrm.Photo> orgPhotosQuery;
  late RealmResults<mrm.Video> orgVideosQuery;
  late RealmResults<mrm.Audio> orgAudiosQuery;
  late RealmResults<mrm.ActivityModel> projectActivitiesQuery;
  late RealmResults<mrm.GeofenceEvent> orgGeofenceQuery;
  late RealmResults<mrm.GeofenceEvent> projectGeofenceQuery;
  late RealmResults<mrm.ProjectPosition> orgPositionsQuery;
  late RealmResults<mrm.ProjectPolygon> orgPolygonsQuery;
  late RealmResults<mrm.GioSubscription> orgSubscriptionQuery;
  late RealmResults<mrm.Rating> orgRatingsQuery;
  late RealmResults<mrm.Rating> projectRatingsQuery;
  late RealmResults<mrm.Organization> organizationsQuery;

  var initialized = false;

  Future<bool> initialize() async {
    pp('$mm ........ initialize Realm with Device Sync ....');
    app = rm.App(rm.AppConfiguration(realmAppId));
    realmUser = app.currentUser ?? await app.logIn(rm.Credentials.anonymous());

    final config = rm.Configuration.flexibleSync(realmUser, schemas,
        syncErrorHandler: (SyncError err) {
      pp('\n\n\n$mm ${E.redDot}${E.redDot}${E.redDot}${E.redDot} '
          'Fuck!! Some kind of Realm SyncError; '
          '\n🍎codeValue: ${err.codeValue} '
          '\n🍎message: ${err.message}  '
          '\n🍎category: ${err.category.name} \n\n');
      if (err.stackTrace != null) {
        pp('\n\n$mm STACKTRACE: ${err.stackTrace.toString()}\n\n');
      }
      //todo - handle this error condition!!!!
      switch (err.codeValue) {
        case 226:
          break;
      }
    });

    try {
      Realm.logger.level = RealmLogLevel.detail;
      //todo - use real creds when in prod
      //todo - save realm user in prefs and avoid unnecessary login
      if (await checkDeviceOnline()) {
        // If the device is online, download changes and then open the realm.
        pp('$mm ........ opening Realm with Device Sync ....');
        realmRemote = await Realm.open(config, onProgressCallback: (cb) {
          pp('$mm transferableBytes: ${cb.transferableBytes} transferredBytes: ${cb.transferredBytes}');
        });
      } else {
        // If the device is offline, open the realm immediately
        // and automatically sync changes in the background when the device is online.
        realmRemote = Realm(config);
      }

      pp('\n\n$mm RealmApp configured  🥬 🥬 🥬 🥬; realmUser : $realmUser'
          '\n🌎🌎state: ${realmUser.state.name} '
          '\n🌎🌎accessToken: ${realmUser.accessToken} '
          '\n🌎🌎id:${realmUser.id} \n🌎🌎name:${realmUser.profile.name}');

      for (final schema in realmRemote.schema) {
        pp('$mm RealmApp configured; schema : 🍎🍎${schema.name}');
      }
      pp('\n$mm RealmApp configured OK  🥬 🥬 🥬 🥬: 🔵 ${realmRemote.schema.length} Realm schemas \n\n');
      initialized = true;
      final p = await prefsOGx.getUser();
      if (p != null) {
        _user = OldToRealm.getUser(p);
      }
      return true;
    } catch (e) {
      pp('$mm ${E.redDot}${E.redDot}${E.redDot}${E.redDot} Problem initializing Realm: $e');
    }
    return false;
  }

  static const email = 'aubrey@aftarobot.com',
      password = 'khaya1Son3',
      id = '6478402d6358d2b0e1ba6abe';

  Future<bool> checkDeviceOnline() async {
    return true;
  }

  Future setOrganizationSubscriptions(
      {required String? organizationId,
      required String? projectId,
      required String? countryId,
      required String? startDate}) async {
    try {
      if (!initialized) {
        await initialize();
      }

      final count = realmRemote.subscriptions.length;
      pp('$mm Existing subscriptions: $count !');

      await _updateOrganizationSubscriptions(
          organizationId: organizationId,
          projectId: projectId,
          countryId: countryId,
          startDate: startDate);
      return;
    } catch (e) {
      pp('$mm ${E.redDot}${E.redDot}${E.redDot}${E.redDot} '
          'Problem setting up subscriptions to Realm: $e');
    }
  }

  Future _updateOrganizationSubscriptions(
      {required String? organizationId,
      required String? projectId,
      required String? countryId,
      required String? startDate}) async {

    var start = DateTime.now();
    var user = await prefsOGx.getUser();
    countryCitiesQuery =
        realmRemote.query<mrm.City>("countryId == \$0", [countryId]);
    countryCitiesQuery.changes.listen((event) {
      //pp('$mm changes for countryCitiesQuery delivered: ${event.results.length}');
      final list = <mrm.City>[];
      for (final element in event.results) {
        list.add(element);
      }
      _cityCont.sink.add(list);
    });

    allCountriesQuery = realmRemote.all<mrm.Country>();
    allCountriesQuery.changes.listen((event) {
      //pp('$mm changes for allCountriesQuery delivered: ${event.results.length}');
      final list = <mrm.Country>[];
      for (final element in event.results) {
        list.add(element);
      }
      _countryCont.sink.add(list);
    });
    photosQuery = realmRemote.query<mrm.Photo>("projectId == \$0", [projectId]);
    photosQuery.changes.listen((event) {
      //pp('$mm changes for photosQuery delivered: ${event.results.length}');

      final list = <mrm.Photo>[];
      for (final element in event.results) {
        list.add(element);
      }
      _photoCont.sink.add(list);
    });

    audiosQuery = realmRemote.query<mrm.Audio>("projectId == \$0", [projectId]);
    audiosQuery.changes.listen((event) {
      //pp('$mm changes for audiosQuery delivered: ${event.results.length}');
      final list = <mrm.Audio>[];
      for (final element in event.results) {
        list.add(element);
      }
      _audioCont.sink.add(list);
    });

    videosQuery = realmRemote.query<mrm.Video>("projectId == \$0", [projectId]);
    videosQuery.changes.listen((event) {
      //pp('$mm changes for videosQuery delivered: ${event.results.length}');

      final list = <mrm.Video>[];
      for (final element in event.results) {
        list.add(element);
      }
      _videoCont.sink.add(list);
    });

    projectGeofenceQuery =
        realmRemote.query<mrm.GeofenceEvent>("projectId == \$0", [projectId]);
    projectGeofenceQuery.changes.listen((event) {
      //pp('$mm changes for projectGeofenceQuery delivered: ${event.results.length}');
      final list = <mrm.GeofenceEvent>[];
      for (final element in event.results) {
        list.add(element);
      }
      _geoCont.sink.add(list);
    });
    //
    positionsQuery =
        realmRemote.query<mrm.ProjectPosition>("projectId == \$0", [projectId]);
    positionsQuery.changes.listen((event) {
      final list = <mrm.ProjectPosition>[];
      for (final element in event.results) {
        //pp('$mm changes for positionsQuery delivered: ${event.results.length}');

        list.add(element);
      }
      _positionsCont.sink.add(list);
    });
    polygonsQuery =
        realmRemote.query<mrm.ProjectPolygon>("projectId == \$0", [projectId]);
    polygonsQuery.changes.listen((event) {
      final list = <mrm.ProjectPolygon>[];
      for (final element in event.results) {
        //pp('$mm changes for positionsQuery delivered: ${event.results.length}');

        list.add(element);
      }
      _polCont.sink.add(list);
    });
    //
    projectActivitiesQuery =
        realmRemote.query<mrm.ActivityModel>("projectId == \$0", [projectId]);
    projectActivitiesQuery.changes.listen((event) {
      final list = <mrm.ActivityModel>[];
      for (final element in event.results) {
        //pp('$mm changes for projectActivitiesQuery delivered: ${event.results.length}');
        list.add(element);
      }
      _activityCont.sink.add(list);
    });

    projectRatingsQuery =
        realmRemote.query<mrm.Rating>("projectId == \$0", [projectId]);

    organizationsQuery = realmRemote
        .query<mrm.Organization>("organizationId == \$0", [organizationId]);
    organizationsQuery.changes.listen((event) {
      final list = <mrm.Organization>[];
      ////pp('$mm changes for organizationsQuery delivered: ${event.results.length}');
      for (final element in event.results) {
        list.add(element);
      }
      _orgsCont.sink.add(list);
    });
    settingsQuery = realmRemote
        .query<mrm.SettingsModel>("organizationId == \$0", [organizationId]);
    settingsQuery.changes.listen((event) {
      final list = <mrm.SettingsModel>[];
      pp('$mm changes for settingsQuery delivered: ${event.results.length}');
      for (final element in event.results) {
        list.add(element);
      }
      _settingsCont.sink.add(list);
    });

    orgUsersQuery =
        realmRemote.query<mrm.User>("organizationId == \$0", [organizationId]);
    orgUsersQuery.changes.listen((event) {
      //pp('$mm changes for orgUsersQuery delivered: ${event.results.length}');
      final list = <mrm.User>[];
      for (final element in event.results) {
        list.add(element);
      }
      _userCont.sink.add(list);
    });

    orgPhotosQuery =
        realmRemote.query<mrm.Photo>("organizationId == \$0", [organizationId]);
    orgPhotosQuery.changes.listen((event) {
      //pp('$mm changes for orgPhotosQuery delivered: ${event.results.length}');

      final list = <mrm.Photo>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgPhotoCont.sink.add(list);
    });

    orgVideosQuery =
        realmRemote.query<mrm.Video>("organizationId == \$0", [organizationId]);
    orgVideosQuery.changes.listen((event) {
      //pp('$mm changes for orgVideosQuery delivered: ${event.results.length}');

      final list = <mrm.Video>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgVideoCont.sink.add(list);
    });

    orgAudiosQuery =
        realmRemote.query<mrm.Audio>("organizationId == \$0", [organizationId]);
    orgAudiosQuery.changes.listen((event) {
      //pp('$mm changes for orgAudiosQuery delivered: ${event.results.length}');

      final list = <mrm.Audio>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgAudioCont.sink.add(list);
    });

    orgGeofenceQuery = realmRemote
        .query<mrm.GeofenceEvent>("organizationId == \$0", [organizationId]);
    orgGeofenceQuery.changes.listen((event) {
      //pp('$mm changes for orgGeofenceQuery delivered: ${event.results.length}');
      final list = <mrm.GeofenceEvent>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgGeoCont.sink.add(list);
    });

    orgPositionsQuery = realmRemote
        .query<mrm.ProjectPosition>("organizationId == \$0", [organizationId]);
    orgPositionsQuery.changes.listen((event) {
      //pp('$mm changes for orgPositionsQuery delivered: ${event.results.length}');
      final list = <mrm.ProjectPosition>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgPositionsCont.sink.add(list);
    });

    orgPolygonsQuery = realmRemote
        .query<mrm.ProjectPolygon>("organizationId == \$0", [organizationId]);
    orgPolygonsQuery.changes.listen((event) {
      //pp('$mm changes for orgPolygonsQuery delivered: ${event.results.length}');
      final list = <mrm.ProjectPolygon>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgPolCont.sink.add(list);
    });

    orgActivitiesQuery = realmRemote
        .query<mrm.ActivityModel>("organizationId == \$0", [organizationId]);
    orgActivitiesQuery.changes.listen((event) {
      //pp('$mm changes for orgActivitiesQuery delivered: ${event.results.length}');
      final list = <mrm.ActivityModel>[];
      for (final element in event.results) {
        list.add(element);
      }
      _orgActivityCont.sink.add(list);
    });

    orgProjectsQuery = realmRemote
        .query<mrm.Project>("organizationId == \$0", [organizationId]);
    orgProjectsQuery.changes.listen((event) {
      //pp('$mm changes for orgProjectsQuery delivered: ${event.results.length}');
      final list = <mrm.Project>[];
      for (final element in event.results) {
        list.add(element);
      }
      _projectCont.sink.add(list);
    });

    orgRatingsQuery = realmRemote
        .query<mrm.Rating>("organizationId == \$0", [organizationId]);

    orgSubscriptionQuery = realmRemote
        .query<mrm.GioSubscription>("organizationId == \$0", [organizationId]);

    // Start sync
    //update all PROJECT subs
    realmRemote.subscriptions
        .update((MutableSubscriptionSet mutableSubscriptions) {
      mutableSubscriptions.add(allCountriesQuery,
          name: 'all_countries', update: true);
      mutableSubscriptions.add(countryCitiesQuery,
          name: 'country_cities', update: true);

      mutableSubscriptions.add(projectActivitiesQuery,
          name: 'proj_activities', update: true);

      mutableSubscriptions.add(projectGeofenceQuery,
          name: 'proj_geofences', update: true);

      mutableSubscriptions.add(projectRatingsQuery,
          name: 'proj_ratings', update: true);

      mutableSubscriptions.add(videosQuery, name: 'proj_videos', update: true);

      mutableSubscriptions.add(photosQuery, name: 'proj_photos', update: true);

      mutableSubscriptions.add(audiosQuery, name: 'proj_audios', update: true);

      mutableSubscriptions.add(positionsQuery,
          name: 'proj_positions', update: true);

      mutableSubscriptions.add(polygonsQuery,  name: 'proj_polygons', update: true);

      mutableSubscriptions.add(orgSubscriptionQuery,
          name: 'org_subscriptions', update: true);

      mutableSubscriptions.add(organizationsQuery,
          name: 'organizations', update: true);

      mutableSubscriptions.add(orgPhotosQuery,
          name: 'org_photos', update: true);

      mutableSubscriptions.add(orgVideosQuery,
          name: 'org_videos', update: true);

      mutableSubscriptions.add(orgAudiosQuery,
          name: 'org_audios', update: true);

      mutableSubscriptions.add(orgUsersQuery, name: 'org_users', update: true);

      mutableSubscriptions.add(videosQuery, name: 'proj_videos', update: true);

      mutableSubscriptions.add(photosQuery, name: 'proj_photos', update: true);

      mutableSubscriptions.add(audiosQuery, name: 'proj_audios', update: true);

      mutableSubscriptions.add(orgGeofenceQuery,
          name: 'org_geofence_events', update: true);

      mutableSubscriptions.add(orgPositionsQuery,
          name: 'org_positions', update: true);
      mutableSubscriptions.add(orgPolygonsQuery,
          name: 'org_polygons', update: true);

      mutableSubscriptions.add(orgActivitiesQuery,
          name: 'org_activities', update: true);

      mutableSubscriptions.add(orgProjectsQuery,
          name: 'org_projects', update: true);

      mutableSubscriptions.add(orgRatingsQuery,
          name: 'org_ratings', update: true);

      mutableSubscriptions.add(settingsQuery,
          name: 'org_settings', update: true);
    });

    // Sync all subscriptions
    await realmRemote.subscriptions.waitForSynchronization();
    var end = DateTime.now();
    var diffMs = end.difference(start).inMilliseconds;
    var diffSecs = end.difference(start).inSeconds;

    pp('$mm RealmApp ORGANIZATION waitForSynchronization completed OK  🥬 🥬 🥬 🥬: '
        ' 🛎🛎Queries Subscribed: ${realmRemote.subscriptions.length} '
        '🔵🔵 ELAPSED TIME : $diffMs milliseconds; or $diffSecs seconds');
  }

  mrm.Project? getProject(String projectId) {
    final query =
        realmRemote.query<mrm.Project>("projectId == \$0", [projectId]);
    final list = <mrm.Project>[];
    for (final value in query.toList()) {
      list.add(value);
    }
    pp('$mm project query found: ${list.length}');
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  mrm.Organization? getOrganization(String organizationId) {
    final query = realmRemote
        .query<mrm.Organization>("organizationId == \$0", [organizationId]);
    final list = <mrm.Organization>[];
    for (final value in query.toList()) {
      list.add(value);
    }
    pp('$mm Organization query found: ${list.length}');
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  mrm.User? getUser(String userId) {
    final query = realmRemote.query<mrm.User>("userId == \$0", [userId]);
    final list = <mrm.User>[];
    for (final value in query.toList()) {
      list.add(value);
    }
    pp('$mm user query found: ${list.length}');
    if (list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  RealmResults<mrm.Country> getCountry(String name) {
    late RealmResults<mrm.Country> results;
    realmRemote.write(() {
      results = realmRemote.query('name == \$0', [name]);
    });
    pp('$mm ${results.length} elements in results object');
    return results;
  }

  int addActivities(List<mrm.ActivityModel> activityModels) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(activityModels);
      });
      px('$mm activities added: ${activityModels.length} ');
      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  late mrm.User _user;

  mrm.ActivityModel _getBaseActivity(
      {required String? projectId,
      required String? projectName,
      required String? activityType}) {
    final act = mrm.ActivityModel(
      ObjectId(),
      activityType: activityType,
      projectId: projectId,
      organizationId: _user.organizationId,
      organizationName: _user.organizationName,
      userName: _user.name,
      projectName: projectName,
      userId: _user.userId,
      userType: _user.userType,
      activityModelId: Uuid.v4().toString(),
      intDate: DateTime.now().toUtc().millisecondsSinceEpoch,
      date: DateTime.now().toUtc().toIso8601String(),
      userThumbnailUrl: _user.thumbnailUrl,
    );
    return act;
  }

  int addGeofenceEvents(List<mrm.GeofenceEvent> events) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(events);
      });
      px('$mm geofenceEvents added: ${events.length} ');
      final act = _getBaseActivity(
          projectId: events.first.projectId,
          projectName: events.first.projectName,
          activityType: 'geofenceEventAdded');
      act.geofenceEvent = OldToRealm.getGeofenceString(events.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addRatings(List<mrm.Rating> ratings) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(ratings);
      });
      px('$mm ratings added: ${ratings.length}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addSettings(List<mrm.SettingsModel> settingsModels) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(settingsModels);
      });
      px('$mm settings added: ${settingsModels.length}');
      final act = _getBaseActivity(
          projectId: null, projectName: null, activityType: 'settingsChanged');
      act.settingsModel = OldToRealm.getSettingsString(settingsModels.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: settingsModels activity added : ${act.date}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addPhotos(List<mrm.Photo> photos) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(photos);
      });
      px('$mm photos added: ${photos.length} ');
      final act = _getBaseActivity(
          projectId: photos.first.projectId,
          projectName: photos.first.projectName,
          activityType: 'photoAdded');
      act.photo = OldToRealm.getPhotoString(photos.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: photo activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addVideos(List<mrm.Video> videos) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(videos);
      });
      px('$mm videos added: ${videos.length}');
      final act = _getBaseActivity(
          projectId: videos.first.projectId,
          projectName: videos.first.projectName,
          activityType: 'videoAdded');
      act.video = OldToRealm.getVideoString(videos.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: video activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addAudios(List<mrm.Audio> audios) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(audios);
      });
      px('$mm audios added: ${audios.length}');
      final act = _getBaseActivity(
          projectId: audios.first.projectId,
          projectName: audios.first.projectName,
          activityType: 'audioAdded');
      act.audio = OldToRealm.getAudioString(audios.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: audio activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addProjectPositions(List<mrm.ProjectPosition> projectPositions) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(projectPositions);
      });
      px('$mm ProjectPositions added,: ${projectPositions.length}}');
      final act = _getBaseActivity(
          projectId: projectPositions.first.projectId,
          projectName: projectPositions.first.projectName,
          activityType: 'positionAdded');
      act.projectPosition =
          OldToRealm.getPositionString(projectPositions.first.position!);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addProjectPolygons(List<mrm.ProjectPolygon> projectPolygons) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(projectPolygons);
      });
      px('$mm ProjectPolygons added: ${projectPolygons.length} ');
      final act = _getBaseActivity(
          projectId: projectPolygons.first.projectId,
          projectName: projectPolygons.first.projectName,
          activityType: 'polygonAdded');
      act.projectPolygon =
          OldToRealm.getProjectPolygonString(projectPolygons.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: polygon activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addProjects(List<mrm.Project> projects) {
    try {
      realmRemote.write(() {
        return realmRemote.addAll(projects);
      });
      px('$mm projects added: ${projects.length}');
      final act = _getBaseActivity(
          projectId: projects.first.projectId,
          projectName: projects.first.name,
          activityType: 'projectAdded');
      act.project = OldToRealm.getProjectString(projects.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: project activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  Future<mrm.User> registerOrganization(
      {required mrm.Organization organization, required mrm.User user}) async {
    final start = DateTime.now();
    final loc = await locationBloc.getLocation();

    pp('\n\n$mm 🔵🐦🔵🐦🔵🐦 ORGANIZATION REGISTRATION starting '
        'for ${organization.name} in ${organization.countryName}.......\n');

    try {
      final base = getBaseSettings();
      final sett = mrm.SettingsModel(
        ObjectId(),
        organizationId: organization.organizationId!,
        created: DateTime.now().toUtc().toIso8601String(),
        organizationName: organization.name,
        numberOfDays: base.numberOfDays,
        settingsId: Uuid.v4().toString(),
        themeIndex: base.themeIndex,
        locale: base.locale,
        distanceFromProject: base.distanceFromProject,
        maxVideoLengthInSeconds: base.maxVideoLengthInSeconds,
        maxAudioLengthInMinutes: base.maxAudioLengthInMinutes,
        photoSize: base.photoSize,
        userId: user.userId,
        userName: user.name,
        userUrl: user.thumbnailUrl,
        translatedTitle: 'Settings Changed',
        translatedMessage: 'The settings for the organization',
        refreshRateInMinutes: base.refreshRateInMinutes,
      );
      //
      final sub = mrm.GioSubscription(ObjectId(),
          subscriptionId: Uuid.v4().toString(),
          organizationName: organization.name,
          organizationId: organization.organizationId,
          date: DateTime.now().toUtc().toIso8601String(),
          intDate: DateTime.now().toUtc().millisecondsSinceEpoch,
          active: 0,
          subscriptionType: 0,
          user: OldToRealm.getUserString(user));

      //
      final objects = await _buildSampleProject(
          organization: organization,
          latitude: loc.latitude,
          longitude: loc.longitude,
          user: user);

      final act = mrm.ActivityModel(
        rm.ObjectId(),
        organizationId: organization.organizationId,
        activityType: 'originalRegistration',
        settingsModel: OldToRealm.getSettingsString(sett),
        intDate: DateTime.now().toUtc().millisecondsSinceEpoch,
        date: DateTime.now().toUtc().toIso8601String(),
        organizationName: organization.name,
        userName: user.name,
        userId: user.userId,
        user: OldToRealm.getUserString(user),
        userType: user.userType,
      );

      pp('\n$mm 🔵🐦🔵🐦🔵🐦 The Big Realm Transaction about to launch:!!!! 🔵🐦🔵🐦🔵🐦 '
          '... will update subscriptions with org: ${organization.name}');
      final startDate = DateTime.now()
          .subtract(const Duration(hours: 3))
          .toUtc()
          .toIso8601String();

      await setOrganizationSubscriptions(
          organizationId: organization.organizationId!,
          projectId: null, countryId: null,
          startDate: null);

      final bigResult = await realmRemote.writeAsync(() {
        realmRemote.add<mrm.User>(user);
        realmRemote.add<mrm.Organization>(organization);
        realmRemote.add<mrm.SettingsModel>(sett);
        realmRemote.add<mrm.GioSubscription>(sub);
        realmRemote.add<mrm.Project>(objects.$1);
        realmRemote.add<mrm.ProjectPosition>(objects.$2);
        realmRemote.add<mrm.ActivityModel>(act);
      });

      pp('\n\n$mm 🔵🐦🔵🐦🔵🐦 The Eagle has landed! 🍎🍎 bigResult: $bigResult');
      _checkFinalResults(organization);
      //

      await prefsOGx.saveUser(user);
      final end = DateTime.now();
      final deltaInSeconds = end.difference(start).inSeconds;
      pp('\n$mm 🔵🐦🔵🐦🔵🐦 $uu Time elapsed for Registration: $deltaInSeconds seconds');
      pp('\n$mm 🔵🐦🔵🐦🔵🐦 ORGANIZATION REGISTERED; YEBO!!!! 🔵🐦🔵🐦🔵🐦\n\n');

      return user;
    } catch (e) {
      _handleError(e);
    }
    throw Exception('${E.redDot} registration failed');
  }

  void _checkFinalResults(mrm.Organization organization) {
    final users = getUsers(organization.organizationId!);
    final projects = getProjects(organization.organizationId!);

    final List<mrm.SettingsModel> settings = [];
    realmRemote.write(() {
      var res = realmRemote.all<mrm.SettingsModel>();
      for (var value in res) {
        settings.add(value);
      }
    });
    final List<mrm.Organization> orgs = [];
    realmRemote.write(() {
      var res = realmRemote.all<mrm.Organization>();
      for (var value in res) {
        orgs.add(value);
      }
    });
    final List<mrm.ProjectPosition> positions = [];
    realmRemote.write(() {
      var res = realmRemote.all<mrm.ProjectPosition>();
      for (var value in res) {
        positions.add(value);
      }
    });
    final List<mrm.GioSubscription> subscriptions = [];
    realmRemote.write(() {
      var res = realmRemote.all<mrm.GioSubscription>();
      for (var value in res) {
        subscriptions.add(value);
      }
    });
    final List<mrm.ActivityModel> acts = [];
    realmRemote.write(() {
      final res = realmRemote.all<mrm.ActivityModel>();
      for (final value in res) {
        acts.add(value);
      }
    });

    pp('$mm Check results of registration: 🍎🍎 '
        '\n $uu organizations: ${orgs.length} '
        '\n $uu users: ${users.length} '
        '\n $uu settings: ${settings.length} '
        '\n $uu subscriptions: ${subscriptions.length} '
        '\n $uu projects: ${projects.length} '
        '\n $uu activities: ${acts.length} '
        '\n $uu positions: ${positions.length}');
  }

  static const uu = 'RESULT: 🔷 🔷 🔷';

  Future<(mrm.Project, mrm.ProjectPosition)> _buildSampleProject(
      {required mrm.Organization organization,
      required double latitude,
      required double longitude,
      required mrm.User user}) async {
    //todo - get Nearest cities
    final m = await dataApiDog.findCitiesByLocation(
        latitude: latitude, longitude: longitude, radiusInKM: 60);
    px('$mm got back nearest cities: ${m.length} .......');

    final nearestCities = <String>[];
    for (final value in m) {
      final city = OldToRealm.getCity(value);
      nearestCities.add(OldToRealm.getCityString(city));
    }
    px('$mm ......... build sample project:  🍎 ....... cities: ${nearestCities.length}');

    final df = getFormattedDateHour(DateTime.now().toIso8601String());

    try {
      final proj = mrm.Project(
        ObjectId(),
        name: '🌎🌎Sample Project 🍎 $df',
        organizationName: organization.name,
        organizationId: organization.organizationId,
        projectId: Uuid.v4().toString(),
        created: DateTime.now().toUtc().toIso8601String(),
        monitorMaxDistanceInMetres: 100,
        userName: user.name,
        userUrl: user.thumbnailUrl,
        userId: user.userId,
        description: 'Sample Project to help you learn about Gio and to '
            'practice the app features before you set up your own project',
        nearestCities: nearestCities,
      );

      px('$mm build sample project position:.......');

      final projPosition = mrm.ProjectPosition(
        ObjectId(),
        projectPositionId: Uuid.v4().toString(),
        projectId: proj.projectId,
        created: DateTime.now().toUtc().toIso8601String(),
        organizationId: proj.organizationId,
        organizationName: proj.organizationName,
        name: proj.name,
        projectName: proj.name,
        userId: user.userId,
        userName: user.name,
        userUrl: user.thumbnailUrl,
        possibleAddress: 'Not implemented yet',
        nearestCities: nearestCities,
        position: mrm.Position(
          type: 'Point',
          coordinates: [longitude, latitude],
          latitude: latitude,
          longitude: longitude,
        ),
      );

      return (proj, projPosition);
    } catch (e) {
      _handleError(e);
    }
    //todo translate Sample Project
    throw Exception(
        '${E.redDot} unable to create project and position objects');
  }

  final err = '🍎🍎🍎🍎 Realm Error 🍎🍎🍎🍎';

  int addUsers(List<mrm.User> users) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(users);
      });
      px('$mm users added: ${users.length}');
      final act = _getBaseActivity(
          projectId: null,
          projectName: null,
          activityType: 'userAddedOrModified');
      act.user = OldToRealm.getUserString(users.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: user activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addOrganizations(List<mrm.Organization> organizations) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(organizations);
      });
      px('$mm organizations added: ${organizations.length}');
      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addLocationRequests(List<mrm.LocationRequest> requests) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(requests);
      });
      px('$mm requests added: ${requests.length}');
      final act = _getBaseActivity(
          projectId: null, projectName: null, activityType: 'locationRequest');
      act.locationRequest = OldToRealm.getLocationRequestString(requests.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: locationRequest activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addLocationResponses(List<mrm.LocationResponse> responses) {
    try {
      realmRemote.write(() {
        realmRemote.addAll(responses);
      });
      px('$mm responses added: ${responses.length}');
      final act = _getBaseActivity(
          projectId: null, projectName: null, activityType: 'locationResponse');
      act.locationResponse =
          OldToRealm.getLocationResponseString(responses.first);
      realmSyncApi.addActivities([act]);
      pp('$mm realmSyncApi: activity added : ${act.date} - ${act.projectName}');

      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addCountries(List<mrm.Country> countries) {
    try {
      if (countries.length == 1) {
        realmRemote.write(() {
          return realmRemote.add(countries.first);
        });
      } else {
        realmRemote.write(() {
          return realmRemote.addAll(countries);
        });
        px('$mm Countries added to Realm: 🔶 ${countries.length} countries');
      }
      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  int addCities(List<mrm.City> cities) {
    try {
      if (cities.length == 1) {
        realmRemote.write(() {
          return realmRemote.add(cities.first);
        });
      } else {
        realmRemote.write(() {
          return realmRemote.addAll(cities);
        });
        px('$mm Cities added to Realm: 🔶 ${cities.length} cities');
      }
      return 0;
    } catch (e) {
      _handleError(e);
    }
    return 1;
  }

  Future<void> updateUser({required mrm.User user, required String imageUrl,
    required String thumbUrl}) async {

    await realmRemote.writeAsync(() {
      user.imageUrl = imageUrl;
      user.thumbnailUrl = thumbUrl;
      realmRemote.add<mrm.User>(user, update: true);
    });
    getUsers(user.organizationId!);
    pp('$mm user has been updated');
  }
  void deleteCountries() {
    pp('$mm DELETE all countries ...');
    realmRemote.write(() {
      realmRemote.deleteAll<mrm.Country>();
    });
    pp('$mm all countries deleted ...');
    realmRemote.write(() {
      final s = realmRemote.all<mrm.Country>();
      pp('$mm check countries deleted: ... ${s.length}; cool if ZERO!');
    });
  }

  List<mrm.Country> getCountries() {
    px('$mm ....................  😡 getCountries ... ');

    final result = realmRemote.all<mrm.Country>();
    final list = <mrm.Country>[];
    for (final value in result.toList()) {
      list.add(value);
    }
    px('$mm countries found in Realm:  😡 ${list.length} 😡');
    _countryCont.sink.add(list);
    return list;
  }

  List<mrm.Project> getProjects(String organizationId) {
    final result = realmRemote
        .query<mrm.Project>("organizationId == \$0", [organizationId]);
    final list = <mrm.Project>[];
    for (final value in result.toList()) {
      list.add(value);
    }
    px('$mm projects found in Realm: ${list.length}');
    _projectCont.sink.add(list);
    return list;
  }

  List<mrm.User> getUsers(String organizationId) {
    final result = realmRemote.query<mrm.User>("organizationId == \$0", [
      organizationId,
    ]);
    final list = <mrm.User>[];
    for (final value in result.toList()) {
      list.add(value);
    }
    px('$mm users found in Realm: ${list.length}');
    _orgUserStreamController.sink.add(list);

    return list;
  }



  List<mrm.ActivityModel> getOrganizationActivities(
      {required String organizationId}) {
    final result = realmRemote
        .query<mrm.ActivityModel>("organizationId == \$0", [organizationId]);
    final list = <mrm.ActivityModel>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm Activities found in Realm: ${list.length}');
    list.sort((a, b) => b.date!.compareTo(a.date!));
    _orgActivityCont.sink.add(list);

    return list;
  }

  List<mrm.GeofenceEvent> getOrganizationGeofenceEvents(
      {required String organizationId}) {
    final result = realmRemote
        .query<mrm.GeofenceEvent>("organizationId == \$0", [organizationId]);
    final list = <mrm.GeofenceEvent>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm GeofenceEvents found in Realm: ${list.length}');
    _orgGeoCont.sink.add(list);

    return list;
  }

  List<mrm.ProjectPosition> getOrganizationPositions(
      {required String organizationId}) {
    final result = realmRemote
        .query<mrm.ProjectPosition>("organizationId == \$0", [organizationId]);
    final list = <mrm.ProjectPosition>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm ProjectPositions found in Realm: ${list.length}');
    _orgPositionsCont.sink.add(list);

    return list;
  }

  List<mrm.ProjectPolygon> getOrganizationPolygons(
      {required String organizationId}) {
    final result = realmRemote
        .query<mrm.ProjectPolygon>("organizationId == \$0", [organizationId]);
    final list = <mrm.ProjectPolygon>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm ProjectPolygons found in Realm: ${list.length}');
    _orgPolCont.sink.add(list);

    return list;
  }

  List<mrm.Photo> getOrganizationPhotos({required String organizationId}) {
    final result =
        realmRemote.query<mrm.Photo>("organizationId == \$0", [organizationId]);
    final list = <mrm.Photo>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm org Photos found in Realm: ${list.length}');
    _orgPhotoCont.sink.add(list);

    return list;
  }

  List<mrm.Video> getOrganizationVideos({required String organizationId}) {
    final result =
        realmRemote.query<mrm.Video>("organizationId == \$0", [organizationId]);
    final list = <mrm.Video>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm org Videos found in Realm: ${list.length}');
    _orgVideoCont.sink.add(list);

    return list;
  }

  List<mrm.Audio> getOrganizationAudios({required String organizationId}) {
    final result =
        realmRemote.query<mrm.Audio>("organizationId == \$0", [organizationId]);
    final list = <mrm.Audio>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm org Audios found in Realm: ${list.length}');
    _orgAudioCont.sink.add(list);

    return list;
  }

  List<mrm.User> getOrganizationUsers({required String organizationId}) {
    final result =
        realmRemote.query<mrm.User>("organizationId == \$0", [organizationId]);
    final list = <mrm.User>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm org Users found in Realm: ${list.length}');
    _orgUserStreamController.sink.add(list);

    return list;
  }

  mrm.SettingsModel? getLatestOrganizationSettings(
      {required String organizationId}) {
    final result = realmRemote
        .query<mrm.SettingsModel>("organizationId == \$0", [organizationId]);
    final list = <mrm.SettingsModel>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm SettingsModels found in Realm: ${list.length}');
    if (list.isNotEmpty) {
      list.sort((a, b) => b.created!.compareTo(a.created!));
      _settingsCont.sink.add(list);
      return list.first;
    }

    return null;
  }

  List<mrm.ActivityModel> getProjectActivities(
      {required String projectId, required int numberOfHours}) {
    final map = getStartEndDatesFromHours(numberOfHours: numberOfHours);
    final result = realmRemote.query<mrm.ActivityModel>(
        "projectId == \$0 AND date >= \$1", [projectId, map.$1]);
    final list = <mrm.ActivityModel>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm Activities found in Realm: ${list.length}');
    list.sort((a, b) => b.date!.compareTo(a.date!));
    _activityCont.sink.add(list);

    return list;
  }

  List<mrm.GeofenceEvent> getProjectGeofenceEvents(
      {required String projectId, required int numberOfDays}) {
    final map = getStartEndDatesFromDays(numberOfDays: numberOfDays);
    final result = realmRemote.query<mrm.GeofenceEvent>(
      "(projectId == \$0 AND date >= \$1",
      [
        projectId,
        map.$1,
      ],
    );

    final list = <mrm.GeofenceEvent>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm GeofenceEvents found in Realm: ${list.length}');
    list.sort((a, b) => b.date!.compareTo(a.date!));
    _geoCont.sink.add(list);

    return list;
  }

  List<mrm.ProjectPosition> getProjectPositions({required String projectId}) {
    final result = realmRemote.query<mrm.ProjectPosition>(
      "(projectId == \$0",
      [projectId],
    );
    final list = <mrm.ProjectPosition>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm ProjectPositions found in Realm: ${list.length}');
    list.sort((a, b) => b.created!.compareTo(a.created!));
    _positionsCont.sink.add(list);
    return list;
  }

  List<mrm.ProjectPolygon> getProjectPolygons({required String projectId}) {
    final result = realmRemote.query<mrm.ProjectPolygon>(
      "(projectId == \$0",
      [projectId],
    );
    final list = <mrm.ProjectPolygon>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm ProjectPolygons found in Realm: ${list.length}');
    list.sort((a, b) => b.created!.compareTo(a.created!));
    _polCont.sink.add(list);
    return list;
  }

  List<mrm.Photo> getProjectPhotos(
      {required String projectId, required int numberOfDays}) {
    final map = getStartEndDatesFromDays(numberOfDays: numberOfDays);
    final result = realmRemote.query<mrm.Photo>(
        "projectId >= \$0 AND created >= \$1", [projectId, map.$1]);
    final list = <mrm.Photo>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }

    px('$mm Photos found in Realm: ${list.length}');
    list.sort((a, b) => b.created!.compareTo(a.created!));
    _photoCont.sink.add(list);
    return list;
  }

  List<mrm.Video> getProjectVideos(
      {required String projectId, required int numberOfDays}) {
    final map = getStartEndDatesFromDays(numberOfDays: numberOfDays);
    final result = realmRemote.query<mrm.Video>(
        "projectId >= \$0 AND created >= \$1", [projectId, map.$1]);
    final list = <mrm.Video>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }
    px('$mm Videos found in Realm: ${list.length}');
    list.sort((a, b) => b.created!.compareTo(a.created!));

    _videoCont.sink.add(list);
    return list;
  }

  List<mrm.Audio> getProjectAudios(
      {required String projectId, required int numberOfDays}) {
    final map = getStartEndDatesFromDays(numberOfDays: numberOfDays);
    final result = realmRemote.query<mrm.Audio>(
        "projectId >= \$0 AND created >= \$1", [projectId, map.$1]);
    final list = <mrm.Audio>[];
    final resList = result.toList();
    for (final value in resList) {
      list.add(value);
    }

    px('$mm Audios found in Realm: ${list.length}');
    list.sort((a, b) => b.created!.compareTo(a.created!));

    _audioCont.sink.add(list);
    return list;
  }

  void _handleError(Object e) {
    if (e is rm.RealmException) {
      pp('$err RealmException happened! : ${e.message}');
      if (e.message.contains('1013')) {
        //pp('$err Object already exists: $e');
      } else {
        pp('$err handle Realm error: $err $e');
        errorHandler.handleError(
            exception: GeoException(
                message: 'Realm error: $e',
                translationKey: 'realmExists',
                errorType: 'duplicate',
                url: ''));

        throw Exception('${E.redDot} Realm Error: $e');
      }
    } else {
      pp('$err handle unknown error (is not RealmException ): $e');
      errorHandler.handleError(
          exception: GeoException(
              message: 'Unknown error: $e',
              translationKey: 'unknownError',
              errorType: 'deviceError',
              url: ''));

      throw Exception('${E.redDot} Local Error: $e');
    }
  }
}
