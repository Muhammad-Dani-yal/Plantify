import 'package:flutter/material.dart';
import '../components/motion_icon.dart';
import '../services/plant_guide.dart';
import '../state/app_state.dart';
import '../components/botanical_widgets.dart';

class PlantChatScreen extends StatefulWidget {
  const PlantChatScreen({super.key, this.plantContext = '', this.guide});
  final String plantContext;
  final PlantGuide? guide;
  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <GuideMessage>[];
  late final PlantGuide _guide = widget.guide ?? FirebasePlantGuide();
  bool _busy = false;
  String? _error, _uid;
  String? _failed;
  int _version = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = AppScope.of(context).account?.id;
    if (_uid != uid) {
      _uid = uid;
      _reset();
    }
  }

  void _reset() {
    _version++;
    _messages.clear();
    _busy = false;
    _error = _failed = null;
    _input.clear();
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });
  Future<void> _send([String? suggestion]) async {
    final text = (suggestion ?? _input.text).trim();
    if (_busy || text.isEmpty || text.length > 2000) return;
    final version = ++_version;
    setState(() {
      _error = _failed = null;
      _busy = true;
      _input.clear();
      _messages.add(GuideMessage(text));
    });
    _bottom();
    try {
      final answer = await _guide.answer(
          List.unmodifiable(_messages
              .skip(_messages.length > 25 ? _messages.length - 25 : 0)),
          widget.plantContext);
      if (!mounted || version != _version) return;
      setState(() {
        _messages.add(GuideMessage(answer, fromUser: false));
        _busy = false;
      });
      _bottom();
    } catch (_) {
      if (!mounted || version != _version) return;
      setState(() {
        _messages.removeLast();
        _failed = text;
        _busy = false;
        _error =
            'The AI guide could not answer right now. Your question is kept below. Check your connection and retry in a moment.';
        _input.text = text;
      });
    }
  }

  @override
  void dispose() {
    _version++;
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  MotionIcon(Icons.auto_awesome, size: 20, live: true),
                  SizedBox(width: 10),
                  Text('Plantify AI guide'),
                ])),
            actions: [
              IconButton(
                  tooltip: 'New conversation',
                  onPressed: () => setState(_reset),
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(children: [
            Expanded(
                child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(20),
                    children: [
                  if (_messages.isEmpty) ...[
                    const BrandMark(size: 58),
                    const SizedBox(height: 16),
                    Text('A growing companion,\nevery step of the way.',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    const Text(
                        'Ask in English, Urdu, or Roman Urdu. Start from choosing a plant, or tell me what needs help today.'),
                    if (widget.plantContext.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              'Discussing: ${widget.plantContext.split('\n').first}')),
                    const SizedBox(height: 20),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final entry in const {
                        '1 · Choose a plant':
                            'I am new to gardening. Help me choose my first plant step by step.',
                        '2 · Light & location':
                            'How do I find the right light and location for my plant?',
                        '3 · Pot & soil':
                            'Help me choose a pot and soil for my plant.',
                        '4 · Watering':
                            'How can I tell when my plant needs water?',
                        '5 · First week':
                            'Guide me through my first week caring for a new plant.',
                        'Fruit garden':
                            'Which fruit plants could I grow? Ask about my climate and space first.',
                        'Rare plants':
                            'Help me explore unusual plants suitable for growing at home.',
                        'Plant problems':
                            'Help me troubleshoot my plant step by step.',
                      }.entries)
                        ActionChip(
                            avatar:
                                MotionIcon(collectionIcon(entry.key), size: 16),
                            label: Text(entry.key),
                            onPressed: () => _send(entry.value)),
                    ]),
                    const SizedBox(height: 20),
                    const Text(
                        'Questions are sent to the AI provider. Answers can be mistaken; confirm important plant care details. Conversations stay in this screen and clear when you leave.',
                        style: TextStyle(fontSize: 12)),
                  ],
                  for (final message in _messages)
                    Align(
                        alignment: message.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            constraints: const BoxConstraints(maxWidth: 680),
                            decoration: BoxDecoration(
                                color: message.fromUser
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.fromUser ? 'You' : 'Plantify AI',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  const SizedBox(height: 8),
                                  SelectableText(message.text),
                                ]))),
                  if (_busy)
                    const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(children: [
                          SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Your guide is thinking…')
                        ])),
                  if (_error != null) ...[
                    Text(_error!),
                    TextButton.icon(
                        onPressed: () => _send(_failed),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry question')),
                  ],
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                      child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          enabled: !_busy,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                              hintText: 'Ask about your plants…',
                              counterText: '',
                              border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      tooltip: 'Send question',
                      onPressed: _busy ? null : () => _send(),
                      icon: const Icon(Icons.send_rounded)),
                ])),
          ]),
        ))),
      );
}
