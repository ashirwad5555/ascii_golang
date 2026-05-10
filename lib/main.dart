import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ASCII Converter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F172A),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Color(0xFF0F172A),
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF475569),
          ),
        ),
      ),
      home: const MyHomePage(title: 'ASCII Converter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class AsciiResult {
  AsciiResult({required this.character, required this.asciiValue});

  final String character;
  final int asciiValue;

  factory AsciiResult.fromJson(Map<String, dynamic> json) {
    return AsciiResult(
      character: json['character'] as String,
      asciiValue: json['ascii_value'] as int,
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _characterController = TextEditingController();
  String? _resultText;
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }

  String get _backendBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.48.159.134:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080';
    }
  }

  Future<void> _convertCharacter() async {
    final character = _characterController.text.trim();

    if (character.isEmpty) {
      setState(() {
        _errorText = 'Enter one character first.';
        _resultText = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _resultText = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/convert'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'character': character}),
      );

      final payload = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        setState(() {
          _errorText =
              payload['error']?.toString() ?? 'Unexpected backend error.';
        });
        return;
      }

      final result = AsciiResult.fromJson(payload);

      setState(() {
        _resultText = '${result.character} -> ${result.asciiValue}';
      });
    } catch (error) {
      setState(() {
        _errorText = 'Could not reach backend: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearAll() {
    setState(() {
      _characterController.clear();
      _resultText = null;
      _errorText = null;
    });
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -4,
            top: -12,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ASCII Converter',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'A clean Flutter + Go demo for sending one character to a backend and showing the ASCII value instantly.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildHeroChip('Frontend', 'Flutter'),
                  _buildHeroChip('Backend', 'Go'),
                  _buildHeroChip('API', 'JSON / HTTP'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label  •  $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final message = _resultText ?? _errorText;
    final isError = _errorText != null;

    if (message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isError
              ? [Colors.red.shade50, Colors.red.shade100]
              : [const Color(0xFFF0FDFA), const Color(0xFFD9F99D)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError ? Colors.red.shade200 : const Color(0xFF99F6E4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red.shade700 : const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isError ? Colors.red.shade900 : const Color(0xFF134E4A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE6FFFB), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // _buildHero(),
                    // const SizedBox(height: 18),
                    Card(
                      elevation: 14,
                      shadowColor: Colors.black12,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Convert a single character',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Send one character to the Go backend and get its ASCII value back in the app.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _characterController,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Character',
                                hintText: 'A',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F766E),
                                    width: 1.5,
                                  ),
                                ),
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _convertCharacter,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    _isLoading ? 'Converting...' : 'Convert',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _isLoading ? null : _clearAll,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildResultCard(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _buildKeyValue('Backend URL', _backendBaseUrl),
                    //     ),
                    //     const SizedBox(width: 12),
                    //     Expanded(
                    //       child: _buildKeyValue(
                    //         'Input',
                    //         'Single ASCII character',
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
