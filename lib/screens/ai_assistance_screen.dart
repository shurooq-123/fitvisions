import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../services/ai_generation_service.dart';
import '../services/body_size_presets.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/measurement_guide.dart';

class AiAssistanceScreen extends StatefulWidget {
  const AiAssistanceScreen(
      {super.key,
      this.recommendations = false,
      this.request,
      this.initialMeasurements = const {},
      this.clothingContext = '',
      this.referenceImage});
  final bool recommendations;
  final Uint8List? referenceImage;
  final Map<String, String> initialMeasurements;
  final String clothingContext;
  final Future<String> Function(String, Map<String, dynamic>)? request;
  @override
  State<AiAssistanceScreen> createState() => _AiAssistanceScreenState();
}

class _AiAssistanceScreenState extends State<AiAssistanceScreen> {
  final input = TextEditingController();
  final messages = <Map<String, String>>[];
  Map<String, String> measurements = {};
  bool busy = false;
  String? error, recommendation;
  String? owner, recommendedAt;
  bool loadingProfile = false;
  @override
  void initState() {
    super.initState();
    measurements = Map.of(widget.initialMeasurements);
    if (widget.recommendations && widget.request == null) {
      loadingProfile = true;
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    try {
      owner = FirebaseAuth.instance.currentUser?.uid;
      if (owner != null) {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        final cached = prefs.getString('recommendations.$owner');
        if (cached != null && widget.clothingContext.isEmpty) {
          final data = jsonDecode(cached) as Map<String, dynamic>;
          recommendation = data['answer'] as String?;
          recommendedAt = data['at'] as String?;
          input.text = data['preferences'] as String? ?? '';
        }
        if (measurements.isEmpty) {
          final doc = await FirebaseFirestore.instance
              .collection('measurements')
              .doc(owner)
              .get();
          if (!mounted) return;
          final data = doc.data() ?? {};
          measurements = {
            for (final e in {
              'Height': 'height',
              'Chest': 'chest',
              'Waist': 'waist',
              'Hips': 'hip',
              'Shoulders': 'shoulders'
            }.entries)
              e.key: '${data[e.value] ?? ''}'
          };
        }
      }
    } catch (_) {
      error = 'Could not load saved preferences. You can enter them below.';
    } finally {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy) return;
    final text = input.text.trim().isEmpty && widget.clothingContext.isNotEmpty
        ? 'Suggest complementary clothing, colours and styles.'
        : input.text.trim();
    if (text.isEmpty ||
        (widget.recommendations && !validAvatarMeasurements(measurements))) {
      setState(() => error = widget.recommendations
          ? 'Enter valid measurements and your preferences.'
          : 'Enter your question.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final pending = [
      ...messages,
      {'role': 'user', 'content': text}
    ];
    try {
      final answer = await (widget.request ?? AiGenerationService.assistance)(
          widget.recommendations ? '/recommendations' : '/chat', {
        'language': AppLanguage.locale.value.languageCode,
        if (widget.recommendations) ...{
          'measurements': measurements,
          if (widget.referenceImage != null)
            'image':
                await AiGenerationService.reference(widget.referenceImage!),
          'preferences': (widget.clothingContext.isEmpty
                  ? text
                  : '${widget.clothingContext}. $text')
              .substring(
                  0,
                  (widget.clothingContext.isEmpty
                          ? text
                          : '${widget.clothingContext}. $text')
                      .length
                      .clamp(0, 500))
        } else
          'messages': (pending.length > 11
                  ? pending.sublist(pending.length - 11)
                  : pending)
              .map((m) => {
                    'role': m['role'],
                    'content': m['content']!.length > 2000
                        ? m['content']!.substring(0, 2000)
                        : m['content']
                  })
              .toList(),
      });
      if (!mounted) return;
      if (widget.recommendations &&
          owner != null &&
          FirebaseAuth.instance.currentUser?.uid == owner) {
        recommendedAt = DateTime.now().toIso8601String();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'recommendations.$owner',
              jsonEncode({
                'answer': answer,
                'at': recommendedAt,
                'preferences': input.text.trim()
              }));
        } catch (_) {
          /* The generated answer remains available in this session. */
        }
      }
      if (!mounted) return;
      setState(() {
        if (widget.recommendations) {
          recommendation = answer;
        } else {
          messages
            ..add({'role': 'user', 'content': text})
            ..add({'role': 'assistant', 'content': answer});
          input.clear();
        }
      });
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppLanguage.observe(
      context,
      () => PrototypePage(
          title: widget.recommendations
              ? (widget.clothingContext.isEmpty
                  ? 'Recommended For You'
                  : 'You May Also Like')
              : 'Help & support',
          nav: false,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppText(widget.recommendations
                ? 'Your measurements and preferences are sent to Cloudflare AI when you request recommendations. Sizes are suggestions; check the brand chart.'
                : 'Ask about uploading clothes, virtual fitting or using FitVisions. Your messages are sent to Cloudflare AI. Do not enter passwords or payment details.'),
            const SizedBox(height: 16),
            if (widget.referenceImage != null)
              const AppText(
                  'The displayed outfit image is sent to AI when you request suggestions.'),
            if (loadingProfile) const LinearProgressIndicator(),
            if (widget.clothingContext.isNotEmpty) Text(widget.clothingContext),
            if (widget.recommendations && !loadingProfile)
              AbsorbPointer(
                  absorbing: busy,
                  child: BodyMeasurements(
                      initialValues: measurements,
                      avatarSizing: true,
                      onChanged: (v) => measurements = v)),
            if (!widget.recommendations && messages.isEmpty)
              Wrap(spacing: 8, children: [
                for (final q in [
                  'How do I upload clothes?',
                  'How do I edit my avatar?',
                  'Why is AI not connected?'
                ])
                  ActionChip(
                      label: AppText(q),
                      onPressed: busy
                          ? null
                          : () {
                              input.text = tr(q);
                              send();
                            })
              ]),
            for (final message in messages)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: PrototypePanel(
                      radius: 16,
                      padding: 12,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                                message['role'] == 'user'
                                    ? 'You'
                                    : 'AI assistant',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            SelectableText(message['content']!)
                          ]))),
            TextField(
                controller: input,
                enabled: !busy,
                maxLength: widget.recommendations ? 500 : 2000,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                    labelText: tr(widget.recommendations
                        ? 'Clothing and colour preferences'
                        : 'Your question'))),
            PrototypeButton(
                widget.recommendations ? 'Get recommendations' : 'Send',
                onPressed: busy || loadingProfile ? null : send),
            if (busy) const LinearProgressIndicator(),
            if (error != null) ...[
              AppText(error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                  onPressed: busy ? null : send, child: const AppText('Retry'))
            ],
            if (recommendation != null)
              const AppText('Latest personal recommendations'),
            if (recommendedAt != null)
              Text(MaterialLocalizations.of(context)
                  .formatShortDate(DateTime.parse(recommendedAt!).toLocal())),
            if (recommendation != null)
              Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SelectableText(recommendation!)),
            if (messages.isNotEmpty)
              TextButton(
                  onPressed: busy ? null : () => setState(messages.clear),
                  child: const AppText('Clear conversation')),
          ])));
}
