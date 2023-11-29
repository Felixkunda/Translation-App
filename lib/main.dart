import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZamTranslate',
      theme: ThemeData.dark(),
      home: TranslatorScreen(),
    );
  }
}

class TranslatorScreen extends StatefulWidget {
  @override
  _TranslatorScreenState createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  TextEditingController _inputController = TextEditingController();
  String _translatedText = '';
  String _sourceLanguage = "en"; // Default source language
  String _targetLanguage = "bem"; // Default target language
  ThemeMode _currentThemeMode = ThemeMode.dark;
  bool _isTranslating = false;

  void _toggleTheme() {
    setState(() {
      _currentThemeMode = _currentThemeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _translate(String inputText) async {
    setState(() {
      _isTranslating = true;
      _translatedText = 'Translation Model loading...';
    });

    final Map<String, String> headers = {
      "Authorization": "Bearer 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",
      "Content-Type": "application/json",
    };

    final Map<String, dynamic> requestBody = {
      'inputs': inputText,
    };

    final String apiURL =
        "https://api-inference.huggingface.co/models/Helsinki-NLP/opus-mt-$_sourceLanguage-$_targetLanguage";

    try {
      final response = await http.post(
        Uri.parse(apiURL),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);

        if (responseData.isNotEmpty &&
            responseData[0] is Map<String, dynamic> &&
            responseData[0].containsKey('translation_text')) {
          final String translationText = responseData[0]['translation_text'];
          setState(() {
            _translatedText = translationText;
          });
        } else {
          print('Unexpected response format');
          showErrorDialog('Unexpected response format');
        }
      } else {
        print('Error: ${response.statusCode}');
        print('Response: ${response.body}');
        showErrorDialog('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      showErrorDialog('Exception: $e');
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> _translateWithRetries(String inputText) async {
    try {
      await _translate(inputText);
    } catch (e) {
      print('Error: $e');
      await Future.delayed(
          Duration(seconds: 2)); // Wait for a short duration before retrying
      await _translateWithRetries(
          inputText); // Recursively retry the translation
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZamTranslate',
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _currentThemeMode,
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'LINGO LINK',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.lightbulb_outline),
              onPressed: _toggleTheme,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Source Language',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _sourceLanguage,
                    onChanged: (value) {
                      setState(() {
                        _sourceLanguage = value!;
                      });
                    },
                    items: [
                      "en - English",
                      "bem - Bemba",
                      "ny - Nyanja",
                    ].map((lang) {
                      final parts = lang.split(' - ');
                      return DropdownMenuItem<String>(
                          value: parts[0],
                          child: Text(
                            parts[1],
                          ));
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Target Language',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _targetLanguage,
                    onChanged: (value) {
                      setState(() {
                        _targetLanguage = value!;
                      });
                    },
                    items: [
                      "bem - Bemba",
                      "en - English",
                      "ny - Nyanja",
                    ].map((lang) {
                      final parts = lang.split(' - ');
                      return DropdownMenuItem<String>(
                        value: parts[0],
                        child: Text(parts[1]),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _inputController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Enter text to translate',
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.all(16.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _isTranslating
                            ? null
                            : () {
                                String inputText = _inputController.text;
                                if (inputText.isNotEmpty) {
                                  _translateWithRetries(inputText);
                                }
                              },
                        child: Text('Translate Language'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Visibility(
                    visible: _isTranslating,
                    child: CircularProgressIndicator(),
                  ),
                  Visibility(
                    visible: !_isTranslating && _translatedText.isNotEmpty,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          ' $_translatedText',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
