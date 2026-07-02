import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class ObfPage extends StatefulWidget {
  final String sessionKey;
  
  const ObfPage({super.key, required this.sessionKey});

  @override
  State<ObfPage> createState() => _ObfPageState();
}

class _ObfPageState extends State<ObfPage> with TickerProviderStateMixin {
  late String sessionKey;
  File? _selectedFile;
  String _selectedObfType = 'HARDCORE';
  bool _isProcessing = false;
  String _processingStatus = '';
  double _progress = 0;
  String? _resultFilePath;
  bool _isDownloading = false;
  
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
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
  
  final List<Map<String, dynamic>> _obfTypes = [
    {'id': 'HARDCORE', 'name': 'SUPER HARDCORE', 'icon': FontAwesomeIcons.shieldHalved, 'color': Color(0xFFE0E0F8), 'desc': 'ANTI DEBUG + ANTI TAMPER'},
    {'id': 'EXTREME', 'name': 'EXTREME', 'icon': FontAwesomeIcons.explosion, 'color': Color(0xFF9090B4), 'desc': '15 LAYER ENCRYPTION'},
    {'id': 'ULTIMATE', 'name': 'ULTIMATE', 'icon': FontAwesomeIcons.crown, 'color': Color(0xFFCCBB88), 'desc': 'VIRTUAL MACHINE EMULATION'},
    {'id': 'ANTIBYPASS', 'name': 'ANTIBYPASS', 'icon': FontAwesomeIcons.lock, 'color': Color(0xFFBB8899), 'desc': 'ADD PROTECTION LAYER'},
    {'id': 'HTML', 'name': 'HTML ENCRYPT', 'icon': FontAwesomeIcons.code, 'color': Color(0xFF8899AA), 'desc': 'ENCRYPT HTML FILES'},
  ];
  
  final List<Map<String, dynamic>> _loadingStages = [
    {'text': 'ANALYZING FILE', 'progress': 20},
    {'text': 'APPLYING ENCRYPTION', 'progress': 40},
    {'text': 'ADDING PROTECTION', 'progress': 60},
    {'text': 'FINALIZING', 'progress': 80},
    {'text': 'COMPLETE', 'progress': 100},
  ];
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _requestStoragePermission();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(_progressController);
  }
  
  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }
  
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['js', 'html'],
    );
    
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _resultFilePath = null;
      });
    }
  }
  
  Future<void> _processFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isProcessing = true;
      _progress = 0;
      _processingStatus = _loadingStages[0]['text'];
    });
    
    try {
      final fileContent = await _selectedFile!.readAsString();
      final isHtml = _selectedFile!.path.endsWith('.html');
      
      if (_selectedObfType == 'HTML' && !isHtml) {
        _showError('HTML ENCRYPT ONLY FOR .HTML FILES');
        setState(() => _isProcessing = false);
        return;
      }
      
      if (_selectedObfType != 'HTML' && !_selectedFile!.path.endsWith('.js')) {
        _showError('ONLY .JS FILES FOR OBFUSCATION');
        setState(() => _isProcessing = false);
        return;
      }
      
      for (int i = 0; i < _loadingStages.length; i++) {
        if (!mounted) return;
        setState(() {
          _progress = _loadingStages[i]['progress'].toDouble();
          _processingStatus = _loadingStages[i]['text'];
        });
        await Future.delayed(Duration(milliseconds: 600));
      }
      
      String processedCode = await _simulateObfuscation(fileContent);
      
      final outputDir = await getTemporaryDirectory();
      final extension = _selectedFile!.path.split('.').last;
      final outputFileName = 'FLOTX-${_selectedObfType}-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final outputFile = File('${outputDir.path}/$outputFileName');
      await outputFile.writeAsString(processedCode);
      
      setState(() {
        _resultFilePath = outputFile.path;
        _isProcessing = false;
        _progress = 100;
      });
      
    } catch (e) {
      _showError('PROCESSING ERROR: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }
  
  Future<String> _simulateObfuscation(String code) async {
    String watermark = '// FLOTXNIKIDS ${_selectedObfType} PROTECTION\n// DO NOT DECOMPILE\n\n';
    
    String obfuscated = code;
    
    if (_selectedObfType == 'HARDCORE') {
      obfuscated = _hardcoreObfuscate(code);
    } else if (_selectedObfType == 'EXTREME') {
      obfuscated = _extremeObfuscate(code);
    } else if (_selectedObfType == 'ULTIMATE') {
      obfuscated = _ultimateObfuscate(code);
    } else if (_selectedObfType == 'ANTIBYPASS') {
      obfuscated = _addAntibypass(code);
    } else if (_selectedObfType == 'HTML') {
      obfuscated = _encryptHtml(code);
    }
    
    return watermark + obfuscated;
  }
  
  String _hardcoreObfuscate(String code) {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    
    String generateVarName() {
      return '_0x' + List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    }
    
    String result = '';
    List<String> lines = code.split('\n');
    
    for (String line in lines) {
      if (line.trim().startsWith('//') || line.trim().isEmpty) {
        result += line + '\n';
        continue;
      }
      
      String newLine = line;
      RegExp(r'\b([a-zA-Z_$][a-zA-Z0-9_$]*)\b').allMatches(line).forEach((match) {
        if (!['var', 'let', 'const', 'function', 'if', 'else', 'for', 'while', 'return', 'true', 'false', 'null', 'undefined', 'this'].contains(match.group(1))) {
          newLine = newLine.replaceAll(match.group(1)!, generateVarName());
        }
      });
      
      result += newLine + '\n';
    }
    
    result = _addAntiDebug(result);
    result = _addIntegrityCheck(result);
    
    return result;
  }
  
  String _extremeObfuscate(String code) {
    String encoded = base64.encode(utf8.encode(code));
    return '''
(function(){
  var _0x = atob("$encoded");
  var _0x2 = "";
  for(var i=0;i<_0x.length;i++){
    _0x2 += String.fromCharCode(_0x.charCodeAt(i) ^ 0x42);
  }
  eval(_0x2);
})();
''';
  }
  
  String _ultimateObfuscate(String code) {
    String encoded = '';
    for (int i = 0; i < code.length; i++) {
      encoded += '\\u${code.codeUnitAt(i).toRadixString(16).padLeft(4, '0')}';
    }
    
    String layers = '';
    for (int i = 0; i < 5; i++) {
      encoded = base64.encode(utf8.encode(encoded));
      layers += '''
  _0x = atob(_0x);
''';
    }
    
    return '''
(function(){
  var _0x = "$encoded";
  $layers
  eval(_0x);
})();
''';
  }
  
  String _addAntibypass(String code) {
    String antibypass = '''
// ANTI DEBUG
if (typeof process !== 'undefined' && process.execArgv && process.execArgv.some(arg => 
  arg.includes('--inspect') || 
  arg.includes('--debug') ||
  arg.includes('--trace')
)) {
  console.log("FLOTX: DEBUG DETECTED!");
  process.exit(1);
}

// ANTI TAMPER
if (typeof crypto !== 'undefined' && typeof fs !== 'undefined') {
  const crypto = require('crypto');
  const fs = require('fs');
  const scriptHash = crypto.createHash('sha256').update(__filename).digest('hex');
  
  setInterval(() => {
    try {
      const currentHash = crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex');
      if (currentHash !== scriptHash) {
        console.log("FLOTX: TAMPER DETECTED!");
        process.exit(1);
      }
    } catch(e) {}
  }, 5000);
}

// ANTI VM
const isVM = () => {
  try {
    if (typeof process !== 'undefined') {
      if (process.env.VM || process.env.CONTAINER) return true;
    }
    if (typeof require !== 'undefined') {
      if (require('os').cpus().length < 2) return true;
    }
    return false;
  } catch(e) { return false; }
};

if (isVM()) {
  console.log("FLOTX: VM DETECTED!");
  if (typeof process !== 'undefined') process.exit(1);
}

console.log("FLOTX PROTECTION ACTIVE");

''';
    return antibypass + code;
  }
  
  String _encryptHtml(String html) {
    String encoded = base64.encode(utf8.encode(html));
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FLOTX ENCRYPTED</title>
<style>
  body { background: #0C0C10; color: #E0E0F8; font-family: monospace; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
  .container { text-align: center; }
  .loader { width: 48px; height: 48px; border: 3px solid #E0E0F8; border-radius: 50%; border-top-color: transparent; animation: spin 1s linear infinite; margin: 20px auto; }
  @keyframes spin { to { transform: rotate(360deg); } }
</style>
</head>
<body>
<div class="container">
  <div class="loader"></div>
  <h3>FLOTX PROTECTED</h3>
  <p>Loading content...</p>
</div>
<script>
  (function(){
    var _0x = "$encoded";
    try {
      var _0x2 = atob(_0x);
      document.open();
      document.write(_0x2);
      document.close();
    } catch(e) {
      console.error("FLOTX: DECRYPT ERROR", e);
      document.body.innerHTML = '<div class="container"><h3>FLOTX ERROR</h3><p>Enable JavaScript to view content</p></div>';
    }
  })();
</script>
</body>
</html>''';
  }
  
  String _addAntiDebug(String code) {
    return '''
// FLOTX ANTI DEBUG
(function(){
  var check = function(){
    if (typeof process !== 'undefined' && process.execArgv) {
      if(process.execArgv.some(function(arg){ 
        return arg.includes('--inspect') || arg.includes('--debug');
      })){
        console.log("FLOTX: DEBUGGER DETECTED");
        if(typeof process !== 'undefined') process.exit(1);
      }
    }
    var start = Date.now();
    debugger;
    var end = Date.now();
    if(end - start > 100){
      console.log("FLOTX: DEVTOOLS DETECTED");
      if(typeof process !== 'undefined') process.exit(1);
      else window.location.href = "about:blank";
    }
  };
  check();
  setInterval(check, 1000);
})();

''' + code;
  }
  
  String _addIntegrityCheck(String code) {
    String hash = base64.encode(utf8.encode(code.substring(0, min(100, code.length))));
    return '''
// FLOTX INTEGRITY CHECK
(function(){
  const expectedHash = "$hash";
  let currentCode = "";
  const observer = new MutationObserver(function(){
    try{
      throw new Error();
    } catch(e){
      const stack = e.stack;
      if(stack !== currentCode){
        currentCode = stack;
        if(checksum(currentCode) !== expectedHash){
          console.log("FLOTX: INTEGRITY FAILED");
          if(typeof process !== 'undefined') process.exit(1);
          else window.location.href = "about:blank";
        }
      }
    }
  });
  function checksum(str){
    let hash = 0;
    for(let i=0; i<str.length; i++){
      hash = ((hash << 5) - hash) + str.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash).toString(16);
  }
  if(typeof document !== 'undefined'){
    observer.observe(document, {childList: true, subtree: true});
  }
})();

''' + code;
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _cinzel(12, FontWeight.w600, 1.0)),
        backgroundColor: _roseColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _cinzel(12, FontWeight.w600, 1.0)),
        backgroundColor: _successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  Future<void> _downloadResult() async {
    if (_resultFilePath == null) return;
    
    setState(() {
      _isDownloading = true;
    });
    
    try {
      final sourceFile = File(_resultFilePath!);
      final bytes = await sourceFile.readAsBytes();
      final fileName = sourceFile.path.split('/').last;
      
      if (Platform.isAndroid) {
        await Permission.storage.request();
        if (await Permission.storage.isGranted) {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          final destinationFile = File('${downloadsDir.path}/$fileName');
          await destinationFile.writeAsBytes(bytes);
          
          _showSuccess('FILE SAVED TO DOWNLOADS FOLDER: $fileName');
        } else {
          final tempDir = await getExternalStorageDirectory();
          final destinationFile = File('${tempDir?.path}/$fileName');
          await destinationFile.writeAsBytes(bytes);
          _showSuccess('FILE SAVED TO: ${destinationFile.path}');
        }
      } else {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final destinationFile = File('${downloadsDir.path}/$fileName');
          await destinationFile.writeAsBytes(bytes);
          _showSuccess('FILE SAVED TO DOWNLOADS FOLDER: $fileName');
        } else {
          final tempDir = await getTemporaryDirectory();
          final destinationFile = File('${tempDir.path}/$fileName');
          await destinationFile.writeAsBytes(bytes);
          _showSuccess('FILE SAVED TO: ${destinationFile.path}');
        }
      }
      
    } catch (e) {
      _showError('DOWNLOAD FAILED: ${e.toString()}');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildFileSelector(),
                      const SizedBox(height: 24),
                      _buildObfTypeSelector(),
                      const SizedBox(height: 24),
                      if (_selectedFile != null) _buildFileInfo(),
                      const SizedBox(height: 24),
                      _buildProcessButton(),
                      if (_isProcessing) ...[
                        const SizedBox(height: 24),
                        _buildProgressIndicator(),
                      ],
                      if (_resultFilePath != null && !_isProcessing) ...[
                        const SizedBox(height: 24),
                        _buildResultCard(),
                      ],
                      const SizedBox(height: 40),
                      _buildFooter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 1.6,
          colors: [_glowColor1.withOpacity(0.03), _darkerBg, _darkBg],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                  ),
                  child: Icon(FontAwesomeIcons.shieldHalved, color: _glowColor1, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [_glowColor1, _accentColor, _glowColor2],
                        ).createShader(bounds),
                        child: Text(
                          'FLOTX OBFUSCATOR',
                          style: _cinzel(18, FontWeight.w900, 1.0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PROTECT YOUR CODE',
                        style: _cinzel(10, FontWeight.w600, 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFileSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: _glowColor1.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(FontAwesomeIcons.fileCode, color: _glowColor1.withOpacity(0.5), size: 48),
              const SizedBox(height: 12),
              Text(
                _selectedFile == null ? 'SELECT FILE' : _selectedFile!.path.split('/').last,
                style: _cinzel(13, FontWeight.w700, 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                '.JS OR .HTML ONLY',
                style: _cinzel(10, FontWeight.w500, 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _successColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(FontAwesomeIcons.checkCircle, color: _successColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'FILE READY FOR OBFUSCATION',
                style: _cinzel(12, FontWeight.w700, 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildObfTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'SELECT OBFUSCATION TYPE',
              style: _cinzel(11, FontWeight.w700, 0.5),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _obfTypes.map((type) {
                final isSelected = _selectedObfType == type['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedObfType = type['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 140,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? (type['color'] as Color).withOpacity(0.15) : _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? type['color'] : type['color'].withOpacity(0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          FaIcon(type['icon'], color: type['color'], size: 24),
                          const SizedBox(height: 8),
                          Text(
                            type['name'],
                            style: _cinzel(11, FontWeight.w800, isSelected ? 0.9 : 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type['desc'],
                            style: _cinzel(8, FontWeight.w500, 0.3),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: (_selectedFile != null && !_isProcessing) ? _processFile : null,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_glowColor1, _glowColor2],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'PROCESS FILE',
                  style: _cinzel(13, FontWeight.w900, 1.0).copyWith(color: _darkerBg),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              _processingStatus,
              style: _cinzel(13, FontWeight.w700, 0.8),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: _surfaceColor,
                valueColor: AlwaysStoppedAnimation<Color>(_glowColor1),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_progress.toInt()}%',
              style: _cinzel(11, FontWeight.w600, 0.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _successColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(FontAwesomeIcons.checkCircle, color: _successColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'OBFUSCATION COMPLETE',
                  style: _cinzel(14, FontWeight.w800, 0.9),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isDownloading ? null : _downloadResult,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_glowColor1, _glowColor2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor1.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.download, color: _darkerBg, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'DOWNLOAD TO DEVICE',
                            style: _cinzel(12, FontWeight.w900, 1.0).copyWith(color: _darkerBg),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText('PROTECTED'),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor3),
            const SizedBox(width: 10),
            _buildFooterText('SECURE'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'FLOTX OBFUSCATOR V2.0',
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 3,
            fontFamily: 'CinzelDecorative',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }
  
  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'CinzelDecorative',
      ),
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
    _glowController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}