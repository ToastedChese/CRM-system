import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:powerlink_crm/data/supabase_service.dart';

// Constants for placeholder messages to avoid magic strings
const String kSummaryNotGenerated = "Summary has not been generated yet.";
const String kSummaryFailed =
    "Sorry for the long wait the AI summarizing service maybe down try regenorating the summerie at a later time";

class SavedSummariesScreen extends StatefulWidget {
  const SavedSummariesScreen({Key? key}) : super(key: key);

  @override
  _SavedSummariesScreenState createState() => _SavedSummariesScreenState();
}

class _SavedSummariesScreenState extends State<SavedSummariesScreen>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _summariesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSummaries();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadSummaries();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadSummaries() {
    if (mounted) {
      setState(() {
        _summariesFuture = SupabaseService.getMyAiSummaries();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummaries,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _summariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No saved recordings found.'));
          }

          final summaries = snapshot.data!;
          return ListView.builder(
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final createdAt = DateTime.parse(summary['created_at']);
              final formattedDate =
              DateFormat.yMMMd().add_jm().format(createdAt);

              final contextText = summary['context'] as String?;
              final titleText = (contextText != null && contextText.isNotEmpty)
                  ? contextText
                  : (summary['title'] ?? 'Untitled Recording');

              final transcriptText =
                  summary['transcript'] as String? ?? 'No transcript available.';

              final summaryText = summary['ai_summary']?.toString() ?? '';
              final bool needsGenerating = summaryText == kSummaryNotGenerated;
              final bool isFailed = summaryText == kSummaryFailed;

              IconData trailingIcon = Icons.arrow_forward_ios;
              Color? titleColor;

              if (needsGenerating) {
                trailingIcon = Icons.edit_document;
                titleColor = Theme.of(context).colorScheme.secondary;
              } else if (isFailed) {
                trailingIcon = Icons.warning_amber_rounded;
                titleColor = Colors.orange.shade800;
              }

              return ListTile(
                leading: const Icon(Icons.mic_none, size: 30),
                title: Text(
                  titleText,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${transcriptText.replaceAll('\n', ' ')}\n$formattedDate',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: Icon(trailingIcon),
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SummaryDetailScreen(summary: summary),
                    ),
                  );
                  if (result == true) {
                    _loadSummaries();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class SummaryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> summary;

  const SummaryDetailScreen({Key? key, required this.summary})
      : super(key: key);

  @override
  State<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends State<SummaryDetailScreen> {
  late Map<String, dynamic> _currentSummary;
  bool _isGenerating = false;
  String? _generationError;

  @override
  void initState() {
    super.initState();
    _currentSummary = Map<String, dynamic>.from(widget.summary);
  }

  Future<void> _generateOrRegenerateSummary() async {
    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    final transcript = _currentSummary['transcript'] as String?;
    final summaryContext = _currentSummary['context'] as String?;
    final summaryId = _currentSummary['id'];

    if (transcript == null || transcript.isEmpty) {
      if (!mounted) return;
      setState(() {
        _generationError =
        "Cannot generate: The original transcript is missing.";
        _isGenerating = false;
      });
      return;
    }

    try {
      final newSummary =
      await _fetchNewSummaryFromAPI(transcript, summaryContext);

      await SupabaseService.updateAiSummary(
        summaryId: summaryId,
        newSummary: newSummary,
      );

      if (!mounted) return;
      setState(() {
        _currentSummary['ai_summary'] = newSummary;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generationError = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<String> _fetchNewSummaryFromAPI(
      String text, String? summaryContext) async {
    // Corrected API URL for the cloud service
    const String apiUrl = "https://ollama.com/api/chat";
    final apiKey = dotenv.env['OLLAMA_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Ollama API key is missing from .env file.");
    }

    String userPrompt = text;
    if (summaryContext != null && summaryContext.isNotEmpty) {
      userPrompt = '''Context: $summaryContext.

Please summarize the following text:
$text''';
    }

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {
          // Add the Authorization header required for the cloud API
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "model": "gpt-oss:20b-cloud",
          "messages": [
            {
              "role": "system",
              "content":
              "You are an expert assistant who provides concise and accurate summaries of the given text."
            },
            {"role": "user", "content": userPrompt}
          ],
          "stream": false
        }),
      )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] != null &&
            responseBody['message']['content'] != null) {
          return responseBody['message']['content'].toString().trim();
        } else {
          throw Exception("Invalid response from Ollama API.");
        }
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['error'] ?? response.body;
        throw Exception(
            "Failed (Status code: ${response.statusCode}) Details: $errorMessage");
      }
    } catch (e) {
      throw Exception("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentSummary['title'] ??
        _currentSummary['Title'] ?? // <-- FIX
        'Recording Details';

    final summaryText = _currentSummary['ai_summary']?.toString() ?? '';
    final bool needsGenerating = summaryText == kSummaryNotGenerated;
    final bool isFailed = summaryText == kSummaryFailed;
    final bool canGenerate = needsGenerating || isFailed;

    String buttonText =
    needsGenerating ? 'Generate Summary' : 'Regenerate Summary';

    return Scaffold(
      appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                Navigator.of(context).pop(_isGenerating ? null : true),
          )),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Summary', _currentSummary['ai_summary'] ?? ''),
            if (canGenerate || _isGenerating)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24.0),
                child: _isGenerating
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.psychology_alt),
                    label: Text(buttonText),
                    onPressed: _generateOrRegenerateSummary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Theme.of(context).colorScheme.primary,
                      foregroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            if (_generationError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Center(
                  child: Text(
                    _generationError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // --- MODIFICATION START ---
            // The order of these two blocks has been swapped so Context is on top.
            if (_currentSummary['context'] != null &&
                _currentSummary['context'].isNotEmpty)
              _buildSection('Context', _currentSummary['context'] ?? ''),
            if (_currentSummary['transcript'] != null &&
                _currentSummary['transcript'].isNotEmpty)
              _buildSection('Transcript', _currentSummary['transcript'] ?? ''),
            // --- MODIFICATION END ---
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
          SelectableText(content, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
