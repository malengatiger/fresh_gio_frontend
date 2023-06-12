import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:freshgio/library/api/prefs_og.dart';
import 'package:freshgio/library/bloc/geo_exception.dart';
import 'package:freshgio/library/data/activity_model.dart';
import 'package:freshgio/library/data/app_error.dart';
import 'package:freshgio/library/data/data_counts.dart';
import 'package:freshgio/library/data/location_request.dart';
import 'package:freshgio/library/data/organization_registration_bag.dart';
import 'package:freshgio/library/data/project_polygon.dart';
import 'package:freshgio/library/data/project_summary.dart';
import 'package:freshgio/library/data/stitch/payment_request.dart';
import 'package:freshgio/library/data/subscription.dart';
import 'package:freshgio/library/errors/error_handler.dart';
import 'package:freshgio/realm_data/data/schemas.dart' as mrm;
import 'package:http/http.dart' as http;
import 'package:realm/realm.dart';

import '../auth/app_auth.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/project_bloc.dart';
import '../bloc/user_bloc.dart';
import '../cache_manager.dart';
import '../data/audio.dart';
import '../data/city.dart';
import '../data/community.dart';
import '../data/condition.dart';
import '../data/counters.dart';
import '../data/country.dart';
import '../data/data_bag.dart';
import '../data/field_monitor_schedule.dart';
import '../data/geofence_event.dart';
import '../data/kill_response.dart';
import '../data/location_response.dart';
import '../data/org_message.dart';
import '../data/organization.dart';
import '../data/photo.dart';
import '../data/pricing.dart';
import '../data/project.dart';
import '../data/project_position.dart';
import '../data/questionnaire.dart';
import '../data/rating.dart';
import '../data/section.dart';
import '../data/settings_model.dart';
import '../data/translation_bag.dart';
import '../data/user.dart' as ur;
import '../data/video.dart';
import '../data/weather/daily_forecast.dart';
import '../data/weather/hourly_forecast.dart';
import '../emojis.dart';
import '../functions.dart';
import '../utilities/environment.dart';

late DataApiDog dataApiDog;

/// Handles all data requests to backend api using Riverpod
///

class DataApiDog {
  static const mm = '❤️❤️❤️ DataApiDog: ❤️: ';
  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };
  Map<String, String> zipHeaders = {
    'Content-type': 'application/json',
    'Accept': 'application/zip',
  };

  late String url;
  static const timeOutInSeconds = 120;

  final http.Client client;
  final AppAuth appAuth;
  final CacheManager cacheManager;
  final PrefsOGx prefsOGx;
  final ErrorHandler errorHandler;

  DataApiDog(this.client, this.appAuth, this.cacheManager, this.prefsOGx,
      this.errorHandler) {
    if (GioEnv.currentStatus == 'dev') {
      url = GioEnv.devUrl;
    } else {
      url = GioEnv.prodUrl;
    }
    pp('$mm DataApiDog constructed! url: $url');
  }

  String shoutOut() {
    return '🌺🌺🌺 Hey! I am a RiverPod Provider for managing database data!';
  }

  Future<FieldMonitorSchedule> addFieldMonitorSchedule(
      FieldMonitorSchedule monitorSchedule) async {
    Map bag = monitorSchedule.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');
    var result = await _callWebAPIPost('${url!}addFieldMonitorSchedule', bag);
    var s = FieldMonitorSchedule.fromJson(result);
    await cacheManager.addFieldMonitorSchedule(schedule: s);
    return s;
  }

  Future<SettingsModel> addSettings(SettingsModel settings) async {
    Map bag = settings.toJson();
    var result = await _callWebAPIPost('${url!}addSettings', bag);
    pp('$xz $result');
    var s = SettingsModel.fromJson(result);
    pp('$xz settings from db: ${s.toJson()}');
    await cacheManager.addSettings(settings: s);
    return s;
  }

  Future<GioPaymentRequest> addPaymentRequest(
      GioPaymentRequest paymentRequest) async {
    Map bag = paymentRequest.toJson();

    var result = await _callWebAPIPost('${url}addPaymentRequest', bag);
    var s = GioPaymentRequest.fromJson(result);
    return s;
  }

  Future<GioSubscription> addSubscription(GioSubscription subscription) async {
    Map bag = subscription.toJson();

    var result = await _callWebAPIPost('${url!}addSubscription', bag);
    var s = GioSubscription.fromJson(result);
    await prefsOGx.saveGioSubscription(s);
    return s;
  }

  Future<GioSubscription> updateSubscription(
      GioSubscription subscription) async {
    Map bag = subscription.toJson();

    var result = await _callWebAPIPost('${url!}updateSubscription', bag);
    var s = GioSubscription.fromJson(result);
    await prefsOGx.saveGioSubscription(s);
    return s;
  }

  Future<GioSubscription> activateSubscription(
      GioSubscription subscription) async {
    Map bag = subscription.toJson();

    var result = await _callWebAPIPost('${url!}activateSubscription', bag);
    var s = GioSubscription.fromJson(result);
    await prefsOGx.saveGioSubscription(s);
    return s;
  }

  Future<GioSubscription> deActivateSubscription(
      GioSubscription subscription) async {
    Map bag = subscription.toJson();

    var result = await _callWebAPIPost('${url!}deActivateSubscription', bag);
    var s = GioSubscription.fromJson(result);
    await prefsOGx.saveGioSubscription(s);
    return s;
  }

  Future<List<Pricing>> getPricing(String countryId) async {
    List<Pricing> mList = [];

    List result =
        await _sendHttpGET('${url!}getCountryPricing?countryId=$countryId');
    for (var element in result) {
      mList.add(Pricing.fromJson(element));
    }
    pp('🌿 🌿 🌿 getPricing returned: 🌿 ${mList.length}');
    mList.sort((a, b) => b.date!.compareTo(a.date!));
    return mList;
  }

  Future<GeofenceEvent> addGeofenceEvent(GeofenceEvent geofenceEvent) async {
    Map bag = geofenceEvent.toJson();

    var result = await _callWebAPIPost('${url!}addGeofenceEvent', bag);
    var s = GeofenceEvent.fromJson(result);
    await cacheManager.addGeofenceEvent(geofenceEvent: s);
    return s;
  }

  Future<LocationResponse> addLocationResponse(
      LocationResponse response) async {
    Map bag = response.toJson();

    var result = await _callWebAPIPost('${url!}addLocationResponse', bag);
    var s = LocationResponse.fromJson(result);
    await cacheManager.addLocationResponse(locationResponse: s);
    return s;
  }

  Future<List<FieldMonitorSchedule>> getProjectFieldMonitorSchedules(
      String projectId) async {
    List<FieldMonitorSchedule> mList = [];

    List result = await _sendHttpGET(
        '${url!}getProjectFieldMonitorSchedules?projectId=$projectId');
    for (var element in result) {
      mList.add(FieldMonitorSchedule.fromJson(element));
    }
    pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
    await cacheManager.addFieldMonitorSchedules(schedules: mList);
    return mList;
  }

  Future<List<FieldMonitorSchedule>> getUserFieldMonitorSchedules(
      String userId) async {
    List<FieldMonitorSchedule> mList = [];
    List result = await _sendHttpGET(
        '${url!}getUserFieldMonitorSchedules?projectId=$userId');
    for (var element in result) {
      mList.add(FieldMonitorSchedule.fromJson(element));
    }
    pp('🌿 🌿 🌿 getProjectFieldMonitorSchedules returned: 🌿 ${mList.length}');
    await cacheManager.addFieldMonitorSchedules(schedules: mList);
    return mList;
  }

  Future<String> testUploadPhoto() async {
    dynamic result;
    result = await _sendHttpGET('${url!}testUploadPhoto');

    pp('$xz 🌿🌿🌿 testUploadPhoto returned: 🌿 $result');
    return result["url"];
  }

  Future<List<FieldMonitorSchedule>> getMonitorFieldMonitorSchedules(
      String userId) async {
    List<FieldMonitorSchedule> mList = [];
    List result = await _sendHttpGET(
        '${url!}getMonitorFieldMonitorSchedules?userId=$userId');
    for (var element in result) {
      mList.add(FieldMonitorSchedule.fromJson(element));
    }
    pp('🌿 🌿 🌿 getMonitorFieldMonitorSchedules returned: 🌿 ${mList.length}');
    await cacheManager.addFieldMonitorSchedules(schedules: mList);
    return mList;
  }

  Future<List<TranslationBag>> getTranslationBags() async {
    List<TranslationBag> mList = [];
    List result = await _sendHttpGET('${url!}getTranslationBags');
    for (var element in result) {
      mList.add(TranslationBag.fromJson(element));
    }
    pp('🌿 🌿 🌿 getTranslationBags returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<SettingsModel>> getOrganizationSettings(
      String organizationId) async {
    List<SettingsModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getOrganizationSettings?organizationId=$organizationId');

    for (var element in result) {
      mList.add(SettingsModel.fromJson(element));
    }
    if (mList.isNotEmpty) {
      mList.sort((a, b) => DateTime.parse(b.created!)
          .millisecondsSinceEpoch
          .compareTo(DateTime.parse(a.created!).millisecondsSinceEpoch));
      await cacheManager.addSettings(settings: mList!.first);

      //await prefsOGx.saveSettings(mList.first, getStorage);
      await cacheManager.addSettings(settings: mList.first);
    }

    pp('🌿 🌿 🌿 getOrganizationSettings returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ActivityModel>> getOrganizationActivity(
      String organizationId, int hours) async {
    List<ActivityModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getOrganizationActivity?organizationId=$organizationId&hours=$hours');

    for (var element in result) {
      mList.add(ActivityModel.fromJson(element));
    }

    if (mList.isNotEmpty) {
      mList.sort((a, b) => b.date!.compareTo(a.date!));
      await cacheManager.addActivityModels(activities: mList);
      organizationBloc.activityController.sink.add(mList);
    }

    pp('$xz 🌿 🌿 🌿 getOrganizationActivity returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<Organization?> getOrganization(String organizationId) async {
    Organization? org;

    final result = await _sendHttpGET(
        '${url!}getOrganization?organizationId=$organizationId');

    org = Organization.fromJson(result);
    return org;
  }

  Future<List<Organization>> getOrganizations() async {
    var mList = <Organization>[];
    List result = await _sendHttpGET('${url}getOrganizations');
    for (var org in result) {
      mList.add(Organization.fromJson(org));
    }

    return mList;
  }

  Future<List<ProjectSummary>> getOrganizationDailySummary(
      String organizationId, String startDate, String endDate) async {
    List<ProjectSummary> mList = [];

    List result = await _sendHttpGET(
        '${url!}createDailyOrganizationSummaries?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');

    for (var element in result) {
      mList.add(ProjectSummary.fromJson(element));
    }

    pp('$xz 🌿 🌿 🌿 getOrganization Summaries returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ProjectSummary>> getProjectDailySummary(
      String projectId, String startDate, String endDate) async {
    List<ProjectSummary> mList = [];

    List result = await _sendHttpGET(
        '${url!}createDailyProjectSummaries?projectId=$projectId&startDate=$startDate&endDate=$endDate');

    for (var element in result) {
      mList.add(ProjectSummary.fromJson(element));
    }

    pp('$xz 🌿 🌿 🌿 Daily Project Summaries returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ActivityModel>> getProjectActivity(
      String projectId, int hours) async {
    List<ActivityModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getProjectActivity?projectId=$projectId&hours=$hours');

    for (var element in result) {
      mList.add(ActivityModel.fromJson(element));
    }

    if (mList.isNotEmpty) {
      mList.sort((a, b) => b.date!.compareTo(a.date!));
      await cacheManager.addActivityModels(activities: mList);
      projectBloc.activityController.sink.add(mList);
    }

    pp('$xz 🌿 🌿 🌿 getProjectActivity returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<ActivityModel>> getUserActivity(String userId, int hours) async {
    List<ActivityModel> mList = [];

    List result = await _sendHttpGET(
        '${url!}getUserActivity?userId=$userId&hours=$hours');

    for (var element in result) {
      mList.add(ActivityModel.fromJson(element));
    }

    if (mList.isNotEmpty) {
      mList.sort((a, b) => b.date!.compareTo(a.date!));
      await cacheManager.addActivityModels(activities: mList);
      userBloc.activityController.sink.add(mList);
    }

    pp('$xz 🌿 🌿 🌿 getProjectActivity returned: 🌿 ${mList.length}');
    return mList;
  }

  Future<List<FieldMonitorSchedule>> getOrgFieldMonitorSchedules(
      String organizationId, String startDate, String endDate) async {
    List<FieldMonitorSchedule> mList = [];

    List result = await _sendHttpGET(
        '${url!}getOrgFieldMonitorSchedules?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
    for (var element in result) {
      mList.add(FieldMonitorSchedule.fromJson(element));
    }
    pp('🌿 🌿 🌿 getOrgFieldMonitorSchedules returned: 🌿 ${mList.length}');
    await cacheManager.addFieldMonitorSchedules(schedules: mList);
    return mList;
  }

  Future<ur.User> addUser(ur.User user) async {
    user.active ??= 0;
    Map bag = user.toJson();
    pp('DataAPI: ☕️ ☕️ ☕️ bag about to be sent to backend: check name: ☕️ $bag');

    var result = await _callWebAPIPost('${url!}addUser', bag);
    var u = ur.User.fromJson(result);
    await cacheManager.addUser(user: u);
    return u;
  }

  Future<int> deleteAuthUser(String userId) async {
    var result = await _sendHttpGET('${url!}deleteAuthUser?userId=$userId');
    var res = result['result'];
    pp('$xz 🌿 🌿 🌿 deleteAuthUser returned: 🌿 $result');
    return res;
  }

  Future<KillResponse> killUser(
      {required String userId, required String killerId}) async {
    var result =
        await _sendHttpGET('${url}killUser?userId=$userId&killerId=$killerId');
    var resp = KillResponse.fromJson(result);
    return resp;
  }

  Future<OrganizationRegistrationBag> registerOrganization(
      OrganizationRegistrationBag orgBag) async {
    Map bag = orgBag.toJson();
    pp('$xz️ OrganizationRegistrationBag about to be sent to backend: check name: ☕️ $bag');

    var result = await _callWebAPIPost('${url}registerOrganization', bag);
    var u = OrganizationRegistrationBag.fromJson(result);

    // await prefsOGx.saveUser(OldToRealm.getUser(user!)u.user!);
    // await cacheManager.addRegistration(bag: u);
    // await cacheManager.addUser(user: u.user!);
    // await cacheManager.addProject(project: u.project!);
    // await cacheManager.addSettings(settings: u.settings!);
    // await cacheManager.addOrganization(organization: u.organization!);
    // await cacheManager.addProjectPosition(projectPosition: u.projectPosition!);

    pp('$xz️ Organization registered! 😡😡 RegistrationBag arrived from backend server and cached in Hive; org:: ☕️ ${u.organization!.name!}');

    return u;
  }

  Future<ur.User> createUser(ur.User user) async {
    Map bag = user.toJson();

    var result = await _callWebAPIPost('${url!}createUser', bag);
    var u = ur.User.fromJson(result);
    await cacheManager.addUser(user: u);

    pp('$xz️ User creation complete: user: ☕️ ${u.toJson()}');

    return u;
  }

  Future updateUser(mrm.User user) async {
    // Map bag = user.toJson();
    var bag = {
      'userId': user.userId,
      'name': user.name,
      'imageUrl': user.imageUrl,
      'organizationId': user.organizationId,
      'organizationName': user.organizationName,
      'thumbnailUrl': user.thumbnailUrl,
      'locale': user.locale,
      'fcmRegistration': user.fcmRegistration,
      'email': user.email,
      'cellphone': user.cellphone,
      'userType': user.userType,
    };

    var result = await _callWebAPIPost('${url!}updateUser', bag);
    return ur.User.fromJson(result);
  }

  Future<int> updateAuthedUser(ur.User user) async {
    pp('\n$xz updateAuthedUser started for ${user.name!}');

    Map bag = user.toJson();

    var result = await _callWebAPIPost('${url!}updateAuthedUser', bag);
    return result['returnCode'];
  }

  Future<ProjectCount> getProjectCount(String projectId) async {
    var result =
        await _sendHttpGET('${url}getCountsByProject?projectId=$projectId');
    var cnt = ProjectCount.fromJson(result);
    pp('🌿 🌿 🌿 Project count returned: 🌿 ${cnt.toJson()}');
    return cnt;
  }

  Future<UserCount> getUserCount(String userId) async {
    var result = await _sendHttpGET('${url!}getCountsByUser?userId=$userId');
    var cnt = UserCount.fromJson(result);
    pp('🌿 🌿 🌿 User count returned: 🌿 ${cnt.toJson()}');
    return cnt;
  }

  Future<Project> findProjectById(String projectId) async {
    Map bag = {
      'projectId': projectId,
    };

    var result = await _callWebAPIPost('${url!}findProjectById', bag);
    var p = Project.fromJson(result);
    await cacheManager.addProject(project: p);
    return p;
  }

  //  Future<List<ProjectPosition>> findProjectPositionsById(
  //     String projectId, String startDate, String endDate) async {
  //
  //
  //
  //     var result = await _sendHttpGET(
  //         '${url!}getProjectPositions?projectId=$projectId&startDate=$startDate&endDate=$endDate');
  //     List<ProjectPosition> list = [];
  //     result.forEach((m) {
  //       list.add(ProjectPosition.fromJson(m));
  //     });
  //     await cacheManager.addProjectPositions(positions: list);
  //     return list;
  //   } catch (e) {
  //     pp(e);
  //     rethrow;
  //   }
  // }

  Future<List<ProjectPolygon>> findProjectPolygonsById(String projectId) async {
    var result =
        await _sendHttpGET('${url!}getProjectPolygons?projectId=$projectId');
    List<ProjectPolygon> list = [];
    result.forEach((m) {
      list.add(ProjectPolygon.fromJson(m));
    });
    await cacheManager.addProjectPolygons(polygons: list);
    return list;
  }

  Future<List<ProjectPosition>> getOrganizationProjectPositions(
      String organizationId, String startDate, String endDate) async {
    final list = <ProjectPosition>[];
    var result = await _sendHttpGET(
        '${url!}getOrganizationProjectPositions?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
    result.forEach((m) {
      list.add(ProjectPosition.fromJson(m));
    });
    pp('$xz org project positions found .... ${list.length}');
    await cacheManager.addProjectPositions(positions: list);
    return list;
  }

  Future<List<ProjectPosition>> getAllOrganizationProjectPositions(
      String organizationId) async {
    var result = await _sendHttpGET(
        '${url!}getAllOrganizationProjectPositions?organizationId=$organizationId');
    List<ProjectPosition> list = [];
    result.forEach((m) {
      list.add(ProjectPosition.fromJson(m));
    });
    pp('$xz org project positions found .... ${list.length}');
    await cacheManager.addProjectPositions(positions: list);
    return list;
  }

  Future<List<ProjectPolygon>> getOrganizationProjectPolygons(
      String organizationId, String startDate, String endDate) async {
    var result = await _sendHttpGET(
        '${url!}getOrganizationProjectPolygons?organizationId=$organizationId&startDate=$startDate&endDate=$endDate');
    List<ProjectPolygon> list = [];
    result.forEach((m) {
      list.add(ProjectPolygon.fromJson(m));
    });
    pp('$xz org project positions found .... ${list.length}');
    await cacheManager.addProjectPolygons(polygons: list);
    return list;
  }

  Future<List<ProjectPolygon>> getAllOrganizationProjectPolygons(
      String organizationId) async {
    var result = await _sendHttpGET(
        '${url!}getAllOrganizationProjectPolygons?organizationId=$organizationId');
    List<ProjectPolygon> list = [];
    result.forEach((m) {
      list.add(ProjectPolygon.fromJson(m));
    });
    pp('$xz org project positions found .... ${list.length}');
    await cacheManager.addProjectPolygons(polygons: list);
    return list;
  }

  Future<LocationRequest> sendLocationRequest(LocationRequest request) async {
    var result =
        await _callWebAPIPost('${url!}sendLocationRequest', request.toJson());
    final bag = LocationRequest.fromJson(result);
    return bag;
  }

  Future<ur.User?> getUserById({required String userId}) async {
    ur.User? user;

    var result = await _sendHttpGET('${url!}getUserById?userId=$userId');
    user = ur.User.fromJson(result);
    return user;
  }

  Future<List<ProjectPosition>> getProjectPositions(
      String projectId, String startDate, String endDate) async {
    var result = await _sendHttpGET(
        '${url!}getProjectPositions?projectId=$projectId&startDate=$startDate&endDate=$endDate');
    List<ProjectPosition> list = [];
    result.forEach((m) {
      list.add(ProjectPosition.fromJson(m));
    });
    await cacheManager.addProjectPositions(positions: list);
    return list;
  }

  Future<List<ProjectPolygon>> getProjectPolygons(
      String projectId, String startDate, String endDate) async {
    var result = await _sendHttpGET(
        '${url!}getProjectPolygons?projectId=$projectId&startDate=$startDate&endDate=$endDate');
    List<ProjectPolygon> list = [];
    result.forEach((m) {
      list.add(ProjectPolygon.fromJson(m));
    });
    await cacheManager.addProjectPolygons(polygons: list);
    return list;
  }

  Future<List<DailyForecast>> getDailyForecast(
      {required double latitude,
      required double longitude,
      required String timeZone,
      required String projectPositionId,
      required String projectId,
      required String projectName}) async {
    var result = await _sendHttpGET(
        '${url!}getDailyForecasts?latitude=$latitude&longitude=$longitude&timeZone=$timeZone');
    List<DailyForecast> list = [];
    result.forEach((m) {
      var fc = DailyForecast.fromJson(m);
      fc.projectPositionId = projectPositionId;
      fc.date = DateTime.now().toIso8601String();
      fc.projectName = projectName;
      fc.projectId = projectId;
      list.add(fc);
    });
    await cacheManager.addDailyForecasts(forecasts: list);
    return list;
  }

  Future<List<HourlyForecast?>> getHourlyForecast(
      {required double latitude,
      required double longitude,
      required String timeZone,
      required String projectPositionId,
      required String projectId,
      required String projectName}) async {
    var result = await _sendHttpGET(
        '${url!}getHourlyForecasts?latitude=$latitude&longitude=$longitude&timeZone=$timeZone');
    List<HourlyForecast> list = [];
    result.forEach((m) {
      var fc = HourlyForecast.fromJson(m);
      fc.projectPositionId = projectPositionId;
      fc.date = DateTime.now().toIso8601String();
      fc.projectName = projectName;
      fc.projectId = projectId;
      list.add(fc);
    });
    await cacheManager.addHourlyForecasts(forecasts: list);
    return list;
  }

  Future<List<Photo>> getProjectPhotos(
      {required String projectId,
      required String startDate,
      required String endDate}) async {
    var result = await _sendHttpGET(
        '${url!}getProjectPhotos?projectId=$projectId&startDate=$startDate&endDate=$endDate');
    List<Photo> list = [];
    result.forEach((m) {
      list.add(Photo.fromJson(m));
    });
    await cacheManager.addPhotos(photos: list);
    return list;
  }

  Future<List<Photo>> getUserProjectPhotos(String userId) async {
    var result =
        await _sendHttpGET('${url!}getUserProjectPhotos?userId=$userId');
    List<Photo> list = [];
    result.forEach((m) {
      list.add(Photo.fromJson(m));
    });
    await cacheManager.addPhotos(photos: list);
    return list;
  }

  Future<DataBag> getProjectData(
      String projectId, String startDate, String endDate) async {
    var bag = DataBag(
        photos: [],
        videos: [],
        fieldMonitorSchedules: [],
        projects: [],
        users: [],
        audios: [],
        projectPositions: [],
        geofenceEvents: [],
        projectPolygons: [],
        date: DateTime.now().toIso8601String(),
        settings: [],
        activityModels: []);

    var result = await _sendHttpGET(
        '${url!}getProjectData?projectId=$projectId&startDate=$startDate&endDate=$endDate');

    bag = DataBag.fromJson(result);
    await cacheManager.addProjects(projects: bag.projects!);
    await cacheManager.addProjectPolygons(polygons: bag.projectPolygons!);
    await cacheManager.addProjectPositions(positions: bag.projectPositions!);
    await cacheManager.addUsers(users: bag.users!);
    await cacheManager.addPhotos(photos: bag.photos!);
    await cacheManager.addVideos(videos: bag.videos!);
    await cacheManager.addAudios(audios: bag.audios!);
    //get latest settings
    bag.settings!.sort((a, b) => DateTime.parse(b.created!)
        .millisecondsSinceEpoch
        .compareTo(DateTime.parse(a.created!).millisecondsSinceEpoch));
    if (bag.settings!.isNotEmpty) {
      await cacheManager.addSettings(settings: bag.settings!.first);
    }
    await cacheManager.addFieldMonitorSchedules(
        schedules: bag.fieldMonitorSchedules!);

    return bag;
  }

  Future<List<Video>> getUserProjectVideos(String userId) async {
    var result =
        await _sendHttpGET('${url!}getUserProjectVideos?userId=$userId');
    List<Video> list = [];
    result.forEach((m) {
      list.add(Video.fromJson(m));
    });
    await cacheManager.addVideos(videos: list);
    return list;
  }

  Future<List<Audio>> getUserProjectAudios(String userId) async {
    var result =
        await _sendHttpGET('${url!}getUserProjectAudios?userId=$userId');
    List<Audio> list = [];
    result.forEach((m) {
      list.add(Audio.fromJson(m));
    });
    await cacheManager.addAudios(audios: list);
    return list;
  }

  Future<List<Video>> getProjectVideos(
      String projectId, String startDate, String endDate) async {
    var result = await _sendHttpGET(
        '${url!}getProjectVideos?projectId=$projectId&startDate=$startDate&endDate=$endDate');
    List<Video> list = [];
    result.forEach((m) {
      list.add(Video.fromJson(m));
    });
    await cacheManager.addVideos(videos: list);
    return list;
  }

  Future<List<Audio>> getProjectAudios(
      String projectId, String startDate, String endDate) async {
    var result = await _sendHttpGET(
        '${url!}getProjectAudios?projectId=$projectId&startDate=$startDate&endDate=$endDate');
    List<Audio> list = [];
    result.forEach((m) {
      list.add(Audio.fromJson(m));
    });
    await cacheManager.addAudios(audios: list);
    return list;
  }

  Future<List<ur.User>> findUsersByOrganization(String organizationId) async {
    var cmd = 'getAllOrganizationUsers?organizationId=$organizationId';
    var u = '$url$cmd';

    List result = await _sendHttpGET(u);
    pp('$xz findUsersByOrganization: 🍏 found: ${result.length} users');
    List<ur.User> list = [];
    for (var m in result) {
      list.add(ur.User.fromJson(m));
    }
    await cacheManager.addUsers(users: list);
    pp('$xz findUsersByOrganization: 🍏 returning objects for: ${list.length} users');
    return list;
  }

  // const mm = '🍏🍏🍏 DataAPI: ';
  Future<List<Project>> findProjectsByOrganization(
      String organizationId) async {
    var cmd = 'findProjectsByOrganization';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    pp('$xz findProjectsByOrganization: 🍏 result: ${result.length} projects');
    List<Project> list = [];
    for (var m in result) {
      list.add(Project.fromJson(m));
    }
    // pp('$xz ${list.length} project objects built .... about to cache in local mongo');
    await cacheManager.addProjects(projects: list);
    return list;
  }

  Future<Organization?> findOrganizationById(String organizationId) async {
    pp('$xz findOrganizationById: 🍏 id: $organizationId');

    var cmd = 'findOrganizationById';
    var u = '$url$cmd?organizationId=$organizationId';

    var result = await _sendHttpGET(u);
    pp('$xz findOrganizationById: 🍏 result: $result ');
    Organization? org = Organization.fromJson(result);
    await cacheManager.addOrganization(organization: org);
    return org;
  }

  Future<List<Photo>> getOrganizationPhotos(String organizationId) async {
    pp('$xz getOrganizationPhotos: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationPhotos';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    pp('$xz getOrganizationPhotos: 🍏 found: ${result.length} org photos');
    List<Photo> list = [];
    for (var m in result) {
      list.add(Photo.fromJson(m));
    }
    return list;
  }

  Future<List<ProjectPosition>> getOrganizationPositions(
      String organizationId) async {
    pp('$xz getOrganizationPhotos: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationPositions';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    pp('$xz getOrganizationPhotos: 🍏 found: ${result.length} org photos');
    List<ProjectPosition> list = [];
    for (var m in result) {
      list.add(ProjectPosition.fromJson(m));
    }
    return list;
  }

  Future<List<ProjectPolygon>> getOrganizationPolygons(
      String organizationId) async {
    pp('$xz getOrganizationPhotos: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationPolygons';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    pp('$xz getOrganizationPhotos: 🍏 found: ${result.length} org photos');
    List<ProjectPolygon> list = [];
    for (var m in result) {
      list.add(ProjectPolygon.fromJson(m));
    }
    return list;
  }

  Future<List<Video>> getOrganizationVideos(
    String organizationId,
  ) async {
    pp('$xz getOrganizationVideos: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationVideos';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<Video> list = [];
    for (var m in result) {
      list.add(Video.fromJson(m));
    }
    await cacheManager.addVideos(videos: list);
    return list;
  }

  Future<List<Audio>> getOrganizationAudios(String organizationId) async {
    pp('$xz getOrganizationAudios: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationAudios';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<Audio> list = [];
    for (var m in result) {
      list.add(Audio.fromJson(m));
    }
    await cacheManager.addAudios(audios: list);
    return list;
  }

  Future<List<ActivityModel>> getAllOrganizationActivity(
      String organizationId) async {
    pp('$xz getOrganizationAudios: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationActivity';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<ActivityModel> list = [];
    for (var m in result) {
      list.add(ActivityModel.fromJson(m));
    }
    return list;
  }

  Future<List<Project>> getOrganizationProjects(String organizationId) async {
    pp('$xz getOrganizationProjects: 🍏 id: $organizationId');

    var cmd = 'getAllOrganizationProjects';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<Project> list = [];
    for (var m in result) {
      list.add(Project.fromJson(m));
    }
    await cacheManager.addProjects(projects: list);
    return list;
  }

  Future<List<ur.User>> getOrganizationUsers(String organizationId) async {
    var cmd = 'getAllOrganizationUsers';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<ur.User> list = [];
    for (var m in result) {
      list.add(ur.User.fromJson(m));
    }
    await cacheManager.addUsers(users: list);
    return list;
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByProjectPosition(
      String projectPositionId) async {
    var cmd = 'getGeofenceEventsByProjectPosition';
    var u = '$url$cmd?projectPositionId=$projectPositionId';

    List result = await _sendHttpGET(u);
    List<GeofenceEvent> list = [];
    for (var m in result) {
      list.add(GeofenceEvent.fromJson(m));
    }

    for (var b in list) {
      await cacheManager.addGeofenceEvent(geofenceEvent: b);
    }
    return list;
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByOrganization(
      String organizationId) async {
    var cmd = 'getGeofenceEventsByOrganization';
    var u = '$url$cmd?organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<GeofenceEvent> list = [];
    for (var m in result) {
      list.add(GeofenceEvent.fromJson(m));
    }

    return list;
  }

  Future<List<GeofenceEvent>> getGeofenceEventsByUser(String userId) async {
    var cmd = 'getGeofenceEventsByUser';
    var u = '$url$cmd?userId=$userId';

    List result = await _sendHttpGET(u);
    List<GeofenceEvent> list = [];
    for (var m in result) {
      list.add(GeofenceEvent.fromJson(m));
    }

    for (var b in list) {
      await cacheManager.addGeofenceEvent(geofenceEvent: b);
    }
    return list;
  }

  Future<List<Project>> findProjectsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('\n$xz ......... findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres,  '
        '🥏 🥏 🥏about to call _sendHttpGET.........');

    var cmd = 'findProjectsByLocation';
    var u =
        '$url$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM&organizationId=$organizationId';

    List result = await _sendHttpGET(u);
    List<Project> list = [];
    for (var m in result) {
      list.add(Project.fromJson(m));
    }
    pp('\n$xz findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres; 🔵🔵 found ${list.length}');
    var map = HashMap<String, Project>();
    for (var element in list) {
      map[element.projectId!] = element;
    }

    var mList = map.values.toList();
    pp('\n$xz findProjectsByLocation: 🍏 radiusInKM: $radiusInKM kilometres; 🔵🔵 found ${mList.length} after filtering for duplicates');
    await cacheManager.addProjects(projects: mList);
    return mList;
  }

  Future<List<City>> findCitiesByLocation(
      {required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$xz findCitiesByLocation: 🍏 radiusInKM: $radiusInKM');

    var cmd = 'findCitiesByLocation';
    var u =
        '$url$cmd?latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';

    List result = await _sendHttpGET(u);
    List<City> list = [];
    for (var m in result) {
      list.add(City.fromJson(m));
    }
    pp('$xz findCitiesByLocation: 🍏 found: ${list.length} cities');
    // for (var city in list) {
    //   pp('$xz city found by findCitiesByLocation call: ${city.name} - ${city.stateName}, ${city.countryName}  \n');
    // }
    pp('$xz cities found by findCitiesByLocation : ${list.length}');
    return list;
  }

  Future<List<mrm.ProjectPosition>> findProjectPositionsByLocation(
      {required String organizationId,
      required double latitude,
      required double longitude,
      required double radiusInKM}) async {
    pp('$xz findProjectPositionsByLocation: 🍏 radiusInKM: $radiusInKM');

    var cmd = 'findProjectPositionsByLocation';
    var u =
        '$url$cmd?organizationId=$organizationId&latitude=$latitude&longitude=$longitude&radiusInKM=$radiusInKM';

    List result = await _sendHttpGET(u);
    List<mrm.ProjectPosition> list = [];
    pp('$xz findProjectPositionsByLocation: 🍏 found, before deserialization: ${result.length} project positions');
    for (var m in result) {
      final nearestCities = <String>[];
      if (m['nearestCities'] != null) {
        List cc = m['nearestCities'];
        for (var element in cc) {
          nearestCities.add(element as String);
        }
      }
      var posJson = m['position'];
      final lat = posJson['latitude'] as double;
      final lng = posJson['longitude'] as double;
      final coords = [longitude, latitude];
      list.add(mrm.ProjectPosition(
        ObjectId(),
        projectId: m['projectId'],
        projectName: m['projectName'],
        organizationId: m['organizationId'],
        organizationName: m['organizationName'],
        name: m['name'],
        created: m['created'],
        userId: m['userId'],
        userUrl: m['userUrl'],
        projectPositionId: m['projectPositionId'],
        possibleAddress: m['possibleAddress'],
        nearestCities: nearestCities,

        position: mrm.Position(
          type: 'Point', coordinates: coords,
          latitude: lat, longitude: lng,
        ),
        userName: m['userName'],
      ));
    }
    pp('$xz findProjectPositionsByLocation: 🍏 found: ${list.length} project positions');
    return list;
  }

  Future<List<Questionnaire>> getQuestionnairesByOrganization(
      String organizationId) async {
    pp('$xz getQuestionnairesByOrganization: 🍏 id: $organizationId');

    var cmd = 'getQuestionnairesByOrganization?organizationId=$organizationId';
    var u = '$url$cmd';

    List result = await _sendHttpGET(u);
    List<Questionnaire> list = [];
    for (var m in result) {
      list.add(Questionnaire.fromJson(m));
    }
    return list;
  }

  Future<DataCounts> getOrganizationDataCounts(String organizationId,
      String startDate, String endDate, int activityStreamHours) async {
    pp('$xz getOrganizationDataCounts: 🍏 id: $organizationId');

    var cmd =
        'getOrganizationDataCounts?organizationId=$organizationId&startDate=$startDate&endDate=$endDate&activityStreamHours=$activityStreamHours';
    var u = '$url$cmd';

    var result = await _sendHttpGET(u);
    final dc = DataCounts.fromJson(result);
    pp('$xz DataCounts received: ${dc.toJson()}');

    return dc;
  }

  Future<Community> updateCommunity(Community community) async {
    Map bag = community.toJson();

    var result = await _callWebAPIPost('${url!}updateCommunity', bag);
    return Community.fromJson(result);
  }

  Future<Community> addCommunity(Community community) async {
    Map bag = community.toJson();

    var result = await _callWebAPIPost('${url!}addCommunity', bag);
    var c = Community.fromJson(result);
    await cacheManager.addCommunity(community: c);
    return c;
  }

  //  Future<GeofenceEvent> addGeofenceEvent(GeofenceEvent geofenceEvent) async {
  //
  //   Map bag = geofenceEvent.toJson();
  //
  //     var result = await _callWebAPIPost(url! + 'addGeofenceEvent', bag);
  //     var c = GeofenceEvent.fromJson(result);
  //     await hiveUtil.addGeofenceEvent(geofenceEvent: c);
  //     return c;
  //   } catch (e) {
  //     pp(e);
  //     rethrow;
  //   }
  // }

  Future addPointToPolygon(
      {required String communityId,
      required double latitude,
      required double longitude}) async {
    Map bag = {
      'communityId': communityId,
      'latitude': latitude,
      'longitude': longitude,
    };

    var result = await _callWebAPIPost('${url}addPointToPolygon', bag);
    return result;
  }

  Future addQuestionnaireSection(
      {required String questionnaireId, required Section section}) async {
    Map bag = {
      'questionnaireId': questionnaireId,
      'section': section.toJson(),
    };

    var result = await _callWebAPIPost('${url!}addQuestionnaireSection', bag);
    return result;
  }

  Future<List<Community>> findCommunitiesByCountry(String countryId) async {
    pp('🍏🍏🍏🍏 ..... findCommunitiesByCountry ');
    var cmd = 'findCommunitiesByCountry';
    var u = '$url$cmd?countryId=$countryId';

    List result = await _sendHttpGET(u);
    List<Community> communityList = [];
    for (var m in result) {
      communityList.add(Community.fromJson(m));
    }
    pp('🍏 🍏 🍏 findCommunitiesByCountry found ${communityList.length}');
    await cacheManager.addCommunities(communities: communityList);
    return communityList;
  }

  Future<Project> addProject(Project project) async {
    Map bag = project.toJson();

    var result = await _callWebAPIPost('${url!}addProject', bag);
    var p = Project.fromJson(result);
    await cacheManager.addProject(project: p);
    return p;
  }

  Future<Project> updateProject(Project project) async {
    Map bag = project.toJson();

    var result = await _callWebAPIPost('${url!}updateProject', bag);
    var p = Project.fromJson(result);
    await cacheManager.addProject(project: p);
    return p;
  }

  Future<Project> addSettlementToProject(
      {required String projectId, required String settlementId}) async {
    Map bag = {
      'projectId': projectId,
      'settlementId': settlementId,
    };

    var result = await _callWebAPIPost('${url!}addSettlementToProject', bag);
    var proj = Project.fromJson(result);
    await cacheManager.addProject(project: proj);
    return proj;
  }

  Future<ProjectPosition> addProjectPosition(
      {required ProjectPosition position}) async {
    Map bag = position.toJson();

    var result = await _callWebAPIPost('${url!}addProjectPosition', bag);

    var pp = ProjectPosition.fromJson(result);
    await cacheManager.addProjectPosition(projectPosition: pp);
    return pp;
  }

  Future<ProjectPolygon> addProjectPolygon(
      {required ProjectPolygon polygon}) async {
    Map bag = polygon.toJson();

    var result = await _callWebAPIPost('${url!}addProjectPolygon', bag);

    var pp = ProjectPolygon.fromJson(result);
    await cacheManager.addProjectPolygon(projectPolygon: pp);
    return pp;
  }

  Future<AppError> addAppError(AppError appError) async {
    pp('$xz appError: ${appError.toJson()}');
    var result = await _callWebAPIPost('${url!}addAppError', appError.toJson());
    pp('\n\n\n$xz 🔴🔴🔴 DataAPI addAppError succeeded. Everything OK?? 🔴🔴🔴');
    var ae = AppError.fromJson(result);
    await cacheManager.addAppError(appError: ae);
    pp('$xz addAppError has added AppError to DB and to Hive cache\n');
    return appError;
  }

  Future<Photo> addPhoto(Photo photo) async {
    var result = await _callWebAPIPost('${url!}addPhoto', photo.toJson());
    pp('\n\n\n$xz 🔴🔴🔴 DataAPI addPhoto succeeded. Everything OK?? 🔴🔴🔴');
    var photoBack = Photo.fromJson(result);
    await cacheManager.addPhoto(photo: photoBack);
    pp('$xz addPhoto has added photo to DB and to Hive cache\n');
    return photo;
  }

  Future<Video> addVideo(Video video) async {
    var result = await _callWebAPIPost('${url!}addVideo', video.toJson());
    pp('$xz addVideo has added photo to DB and to Hive cache');
    var vx = Video.fromJson(result);
    await cacheManager.addVideo(video: vx);
    return vx;
  }

  Future<Audio> addAudio(Audio audio) async {
    var result = await _callWebAPIPost('${url!}addAudio', audio.toJson());
    var audiox = Audio.fromJson(result);
    pp('$xz addAudio has added audio to DB : 😡😡😡 fromJson:: ${audiox.toJson()}');
    return audiox;
  }

  _handleError({required String message, required String type}) {
    errorHandler.handleError(
        exception: GeoException(
            message: message,
            translationKey: 'error',
            errorType: type,
            url: url));
  }

  Future<Rating> addRating(Rating rating) async {
    var result = await _callWebAPIPost('${url!}addRating', rating.toJson());
    var mRating = Rating.fromJson(result);
    pp('$xz addRating has added mRating to DB : 😡😡😡 fromJson:: ${mRating.toJson()}');

    // var x = await cacheManager.addRating(rating: mRating);
    // pp('$xz addRating has added result to Hive??? : 😡😡😡 result from hive: $x');

    return mRating;
  }

  Future<Condition> addCondition(Condition condition) async {
    var result =
        await _callWebAPIPost('${url!}addCondition', condition.toJson());
    var x = Condition.fromJson(result);
    await cacheManager.addCondition(condition: x);
    return x;
  }

  Future<Photo> addSettlementPhoto(
      {required String settlementId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'settlementId': settlementId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
    };

    var result = await _callWebAPIPost('${url!}addSettlementPhoto', bag);

    var photo = Photo.fromJson(result);
    await cacheManager.addPhoto(photo: photo);
    return photo;
  }

  Future<Video> addProjectVideo(
      {required String projectId,
      required String url,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'projectId': projectId,
      'url': url,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };

    var result = await _callWebAPIPost('${url!}addProjectVideo', bag);
    var video = Video.fromJson(result);
    await cacheManager.addVideo(video: video);
    return video;
  }

  Future<Project> addProjectRating(
      {required String projectId,
      required String rating,
      required String comment,
      required double latitude,
      longitude,
      required String userId}) async {
    Map bag = {
      'projectId': projectId,
      'rating': rating,
      'comment': comment,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId
    };

    var result = await _callWebAPIPost('${url!}addProjectRating', bag);
    return Project.fromJson(result);
  }

  Future<Questionnaire> addQuestionnaire(Questionnaire questionnaire) async {
    Map bag = questionnaire.toJson();
    prettyPrint(bag,
        'DataAPI  💦 💦 💦 addQuestionnaire: 🔆🔆 Sending to web api ......');

    var result = await _callWebAPIPost('${url!}addQuestionnaire', bag);
    return Questionnaire.fromJson(result);
  }

  Future<List<Project>> findAllProjects(String organizationId) async {
    Map bag = {};

    List result = await _callWebAPIPost('${url!}findAllProjects', bag);
    List<Project> list = [];
    for (var m in result) {
      list.add(Project.fromJson(m));
    }
    await cacheManager.addProjects(projects: list);
    return list;
  }

  Future<Organization> addOrganization(Organization org) async {
    Map bag = org.toJson();

    pp('DataAPI_addOrganization:  🍐 org Bag to be sent, check properties:  🍐 $bag');

    var result = await _callWebAPIPost('${url!}addOrganization', bag);
    var o = Organization.fromJson(result);
    await cacheManager.addOrganization(organization: o);
    return o;
  }

  Future<OrgMessage> sendMessage(OrgMessage message) async {
    Map bag = message.toJson();

    pp('DataAPI_sendMessage:  🍐 org message to be sent, check properties:  🍐 $bag');

    var result = await _callWebAPIPost('${url!}sendMessage', bag);
    var m = OrgMessage.fromJson(result);
    await cacheManager.addOrgMessage(message: m);
    return m;
  }

  Future<ur.User?> findUserByEmail(String email) async {
    pp('🐤🐤🐤🐤 DataAPI : ... findUserByEmail $email ');

    var command = "findUserByEmail?email=$email";

    pp('🐤🐤🐤🐤 DataAPI : ... 🥏 calling _callWebAPIPost .. 🥏 findUserByEmail $url$command ');
    var result = await _sendHttpGET(
      '$url$command',
    );

    return ur.User.fromJson(result);
  }

  Future<Photo?> findPhotoById(String photoId) async {
    var command = "findPhotoById?photoId=$photoId";

    pp('🐤🐤🐤🐤 DataAPI : ... 🥏 calling _callWebAPIPost .. 🥏 $url$command ');
    var result = await _sendHttpGET(
      '$url$command',
    );
    if (result is bool) {
      return null;
    }

    return Photo.fromJson(result);
  }

  Future<Video?> findVideoById(String videoId) async {
    var command = "findVideoById?videoId=$videoId";

    var result = await _sendHttpGET(
      '$url$command',
    );
    if (result is bool) {
      return null;
    }

    return Video.fromJson(result);
  }

  Future<Audio?> findAudioById(String audioId) async {
    var command = "findAudioById?audioId=$audioId";

    var result = await _sendHttpGET(
      '$url$command',
    );
    if (result is bool) {
      return null;
    }

    return Audio.fromJson(result);
  }

  Future<ur.User> findUserByUid(String uid) async {
    Map bag = {
      'uid': uid,
    };

    var result = await _callWebAPIPost('${url!}findUserByUid', bag);
    return ur.User.fromJson(result);
  }

  Future<List<Country>> getCountries() async {
    var cmd = 'getCountries';
    var u = '$url$cmd';

    List result = await _sendHttpGET(u);
    List<Country> list = [];
    for (var m in result) {
      var entry = Country.fromJson(m);
      list.add(entry);
    }
    pp('🐤🐤🐤🐤 ${list.length} Countries found 🥏');
    list.sort((a, b) => a.name!.compareTo(b.name!));
    return list;
  }

  Future<List<City>> getCitiesByCountry(String countryId) async {
    var cmd = 'getCitiesByCountry?countryId=$countryId';
    var u = '$url$cmd';

    List result = await _sendHttpGET(u);
    List<City> list = [];
    for (var m in result) {
      var entry = City.fromJson(m);
      list.add(entry);
    }
    pp('🐤🐤🐤🐤 ${list.length} country $countryId  found ${list.length} cities 🥏');
    list.sort((a, b) => a.name!.compareTo(b.name!));
    return list;
  }

  Future hello() async {
    var result = await _sendHttpGET(url!);
  }

  Future ping() async {
    var result = await _sendHttpGET('${url!}ping');
  }

  Future _callWebAPIPost(String mUrl, Map? bag) async {
    // pp('$xz http POST call: 🔆 🔆 🔆  calling : 💙  $mUrl  💙 ');

    String? mBag;
    if (bag != null) {
      mBag = json.encode(bag);
    }
    var start = DateTime.now();
    var token = await appAuth.getAuthToken();

    headers['Authorization'] = 'Bearer $token';
    try {
      var resp = await client
          .post(
            Uri.parse(mUrl),
            body: mBag,
            headers: headers,
          )
          .timeout(const Duration(seconds: timeOutInSeconds));
      if (resp.statusCode == 200) {
        pp('$xz _callWebAPIPost RESPONSE: 💙💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      } else {
        pp('👿👿👿_callWebAPIPost: 🔆 statusCode: 👿👿👿 ${resp.statusCode} 🔆🔆🔆 for $mUrl');
        pp(resp.body);
        throw GeoException(
            message: 'Bad status code: ${resp.statusCode} - ${resp.body}',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.socketException);
      }
      var end = DateTime.now();
      pp('$xz _callWebAPIPost: 🔆 elapsed time: ${end.difference(start).inSeconds} seconds 🔆');
      try {
        var mJson = json.decode(resp.body);
        return mJson;
      } catch (e) {
        pp("👿👿👿👿👿👿👿 json.decode failed, returning response body");
        return resp.body;
      }
    } on SocketException {
      pp('$xz SocketException: really means that server cannot be reached 😑');
      final gex = GeoException(
          message: 'Server not available',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.socketException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on HttpException {
      pp("$xz HttpException occurred 😱");
      final gex = GeoException(
          message: 'Server not available',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.httpException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on FormatException {
      pp("$xz Bad response format 👎");
      final gex = GeoException(
          message: 'Bad response format',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.formatException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on TimeoutException {
      pp("$xz No Internet connection. Request has timed out in $timeOutInSeconds seconds 👎");
      final gex = GeoException(
          message: 'Request timed out. No Internet connection',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.timeoutException);
      errorHandler.handleError(exception: gex);
      throw gex;
    }
  }

  static const xz = '🌎🌎🌎🌎🌎🌎 DataApiDog: ';

  Future _sendHttpGET(String mUrl) async {
    pp('$xz _sendHttpGET: 🔆 🔆 🔆 calling : 💙 $mUrl  💙');
    var start = DateTime.now();
    var token = await appAuth.getAuthToken();
    if (token != null) {
      // pp('$xz _sendHttpGET: 😡😡😡 Firebase Auth Token: 💙️ Token is GOOD! 💙 ');
    } else {
      pp('$xz Firebase token missing ${E.redDot}${E.redDot}${E.redDot}${E.redDot}');
      final gex = GeoException(
          message: 'Firebase Authentication token missing',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.timeoutException);
      errorHandler.handleError(exception: gex);
      //throw gex;
    }
    headers['Authorization'] = 'Bearer $token';
    try {
      var resp = await client
          .get(
            Uri.parse(mUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: timeOutInSeconds));
      pp('$xz http GET call RESPONSE: .... : 💙 statusCode: 👌👌👌 ${resp.statusCode} 👌👌👌 💙 for $mUrl');
      var end = DateTime.now();
      pp('$xz http GET call: 🔆 elapsed time for http: ${end.difference(start).inSeconds} seconds 🔆 \n\n');

      if (resp.body.contains('not found')) {
        return false;
      }

      if (resp.statusCode == 403) {
        var msg =
            '😡 😡 status code: ${resp.statusCode}, Request Forbidden 🥪 🥙 🌮  😡 ${resp.body}';
        pp(msg);
        final gex = GeoException(
            message: 'Forbidden call',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.httpException);
        errorHandler.handleError(exception: gex);
        throw gex;
      }

      if (resp.statusCode != 200) {
        var msg =
            '😡 😡 The response is not 200; it is ${resp.statusCode}, NOT GOOD, throwing up !! 🥪 🥙 🌮  😡 ${resp.body}';
        pp(msg);
        final gex = GeoException(
            message: 'Bad status code: ${resp.statusCode} - ${resp.body}',
            url: mUrl,
            translationKey: 'serverProblem',
            errorType: GeoException.socketException);
        errorHandler.handleError(exception: gex);
        throw gex;
      }
      var mJson = json.decode(resp.body);
      return mJson;
    } on SocketException {
      pp('$xz SocketException, really means that server cannot be reached 😑');
      final gex = GeoException(
          message: 'Server not available',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.socketException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on HttpException {
      pp("$xz HttpException occurred 😱");
      final gex = GeoException(
          message: 'Server not available',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.httpException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on FormatException {
      pp("$xz Bad response format 👎");
      final gex = GeoException(
          message: 'Bad response format',
          url: mUrl,
          translationKey: 'serverProblem',
          errorType: GeoException.formatException);
      errorHandler.handleError(exception: gex);
      throw gex;
    } on TimeoutException {
      pp("$xz No Internet connection. Request has timed out in $timeOutInSeconds seconds 👎");
      final gex = GeoException(
          message: 'No Internet connection. Request timed out',
          url: mUrl,
          translationKey: 'networkProblem',
          errorType: GeoException.timeoutException);
      errorHandler.handleError(exception: gex);
      throw gex;
    }
  }
}
