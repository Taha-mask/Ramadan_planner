import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Position? _currentPosition;
  String _currentAddress = "حدد موقعك"; // Default

  Position? get currentPosition => _currentPosition;
  String get currentAddress => _currentAddress;

  /// Determine the current position of the device.
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied.');
      return null;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_currentPosition != null) {
        await _getAddressFromLatLng(_currentPosition!);
      }

      return _currentPosition;
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String city = place.locality ?? place.subAdministrativeArea ?? "";
        String area = place.subLocality ?? place.thoroughfare ?? "";

        if (city.isNotEmpty && area.isNotEmpty) {
          _currentAddress = "$area, $city";
        } else if (city.isNotEmpty) {
          _currentAddress = city;
        } else if (place.country != null) {
          _currentAddress = place.country!;
        }

        await saveAddress(_currentAddress);
        await _saveCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
  }

  // --- Persistence Methods for HomeScreen ---

  Future<void> saveAddress(String address) async {
    _currentAddress = address;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location_address', address);
    } catch (e) {
      debugPrint("Error saving address: $e");
    }
  }

  Future<void> _saveCoordinates(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_lat', lat);
      await prefs.setDouble('user_lng', lng);
    } catch (e) {
      debugPrint("Error saving coordinates: $e");
    }
  }

  Future<double?> getSavedLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_lat');
  }

  Future<double?> getSavedLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_lng');
  }

  Future<String?> getSavedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_location_address');
      if (saved != null) {
        _currentAddress = saved;
      }
      return _currentAddress;
    } catch (e) {
      return _currentAddress;
    }
  }

  Future<String?> getCurrentAddress() async {
    await determinePosition();
    return _currentAddress;
  }
}
