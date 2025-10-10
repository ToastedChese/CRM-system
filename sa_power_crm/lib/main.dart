import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load the Hugging Face API key from the .env file
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech to Text + AI Summary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Speech Recognition + Summary'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isSummarizing = false;
  String _text = 'Tap the mic and start speaking...';
  String _summary = '';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('Status: $val'),
        onError: (val) => print('Error: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _summary = '';
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      } else {
        setState(() => _isListening = false);
        await _speech.stop();
      }
    } else {
      // Stop listening and summarize text
      setState(() => _isListening = false);
      await _speech.stop();
      if (_text.isNotEmpty && _text != 'Tap the mic and start speaking...') {
        await _summarizeText(_text);
      }
    }
  }

  Future<void> _summarizeText(String inputText) async {
    setState(() => _isSummarizing = true);

    try {
      final apiKey = dotenv.env['HF_API_KEY'];
      const endpoint =
          'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': inputText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _summary = data[0]['summary_text'] ?? 'No summary generated.';
        });
      } else {
        setState(() {
          _summary = 'Error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _summary = 'Failed to summarize: $e';
      });
    }

    setState(() => _isSummarizing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          '${widget.title} (Conf: ${(_confidence * 100).toStringAsFixed(1)}%)',
          style: const TextStyle(fontSize: 14),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recognized Speech:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _text,
                style: const TextStyle(fontSize: 18),
              ),
              const Divider(height: 30),
              const Text(
                "AI Summary:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              _isSummarizing
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                _summary.isEmpty ? '—' : _summary,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
