import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_animations.dart';
import '../../core/services/api_service.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with TickerProviderStateMixin {
  int _selectedLang = 0;
  bool _running = false;
  bool _hasOutput = false;
  String _output = '';
  final _codeCtrl = TextEditingController();
  late final AnimationController _runCtrl =
      AnimationController(vsync: this, duration: 1500.ms);

  static const _langs = ['Rust', 'Go', 'Python', 'Node.js', 'TypeScript'];
  static const _langIcons = [
    Icons.memory_rounded,
    Icons.hub_rounded,
    Icons.code_rounded,
    Icons.storage_rounded,
    Icons.javascript_rounded,
  ];
  static const _langColors = [
    AppColors.tertiary,
    AppColors.primary,
    AppColors.secondary,
    AppColors.primary,
    AppColors.secondary,
  ];

  static const _starterCode = {
    'Rust': '''fn main() {
    let message = String::from("Hello, DevPulse!");
    println!("{}", message);
    
    // Try modifying this code
    let numbers = vec![1, 2, 3, 4, 5];
    let sum: i32 = numbers.iter().sum();
    println!("Sum: {}", sum);
}''',
    'Go': '''package main

import "fmt"

func main() {
    message := "Hello, DevPulse!"
    fmt.Println(message)
    
    // Try modifying this code
    numbers := []int{1, 2, 3, 4, 5}
    sum := 0
    for _, n := range numbers {
        sum += n
    }
    fmt.Printf("Sum: %d\\n", sum)
}''',
    'Python': '''def main():
    message = "Hello, DevPulse!"
    print(message)
    
    # Try modifying this code
    numbers = [1, 2, 3, 4, 5]
    total = sum(numbers)
    print(f"Sum: {total}")

if __name__ == "__main__":
    main()''',
    'Node.js': '''const message = "Hello, DevPulse!";
console.log(message);

// Try modifying this code
const numbers = [1, 2, 3, 4, 5];
const sum = numbers.reduce((a, b) => a + b, 0);
console.log(\`Sum: \${sum}\`);''',
    'TypeScript': '''const message: string = "Hello, DevPulse!";
console.log(message);

// Try modifying this code
const numbers: number[] = [1, 2, 3, 4, 5];
const sum: number = numbers.reduce((a, b) => a + b, 0);
console.log(\`Sum: \${sum}\`);''',
  };

  @override
  void initState() {
    super.initState();
    _codeCtrl.text = _starterCode[_langs[_selectedLang]] ?? '';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _runCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() { _running = true; _hasOutput = false; _output = ''; });
    _runCtrl.forward(from: 0);

    final lang = _langs[_selectedLang];
    if (lang != 'Python') {
      await Future.delayed(800.ms);
      if (mounted) {
        setState(() {
          _output = 'Only Python is supported in the sandbox.\nPlease switch to Python to run code.';
          _running = false;
          _hasOutput = true;
        });
      }
      return;
    }

    try {
      final result = await ApiService.executeCode('python', _codeCtrl.text);
      if (!mounted) return;
      final stdout = result['stdout'] as String? ?? '';
      final stderr = result['stderr'] as String? ?? '';
      final exitCode = result['exit_code'] as int? ?? 0;
      final error = result['error'] as String?;
      final buf = StringBuffer();
      if (stdout.isNotEmpty) buf.write(stdout);
      if (stderr.isNotEmpty) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write('STDERR:\n$stderr');
      }
      if (error != null) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write('ERROR: $error');
      }
      if (exitCode != 0 && buf.isEmpty) {
        buf.write('Process finished with exit code $exitCode');
      }
      if (buf.isEmpty) buf.write('(no output)');
      setState(() { _output = buf.toString(); _running = false; _hasOutput = true; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _output = 'Error connecting to sandbox:\n$e';
        _running = false;
        _hasOutput = true;
      });
    }
  }

  void _selectLang(int i) {
    setState(() {
      _selectedLang = i;
      _codeCtrl.text = _starterCode[_langs[i]] ?? '';
      _hasOutput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = _langs[_selectedLang];
    final color = _langColors[_selectedLang];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(lang, color),
      body: Column(
        children: [
          // Language tabs
          _buildLangTabs(),
          // Editor area
          Expanded(
            flex: _hasOutput ? 3 : 5,
            child: _buildEditor(),
          ),
          // Run button
          _buildRunBar(color),
          // Output panel
          if (_hasOutput || _running)
            Expanded(
              flex: 2,
              child: _buildOutput(lang),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String lang, Color color) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainer.withValues(alpha: 0.95),
      elevation: 0,
      leading: const Icon(Icons.terminal, color: AppColors.primary, size: 22),
      title: Row(
        children: [
          Text('DevPulse',
              style: AppTextStyles.displayLgMobile(color: AppColors.primary)
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Editor',
                style: AppTextStyles.labelSm(color: color)
                    .copyWith(fontSize: 11)),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.format_align_left_rounded,
              color: AppColors.onSurfaceVariant, size: 20),
          onPressed: () {},
          tooltip: 'Format',
        ),
        IconButton(
          icon: const Icon(Icons.content_copy_rounded,
              color: AppColors.onSurfaceVariant, size: 20),
          onPressed: () {},
          tooltip: 'Copy',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildLangTabs() {
    return Container(
      height: 44,
      color: AppColors.surfaceContainerLow,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _langs.length,
        itemBuilder: (_, i) {
          final active = i == _selectedLang;
          final c = _langColors[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectLang(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? c.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active
                        ? c.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_langIcons[i], color: active ? c : AppColors.onSurfaceVariant, size: 14),
                    const SizedBox(width: 5),
                    Text(_langs[i],
                        style: AppTextStyles.labelSm(
                          color: active ? c : AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          // Line numbers + code
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line numbers
                Container(
                  width: 40,
                  color: const Color(0xFF0A0F16),
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: Column(
                    children: List.generate(20, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.codeBlock(
                                color: AppColors.onSurfaceVariant
                                    .withValues(alpha: 0.3))
                            .copyWith(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    )),
                  ),
                ),
                // Code input
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    maxLines: null,
                    expands: true,
                    style: AppTextStyles.codeBlock(color: AppColors.onSurface)
                        .copyWith(fontSize: 13, height: 1.6),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildRunBar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Status
          Row(
            children: [
              NeonPulse(
                color: _running ? AppColors.secondary : AppColors.primary,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _running ? AppColors.secondary : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _running ? 'Running...' : _hasOutput ? 'Completed' : 'Ready',
                style: AppTextStyles.labelSm(
                  color: _running
                      ? AppColors.secondary
                      : _hasOutput
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // Run button
          GestureDetector(
            onTap: _running ? null : _run,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _running
                    ? color.withValues(alpha: 0.3)
                    : color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: _running
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_running)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _selectedLang == 0 || _selectedLang == 2
                            ? AppColors.onSecondary
                            : AppColors.onPrimary,
                      ),
                    )
                  else
                    Icon(Icons.play_arrow_rounded,
                        color: _selectedLang == 0 || _selectedLang == 2
                            ? AppColors.onSecondary
                            : AppColors.onPrimary,
                        size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _running ? 'Running' : 'Run',
                    style: AppTextStyles.labelSm(
                      color: _selectedLang == 0 || _selectedLang == 2
                          ? AppColors.onSecondary
                          : AppColors.onPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput(String lang) {
    return Container(
      color: const Color(0xFF0A0F16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Output header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: AppColors.onSurfaceVariant, size: 14),
                const SizedBox(width: 8),
                Text('OUTPUT',
                    style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)
                        .copyWith(letterSpacing: 1.5, fontSize: 11)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _hasOutput = false),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.onSurfaceVariant, size: 16),
                ),
              ],
            ),
          ),
          // Output content
          Expanded(
            child: _running
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _runCtrl,
                          builder: (_, __) => CircularProgressIndicator(
                            value: _runCtrl.value,
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Compiling...',
                            style: AppTextStyles.codeBlock(
                                    color: AppColors.onSurfaceVariant)
                                .copyWith(fontSize: 12)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _output,
                      style: AppTextStyles.codeBlock(color: AppColors.secondary)
                          .copyWith(fontSize: 13, height: 1.7),
                    ).animate().fadeIn(duration: 400.ms),
                  ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, end: 0, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}
