import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/debug/network_inspector_toggle.dart';
import '../../../shared/widgets/app_async_status.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/image_preview.dart';
import '../data/attendance_repository.dart';
import '../data/models/attendance_operation_payload.dart';
import '../data/models/effective_today_attendance.dart';
import '../data/models/today_attendance.dart';
import '../workforce_providers.dart';
import 'attendance_location_validator.dart';
import 'attendance_selfie_session_controller.dart';

enum AttendancePresenceType {
  regular('Regular', 'regular'),
  overtime('Lembur', 'overtime');

  const AttendancePresenceType(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

enum AttendanceSelfieAction { checkIn, checkOut }

class AttendanceSelfieRequest {
  const AttendanceSelfieRequest({
    required this.presenceType,
    required this.action,
    this.workplace,
    this.overtimeId,
    this.overtimeLabel,
    this.session,
  });

  final AttendancePresenceType presenceType;
  final AttendanceSelfieAction action;
  final AttendanceWorkplace? workplace;
  final String? overtimeId;
  final String? overtimeLabel;
  final EffectivePresence? session;
}

class AttendanceSelfieResult {
  const AttendanceSelfieResult({required this.stored});

  final AttendanceStored stored;
}

final attendanceSelfieSubmissionServiceProvider =
    Provider<AttendanceSelfieSubmissionService>((ref) {
      return AttendanceSelfieSubmissionService(
        repository: () => ref.read(attendanceRepositoryProvider),
      );
    });

class AttendanceSelfieSubmissionService {
  const AttendanceSelfieSubmissionService({required this.repository});

  final AttendanceRepository? Function() repository;

  Future<AttendanceStored> submit({
    required AttendanceSelfieRequest request,
    required AttendanceCapture capture,
  }) async {
    final attendanceRepository = repository();
    if (attendanceRepository == null) {
      throw StateError('Sesi login tidak tersedia.');
    }

    final result = switch (request.action) {
      AttendanceSelfieAction.checkIn =>
        await attendanceRepository.enqueueCheckIn(
          capture: capture,
          type: request.presenceType == AttendancePresenceType.regular
              ? AttendanceType.regular
              : AttendanceType.overtime,
          overtimeId: request.presenceType == AttendancePresenceType.overtime
              ? request.overtimeId
              : null,
          overtimeLabel: request.presenceType == AttendancePresenceType.overtime
              ? request.overtimeLabel
              : null,
        ),
      AttendanceSelfieAction.checkOut =>
        await attendanceRepository.enqueueCheckOut(
          capture: capture,
          session: request.session!,
        ),
    };
    if (result case AttendanceStoreFailed(:final message)) {
      throw StateError(message);
    }
    return result as AttendanceStored;
  }
}

class WorkforceAttendanceSelfiePage extends ConsumerStatefulWidget {
  const WorkforceAttendanceSelfiePage({required this.request, super.key});

  final AttendanceSelfieRequest request;

  @override
  ConsumerState<WorkforceAttendanceSelfiePage> createState() =>
      _WorkforceAttendanceSelfiePageState();
}

class _WorkforceAttendanceSelfiePageState
    extends ConsumerState<WorkforceAttendanceSelfiePage>
    with WidgetsBindingObserver {
  static const _longProcessThreshold = Duration(seconds: 3);
  static const _progressStatusDelay = Duration(milliseconds: 250);

  AttendanceSelfieSessionController get _session =>
      ref.read(attendanceSelfieSessionControllerProvider);
  bool _isSubmitting = false;
  bool _showProgressStatus = false;
  bool _isTakingLonger = false;
  String? _submissionError;
  Timer? _progressStatusTimer;
  Timer? _longProcessTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_session.selfie == null || _session.position == null)) {
        _prepareSelfieSession();
      }
    });
  }

  @override
  void dispose() {
    _progressStatusTimer?.cancel();
    _longProcessTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !_session.openedLocationSettings ||
        _session.loadingLocation) {
      return;
    }

    _session.resumedFromLocationSettings();
  }

  Future<void> _prepareSelfieSession() async {
    _session.setPreparing(true);
    await _session.loadLocation();
    if (mounted) {
      await _takeSelfie();
    }
    if (mounted) {
      _session.setPreparing(false);
    }
  }

  Future<Position?> _loadLocation() async {
    return _session.loadLocation();
  }

  Future<void> _takeSelfie() async {
    _session.beginCamera();

    try {
      final hasCameraPermission = await _session.ensureCameraPermission();
      if (!mounted) return;

      if (!hasCameraPermission) {
        _session.setCameraError(_session.errorMessage);
        return;
      }

      final image = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(builder: (_) => const _AttendanceCameraPage()),
      );

      if (!mounted) return;

      _session.setCameraResult(image);
    } catch (_) {
      if (!mounted) return;

      _session.setCameraError();
    }
  }

  Future<void> _useSelfie() async {
    if (_isSubmitting) return;
    final selfie = _session.selfie;
    final position = _session.position;
    if (selfie == null || position == null) {
      return;
    }

    final locationError = validateAttendanceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      workplace: widget.request.workplace,
      debugToolsEnabled: networkInspectorEnabled.value,
    );
    if (locationError != null) {
      setState(() => _submissionError = locationError);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showProgressStatus = false;
      _isTakingLonger = false;
      _submissionError = null;
    });
    _progressStatusTimer?.cancel();
    _progressStatusTimer = Timer(_progressStatusDelay, () {
      if (mounted && _isSubmitting) {
        setState(() => _showProgressStatus = true);
      }
    });
    _longProcessTimer?.cancel();
    _longProcessTimer = Timer(_longProcessThreshold, () {
      if (mounted && _isSubmitting) {
        setState(() => _isTakingLonger = true);
      }
    });

    try {
      final stored = await ref
          .read(attendanceSelfieSubmissionServiceProvider)
          .submit(
            request: widget.request,
            capture: AttendanceCapture(
              selfiePath: selfie.path,
              latitude: position.latitude,
              longitude: position.longitude,
              accuracyMeters: position.accuracy,
              isMocked: position.isMocked,
            ),
          );
      if (!mounted) return;
      context.pop(AttendanceSelfieResult(stored: stored));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submissionError = _errorMessage(error);
        _isSubmitting = false;
        _showProgressStatus = false;
        _isTakingLonger = false;
      });
    } finally {
      _progressStatusTimer?.cancel();
      _progressStatusTimer = null;
      _longProcessTimer?.cancel();
      _longProcessTimer = null;
    }
  }

  Future<void> _openLocationSettings() async {
    await _session.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(attendanceSelfieSessionControllerProvider);
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Presensi',
                onBackPressed: _isSubmitting ? null : () => context.pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Expanded(
                        child: _SelfiePreview(
                          selfie: session.selfie,
                          busy:
                              session.openingCamera || session.preparingSession,
                          errorMessage: session.errorMessage,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.request.presenceType.label,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _LocationStatus(
                        position: session.position,
                        loading: session.loadingLocation,
                        showLocationSettings: session.locationServiceDisabled,
                        errorMessage: session.locationErrorMessage,
                        onOpenLocationSettings: _openLocationSettings,
                        onRetry: session.loadingLocation
                            ? null
                            : () => _loadLocation(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_isSubmitting && _showProgressStatus) ...[
                        AppAsyncStatus(
                          message: _isTakingLonger
                              ? 'Proses membutuhkan waktu lebih lama dari biasanya. Jangan tutup aplikasi.'
                              : 'Foto dan lokasi sedang disimpan dengan aman di perangkat.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ] else if (_submissionError case final error?) ...[
                        AppAsyncStatus(
                          message: error,
                          type: AppAsyncStatusType.error,
                          onRetry: _useSelfie,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppButton(
                        label: session.selfie == null
                            ? 'Ambil Selfie'
                            : 'Ambil Ulang',
                        onPressed:
                            _isSubmitting ||
                                session.openingCamera ||
                                session.preparingSession
                            ? null
                            : _takeSelfie,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: _isSubmitting
                            ? 'Menyimpan presensi...'
                            : 'Gunakan Foto',
                        isLoading: _isSubmitting,
                        backgroundColor: AppColors.workforceStatusInfo,
                        onPressed:
                            session.selfie == null ||
                                session.position == null ||
                                session.openingCamera ||
                                session.loadingLocation ||
                                session.preparingSession ||
                                _isSubmitting
                            ? null
                            : _useSelfie,
                      ),
                      SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
    return message.isEmpty
        ? 'Presensi tidak dapat disimpan. Silakan coba lagi.'
        : message;
  }
}

class _AttendanceCameraPage extends StatefulWidget {
  const _AttendanceCameraPage();

  @override
  State<_AttendanceCameraPage> createState() => _AttendanceCameraPageState();
}

class _AttendanceCameraPageState extends State<_AttendanceCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _selectedCamera;
  var _initializing = true;
  var _takingPicture = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePreferredCamera();
  }

  Future<void> _initializePreferredCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'Kamera tidak tersedia.');
      }

      final frontCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      final rearCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selectedCamera = frontCameras.isNotEmpty
          ? frontCameras.first
          : rearCameras.isNotEmpty
          ? rearCameras.first
          : cameras.first;

      _selectedCamera = selectedCamera;
      await _initializeController(selectedCamera);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = error.code == 'CameraAccessDenied'
            ? 'Izin kamera diperlukan untuk presensi.'
            : 'Kamera tidak dapat dibuka.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = 'Kamera tidak dapat dibuka.';
      });
    }
  }

  Future<void> _initializeController(CameraDescription camera) async {
    final previousController = _controller;
    _controller = null;
    await previousController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    await controller.initialize();

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _initializing = false;
      _errorMessage = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    final camera = _selectedCamera;

    if (state == AppLifecycleState.inactive && controller != null) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed &&
        controller == null &&
        camera != null) {
      setState(() => _initializing = true);
      _initializeController(camera);
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _takingPicture) {
      return;
    }

    setState(() => _takingPicture = true);
    try {
      final image = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(image);
    } on CameraException {
      if (!mounted) return;
      setState(() {
        _takingPicture = false;
        _errorMessage = 'Foto gagal diambil. Coba lagi.';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                Center(child: CameraPreview(controller))
              else if (_initializing)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                )
              else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      _errorMessage ?? 'Kamera tidak tersedia.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: IconButton.filled(
                  tooltip: 'Tutup kamera',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              if (controller != null && controller.value.isInitialized)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.xl,
                  child: Center(
                    child: IconButton.filled(
                      tooltip: 'Ambil foto',
                      onPressed: _takingPicture ? null : _takePicture,
                      iconSize: 40,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.black,
                        disabledBackgroundColor: AppColors.white.withValues(
                          alpha: 0.54,
                        ),
                      ),
                      icon: _takingPicture
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationStatus extends StatelessWidget {
  const _LocationStatus({
    required this.position,
    required this.loading,
    required this.showLocationSettings,
    required this.errorMessage,
    required this.onOpenLocationSettings,
    required this.onRetry,
  });

  final Position? position;
  final bool loading;
  final bool showLocationSettings;
  final String? errorMessage;
  final VoidCallback? onOpenLocationSettings;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final text = loading
        ? 'Membaca lokasi...'
        : position != null
        ? 'Koordinat Lokasi: ${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}'
        : errorMessage ?? 'Lokasi belum tersedia.';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontFamily: AppFonts.inter,
              fontSize: 12,
              height: 1.33,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
        if (showLocationSettings && onOpenLocationSettings != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onOpenLocationSettings,
            child: const Text('Buka Pengaturan'),
          ),
        ] else if (!loading && position == null && onRetry != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ],
    );
  }
}

class _SelfiePreview extends StatelessWidget {
  const _SelfiePreview({
    required this.selfie,
    required this.busy,
    required this.errorMessage,
  });

  final XFile? selfie;
  final bool busy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (busy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selfie != null) {
      return ImagePreview.file(
        path: selfie!.path,
        title: 'Pratinjau selfie',
        child: Image.file(
          File(selfie!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text('Preview foto tidak dapat ditampilkan.'),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          errorMessage ?? 'Kamera akan terbuka untuk mengambil foto selfie.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
