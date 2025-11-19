class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String touristId;
  final String nationality;
  final String location;
  final DateTime validUntil;
  final DateTime checkInDate;
  final int duration;
  final String purpose;
  final int groupSize;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.touristId,
    required this.nationality,
    required this.location,
    required this.validUntil,
    required this.checkInDate,
    required this.duration,
    required this.purpose,
    required this.groupSize,
  });

  factory User.demo() {
    return User(
      id: '1',
      name: 'Rajesh Kumar',
      email: 'rajesh@example.com',
      phone: '+91-9876543210',
      profileImage: 'https://i.pravatar.cc/150?u=rajeshkumar',
      touristId: 'TID-2024-001234',
      nationality: 'Indian',
      location: 'Guwahati, Assam',
      validUntil: DateTime(2024, 12, 31),
      checkInDate: DateTime(2024, 11, 15),
      duration: 7,
      purpose: 'Tourism',
      groupSize: 2,
    );
  }
}