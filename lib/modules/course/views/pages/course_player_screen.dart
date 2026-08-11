import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:badminton_ai/modules/course/models/course.dart';
import 'package:badminton_ai/modules/course/viewmodels/course_provider.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';
import 'package:badminton_ai/core/design_system/components/ui/custom_gradient_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class CoursePlayerScreen extends StatefulWidget {
  final Course course;

  const CoursePlayerScreen({super.key, required this.course});

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    // Đánh dấu là đã xem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().markAsWatched(widget.course);
    });

    final videoId = YoutubePlayer.convertUrlToId(widget.course.videoUrl) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: videoId.isEmpty ? 's9X_Pj4r9i0' : videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    )..addListener(listener);
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: VColors.brandPrimary,
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: CustomGradientAppBar(
            title: Text(
              widget.course.title,
              style: TextStyle(fontSize: 16),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              player,
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Thời lượng: ${widget.course.duration}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text('screens.courseDescription'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.course.description,
                      style: TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
