import 'daily_quote.dart';
import 'daily_quotes_001_100.dart';
import 'daily_quotes_101_200.dart';
import 'daily_quotes_201_300.dart';
import 'daily_quotes_301_400.dart';

export 'daily_quote.dart';

// 원전과 공식 연설의 뜻을 앱 문체에 맞게 옮긴 400개 명언입니다.
const dailyQuotes = <DailyQuote>[
  ...dailyQuotes001To100,
  ...dailyQuotes101To200,
  ...dailyQuotes201To300,
  ...dailyQuotes301To400,
];
