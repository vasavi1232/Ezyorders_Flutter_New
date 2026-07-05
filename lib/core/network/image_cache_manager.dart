import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

class ImageCacheManager extends CacheManager {
  static const key = 'customImageCache';

  static final ImageCacheManager _instance = ImageCacheManager._();
  factory ImageCacheManager() => _instance;

  ImageCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(
              httpClient: IOClient(
                HttpClient()
                  ..badCertificateCallback =
                      (X509Certificate cert, String host, int port) => true,
              ),
            ),
          ),
        );
}
