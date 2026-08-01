import 'package:clock_app/voice/alarm_mapper.dart';
import 'package:clock_app/voice/local_alarm_parser.dart';
import 'package:clock_app/voice/parsed_alarm.dart';
import 'package:clock_app/theme/aurora/aurora_surface.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _VoiceAgentState {
  listening,
  processing,
  missingTime,
  complete,
  error,
}

class VoiceAgentSheet extends StatefulWidget {
  const VoiceAgentSheet({super.key});

  @override
  State<VoiceAgentSheet> createState() => _VoiceAgentSheetState();
}

class _VoiceAgentSheetState extends State<VoiceAgentSheet> {
  final SpeechToText _speech = SpeechToText();

  _VoiceAgentState _state = _VoiceAgentState.listening;
  String _transcript = '';
  String _errorMessage = '';
  ParsedAlarm? _parsedAlarm;
  bool _parseStarted = false;

  bool get isListening => _state == _VoiceAgentState.listening;
  bool get isProcessing => _state == _VoiceAgentState.processing;
  bool get isComplete => _state == _VoiceAgentState.complete;
  bool get hasError => _state == _VoiceAgentState.error;

  @override
  void initState() {
    super.initState();
    _initializeAndListen();
  }

  Future<void> _initializeAndListen() async {
    final available = await _speech.initialize(
      onStatus: _handleSpeechStatus,
      onError: _handleSpeechError,
    );
    if (!mounted) return;

    if (!available) {
      _showError('Speech recognition is unavailable on this device.');
      return;
    }

    setState(() {
      _state = _VoiceAgentState.listening;
      _transcript = '';
      _errorMessage = '';
      _parseStarted = false;
    });

    await _speech.listen(
      onResult: _handleSpeechResult,
      listenMode: ListenMode.confirmation,
      partialResults: true,
      cancelOnError: true,
    );
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _transcript = result.recognizedWords);
    if (result.finalResult) {
      _processTranscript();
    }
  }

  void _handleSpeechStatus(String status) {
    if ((status == 'done' || status == 'notListening') &&
        _transcript.trim().isNotEmpty) {
      _processTranscript();
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (!mounted || _parseStarted) return;
    _showError(error.errorMsg);
  }

  Future<void> _processTranscript() async {
    if (_parseStarted || _transcript.trim().isEmpty) return;
    _parseStarted = true;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _state = _VoiceAgentState.processing);

    final result = LocalAlarmParser.parse(_transcript);
    if (!mounted) return;

    if (result == null) {
      _showError(
        LocalAlarmParser.failureMessage ??
            'Could not understand the alarm. Please try again.',
      );
      return;
    }

    setState(() {
      _parsedAlarm = result;
      _state = result.isComplete
          ? _VoiceAgentState.complete
          : _VoiceAgentState.missingTime;
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _parsedAlarm = _parsedAlarm!.copyWith(
        hour: selected.hour,
        minute: selected.minute,
      );
      _state = _VoiceAgentState.complete;
    });
  }

  Future<void> _saveAlarm() async {
    final alarm = _parsedAlarm;
    if (alarm == null || !alarm.isComplete) return;

    setState(() => _state = _VoiceAgentState.processing);
    try {
      await saveParsedAlarm(alarm, context);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        _showError('The alarm could not be saved. Please try again.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _state = _VoiceAgentState.error;
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: AuroraSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        accent: DopamineTokens.cyan,
        emphasized: true,
        padding: EdgeInsets.fromLTRB(
          24,
          14,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 52,
                  height: 7,
                  decoration: BoxDecoration(
                    color: DopamineTokens.magenta,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: DopamineTokens.yellow,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close voice agent',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    foregroundColor: DopamineTokens.cosmic,
                    backgroundColor: DopamineTokens.yellow,
                    side: const BorderSide(
                      color: DopamineTokens.magenta,
                      width: 3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _VoiceOrb(listening: isListening, processing: isProcessing),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Text(
                _title,
                key: ValueKey(_state),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: DopamineTokens.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                  shadows: const [
                    Shadow(color: DopamineTokens.purple, offset: Offset(2, 2)),
                    Shadow(color: DopamineTokens.magenta, offset: Offset(4, 4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_transcript.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DopamineTokens.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DopamineTokens.orange, width: 3),
                ),
                child: Text(
                  '“$_transcript”',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: DopamineTokens.white,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(),
            if (isListening && _transcript.isEmpty)
              Text(
                'Try "Remind me every day at 7 AM to cook soya and eggs."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DopamineTokens.white.withOpacity(.76),
                ),
              ),
            if (isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: LinearProgressIndicator()),
            ],
            if (_state == _VoiceAgentState.missingTime) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Select Time'),
              ),
            ],
            if (isComplete && _parsedAlarm != null) ...[
              const SizedBox(height: 20),
              _ConfirmationCard(alarm: _parsedAlarm!)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: .08, end: 0),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saveAlarm,
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text('Save Alarm'),
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DopamineTokens.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _initializeAndListen,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (_state) {
      case _VoiceAgentState.listening:
        return "I'm listening";
      case _VoiceAgentState.processing:
        return 'Building your alarm';
      case _VoiceAgentState.missingTime:
        return 'What time should I use?';
      case _VoiceAgentState.complete:
        return 'Everything looks good';
      case _VoiceAgentState.error:
        return "Let's try that again";
    }
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({required this.listening, required this.processing});

  final bool listening;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final accent = processing ? DopamineTokens.yellow : DopamineTokens.magenta;
    Widget orb = Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent,
          border: Border.all(
            color: DopamineTokens.clashFor(accent),
            width: 4,
          ),
          boxShadow: DopamineTokens.stackedShadow(accent, emphasized: true),
        ),
        child: Icon(
          processing ? Icons.graphic_eq_rounded : Icons.mic_rounded,
          color: DopamineTokens.inkFor(accent),
          size: 38,
        ),
      ),
    );
    if (listening && !reduceMotion) {
      orb = orb
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: .96, end: 1.05, duration: 900.ms);
    }
    return orb;
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({required this.alarm});

  final ParsedAlarm alarm;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay(hour: alarm.hour!, minute: alarm.minute!);
    final recurrence = _recurrenceDescription(context);

    return AuroraSurface(
      padding: const EdgeInsets.all(18),
      accent: DopamineTokens.yellow,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alarm.label.isEmpty ? 'Voice Alarm' : alarm.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.schedule_rounded,
              value: time.format(context),
            ),
            const SizedBox(height: 6),
            _DetailRow(
              icon: Icons.repeat_rounded,
              value: recurrence,
            ),
          ],
        ),
      ),
    );
  }

  String _recurrenceDescription(BuildContext context) {
    if (alarm.recurrence == 'interval') {
      final amount = alarm.intervalValue ?? 1;
      final rawUnit = alarm.intervalUnit ?? 'days';
      final unit = amount == 1 && rawUnit.endsWith('s')
          ? rawUnit.substring(0, rawUnit.length - 1)
          : rawUnit;
      var value = amount == 1
          ? 'Every ${_titleCase(unit)}'
          : 'Every $amount ${_titleCase(unit)}';
      if (alarm.weekOfMonth != null && alarm.days.isNotEmpty) {
        final week =
            alarm.weekOfMonth == -1 ? 'Last' : _ordinal(alarm.weekOfMonth!);
        value = 'Every Month On The $week ${_titleCase(alarm.days.first)}';
      } else if (alarm.monthDay != null) {
        final day = alarm.monthDay == -1 ? 'Last Day' : 'Day ${alarm.monthDay}';
        value = 'Every Month On $day';
      } else if (alarm.days.isNotEmpty) {
        value += ' On ${alarm.days.map(_titleCase).join(', ')}';
      }
      if (alarm.date != null) {
        final start =
            MaterialLocalizations.of(context).formatMediumDate(alarm.date!);
        value += ' · Starts $start';
      }
      return value;
    }
    if (alarm.date != null) {
      return MaterialLocalizations.of(context).formatFullDate(alarm.date!);
    }
    if (alarm.recurrence == 'weekly' && alarm.days.isNotEmpty) {
      return alarm.days.map(_titleCase).join(', ');
    }
    return _titleCase(alarm.recurrence);
  }

  static String _ordinal(int value) {
    final mod100 = value % 100;
    final suffix = mod100 >= 11 && mod100 <= 13
        ? 'th'
        : switch (value % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    return '$value$suffix';
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DopamineTokens.cyan,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DopamineTokens.orange, width: 2),
          ),
          child: Icon(icon, size: 20, color: DopamineTokens.cosmic),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    );
  }
}
