import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../services/ai_generation_service.dart';
import '../services/body_size_presets.dart';
import '../widgets/prototype_ui.dart';
import '../widgets/measurement_guide.dart';

class AiAssistanceScreen extends StatefulWidget {
  const AiAssistanceScreen(
      {super.key, this.recommendations = false, this.request});
  final bool recommendations;
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
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy) return;
    final text = input.text.trim();
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
          'preferences': text
        } else
          'messages': (pending.length > 11 ? pending.sublist(pending.length - 11) : pending).map((m) => {'role':m['role'], 'content':m['content']!.length>2000 ? m['content']!.substring(0,2000) : m['content']}).toList(),
      });
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
              ? 'AI size and colour recommendations'
              : 'FitVisions AI assistant',
          nav: false,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppText(widget.recommendations
                ? 'Your measurements and preferences are sent to Cloudflare AI when you request recommendations. Sizes are suggestions; check the brand chart.'
                : 'Ask about uploading clothes, virtual fitting or using FitVisions. Your messages are sent to Cloudflare AI. Do not enter passwords or payment details.'),
            const SizedBox(height: 16),
            if (widget.recommendations)
              AbsorbPointer(
                  absorbing: busy,
                  child: BodyMeasurements(
                      avatarSizing: true, onChanged: (v) => measurements = v)),
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
                onPressed: busy ? null : send),
            if (busy) const LinearProgressIndicator(),
            if (error != null) ...[
              AppText(error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                  onPressed: busy ? null : send, child: const AppText('Retry'))
            ],
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
