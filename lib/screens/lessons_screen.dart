import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class Lesson {
  final String title;
  final String url;
  final String thumbnail;

  Lesson({required this.title, required this.url, required this.thumbnail});
}

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  static List<Lesson> lessons = [
    Lesson(
      title: 'الدرس الأول',
      url: 'https://youtu.be/ZSo0_0zxYHQ?si=DXvbjCByNQSbya0X',
      thumbnail: 'https://img.youtube.com/vi/ZSo0_0zxYHQ/hqdefault.jpg',
    ),
    Lesson(
      title: 'الدرس الثاني',
      url: 'https://youtu.be/3XvnTZX7hV8?si=Y8ndlGOv_8oBhb8v',
      thumbnail: 'https://img.youtube.com/vi/3XvnTZX7hV8/hqdefault.jpg',
    ),
    Lesson(
      title: 'الدرس الثالث',
      url: 'https://youtu.be/PB2aGWhRIOU?si=qFjGovWzN648uZpA',
      thumbnail: 'https://img.youtube.com/vi/PB2aGWhRIOU/hqdefault.jpg',
    ),
  ];

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الدروس',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryEmerald,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryEmerald.withOpacity(0.1), Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () => _launchUrl(lesson.url),
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            lesson.thumbnail,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 200,
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.video_library_rounded,
                            color: AppTheme.primaryEmerald,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lesson.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
