import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class _C {
  static const bg      = Color(0xFF000000);
  static const s1      = Color(0xFF030D1F);
  static const s2      = Color(0xFF141414);
  static const border  = Color(0xFF1E1E1E);
  static const accent  = Color(0xFF1565C0);
  static const accentL = Color(0xFF42A5F5);
  static const green   = Color(0xFF4CAF50);
  static const red     = Color(0xFF2979FF);
  static const textP   = Color(0xFFFFFFFF);
  static const textS   = Color(0xFFCCCCCC);
  static const textM   = Color(0xFF2A2A2A);
  static const white   = Color(0xFFFFFFFF);
}

class _StarBg extends StatefulWidget {
  final Widget child;
  const _StarBg({required this.child});
  @override State<_StarBg> createState() => _StarBgState();
}
class _StarBgState extends State<_StarBg> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _r = Random();
  late List<List<double>> _dots;
  @override void initState() {
    super.initState();
    _dots = List.generate(55, (_) => [_r.nextDouble(), _r.nextDouble(), _r.nextDouble() * 1.8 + 0.3, _r.nextDouble() * pi * 2, _r.nextDouble() * 0.7 + 0.2]);
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, ch) => CustomPaint(painter: _StarPainter(_dots, _c.value), child: ch),
    child: widget.child,
  );
}
class _StarPainter extends CustomPainter {
  final List<List<double>> d; final double t;
  _StarPainter(this.d, this.t);
  @override void paint(Canvas c, Size s) {
    final p = Paint();
    for (final dot in d) {
      final a = (sin(t * pi * 2 * dot[4] + dot[3]) * 0.5 + 0.5);
      p.color = _C.accentL.withOpacity(a * 0.35);
      c.drawCircle(Offset(dot[0] * s.width, dot[1] * s.height), dot[2], p);
    }
  }
  @override bool shouldRepaint(_StarPainter _) => true;
}

// YouTube thumbnail helper - pakai video ID biar gambar pasti muncul
String _ytThumb(String videoId) => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
String _ytUrl(String videoId) => 'https://www.youtube.com/watch?v=$videoId';
String _ytSearch(String q) => 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}';

final List<Map<String, dynamic>> _list = [
  // ── DONGHUA / ANIMASI ──
  { 'title': 'Battle Through the Heavens', 'genre': 'Action · Cultivation', 'ep': '40+', 'tag': 'Donghua',
    'img': _ytThumb('JGjfTZMaXcU'), 'url': _ytSearch('battle through the heavens donghua episode 1') },
  { 'title': 'Soul Land (Douluo Dalu)', 'genre': 'Adventure · Fantasy', 'ep': '200+', 'tag': 'Donghua',
    'img': _ytThumb('NMPVmQKLzv4'), 'url': _ytSearch('douluo dalu soul land episode 1 english sub') },
  { 'title': "The King's Avatar",'genre':'E-Sports · Action','ep':'24','tag':'Donghua',
    'img': _ytThumb('RMBMkOL7ofU'), 'url': _ytSearch('the kings avatar donghua full episode') },
  { 'title': 'Martial Universe', 'genre': 'Martial Arts · Fantasy', 'ep': '40+', 'tag': 'Donghua',
    'img': _ytThumb('s9YrjnQDVHc'), 'url': _ytSearch('martial universe donghua episode 1') },
  { 'title': 'Perfect World', 'genre': 'Cultivation · Fantasy', 'ep': '50+', 'tag': 'Donghua',
    'img': _ytThumb('EQ5D3gBNzH8'), 'url': _ytSearch('perfect world donghua full episode') },
  { 'title': "Heaven Official's Blessing",'genre':'Romance · Fantasy','ep':'24','tag':'Donghua',
    'img': _ytThumb('5O0m7YfVnXk'), 'url': _ytSearch('heaven officials blessing tgcf episode 1') },
  { 'title': 'Stellar Transformations', 'genre': 'Sci-Fi · Cultivation', 'ep': '44+', 'tag': 'Donghua',
    'img': _ytThumb('VcaF7ykfGDw'), 'url': _ytSearch('stellar transformations donghua episode 1') },
  { 'title': 'A Will Eternal', 'genre': 'Comedy · Cultivation', 'ep': '40+', 'tag': 'Donghua',
    'img': _ytThumb('fKuHBXrn2ac'), 'url': _ytSearch('a will eternal donghua full') },
  { 'title': 'Swallowed Star', 'genre': 'Sci-Fi · Action', 'ep': '100+', 'tag': 'Donghua',
    'img': _ytThumb('h7JfR_l3RRE'), 'url': _ytSearch('swallowed star donghua episode 1') },
  { 'title': 'The Daily Life of the Immortal King', 'genre': 'Comedy · Cultivation', 'ep': '50+', 'tag': 'Donghua',
    'img': _ytThumb('gM5PXa8T5oA'), 'url': _ytSearch('daily life immortal king donghua full') },
  // ── DRAMA CHINA ──
  { 'title': 'The Untamed (陈情令)', 'genre': 'Romance · Wuxia', 'ep': '50', 'tag': 'Drama',
    'img': _ytThumb('E6mwJIxbPEI'), 'url': _ytSearch('the untamed chen qing ling full drama english sub') },
  { 'title': 'Word of Honor (山河令)', 'genre': 'Action · Bromance', 'ep': '36', 'tag': 'Drama',
    'img': _ytThumb('1x9yMPrYcXk'), 'url': _ytSearch('word of honor shan he ling drama full') },
  { 'title': 'Love Between Fairy and Devil', 'genre': 'Romance · Fantasy', 'ep': '36', 'tag': 'Drama',
    'img': _ytThumb('dVaqshAiYjM'), 'url': _ytSearch('love between fairy and devil full drama') },
  { 'title': 'Eternal Love (三生三世)', 'genre': 'Romance · Xianxia', 'ep': '58', 'tag': 'Drama',
    'img': _ytThumb('aNgkb3DHPNA'), 'url': _ytSearch('eternal love ten miles peach blossoms drama full') },
  { 'title': 'Ashes of Love (香蜜沉沉烬如霜)', 'genre': 'Romance · Fantasy', 'ep': '63', 'tag': 'Drama',
    'img': _ytThumb('x7nOJMHdFk0'), 'url': _ytSearch('ashes of love chinese drama full episode') },
  { 'title': 'Nirvana in Fire (琅琊榜)', 'genre': 'Political · Wuxia', 'ep': '54', 'tag': 'Drama',
    'img': _ytThumb('W1MeWMfq_wY'), 'url': _ytSearch('nirvana in fire lang ya bang full drama') },
  { 'title': 'Lost You Forever (长相思)', 'genre': 'Romance · Xianxia', 'ep': '39', 'tag': 'Drama',
    'img': _ytThumb('b8Jv0HwfJHk'), 'url': _ytSearch('lost you forever chang xiang si drama full') },
  { 'title': 'Go Go Squid! (亲爱的，热爱的)', 'genre': 'Romance · E-Sports', 'ep': '41', 'tag': 'Drama',
    'img': _ytThumb('4s6TYZ79YoI'), 'url': _ytSearch('go go squid chinese drama full episode') },
  { 'title': 'You Are My Glory (你是我的荣耀)', 'genre': 'Romance · Modern', 'ep': '32', 'tag': 'Drama',
    'img': _ytThumb('XarRwGrHkY4'), 'url': _ytSearch('you are my glory chinese drama full') },
  { 'title': 'The Story of Ming Lan (知否)', 'genre': 'Historical · Romance', 'ep': '73', 'tag': 'Drama',
    'img': _ytThumb('zJNAjYj7ZJo'), 'url': _ytSearch('story of minglan chinese drama full') },
];

final _tags = ['Semua', 'Donghua', 'Drama'];

class DracinPage extends StatefulWidget {
  const DracinPage({super.key});
  @override State<DracinPage> createState() => _DracinPageState();
}

class _DracinPageState extends State<DracinPage> {
  String _q = '';
  String _tag = 'Semua';
  final _ctrl = TextEditingController();

  List<Map<String,dynamic>> get _filtered => _list
      .where((d) {
        final matchQ = _q.isEmpty || (d['title'] as String? ?? '').toLowerCase().contains(_q.toLowerCase()) || (d['genre'] as String? ??'').toLowerCase().contains(_q.toLowerCase());
        final matchT = _tag == 'Semua' || d['tag'] == _tag;
        return matchQ && matchT;
      }).toList();

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    body: _StarBg(child: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16,14,16,0), child: Row(children: [
        Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _C.s2, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
          child: Icon(Icons.play_circle_rounded, color: _C.accentL, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DRACIN', style: TextStyle(color: _C.textP, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 4)),
          Text('Donghua & Drama China', style: TextStyle(color: _C.textS, fontSize: 11)),
        ]),
        const Spacer(),
        Text('${_filtered.length} judul', style: TextStyle(color: _C.textM, fontSize: 10)),
      ])),
      const SizedBox(height: 12),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(
        decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
        child: TextField(controller: _ctrl, onChanged: (v) => setState(() => _q = v),
          style: TextStyle(color: _C.textP, fontSize: 13),
          decoration: InputDecoration(hintText: 'Cari judul atau genre...', hintStyle: TextStyle(color: _C.textM),
            prefixIcon: Icon(Icons.search_rounded, color: _C.textS, size: 18),
            border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12))),
      )),
      const SizedBox(height: 10),
      SizedBox(height: 34, child: ListView.separated(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tags.length, separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final t = _tags[i]; final active = t == _tag;
          return GestureDetector(onTap: () => setState(() => _tag = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _C.accent : _C.s1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _C.accentL : _C.border)),
              child: Text(t, style: TextStyle(color: active ? _C.white : _C.textS, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal))));
        })),
      const SizedBox(height: 10),
      Expanded(child: _filtered.isEmpty
        ? Center(child: Text('Tidak ditemukan', style: TextStyle(color: _C.textM)))
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(16,0,16,100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.57),
            itemCount: _filtered.length,
            itemBuilder: (ctx, i) {
              final d = _filtered[i];
              return GestureDetector(
                onTap: () async {
                  final u = Uri.parse(d['url'] as String);
                  if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
                },
                child: Container(
                  decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Stack(fit: StackFit.expand, children: [
                      Image.network(
                        d['img'] as String,
                        fit: BoxFit.cover,
                        // Retry dengan headers berbeda untuk bypass hotlink protection
                        headers: const {'Referer': 'https://www.youtube.com/'},
                        loadingBuilder: (_, child, progress) => progress == null ? child
                            : Container(
                                color: const Color(0xFF2E0022),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF2979FF),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF2E0022),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.live_tv_rounded, color: Color(0xFF2979FF), size: 32),
                            const SizedBox(height: 6),
                          ]),
                        ),
                      ),
                      // Dark overlay bottom
                      Positioned(bottom: 0, left: 0, right: 0, child: Container(height: 60,
                        decoration: BoxDecoration(gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xFF2A0020)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                      // YouTube badge
                      Positioned(top: 8, left: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(5)),
                        child: const Row(children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text('YT', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ]))),
                      // EP badge
                      Positioned(top: 8, right: 8, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: _C.accent.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                        child: Text('EP ${d["ep"]}', style: TextStyle(color: _C.white, fontSize: 9, fontWeight: FontWeight.bold)))),
                      // Play button center
                      Center(child: Container(padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Color(0x541A0010), shape: BoxShape.circle),
                        child: Icon(Icons.play_arrow_rounded, color: _C.white, size: 28))),
                    ])),
                    Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] as String, style: TextStyle(color: _C.textP, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: Color(0x261A0010), borderRadius: BorderRadius.circular(4)),
                          child: Text(d['tag'] as String, style: TextStyle(
                            color: (d['tag'] as String) == 'Drama' ? Colors.pinkAccent : _C.accentL, fontSize: 8, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 4),
                        Expanded(child: Text(d['genre'] as String, style: TextStyle(color: _C.textS, fontSize: 9), overflow: TextOverflow.ellipsis)),
                      ]),
                    ])),
                  ]),
                ),
              );
            }),
      ),
    ]))),
  );
}
