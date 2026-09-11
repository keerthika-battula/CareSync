import 'version_service.dart';

VersionService createVersionService() => VersionServiceStub();

class VersionServiceStub implements VersionService {
  @override
  Future<String?> fetchLatestBuildNumber() async => null;

  @override
  void hardRefresh() {}
}
