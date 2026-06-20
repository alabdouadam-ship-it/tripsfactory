import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:tripsfactory/core/utils/format_utils.dart';
import 'package:tripsfactory/features/chat/data/chat_attachment_url.dart';

class AudioMessageBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  final Duration? duration;

  const AudioMessageBubble({
    super.key,
    required this.url,
    required this.isMe,
    this.duration,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();
    _duration = widget.duration ?? Duration.zero;

    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((
      newDuration,
    ) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((
      newPosition,
    ) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Resolve to a signed URL (private chat-attachments bucket) before play.
      final url = await ChatAttachmentUrl.resolve(widget.url) ?? widget.url;
      await _audioPlayer.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isMe ? Colors.white : theme.colorScheme.onSurface;
    final trackColor = widget.isMe
        ? Colors.white38
        : theme.colorScheme.surfaceContainerHighest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _togglePlay,
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          color: color,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 2,
                activeTrackColor: color,
                inactiveTrackColor: trackColor,
                thumbColor: color,
              ),
              child: SizedBox(
                width: 150,
                child: Slider(
                  value: _position.inMilliseconds
                      .clamp(0, _duration.inMilliseconds)
                      .toDouble(),
                  max: _duration.inMilliseconds > 0
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                FormatUtils.formatDuration(
                  _duration > Duration.zero
                      ? _duration
                      : (widget.duration ?? Duration.zero),
                ),
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
