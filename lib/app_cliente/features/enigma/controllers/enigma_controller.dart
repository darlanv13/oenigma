import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/app_cliente/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/app_cliente/features/enigma/repositories/enigma_repository.dart';
import 'package:oenigma/app_cliente/features/enigma/services/decoy_location_service.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/enigma_dialogs.dart';
import 'package:oenigma/app_cliente/features/event/repositories/event_repository.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';

/// Controller para gerenciar todo o ciclo de vida, estado, telemetria GPS e
/// requisições da tela do Enigma.
class EnigmaController extends ChangeNotifier {
  final EventModel event;
  final PhaseModel phase;
  final EnigmaRepository _enigmaRepository;
  final EventRepository _eventService;

  late EnigmaModel _currentEnigma;
  bool _isLoading = false;
  bool _isLoadingHints = true;
  StreamSubscription<Position>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isBlocked = false;
  Timer? _statusPollTimer;

  // Ferramentas e Dicas (Padrão: 15 minutos = 900s de uso ativo)
  bool _hasCompass = false;
  bool _hasMap = false;
  bool _hasRadar = false;
  int _selectedTacticalTab = 0;
  Map<String, double>? _destinationLocation;
  int _compassDuration = 900;
  double _compassPrice = 15.0;
  int _compassRemainingSeconds = 900;
  int _radarRemainingSeconds = 900;
  int _mapRemainingSeconds = 900;

  // Gerenciamento seguro de tempo de uso ativo (Zero Trust)
  String? _activeTool;
  Timer? _activeToolTimer;
  int _unsyncedSeconds = 0;

  List<ParseObject> _hintsList = [];
  List<String> _hintsPurchased = [];

  EnigmaController({
    required this.event,
    required this.phase,
    required EnigmaModel initialEnigma,
    EnigmaRepository? enigmaRepository,
    EventRepository? eventService,
  })  : _currentEnigma = initialEnigma,
        _enigmaRepository = enigmaRepository ?? EnigmaRepository(),
        _eventService = eventService ?? EventRepository();

  // Getters de Estado
  EnigmaModel get currentEnigma => _currentEnigma;
  bool get isLoading => _isLoading;
  bool get isLoadingHints => _isLoadingHints;
  bool get isNear => _isNear;
  double? get distance => _distance;
  bool get isBlocked => _isBlocked;
  bool get hasCompass => _hasCompass;
  bool get hasMap => _hasMap;
  bool get hasRadar => _hasRadar;
  int get selectedTacticalTab => _selectedTacticalTab;
  Map<String, double>? get destinationLocation => _destinationLocation;
  int get compassDuration => _compassDuration;
  double get compassPrice => _compassPrice;
  int get compassRemainingSeconds => _compassRemainingSeconds;
  int get radarRemainingSeconds => _radarRemainingSeconds;
  int get mapRemainingSeconds => _mapRemainingSeconds;
  String? get activeTool => _activeTool;
  List<ParseObject> get hintsList => _hintsList;
  List<String> get hintsPurchased => _hintsPurchased;

  bool get isClassic => event.eventType == 'classic';
  bool get isGpsEnigma => _currentEnigma.type == 'gps';
  bool get isActionReady => (!isGpsEnigma || _isNear) && !_isBlocked;
  bool get enableToolTimer => _currentEnigma.enableToolTimer;
  bool get enableFakeTargets => _currentEnigma.enableFakeTargets;

  double? get targetLatitude =>
      _destinationLocation?['latitude'] ?? _currentEnigma.location?.latitude;
  double? get targetLongitude =>
      _destinationLocation?['longitude'] ?? _currentEnigma.location?.longitude;

  /// Retorna deterministamente os alvos da caçada:
  /// Se enableFakeTargets for false, retorna APENAS o alvo real da relíquia!
  /// Se enableFakeTargets for true, retorna os 5 alvos (1 real + 4 fakes num raio de 300m).
  List<DecoyTarget> get targets {
    final lat = targetLatitude;
    final lng = targetLongitude;
    if (lat == null || lng == null) return [];
    if (!_currentEnigma.enableFakeTargets) {
      return [
        DecoyTarget(
          index: 1,
          label: 'Alvo Principal',
          latitude: lat,
          longitude: lng,
          isReal: true,
        ),
      ];
    }
    return DecoyLocationService.generateTargets(
      enigmaId: _currentEnigma.id,
      trueLatitude: lat,
      trueLongitude: lng,
    );
  }

  void setSelectedTacticalTab(int index) {
    _selectedTacticalTab = index;
    if (!_currentEnigma.enableToolTimer) {
      // Cronômetro desabilitado no painel admin para este enigma: uso livre
      setActiveTool(null);
      notifyListeners();
      return;
    }
    switch (index) {
      case 1:
        if (_hasCompass && _compassRemainingSeconds > 0) {
          setActiveTool('compass');
        } else {
          setActiveTool(null);
        }
        break;
      case 2:
        if (_hasRadar && _radarRemainingSeconds > 0) {
          setActiveTool('radar');
        } else {
          setActiveTool(null);
        }
        break;
      case 3:
        if (_hasMap && _mapRemainingSeconds > 0) {
          setActiveTool('map');
        } else {
          setActiveTool(null);
        }
        break;
      default:
        setActiveTool(null);
        break;
    }
    notifyListeners();
  }

  /// Define qual ferramenta está aberta/visível.
  /// A contagem só roda para a ferramenta aberta. Se fechar ou trocar, a contagem pausa.
  void setActiveTool(String? toolType) {
    if (_activeTool == toolType) return;

    // Sincroniza o uso da ferramenta anterior
    if (_activeTool != null && _unsyncedSeconds > 0) {
      _syncToolUsageSilently(_activeTool!, _unsyncedSeconds);
      _unsyncedSeconds = 0;
    }

    _activeToolTimer?.cancel();
    _activeTool = toolType;

    if (_activeTool != null) {
      _startActiveToolTimer();
    }
    notifyListeners();
  }

  void _startActiveToolTimer() {
    _activeToolTimer?.cancel();
    _activeToolTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = _activeTool;
      if (current == null) {
        timer.cancel();
        return;
      }

      int remaining = getToolRemainingSeconds(current);
      if (remaining > 0) {
        remaining--;
        _setToolRemainingSeconds(current, remaining);
        _unsyncedSeconds++;

        // Sincroniza a cada 15 segundos de uso ativo ininterrupto
        if (_unsyncedSeconds >= 15) {
          _syncToolUsageSilently(current, _unsyncedSeconds);
          _unsyncedSeconds = 0;
        }
        notifyListeners();
      } else {
        timer.cancel();
        onToolTimeUp(current);
      }
    });
  }

  int getToolRemainingSeconds(String toolType) {
    switch (toolType) {
      case 'compass':
        return _compassRemainingSeconds;
      case 'radar':
        return _radarRemainingSeconds;
      case 'map':
        return _mapRemainingSeconds;
      default:
        return 0;
    }
  }

  void _setToolRemainingSeconds(String toolType, int seconds) {
    switch (toolType) {
      case 'compass':
        _compassRemainingSeconds = seconds;
        break;
      case 'radar':
        _radarRemainingSeconds = seconds;
        break;
      case 'map':
        _mapRemainingSeconds = seconds;
        break;
    }
    _saveLocalToolRemaining(toolType, seconds);
  }

  Future<void> _saveLocalToolRemaining(String toolType, int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tool_remaining_${_currentEnigma.id}_$toolType', seconds);
    } catch (_) {}
  }

  Future<int?> _loadLocalToolRemaining(String toolType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('tool_remaining_${_currentEnigma.id}_$toolType');
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncToolUsageSilently(String toolType, int usedSeconds) async {
    try {
      await _enigmaRepository.callEnigmaFunction('syncToolUsage', {
        'eventId': event.id,
        'phaseOrder': phase.order,
        'enigmaId': _currentEnigma.id,
        'toolType': toolType,
        'usedSeconds': usedSeconds,
      });
    } catch (_) {}
  }

  void updateCompassRemainingSeconds(int seconds) {
    _compassRemainingSeconds = seconds;
    _saveLocalToolRemaining('compass', seconds);
    notifyListeners();
  }

  void updateRadarRemainingSeconds(int seconds) {
    _radarRemainingSeconds = seconds;
    _saveLocalToolRemaining('radar', seconds);
    notifyListeners();
  }

  void updateMapRemainingSeconds(int seconds) {
    _mapRemainingSeconds = seconds;
    _saveLocalToolRemaining('map', seconds);
    notifyListeners();
  }

  void onRadarTimeUp(BuildContext context) {
    onToolTimeUp('radar', context: context);
  }

  void onMapTimeUp(BuildContext context) {
    onToolTimeUp('map', context: context);
  }

  void onToolTimeUp(String toolType, {BuildContext? context}) {
    switch (toolType) {
      case 'compass':
        _hasCompass = false;
        _compassRemainingSeconds = 0;
        break;
      case 'radar':
        _hasRadar = false;
        _radarRemainingSeconds = 0;
        break;
      case 'map':
        _hasMap = false;
        _mapRemainingSeconds = 0;
        break;
    }
    _activeTool = null;
    _activeToolTimer?.cancel();
    _consumeToolSilently(toolType);
    setSelectedTacticalTab(0);
    notifyListeners();

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Os 15 minutos de uso de $toolType se esgotaram!'),
          backgroundColor: AppColors.amareloVale,
        ),
      );
    }
  }

  void onCompassTimeUp(BuildContext context) {
    onToolTimeUp('compass', context: context);
  }

  /// Inicializa o estado do enigma carregando GPS, dicas e status remoto
  Future<void> resetEnigmaState(BuildContext context) async {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    _activeToolTimer?.cancel();
    _activeTool = null;
    _unsyncedSeconds = 0;

    _distance = null;
    _isNear = false;
    _isBlocked = false;
    _isLoading = true;
    _hasCompass = false;
    _hasMap = false;
    _hasRadar = false;
    _destinationLocation = null;
    _compassRemainingSeconds = 900;
    _radarRemainingSeconds = 900;
    _mapRemainingSeconds = 900;
    _isLoadingHints = true;
    notifyListeners();

    try {
      if (_currentEnigma.location != null && context.mounted) {
        await initializeGpsListener(context);
      }
      await loadHints();
      if (context.mounted) {
        await fetchInitialStatus(context);
      }
    } catch (e) {
      debugPrint("Erro na inicialização do enigma: $e");
      if (context.mounted) {
        await loadOfflineCache(context);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega informações do cache local caso a rede falhe
  Future<void> loadOfflineCache(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('enigma_cache_${_currentEnigma.id}');
      if (cached != null) {
        final statusData = Map<String, dynamic>.from(jsonDecode(cached));
        _hintsPurchased = List<String>.from(statusData['hintsPurchased'] ?? []);
        _isBlocked = statusData['isBlocked'] ?? false;
        _hasCompass = statusData['hasCompass'] ?? _currentEnigma.hasCompass;
        _hasMap = statusData['hasMap'] ?? _currentEnigma.hasMap;
        _hasRadar = statusData['hasRadar'] ?? _currentEnigma.hasRadar;
        _compassDuration = 900;
        _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;
        if (_compassPrice == 0.0) _compassPrice = 15.0;

        final localCompass = await _loadLocalToolRemaining('compass');
        final localRadar = await _loadLocalToolRemaining('radar');
        final localMap = await _loadLocalToolRemaining('map');

        _compassRemainingSeconds = localCompass ?? (statusData['compassRemainingSeconds'] as num?)?.toInt() ?? 900;
        _radarRemainingSeconds = localRadar ?? (statusData['radarRemainingSeconds'] as num?)?.toInt() ?? 900;
        _mapRemainingSeconds = localMap ?? (statusData['mapRemainingSeconds'] as num?)?.toInt() ?? 900;

        if (statusData['destinationLocation'] != null) {
          _destinationLocation = {
            'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
            'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
          };
        }

        if (statusData['enableToolTimer'] != null || statusData['enableFakeTargets'] != null) {
          _currentEnigma = _currentEnigma.copyWith(
            enableToolTimer: statusData['enableToolTimer'] != null
                ? statusData['enableToolTimer'] == true
                : _currentEnigma.enableToolTimer,
            enableFakeTargets: statusData['enableFakeTargets'] != null
                ? statusData['enableFakeTargets'] == true
                : _currentEnigma.enableFakeTargets,
          );
        }
        notifyListeners();

        if (_isBlocked && statusData['cooldownUntil'] != null && context.mounted) {
          handleCooldown(statusData['cooldownUntil'], context);
        }
      }
    } catch (_) {}
  }

  /// Busca a lista de dicas cadastradas via Cloud Function (SecOps Zero Trust)
  Future<void> loadHints() async {
    try {
      final response = await _enigmaRepository.callFunction('getEnigmaHints', {
        'enigmaId': _currentEnigma.id,
        'eventId': event.id,
      });

      if (response.success && response.result is List) {
        final list = response.result as List;
        _hintsList = list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ParseObject('Hint')
            ..objectId = map['id'] ?? map['objectId']
            ..set('price', map['price'])
            ..set('type', map['type'])
            ..set('description', map['description'])
            ..set('data', map['data']);
        }).toList();
      }
    } catch (e) {
      debugPrint("Erro ao carregar dicas: $e");
    } finally {
      _isLoadingHints = false;
      notifyListeners();
    }
  }

  /// Busca o status atualizado do enigma via Cloud Function
  Future<void> fetchInitialStatus(BuildContext context) async {
    try {
      final result = await _enigmaRepository.callEnigmaFunction('getStatus', {
        'eventId': event.id,
        'phaseOrder': phase.order,
        'enigmaId': _currentEnigma.id,
      });

      if (result.success && result.result != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'enigma_cache_${_currentEnigma.id}',
            jsonEncode(result.result),
          );
        } catch (_) {}

        final statusData = Map<String, dynamic>.from(result.result);
        _hintsPurchased = List<String>.from(statusData['hintsPurchased'] ?? []);
        _isBlocked = statusData['isBlocked'] ?? false;
        _hasCompass = statusData['hasCompass'] ?? _currentEnigma.hasCompass;
        _hasMap = statusData['hasMap'] ?? _currentEnigma.hasMap;
        _hasRadar = statusData['hasRadar'] ?? _currentEnigma.hasRadar;
        _compassDuration = 900;
        _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;
        if (_compassPrice == 0.0) _compassPrice = 15.0;

        final remoteCompass = (statusData['compassRemainingSeconds'] as num?)?.toInt() ??
            (statusData['toolTimes']?['compass'] as num?)?.toInt() ?? 900;
        final remoteRadar = (statusData['radarRemainingSeconds'] as num?)?.toInt() ??
            (statusData['toolTimes']?['radar'] as num?)?.toInt() ?? 900;
        final remoteMap = (statusData['mapRemainingSeconds'] as num?)?.toInt() ??
            (statusData['toolTimes']?['map'] as num?)?.toInt() ?? 900;

        final localCompass = await _loadLocalToolRemaining('compass');
        final localRadar = await _loadLocalToolRemaining('radar');
        final localMap = await _loadLocalToolRemaining('map');

        // Pega o menor valor para segurança anti-burla (Zero Trust)
        _compassRemainingSeconds = (localCompass != null && localCompass < remoteCompass) ? localCompass : remoteCompass;
        _radarRemainingSeconds = (localRadar != null && localRadar < remoteRadar) ? localRadar : remoteRadar;
        _mapRemainingSeconds = (localMap != null && localMap < remoteMap) ? localMap : remoteMap;

        if (statusData['destinationLocation'] != null) {
          _destinationLocation = {
            'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
            'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
          };
        }

        if (statusData['enableToolTimer'] != null || statusData['enableFakeTargets'] != null) {
          _currentEnigma = _currentEnigma.copyWith(
            enableToolTimer: statusData['enableToolTimer'] != null
                ? statusData['enableToolTimer'] == true
                : _currentEnigma.enableToolTimer,
            enableFakeTargets: statusData['enableFakeTargets'] != null
                ? statusData['enableFakeTargets'] == true
                : _currentEnigma.enableFakeTargets,
          );
        }
        notifyListeners();

        if (_isBlocked && statusData['cooldownUntil'] != null && context.mounted) {
          handleCooldown(statusData['cooldownUntil'], context);
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar status: $e");
    }
  }

  /// Trata a contagem regressiva de cooldown e exibe o diálogo de bloqueio
  void handleCooldown(dynamic rawCooldown, BuildContext context) {
    if (rawCooldown == null) return;
    DateTime? cooldownUntil;
    if (rawCooldown is num) {
      cooldownUntil = DateTime.fromMillisecondsSinceEpoch(rawCooldown.toInt());
    } else if (rawCooldown is String) {
      final asNum = num.tryParse(rawCooldown);
      if (asNum != null) {
        cooldownUntil = DateTime.fromMillisecondsSinceEpoch(asNum.toInt());
      } else {
        cooldownUntil = DateTime.tryParse(rawCooldown);
      }
    } else if (rawCooldown is DateTime) {
      cooldownUntil = rawCooldown;
    }

    if (cooldownUntil != null && cooldownUntil.isAfter(DateTime.now())) {
      final targetCooldown = cooldownUntil;
      _isBlocked = true;
      notifyListeners();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: targetCooldown,
          onCooldownFinished: () {
            _isBlocked = false;
            notifyListeners();
          },
        ),
      );
    }
  }

  /// Inicializa o listener de GPS para cálculo de distância e anti-fraude
  Future<void> initializeGpsListener(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position currentLocation) {
      if (_currentEnigma.location == null) return;

      if (currentLocation.isMocked) {
        _distance = null;
        _isNear = false;
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Fake GPS detectado!'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        try {
          _enigmaRepository.callFunction('reportFraud', {
            'eventId': event.id,
            'enigmaId': _currentEnigma.id,
            'reason': 'Fake GPS Detectado',
          });
        } catch (_) {}
        return;
      }

      final distanceInMeters = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentEnigma.location!.latitude,
        _currentEnigma.location!.longitude,
      );

      _distance = distanceInMeters;
      _isNear = distanceInMeters <= 100;
      notifyListeners();
    });
  }

  /// Compra de ferramentas (bússola ou mapa)
  Future<void> handleToolPurchase(String toolType, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _enigmaRepository.callEnigmaFunction(
        'purchaseTool',
        {'eventId': event.id, 'toolType': toolType},
      );

      final data = Map<String, dynamic>.from(result.result);

      if (data['success'] ?? false) {
        _setToolRemainingSeconds(toolType, 900);
        switch (toolType) {
          case 'compass':
            _hasCompass = true;
            _compassRemainingSeconds = 900;
            setSelectedTacticalTab(1);
            break;
          case 'radar':
            _hasRadar = true;
            _radarRemainingSeconds = 900;
            setSelectedTacticalTab(2);
            break;
          case 'map':
            _hasMap = true;
            _mapRemainingSeconds = 900;
            setSelectedTacticalTab(3);
            break;
        }
        if (context.mounted) {
          await fetchInitialStatus(context);
        }
        if (context.mounted) {
          EnigmaDialogs.showToolActivated(context, toolType);
        }
      }
    } on ParseError catch (e) {
      if (e.message.contains('saldo') == true ||
          e.message.contains('Saldo insuficiente') == true) {
        if (context.mounted) EnigmaDialogs.showInsufficientFunds(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Consome a ferramenta sem exibir diálogo
  Future<void> _consumeToolSilently(String toolType) async {
    try {
      await _enigmaRepository.callEnigmaFunction('consumeTool', {
        'eventId': event.id,
        'phaseOrder': phase.order,
        'enigmaId': _currentEnigma.id,
        'toolType': toolType,
      });
    } catch (_) {}
  }

  /// Executa ações do enigma (validação de código, compra de dica, etc.)
  Future<void> handleAction(
    String action, {
    required BuildContext context,
    String? code,
    String? toolType,
    String? hintId,
    required VoidCallback onEnigmaSolved,
    required VoidCallback onShake,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      double? currentLat;
      double? currentLng;

      // Validação Geográfica para o Anti-Fraude
      if (action == 'validateCode' || action == 'verify_code' || action == 'scan_enigma') {
        try {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          currentLat = position.latitude;
          currentLng = position.longitude;
        } catch (_) {
          throw 'É necessário ativar o GPS para validar o enigma.';
        }
      }

      final result = await _enigmaRepository.callEnigmaFunction(action, {
        'eventId': event.id,
        'phaseOrder': phase.order,
        'enigmaId': _currentEnigma.id,
        'code': ?code,
        'toolType': ?toolType,
        'hintId': ?hintId,
        'latitude': ?currentLat,
        'longitude': ?currentLng,
      });

      final data = Map<String, dynamic>.from(result.result);
      final success = data['success'] ?? false;

      if (success) {
        if (action == 'consumeTool') {
          return;
        } else if (action == 'purchaseHint') {
          SoundService.playUnlock();
          if (context.mounted) {
            await fetchInitialStatus(context);
          }
        } else if (action == 'validateCode') {
          final nextStep = data['nextStep'] != null
              ? Map<String, dynamic>.from(data['nextStep'])
              : null;
          if (nextStep == null) return;

          switch (nextStep['type']) {
            case 'find_and_win_complete':
              SoundService.playReward();
              final double prizeWon = (nextStep['prizeWon'] is num)
                  ? (nextStep['prizeWon'] as num).toDouble()
                  : (double.tryParse(nextStep['prizeWon']?.toString() ?? '0') ?? 0.0);
              if (context.mounted) {
                await EnigmaDialogs.showChestWon(
                  context,
                  prizeWon: prizeWon,
                  onDismiss: () {
                    onEnigmaSolved();
                    Navigator.of(context).pop();
                  },
                );
              }
              break;

            case 'event_complete':
              final double prizeWon = (nextStep['prizeWon'] is num)
                  ? (nextStep['prizeWon'] as num).toDouble()
                  : (double.tryParse(nextStep['prizeWon']?.toString() ?? '0') ?? 0.0);
              final bool isWinner = nextStep['isWinner'] == true;
              if (isWinner) {
                SoundService.playVictory();
              } else {
                SoundService.playSuccess();
              }
              final String winnerName = (nextStep['winnerName'] ??
                      event.winnerName ??
                      'Outro explorador')
                  .toString();
              final List<PhaseModel> allPhases =
                  await _eventService.getPhasesForEvent(event.id);

              if (context.mounted) {
                if (isWinner) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => WinnerCertificateScreen(
                        event: event,
                        prizeWon: prizeWon,
                        allPhases: allPhases,
                      ),
                    ),
                  );
                } else {
                  await EnigmaDialogs.showJourneyCompleted(
                    context,
                    event: event,
                    winnerName: winnerName,
                    onDismiss: () => Navigator.of(context).pop(),
                  );
                }
              }
              break;

            case 'next_enigma':
              SoundService.playSuccess();
              if (nextStep['enigmaData'] != null &&
                  nextStep['enigmaData'] is Map &&
                  (nextStep['enigmaData'] as Map).isNotEmpty) {
                final nextEnigma = EnigmaModel.fromMap(
                  Map<String, dynamic>.from(nextStep['enigmaData']),
                );
                if (context.mounted) {
                  await EnigmaDialogs.showNextEnigmaUnlocked(
                    context,
                    onNextPressed: () async {
                      _currentEnigma = nextEnigma;
                      notifyListeners();
                      await resetEnigmaState(context);
                    },
                  );
                }
              } else if (phase.id == 'find_and_win' || event.eventType == 'find_and_win') {
                final double prizeWon = (nextStep['prizeWon'] is num)
                    ? (nextStep['prizeWon'] as num).toDouble()
                    : (double.tryParse(nextStep['prizeWon']?.toString() ?? '0') ?? 0.0);
                if (context.mounted) {
                  await EnigmaDialogs.showChestWon(
                    context,
                    prizeWon: prizeWon,
                    onDismiss: () {
                      onEnigmaSolved();
                      Navigator.of(context).pop();
                    },
                  );
                }
              }
              break;

            case 'phase_complete':
              SoundService.playVictory();
              if (context.mounted) {
                showCompletionDialog(
                  context,
                  isPhaseComplete: true,
                  onOkPressed: () {
                    Navigator.of(context).pop();
                    onEnigmaSolved();
                    Navigator.of(context).pop();
                  },
                );
              }
              break;
          }
        }
      } else {
        SoundService.playError();
        final message = data['message'] ?? 'Ação falhou.';
        if (action == 'validateCode') onShake();

        if (data['cooldownUntil'] != null && context.mounted) {
          handleCooldown(data['cooldownUntil'], context);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.danger),
          );
        }
      }
    } on ParseError catch (e) {
      if (action == 'validateCode') SoundService.playError();
      if (e.message.contains('saldo') == true ||
          e.message.contains('Saldo insuficiente') == true) {
        if (context.mounted) EnigmaDialogs.showInsufficientFunds(context);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (action == 'validateCode') SoundService.playError();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_activeTool != null && _unsyncedSeconds > 0) {
      _syncToolUsageSilently(_activeTool!, _unsyncedSeconds);
      _unsyncedSeconds = 0;
    }
    _activeToolTimer?.cancel();
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }
}
