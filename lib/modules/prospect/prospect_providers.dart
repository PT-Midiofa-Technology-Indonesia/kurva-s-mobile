import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../auth/data/models/auth_user.dart';
import 'data/models/prospect_models.dart';
import 'data/prospect_repository.dart';

final prospectRepositoryProvider = Provider<ProspectRepository>((ref) {
  return ProspectRepository(dioClient: ref.watch(dioClientProvider));
});

final prospectCompanyOptionsProvider = Provider<List<AuthCompany>>((ref) {
  final authState = ref.watch(authControllerProvider).valueOrNull;
  final user = authState?.user;
  if (user == null) {
    return const [];
  }

  final companiesById = <String, AuthCompany>{};
  for (final assignment in user.assignments) {
    final company = assignment.company;
    if (company != null && company.id.isNotEmpty) {
      companiesById.putIfAbsent(company.id, () => company);
    }
  }
  for (final company in user.companies) {
    if (company.id.isNotEmpty) {
      companiesById.putIfAbsent(company.id, () => company);
    }
  }

  return companiesById.values.toList(growable: false);
});

final prospectSelectedCompanyIdProvider = StateProvider<String?>((ref) => null);

final prospectCompanyIdProvider = Provider<String?>((ref) {
  final selectedCompanyId = ref.watch(prospectSelectedCompanyIdProvider);
  if (selectedCompanyId != null && selectedCompanyId.isNotEmpty) {
    return selectedCompanyId;
  }

  return ref.watch(prospectCompanyOptionsProvider).firstOrNull?.id;
});

final prospectSelectedCompanyProvider = Provider<AuthCompany?>((ref) {
  final companyId = ref.watch(prospectCompanyIdProvider);
  if (companyId == null || companyId.isEmpty) {
    return null;
  }

  for (final company in ref.watch(prospectCompanyOptionsProvider)) {
    if (company.id == companyId) {
      return company;
    }
  }

  return null;
});

final prospectPipelineProvider = FutureProvider<List<ProspectStage>>((ref) {
  return ref
      .watch(prospectRepositoryProvider)
      .fetchProspects(companyId: ref.watch(prospectCompanyIdProvider));
});

final prospectProjectTypesProvider = FutureProvider<List<ProspectProjectType>>((
  ref,
) {
  return ref.watch(prospectRepositoryProvider).fetchProjectTypes();
});

final prospectDetailProvider = FutureProvider.family<ProspectDetail, String>((
  ref,
  prospectId,
) {
  return ref
      .watch(prospectRepositoryProvider)
      .fetchProspectDetail(
        prospectId: prospectId,
        companyId: ref.watch(prospectCompanyIdProvider),
      );
});

final prospectStageHistoryProvider =
    FutureProvider.family<List<ProspectStageHistory>, String>((
      ref,
      prospectId,
    ) {
      return ref
          .watch(prospectRepositoryProvider)
          .fetchStageHistory(
            prospectId: prospectId,
            companyId: ref.watch(prospectCompanyIdProvider),
          );
    });
