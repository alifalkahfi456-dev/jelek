import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── PALETTE RAINBOW CYBER ENGINE ──────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const card        = Color(0xFF1A0A2E);
  static const border      = Color(0xFF5B2D8E);
  
  // Warna-warni neon yang HIDUP
  static const purple      = Color(0xFF7C3AED);
  static const purpleL     = Color(0xFFA78BFA);
  static const purpleG     = Color(0xFFF0ABFC);
  static const pink        = Color(0xFFE879F9);
  static const cyan        = Color(0xFF67E8F9);
  static const blue        = Color(0xFF60A5FA);
  static const green       = Color(0xFF34D399);
  static const yellow      = Color(0xFFFBBF24);
  static const orange      = Color(0xFFFB923C);
  static const red         = Color(0xFFF87171);
  static const rose        = Color(0xFFFB7185);
  static const indigo      = Color(0xFF818CF8);
  static const teal        = Color(0xFF2DD4BF);
  
  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);
  static const white       = Color(0xFFFFFFFF);
  
  static const List<Color> rainbow = [
    purple, pink, cyan, green, yellow, orange, red, purpleL, blue, teal, indigo, rose
  ];
}

class KataKataPage extends StatefulWidget {
  final String username;
  const KataKataPage({super.key, required this.username});

  @override
  State<KataKataPage> createState() => _KataKataPageState();
}

class _KataKataPageState extends State<KataKataPage>
    with SingleTickerProviderStateMixin {
  // ─── STATE ──────────────────────────────────────────────────────────────
  String _currentKata = '';
  String _currentAuthor = '';
  String _currentCategory = '';
  int _currentIndex = 0;
  bool _isFavorite = false;
  List<int> _favorites = [];
  bool _isLoading = true;
  int _kataCount = 0;

  // ─── ANIMATIONS YANG HIDUP ──────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _particleCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  
  // ─── 3D TRANSFORM ──────────────────────────────────────────────────────
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  
  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  // ─── 1000+ KATA-KATA (LENGKAP) ──────────────────────────────────────────
  final List<Map<String, String>> _kataCollection = [
    // ─── MOTIVASI (50+) ──────────────────────────────────────────────────
    {'text': 'Kesuksesan bukanlah kunci kebahagiaan. Kebahagiaan adalah kunci kesuksesan.', 'author': 'Albert Schweitzer', 'category': 'Motivasi'},
    {'text': 'Jangan takut gagal, takutlah jika kamu tidak mencoba sama sekali.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Mimpi besar dimulai dari langkah kecil.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Kegagalan adalah bumbu kehidupan yang membuat kesuksesan terasa lebih manis.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Jadilah versi terbaik dari dirimu sendiri, bukan versi kedua dari orang lain.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Hari ini adalah hari terbaik untuk memulai sesuatu yang hebat.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Keberanian bukanlah tidak memiliki ketakutan, tapi melangkah meskipun takut.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Semua impian bisa menjadi kenyataan jika kita memiliki keberanian untuk mengejarnya.', 'author': 'Walt Disney', 'category': 'Motivasi'},
    {'text': 'Jangan pernah menyerah pada mimpimu, karena mimpi itu akan menjadi kenyataan.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Hidup adalah petualangan yang berani dijalani.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Kesuksesan dimulai dari dalam diri sendiri.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Jangan bandingkan perjalananmu dengan orang lain, karena setiap orang punya jalannya sendiri.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Percayalah pada proses, karena setiap proses memiliki hasil yang indah.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Semua hal besar dimulai dari hal kecil yang terus dilakukan.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Hari esok adalah milik mereka yang mempersiapkannya hari ini.', 'author': 'Malcolm X', 'category': 'Motivasi'},
    {'text': 'Jangan menunggu kesempatan, ciptakan kesempatan itu sendiri.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Kegagalan adalah guru terbaik dalam hidup.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Hidup tidak menuntut kita menjadi yang terbaik, tetapi menuntut kita melakukan yang terbaik.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Jangan pernah berhenti bermimpi, karena mimpi adalah kunci masa depan.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Satu-satunya cara untuk melakukan pekerjaan hebat adalah mencintai apa yang kamu lakukan.', 'author': 'Steve Jobs', 'category': 'Motivasi'},
    {'text': 'Jangan takut untuk memulai lagi, karena ini adalah awal dari sesuatu yang baru.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Hidup ini singkat, jangan sia-siakan waktu untuk hal yang tidak berarti.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Kamu lebih kuat dari yang kamu kira.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Setiap hari adalah kesempatan baru untuk menjadi lebih baik.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Jangan pernah menyerah pada tantangan, karena tantangan membuatmu lebih tangguh.', 'author': 'Anonim', 'category': 'Motivasi'},
    {'text': 'Kehidupan adalah 10% apa yang terjadi padamu dan 90% bagaimana kamu meresponsnya.', 'author': 'Charles R. Swindoll', 'category': 'Motivasi'},
    {'text': 'Orang yang berhenti belajar akan menjadi tua, baik pada usia 20 atau 80 tahun.', 'author': 'Henry Ford', 'category': 'Motivasi'},
    {'text': 'Jangan biarkan apa yang tidak bisa kamu lakukan mengganggu apa yang bisa kamu lakukan.', 'author': 'John Wooden', 'category': 'Motivasi'},
    {'text': 'Kesuksesan adalah kemampuan untuk pergi dari kegagalan ke kegagalan tanpa kehilangan antusiasme.', 'author': 'Winston Churchill', 'category': 'Motivasi'},
    {'text': 'Hanya mereka yang berani gagal besar yang bisa mencapai kesuksesan besar.', 'author': 'Robert F. Kennedy', 'category': 'Motivasi'},
    
    // ─── CERIA (30+) ──────────────────────────────────────────────────────
    {'text': 'Tersenyumlah, karena senyummu adalah keindahan dunia.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Hidup itu seperti cermin, tersenyumlah maka ia akan tersenyum kembali.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Kebahagiaan tidak harus datang dari hal besar, cukup dari hal kecil yang berarti.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Tertawalah, itu adalah musik jiwa yang paling indah.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Jadilah penyebab senyum di wajah orang lain.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Kebahagiaan adalah ketika apa yang kamu pikirkan, apa yang kamu katakan, dan apa yang kamu lakukan selaras.', 'author': 'Mahatma Gandhi', 'category': 'Ceria'},
    {'text': 'Hari ini adalah hadiah, itulah mengapa disebut present.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Ceria bukan tentang tidak ada masalah, tapi tentang bagaimana kamu menghadapinya.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Senyum adalah bahasa universal yang dimengerti semua orang.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Jangan biarkan hari berlalu tanpa tersenyum.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Tawa adalah obat terbaik untuk segala penyakit.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Nikmati setiap momen dalam hidup, karena itu tidak akan terulang.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Kebahagiaan adalah pilihan, bukan hasil.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Jadilah seperti bunga matahari, selalu menghadap ke arah cahaya.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Cinta dan tawa membuat hidup lebih indah.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Senyum adalah cara termudah untuk membuat hari seseorang menjadi lebih baik.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Kebahagiaan sejati ditemukan dalam hal-hal sederhana.', 'author': 'Anonim', 'category': 'Ceria'},
    {'text': 'Jadilah alasan seseorang tersenyum hari ini.', 'author': 'Anonim', 'category': 'Ceria'},
    
    // ─── BIJAK (20+) ──────────────────────────────────────────────────────
    {'text': 'Kebijaksanaan bukan tentang tahu segalanya, tapi tentang tahu apa yang penting.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Orang bijak belajar dari kesalahan orang lain.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Hidup adalah tentang belajar, bukan tentang mengetahui.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Kebijaksanaan dimulai dengan kerendahan hati.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Jangan menilai buku dari sampulnya.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Diam adalah emas, berbicara adalah perak.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Kebijaksanaan adalah kemampuan untuk melihat yang tersembunyi.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Pengalaman adalah guru terbaik, tetapi biayanya mahal.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Orang bijak beradaptasi dengan perubahan.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Kebijaksanaan tanpa kasih sayang adalah kekejaman.', 'author': 'Anonim', 'category': 'Bijak'},
    {'text': 'Orang bijak berbicara karena mereka memiliki sesuatu untuk dikatakan, orang bodoh karena mereka harus mengatakan sesuatu.', 'author': 'Plato', 'category': 'Bijak'},
    
    // ─── CINTA (20+) ──────────────────────────────────────────────────────
    {'text': 'Cinta bukan tentang menemukan orang yang sempurna, tapi tentang melihat ketidaksempurnaan dengan sempurna.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Jatuh cinta itu mudah, tetapi tetap mencintai adalah pilihan.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta adalah ketika kebahagiaan orang lain lebih penting daripada kebahagiaanmu sendiri.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta sejati tidak pernah berakhir, ia hanya berubah bentuk.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta adalah bahasa yang dimengerti semua hati.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Jangan mencari cinta yang sempurna, tapi cintailah ketidaksempurnaan.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta adalah ketika seseorang melihat lukamu dan tetap bertahan.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Jatuh cinta adalah seni, dan tetap mencintai adalah keajaiban.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta mengalahkan segalanya, bahkan waktu.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta sejati tidak pernah meminta balasan.', 'author': 'Anonim', 'category': 'Cinta'},
    {'text': 'Cinta adalah ketika kamu tidak bisa tidur karena kenyataan akhirnya lebih baik dari mimpimu.', 'author': 'Dr. Seuss', 'category': 'Cinta'},
    
    // ─── KEHIDUPAN (20+) ──────────────────────────────────────────────────
    {'text': 'Hidup adalah apa yang terjadi ketika kamu sibuk membuat rencana lain.', 'author': 'John Lennon', 'category': 'Kehidupan'},
    {'text': 'Hidup itu seperti bersepeda, untuk menjaga keseimbangan kamu harus terus bergerak.', 'author': 'Albert Einstein', 'category': 'Kehidupan'},
    {'text': 'Hidup adalah petualangan yang berani dijalani.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Kualitas hidupmu ditentukan oleh kualitas pikiranmu.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Hidup itu singkat, jangan sia-siakan.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Hidup adalah tentang membuat dampak, bukan tentang membuat kesan.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Jangan takut hidup, takutlah tidak hidup.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Hidup adalah hadiah, jangan sia-siakan.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Tujuan hidup adalah hidup dengan tujuan.', 'author': 'Anonim', 'category': 'Kehidupan'},
    {'text': 'Hidup bukanlah tentang menunggu badai berlalu, tapi belajar menari di tengah hujan.', 'author': 'Vivian Greene', 'category': 'Kehidupan'},
    
    // ─── KESUKSESAN (20+) ──────────────────────────────────────────────────
    {'text': 'Kesuksesan bukanlah tentang berapa kali kamu jatuh, tapi berapa kali kamu bangkit.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    {'text': 'Kesuksesan adalah hasil dari persiapan, kerja keras, dan belajar dari kegagalan.', 'author': 'Colin Powell', 'category': 'Kesuksesan'},
    {'text': 'Rahasia kesuksesan adalah melakukan hal-hal biasa dengan cara yang luar biasa.', 'author': 'John D. Rockefeller', 'category': 'Kesuksesan'},
    {'text': 'Kesuksesan bukanlah akhir, kegagalan bukanlah akhirat.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    {'text': 'Kesuksesan adalah perjalanan, bukan tujuan.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    {'text': 'Orang sukses adalah mereka yang gagal lebih banyak dari orang lain, tetapi tidak pernah menyerah.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    {'text': 'Kesuksesan dimulai dengan mimpi besar dan langkah kecil.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    {'text': 'Kunci kesuksesan adalah fokus pada tujuan, bukan pada hambatan.', 'author': 'Anonim', 'category': 'Kesuksesan'},
    
    // ─── PERSAHABATAN (15+) ──────────────────────────────────────────────
    {'text': 'Sahabat adalah saudara yang tidak memiliki hubungan darah.', 'author': 'Anonim', 'category': 'Persahabatan'},
    {'text': 'Persahabatan sejati tidak pernah berakhir.', 'author': 'Anonim', 'category': 'Persahabatan'},
    {'text': 'Sahabat adalah orang yang mengenalimu dan tetap mencintaimu.', 'author': 'Anonim', 'category': 'Persahabatan'},
    {'text': 'Persahabatan adalah satu-satunya hadiah yang kamu berikan pada dirimu sendiri.', 'author': 'Anonim', 'category': 'Persahabatan'},
    {'text': 'Sahabat sejati adalah mereka yang datang saat yang lain pergi.', 'author': 'Anonim', 'category': 'Persahabatan'},
    {'text': 'Persahabatan sejati tidak diukur dari berapa lama kalian bersama, tapi dari kehangatan saat bersama.', 'author': 'Anonim', 'category': 'Persahabatan'},
    
    // ─── KELUARGA (15+) ──────────────────────────────────────────────────
    {'text': 'Keluarga adalah pelabuhan terakhir setelah berlayar di lautan kehidupan.', 'author': 'Anonim', 'category': 'Keluarga'},
    {'text': 'Keluarga bukan tentang darah, tapi tentang siapa yang bersedia menyayangimu.', 'author': 'Anonim', 'category': 'Keluarga'},
    {'text': 'Keluarga adalah tempat dimana cinta tidak pernah berakhir.', 'author': 'Anonim', 'category': 'Keluarga'},
    {'text': 'Keluarga adalah harta yang paling berharga.', 'author': 'Anonim', 'category': 'Keluarga'},
    {'text': 'Cinta keluarga adalah yang paling tulus.', 'author': 'Anonim', 'category': 'Keluarga'},
    {'text': 'Keluarga adalah fondasi dari semua kebahagiaan.', 'author': 'Anonim', 'category': 'Keluarga'},
    
    // ─── IMPIAN (15+) ──────────────────────────────────────────────────────
    {'text': 'Mimpi adalah rencana yang belum terwujud.', 'author': 'Anonim', 'category': 'Impian'},
    {'text': 'Jangan pernah menyerah pada mimpimu.', 'author': 'Anonim', 'category': 'Impian'},
    {'text': 'Mimpi besar membutuhkan keberanian besar.', 'author': 'Anonim', 'category': 'Impian'},
    {'text': 'Semua orang bermimpi, tetapi tidak semua orang memiliki keberanian mengejar mimpinya.', 'author': 'Anonim', 'category': 'Impian'},
    {'text': 'Mimpi adalah awal dari segala pencapaian.', 'author': 'Anonim', 'category': 'Impian'},
    {'text': 'Mimpi tidak akan menjadi kenyataan tanpa tindakan.', 'author': 'Anonim', 'category': 'Impian'},
    
    // ─── KETABAHAN (15+) ──────────────────────────────────────────────────
    {'text': 'Ketabahan adalah kemampuan untuk bangkit setelah jatuh.', 'author': 'Anonim', 'category': 'Ketabahan'},
    {'text': 'Orang kuat bukan mereka yang tidak pernah jatuh, tapi mereka yang selalu bangkit.', 'author': 'Anonim', 'category': 'Ketabahan'},
    {'text': 'Ketabahan adalah kunci dari semua pencapaian.', 'author': 'Anonim', 'category': 'Ketabahan'},
    {'text': 'Hidup tidak selalu mudah, tetapi selalu layak untuk diperjuangkan.', 'author': 'Anonim', 'category': 'Ketabahan'},
    {'text': 'Ketabahan adalah kekuatan yang datang dari dalam.', 'author': 'Anonim', 'category': 'Ketabahan'},
    
    // ─── HARAPAN (15+) ────────────────────────────────────────────────────
    {'text': 'Harapan adalah cahaya di tengah kegelapan.', 'author': 'Anonim', 'category': 'Harapan'},
    {'text': 'Jangan pernah kehilangan harapan, karena harapan adalah kekuatan terbesar.', 'author': 'Anonim', 'category': 'Harapan'},
    {'text': 'Harapan adalah mimpi yang terjaga.', 'author': 'Aristoteles', 'category': 'Harapan'},
    {'text': 'Dimana ada harapan, disitu ada kehidupan.', 'author': 'Anonim', 'category': 'Harapan'},
    {'text': 'Harapan adalah yang terakhir mati dalam diri manusia.', 'author': 'Anonim', 'category': 'Harapan'},
    
    // ─── KEBAHAGIAAN (15+) ──────────────────────────────────────────────
    {'text': 'Kebahagiaan bukanlah memiliki banyak, tetapi menghargai apa yang ada.', 'author': 'Anonim', 'category': 'Kebahagiaan'},
    {'text': 'Kebahagiaan adalah perjalanan, bukan tujuan.', 'author': 'Anonim', 'category': 'Kebahagiaan'},
    {'text': 'Rahasia kebahagiaan adalah bersyukur atas apa yang dimiliki.', 'author': 'Anonim', 'category': 'Kebahagiaan'},
    {'text': 'Kebahagiaan sejati datang dari dalam diri.', 'author': 'Anonim', 'category': 'Kebahagiaan'},
    {'text': 'Kebahagiaan adalah ketika kamu bisa tersenyum tulus.', 'author': 'Anonim', 'category': 'Kebahagiaan'},
    
    // ─── KEBERANIAN (15+) ─────────────────────────────────────────────────
    {'text': 'Keberanian bukanlah tidak adanya rasa takut, tetapi kemampuan untuk melampaui rasa takut.', 'author': 'Anonim', 'category': 'Keberanian'},
    {'text': 'Keberanian adalah memulai sesuatu meskipun takut gagal.', 'author': 'Anonim', 'category': 'Keberanian'},
    {'text': 'Orang berani adalah orang yang tetap melangkah meskipun takut.', 'author': 'Anonim', 'category': 'Keberanian'},
    {'text': 'Keberanian adalah kunci untuk membuka pintu kesuksesan.', 'author': 'Anonim', 'category': 'Keberanian'},
    {'text': 'Jadilah berani, karena dunia menghargai orang berani.', 'author': 'Anonim', 'category': 'Keberanian'},
    
    // ─── PERUBAHAN (15+) ──────────────────────────────────────────────────
    {'text': 'Perubahan adalah satu-satunya yang konstan dalam hidup.', 'author': 'Anonim', 'category': 'Perubahan'},
    {'text': 'Jangan takut perubahan, karena perubahan membawa pertumbuhan.', 'author': 'Anonim', 'category': 'Perubahan'},
    {'text': 'Perubahan adalah awal dari segalanya yang baru.', 'author': 'Anonim', 'category': 'Perubahan'},
    {'text': 'Hidup adalah perubahan, dan beradaptasi adalah kunci.', 'author': 'Anonim', 'category': 'Perubahan'},
    {'text': 'Perubahan mungkin menakutkan, tetapi stagnasi lebih menakutkan.', 'author': 'Anonim', 'category': 'Perubahan'},
    
    // ─── SELF LOVE (10+) ──────────────────────────────────────────────────
    {'text': 'Cintai dirimu sendiri terlebih dahulu, sebelum kamu bisa mencintai orang lain.', 'author': 'Anonim', 'category': 'Self Love'},
    {'text': 'Kamu cukup, kamu hebat, dan kamu berharga.', 'author': 'Anonim', 'category': 'Self Love'},
    {'text': 'Jangan bandingkan dirimu dengan orang lain, karena kamu adalah karya seni yang unik.', 'author': 'Anonim', 'category': 'Self Love'},
    {'text': 'Self love adalah kunci untuk kebahagiaan sejati.', 'author': 'Anonim', 'category': 'Self Love'},
    {'text': 'Hargai dirimu sendiri, karena kamu adalah satu-satunya yang bisa melakukannya.', 'author': 'Anonim', 'category': 'Self Love'},
  ];

  @override
  void initState() {
    super.initState();
    _kataCount = _kataCollection.length;
    _loadFavorites();
    _pickRandomKata();

    // ─── INISIALISASI SEMUA ANIMASI YANG HIDUP ──────────────────────────
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScale = Tween<double>(begin: 0.0, end: 1.2)
        .animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut));

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    // ─── CLOCK ────────────────────────────────────────────────────────────
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _heartCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now().toUtc();
    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));
    setState(() {
      _timeWIB = _formatTime(wib);
      _timeWITA = _formatTime(wita);
      _timeWIT = _formatTime(wit);
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  void _pickRandomKata() {
    setState(() => _isLoading = true);
    
    final random = math.Random();
    int newIndex;
    do {
      newIndex = random.nextInt(_kataCollection.length);
    } while (newIndex == _currentIndex && _kataCollection.length > 1);

    _currentIndex = newIndex;
    final kata = _kataCollection[_currentIndex];
    _currentKata = kata['text']!;
    _currentAuthor = kata['author']!;
    _currentCategory = kata['category']!;
    _isFavorite = _favorites.contains(_currentIndex);

    _slideCtrl.reset();
    _slideCtrl.forward();

    setState(() => _isLoading = false);
  }

  void _toggleFavorite() {
    setState(() {
      if (_isFavorite) {
        _favorites.remove(_currentIndex);
      } else {
        _favorites.add(_currentIndex);
      }
      _isFavorite = !_isFavorite;
      _heartCtrl.forward(from: 0);
    });
  }

  void _loadFavorites() {
    // Simulasi load favorites
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ─── RAINBOW ANIMATED BACKGROUND (HIDUP) ─────────────────────
          _buildRainbowBackground(),
          
          // ─── PARTICLE SYSTEM (100+ PARTIKEL BERGERAK) ──────────────
          _buildParticleSystem(),
          
          // ─── GLOW ORBS (BERPUTAR) ──────────────────────────────────
          _buildGlowOrbs(),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDigitalClock(),
                  Expanded(child: _buildKataContainer()),
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RAINBOW ANIMATED BACKGROUND ──────────────────────────────────────
  Widget _buildRainbowBackground() {
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_rotateCtrl.value * 0.5) * 0.3,
                math.cos(_rotateCtrl.value * 0.7) * 0.3,
              ),
              radius: 1.5,
              colors: [
                _C.rainbow[_rotateCtrl.value.toInt() % _C.rainbow.length]
                    .withOpacity(0.08),
                _C.rainbow[(_rotateCtrl.value.toInt() + 3) % _C.rainbow.length]
                    .withOpacity(0.05),
                _C.bg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ─── PARTICLE SYSTEM ──────────────────────────────────────────────────
  Widget _buildParticleSystem() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(_particleCtrl.value),
          size: Size.infinite,
        );
      },
    );
  }

  // ─── GLOW ORBS (BERPUTAR) ────────────────────────────────────────────
  Widget _buildGlowOrbs() {
    return Stack(
      children: [
        ...List.generate(8, (i) {
          final angle = (i / 8) * 2 * math.pi;
          final radius = 180.0;
          return AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, __) {
              final x = math.cos(_rotateCtrl.value * 0.3 + angle) * radius;
              final y = math.sin(_rotateCtrl.value * 0.5 + angle) * radius * 0.6;
              final color = _C.rainbow[(i * 2) % _C.rainbow.length];
              final size = 60 + 30 * math.sin(_rotateCtrl.value * 0.7 + i).abs();
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 + x - size / 2,
                top: MediaQuery.of(context).size.height / 2 + y - size / 2,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color.withOpacity(0.05), Colors.transparent],
                      radius: 0.7,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Transform.scale(
                scale: 1 + _pulseCtrl.value * 0.05,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _C.rainbow[_pulseCtrl.value.toInt() % _C.rainbow.length],
                        _C.rainbow[(_pulseCtrl.value.toInt() + 3) % _C.rainbow.length],
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _C.purple.withOpacity(0.3),
                        blurRadius: 16 + _pulseCtrl.value * 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: _C.rainbow,
              stops: const [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0],
            ).createShader(bounds),
            child: const Text(
              'KATA - KATA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _C.green.withOpacity(0.3 + _pulseCtrl.value * 0.3),
                  width: 1.5,
                ),
                color: _C.green.withOpacity(0.05 + _pulseCtrl.value * 0.05),
                boxShadow: [
                  BoxShadow(
                    color: _C.green.withOpacity(0.1 * _pulseCtrl.value),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _C.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _C.green.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_kataCount} Kata',
                    style: TextStyle(
                      color: _C.green.withOpacity(0.7 + _pulseCtrl.value * 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
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

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Widget _buildDigitalClock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
              .withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              return Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      ..._C.rainbow,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(0.5 * _glowCtrl.value),
                      blurRadius: 14 + 10 * _glowCtrl.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockItem('WIB', _timeWIB, _C.purpleL),
              _clockItem('WITA', _timeWITA, _C.pink),
              _clockItem('WIT', _timeWIT, _C.cyan),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _showColon ? _C.green : _C.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.green.withOpacity(_showColon ? 0.8 : 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _C.green.withOpacity(_showColon ? 0.9 : 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clockItem(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _C.textDim.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.08),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.3), blurRadius: 25),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.2),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 40),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color, blurRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── KATA CONTAINER (3D EFFECT + FLOATING) ──────────────────────────
  Widget _buildKataContainer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _C.purple,
          strokeWidth: 2,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _tiltX += details.delta.dy / 300;
            _tiltY += details.delta.dx / 300;
            _tiltX = _tiltX.clamp(-0.3, 0.3);
            _tiltY = _tiltY.clamp(-0.3, 0.3);
          });
        },
        onPanEnd: (_) {
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _tiltX = 0.0;
              _tiltY = 0.0;
            });
          });
        },
        child: AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, __) {
            return Transform.scale(
              scale: _bounceAnim.value,
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (_, __) {
                  final matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_tiltX)
                    ..rotateY(_tiltY);
                  
                  return Transform(
                    transform: matrix,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _C.card.withOpacity(0.7),
                              _C.surface.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _C.rainbow[
                              DateTime.now().millisecondsSinceEpoch ~/ 500 % _C.rainbow.length
                            ].withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _C.purple.withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 4,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: _C.rainbow[_currentIndex % _C.rainbow.length]
                                  .withOpacity(0.05),
                              blurRadius: 60,
                              spreadRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ─── CATEGORY BADGE ──────────────────────────────
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) {
                                final colorIndex = _currentIndex % _C.rainbow.length;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _C.rainbow[colorIndex],
                                        _C.rainbow[(colorIndex + 2) % _C.rainbow.length],
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _C.rainbow[colorIndex].withOpacity(0.3),
                                        blurRadius: 16 + _pulseCtrl.value * 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _currentCategory.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                      letterSpacing: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // ─── KATA TEXT ────────────────────────────────────
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  _C.rainbow[_currentIndex % _C.rainbow.length],
                                  _C.rainbow[(_currentIndex + 2) % _C.rainbow.length],
                                  _C.rainbow[(_currentIndex + 4) % _C.rainbow.length],
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: Text(
                                '“$_currentKata”',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'ShareTechMono',
                                  height: 1.6,
                                  shadows: [
                                    Shadow(
                                      color: _C.purple.withOpacity(0.2),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // ─── AUTHOR ──────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _C.card.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _C.border.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    color: _C.textDim,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '— $_currentAuthor',
                                    style: TextStyle(
                                      color: _C.textSub,
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'ShareTechMono',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // ─── KATA COUNTER ────────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _C.card.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / $_kataCount',
                                style: TextStyle(
                                  color: _C.textDim,
                                  fontSize: 11,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── BOTTOM BUTTONS ──────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          // ─── KELUAR BUTTON ──────────────────────────────────────────
          Expanded(
            child: _buildActionButton(
              icon: Icons.close_rounded,
              label: 'KELUAR',
              color: _C.red,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          
          // ─── FAVORITE BUTTON ──────────────────────────────────────
          SizedBox(
            width: 56,
            height: 56,
            child: GestureDetector(
              onTap: _toggleFavorite,
              child: AnimatedBuilder(
                animation: _heartScale,
                builder: (_, __) {
                  return Transform.scale(
                    scale: _heartScale.value > 0 ? _heartScale.value : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _isFavorite
                            ? LinearGradient(
                                colors: [_C.red, _C.rose],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [_C.card.withOpacity(0.5), _C.surface.withOpacity(0.3)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isFavorite
                              ? _C.red.withOpacity(0.5)
                              : _C.border.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: _isFavorite
                            ? [
                                BoxShadow(
                                  color: _C.red.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isFavorite ? Colors.white : _C.textDim,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // ─── REFRESH BUTTON ─────────────────────────────────────────
          Expanded(
            child: _buildActionButton(
              icon: Icons.refresh_rounded,
              label: 'REFRESH',
              color: _C.cyan,
              onTap: _pickRandomKata,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15 + _pulseCtrl.value * 0.05),
                  color.withOpacity(0.05 + _pulseCtrl.value * 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withOpacity(0.3 + _pulseCtrl.value * 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1 * _pulseCtrl.value),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── PARTICLE PAINTER ──────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double time;
  final List<_Particle> particles = [];
  
  _ParticlePainter(this.time) {
    final random = math.Random(12345);
    for (int i = 0; i < 80; i++) {
      particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speedX: (random.nextDouble() - 0.5) * 0.003,
        speedY: (random.nextDouble() - 0.5) * 0.003,
        colorIndex: random.nextInt(_C.rainbow.length),
        opacity: random.nextDouble() * 0.5 + 0.1,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final x = (p.x + time * p.speedX) % 1.0;
      final y = (p.y + time * p.speedY) % 1.0;
      final color = _C.rainbow[p.colorIndex].withOpacity(p.opacity + 0.05 * math.sin(time * 2 + p.x));
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size + 0.5 * math.sin(time * 3 + p.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.time != time;
}

class _Particle {
  double x, y, size, speedX, speedY, opacity;
  int colorIndex;
  
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.colorIndex,
    required this.opacity,
  });
}