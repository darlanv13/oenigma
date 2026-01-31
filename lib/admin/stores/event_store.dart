import 'package:mobx/mobx.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/services/firebase_service.dart';

part 'event_store.g.dart';

class EventStore = _EventStore with _$EventStore;

abstract class _EventStore with Store {
  final FirebaseService _service = FirebaseService();

  @observable
  String name = '';

  @observable
  String prize = '';

  @observable
  double price = 0.0;

  @observable
  String iconUrl = ''; // URL do Lottie

  @observable
  String description = '';

  @observable
  String location = '';

  @observable
  String startDate = '';

  @observable
  String eventType = 'classic';

  @observable
  String status = 'dev';

  @observable
  bool isSaving = false;

  @observable
  String? errorMessage;

  @computed
  bool get isValid => name.isNotEmpty && description.isNotEmpty;

  @action
  void setName(String val) => name = val;

  @action
  void setPrize(String val) => prize = val;

  @action
  void setPrice(String val) =>
      price = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;

  @action
  void setIconUrl(String val) => iconUrl = val;

  @action
  void setDescription(String val) => description = val;

  @action
  void setLocation(String val) => location = val;

  @action
  void setStartDate(String val) => startDate = val;

  @action
  void setEventType(String val) => eventType = val;

  @action
  void setStatus(String val) => status = val;

  @action
  void loadFromModel(EventModel event) {
    name = event.name;
    prize = event.prize;
    price = event.price;
    iconUrl = event.icon;
    description = event.fullDescription;
    location = event.location;
    startDate = event.startDate;
    eventType = event.eventType;
    status = event.status;
  }

  @action
  Future<bool> saveEvent(String? eventId) async {
    if (!isValid) {
      errorMessage = "Preencha os campos obrigatórios.";
      return false;
    }

    isSaving = true;
    errorMessage = null;

    try {
      final data = {
        'name': name,
        'prize': prize,
        'price': price,
        'icon': iconUrl,
        'fullDescription': description,
        'location': location,
        'startDate': startDate,
        'eventType': eventType,
        'status': status,
      };

      await _service.createOrUpdateEvent(eventId: eventId, data: data);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isSaving = false;
    }
  }
}
