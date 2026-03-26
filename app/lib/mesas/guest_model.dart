/// Modelo de invitado
class GuestModel {
  final String id;
  final String name;
  final String tableNumber;
  final String status;
  final String email;
  final String phone;

  GuestModel({
    required this.id,
    required this.name,
    required this.tableNumber,
    required this.status,
    this.email = '',
    this.phone = '',
  });

  factory GuestModel.fromFirestore(String id, Map<String, dynamic> data) {
    return GuestModel(
      id: id,
      name: data['name'] ?? '',
      tableNumber: data['tableNumber']?.toString() ?? '',
      status: data['status'] ?? 'invited',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tableNumber': tableNumber,
      'status': status,
      if (email.isNotEmpty) 'email': email,
      if (phone.isNotEmpty) 'phone': phone,
    };
  }
}
