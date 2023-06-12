import 'package:freshgio/realm_data/data/realm_sync_api.dart';

import '../l10n/translation_handler.dart';

void readShit(RealmSyncApi realmSyncApi, String organizationId) {
  realmSyncApi.getOrganizationActivities(organizationId: organizationId);
  realmSyncApi.getProjects(organizationId);
  realmSyncApi.getOrganizationUsers(organizationId: organizationId);

  realmSyncApi.getOrganizationPositions(organizationId: organizationId);
  realmSyncApi.getOrganizationPolygons(organizationId: organizationId);

  realmSyncApi.getOrganizationPhotos(organizationId: organizationId);
  realmSyncApi.getOrganizationVideos(organizationId: organizationId);
  realmSyncApi.getOrganizationAudios(organizationId: organizationId);

  realmSyncApi.getOrganizationGeofenceEvents(organizationId: organizationId);
}

String? english,
    french,
    portuguese,
    lingala,
    sotho,
    spanish,
    shona,
    swahili,
    tsonga,
    xhosa,
    zulu,
    yoruba,
    afrikaans,
    german,
    chinese;

Future<String> getLanguageFromLocale(String locale) async {
  switch (locale) {
    case 'en':
      return await translator.translate('en', locale);

    case 'af':
      return await translator.translate('af', locale);

    case 'fr':
      return await translator.translate('fr', locale);

    case 'pt':
      return await translator.translate('pt', locale);

    case 'ig':
      return await translator.translate('ig', locale);

    case 'st':
      return await translator.translate('st', locale);

    case 'es':
      return await translator.translate('es', locale);

    case 'sw':
      return await translator.translate('sw', locale);

    case 'ts':
      return await translator.translate('ts', locale);

    case 'xh':
      return await translator.translate('xh', locale);

    case 'zu':
      return await translator.translate('zu', locale);

    case 'yo':
      return await translator.translate('yo', locale);

    case 'de':
      return await translator.translate('de', locale);

    case 'zh':
      return await translator.translate('zh', locale);

    case 'sn':
      return await translator.translate('sn', locale);
    default:
      return await translator.translate('en', locale);
  }
}
