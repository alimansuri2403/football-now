import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/shimmer_loading.dart';

class FanChallengesScreen extends ConsumerStatefulWidget {
  const FanChallengesScreen({super.key});

  @override
  ConsumerState<FanChallengesScreen> createState() => _FanChallengesScreenState();
}

class _FanChallengesScreenState extends ConsumerState<FanChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Quiz State
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  int _score = 0;
  bool _quizFinished = false;

  // Match predictions state
  Map<String, Map<String, dynamic>> _predictions = {}; // matchId -> {'prediction': 'H'/'D'/'A', 'homeScore': 0, 'awayScore': 0}
  int _userPoints = 30; // Mock base points

  // Trivia questions
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How many teams play in FIFA WC 2026?',
      'options': ['32', '40', '48', '64'],
      'correctIndex': 2,
    },
    {
      'question': 'Which country hosts the Final of FIFA World Cup 2026?',
      'options': ['Canada', 'Mexico', 'USA (MetLife Stadium)', 'Brazil'],
      'correctIndex': 2,
    },
    {
      'question': 'Who won the FIFA World Cup in 2022?',
      'options': ['France', 'Argentina', 'Croatia', 'Morocco'],
      'correctIndex': 1,
    },
    {
      'question': 'What is the most goals scored in a World Cup final match by a single player?',
      'options': ['2 goals', '3 goals (Geoff Hurst, Mbappe)', '4 goals', '5 goals'],
      'correctIndex': 1,
    },
    {
      'question': 'Which stadium hosts the opening match of the 2026 World Cup?',
      'options': ['MetLife Stadium', 'Estadio Azteca', 'BC Place', 'Mercedes-Benz Stadium'],
      'correctIndex': 1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPredictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('fan_predictions');
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(data);
        setState(() {
          _predictions = decoded.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
          _userPoints = 30 + (_predictions.length * 10); // 10 points per prediction submitted
        });
      } catch (_) {}
    }
  }

  Future<void> _savePrediction(String matchId, String outcome, int homeScore, int awayScore) async {
    setState(() {
      _predictions[matchId] = {
        'prediction': outcome,
        'homeScore': homeScore,
        'awayScore': awayScore,
        'submitted': true,
      };
      _userPoints = 30 + (_predictions.length * 10);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fan_predictions', json.encode(_predictions));
  }

  void _handleQuizAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      if (index == _questions[_currentQuestionIndex]['correctIndex']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
      } else {
        _quizFinished = true;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _answered = false;
      _score = 0;
      _quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fan Challenges'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Daily Quiz', icon: Icon(Icons.quiz)),
            Tab(text: 'Match Predictor', icon: Icon(Icons.insights)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizTab(theme),
          _buildPredictorTab(theme),
        ],
      ),
    );
  }

  Widget _buildQuizTab(ThemeData theme) {
    if (_quizFinished) {
      final isPerfect = _score == _questions.length;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPerfect ? '🏆 Perfect Score!' : '🎉 Quiz Completed!',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'You got $_score out of ${_questions.length} questions correct.',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _resetQuiz,
              ),
            ],
          ),
        ),
      );
    }

    final q = _questions[_currentQuestionIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                'Score: $_score',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 32),

          // Question Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(context: context, radius: 24),
            child: Text(
              q['question'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...List.generate(4, (index) {
            final option = q['options'][index];
            final isCorrect = index == q['correctIndex'];
            final isSelected = index == _selectedAnswerIndex;

            Color? btnColor;
            Color? textColor;
            if (_answered) {
              if (isCorrect) {
                btnColor = AppTheme.success.withOpacity(0.25);
                textColor = AppTheme.success;
              } else if (isSelected) {
                btnColor = AppTheme.liveColor.withOpacity(0.25);
                textColor = AppTheme.liveColor;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _answered
                          ? (isCorrect ? AppTheme.success : (isSelected ? AppTheme.liveColor : Colors.transparent))
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  elevation: 0,
                ),
                onPressed: () => _handleQuizAnswer(index),
                child: Text(
                  option,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Next button
          if (_answered)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentQuestionIndex == _questions.length - 1 ? 'Finish Quiz' : 'Next Question',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPredictorTab(ThemeData theme) {
    final matchState = ref.watch(matchProvider);
    final upcoming = matchState.allMatches
        .where((m) => m.status == MatchStatus.scheduled)
        .toList();

    return Column(
      children: [
        // Points banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          color: theme.colorScheme.primary.withOpacity(0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'Your Points:',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '$_userPoints pts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: matchState.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ShimmerLoading(child: ShimmerLoading.cardList(count: 4)),
                )
              : upcoming.isEmpty
                  ? const Center(child: Text('No upcoming matches available to predict.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: upcoming.length,
                      itemBuilder: (context, index) {
                        final match = upcoming[index];
                        final pred = _predictions[match.id];
                        final isPredicted = pred != null;

                        return _PredictorMatchCard(
                          match: match,
                          theme: theme,
                          isPredicted: isPredicted,
                          prediction: pred,
                          onPredict: (outcome, homeScore, awayScore) {
                            _savePrediction(match.id, outcome, homeScore, awayScore);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _PredictorMatchCard extends StatefulWidget {
  final Match match;
  final ThemeData theme;
  final bool isPredicted;
  final Map<String, dynamic>? prediction;
  final Function(String outcome, int homeScore, int awayScore) onPredict;

  const _PredictorMatchCard({
    required this.match,
    required this.theme,
    required this.isPredicted,
    required this.prediction,
    required this.onPredict,
  });

  @override
  State<_PredictorMatchCard> createState() => _PredictorMatchCardState();
}

class _PredictorMatchCardState extends State<_PredictorMatchCard> {
  String _selectedOutcome = 'H';
  int _homeScore = 1;
  int _awayScore = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isPredicted && widget.prediction != null) {
      _selectedOutcome = widget.prediction!['prediction'] ?? 'H';
      _homeScore = widget.prediction!['homeScore'] ?? 1;
      _awayScore = widget.prediction!['awayScore'] ?? 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(context: context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match timing & venue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d • h:mm a').format(widget.match.kickoffTime),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (widget.isPredicted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Submitted!',
                    style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Match teams details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        AppConstants.getFlagUrl(widget.match.homeTeam.flagCode),
                        width: 44,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.match.homeTeam.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),

              // Away Team
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        AppConstants.getFlagUrl(widget.match.awayTeam.flagCode),
                        width: 44,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.match.awayTeam.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Scoreline Picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Home Score Controls
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.isPredicted ? null : () {
                  if (_homeScore > 0) setState(() => _homeScore--);
                },
              ),
              Text(
                '$_homeScore',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: widget.isPredicted ? null : () {
                  if (_homeScore < 9) setState(() => _homeScore++);
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

              // Away Score Controls
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: widget.isPredicted ? null : () {
                  if (_awayScore > 0) setState(() => _awayScore--);
                },
              ),
              Text(
                '$_awayScore',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: widget.isPredicted ? null : () {
                  if (_awayScore < 9) setState(() => _awayScore++);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Win/Draw/Loss Picker
          Row(
            children: [
              Expanded(
                child: _buildOutcomeBtn('H', widget.match.homeTeam.code, theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOutcomeBtn('D', 'DRAW', theme),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOutcomeBtn('A', widget.match.awayTeam.code, theme),
              ),
            ],
          ),

          if (!widget.isPredicted) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => widget.onPredict(_selectedOutcome, _homeScore, _awayScore),
              child: const Text('Submit Prediction'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutcomeBtn(String type, String label, ThemeData theme) {
    final isSelected = _selectedOutcome == type;
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? theme.colorScheme.primary : Colors.transparent,
        foregroundColor: isSelected ? theme.colorScheme.onPrimary : (isDark ? Colors.white : Colors.black87),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: widget.isPredicted ? null : () {
        setState(() => _selectedOutcome = type);
      },
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
