// lib/screens/analyzer_screen.dart
// Feature C: AI Medical Report Analyzer – powered by Google Gemini Vision API.
// Supports: X-rays, blood reports, MRI scans, prescriptions (image or PDF).

import 'dart:io';
// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ⚠️  PASTE YOUR GEMINI API KEY BELOW
//     Get it free at: https://aistudio.google.com → Get API Key
//     For production: move this to a Firebase Cloud Function
// ─────────────────────────────────────────────────────────────────────────────
const String _geminiApiKey = 'AIzaSyDFRLOua3kIgdsh_KmPFaMmAb8w_UBaunI';

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen>
    with SingleTickerProviderStateMixin {

  // ── State ──────────────────────────────────────────────────────────────────
  File?   _selectedFile;
  String? _fileName;
  bool    _isImage      = false;
  bool    _isAnalyzing  = false;
  bool    _showResults  = false;
  String? _errorMsg;

  // Parsed result sections
  String _summary       = '';
  String _findings      = '';
  String _whatItMeans   = '';
  String _nextSteps     = '';
  String _rawResponse   = '';

  // Animation for upload zone pulse
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Pick image from camera or gallery ─────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source:      source,
        imageQuality: 85,
        maxWidth:    1920,
      );
      if (picked == null) return;
      setState(() {
        _selectedFile = File(picked.path);
        _fileName     = picked.name;
        _isImage      = true;
        _showResults  = false;
        _errorMsg     = null;
        _rawResponse  = '';
      });
    } catch (e) {
      setState(() => _errorMsg = 'Could not open camera/gallery. Please try again.');
    }
  }

  // ── Pick PDF or image file from file system ────────────────────────────────
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type:           FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
        withData:       false,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      if (f.path == null) return;

      final ext = f.extension?.toLowerCase() ?? '';
      setState(() {
        _selectedFile = File(f.path!);
        _fileName     = f.name;
        _isImage      = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
        _showResults  = false;
        _errorMsg     = null;
        _rawResponse  = '';
      });
    } catch (e) {
      setState(() => _errorMsg = 'Could not open file picker. Please try again.');
    }
  }

  // ── Analyze with Gemini ────────────────────────────────────────────────────
  Future<void> _analyze() async {
    if (_selectedFile == null) return;
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      setState(() => _errorMsg =
          '⚠️ Please add your Gemini API key in analyzer_screen.dart');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
      _errorMsg    = null;
    });

    try {
      final model = GenerativeModel(
        model:  'gemini-2.5-flash',
        apiKey: _geminiApiKey,
      );

      final bytes    = await _selectedFile!.readAsBytes();
      final ext      = _fileName?.split('.').last.toLowerCase() ?? 'jpg';
      final mimeType = _mimeType(ext);

      // Build the prompt
      const prompt = '''
You are an expert medical AI assistant. Analyze this medical document (which may be an X-ray, MRI, CT scan, blood test report, prescription, or other medical report).

Provide a structured analysis with EXACTLY these four sections, using these exact headers:

## SUMMARY
A brief 2-3 sentence overall summary of what the document shows. Mention the type of report and the overall impression.

## KEY FINDINGS
List each notable finding as a bullet point (use • symbol). For each finding include the parameter name, value (if present), and whether it is Normal, Low, High, or Abnormal. If it is an imaging report, describe what is visible.

## WHAT THIS MAY INDICATE
Explain in simple language what these findings could mean for the patient's health. Use bullet points. Avoid overly technical jargon.

## SUGGESTED NEXT STEPS
List 3-5 concrete, actionable next steps the patient should take. Number them 1, 2, 3, etc.

Important rules:
- Always end with a reminder that this is AI analysis only and not a substitute for professional medical advice
- Be accurate but compassionate
- If the image is not a medical document, say so clearly in the SUMMARY section
- Do not make definitive diagnoses, only observations and possibilities
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, bytes),
        ]),
      ]);

      final text = response.text ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      _parseResponse(text);

      setState(() {
        _isAnalyzing = false;
        _showResults  = true;
        _rawResponse  = text;
      });

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMsg    = _friendlyError(e.toString());
      });
    }
  }

  // ── Parse Gemini response into sections ───────────────────────────────────
  void _parseResponse(String text) {
    _summary     = _extractSection(text, 'SUMMARY',           'KEY FINDINGS');
    _findings    = _extractSection(text, 'KEY FINDINGS',      'WHAT THIS MAY INDICATE');
    _whatItMeans = _extractSection(text, 'WHAT THIS MAY INDICATE', 'SUGGESTED NEXT STEPS');
    _nextSteps   = _extractSection(text, 'SUGGESTED NEXT STEPS', null);
  }

  String _extractSection(String text, String start, String? end) {
    final startMarker = '## $start';
    final startIdx    = text.indexOf(startMarker);
    if (startIdx == -1) return '';

    final contentStart = startIdx + startMarker.length;
    int contentEnd;

    if (end != null) {
      final endIdx = text.indexOf('## $end', contentStart);
      contentEnd   = endIdx == -1 ? text.length : endIdx;
    } else {
      contentEnd = text.length;
    }

    return text.substring(contentStart, contentEnd).trim();
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      default:     return 'image/jpeg';
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('API_KEY') || raw.contains('api key') || raw.contains('apiKey')) {
      return 'Invalid API key. Please check your Gemini API key in analyzer_screen.dart';
    }
    if (raw.contains('quota') || raw.contains('RESOURCE_EXHAUSTED')) {
      return 'API quota exceeded. Please wait a moment and try again.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('SAFETY')) {
      return 'The content was blocked by safety filters. Please try a clearer image.';
    }
    return 'Analysis failed. Please try again with a clearer image.';
  }

  void _reset() {
    setState(() {
      _selectedFile = null;
      _fileName     = null;
      _isImage      = false;
      _showResults  = false;
      _isAnalyzing  = false;
      _errorMsg     = null;
      _rawResponse  = '';
      _summary = _findings = _whatItMeans = _nextSteps = '';
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Report Analyzer'),
        actions: [
          if (_selectedFile != null)
            IconButton(
              icon:    const Icon(Icons.refresh),
              tooltip: 'Start over',
              onPressed: _reset,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Disclaimer
          const _DisclaimerBanner(),
          const SizedBox(height: 20),

          Text('Upload Medical Document', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Supports X-rays, blood reports, MRI, CT scans, prescriptions',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),

          // ── Upload zone or file preview ──
          if (_selectedFile == null)
            _UploadZone(
              pulseAnimation: _pulseAnimation,
              onPickGallery: () => _pickImage(ImageSource.gallery),
              onPickCamera:  () => _pickImage(ImageSource.camera),
              onPickFile:    _pickFile,
            )
          else ...[
            // File preview
            _FilePreview(
              file:    _selectedFile!,
              name:    _fileName ?? 'document',
              isImage: _isImage,
              onRemove: _reset,
            ),
            const SizedBox(height: 16),

            // Error
            if (_errorMsg != null) ...[
              _ErrorBanner(message: _errorMsg!),
              const SizedBox(height: 12),
            ],

            // Analyze button
            SizedBox(
              height: 52,
              width:  double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 20),
                label: Text(_isAnalyzing
                    ? 'Analyzing your report…'
                    : 'Analyze with AI'),
              ),
            ),
          ],

          // ── Results ──
          if (_showResults) ...[
            const SizedBox(height: 28),
            _ResultsSection(
              summary:     _summary,
              findings:    _findings,
              whatItMeans: _whatItMeans,
              nextSteps:   _nextSteps,
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Upload Zone ───────────────────────────────────────────────────────────────
class _UploadZone extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickFile;

  const _UploadZone({
    required this.pulseAnimation,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Main tap zone
      ScaleTransition(
        scale: pulseAnimation,
        child: GestureDetector(
          onTap: onPickGallery,
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color:        AppTheme.accentMint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:       AppTheme.primaryTeal.withValues(alpha: 0.5),
                width:       2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_upload_outlined,
                    size: 40, color: AppTheme.primaryTeal),
              ),
              const SizedBox(height: 16),
              Text('Tap to upload from Gallery',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppTheme.primaryDark)),
              const SizedBox(height: 4),
              Text('JPG, PNG, PDF supported (max 20 MB)',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 12)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Or divider
      const Row(children: [
        Expanded(child: Divider()),
        SizedBox(width: 12),
        Text('or', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
        SizedBox(width: 12),
        Expanded(child: Divider()),
      ]),
      const SizedBox(height: 14),

      // Camera + File picker buttons
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickCamera,
            icon:  const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPickFile,
            icon:  const Icon(Icons.attach_file),
            label: const Text('Browse Files'),
          ),
        ),
      ]),
    ]);
  }
}

// ── File Preview ──────────────────────────────────────────────────────────────
class _FilePreview extends StatelessWidget {
  final File         file;
  final String       name;
  final bool         isImage;
  final VoidCallback onRemove;

  const _FilePreview({
    required this.file,
    required this.name,
    required this.isImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(
            color: AppTheme.primaryTeal.withValues(alpha: 0.08), blurRadius: 10)],
      ),
      child: Column(children: [
        // Image thumbnail if it's an image
        if (isImage)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.file(
              file,
              width:  double.infinity,
              height: 200,
              fit:    BoxFit.cover,
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color:        AppTheme.accentMint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                color: AppTheme.primaryTeal, size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                const Text('Ready for AI analysis',
                    style: TextStyle(color: AppTheme.success,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            )),
            IconButton(
              icon:      const Icon(Icons.close, color: AppTheme.textLight),
              onPressed: onRemove,
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Results Section ───────────────────────────────────────────────────────────
class _ResultsSection extends StatelessWidget {
  final String summary, findings, whatItMeans, nextSteps;

  const _ResultsSection({
    required this.summary,
    required this.findings,
    required this.whatItMeans,
    required this.nextSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        const Icon(Icons.auto_awesome, color: AppTheme.primaryTeal, size: 22),
        const SizedBox(width: 8),
        Text('AI Analysis Results', style: theme.textTheme.titleLarge),
      ]),
      const SizedBox(height: 4),
      Text(
        'Analyzed at ${TimeOfDay.now().format(context)} today  •  Powered by Gemini AI',
        style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 11, color: AppTheme.textLight),
      ),
      const SizedBox(height: 16),

      // Summary card
      if (summary.isNotEmpty)
        _ResultCard(
          color:       AppTheme.accentMint,
          borderColor: AppTheme.primaryTeal,
          icon:        Icons.summarize_outlined,
          iconColor:   AppTheme.primaryTeal,
          title:       'Overall Summary',
          content:     summary,
        ),
      if (summary.isNotEmpty) const SizedBox(height: 12),

      // Findings card
      if (findings.isNotEmpty)
        _ResultCard(
          color:       const Color(0xFFF3E5F5),
          borderColor: const Color(0xFF7B61FF),
          icon:        Icons.biotech_outlined,
          iconColor:   const Color(0xFF7B61FF),
          title:       'Key Findings',
          content:     findings,
        ),
      if (findings.isNotEmpty) const SizedBox(height: 12),

      // What it means card
      if (whatItMeans.isNotEmpty)
        _ResultCard(
          color:       const Color(0xFFFFF8E1),
          borderColor: AppTheme.warning,
          icon:        Icons.lightbulb_outline,
          iconColor:   AppTheme.warning,
          title:       'What This May Indicate',
          content:     whatItMeans,
        ),
      if (whatItMeans.isNotEmpty) const SizedBox(height: 12),

      // Next steps card
      if (nextSteps.isNotEmpty)
        _ResultCard(
          color:       const Color(0xFFE8F5E9),
          borderColor: AppTheme.success,
          icon:        Icons.recommend_outlined,
          iconColor:   AppTheme.success,
          title:       'Suggested Next Steps',
          content:     nextSteps,
        ),
      if (nextSteps.isNotEmpty) const SizedBox(height: 20),

      // Final disclaimer
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        const Color(0xFFFCE4EC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'This AI analysis is for informational purposes only and does NOT '
            'replace a doctor\'s diagnosis. Always consult a licensed medical '
            'professional before making any health decisions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color:      const Color(0xFFB71C1C),
              fontSize:   12,
              fontWeight: FontWeight.w600,
            ),
          )),
        ]),
      ),
    ]);
  }
}

class _ResultCard extends StatelessWidget {
  final Color    color, borderColor, iconColor;
  final IconData icon;
  final String   title, content;

  const _ResultCard({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 15)),
        ]),
        const SizedBox(height: 10),
        Text(content.trim(),
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.6)),
      ]),
    );
  }
}

// ── Disclaimer Banner ─────────────────────────────────────────────────────────
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.6)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.warning_amber_rounded,
            color: AppTheme.warning, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'AI analysis is for informational purposes only and does not replace '
          'a doctor\'s diagnosis. Always consult a qualified medical professional.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color:      const Color(0xFF795548),
            fontSize:   12,
            fontWeight: FontWeight.w600,
          ),
        )),
      ]),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: const TextStyle(color: AppTheme.error, fontSize: 13))),
      ]),
    );
  }
}