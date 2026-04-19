import 'package:get_it/get_it.dart';

import 'package:wevacalc/data/database/app_database.dart';
import 'package:wevacalc/data/repositories/history_repository.dart';
import 'package:wevacalc/data/repositories/history_repository_impl.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Repositories
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(database: getIt<AppDatabase>()),
  );

  // ViewModels serão adicionados nas próximas etapas (3 e 4)
}
