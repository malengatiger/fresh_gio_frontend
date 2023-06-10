import 'dart:async';

import 'package:freshgio/library/api/data_api_og.dart';
import 'package:freshgio/library/bloc/geo_exception.dart';
import 'package:freshgio/library/bloc/old_to_realm.dart';
import 'package:freshgio/library/data/settings_model.dart';
import 'package:freshgio/library/errors/error_handler.dart';
import 'package:freshgio/realm_data/data/schemas.dart' as mrm;
import 'package:geofence_service/geofence_service.dart';
import 'package:geofence_service/models/geofence.dart' as geo;
import 'package:realm/realm.dart';

import '../../device_location/device_location_bloc.dart';
import '../../l10n/translation_handler.dart';
import '../../realm_data/data/realm_sync_api.dart';
import '../api/prefs_og.dart';
import '../functions.dart';

final geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

late TheGreatGeofencer theGreatGeofencer;

class TheGreatGeofencer {
  final xx = '😡😡😡😡😡😡😡 TheGreatGeofencer:  🔱 🔱 ';

  final DataApiDog dataApiDog;
  final PrefsOGx prefsOGx;
  final RealmSyncApi realmSyncApi;

  final StreamController<mrm.GeofenceEvent> _streamController =
      StreamController.broadcast();

  TheGreatGeofencer(this.prefsOGx, this.realmSyncApi, this.dataApiDog);

  Stream<mrm.GeofenceEvent> get geofenceEventStream => _streamController.stream;

  final _geofenceList = <geo.Geofence>[];
  mrm.User? _user;
  late SettingsModel settingsModel;

  Future<List<mrm.ProjectPosition>> _findProjectPositionsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    var mList = await dataApiDog.findProjectPositionsByLocation(
        organizationId: organizationId,
        latitude: latitude,
        longitude: longitude,
        radiusInKM: radiusInKM);
    pp('$xx _getProjectPositionsByLocation: found ${mList.length}\n');
    final fList = <mrm.ProjectPosition>[];
    for (var value in mList) {
      fList.add(OldToRealm.getProjectPosition(value));
    }
    return fList;
  }

  Future buildGeofences({double? radiusInKM}) async {
    pp('$xx buildGeofences .... build geofences for the organization started ... 🌀 ');
    var p = await prefsOGx.getUser();
    _user = OldToRealm.getUser(p!);
    settingsModel = await prefsOGx.getSettings();
    if (_user == null) {
      return;
    }


    var finalList = <mrm.ProjectPosition>[];
    var loc = await locationBloc.getLocation();
    finalList = await _findProjectPositionsByLocation(
        organizationId: _user!.organizationId!,
        latitude: loc.latitude,
        longitude: loc.longitude!,
        radiusInKM: radiusInKM ?? 50);

    pp('$xx buildGeofences .... project positions found by location: ${finalList.length} ');
    if (finalList.isEmpty) {
      finalList = realmSyncApi.getOrganizationPositions(
        organizationId: _user!.organizationId!,
      );
    }

    int cnt = 0;
    for (var pos in finalList) {
      await addGeofence(
          projectPosition: pos,
          radius: settingsModel.distanceFromProject!.toDouble());
      cnt++;
      if (cnt > 98) {
        break;
      }
    }

    pp('\n$xx ${_geofenceList.length} geofences added to service\n');
    geofenceService.addGeofenceList(_geofenceList);

    geofenceService.addGeofenceStatusChangeListener(
        (geofence, geofenceRadius, geofenceStatus, location) async {
      pp('$xx Geofence Listener 💠 FIRED!! '
          '🔵🔵🔵 geofenceStatus: ${geofenceStatus.name}  at 🔶 ${geofence.data['projectName']}');
      await _processGeofenceEvent(
          geofence: geofence,
          geofenceRadius: geofenceRadius,
          geofenceStatus: geofenceStatus,
          location: location);
    });

    try {
      pp('$xx  🔶🔶🔶🔶🔶🔶 Starting GeofenceService ...... 🔶🔶🔶🔶🔶🔶 ');
      await geofenceService.start().onError((error, stackTrace) => errorHandler.handleError(
                exception: GeoException(
                    message: 'No location available, geofenceEvent failed',
                    translationKey: 'serverProblem',
                    errorType: GeoException.formatException,
                    url: '/geo/v1/addGeofenceEvent'))
          );

      // pp('$xx ✅✅✅✅✅✅ geofences 🍐🍐🍐 STARTED OK 🍐🍐🍐 '
      //     '🔆🔆🔆 will wait for geofence status changes ... 🔵🔵🔵🔵🔵 ');
    } catch (e) {
      pp('\n\n$xx GeofenceService failed to start: 🔴 $e 🔴 }');
      errorHandler.handleError(
          exception: GeoException(
              message: 'GeofenceService failed to start',
              translationKey: 'serverProblem',
              errorType: GeoException.formatException,
              url: 'n/a'));
    }
  }

  final reds = '🔴 🔴 🔴 🔴 🔴 🔴 TheGreatGeofencer: ';

  void onError() {}

  Future _processGeofenceEvent(
      {required Geofence geofence,
      required GeofenceRadius geofenceRadius,
      required GeofenceStatus geofenceStatus,
      required Location location}) async {
    pp('$xx _processing new GeofenceEvent; 🔵 ${geofence.data['projectName']} '
        '🔵geofenceStatus: ${geofenceStatus.toString()}');

    var loc = await locationBloc.getLocation();
    //todo use org settings rather than possibly changed settings from prefs
    final sett = await prefsOGx.getSettings();
    var orgSetting = realmSyncApi.getLatestOrganizationSettings(
        organizationId: sett.organizationId!);
    if (orgSetting != null) {
      final settings = orgSetting;
      String message =
          'A member has arrived at ${geofence.data['projectName']}';
      String title = 'Message from Gio';
      final arr = await translator.translate('arrivedAt', settings.locale!);
      message = arr.replaceAll('\$project', geofence.data['projectName']);
      final tit =
          await translator.translate('messageFromGeo', settings.locale!);
      title = tit.replaceAll('\$geo', 'Gio');

      var event = mrm.GeofenceEvent(ObjectId(),
          status: geofenceStatus.toString(),
          organizationId: settings.organizationId,
          translatedMessage: message,
          userId: _user!.userId!,
          userUrl: _user!.thumbnailUrl,
          userName: _user!.name,
          position: mrm.Position(
              coordinates: [loc.longitude, loc.latitude], type: 'Point'),
          geofenceEventId: Uuid.v4().toString(),
          projectPositionId: geofence.id,
          projectId: geofence.data['projectId'],
          projectName: geofence.data['projectName'],
          date: DateTime.now().toUtc().toIso8601String(),
          translatedTitle: title);

      String status = geofenceStatus.toString();
      switch (status) {
        case 'GeofenceStatus.ENTER':
          event.status = 'ENTER';
          pp('$xx IGNORING geofence ENTER event for ${event.projectName}');
          break;
        case 'GeofenceStatus.DWELL':
          event.status = 'DWELL';
          addObject(event);
          break;
        case 'GeofenceStatus.EXIT':
          event.status = 'EXIT';
          addObject(event);
          break;
      }
      //
      final act = mrm.ActivityModel(ObjectId(),
      geofenceEvent: OldToRealm.getGeofenceString(event),
        projectId: event.projectId,
        organizationId: event.organizationId,
        organizationName: _user!.organizationName,
        userName: _user!.name,
        projectName: event.projectName,
        userId: _user!.userId,
        userType: _user!.userType,
        activityModelId: Uuid.v4().toString(),
        intDate: DateTime.now().toUtc().millisecondsSinceEpoch,
        date: DateTime.now().toUtc().toIso8601String(),
        userThumbnailUrl: _user!.thumbnailUrl,
      );
      realmSyncApi.addActivities([act]);
      pp('$xx realmSyncApi: activity added : ${act.date} - ${act.projectName}');
    }
  }

  Future addObject(mrm.GeofenceEvent event) async {
    pp('$xx about to send geofence event to backend ... ');
    try {
      realmSyncApi.addGeofenceEvents([event]);
      pp('$xx realmSyncApi: geofence event added to database for '
          '${event.projectName} - 🍎 ${event.date} 🍎');
      _streamController.sink.add(event);
    } catch (e) {
      pp('$xx failed to add geofence event');
      if (e is GeoException) {
        errorHandler.handleError(exception: e);
      } else {
        errorHandler.handleError(
            exception: GeoException(
                message: 'Failed to add geofenceEvent: $e',
                translationKey: 'serverProblem',
                errorType: GeoException.httpException,
                url: getUrl()));
      }
    }
  }

  Future addGeofence(
      {required mrm.ProjectPosition projectPosition,
      required double radius}) async {

    if (projectPosition.position != null) {
      var data = {
        'projectId': projectPosition.projectId,
        'projectName': projectPosition.projectName,
        'organizationId': projectPosition.organizationId,
        'userId': _user!.userId,
        'userName': _user!.name,
        'userUrl': _user!.thumbnailUrl,
        'dateGeofenceAdded': DateTime.now().toUtc().toIso8601String(),
      };
      var fence = Geofence(
        id: '${projectPosition.projectId!}_${DateTime.now().microsecondsSinceEpoch}',
        data: data,
        latitude: projectPosition.position!.coordinates[1],
        longitude: projectPosition.position!.coordinates[0],
        radius: [
          GeofenceRadius(id: 'radius_from_settings', length: radius),
        ],
      );

      _geofenceList.add(fence);

    } else {
      pp('🔴🔴🔴🔴🔴🔴 project position is null, WTF??? ${projectPosition.projectName}');
    }
  }

  var defaultRadiusInKM = 100.0;
  var defaultRadiusInMetres = 150.0;
  var defaultDwellInMilliSeconds = 30;

  close() {
    _streamController.close();
  }
}
