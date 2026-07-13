import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'audio_service.dart';
import 'data/positive_stories.dart';
import 'data/story_db.dart';
import 'firebase_options.dart';
import 'firebase_service.dart';
import 'kakao_auth_service.dart';
import 'models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  KakaoSdk.init(nativeAppKey: '7a9530370e39ec27e50f8d38379a0d22');
  await AppAudioService.instance.initialize();
  runApp(const ChameulinApp());
}

class ChameulinApp extends StatefulWidget {
  const ChameulinApp({super.key});
  @override
  State<ChameulinApp> createState() => _ChameulinAppState();
}

class _ChameulinAppState extends State<ChameulinApp> {
  bool darkMode = false;
  bool effectSound = true;
  bool backgroundMusic = true;
  double effectVolume = .24;
  double backgroundVolume = .20;
  String storyStyle = 'random';

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF617A3F),
    ).copyWith(
      surface: const Color(0xFFF7FAEC),
      surfaceContainerLow: const Color(0xFFFBFDF4),
    );
    return MaterialApp(
      title: '참을인',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF2F7E4),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF2F7E4)),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFFF8FBEF),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8FAA66),
          brightness: Brightness.dark,
        ).copyWith(outline: Colors.white70, outlineVariant: Colors.white38),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white38),
          ),
        ),
        dividerTheme: const DividerThemeData(color: Colors.white38),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF8FAA66), width: 2)),
        ),
      ),
      home: AppShell(
        darkMode: darkMode,
        effectSound: effectSound,
        backgroundMusic: backgroundMusic,
        effectVolume: effectVolume,
        backgroundVolume: backgroundVolume,
        storyStyle: storyStyle,
        onDarkMode: (v) => setState(() => darkMode = v),
        onEffectSound: (v) {
          setState(() => effectSound = v);
          unawaited(AppAudioService.instance.setEffectEnabled(v));
        },
        onBackgroundMusic: (v) {
          setState(() => backgroundMusic = v);
          unawaited(AppAudioService.instance.setBackgroundEnabled(v));
        },
        onEffectVolume: (v) {
          setState(() => effectVolume = v);
          unawaited(AppAudioService.instance.setEffectVolume(v));
        },
        onBackgroundVolume: (v) {
          setState(() => backgroundVolume = v);
          unawaited(AppAudioService.instance.setBackgroundVolume(v));
        },
        onStoryStyle: (v) => setState(() => storyStyle = v),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final bool darkMode;
  final bool effectSound;
  final bool backgroundMusic;
  final double effectVolume;
  final double backgroundVolume;
  final String storyStyle;
  final ValueChanged<bool> onDarkMode;
  final ValueChanged<bool> onEffectSound;
  final ValueChanged<bool> onBackgroundMusic;
  final ValueChanged<double> onEffectVolume;
  final ValueChanged<double> onBackgroundVolume;
  final ValueChanged<String> onStoryStyle;

  const AppShell({
    super.key,
    required this.darkMode,
    required this.effectSound,
    required this.backgroundMusic,
    required this.effectVolume,
    required this.backgroundVolume,
    required this.storyStyle,
    required this.onDarkMode,
    required this.onEffectSound,
    required this.onBackgroundMusic,
    required this.onEffectVolume,
    required this.onBackgroundVolume,
    required this.onStoryStyle,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? nickname;
  String? linkedAccountLabel;
  int tabIndex = 0;
  String currentUserId = 'connecting';
  final records = <EmotionRecord>[];
  StreamSubscription<List<SharedPost>>? _postsSubscription;
  final sharedPosts = <SharedPost>[];

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _connectFirebase();
  }

  Future<void> _connectFirebase() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final userId = await AppFirebaseService.instance.signIn();
      var savedNickname = await AppFirebaseService.instance.loadNickname();
      final savedRecords = await AppFirebaseService.instance.loadRecords();
      final accountLabel = await AppFirebaseService.instance.linkedAccountLabel();
      if (!mounted) return;
      setState(() {
        currentUserId = userId;
        linkedAccountLabel = accountLabel;
        if (savedNickname != null) nickname = savedNickname;
        records
          ..clear()
          ..addAll(savedRecords);
      });
      _postsSubscription =
          AppFirebaseService.instance.watchSharedPosts().listen(
        (posts) {
          if (!mounted) return;
          setState(() {
            sharedPosts
              ..clear()
              ..addAll(posts);
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Firestore shared posts error: $error');
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Firebase connection error: $error\n$stackTrace');
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onStart: _startWriting),
      RecordsPage(records: records, onTabSelected: _selectTabFromRoute),
      EmpathyPage(
        posts: sharedPosts,
        currentUserId: currentUserId,
        onReact: _react,
        onReport: _report,
      ),
      MySharePage(
          posts: sharedPosts.where((p) => p.ownerId == currentUserId).toList()),
      const PositivePage(),
      SettingsPage(
        nickname: nickname,
        linkedAccountLabel: linkedAccountLabel,
        darkMode: widget.darkMode,
        effectSound: widget.effectSound,
        backgroundMusic: widget.backgroundMusic,
        effectVolume: widget.effectVolume,
        backgroundVolume: widget.backgroundVolume,
        storyStyle: widget.storyStyle,
        onDarkMode: widget.onDarkMode,
        onEffectSound: widget.onEffectSound,
        onBackgroundMusic: widget.onBackgroundMusic,
        onEffectVolume: widget.onEffectVolume,
        onBackgroundVolume: widget.onBackgroundVolume,
        onStoryStyle: widget.onStoryStyle,
        onDeleteData: _deleteData,
        onDeleteAccount: _deleteAccount,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: pages),
      bottomNavigationBar: AppBottomArea(
          selectedIndex: tabIndex,
          onSelected: (i) => setState(() => tabIndex = i)),
    );
  }

  Future<void> _deleteData() async {
    try {
      if (currentUserId != 'connecting') {
        await AppFirebaseService.instance.deleteMyData();
      }
      if (!mounted) return;
      setState(() {
        records.clear();
        sharedPosts.removeWhere((p) => p.ownerId == currentUserId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내 기록과 공유 데이터가 삭제되었습니다.')),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터를 삭제하지 못했습니다. 잠시 후 다시 시도해주세요.')),
        );
    }
  }

  Future<void> _deleteAccount() async {
    if (!AppFirebaseService.instance.hasLinkedAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연동된 계정이 없습니다.')),
      );
      return;
    }
    try {
      await AppFirebaseService.instance.deleteLinkedAccount();
      if (!mounted) return;
      setState(() {
        nickname = null;
        linkedAccountLabel = null;
        records.clear();
        sharedPosts.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('보안을 위해 다시 로그인한 뒤 탈퇴해주세요.')),
        );
    }
  }

  Future<void> _startWriting() async {
    await AppAudioService.instance.playButton();
    if (!mounted) return;
    final result = await Navigator.of(context).push<WritingResult>(
      MaterialPageRoute(
        builder: (_) => WritingFlow(
          storyStyle: widget.storyStyle,
          todayWritingNumber: _todayWritingCount() + 1,
          onTabSelected: _selectTabFromRoute,
        ),
      ),
    );
    if (result == null) {
      unawaited(AppAudioService.instance.setBgm(AppBgm.home));
      return;
    }
    final activeUserId = AppFirebaseService.instance.currentUserId;
    final activeNickname = AppFirebaseService.instance.hasLinkedAccount
        ? await AppFirebaseService.instance.loadNickname()
        : nickname;
    final activeAccountLabel =
        await AppFirebaseService.instance.linkedAccountLabel();
    if (!mounted) return;
    final record = EmotionRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      category: result.category,
      moodEmoji: result.moodEmoji,
      moodLabel: result.moodLabel,
      text: result.text,
      story: result.story,
      shared: result.shared,
    );
    setState(() {
      if (activeUserId != null) currentUserId = activeUserId;
      nickname = activeNickname;
      linkedAccountLabel = activeAccountLabel;
      records.insert(0, record);
      if (result.shared) {
        sharedPosts.insert(
          0,
          SharedPost(
            id: record.id,
            ownerId: currentUserId,
            category: record.category,
            text: record.text,
            moodEmoji: record.moodEmoji,
            createdAt: record.createdAt,
          ),
        );
        tabIndex = 3;
      } else {
        tabIndex = 1;
      }
    });
    if (currentUserId != 'connecting') {
      unawaited(AppFirebaseService.instance.saveRecord(record));
      if (result.storyFeedback != null) {
        unawaited(
          AppFirebaseService.instance.submitStoryFeedback(
            result.story.id,
            result.storyFeedback!,
          ),
        );
      }
    }
  }

  void _selectTabFromRoute(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => tabIndex = index);
    unawaited(AppAudioService.instance.setBgm(AppBgm.home));
  }

  int _todayWritingCount() {
    final now = DateTime.now();
    return records.where((record) {
      final date = record.createdAt;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  void _react(SharedPost post, int reactionIndex) {
    if (post.ownerId == currentUserId || post.myReaction != null) return;
    setState(() {
      post.myReaction = reactionIndex;
      post.reactions[reactionIndex]++;
    });
    unawaited(AppFirebaseService.instance.react(post, reactionIndex));
  }

  void _report(SharedPost post) {
    setState(() => post.reportCount++);
    unawaited(AppFirebaseService.instance.report(post));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고가 접수되었습니다. 운영자 검토 후 처리됩니다.')),
    );
  }
}

class AppBottomArea extends StatelessWidget {
  const AppBottomArea(
      {super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        NavigationBar(
          indicatorColor: const [
            Color(0xFFFFE1C2),
            Color(0xFFE7D9FF),
            Color(0xFFFFD8DE),
            Color(0xFFD8ECCA),
            Color(0xFFFFE9B8),
            Color(0xFFDCE2EA)
          ][selectedIndex],
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            unawaited(AppAudioService.instance.playButton());
            onSelected(index);
          },
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined, color: Color(0xFFE9823B)),
                selectedIcon: Icon(Icons.home, color: Color(0xFFD46B20)),
                label: '홈'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined,
                    color: Color(0xFF8559B5)),
                selectedIcon:
                    Icon(Icons.calendar_month, color: Color(0xFF6F419F)),
                label: '내 기록'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border, color: Color(0xFFE15064)),
                selectedIcon: Icon(Icons.favorite, color: Color(0xFFC9374E)),
                label: '공감'),
            NavigationDestination(
                icon: Icon(Icons.eco_outlined, color: Color(0xFF55934E)),
                selectedIcon: Icon(Icons.eco, color: Color(0xFF3E7B38)),
                label: '내 공유'),
            NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined, color: Color(0xFFE4A52C)),
                selectedIcon: Icon(Icons.wb_sunny, color: Color(0xFFC88A12)),
                label: '긍정'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined, color: Color(0xFF6F7887)),
                selectedIcon: Icon(Icons.settings, color: Color(0xFF535D6D)),
                label: '설정'),
          ],
        ),
        const BottomAdSlots(),
      ]);
}

class BottomAdSlots extends StatefulWidget {
  const BottomAdSlots({super.key});

  static const double height = 50;

  @override
  State<BottomAdSlots> createState() => _BottomAdSlotsState();
}

class _BottomAdSlotsState extends State<BottomAdSlots> {
  Future<void> _open(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        height: BottomAdSlots.height,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(children: [
          Expanded(
              child: _AdSlot(
            key: const ValueKey('bottom-ad-slot-1'),
            label: '광고 영역 1: 조용한 밤의 위로',
            title: '조용한 밤의 위로',
            color: Colors.white,
            youtube: true,
            background: const [Color(0xFF17283A), Color(0xFF526B56)],
            onTap: () => _open('https://www.youtube.com/@slowhug'),
          )),
          VerticalDivider(width: 1, thickness: 1, color: colors.outlineVariant),
          const Expanded(
              child: _AdSlot(
            key: ValueKey('bottom-ad-slot-2'),
            label: '광고 영역 2: 비어 있음',
            title: '',
            color: Colors.transparent,
          )),
        ]),
      ),
    );
  }
}

class _AdSlot extends StatelessWidget {
  const _AdSlot({
    super.key,
    required this.label,
    required this.title,
    required this.color,
    this.onTap,
    this.youtube = false,
    this.background,
  });
  final String label;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final bool youtube;
  final List<Color>? background;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleColor = youtube && Theme.of(context).brightness == Brightness.light
        ? Colors.black87
        : color;
    return Semantics(
      label: label,
      button: onTap != null,
      child: Ink(
        decoration: background == null
            ? null
            : BoxDecoration(
                gradient: LinearGradient(colors: background!),
              ),
        child: InkWell(
          onTap: onTap,
          child: Stack(children: [
            Positioned(
                left: 5,
                top: 3,
                child: Text('광고',
                    style: TextStyle(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.55),
                      fontSize: 9,
                    ))),
            Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (youtube) ...[
                const Icon(Icons.play_circle_fill,
                    color: Color(0xFFFF0033), size: 17),
                const SizedBox(width: 5),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: TextStyle(
                      color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ])),
          ]),
        ),
      ),
    );
  }
}

class SplashNicknameFlow extends StatefulWidget {
  final ValueChanged<String> onDone;
  final Future<bool> Function(String nickname)? claimNickname;
  const SplashNicknameFlow({
    super.key,
    required this.onDone,
    this.claimNickname,
  });

  @override
  State<SplashNicknameFlow> createState() => _SplashNicknameFlowState();
}

class _SplashNicknameFlowState extends State<SplashNicknameFlow> {
  int step = 0;
  final controller = TextEditingController();
  Timer? _timer;
  String? nicknameError;
  bool checkingNickname = false;
  bool canStartOffline = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => step = 1);
    });
  }

  Future<void> submit() async {
    final nick = controller.text.trim();
    if (nick.length < 2 || nick.length > 12) {
      setState(() => nicknameError = '닉네임은 2~12자로 입력해주세요.');
      return;
    }
    if (!RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(nick)) {
      setState(() => nicknameError = '한글, 영문, 숫자, 밑줄만 사용할 수 있습니다.');
      return;
    }
    setState(() {
      checkingNickname = true;
      nicknameError = null;
      canStartOffline = false;
    });
    try {
      final available = await (widget.claimNickname ??
          AppFirebaseService.instance.claimNickname)(nick);
      if (!mounted) return;
      if (!available) {
        setState(() {
          checkingNickname = false;
          nicknameError = '이미 사용 중인 닉네임입니다.';
        });
        return;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        checkingNickname = false;
        canStartOffline = true;
        nicknameError = '닉네임 서버에 연결할 수 없습니다.';
      });
      return;
    }
    _finish(nick);
  }

  void _finish(String nickname) {
    setState(() => step = 2);
    unawaited(AppAudioService.instance.playComplete());
    _timer?.cancel();
    _timer = Timer(
      const Duration(milliseconds: 2500),
      () => widget.onDone(nickname),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('忍',
                style: TextStyle(fontSize: 130, color: Color(0xFF617A3F))),
            SizedBox(height: 8),
            Text('참을인',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('화난 마음에, 이야기 하나.'),
          ]),
        ),
      );
    }
    if (step == 2) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🌱', style: TextStyle(fontSize: 54)),
            SizedBox(height: 16),
            Text('반가워요.',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('화난 순간마다\n이야기 하나를 건네드릴게요.', textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('참을인에서 사용할\n닉네임을 정해주세요.',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('실명 대신 앱 안에서만 사용할 이름입니다.'),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              maxLength: 12,
              onChanged: (_) => setState(() {
                nicknameError = null;
                canStartOffline = false;
              }),
              decoration: InputDecoration(
                hintText: '예) 화가많은화가',
                errorText: nicknameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: checkingNickname ? null : submit,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: checkingNickname
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('시작하기'),
                ),
              ),
            ),
            if (canStartOffline) ...[
              const SizedBox(height: 10),
              const Text(
                '인터넷 연결 후 닉네임 중복 확인을 다시 진행합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _finish(controller.text.trim()),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(child: Text('오프라인으로 시작하기')),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final VoidCallback onStart;
  const HomePage({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('참을인',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 16),
          const Text('내 마음을 위해,\n참을인 하나.',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
              child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30)),
            child: const Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('忍',
                      style:
                          TextStyle(fontSize: 130, color: Color(0xFF617A3F))),
                  Text('참을 인을 써봅시다',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          )),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: onStart,
              child: const SizedBox(
                  width: double.infinity, child: Center(child: Text('시작하기')))),
        ]),
      ),
    );
  }
}

class WritingResult {
  final String text;
  final String category;
  final String moodEmoji;
  final String moodLabel;
  final StoryItem story;
  final bool shared;
  final String? storyFeedback;
  const WritingResult(
    this.text,
    this.category,
    this.moodEmoji,
    this.moodLabel,
    this.story,
    this.shared,
    this.storyFeedback,
  );
}

class WritingFlow extends StatefulWidget {
  final String storyStyle;
  final int todayWritingNumber;
  final ValueChanged<int>? onTabSelected;
  const WritingFlow({
    super.key,
    required this.storyStyle,
    this.todayWritingNumber = 1,
    this.onTabSelected,
  });
  @override
  State<WritingFlow> createState() => _WritingFlowState();
}

class _WritingFlowState extends State<WritingFlow> {
  int page = 0;
  final pageController = PageController();
  final textController = TextEditingController();
  final points = <Offset?>[];
  String category = '직장';
  String moodEmoji = '😤';
  String moodLabel = '많이 화남';
  StoryItem? selectedStory;
  String? storyFeedback;
  int strokeIndex = 0;
  Timer? strokeTimer;
  bool thirdWritingMessageShown = false;

  final categories = const ['직장', '고객', '가족', '연인', '친구', '타인', '나 자신', '기타'];
  final moods = const [
    ('🤬', '폭발 직전'),
    ('😤', '많이 화남'),
    ('😐', '답답함'),
    ('🙂', '조금 괜찮음')
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (var i = 1; i <= 7; i++) {
      precacheImage(AssetImage('assets/stroke/stroke_$i.png'), context);
    }
  }

  void next() {
    if (page == 2)
      selectedStory =
          recommendStory(textController.text, category, widget.storyStyle);
    if (page < 4) {
      if (page == 2) {
        unawaited(AppAudioService.instance.playStoryTransition());
      } else {
        unawaited(AppAudioService.instance.playButton());
      }
      setState(() => page++);
      pageController.animateToPage(page,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  void showStrokeOrder() {
    strokeTimer?.cancel();
    setState(() => strokeIndex = 0);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        strokeTimer ??= Timer.periodic(const Duration(milliseconds: 650), (t) {
          if (strokeIndex >= 6) {
            t.cancel();
            strokeTimer = null;
          } else {
            setDialogState(() => strokeIndex++);
          }
        });
        return AlertDialog(
          title: const Text('忍 획순 보기'),
          content: SizedBox.square(
            dimension: 240,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                'assets/stroke/stroke_${strokeIndex + 1}.png',
                key: ValueKey(strokeIndex),
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  strokeTimer?.cancel();
                  strokeTimer = null;
                  Navigator.pop(ctx);
                },
                child: const Text('닫기')),
          ],
        );
      }),
    );
  }

  Future<void> completeDrawing() async {
    if (widget.todayWritingNumber == 3 && !thirdWritingMessageShown) {
      thirdWritingMessageShown = true;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Text('🌿', style: TextStyle(fontSize: 38)),
          title: const Text('오늘 세 번째 참을인을 쓰셨네요.'),
          content: const Text(
            '오늘 주변이 조금 시끄러웠나 봅니다.\n그만큼 마음을 지키려고 애쓴 당신도 토닥여 주세요.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('마음 돌보기'),
            ),
          ],
        ),
      );
      if (!mounted) return;
    }
    next();
  }

  @override
  void dispose() {
    pageController.dispose();
    textController.dispose();
    strokeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: AppBottomArea(
          selectedIndex: 0, onSelected: widget.onTabSelected ?? (_) {}),
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _drawPage(),
          _recordPage(),
          _moodPage(),
          _storyPage(),
          _savePage(),
        ],
      ),
    );
  }

  Widget _drawPage() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(key: const ValueKey('writing-header'), children: [
            const Expanded(child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('참을인을 직접 써보세요.', maxLines: 1,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            )),
            const SizedBox(width: 6),
            TextButton.icon(
                onPressed: showStrokeOrder,
                icon: const Icon(Icons.animation),
                label: const Text('획순 보기')),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: GestureDetector(
              onPanStart: (d) {
                unawaited(AppAudioService.instance.playBrush());
                setState(() => points.add(d.localPosition));
              },
              onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
              onPanEnd: (_) => setState(() => points.add(null)),
              child: CustomPaint(
                painter: DrawPainter(
                  points,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
                child: Container(
                  key: const ValueKey('writing-canvas'),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                      child: Text('忍',
                          style: TextStyle(
                              fontSize: 150, color: Color(0x22617A3F)))),
                ),
              ),
            ),
          ),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => setState(points.clear),
                    child: const Text('지우기'))),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton(
                    onPressed: completeDrawing, child: const Text('다 적었습니다'))),
          ]),
        ]),
      );

  Widget _recordPage() =>
      ListView(padding: const EdgeInsets.all(20), children: [
        const Text('무슨 일이 있었나요?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
            controller: textController,
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: '예) 의욕만 앞서서 너무 실수가 잦다.',
                border: OutlineInputBorder())),
        const SizedBox(height: 24),
        const Text('누구 때문에 화가 났나요?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: category,
          items: categories
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => setState(() => category = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: next, child: const Text('다음')),
      ]);

  Widget _moodPage() => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('지금 감정은 어떤가요?',
                maxLines: 1,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              key: const ValueKey('mood-grid'),
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: moods
                  .map((m) => Card(
                        color: moodEmoji == m.$1
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            unawaited(AppAudioService.instance.playEmotion());
                            setState(() {
                              moodEmoji = m.$1;
                              moodLabel = m.$2;
                            });
                            next();
                          },
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m.$1,
                                    style: const TextStyle(fontSize: 28)),
                                FittedBox(
                                    child: Text(m.$2,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)))
                              ]),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ]),
      );

  Widget _storyPage() {
    final story = selectedStory ?? storyDb.first;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('여러분께\n드리고 싶은 이야기는요.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(story.theme)),
                    Text(story.title,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(story.body),
                    const SizedBox(height: 14),
                    Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text(story.quote,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                  ]))),
      const SizedBox(height: 14),
      const Text('이 이야기는 어땠나요?', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: [
        for (final option in const ['좋아요', '잘 모르겠어요', '별로에요']) ...[
          Expanded(
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              visualDensity: VisualDensity.compact,
              selected: storyFeedback == option,
              selectedColor: switch (option) {
                '좋아요' => const Color(0xFFCFE8B5),
                '잘 모르겠어요' => const Color(0xFFFFE8A8),
                _ => const Color(0xFFF2CBC5),
              },
              onSelected: (_) => setState(() => storyFeedback = option),
            ),
          ),
          if (option != '별로에요') const SizedBox(width: 6),
        ],
      ]),
      const SizedBox(height: 10),
      FilledButton(onPressed: next, child: const Text('다음')),
    ]);
  }

  Widget _savePage() {
    final story = selectedStory ?? storyDb.first;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('어떻게 기록할까요?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Text('내 기록으로 저장',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('달력에서 다시 볼 수 있습니다.'),
                FilledButton(
                    onPressed: () {
                      unawaited(AppAudioService.instance.playComplete());
                      Navigator.pop(
                          context,
                          WritingResult(
                              textController.text,
                              category,
                              moodEmoji,
                              moodLabel,
                              story,
                              false,
                              storyFeedback));
                    },
                    child: const Text('내 기록으로 저장')),
              ]))),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Text('공유하기',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('익명으로 공유하고 공감을 받을 수 있습니다.'),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6B84A),
                    foregroundColor: const Color(0xFF382B0A),
                  ),
                  onPressed: () async {
                    unawaited(AppAudioService.instance.playButton());
                    if (!AppFirebaseService.instance.hasLinkedAccount) {
                      final linked = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => AccountLinkPage(
                              onTabSelected: widget.onTabSelected)),
                      );
                      if (!mounted || linked != true) return;
                    }
                    Navigator.pop(
                      context,
                      WritingResult(textController.text, category, moodEmoji,
                          moodLabel, story, true, storyFeedback),
                    );
                  },
                  child: const Text('공유하기'),
                ),
              ]))),
    ]);
  }
}

class AccountLinkPage extends StatefulWidget {
  const AccountLinkPage({super.key, this.onTabSelected});
  final ValueChanged<int>? onTabSelected;

  @override
  State<AccountLinkPage> createState() => _AccountLinkPageState();
}

class _AccountLinkPageState extends State<AccountLinkPage> {
  bool signingIn = false;

  Future<void> _signInWithKakao() async {
    if (signingIn) return;
    setState(() => signingIn = true);
    try {
      await KakaoAuthService.instance.signIn();
      if (!mounted) return;
      final nickname = await AppFirebaseService.instance.loadNickname();
      if (!mounted) return;
      if (nickname == null) {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const AccountNicknamePage()),
        );
        if (!mounted || completed != true) return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('CANCELED')
          ? '카카오 로그인이 취소되었습니다.'
          : '카카오 로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar:
          AppBottomArea(selectedIndex: 3, onSelected: widget.onTabSelected ?? (_) {}),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.lock_person_outlined,
                size: 58, color: Color(0xFF617A3F)),
            const SizedBox(height: 18),
            const Text(
              '공유하려면\n계정 연동이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '카카오 계정으로 기록을 안전하게 보관하고, 내가 공유한 글을 관리할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 32),
            _accountButton(
              icon: '💬',
              label: '카카오로 계속하기',
              color: const Color(0xFFFFE812),
              foreground: Colors.black87,
              onPressed: signingIn ? null : _signInWithKakao,
            ),
            const SizedBox(height: 12),
            _accountButton(
              icon: 'G',
              label: 'Google로 계속하기 (준비 중)',
              color: Colors.white,
              foreground: Colors.black87,
              bordered: true,
              onPressed: null,
            ),
            const SizedBox(height: 12),
            _accountButton(
              icon: '●',
              label: 'Apple로 계속하기 (준비 중)',
              color: Colors.black,
              foreground: Colors.white,
              onPressed: null,
            ),
            const SizedBox(height: 18),
            const Text(
              '현재 카카오 계정 연동을 지원합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _accountButton({
    required String icon,
    required String label,
    required Color color,
    required Color foreground,
    bool bordered = false,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          side: bordered ? const BorderSide(color: Colors.black12) : null,
        ),
        onPressed: onPressed,
        icon: Text(icon, style: const TextStyle(fontWeight: FontWeight.bold)),
        label: Text(label),
      ),
    );
  }
}

class AccountNicknamePage extends StatefulWidget {
  const AccountNicknamePage({super.key});
  @override
  State<AccountNicknamePage> createState() => _AccountNicknamePageState();
}

class _AccountNicknamePageState extends State<AccountNicknamePage> {
  final controller = TextEditingController();
  bool saving = false;
  String? errorText;

  Future<void> _save() async {
    final nickname = controller.text.trim();
    if (nickname.length < 2 || nickname.length > 12 ||
        !RegExp(r'^[가-힣a-zA-Z0-9_]+$').hasMatch(nickname)) {
      setState(() => errorText = '한글, 영문, 숫자, 밑줄로 2~12자를 입력해주세요.');
      return;
    }
    setState(() { saving = true; errorText = null; });
    try {
      final claimed = await AppFirebaseService.instance.claimNickname(nickname);
      if (!mounted) return;
      if (!claimed) {
        setState(() => errorText = '이미 사용 중인 닉네임입니다.');
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => errorText = '닉네임을 저장하지 못했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('계정에서 사용할\n닉네임을 정해주세요.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('공감하기와 내 공유에서 사용할 이름입니다.'),
        const SizedBox(height: 24),
        TextField(controller: controller, maxLength: 12, decoration: InputDecoration(
          hintText: '예) 따뜻한마음', errorText: errorText, border: const OutlineInputBorder(),
        )),
        const Spacer(),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: saving ? null : _save,
          child: saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('닉네임 사용하기'),
        )),
      ]),
    )),
  );
}

class DrawPainter extends CustomPainter {
  final List<Offset?> points;
  final bool isDark;
  DrawPainter(this.points, {required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      if (start != null && end != null) {
        final distance = (end - start).distance;
        final width = (14.0 - distance * .22).clamp(5.5, 13.5);
        final color = isDark ? Colors.white : Colors.black;
        final feather = Paint()
          ..color = color.withValues(alpha: .16)
          ..strokeWidth = width + 3
          ..strokeCap = StrokeCap.round;
        final ink = Paint()
          ..color = color.withValues(alpha: .92)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(start, end, feather);
        canvas.drawLine(start, end, ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) => true;
}

StoryItem recommendStory(String text, String category, String style) {
  final lower = text.toLowerCase();
  final emotions = <String>{};
  if (RegExp(r'실수|자책|의욕|앞서|망쳤|못했|실패').hasMatch(lower))
    emotions.addAll(['자책', '실수']);
  if (RegExp(r'계속|곱씹|하루종일|반복').hasMatch(lower)) emotions.add('반추');
  if (RegExp(r'서운|섭섭|실망|상처').hasMatch(lower)) emotions.add('서운함');
  if (RegExp(r'카톡|문자|답장|보내|전화').hasMatch(lower)) emotions.add('충동');
  if (RegExp(r'억울|부당|누명|무시').hasMatch(lower)) emotions.add('억울함');

  StoryItem best = storyDb.first;
  var maxScore = -999;
  for (final story in storyDb) {
    var score = 0;
    for (final k in story.keywords) {
      if (lower.contains(k)) score += 5;
    }
    for (final e in story.emotions) {
      if (emotions.contains(e)) score += 7;
    }
    if (story.categories.contains(category)) score += 2;
    if (style != 'random' && story.styles.contains(style)) score += 3;
    if (score > maxScore) {
      maxScore = score;
      best = story;
    }
  }
  return best;
}

class RecordsPage extends StatefulWidget {
  final List<EmotionRecord> records;
  final ValueChanged<int>? onTabSelected;
  const RecordsPage({super.key, required this.records, this.onTabSelected});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int year = 2026;
  int month = 7;

  @override
  Widget build(BuildContext context) {
    final monthly = widget.records
        .where((r) => r.createdAt.year == year && r.createdAt.month == month)
        .toList();
    final counts = <String, int>{};
    for (final r in monthly) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    final top = counts.entries.isEmpty
        ? null
        : counts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('내 기록',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        DropdownButton<int>(
            value: year,
            items: [2026, 2027, 2028, 2029, 2030]
                .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                .toList(),
            onChanged: (v) => setState(() => year = v!)),
      ]),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () => setState(() {
                              month--;
                              if (month < 1) {
                                month = 12;
                                year--;
                              }
                            }),
                        icon: const Icon(Icons.chevron_left)),
                    Text('$year년 $month월',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => setState(() {
                              month++;
                              if (month > 12) {
                                month = 1;
                                year++;
                              }
                            }),
                        icon: const Icon(Icons.chevron_right)),
                  ]))),
      CalendarGrid(
          year: year,
          month: month,
          records: monthly,
          onTabSelected: widget.onTabSelected),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('월별 통계',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('이번달 참을인 횟수 : ${monthly.length}회'),
                    Text(
                        '가장 많이 화난 카테고리 : ${top?.key ?? '-'} ${top?.value ?? 0}회'),
                    Text(
                        '내가 공유한 사연 수 : ${monthly.where((r) => r.shared).length}개'),
                  ]))),
    ]));
  }
}

class CalendarGrid extends StatelessWidget {
  final int year, month;
  final List<EmotionRecord> records;
  final ValueChanged<int>? onTabSelected;
  const CalendarGrid(
      {super.key,
      required this.year,
      required this.month,
      required this.records,
      this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final days = DateTime(year, month + 1, 0).day;
    final cells = <Widget>[];
    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (var d = 1; d <= days; d++) {
      final list = records.where((r) => r.createdAt.day == d).toList();
      cells.add(InkWell(
        onTap: list.isEmpty
            ? null
            : () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => FractionallySizedBox(
                    heightFactor: .78,
                    child: RecordListSheet(
                        day: d, records: list, onTabSelected: onTabSelected),
                  ),
                ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: const TextStyle(fontSize: 12)),
            if (list.isNotEmpty) Text(representativeMoodEmoji(list)),
            if (list.length > 1)
              Text('${list.length}개', style: const TextStyle(fontSize: 9)),
          ]),
        ),
      ));
    }
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('일'),
                    Text('월'),
                    Text('화'),
                    Text('수'),
                    Text('목'),
                    Text('금'),
                    Text('토')
                  ]),
              GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  childAspectRatio: .9,
                  children: cells),
            ])));
  }
}

String representativeMoodEmoji(List<EmotionRecord> records) {
  if (records.isEmpty) return '';
  final counts = <String, int>{};
  for (final record in records) {
    counts[record.moodLabel] = (counts[record.moodLabel] ?? 0) + 1;
  }

  final maxCount = counts.values.reduce(max);
  final candidates = counts.entries
      .where((entry) => entry.value == maxCount)
      .map((entry) => entry.key)
      .toSet();
  final newest = [...records]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return newest
      .firstWhere((record) => candidates.contains(record.moodLabel))
      .moodEmoji;
}

class RecordListSheet extends StatelessWidget {
  final int day;
  final List<EmotionRecord> records;
  final ValueChanged<int>? onTabSelected;
  const RecordListSheet(
      {super.key,
      required this.day,
      required this.records,
      this.onTabSelected});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(18), children: [
        Text('$day일 기록 ${records.length}개',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ...records.map((r) => Card(
                child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => RecordDetailPage(
                        record: r, onTabSelected: onTabSelected)),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(r.moodEmoji,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('${r.moodLabel} · ${r.category}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                          const Icon(Icons.chevron_right),
                        ]),
                        const SizedBox(height: 10),
                        const Text('어떤 일이 있었나요?',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(r.text.trim().isEmpty ? '작성한 내용이 없습니다.' : r.text,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
            ))),
      ]));
}

class RecordDetailPage extends StatelessWidget {
  final EmotionRecord record;
  final ValueChanged<int>? onTabSelected;
  const RecordDetailPage({super.key, required this.record, this.onTabSelected});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('감정 기록 상세')),
        bottomNavigationBar: AppBottomArea(
            selectedIndex: 1, onSelected: onTabSelected ?? (_) {}),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.moodEmoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(record.moodLabel,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Text(
                  '${record.category} · ${record.createdAt.year}.${record.createdAt.month.toString().padLeft(2, '0')}.${record.createdAt.day.toString().padLeft(2, '0')}'),
            ]),
          )),
          const SizedBox(height: 10),
          const Text('어떤 일이 있었나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
                record.text.trim().isEmpty ? '작성한 내용이 없습니다.' : record.text),
          )),
          const SizedBox(height: 18),
          const Text('그날 받은 이야기',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Chip(label: Text(record.story.theme)),
              Text(record.story.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(record.story.body),
              const SizedBox(height: 12),
              Text(record.story.quote,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          )),
        ]),
      );
}

class EmpathyPage extends StatelessWidget {
  final List<SharedPost> posts;
  final String currentUserId;
  final void Function(SharedPost, int) onReact;
  final ValueChanged<SharedPost> onReport;
  const EmpathyPage(
      {super.key,
      required this.posts,
      required this.currentUserId,
      required this.onReact,
      required this.onReport});

  @override
  Widget build(BuildContext context) {
    final List<SharedPost>? best = posts.isEmpty
        ? null
        : ([...posts]..sort(
            (a, b) => b.reactions[0].compareTo(a.reactions[0]),
          ));
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('공감하기',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      if (posts.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Text(
              '아직 공유된 사연이 없습니다.\n첫 번째 따뜻한 공감을 기다리고 있어요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      if (best != null)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Chip(label: Text('오늘의 Best 사연')),
                      Chip(
                          label: Text(best.first.category.trim().isEmpty
                              ? '기타'
                              : best.first.category)),
                      Text('🤬 화난다 공감 ${best.first.reactions[0]}개',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(best.first.text),
                    ]))),
      ...posts.map((p) => SharedPostCard(
          post: p,
          mine: p.ownerId == currentUserId,
          onReact: onReact,
          onReport: onReport)),
    ]));
  }
}

class SharedPostCard extends StatelessWidget {
  final SharedPost post;
  final bool mine;
  final void Function(SharedPost, int) onReact;
  final ValueChanged<SharedPost> onReport;
  const SharedPostCard(
      {super.key,
      required this.post,
      required this.mine,
      required this.onReact,
      required this.onReport});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Chip(
                label:
                    Text(post.category.trim().isEmpty ? '기타' : post.category)),
            Text(post.text),
            if (mine)
              const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('내가 공유한 사연에는 직접 공감할 수 없습니다.',
                      style: TextStyle(fontSize: 12))),
            Row(
                children: List.generate(
                    3,
                    (i) => Expanded(
                        child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: OutlinedButton(
                              onPressed: mine || post.myReaction != null
                                  ? null
                                  : () => onReact(post, i),
                              child: Text(
                                  '${[
                                    '🤬',
                                    '😐',
                                    '🙂'
                                  ][i]}\n${post.reactions[i]}',
                                  textAlign: TextAlign.center),
                            ))))),
            TextButton.icon(
                onPressed: () => onReport(post),
                icon: const Icon(Icons.report, color: Colors.red),
                label: const Text('신고')),
          ])));
}

class MySharePage extends StatelessWidget {
  final List<SharedPost> posts;
  const MySharePage({super.key, required this.posts});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('내 공유',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        if (posts.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('아직 공유한 사연이 없습니다.'))),
        ...posts.map((p) => Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.category} · 내 공유',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(p.text),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('🤬 ${p.reactions[0]}'),
                            Text('😐 ${p.reactions[1]}'),
                            Text('🙂 ${p.reactions[2]}'),
                          ]),
                    ])))),
      ]));
}

class PositivePage extends StatefulWidget {
  const PositivePage({super.key});
  @override
  State<PositivePage> createState() => _PositivePageState();
}

class _PositivePageState extends State<PositivePage> {
  int index = 0;
  @override
  void initState() {
    super.initState();
    index = Random().nextInt(positiveStories.length);
  }

  void next() {
    setState(() => index = Random().nextInt(positiveStories.length));
  }

  @override
  Widget build(BuildContext context) {
    final s = positiveStories[index];
    return SafeArea(
        child: Column(children: [
      Expanded(child: ListView(
        key: const ValueKey('positive-story-scroll'),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        children: [
          const Text('오늘의 긍정',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title,
                            style: const TextStyle(
                                fontSize: 27, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(s.body,
                            style: const TextStyle(fontSize: 16, height: 1.65)),
                        const SizedBox(height: 14),
                        Text(s.quote,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]))),
        ],
      )),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          key: const ValueKey('positive-next-button'),
          width: double.infinity,
          height: 52,
          child: FilledButton(
              onPressed: () {
                unawaited(AppAudioService.instance.playButton());
                next();
              },
              child: const Text('다른 긍정 보기')),
        ),
      ),
    ]));
  }
}

class SettingsPage extends StatelessWidget {
  final String? nickname;
  final String? linkedAccountLabel;
  final bool darkMode, effectSound, backgroundMusic;
  final double effectVolume, backgroundVolume;
  final String storyStyle;
  final ValueChanged<bool> onDarkMode, onEffectSound, onBackgroundMusic;
  final ValueChanged<double> onEffectVolume, onBackgroundVolume;
  final ValueChanged<String> onStoryStyle;
  final Future<void> Function() onDeleteData, onDeleteAccount;
  const SettingsPage(
      {super.key,
      required this.nickname,
      required this.linkedAccountLabel,
      required this.darkMode,
      required this.effectSound,
      required this.backgroundMusic,
      required this.effectVolume,
      required this.backgroundVolume,
      required this.storyStyle,
      required this.onDarkMode,
      required this.onEffectSound,
      required this.onBackgroundMusic,
      required this.onEffectVolume,
      required this.onBackgroundVolume,
      required this.onStoryStyle,
      required this.onDeleteData,
      required this.onDeleteAccount});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('설정',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Card(
            child: Column(children: [
          ListTile(
              title: const Text('닉네임'),
              subtitle: Text(nickname ?? '계정 연동 후 설정할 수 있어요')),
          ListTile(
              title: const Text('연결 계정'),
              subtitle: Text(linkedAccountLabel ?? '아직 연결된 계정 없음')),
        ])),
        Card(
            child: Column(children: [
          SwitchListTile(
              title: const Text('☀ 다크모드'),
              value: darkMode,
              onChanged: onDarkMode),
          SwitchListTile(
              title: const Text('🔊 효과음'),
              value: effectSound,
              onChanged: onEffectSound),
          ListTile(
              title: const Text('효과음 음량'),
              subtitle: Slider(
                  value: effectVolume,
                  onChanged: effectSound ? onEffectVolume : null)),
          SwitchListTile(
              title: const Text('🎵 배경음악'),
              value: backgroundMusic,
              onChanged: onBackgroundMusic),
          ListTile(
              title: const Text('배경음악 음량'),
              subtitle: Slider(
                  value: backgroundVolume,
                  onChanged: backgroundMusic ? onBackgroundVolume : null)),
        ])),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌱 이야기 스타일',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      RadioGroup<String>(
                        groupValue: storyStyle,
                        onChanged: (value) {
                          if (value != null) onStoryStyle(value);
                        },
                        child: Column(
                          children: [
                            ('comfort', '위로 중심'),
                            ('growth', '성장 중심'),
                            ('reality', '현실 조언 중심'),
                            ('random', '랜덤'),
                          ]
                              .map((x) => RadioListTile<String>(
                                  value: x.$1, title: Text(x.$2)))
                              .toList(),
                        ),
                      ),
                    ]))),
        Card(
            child: Column(children: [
          ListTile(
              title: const Text('내 데이터 삭제'),
              trailing: TextButton(
                  onPressed: () => _confirm(context, '내 데이터를 삭제할까요?',
                      '휴대폰과 서버에 저장된 기록 및 공유 글이 삭제됩니다.', onDeleteData),
                  child: const Text('삭제'))),
          ListTile(
              title: const Text('회원탈퇴', style: TextStyle(color: Colors.red)),
              trailing: TextButton(
                  onPressed: () => _confirm(context, '회원탈퇴를 진행할까요?',
                      '연동 계정과 모든 데이터가 삭제됩니다.', onDeleteAccount),
                  child: const Text('탈퇴'))),
        ])),
      ]));

  static Future<void> _confirm(BuildContext context, String title, String body,
      Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('확인')),
              ],
            ));
    if (confirmed == true) await action();
  }
}
