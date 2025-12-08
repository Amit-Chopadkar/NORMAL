class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? userType; // 'indian' or 'international'
  final String? nationality;
  final String? documentUrl;
  final String? hashId;
  final String? blockchainHashId; // Ethereum blockchain hash ID

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.userType,
    this.nationality,
    this.documentUrl,
    this.hashId,
    this.blockchainHashId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'],
      nationality: json['nationality'],
      documentUrl: json['documentUrl'],
      hashId: json['hashId'],
      blockchainHashId: json['blockchainHashId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'nationality': nationality,
      'documentUrl': documentUrl,
      'hashId': hashId,
      'blockchainHashId': blockchainHashId,
    };
  }
}
