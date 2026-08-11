import 'package:equatable/equatable.dart';

class Court extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int courtNumber;
  final String? imageUrl;
  final int pricePerHour;
  final bool isActive;
  final DateTime? openTime;
  final DateTime? closeTime;

  const Court({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.courtNumber,
    this.imageUrl,
    required this.pricePerHour,
    this.isActive = true,
    this.openTime,
    this.closeTime,
  });

  Court copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? courtNumber,
    String? imageUrl,
    int? pricePerHour,
    bool? isActive,
    DateTime? openTime,
    DateTime? closeTime,
  }) {
    return Court(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      courtNumber: courtNumber ?? this.courtNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isActive: isActive ?? this.isActive,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        courtNumber,
        imageUrl,
        pricePerHour,
        isActive,
        openTime,
        closeTime,
      ];
}