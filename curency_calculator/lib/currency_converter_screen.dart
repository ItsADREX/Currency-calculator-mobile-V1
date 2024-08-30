import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'currency_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  String _amount = '0';
  String? _fromCurrency;
  String? _toCurrency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyService>().fetchExchangeRates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDisplay(),
            const SizedBox(height: 20),
            _buildCurrencyDropdowns(),
            const SizedBox(height: 20),
            _buildKeypad(),
            const SizedBox(height: 20),
            _buildConvertButton(),
            const SizedBox(height: 20),
            _buildLastUpdated(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Consumer<CurrencyService>(
        builder: (context, currencyService, _) {
          return Text(
            currencyService.result.isEmpty ? _amount : currencyService.result,
            style: const TextStyle(fontSize: 36, color: Colors.orange),
            textAlign: TextAlign.right,
          );
        },
      ),
    );
  }

  Widget _buildCurrencyDropdowns() {
    return Consumer<CurrencyService>(
      builder: (context, currencyService, _) {
        if (currencyService.isLoading) {
          return const CircularProgressIndicator();
        }

        _fromCurrency ??= currencyService.defaultFromCurrency;
        _toCurrency ??= currencyService.currencies.firstWhere((c) => c != _fromCurrency, orElse: () => 'EUR');

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDropdown(
              value: _fromCurrency!,
              items: currencyService.currencies,
              onChanged: (String? newValue) {
                setState(() {
                  _fromCurrency = newValue;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.orange),
              onPressed: () {
                setState(() {
                  final temp = _fromCurrency;
                  _fromCurrency = _toCurrency;
                  _toCurrency = temp;
                });
              },
            ),
            _buildDropdown(
              value: _toCurrency!,
              items: currencyService.currencies,
              onChanged: (String? newValue) {
                setState(() {
                  _toCurrency = newValue;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.orange),
        underline: Container(),
      ),
    );
  }

  Widget _buildKeypad() {
    return Expanded(
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildKeypadButton('7'),
          _buildKeypadButton('8'),
          _buildKeypadButton('9'),
          _buildKeypadButton('4'),
          _buildKeypadButton('5'),
          _buildKeypadButton('6'),
          _buildKeypadButton('1'),
          _buildKeypadButton('2'),
          _buildKeypadButton('3'),
          _buildKeypadButton('C'),
          _buildKeypadButton('0'),
          _buildKeypadButton('.'),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label) {
    return ElevatedButton(
      onPressed: () => _onKeypadPressed(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.withOpacity(0.2),
        foregroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 24)),
    );
  }

  void _onKeypadPressed(String key) {
    setState(() {
      if (key == 'C') {
        _amount = '0';
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount += key;
        }
      } else {
        _amount = (_amount == '0') ? key : _amount + key;
      }
    });
  }

  Widget _buildConvertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _convert,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Convert',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  void _convert() {
    if (_fromCurrency == null || _toCurrency == null) return;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    currencyService.convert(
      amount: double.parse(_amount),
      fromCurrency: _fromCurrency!,
      toCurrency: _toCurrency!,
    );
  }

  Widget _buildLastUpdated() {
    return Consumer<CurrencyService>(
      builder: (context, currencyService, _) {
        return Text(
          'Last updated: ${currencyService.lastUpdated}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        );
      },
    );
  }
}