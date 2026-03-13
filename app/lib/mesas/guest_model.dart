/// Modelo de invitado
class GuestModel {
  final String id;
  final String name;
  final String tableNumber;
  final String status;

  GuestModel({
    required this.id,
    required this.name,
    required this.tableNumber,
    required this.status,
  });

  factory GuestModel.fromFirestore(String id, Map<String, dynamic> data) {
    return GuestModel(
      id: id,
      name: data['name'] ?? '',
      tableNumber: data['tableNumber']?.toString() ?? '',
      status: data['status'] ?? 'invited',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tableNumber': tableNumber,
      'status': status,
    };
  }
}
