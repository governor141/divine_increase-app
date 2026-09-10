import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

/// Admin-only screen: record a voice note in the app and post it as a new
/// Daily Declaration / Prayer, visible to every user on the Prayer screen.
/// Only reachable from PrayerScreen when isCurrentUserAdmin is true — but
/// the real enforcement is Firestore's own security rules, not this check.
class PostPrayerScreen extends StatefulWidget {
  const PostPrayerScreen({super.key});

  @override
  State<PostPrayerScreen> createState() => _PostPrayerScreenState();
}

class _PostPrayerScreenState extends State<PostPrayerScreen> {
  final _recorder = AudioRecorder();
  final _titleCtrl = TextEditingController();
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _uploading = false;
  String? _filePath;
  String? _error;
  Duration _elapsed = Duration.zero;
  DateTime? _startTime;

  @override
  void dispose() {
    _recorder.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _error = null);
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _error = 'Microphone permission is needed to record. Please allow it and try again.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/declaration_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _hasRecording = false;
      _filePath = path;
      _startTime = DateTime.now();
      _elapsed = Duration.zero;
    });
    _tick();
  }

  Future<void> _tick() async {
    while (_isRecording && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording || !mounted) break;
      setState(() => _elapsed = DateTime.now().difference(_startTime!));
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _hasRecording = path != null;
      _filePath = path ?? _filePath;
    });
  }

  Future<void> _discard() async {
    if (_filePath != null) {
      final f = File(_filePath!);
      if (await f.exists()) await f.delete();
    }
    setState(() {
      _hasRecording = false;
      _filePath = null;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _postDeclaration() async {
    if (_filePath == null || _titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please add a title and record audio first.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final url = await CloudinaryService.uploadAudio(File(_filePath!));
      if (url == null) throw Exception('Upload failed');
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('voiceDeclarations').add({
        'title': _titleCtrl.text.trim(),
        'audioUrl': url,
        'addedBy': user?.email ?? 'App',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted! It now shows for everyone on the Prayer screen.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not post — check your connection and try again.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Post Prayer / Declaration', style: AppTheme.heading(size: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppTheme.body(size: 11.5, weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(color: AppColors.cream2, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _titleCtrl,
                style: AppTheme.body(size: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Daily Declaration — Today',
                  hintStyle: AppTheme.body(size: 14, color: AppColors.muted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : (_hasRecording ? null : _startRecording),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? AppColors.danger : AppColors.navy,
                      ),
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, color: AppColors.goldSoft, size: 34),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _isRecording
                        ? _formatDuration(_elapsed)
                        : (_hasRecording ? 'Recording ready (${_formatDuration(_elapsed)})' : 'Tap to record'),
                    style: AppTheme.body(size: 13, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (_hasRecording && !_isRecording) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _discard,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line)),
                  child: Text('Discard & Re-record', style: AppTheme.body(size: 12.5, weight: FontWeight.w600)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: AppTheme.body(size: 12.5, color: AppColors.danger)),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasRecording && !_isRecording && !_uploading) ? _postDeclaration : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: AppColors.line,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Post for Everyone', style: AppTheme.body(size: 14, weight: FontWeight.w700, color: AppColors.navy)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
