import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'data/positive_stories.dart';
import 'data/story_db.dart';
import 'models.dart';

void main() => runApp(const ChameulinApp());

class ChameulinApp extends StatefulWidget {
  const ChameulinApp({super.key});
  @override
  State<ChameulinApp> createState() => _ChameulinAppState();
}

class _ChameulinAppState extends State<ChameulinApp> {
  bool darkMode = false;
  bool effectSound = true;
  bool backgroundMusic = true;
  String storyStyle = 'random';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '참을인',
      debugShowCheckedModeBanner: false,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF617A3F)),
        scaffoldBackgroundColor: const Color(0xFFFBFCF2),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8FAA66),
          brightness: Brightness.dark,
        ),
      ),
      home: AppShell(
        darkMode: darkMode,
        effectSound: effectSound,
        backgroundMusic: backgroundMusic,
        storyStyle: storyStyle,
        onDarkMode: (v) => setState(() => darkMode = v),
        onEffectSound: (v) => setState(() => effectSound = v),
        onBackgroundMusic: (v) => setState(() => backgroundMusic = v),
        onStoryStyle: (v) => setState(() => storyStyle = v),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final bool darkMode;
  final bool effectSound;
  final bool backgroundMusic;
  final String storyStyle;
  final ValueChanged<bool> onDarkMode;
  final ValueChanged<bool> onEffectSound;
  final ValueChanged<bool> onBackgroundMusic;
  final ValueChanged<String> onStoryStyle;

  const AppShell({
    super.key,
    required this.darkMode,
    required this.effectSound,
    required this.backgroundMusic,
    required this.storyStyle,
    required this.onDarkMode,
    required this.onEffectSound,
    required this.onBackgroundMusic,
    required this.onStoryStyle,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String? nickname;
  int tabIndex = 0;
  final String currentUserId = 'local-user';
  final records = <EmotionRecord>[];
  final sharedPosts = <SharedPost>[
    SharedPost(
      id: 'sample-1',
      ownerId: 'other-1',
      category: '직장',
      text: '회의에서 한마디 들은 뒤 하루 종일 기분이 상했습니다.',
      moodEmoji: '😤',
      createdAt: DateTime.now(),
      reactions: [42, 11, 6],
    ),
    SharedPost(
      id: 'sample-2',
      ownerId: 'other-2',
      category: '고객',
      text: '무리한 요구를 반복해서 받아서 마음이 너무 힘들었습니다.',
      moodEmoji: '🤬',
      createdAt: DateTime.now(),
      reactions: [88, 12, 4],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (nickname == null) {
      return SplashNicknameFlow(onDone: (value) => setState(() => nickname = value));
    }

    final pages = [
      HomePage(onStart: _startWriting),
      RecordsPage(records: records),
      EmpathyPage(
        posts: sharedPosts,
        currentUserId: currentUserId,
        onReact: _react,
        onReport: _report,
      ),
      MySharePage(posts: sharedPosts.where((p) => p.ownerId == currentUserId).toList()),
      const PositivePage(),
      SettingsPage(
        nickname: nickname!,
        darkMode: widget.darkMode,
        effectSound: widget.effectSound,
        backgroundMusic: widget.backgroundMusic,
        storyStyle: widget.storyStyle,
        onDarkMode: widget.onDarkMode,
        onEffectSound: widget.onEffectSound,
        onBackgroundMusic: widget.onBackgroundMusic,
        onStoryStyle: widget.onStoryStyle,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: tabIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => setState(() => tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: '내 기록'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: '공감'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), label: '내 공유'),
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: '긍정'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
      ),
    );
  }

  Future<void> _startWriting() async {
    final result = await Navigator.of(context).push<WritingResult>(
      MaterialPageRoute(builder: (_) => WritingFlow(storyStyle: widget.storyStyle)),
    );
    if (result == null) return;
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
  }

  void _react(SharedPost post, int reactionIndex) {
    if (post.ownerId == currentUserId || post.myReaction != null) return;
    setState(() {
      post.myReaction = reactionIndex;
      post.reactions[reactionIndex]++;
    });
  }

  void _report(SharedPost post) {
    setState(() => post.reportCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고가 접수되었습니다. 운영자 검토 후 처리됩니다.')),
    );
  }
}

class SplashNicknameFlow extends StatefulWidget {
  final ValueChanged<String> onDone;
  const SplashNicknameFlow({super.key, required this.onDone});

  @override
  State<SplashNicknameFlow> createState() => _SplashNicknameFlowState();
}

class _SplashNicknameFlowState extends State<SplashNicknameFlow> {
  int step = 0;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => step = 1);
    });
  }

  void submit() {
    final nick = controller.text.trim().isEmpty ? '화가많은화가' : controller.text.trim();
    setState(() => step = 2);
    Timer(const Duration(seconds: 1), () => widget.onDone(nick));
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('忍', style: TextStyle(fontSize: 130, color: Color(0xFF617A3F))),
            SizedBox(height: 8),
            Text('참을인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
            Text('반가워요.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Chip(label: Text('처음 한 번')),
            const SizedBox(height: 24),
            const Text('참을인에서 사용할\n닉네임을 정해주세요.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('실명 대신 앱 안에서만 사용할 이름입니다.'),
            const SizedBox(height: 28),
            TextField(controller: controller, decoration: const InputDecoration(hintText: '예) 화가많은화가', border: OutlineInputBorder())),
            const Spacer(),
            FilledButton(onPressed: submit, child: const SizedBox(width: double.infinity, child: Center(child: Text('시작하기')))),
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
          const Text('참을인', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 26),
          const Text('후회할 말 전에\n참을 인 하나.', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(30)),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('忍', style: TextStyle(fontSize: 130, color: Color(0xFF617A3F))),
              Text('참을 인을 써봅시다', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
          const Spacer(),
          FilledButton(onPressed: onStart, child: const SizedBox(width: double.infinity, child: Center(child: Text('시작하기')))),
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
  const WritingResult(this.text, this.category, this.moodEmoji, this.moodLabel, this.story, this.shared);
}

class WritingFlow extends StatefulWidget {
  final String storyStyle;
  const WritingFlow({super.key, required this.storyStyle});
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
  int strokeIndex = 0;
  Timer? strokeTimer;

  final categories = const ['직장', '고객', '가족', '연인', '친구', '타인', '나 자신', '기타'];
  final moods = const [('🤬','폭발 직전'), ('😤','많이 화남'), ('😐','답답함'), ('🙂','조금 괜찮음')];

  void next() {
    if (page == 2) selectedStory = recommendStory(textController.text, category, widget.storyStyle);
    if (page < 4) {
      setState(() => page++);
      pageController.animateToPage(page, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
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
          content: Image.asset('assets/stroke/stroke_${strokeIndex + 1}.png', width: 240, height: 240, fit: BoxFit.contain),
          actions: [
            TextButton(onPressed: () { strokeTimer?.cancel(); strokeTimer = null; Navigator.pop(ctx); }, child: const Text('닫기')),
          ],
        );
      }),
    );
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
      appBar: AppBar(title: Text('${page + 1} / 5')),
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
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('참을 인을\n직접 써보세요.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        TextButton.icon(onPressed: showStrokeOrder, icon: const Icon(Icons.animation), label: const Text('획순 보기')),
      ]),
      const SizedBox(height: 16),
      Expanded(
        child: GestureDetector(
          onPanStart: (d) => setState(() => points.add(d.localPosition)),
          onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
          onPanEnd: (_) => setState(() => points.add(null)),
          child: CustomPaint(
            painter: DrawPainter(points),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(24)),
              child: const Center(child: Text('忍', style: TextStyle(fontSize: 150, color: Color(0x22617A3F)))),
            ),
          ),
        ),
      ),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(points.clear), child: const Text('지우기'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: next, child: const Text('다 적었습니다'))),
      ]),
    ]),
  );

  Widget _recordPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('무슨 일이 있었나요?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    TextField(controller: textController, maxLines: 6, decoration: const InputDecoration(hintText: '예) 의욕만 앞서서 너무 실수가 잦다.', border: OutlineInputBorder())),
    const SizedBox(height: 24),
    const Text('누구 때문에 화가 났나요?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      value: category,
      items: categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => setState(() => category = v!),
      decoration: const InputDecoration(border: OutlineInputBorder()),
    ),
    const SizedBox(height: 20),
    FilledButton(onPressed: next, child: const Text('다음')),
  ]);

  Widget _moodPage() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('지금 감정은\n어떤가요?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          children: moods.map((m) => Card(
            color: moodEmoji == m.$1 ? Theme.of(context).colorScheme.primaryContainer : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () { setState(() { moodEmoji = m.$1; moodLabel = m.$2; }); next(); },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(m.$1, style: const TextStyle(fontSize: 40)), Text(m.$2, style: const TextStyle(fontWeight: FontWeight.bold))]),
            ),
          )).toList(),
        ),
      ),
    ]),
  );

  Widget _storyPage() {
    final story = selectedStory ?? storyDb.first;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('여러분께\n드리고 싶은 이야기는요.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Chip(label: Text(story.theme)),
        Text(story.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(story.body),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Text(story.quote, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]))),
      const SizedBox(height: 14),
      const Text('이 이야기는 어땠나요?', style: TextStyle(fontWeight: FontWeight.bold)),
      Wrap(spacing: 8, children: const [Chip(label: Text('마음에 남았어요')), Chip(label: Text('잘 모르겠어요')), Chip(label: Text('도움이 안 됐어요'))]),
      FilledButton(onPressed: next, child: const Text('다음')),
    ]);
  }

  Widget _savePage() {
    final story = selectedStory ?? storyDb.first;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('어떻게 기록할까요?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        const Text('내 기록으로 저장', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('달력에서 다시 볼 수 있습니다.'),
        FilledButton(onPressed: () => Navigator.pop(context, WritingResult(textController.text, category, moodEmoji, moodLabel, story, false)), child: const Text('내 기록으로 저장')),
      ]))),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
        const Text('공유하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('익명으로 공유하고 공감을 받을 수 있습니다.'),
        OutlinedButton(onPressed: () => Navigator.pop(context, WritingResult(textController.text, category, moodEmoji, moodLabel, story, true)), child: const Text('공유하기')),
      ]))),
    ]);
  }
}

class DrawPainter extends CustomPainter {
  final List<Offset?> points;
  DrawPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF617A3F)..strokeWidth = 7..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }
  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) => true;
}

StoryItem recommendStory(String text, String category, String style) {
  final lower = text.toLowerCase();
  final emotions = <String>{};
  if (RegExp(r'실수|자책|의욕|앞서|망쳤|못했|실패').hasMatch(lower)) emotions.addAll(['자책', '실수']);
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
  const RecordsPage({super.key, required this.records});
  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  int year = 2026;
  int month = 7;

  @override
  Widget build(BuildContext context) {
    final monthly = widget.records.where((r) => r.createdAt.year == year && r.createdAt.month == month).toList();
    final counts = <String, int>{};
    for (final r in monthly) counts[r.category] = (counts[r.category] ?? 0) + 1;
    final top = counts.entries.isEmpty ? null : counts.entries.reduce((a,b) => a.value >= b.value ? a : b);

    return SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('내 기록', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        DropdownButton<int>(value: year, items: [2026,2027,2028,2029,2030].map((y) => DropdownMenuItem(value:y, child: Text('$y년'))).toList(), onChanged: (v) => setState(() => year=v!)),
      ]),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(onPressed: () => setState(() { month--; if(month<1){month=12;year--;} }), icon: const Icon(Icons.chevron_left)),
        Text('$year년 $month월', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(onPressed: () => setState(() { month++; if(month>12){month=1;year++;} }), icon: const Icon(Icons.chevron_right)),
      ]))),
      CalendarGrid(year: year, month: month, records: monthly),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('월별 통계', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('이번달 참을인 횟수 : ${monthly.length}회'),
        Text('가장 많이 화난 카테고리 : ${top?.key ?? '-'} ${top?.value ?? 0}회'),
        Text('내가 공유한 사연 수 : ${monthly.where((r)=>r.shared).length}개'),
      ]))),
    ]));
  }
}

class CalendarGrid extends StatelessWidget {
  final int year, month;
  final List<EmotionRecord> records;
  const CalendarGrid({super.key, required this.year, required this.month, required this.records});

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final days = DateTime(year, month + 1, 0).day;
    final cells = <Widget>[];
    for (var i=0;i<firstWeekday;i++) cells.add(const SizedBox());
    for (var d=1;d<=days;d++) {
      final list = records.where((r)=>r.createdAt.day==d).toList();
      cells.add(InkWell(
        onTap: list.isEmpty ? null : () => showModalBottomSheet(context: context, builder: (_) => RecordListSheet(day:d, records:list)),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: const TextStyle(fontSize: 12)),
            if(list.isNotEmpty) Text(list.first.moodEmoji),
            if(list.length>1) Text('${list.length}개', style: const TextStyle(fontSize: 9)),
          ]),
        ),
      ));
    }
    return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
      const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('일'),Text('월'),Text('화'),Text('수'),Text('목'),Text('금'),Text('토')]),
      GridView.count(shrinkWrap:true, physics:const NeverScrollableScrollPhysics(), crossAxisCount:7, childAspectRatio:.9, children:cells),
    ])));
  }
}

class RecordListSheet extends StatelessWidget {
  final int day;
  final List<EmotionRecord> records;
  const RecordListSheet({super.key, required this.day, required this.records});
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
    Text('$day일 기록 ${records.length}개', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    ...records.map((r)=>Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('${r.moodEmoji} ${r.category}', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(r.text),
      const SizedBox(height:8),
      Text(r.story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(r.story.quote),
    ])))),
  ]));
}

class EmpathyPage extends StatelessWidget {
  final List<SharedPost> posts;
  final String currentUserId;
  final void Function(SharedPost,int) onReact;
  final ValueChanged<SharedPost> onReport;
  const EmpathyPage({super.key, required this.posts, required this.currentUserId, required this.onReact, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final best = posts.isEmpty ? null : [...posts]..sort((a,b)=>b.reactions[0].compareTo(a.reactions[0]));
    return SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('공감하기', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      if(best != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Chip(label: Text('오늘의 Best 사연')),
        Text('🤬 화난다 공감 ${best.first.reactions[0]}개', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(best.first.text),
      ]))),
      ...posts.map((p)=>SharedPostCard(post:p, mine:p.ownerId==currentUserId, onReact:onReact, onReport:onReport)),
    ]));
  }
}

class SharedPostCard extends StatelessWidget {
  final SharedPost post;
  final bool mine;
  final void Function(SharedPost,int) onReact;
  final ValueChanged<SharedPost> onReport;
  const SharedPostCard({super.key, required this.post, required this.mine, required this.onReact, required this.onReport});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Chip(label: Text('${post.category} · ${mine ? '내 공유' : '익명'}')),
    Text(post.text),
    if(mine) const Padding(padding: EdgeInsets.only(top:8), child: Text('내가 공유한 사연에는 직접 공감할 수 없습니다.', style: TextStyle(fontSize:12))),
    Row(children: List.generate(3,(i)=>Expanded(child: Padding(padding: const EdgeInsets.all(3), child: OutlinedButton(
      onPressed: mine || post.myReaction != null ? null : ()=>onReact(post,i),
      child: Text('${['🤬','😐','🙂'][i]}\n${post.reactions[i]}', textAlign:TextAlign.center),
    ))))),
    TextButton.icon(onPressed: ()=>onReport(post), icon: const Icon(Icons.siren, color:Colors.red), label: const Text('신고')),
  ])));

class MySharePage extends StatelessWidget {
  final List<SharedPost> posts;
  const MySharePage({super.key, required this.posts});
  @override
  Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.all(18), children:[
    const Text('내 공유', style: TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
    if(posts.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('아직 공유한 사연이 없습니다.'))),
    ...posts.map((p)=>Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text('${p.category} · 내 공유', style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(p.text),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
        Text('🤬 ${p.reactions[0]}'),Text('😐 ${p.reactions[1]}'),Text('🙂 ${p.reactions[2]}'),
      ]),
    ])))),
  ]));
}

class PositivePage extends StatefulWidget {
  const PositivePage({super.key});
  @override
  State<PositivePage> createState()=>_PositivePageState();
}
class _PositivePageState extends State<PositivePage>{
  int index=0;
  @override
  void initState(){super.initState(); index=Random().nextInt(positiveStories.length);}
  void next(){setState(()=>index=Random().nextInt(positiveStories.length));}
  @override
  Widget build(BuildContext context){
    final s=positiveStories[index];
    return SafeArea(child: ListView(padding: const EdgeInsets.all(20), children:[
      const Text('오늘의 긍정', style: TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      const SizedBox(height:20),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Chip(label:Text('${s.icon} 긍정')),
        Text(s.title, style: const TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),
        Text(s.body),
        const SizedBox(height:14),
        Text(s.quote, style: const TextStyle(fontWeight:FontWeight.bold)),
      ]))),
      FilledButton(onPressed:next, child:const Text('다른 긍정 보기')),
    ]));
  }
}

class SettingsPage extends StatelessWidget {
  final String nickname;
  final bool darkMode,effectSound,backgroundMusic;
  final String storyStyle;
  final ValueChanged<bool> onDarkMode,onEffectSound,onBackgroundMusic;
  final ValueChanged<String> onStoryStyle;
  const SettingsPage({super.key,required this.nickname,required this.darkMode,required this.effectSound,required this.backgroundMusic,required this.storyStyle,required this.onDarkMode,required this.onEffectSound,required this.onBackgroundMusic,required this.onStoryStyle});
  @override
  Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.all(18),children:[
    const Text('설정',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
    Card(child:Column(children:[
      ListTile(title:const Text('닉네임'),subtitle:Text(nickname)),
      const ListTile(title:Text('연결 계정'),subtitle:Text('아직 연결된 계정 없음')),
    ])),
    Card(child:Column(children:[
      SwitchListTile(title:const Text('☀ 다크모드'),value:darkMode,onChanged:onDarkMode),
      SwitchListTile(title:const Text('🔊 효과음'),subtitle:const Text('추후 음원 연결'),value:effectSound,onChanged:onEffectSound),
      SwitchListTile(title:const Text('🎵 배경음악'),subtitle:const Text('추후 음원 연결'),value:backgroundMusic,onChanged:onBackgroundMusic),
    ])),
    Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('🌱 AI 이야기 스타일',style:TextStyle(fontWeight:FontWeight.bold)),
      ...[
        ('comfort','위로 중심'),('growth','성장 중심'),('reality','현실 조언 중심'),('random','랜덤')
      ].map((x)=>RadioListTile<String>(value:x.$1,groupValue:storyStyle,onChanged:(v)=>onStoryStyle(v!),title:Text(x.$2))),
    ]))),
    Card(child:Column(children:[
      ListTile(title:const Text('내 데이터 삭제'),trailing:TextButton(onPressed:(){},child:const Text('삭제'))),
      ListTile(title:const Text('회원탈퇴',style:TextStyle(color:Colors.red)),trailing:TextButton(onPressed:(){},child:const Text('탈퇴'))),
    ])),
  ]));
}
