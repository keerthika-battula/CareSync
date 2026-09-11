abstract class VersionService {
  Future<String?> fetchLatestBuildNumber();
  void hardRefresh();
}
