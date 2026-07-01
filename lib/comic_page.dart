import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ComicPage extends StatefulWidget {
  const ComicPage({super.key});

  @override
  State<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends State<ComicPage> {
  // --- VARIABLES ---
  final Color _primaryBackground = const Color(0xFF000000);
  final Color _accentRed = const Color(0xFFA9A9A9);
  final Color _glowColor = const Color(0xFFE0E0E0);
  
  // Controller pencarian
  final TextEditingController _searchController = TextEditingController();
  
  // Data List
  List<dynamic> _comicList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _headingText = "Hot Comic";

  @override
  void initState() {
    super.initState();
    _fetchTopManga(); // Ambil data saat pertama buka
  }

  // --- API FUNCTIONS (Jikan API V4) ---
  
  // 1. Ambil Top Manga (Hot Comic)
  Future<void> _fetchTopManga() async {
    setState(() { _isLoading = true; _isSearching = false; _headingText = "Hot Comic"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/top/manga?limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. Cari Manga
  Future<void> _searchManga(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _isSearching = true; _headingText = "Search Result"; });
    try {
      final response = await http.get(Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=20'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _comicList = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error searching manga: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- WIDGET BUILDER ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Revengers Comic", style: TextStyle(fontFamily: "Orbitron", fontWeight: FontWeight.bold, fontSize: 16)),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Red-Black
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0000), Color(0xFF000000)],
              ),
            ),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // 1. HEADER CARD (Comic Area)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0000),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accentRed.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(color: _accentRed.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    children: [
                      Icon(FontAwesomeIcons.bookOpenReader, color: _glowColor, size: 35),
                      const SizedBox(height: 10),
                      Text("Comic Zone", style: TextStyle(color: _glowColor, fontSize: 22, fontFamily: "Orbitron", fontWeight: FontWeight.bold, shadows: [BoxShadow(color: _glowColor, blurRadius: 10)])),
                      const SizedBox(height: 5),
                      const Text("Read & Find Your Favorite Manga", style: TextStyle(color: Colors.white54, fontFamily: "ShareTechMono", fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 2. SEARCH BAR
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontFamily: "ShareTechMono"),
                    decoration: InputDecoration(
                      hintText: "Search Manga / Comic...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: Icon(Icons.search, color: _accentRed),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white70, size: 20),
                        onPressed: () => _searchManga(_searchController.text),
                      ),
                    ),
                    onSubmitted: (value) => _searchManga(value),
                  ),
                ),

                const SizedBox(height: 15),

                // 3. RECOMMENDATION CHIPS
                const Text("Recommendation Search:", style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: "Orbitron")),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildRecChip("One Piece"),
                      _buildRecChip("Naruto"),
                      _buildRecChip("Solo Leveling"),
                      _buildRecChip("Berserk"),
                      _buildRecChip("Chainsaw Man"),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. TITLE SECTION (Hot Comic / Result)
                Row(
                  children: [
                    Container(
                      height: 20, width: 4,
                      decoration: BoxDecoration(color: _glowColor, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: _glowColor, blurRadius: 8)]),
                    ),
                    const SizedBox(width: 10),
                    Text(_headingText, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: "Orbitron", fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if(_isSearching)
                      GestureDetector(
                        onTap: _fetchTopManga,
                        child: const Text("Reset", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      )
                  ],
                ),

                const SizedBox(height: 15),

                // 5. GRID LIST COMIC
                _isLoading 
                  ? Container(height: 300, alignment: Alignment.center, child: CircularProgressIndicator(color: _glowColor))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 Kolom
                        childAspectRatio: 0.65, // Rasio Tinggi vs Lebar
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _comicList.length,
                      itemBuilder: (context, index) {
                        final manga = _comicList[index];
                        return _buildComicCard(manga);
                      },
                    ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildRecChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {
          _searchController.text = text;
          _searchManga(text);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0505),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentRed.withOpacity(0.3)),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: "ShareTechMono")),
        ),
      ),
    );
  }

  Widget _buildComicCard(dynamic manga) {
    String imageUrl = manga['images']['jpg']['image_url'] ?? '';
    String title = manga['title'] ?? 'Unknown';
    String score = manga['score'] != null ? manga['score'].toString() : 'N/A';
    String type = manga['type'] ?? 'Manga';

    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail
        Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailPage(mangaData: manga)));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF101010),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900], child: const Icon(Icons.broken_image, color: Colors.white24)),
                    ),
                    // Badge Score
                    Positioned(
                      top: 5, right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 3),
                            Text(score, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    // Badge Type
                     Positioned(
                      top: 5, left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _accentRed.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                        child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info Bawah
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: "Orbitron")),
                  const SizedBox(height: 5),
                  Text("Tap to read story", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HALAMAN DETAIL KOMIK ---
class ComicDetailPage extends StatelessWidget {
  final Map<String, dynamic> mangaData;

  const ComicDetailPage({super.key, required this.mangaData});

  @override
  Widget build(BuildContext context) {
    String imageUrl = mangaData['images']['jpg']['large_image_url'] ?? mangaData['images']['jpg']['image_url'];
    String title = mangaData['title'] ?? 'Unknown';
    String synopsis = mangaData['synopsis'] ?? 'No synopsis available.';
    String status = mangaData['status'] ?? 'Unknown';
    String chapters = mangaData['chapters'] != null ? mangaData['chapters'].toString() : '?';
    String url = mangaData['url'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar dengan Gambar Background Besar
          SliverAppBar(
            expandedHeight: 400.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(imageUrl, fit: BoxFit.cover),
                  // Gradient agar teks terbaca
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.9), Colors.black],
                        stops: const [0.5, 0.8, 1.0]
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Konten Detail
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(title, style: const TextStyle(fontFamily: "Orbitron", fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  
                  // Info Bar (Status, Chapter)
                  Row(
                    children: [
                      _buildInfoBadge(Icons.timelapse, status, Colors.blueAccent),
                      const SizedBox(width: 10),
                      _buildInfoBadge(Icons.book, "$chapters Ch", Colors.orangeAccent),
                      const SizedBox(width: 10),
                      _buildInfoBadge(Icons.star, "${mangaData['score'] ?? 'N/A'}", Colors.yellowAccent),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Divider Merah
                  const Divider(color: Color(0xFFB00000), thickness: 1),
                  const SizedBox(height: 15),

                  // Synopsis Header
                  const Row(
                    children: [
                      Icon(Icons.description, color: Color(0xFFB00000), size: 18),
                      SizedBox(width: 8),
                      Text("Story / Synopsis", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Orbitron", fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Synopsis Text
                  Text(
                    synopsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6, fontFamily: "ShareTechMono"),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 40),

                  // Tombol Action (Buka Browser untuk baca full karena copyright)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB00000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 10,
                        shadowColor: Colors.red.withOpacity(0.5)
                      ),
                      onPressed: () async {
                         final uri = Uri.parse(url);
                         if (await canLaunchUrl(uri)) {
                           await launchUrl(uri, mode: LaunchMode.externalApplication);
                         } else {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch url")));
                         }
                      },
                      icon: const Icon(Icons.open_in_browser, color: Colors.white),
                      label: const Text("Read More & Details on Web", style: TextStyle(color: Colors.white, fontFamily: "Orbitron", fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
