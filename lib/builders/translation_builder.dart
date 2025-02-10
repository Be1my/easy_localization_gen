// lib/builders/aggregate_translation_builder.dart
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';

/// 聚合 Builder：以 pubspec.yaml 作为触发输入，扫描用户指定目录下的所有 JSON 文件，
/// 然后将所有 JSON 中的翻译 key 聚合生成到一个 Dart 文件中。
class AggregateTranslationBuilder implements Builder {
  final String inputDir; // 用户指定的扫描目录，例如 "assets/translations/"

  AggregateTranslationBuilder({required this.inputDir});

  /// 我们将此 Builder 的触发输入定为 pubspec.yaml，
  /// 生成的输出文件为 lib/gen/translations.gen.dart
  @override
  final buildExtensions = const {
    'pubspec.yaml': ['lib/gen/translations.gen.dart']
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // 根据用户指定的 inputDir 构造 glob 规则
    final glob = Glob('$inputDir*.json');

    // 查找所有符合条件的 JSON 文件
    final assets = await buildStep.findAssets(glob).toList();

    // 使用 StringBuffer 生成聚合后的 Dart 代码
    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: constant_identifier_names');
    buffer.writeln(
        "import 'package:my_translation_builder/extension/string_hardcoded.dart';");

    buffer.writeln();
    buffer.writeln('class Translations {');

    // 遍历所有 JSON 文件
    for (var asset in assets) {
      // 读取 JSON 文件内容
      final content = await buildStep.readAsString(asset);
      final Map<String, dynamic> jsonMap = json.decode(content);

      // 递归遍历 JSON，生成翻译 key 常量
      void writeConstants(String prefix, Map<String, dynamic> map) {
        map.forEach((key, value) {
          final fullPath = prefix.isEmpty ? key : '$prefix.$key';
          if (value is String) {
            final constantName = _toCamelCase(fullPath);
            buffer.writeln(
                "  String get $constantName => '$fullPath'.hardcoded;");
          } else if (value is Map<String, dynamic>) {
            writeConstants(fullPath, value);
          }
        });
      }

      writeConstants('', jsonMap);
    }

    buffer.writeln('}');

    // 输出文件固定为 lib/gen/translations.gen.dart
    final outputId =
        AssetId(buildStep.inputId.package, 'lib/gen/translations.gen.dart');
    await buildStep.writeAsString(outputId, buffer.toString());
  }
}

/// 将形如 "home.title" 的字符串转换为 camelCase 变量名，如 "homeTitle"。
String _toCamelCase(String keyPath) {
  final parts = keyPath.split('.');
  if (parts.isEmpty) return keyPath;
  final buffer = StringBuffer();

  // 对第一个分段，只转换首字母为小写，保留后面的格式
  final first = parts.first;
  if (first.isNotEmpty) {
    buffer.write(first[0].toLowerCase() + first.substring(1));
  }

  // 后续的每个分段首字母大写
  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isNotEmpty) {
      buffer.write(part[0].toUpperCase() + part.substring(1));
    }
  }

  return buffer.toString();
}
