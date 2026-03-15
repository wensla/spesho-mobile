import '../entities/dashboard_entity.dart';
import '../repositories/i_dashboard_repository.dart';

class GetDashboardUseCase {
  final IDashboardRepository _repo;
  GetDashboardUseCase(this._repo);
  Future<DashboardEntity> call() => _repo.getDashboard();
}

class DashboardUseCases {
  final GetDashboardUseCase getDashboard;

  DashboardUseCases(IDashboardRepository repo)
      : getDashboard = GetDashboardUseCase(repo);
}
