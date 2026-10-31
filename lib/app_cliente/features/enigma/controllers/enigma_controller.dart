import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/app_cliente/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/app_cliente/features/enigma/repositories/enigma_repository.dart';
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

  // Ferramentas e Dicas
  bool _hasCompass = false;
  bool _hasMap = false;
  bool _hasRadar = false;
  int _selectedTacticalTab = 0;
  Map<String, double>? _destinationLocation;
  int _compassDuration = 0;
  double _compassPrice = 15.0;
  int? _compassRemainingSeconds;

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
  int? get compassRemainingSeconds => _compassRemainingSeconds;
  List<ParseObject> get hintsList => _hintsList;
  List<String> get hintsPurchased => _hintsPurchased;

  bool get isClassic => event.eventType == 'classic';
  bool get isGpsEnigma => _currentEnigma.type == 'gps';
  bool get isActionReady => (!isGpsEnigma || _isNear) && !_isBlocked;

  double? get targetLatitude =>
      _destinationLocation?['latitude'] ?? _currentEnigma.location?.latitude;
  double? get targetLongitude =>
      _destinationLocation?['longitude'] ?? _currentEnigma.location?.longitude;

  void setSelectedTacticalTab(int index) {
    _selectedTacticalTab = index;
    notifyListeners();
  }

  void updateCompassRemainingSeconds(int seconds) {
    _compassRemainingSeconds = seconds;
    notifyListeners();
  }

  void onCompassTimeUp(BuildContext context) {
    _hasCompass = false;
    _compassRemainingSeconds = null;
    notifyListeners();

    _consumeToolSilently('compass');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O tempo da bússola acabou!'),
          backgroundColor: AppColors.amareloVale,
        ),
      );
    }
  }

  /// Inicializa o estado do enigma carregando GPS, dicas e status remoto
  Future<void> resetEnigmaState(BuildContext context) async {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();

    _distance = null;
    _isNear = false;
    _isBlocked = false;
    _isLoading = true;
    _hasCompass = false;
    _hasMap = false;
    _hasRadar = false;
    _destinationLocation = null;
    _compassRemainingSeconds = null;
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
        _compassDuration = statusData['compassDuration'] ?? _currentEnigma.compassDuration;
        _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;
        if (_compassPrice == 0.0) _compassPrice = 15.0;

        if (statusData['destinationLocation'] != null) {
          _destinationLocation = {
            'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
            'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
          };
        }
        _compassRemainingSeconds ??= _compassDuration;
        notifyListeners();

        if (_isBlocked && statusData['cooldownUntil'] != null && context.mounted) {
          handleCooldown(statusData['cooldownUntil'], context);
        }
      }
    } catch (_) {}
  }

  /// Busca a lista de dicas cadastradas no Parse
  Future<void> loadHints() async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Hint'))
        ..whereEqualTo('linkedEnigmaId', _currentEnigma.id);

      final response = await query.query();

      if (response.success && response.results != null) {
        _hintsList = response.results as List<ParseObject>;
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
        _compassDuration = statusData['compassDuration'] ?? _currentEnigma.compassDuration;
        _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;
        if (_compassPrice == 0.0) _compassPrice = 15.0;

        if (statusData['destinationLocation'] != null) {
          _destinationLocation = {
            'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
            'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
          };
        }
        _compassRemainingSeconds ??= _compassDuration;
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
        ParseUser.currentUser().then((user) {
          if (user != null && user is ParseUser) {
            ParseObject('FraudLog')
              ..set('objectId', user.objectId)
              ..set('eventId', event.id)
              ..set('enigmaId', _currentEnigma.id)
              ..set('reason', 'Fake GPS Detectado')
              ..save();
          }
        });
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
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }
}
