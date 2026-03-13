import 'guest_model.dart';

/// Modelo de mesa
class MesaModel {
  final String number;
  final List<GuestModel> guests;

  MesaModel({
    required this.number,
    required this.guests,
  });

  factory MesaModel.fromFirestore(String id, Map<String, dynamic> data) {
    final guestsRaw = data['guests'] as List<dynamic>? ?? [];
    final guests = guestsRaw.map((guest) {
      if (guest is Map<String, dynamic>) {
        final guestId = guest['id']?.toString() ?? '';
        return GuestModel.fromFirestore(guestId, guest);
      }
      if (guest is String) {
        return GuestModel(
          id: guest,
          name: guest,
          tableNumber: id,
          status: 'invited',
        );
      }
      return GuestModel(
        id: '',
        name: '',
        tableNumber: id,
        status: 'invited',
      );
    }).toList();

    return MesaModel(
      number: data['number']?.toString() ?? id,
      guests: guests,
    );
  }
}
