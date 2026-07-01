import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  runApp(const DracinApp());
}

class DracinApp extends StatelessWidget {
  const DracinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dracin - Drama China',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.grey[800],
        useMaterial3: true,
      ),
      home: const TikTokStyleDracin(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Drama {
  final String id;
  final String title;
  final String youtubeVideoId;
  final String thumbnail;
  final String description;
  final String genre;
  final int episodeCount;
  final double rating;
  final List<Episode> episodes;

  Drama({
    required this.id,
    required this.title,
    required this.youtubeVideoId,
    required this.thumbnail,
    required this.description,
    required this.genre,
    required this.episodeCount,
    required this.rating,
    required this.episodes,
  });
}

class Episode {
  final int episodeNumber;
  final String title;
  final String youtubeVideoId;
  final String thumbnail;

  Episode({
    required this.episodeNumber,
    required this.title,
    required this.youtubeVideoId,
    required this.thumbnail,
  });
}

List<Drama> allDramas = [
  Drama(
    id: '1',
    title: 'ISTRIKU TIGA TAKDIRKU GILA',
    youtubeVideoId: 'dQw4w9WgXcQ', 
    thumbnail: 'https://picsum.photos/id/100/300/500',
    description: 'Seorang pria biasa mendapati dirinya memiliki tiga istri dari takdir yang berbeda.',
    genre: 'Romance',
    episodeCount: 120,
    rating: 4.8,
    episodes: List.generate(120, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ', 
      thumbnail: 'https://picsum.photos/id/${100 + index}/300/500',
    )),
  ),
  Drama(
    id: '2',
    title: 'DEWA PEDANG DIANTARA KITA',
    youtubeVideoId: 'dQw4w9WgXcQ',
    thumbnail: 'https://picsum.photos/id/101/300/500',
    description: 'Seorang pemuda lemah ternyata adalah reinkarnasi dewa pedang terkuat.',
    genre: 'Action',
    episodeCount: 88,
    rating: 4.9,
    episodes: List.generate(88, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://picsum.photos/id/${101 + index}/300/500',
    )),
  ),
  Drama(
    id: '3',
    title: 'HITUNGAN MUNDUR TAKDIR',
    youtubeVideoId: 'dQw4w9WgXcQ',
    thumbnail: 'https://picsum.photos/id/102/300/500',
    description: 'Detektif dengan kekuatan melihat kematian harus menghentikan pembunuh berantai.',
    genre: 'Thriller',
    episodeCount: 24,
    rating: 4.7,
    episodes: List.generate(24, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://picsum.photos/id/${102 + index}/300/500',
    )),
  ),
  Drama(
    id: '4',
    title: 'SI LEMAH PENYELAMAT DUNIA',
    youtubeVideoId: 'dQw4w9WgXcQ',
    thumbnail: 'https://picsum.photos/id/103/300/500',
    description: 'Pria diremehkan ternyata punya kekuatan super untuk selamatkan bumi.',
    genre: 'Sci-Fi',
    episodeCount: 50,
    rating: 4.6,
    episodes: List.generate(50, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://picsum.photos/id/${103 + index}/300/500',
    )),
  ),
  Drama(
    id: '5',
    title: 'MAFIA DARI MASA DEPAN',
    youtubeVideoId: 'dQw4w9WgXcQ',
    thumbnail: 'https://picsum.photos/id/104/300/500',
    description: 'Mafia dari 2050 kembali ke masa lalu untuk cegah perang saudara.',
    genre: 'Crime',
    episodeCount: 36,
    rating: 4.8,
    episodes: List.generate(36, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://picsum.photos/id/${104 + index}/300/500',
    )),
  ),
  Drama(
    id: '6',
    title: 'CINTA DI UJUNG SAJADAH',
    youtubeVideoId: 'dQw4w9WgXcQ',
    thumbnail: 'https://picsum.photos/id/105/300/500',
    description: 'Wanita karir sukses menemukan cinta di masjid kecil kampung.',
    genre: 'Religious',
    episodeCount: 30,
    rating: 4.9,
    episodes: List.generate(30, (index) => Episode(
      episodeNumber: index + 1,
      title: 'Episode ${index + 1}',
      youtubeVideoId: 'dQw4w9WgXcQ',
      thumbnail: 'https://picsum.photos/id/${105 + index}/300/500',
    )),
  ),
];

class TikTokStyleDracin extends StatefulWidget {
  const TikTokStyleDracin({super.key});

  @override
  State<TikTokStyleDracin> createState() => _TikTokStyleDracinState();
}

class _TikTokStyleDracinState extends State<TikTokStyleDracin> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<Drama> _dramas = [];
  bool _isLoading = true;
  String _selectedGenre = 'All';
  
  final List<String> _genres = ['All', 'Action', 'Romance', 'Thriller', 'Sci-Fi', 'Crime', 'Religious'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDramas();
  }

  void _loadDramas() {
    setState(() {
      _dramas = allDramas;
      _isLoading = false;
    });
  }

  void _filterByGenre(String genre) {
    setState(() {
      _selectedGenre = genre;
      if (genre == 'All') {
        _dramas = allDramas;
      } else {
        _dramas = allDramas.where((d) => d.genre == genre).toList();
      }
      _currentIndex = 0;
      _pageController.jumpToPage(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _dramas.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return DracinVideoPlayer(drama: _dramas[index]);
              },
            ),
          
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
          
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: _buildGenreFilter(),
          ),
          
          Positioned(
            bottom: 100,
            left: 16,
            right: 100,
            child: _buildSideInfo(),
          ),

          Positioned(
            bottom: 100,
            right: 16,
            child: _buildActionButtons(),
          ),
          
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRACIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Swipe untuk drama berikutnya',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreFilter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = _selectedGenre == genre;
          
          return GestureDetector(
            onTap: () => _filterByGenre(genre),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                      )
                    : null,
                color: isSelected ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSideInfo() {
    final drama = _dramas[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          drama.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                drama.genre,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  drama.rating.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              '${drama.episodeCount} eps',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          drama.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black87, blurRadius: 5)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(Icons.favorite_border, '1.2M'),
        const SizedBox(height: 20),
        _buildActionButton(Icons.comment_outlined, '45K'),
        const SizedBox(height: 20),
        _buildActionButton(Icons.share_outlined, 'Share'),
        const SizedBox(height: 20),
        _buildActionButton(Icons.playlist_play, 'Ep'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(_dramas.length, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color(0xFF9CA3AF)
                    : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class DracinVideoPlayer extends StatefulWidget {
  final Drama drama;
  const DracinVideoPlayer({super.key, required this.drama});

  @override
  State<DracinVideoPlayer> createState() => _DracinVideoPlayerState();
}

class _DracinVideoPlayerState extends State<DracinVideoPlayer> {
  late YoutubePlayerController _youtubeController;
  bool _isPlayerReady = false;
  int _currentEpisode = 1;
  bool _showEpisodeList = false;

  @override
  void initState() {
    super.initState();
    _initYoutubePlayer();
  }

  void _initYoutubePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.drama.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        disableDragSeek: false,
      ),
    );
    _youtubeController.addListener(() {
      if (_youtubeController.value.isReady && !_isPlayerReady) {
        setState(() {
          _isPlayerReady = true;
        });
      }
    });
  }

  void _changeEpisode(Episode episode) {
    setState(() {
      _currentEpisode = episode.episodeNumber;
      _showEpisodeList = false;
    });
    _youtubeController.load(episode.youtubeVideoId);
    _youtubeController.play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showEpisodeList = false;
        });
      },
      child: Stack(
        children: [
          YoutubePlayerBuilder(
            player: YoutubePlayer(
              controller: _youtubeController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF9CA3AF),
              onReady: () {
                setState(() {
                  _isPlayerReady = true;
                });
              },
              bottomActions: [
                CurrentPosition(),
                ProgressBar(isExpanded: true),
                RemainingDuration(),
                FullScreenButton(),
              ],
            ),
            builder: (context, player) {
              return Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: player,
              );
            },
          ),
          
          Positioned(
            top: 160,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showEpisodeList = !_showEpisodeList;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9CA3AF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ep $_currentEpisode/${widget.drama.episodeCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Icon(
                      _showEpisodeList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_showEpisodeList)
            Positioned(
              top: 210,
              right: 16,
              left: 16,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF9CA3AF).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10)),
                      ),
                      child: const Text(
                        'Daftar Episode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.drama.episodes.length,
                        itemBuilder: (context, index) {
                          final episode = widget.drama.episodes[index];
                          final isSelected = _currentEpisode == episode.episodeNumber;
                          return GestureDetector(
                            onTap: () => _changeEpisode(episode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF9CA3AF).withOpacity(0.1)
                                    : null,
                                border: const Border(
                                  bottom: BorderSide(color: Colors.white10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(episode.thumbnail),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Episode ${episode.episodeNumber}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF9CA3AF)
                                                : Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          episode.title,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.play_circle_filled,
                                      color: Color(0xFF9CA3AF),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    super.dispose();
  }
}