import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TikTokPage extends StatefulWidget {
  final String sessionKey;
  
  const TikTokPage({super.key, required this.sessionKey});

  @override
  State<TikTokPage> createState() => _TikTokPageState();
}

class _TikTokPageState extends State<TikTokPage> with SingleTickerProviderStateMixin {
  late String sessionKey;
  List<VideoData> videos = [];
  bool isLoading = false;
  bool hasMore = true;
  bool isError = false;
  String? cursor;
  late PageController _pageController;
  int currentIndex = 0;
  
  late AnimationController _likeController;
  late AnimationController _heartBeatController;
  
  final Color _primaryColor = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor = const Color(0xFFD8D8EC);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF161620);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _goldColor = const Color(0xFFCCBB88);
  final Color _roseColor = const Color(0xFFBB8899);
  
  Set<String> likedVideos = {};
  Set<String> bookmarkedVideos = {};
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _pageController = PageController(initialPage: 0);
    _likeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartBeatController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadUserData();
    _fetchVideos();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    likedVideos = prefs.getStringList('tiktok_likes')?.toSet() ?? {};
    bookmarkedVideos = prefs.getStringList('tiktok_bookmarks')?.toSet() ?? {};
    setState(() {});
  }
  
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tiktok_likes', likedVideos.toList());
    await prefs.setStringList('tiktok_bookmarks', bookmarkedVideos.toList());
  }
  
  Future<void> _fetchVideos() async {
    if (isLoading || !hasMore) return;
    
    setState(() {
      isLoading = true;
      isError = false;
    });
    
    bool success = false;
    
    // API 1: TikWM (most reliable)
    try {
      success = await _fetchFromTikWM();
      if (success) {
        setState(() => isLoading = false);
        return;
      }
    } catch (e) {}
    
    // API 2: TikMate
    if (!success) {
      try {
        success = await _fetchFromTikMate();
        if (success) {
          setState(() => isLoading = false);
          return;
        }
      } catch (e) {}
    }
    
    // API 3: Alternative endpoint
    if (!success) {
      try {
        success = await _fetchFromAltAPI();
        if (success) {
          setState(() => isLoading = false);
          return;
        }
      } catch (e) {}
    }
    
    if (!success && videos.isEmpty) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    } else if (!success) {
      setState(() {
        hasMore = false;
        isLoading = false;
      });
    }
  }
  
  Future<bool> _fetchFromTikWM() async {
    try {
      final String url = cursor != null 
          ? 'https://tikwm.com/api/feed/list?count=15&cursor=$cursor'
          : 'https://tikwm.com/api/feed/list?count=15';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 0 && data['data'] != null) {
          final List<dynamic> videoList = data['data']['videos'] ?? [];
          cursor = data['data']['cursor']?.toString();
          hasMore = data['data']['has_more'] == true;
          
          int newCount = 0;
          for (var item in videoList) {
            String videoUrl = '';
            if (item['play'] != null && item['play'].toString().isNotEmpty) {
              videoUrl = item['play'];
            } else if (item['video'] != null && item['video']['play'] != null) {
              videoUrl = item['video']['play'];
            } else if (item['video_url'] != null && item['video_url'].toString().isNotEmpty) {
              videoUrl = item['video_url'];
            }
            
            if (videoUrl.isNotEmpty) {
              videos.add(VideoData(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                videoUrl: videoUrl,
                username: item['author']?['unique_id'] ?? item['author']?['nickname'] ?? 'unknown_user',
                userAvatar: item['author']?['avatar'] ?? 'https://www.tiktok.com/favicon.ico',
                caption: item['title'] ?? item['desc'] ?? '',
                musicName: item['music']?['title'] ?? 'Original Sound',
                likes: _formatNumber(item['digg_count'] ?? 0),
                comments: _formatNumber(item['comment_count'] ?? 0),
                shares: _formatNumber(item['share_count'] ?? 0),
                isVerified: item['author']?['verified'] == true,
              ));
              newCount++;
            }
          }
          
          if (newCount > 0) {
            setState(() {});
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _fetchFromTikMate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.tikmate.app/api/trending'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> videoList = data['videos'] ?? [];
        
        int newCount = 0;
        for (var item in videoList) {
          String videoUrl = item['url'] ?? '';
          if (videoUrl.isNotEmpty) {
            videos.add(VideoData(
              id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              videoUrl: videoUrl,
              username: item['author'] ?? 'trending_user',
              userAvatar: item['avatar'] ?? 'https://www.tiktok.com/favicon.ico',
              caption: item['title'] ?? '',
              musicName: item['music'] ?? 'Trending Sound',
              likes: _formatNumber(item['likes'] ?? 0),
              comments: _formatNumber(item['comments'] ?? 0),
              shares: _formatNumber(item['shares'] ?? 0),
              isVerified: false,
            ));
            newCount++;
          }
        }
        
        if (newCount > 0) {
          hasMore = false;
          setState(() {});
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _fetchFromAltAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.tikwm.com/api/trending?count=15'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 0 && data['data'] != null) {
          final List<dynamic> videoList = data['data'] ?? [];
          
          int newCount = 0;
          for (var item in videoList) {
            String videoUrl = item['play'] ?? '';
            if (videoUrl.isNotEmpty) {
              videos.add(VideoData(
                id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                videoUrl: videoUrl,
                username: item['author']?['unique_id'] ?? 'trending',
                userAvatar: item['author']?['avatar'] ?? 'https://www.tiktok.com/favicon.ico',
                caption: item['title'] ?? '',
                musicName: item['music']?['title'] ?? 'Original Sound',
                likes: _formatNumber(item['digg_count'] ?? 0),
                comments: _formatNumber(item['comment_count'] ?? 0),
                shares: _formatNumber(item['share_count'] ?? 0),
                isVerified: false,
              ));
              newCount++;
            }
          }
          
          if (newCount > 0) {
            hasMore = false;
            setState(() {});
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  String _formatNumber(dynamic value) {
    num numValue = value is num ? value : (value is String ? num.tryParse(value) ?? 0 : 0);
    if (numValue >= 1000000) return '${(numValue / 1000000).toStringAsFixed(1)}M';
    if (numValue >= 1000) return '${(numValue / 1000).toStringAsFixed(1)}K';
    return numValue.toString();
  }
  
  void _toggleLike(String videoId) {
    setState(() {
      if (likedVideos.contains(videoId)) {
        likedVideos.remove(videoId);
      } else {
        likedVideos.add(videoId);
        _heartBeatController.forward(from: 0);
        _heartBeatController.repeat(reverse: true);
        Future.delayed(const Duration(milliseconds: 600), () {
          _heartBeatController.stop();
        });
      }
    });
    _saveUserData();
  }
  
  void _toggleBookmark(String videoId) {
    setState(() {
      if (bookmarkedVideos.contains(videoId)) {
        bookmarkedVideos.remove(videoId);
      } else {
        bookmarkedVideos.add(videoId);
      }
    });
    _saveUserData();
  }
  
  void _retryFetch() {
    setState(() {
      isError = false;
      hasMore = true;
      cursor = null;
    });
    _fetchVideos();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: videos.isEmpty && isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFE0E0F8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LOADING TIKTOK FEED...',
                    style: _cinzel(12, FontWeight.w700, 0.6),
                  ),
                ],
              ),
            )
          : videos.isEmpty && isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.wifi,
                        size: 64,
                        color: _glowColor1.withOpacity(0.3),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'FAILED TO LOAD VIDEOS',
                        style: _cinzel(14, FontWeight.w700, 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Check your internet connection',
                        style: _cinzel(11, FontWeight.w500, 0.3),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _retryFetch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: _glowColor1.withOpacity(0.3)),
                          ),
                          child: Text(
                            'RETRY',
                            style: _cinzel(12, FontWeight.w700, 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                    if (index >= videos.length - 3 && hasMore && !isLoading) {
                      _fetchVideos();
                    }
                  },
                  itemCount: videos.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == videos.length && hasMore) {
                      return _buildLoadingIndicator();
                    }
                    return _buildVideoPlayer(videos[index]);
                  },
                ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE0E0F8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING MORE VIDEOS',
            style: _cinzel(10, FontWeight.w700, 0.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer(VideoData video) {
    return TikTokVideoPlayer(
      videoUrl: video.videoUrl,
      onLike: () => _toggleLike(video.id),
      onBookmark: () => _toggleBookmark(video.id),
      isLiked: likedVideos.contains(video.id),
      isBookmarked: bookmarkedVideos.contains(video.id),
      videoData: video,
      likeAnimation: _likeController,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      successColor: _successColor,
      warningColor: _warningColor,
      darkBg: _darkBg,
      darkerBg: _darkerBg,
      surfaceColor: _surfaceColor,
      cardColor: _cardColor,
      glowColor1: _glowColor1,
      glowColor2: _glowColor2,
      glowColor3: _glowColor3,
      goldColor: _goldColor,
      roseColor: _roseColor,
    );
  }
  
  TextStyle _cinzel(double size, FontWeight weight, double opacity) {
    return TextStyle(
      fontFamily: 'CinzelDecorative',
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: 1,
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _likeController.dispose();
    _heartBeatController.dispose();
    super.dispose();
  }
}

class VideoData {
  final String id;
  final String videoUrl;
  final String username;
  final String userAvatar;
  final String caption;
  final String musicName;
  final String likes;
  final String comments;
  final String shares;
  final bool isVerified;
  
  VideoData({
    required this.id,
    required this.videoUrl,
    required this.username,
    required this.userAvatar,
    required this.caption,
    required this.musicName,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isVerified,
  });
}

class TikTokVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final bool isLiked;
  final bool isBookmarked;
  final VideoData videoData;
  final AnimationController likeAnimation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color successColor;
  final Color warningColor;
  final Color darkBg;
  final Color darkerBg;
  final Color surfaceColor;
  final Color cardColor;
  final Color glowColor1;
  final Color glowColor2;
  final Color glowColor3;
  final Color goldColor;
  final Color roseColor;
  
  const TikTokVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.onLike,
    required this.onBookmark,
    required this.isLiked,
    required this.isBookmarked,
    required this.videoData,
    required this.likeAnimation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.successColor,
    required this.warningColor,
    required this.darkBg,
    required this.darkerBg,
    required this.surfaceColor,
    required this.cardColor,
    required this.glowColor1,
    required this.glowColor2,
    required this.glowColor3,
    required this.goldColor,
    required this.roseColor,
  });
  
  @override
  State<TikTokVideoPlayer> createState() => _TikTokVideoPlayerState();
}

class _TikTokVideoPlayerState extends State<TikTokVideoPlayer> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _showControls = false;
  bool _hasError = false;
  late AnimationController _fadeController;
  late AnimationController _doubleTapController;
  Offset? _doubleTapPosition;
  int _retryCount = 0;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _doubleTapController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeVideo();
  }
  
  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.tiktok.com/',
        },
      );
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(1.0);
      await _controller.play();
      setState(() {
        _isInitialized = true;
        _isPlaying = true;
        _hasError = false;
      });
    } catch (e) {
      if (_retryCount < 2) {
        _retryCount++;
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _initializeVideo();
        });
      } else {
        setState(() => _hasError = true);
      }
    }
  }
  
  void _togglePlayPause() {
    if (_hasError) return;
    setState(() {
      if (_isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }
  
  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _fadeController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _fadeController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _fadeController.status == AnimationStatus.dismissed) {
            setState(() => _showControls = false);
          }
        });
      }
    });
  }
  
  void _onDoubleTap(TapDownDetails details) {
    if (_hasError) return;
    _doubleTapPosition = details.localPosition;
    _doubleTapController.forward(from: 0);
    widget.onLike();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _doubleTapController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return GestureDetector(
      onTap: () {
        if (_hasError) return;
        _showControlsTemporarily();
        _togglePlayPause();
      },
      onDoubleTapDown: _onDoubleTap,
      child: Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isInitialized && !_hasError)
              VideoPlayer(_controller)
            else if (_hasError)
              Container(
                color: widget.darkerBg,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.videoSlash,
                        size: 48,
                        color: widget.glowColor1.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VIDEO UNAVAILABLE',
                        style: TextStyle(
                          color: widget.glowColor1.withOpacity(0.5),
                          fontSize: 11,
                          fontFamily: 'CinzelDecorative',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                color: widget.darkerBg,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE0E0F8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'LOADING VIDEO...',
                        style: TextStyle(
                          color: widget.glowColor1.withOpacity(0.5),
                          fontSize: 11,
                          fontFamily: 'CinzelDecorative',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (!_hasError) ...[
              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [widget.darkerBg.withOpacity(0.4), Colors.transparent],
                  ),
                ),
              ),
              
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [widget.darkerBg.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
              
              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [widget.darkerBg.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.cardColor.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.glowColor1.withOpacity(0.3), width: 1),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: widget.glowColor1,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '@${widget.videoData.username}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'CinzelDecorative',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (widget.videoData.isVerified) ...[
                                    const SizedBox(width: 4),
                                    Icon(Icons.verified, color: widget.glowColor1, size: 14),
                                  ],
                                ],
                              ),
                              if (widget.videoData.musicName.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.music_note, color: Colors.white70, size: 12),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.videoData.musicName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontFamily: 'CinzelDecorative',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onBookmark,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.cardColor.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.glowColor1.withOpacity(0.3), width: 1),
                            ),
                            child: Icon(
                              widget.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: widget.isBookmarked ? widget.goldColor : widget.glowColor1,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Right Action Buttons
              Positioned(
                right: 12,
                bottom: 100,
                child: Column(
                  children: [
                    _buildActionButton(
                      icon: widget.isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
                      color: widget.isLiked ? widget.roseColor : Colors.white,
                      label: widget.videoData.likes,
                      onTap: widget.onLike,
                      isActive: widget.isLiked,
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: FontAwesomeIcons.comment,
                      color: Colors.white,
                      label: widget.videoData.comments,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: FontAwesomeIcons.share,
                      color: Colors.white,
                      label: widget.videoData.shares,
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.glowColor1, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(widget.videoData.userAvatar),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: widget.glowColor1,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Caption Area
              Positioned(
                left: 16,
                bottom: 100,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.videoData.caption,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontFamily: 'CinzelDecorative',
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Music Disc (TikTok style)
              Positioned(
                left: 16,
                bottom: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.cardColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: widget.glowColor1.withOpacity(0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        widget.videoData.musicName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'CinzelDecorative',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Center Play/Pause Indicator
              if (_showControls && !_isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.cardColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.glowColor1.withOpacity(0.5), width: 2),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: widget.glowColor1,
                      size: 48,
                    ),
                  ),
                ),
              
              // Double Tap Heart Animation
              if (_doubleTapController.isAnimating && _doubleTapPosition != null)
                Positioned(
                  left: _doubleTapPosition!.dx - 40,
                  top: _doubleTapPosition!.dy - 40,
                  child: AnimatedBuilder(
                    animation: _doubleTapController,
                    builder: (context, child) {
                      final scale = 0.5 + (_doubleTapController.value * 1.5);
                      final opacity = 1.0 - _doubleTapController.value;
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Icon(
                            Icons.favorite,
                            color: widget.roseColor,
                            size: 80,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              // Progress Bar
              if (_isInitialized && _showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: widget.glowColor1,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white12,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.cardColor.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color.withOpacity(0.5) : Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'CinzelDecorative',
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }
}