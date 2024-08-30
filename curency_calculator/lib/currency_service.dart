import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class CurrencyService extends ChangeNotifier {
  final String apiKey = '487eb7b04e274b821a47c3e4cbdb814a';
  final String baseUrl = 'http://api.exchangeratesapi.io/v1/latest';

  Map<String, double> _exchangeRates = {};
  List<String> _currencies = [];
  String _result = '';
  String _lastUpdated = '';
  String _defaultFromCurrency = 'USD';
  bool _isLoading = false;

  List<String> get currencies => _currencies;
  String get result => _result;
  String get lastUpdated => _lastUpdated;
  String get defaultFromCurrency => _defaultFromCurrency;
  bool get isLoading => _isLoading;

  Future<void> fetchExchangeRates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl?access_key=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _exchangeRates = (data['rates'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value is int) ? value.toDouble() : value as double),
        );
        _currencies = _exchangeRates.keys.toList();
        _lastUpdated = DateTime.now().toString();
        await _getUserLocation();
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return false;
    }
    return true;
  }

  Future<void> _getUserLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        await _getUserCurrencyByIP();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final currency = await _getCurrencyFromCoords(position.latitude, position.longitude);
      if (currency.isNotEmpty && _exchangeRates.containsKey(currency)) {
        _defaultFromCurrency = currency;
      }
    } catch (e) {
      print('Error getting user location: $e');
      await _getUserCurrencyByIP();
    }
  }

  Future<String> _getCurrencyFromCoords(double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _countryToCurrency(data['countryName']);
      }
    } catch (e) {
      print('Error getting currency from coordinates: $e');
    }
    return '';
  }

  Future<void> _getUserCurrencyByIP() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String currency = data['currency'];
        if (currency.isNotEmpty && _exchangeRates.containsKey(currency)) {
          _defaultFromCurrency = currency;
        }
      }
    } catch (e) {
      print('Error getting user location by IP: $e');
    }
  }

  String _countryToCurrency(String country) {
    const Map<String, String> countryCurrencyMap = {
      'United States': 'USD',
      'Canada': 'CAD',
      'United Kingdom': 'GBP',
      'European Union': 'EUR',
      // Add more mappings as needed
    };
    return countryCurrencyMap[country] ?? 'USD';
  }

  void convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    if (_exchangeRates.isEmpty) {
      _result = 'Error: Exchange rates not available';
      notifyListeners();
      return;
    }

    final fromRate = _exchangeRates[fromCurrency];
    final toRate = _exchangeRates[toCurrency];

    if (fromRate == null || toRate == null) {
      _result = 'Error: Invalid currency';
      notifyListeners();
      return;
    }

    final convertedAmount = (amount / fromRate) * toRate;
    _result = '${convertedAmount.toStringAsFixed(2)} $toCurrency';
    notifyListeners();
  }
}