import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:powerlink_crm/data/supabase_service.dart';
import 'package:powerlink_crm/screens/saved_summaries_screen.dart';

class VoiceAIScreen extends StatefulWidget {
  const VoiceAIScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAIScreen> createState() => _VoiceAIScreenState();
}

class _VoiceAIScreenState extends State<VoiceAIScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();

  // Holds the transcript from before the current listening session started.
  String _currentTranscript = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    // Clean up controllers
    _transcriptController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _startListening() async {
    // Save the state of the transcript before starting a new listening session.
    _currentTranscript = _transcriptController.text;
    if (_currentTranscript.isNotEmpty && !_currentTranscript.endsWith(' ')) {
      _currentTranscript += ' ';
    }

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          // Append the newly recognized words to the transcript from when we started.
          _transcriptController.text = _currentTranscript + result.recognizedWords;
        }
      },
    );
    if (mounted) {
      setState(() {
        _isListening = true;
      });
    }
  }

  void _pauseListening() async {
    await _speechToText.stop();
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  void _toggleRecording() {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available or not enabled.')),
      );
      return;
    }
    _isListening ? _pauseListening() : _startListening();
  }

  void _clearAll() {
    if (_isListening) {
      _pauseListening();
    }
    _transcriptController.clear();
    _contextController.clear();
  }

  void _saveRecording() async {
    if (_isListening) {
      _pauseListening();
    }

    final transcript = _transcriptController.text;
    final contextText = _contextController.text;

    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty transcript.')),
      );
      return;
    }

    // Generate a title automatically based on the current date and time.
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final String saveName = 'Recording $date at $time';

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await SupabaseService.createAiSummary(
        title: saveName, // Pass the auto-generated title
        transcript: transcript,
        context: contextText,
        summary: "Summary has not been generated yet.",
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording saved!'), backgroundColor: Colors.green),
      );

      _clearAll();

    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Note'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Saved Recordings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SavedSummariesScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: 'Context (Optional)',
                hintText: 'e.g., meeting title, product names...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _transcriptController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: 'Transcript',
                  hintText: _isListening ? 'Listening...' : 'Press the mic to start recording.',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  onPressed: _toggleRecording,
                  tooltip: _isListening ? 'Pause' : 'Record',
                  child: Icon(_isListening ? Icons.pause : Icons.mic),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all),
                  label: const Text('New/Clear'),
                  onPressed: _clearAll,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: _saveRecording,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
