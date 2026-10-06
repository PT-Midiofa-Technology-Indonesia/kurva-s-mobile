import '../../../../core/constants/asset_paths.dart';

class ProspectDetailData {
  const ProspectDetailData({
    required this.id,
    required this.currentStageValue,
    required this.stage,
    required this.title,
    required this.client,
    required this.dateRange,
    required this.projectValue,
    required this.description,
    required this.availableStages,
    required this.documents,
    required this.stageHistory,
    this.activityDescription,
    this.activityDocuments = const [],
  });

  static const defaultStageHistory = [
    StageHistoryData(
      stage: 'Tender Preparation',
      date: '10 Jul 2026',
      isCurrent: true,
    ),
    StageHistoryData(
      stage: 'Qualify',
      date: '30 Jun 2026',
      documents: [
        StageDocumentData(name: 'Document-1.doc', size: '89.5 KB'),
        StageDocumentData(name: 'Document-2.doc', size: '89.5 KB'),
      ],
    ),
    StageHistoryData(
      stage: 'Prospect Identify',
      date: '25 Jun 2026',
      documents: [
        StageDocumentData(name: 'NPWP.doc', size: '89.5 KB'),
        StageDocumentData(name: 'SIUP.doc', size: '89.5 KB'),
      ],
      activity:
          'Proyek pembangunan jembatan penghubung antar kecamatan dengan estimasi pekerjaan struktur utama dan akses jalan.',
      image: StageDocumentData(
        name: 'ktp.jpg',
        size: '89.5 KB',
        thumbnailPath: AssetPaths.iconProspect,
      ),
    ),
  ];

  factory ProspectDetailData.fallback() {
    return const ProspectDetailData(
      id: '',
      currentStageValue: 'prospect_identify',
      stage: 'Prospect Identify',
      title: 'Pembangunan Jembatan Sungai Cempaka',
      client: 'CV Pembangunan Indonesia',
      dateRange: 'Jun 20 - Des 20, 2026',
      projectValue: 'Rp 1.500.000.000',
      description:
          'Proyek pembangunan jembatan penghubung antar kecamatan dengan estimasi pekerjaan struktur utama dan akses jalan.',
      availableStages: [],
      documents: [
        ProspectDocumentData(title: 'Kartu Tanda Penduduk'),
        ProspectDocumentData(title: 'Nomor Pokok Wajib Pajak'),
        ProspectDocumentData(title: 'Surat Keterangan Catatan Kepolisian'),
      ],
      stageHistory: defaultStageHistory,
    );
  }

  final String id;
  final String currentStageValue;
  final String stage;
  final String title;
  final String client;
  final String dateRange;
  final String projectValue;
  final String description;
  final List<ProspectStageOptionData> availableStages;
  final List<ProspectDocumentData> documents;
  final List<StageHistoryData> stageHistory;
  final String? activityDescription;
  final List<StageDocumentData> activityDocuments;

  ProspectDetailData copyWith({
    String? stage,
    List<StageHistoryData>? stageHistory,
    String? activityDescription,
    List<StageDocumentData>? activityDocuments,
  }) {
    return ProspectDetailData(
      id: id,
      currentStageValue: currentStageValue,
      stage: stage ?? this.stage,
      title: title,
      client: client,
      dateRange: dateRange,
      projectValue: projectValue,
      description: description,
      availableStages: availableStages,
      documents: documents,
      stageHistory: stageHistory ?? this.stageHistory,
      activityDescription: activityDescription ?? this.activityDescription,
      activityDocuments: activityDocuments ?? this.activityDocuments,
    );
  }
}

class ProspectStageOptionData {
  const ProspectStageOptionData({required this.value, required this.label});

  final String value;
  final String label;
}

class ProspectDocumentData {
  const ProspectDocumentData({
    required this.title,
    this.requirementId,
    this.documentTypeId,
    this.isMandatory = false,
    this.allowedFileTypes = '',
    this.allowedFileSize = 0,
    this.uploadedDocuments = const [],
  });

  final String title;
  final String? requirementId;
  final String? documentTypeId;
  final bool isMandatory;
  final String allowedFileTypes;
  final int allowedFileSize;
  final List<ProspectUploadedDocumentData> uploadedDocuments;
}

class ProspectUploadedDocumentData {
  const ProspectUploadedDocumentData({
    required this.id,
    required this.name,
    required this.size,
    required this.url,
  });

  final String id;
  final String name;
  final int size;
  final String url;
}

class StageHistoryData {
  const StageHistoryData({
    required this.stage,
    required this.date,
    this.documents = const [],
    this.activityDocuments = const [],
    this.activity,
    this.image,
    this.isCurrent = false,
    this.dateValue,
  });

  final String stage;
  final String date;
  final List<StageDocumentData> documents;
  final List<StageDocumentData> activityDocuments;
  final String? activity;
  final StageDocumentData? image;
  final bool isCurrent;
  final DateTime? dateValue;
}

class StageDocumentData {
  const StageDocumentData({
    this.id = '',
    required this.name,
    required this.size,
    this.sizeBytes = 0,
    this.fileUrl,
    this.thumbnailPath,
  });

  final String id;
  final String name;
  final String size;
  final int sizeBytes;
  final String? fileUrl;
  final String? thumbnailPath;
}
