import 'dart:convert';
import 'dart:ui' as ui;
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

  /// Resets the entire screen to its initial state.
  void _resetScreen() {
    if (_speech.isListening) {
      _speech.stop();
    }
    setState(() {
      _textController.text = 'Press the button and start speaking';
      _contextController.clear();
      _summary = '';
      _isListening = false;
      _isSummarizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transcribed Text",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Screen',
                    onPressed: _resetScreen,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                readOnly: true,
                maxLines: null,
                style: const TextStyle(fontSize: 22.0),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Context (Optional)",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contextController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16.0),
                decoration: InputDecoration(
                  hintText: 'e.g., "Summarize this for a sales meeting about project X"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text(
                "AI Summary",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSummaryWidget(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: AvatarGlow(
                  animate: _isListening,
                  glowColor: Theme.of(context).primaryColor,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: FloatingActionButton(
                    onPressed: _listen,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _isListening
                              ? [Colors.red.withOpacity(0.7), Colors.red.withOpacity(0.4)]
                              : [
                                  Theme.of(context).primaryColor.withOpacity(0.7),
                                  Theme.of(context).primaryColor.withOpacity(0.4)
                                ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryWidget() {
    final theme = Theme.of(context);
    if (_isSummarizing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_summary.isEmpty) {
      return Text(
        'Summary will appear here after you stop speaking.',
        style: TextStyle(color: theme.hintColor, fontSize: 16),
      );
    }
    bool isError = _summary.startsWith("Error:");
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isError
            ? BorderSide(color: theme.colorScheme.error.withOpacity(0.5))
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          _summary,
          style: TextStyle(
            fontSize: 16,
            color: isError ? theme.colorScheme.error : null,
          ),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        _textController.clear(); // Always clear for a new session
        setState(() {
          _isListening = true;
          _summary = '';
        });
        _speech.listen(
          listenFor: const Duration(minutes: 30),
          pauseFor: const Duration(minutes: 5),
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

  Future<void> _summarizeText(
      {required String textToSummarize, String? context}) async {
    setState(() {
      _isSummarizing = true;
    });

    const String apiUrl =
        "https://api-inference.huggingface.co/models/facebook/bart-large-cnn";
    final String? apiKey = dotenv.env['HUGGING_FACE_API_TOKEN'];

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _summary =
            "Error: Hugging Face API token is missing. Please check your .env file.";
        _isSummarizing = false;
      });
      return;
    }

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
          "parameters": {
            "min_length": 30,
            "max_length": 150,
          }
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        if (responseData.isNotEmpty &&
            responseData[0].containsKey('summary_text')) {
          setState(() {
            _summary = responseData[0]['summary_text'];
          });
        } else {
          setState(
              () => _summary = "Error: Received an invalid response from the API.");
        }
      } else {
        setState(() {
          _summary =
              "Error: Failed to get summary (Status code: ${response.statusCode})\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _summary =
            "Error: Could not connect to the Hugging Face API. Check your internet connection.\n$e";
      });
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }
}
