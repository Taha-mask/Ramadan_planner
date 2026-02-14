import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

enum LessonType { video, playlist, channel }

class Lesson {
  final String title;
  final String url;
  final String? thumbnail; // Optional, can be auto-generated for videos
  final LessonType type;
  final String? id; // Video ID or generic ID for thumbnail generation

  Lesson({
    required this.title,
    required this.url,
    this.thumbnail,
    this.type = LessonType.video,
    this.id,
  });

  String get getThumbnail {
    if (thumbnail != null) return thumbnail!;
    if (id != null) {
      return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    }
    return ''; // Placeholder handled in UI
  }
}

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  static List<Lesson> videos = [
    Lesson(
      title: 'السر وراء يوم عرفة وعلاقته بالدعاء',
      url: 'https://youtu.be/ZSo0_0zxYHQ',
      id: 'ZSo0_0zxYHQ',
      type: LessonType.video,
    ),
    Lesson(
      title: 'وعي ٩٠ | رمضان سؤال وجواب ١',
      url: 'https://youtu.be/3XvnTZX7hV8',
      id: '3XvnTZX7hV8',
      type: LessonType.video,
    ),
    Lesson(
      title: 'وعي ٩١ | رمضان سؤال وجواب ٢',
      url: 'https://youtu.be/PB2aGWhRIOU',
      id: 'PB2aGWhRIOU',
      type: LessonType.video,
    ),
    Lesson(
      title: 'وعي ١٠٣ | آخر رمضان',
      url: 'https://www.youtube.com/watch?v=B9ysqlrrBwY',
      id: 'B9ysqlrrBwY',
      type: LessonType.video,
    ),
    Lesson(
      title: 'خطة الـ 24 ساعة الأولى في رمضان',
      url: 'https://www.youtube.com/watch?v=qeRo1ceJ2xw',
      id: 'qeRo1ceJ2xw',
      type: LessonType.video,
    ),
    Lesson(
      title: 'وعي ١١ | الفتور في رمضان وحسن التعامل مع النفس',
      url: 'https://www.youtube.com/watch?v=fqL5bKCZlMw',
      id: 'fqL5bKCZlMw',
      type: LessonType.video,
    ),
  ];

  static List<Lesson> playlists = [
    Lesson(
      title: 'هداية الراغب شرح عمدة الطالب | كتاب الصيام',
      url:
          'https://www.youtube.com/playlist?list=PLIi5nfiD0RbM-EWzQQy02fvu5n9WQ7LGf',
      id: 'yu6_F5-W5lA', // First video ID
      type: LessonType.playlist,
    ),
    Lesson(
      title: 'شرح كتاب الصيام | متن عمدة الطالب',
      url:
          'https://www.youtube.com/playlist?list=PLIi5nfiD0RbNi04xog8AlVVPguAbQTz2Z',
      id: 'Wwwl_-ayxsg', // First video ID
      type: LessonType.playlist,
    ),
    Lesson(
      title: 'عالمغرب رمضان',
      url:
          'https://www.youtube.com/playlist?list=PLlXQj2VGUTmdN73dvFG17xdOCoM2E1K66',
      id: 'Yx88r8QcsoU', // First video ID
      type: LessonType.playlist,
    ),
  ];

  static List<Lesson> channels = [
    Lesson(
      title: 'وعي',
      url: 'https://www.youtube.com/@waie',
      type: LessonType.channel,
    ),
    Lesson(
      title: 'أمجد سمير',
      url: 'https://www.youtube.com/@AmgadSamir',
      type: LessonType.channel,
    ),
    Lesson(
      title: 'د/ حازم شومان',
      url: 'https://www.youtube.com/@DrHazemShouman',
      type: LessonType.channel,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الدروس والمحتوى نافع',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryEmerald,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white, // Ensure back button/title is white
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppTheme.primaryEmerald.withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ]
                : [
                    AppTheme.primaryEmerald.withValues(alpha: 0.05),
                    Colors.white,
                  ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('الدروس المختارة', Icons.play_circle_fill),
            ...videos.map((l) => _buildVideoCard(l, context)),

            const SizedBox(height: 24),
            _buildSectionTitle('سلاسل وقوائم تشغيل', Icons.video_library),
            ...playlists.map((l) => _buildPlaylistCard(l, context)),

            const SizedBox(height: 24),
            _buildSectionTitle('قنوات مقترحة', Icons.smart_display),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.start,
              children: channels
                  .map((l) => _buildChannelItem(l, context, isDark))
                  .toList(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryEmerald, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryEmerald,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Lesson lesson, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _launchUrl(lesson.url),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    lesson.getThumbnail,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(Lesson lesson, BuildContext context) {
    // Reusing the video card style for consistency as requested
    // but with a playlist indicator
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _launchUrl(lesson.url),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.bottomRight, // Align badge to bottom right
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        lesson.getThumbnail,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons
                              .playlist_play_rounded, // Distinct icon for playlist
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  // Playlist Badge
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.format_list_bulleted,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'قائمة تشغيل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelItem(Lesson lesson, BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _launchUrl(lesson.url),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryEmerald, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              child: Text(
                lesson.title.substring(0, 1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryEmerald,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
