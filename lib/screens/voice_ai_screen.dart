import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';

class VoiceAiScreen extends StatefulWidget {
  const VoiceAiScreen({super.key});

  @override
  _VoiceAiScreenState createState() => _VoiceAiScreenState();
}

class _VoiceAiScreenState extends State<VoiceAiScreen> {
  // State variables for Speech-to-Text
  final TextEditingController _textController =
  TextEditingController(text: 'Press the button and start speaking');
  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _confidence = 1.0;

  final TextEditingController _contextController = TextEditingController();

  // State variables for Summarization
  bool _isSummarizing = false;
  String _summary = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _textController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  // --- Main Build Method (No changes needed) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voice AI (Confidence: ${(_confidence * 100).toStringAsFixed(1)}%)',
        ),
        backgroundColor: const Color(0xFF182D53),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centered FAB
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          onPressed: _listen,
          backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 150.0), // Padding for FAB
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section for Transcribed Text
            Text(
              "Transcribed Text",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              readOnly: true,
              maxLines: null,
              style: const TextStyle(fontSize: 22.0, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xFFF0F0F0),
              ),
            ),
            const SizedBox(height: 24),

            // Section for Context
            Text(
              "Context (Optional)",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contextController,
              maxLines: 3, // Allow for a few lines of text
              style: const TextStyle(fontSize: 16.0, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'e.g., "Summarize this for a sales meeting about project X"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Section for AI Summary
            Text(
              "AI Summary",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSummaryWidget(),
          ],
        ),
      ),
    );
  }

  /// Builds the widget to display the summary or a loading/error state.
  Widget _buildSummaryWidget() {
    if (_isSummarizing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_summary.isEmpty) {
      return const Text(
        'Summary will appear here after you stop speaking.',
        style: TextStyle(color: Colors.grey, fontSize: 16),
      );
    }

    // Display the summary or an error message
    bool isError = _summary.startsWith("Error:");
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: isError ? Border.all(color: Colors.redAccent) : null,
      ),
      child: Text(
        _summary,
        style: TextStyle(
          fontSize: 16,
          color: isError ? Colors.redAccent : Colors.black,
        ),
      ),
    );
  }

  // --- THIS IS THE MODIFIED FUNCTION ---

  /// Handles starting and stopping the speech recognition.
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );

      if (available) {
        if (_textController.text == 'Press the button and start speaking') {
          _textController.clear();
        }
        setState(() {
          _isListening = true;
          _summary = ''; // Clear previous summary when starting
        });

        _speech.listen(
          // *** ADDED PARAMETERS TO PREVENT TIMEOUTS ***
          listenFor: const Duration(minutes: 30), // Max listen duration
          pauseFor: const Duration(minutes: 5),   // Time to wait after speech stops
          onResult: (val) {
            if (mounted) {
              setState(() {
                _textController.text = val.recognizedWords;
                if (val.hasConfidenceRating && val.confidence > 0) {
                  _confidence = val.confidence;
                }
              });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
      if (_textController.text.isNotEmpty) {
        _summarizeText(
          textToSummarize: _textController.text,
          context: _contextController.text,
        );
      }
    }
  }

  /// Sends the transcribed text to the Hugging Face API for summarization.
  Future<void> _summarizeText(
      {required String textToSummarize, String? context}) async {
    setState(() {
      _isSummarizing = true;
    });

    // A popular and reliable summarization model on Hugging Face
    const String apiUrl =
        "https://api-inference.huggingface.co/models/facebook/bart-large-cnn";

    // Retrieve the API key from your .env file
    final String? apiKey = dotenv.env['HUGGING_FACE_API_TOKEN'];

    // Pre-flight check for the API key
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _summary =
        "Error: Hugging Face API token is missing. Please check your .env file.";
        _isSummarizing = false;
      });
      return;
    }

    // Combine transcribed text and context for the AI prompt
    String inputText = textToSummarize;
    if (context != null && context.isNotEmpty) {
      inputText =
      "Context: $context. \n\nSummarize the following text: $textToSummarize";
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "inputs": inputText,
          // You can control the summary length with these parameters
          "parameters": {
            "min_length": 30,
            "max_length": 150,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Successful response
        final List<dynamic> responseData = json.decode(response.body);
        if (responseData.isNotEmpty &&
            responseData[0].containsKey('summary_text')) {
          setState(() {
            _summary = responseData[0]['summary_text'];
          });
        } else {
          // The API returned a 200 OK but the body was not what we expected
          setState(
                  () => _summary = "Error: Received an invalid response from the API.");
        }
      } else {
        // Handle API errors (e.g., model is loading, authentication failed)
        setState(() {
          _summary =
          "Error: Failed to get summary (Status code: ${response.statusCode})\n${response.body}";
        });
      }
    } catch (e) {
      // Handle network errors (no internet, DNS issues)
      setState(() {
        _summary =
        "Error: Could not connect to the Hugging Face API. Check your internet connection.\n$e";
      });
    } finally {
      // Ensure the loading spinner always stops
      setState(() {
        _isSummarizing = false;
      });
    }
  }
}
