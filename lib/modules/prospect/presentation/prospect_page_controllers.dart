import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/page_open_refresh_scope.dart';
import '../prospect_providers.dart';
import 'prospect_detail/prospect_detail_page.dart';

final prospectKanbanPageControllerProvider =
    Provider.autoDispose<ProspectKanbanPageController>((ref) {
      return ProspectKanbanPageController(ref);
    });

final prospectCreatePageControllerProvider =
    Provider.autoDispose<ProspectCreatePageController>((ref) {
      return ProspectCreatePageController(ref);
    });

final prospectDetailPageControllerProvider = Provider.autoDispose
    .family<ProspectDetailPageController, ProspectDetailData>((ref, detail) {
      return ProspectDetailPageController(ref, detail);
    });

class ProspectKanbanPageController implements PageOpenRefreshController {
  const ProspectKanbanPageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(prospectPipelineProvider);
  }
}

class ProspectCreatePageController implements PageOpenRefreshController {
  const ProspectCreatePageController(this._ref);

  final Ref _ref;

  @override
  void refresh() {
    _ref.invalidateIfExists(prospectProjectTypesProvider);
  }
}

class ProspectDetailPageController implements PageOpenRefreshController {
  const ProspectDetailPageController(this._ref, this._detail);

  final Ref _ref;
  final ProspectDetailData _detail;

  @override
  void refresh() {
    if (_detail.id.isEmpty) return;
    _ref.invalidateIfExists(prospectDetailProvider(_detail.id));
    _ref.invalidateIfExists(prospectStageHistoryProvider(_detail.id));
  }
}
