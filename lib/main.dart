
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/result_screen.dart';

import 'firebase_options.dart';
import 'services/analytics_service.dart';

// Step 4: Firebase 초기화 및 flutterfire 설정
// 1. Firebase CLI 설치: `npm install -g firebase-tools`
// 2. Firebase 로그인: `firebase login`
// 3. FlutterFire CLI 설치: `dart pub global activate flutterfire_cli`
// 4. Firebase 프로젝트 생성 및 앱 등록 (Firebase Console)
// 5. 프로젝트 루트에서 flutterfire configure 실행: `flutterfire configure`

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase 초기화
  );
  runApp(const YakBiseoApp());
}

class YakBiseoApp extends StatelessWidget {
  const YakBiseoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '약비서',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _analyticsService.logAppOpen(); // 앱 실행 시 이벤트 로깅
  }

  Future<void> _pickImageFromCamera() async {
    _analyticsService.logCameraClick(); // 카메라 버튼 클릭 이벤트
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (!mounted) return; // context가 유효한지 확인
      // 결과 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(imagePath: pickedFile.path),
        ),
      );
      // TODO: 분석 결과에 따라 logAnalysisResult 호출
      // 예시: _analyticsService.logAnalysisResult(true);
    }
  }

  void _pickImageFromGallery() {
    _analyticsService.logGalleryClick(); // 갤러리 버튼 클릭 이벤트
    // TODO: 갤러리 연동 로직 구현
    developer.log('갤러리 버튼 클릭됨', name: 'com.example.myapp.ui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '💊 내 손안의 약비서',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '김영희님, 안녕하세요!\n지금 드시는 약,\n불필요한 건 없을까요?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '약 봉투나 영양제통을 찍어보세요.\n3초 만에 분석해 드립니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              _buildBigActionButton(
                icon: Icons.camera_alt_rounded,
                label: '약 봉투 촬영하기',
                color: const Color(0xFF2E7D32),
                onTap: _pickImageFromCamera,
              ),
              const SizedBox(height: 16),
              _buildBigActionButton(
                icon: Icons.photo_library_rounded,
                label: '앨범에서 불러오기',
                color: const Color(0xFF424242),
                onTap: _pickImageFromGallery,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '결과는 참고용이며, 정확한 진단은 의사/약사와 상의하세요.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
