// lib/builder.dart
import 'package:build/build.dart';
import 'package:my_translation_builder/builders/translation_builder.dart';

/// 工厂方法，从 BuilderOptions 中读取用户配置，创建 AggregateTranslationBuilder 实例
Builder aggregateTranslationBuilder(BuilderOptions options) {
  final inputDir = options.config['input'] as String? ?? 'assets/translations/';
  return AggregateTranslationBuilder(inputDir: inputDir);
}
