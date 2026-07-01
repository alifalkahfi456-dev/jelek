import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class YouTubeS extends StatefulWidget {
  const YouTubeS({super.key});

  @override
  State<YouTubeS> createState() => _YouTubeSState();
}

class _YouTubeSState extends State<YouTubeS> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  bool _isPlaying = false;
  bool _hasSearchResult = false;
  bool _loadingLyrics = false;

  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedTrack;
  Map<String, dynamic>? _trackData;
  Map<String, dynamic>? _lyricsData;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int _currentTrackIndex = -1;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
  }

  Future<void> _searchTrack() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearchResult = false;
      _searchResults = [];
      _selectedTrack = null;
      _trackData = null;
      _currentTrackIndex = -1;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _lyricsData = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.deline.web.id/search/youtube?q=${Uri.encodeComponent(_searchController.text)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['result'] != null) {
          setState(() {
            _searchResults = data['result'];
            _hasSearchResult = true;
          });
        } else {
          _showError('Tidak ada hasil ditemukan');
        }
      } else {
        _showError('Gagal menghubungi server');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTrack(Map<String, dynamic> track, int index) async {
    setState(() {
      _selectedTrack = track;
      _currentTrackIndex = index;
      _isLoading = true;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _lyricsData = null;
      _trackData = null;
    });

    try {
      await _audioPlayer.stop();

      final response = await http.get(
  Uri.parse(
    'https://api.ikyyxd.my.id/download/ytmp3?url=${Uri.encodeComponent(track['link'])}',
  ),
  headers: {
    'x-api-key': 'kyzz',
  },
);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true &&
            data['result'] != null &&
            data['result']['audio'] != null &&
            data['result']['audio']['url'] != null) {
          setState(() {
            _trackData = {
              'title': data['result']['title'] ?? track['title'],
              'thumbnail': data['result']['thumbnail'] ?? track['imageUrl'],
              'download_url': data['result']['audio']['url'],
              'quality': data['result']['audio']['quality'] ?? '-',
              'duration': data['result']['duration'] ?? 0,
              'size': '-',
            };
          });

          _fetchLyrics(_trackData!['title']);
          await _playTrack();
        } else {
          _showError('Gagal mengambil audio');
        }
      } else {
        _showError('Gagal menghubungi server');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLyrics(String title) async {
    setState(() => _loadingLyrics = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.deline.web.id/tools/lyrics?title=${Uri.encodeComponent(title)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == true &&
            data['result'] != null &&
            data['result'].isNotEmpty) {
          setState(() => _lyricsData = data['result'][0]);
        }
      }
    } catch (e) {
      debugPrint('Error lyrics: $e');
    } finally {
      if (mounted) setState(() => _loadingLyrics = false);
    }
  }

  Future<void> _playTrack() async {
    if (_trackData != null && _trackData!['download_url'] != null) {
      await _audioPlayer.play(
        UrlSource(_trackData!['download_url']),
      );
    }
  }

  Future<void> _pauseTrack() async {
    await _audioPlayer.pause();
  }

  void _playPreviousTrack() {
    if (_searchResults.isNotEmpty && _currentTrackIndex > 0) {
      _selectTrack(
        _searchResults[_currentTrackIndex - 1],
        _currentTrackIndex - 1,
      );
    }
  }

  void _playNextTrack() {
    if (_searchResults.isNotEmpty &&
        _currentTrackIndex < _searchResults.length - 1) {
      _selectTrack(
        _searchResults[_currentTrackIndex + 1],
        _currentTrackIndex + 1,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return '${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'LEGIONS Music',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari lagu...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _searchTrack(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC143C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search, color: Colors.white),
                    onPressed: _isLoading ? null : _searchTrack,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_hasSearchResult &&
                _searchResults.isNotEmpty &&
                _selectedTrack == null)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final track = _searchResults[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            track['imageUrl'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.music_note,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        title: Text(
                          track['title'] ?? 'Unknown Title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track['channel'] ?? 'Unknown Channel',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  color: Colors.grey,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  track['duration'] ?? '-',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.play_arrow,
                          color: Color(0xFFDC143C),
                        ),
                        onTap: () => _selectTrack(track, index),
                      ),
                    );
                  },
                ),
              )
            else if (_selectedTrack != null && _trackData != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _trackData!['thumbnail'] ?? '',
                                width: double.infinity,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 280,
                                  color: Colors.black26,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.grey,
                                    size: 80,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _trackData!['title'] ?? 'Unknown Title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedTrack!['channel'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _trackData!['quality'] ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Slider(
                        value: _position.inSeconds.toDouble().clamp(
                              0,
                              _duration.inSeconds > 0
                                  ? _duration.inSeconds.toDouble()
                                  : 1,
                            ),
                        max: _duration.inSeconds > 0
                            ? _duration.inSeconds.toDouble()
                            : 1,
                        onChanged: (v) {
                          _audioPlayer.seek(
                            Duration(seconds: v.toInt()),
                          );
                        },
                        activeColor: const Color(0xFFDC143C),
                        inactiveColor: Colors.white24,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _playPreviousTrack,
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: const Color(0xFFDC143C),
                              size: 60,
                            ),
                            onPressed: _isPlaying ? _pauseTrack : _playTrack,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _playNextTrack,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_loadingLyrics)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            color: Color(0xFFDC143C),
                          ),
                        )
                      else if (_lyricsData != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _lyricsData!['plainLyrics'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ),

                      TextButton(
                        onPressed: () async {
                          await _audioPlayer.stop();
                          setState(() {
                            _selectedTrack = null;
                            _trackData = null;
                            _lyricsData = null;
                            _position = Duration.zero;
                            _duration = Duration.zero;
                            _isPlaying = false;
                          });
                        },
                        child: const Text(
                          'Kembali',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFDC143C),
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "Cari lagu favoritmu",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension FormatNumber on num {
  String formatViews() {
    if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    }
    return toString();
  }

  String formatDuration() {
    final minutes = (this / 60).floor();
    final seconds = this % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}