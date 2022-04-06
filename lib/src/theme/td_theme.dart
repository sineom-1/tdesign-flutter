import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/src/theme/td_default_theme.dart';
import 'package:tdesign_flutter/src/theme/td_font_family.dart';
import 'package:tdesign_flutter/src/theme/td_fonts.dart';
import 'package:tdesign_flutter/src/util/string_util.dart';
import 'package:tdesign_flutter/src/util/log.dart';

import 'basic.dart';

/// 主题控件
class TDTheme extends StatelessWidget {
  final Widget child;

  final TDThemeData data;

  /// Flutter系统主题数据
  final ThemeData? systemData;

  const TDTheme(
      {required this.data, required this.child, this.systemData, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = _TDInheritedTheme(
      theme: this,
      child: child,
    );
    if (systemData != null) {
      result = Theme(data: systemData!, child: result);
    }
    return result;
  }

  /// 获取默认主题数据，全局唯一
  static TDThemeData defaultData() {
    return TDThemeData.defaultData();
  }

  /// 获取主题数据，如果未传context则获取全局唯一的默认数据,
  /// 传了context，则获取最近的主题，取不到则会获取全局唯一默认数据
  static TDThemeData of(BuildContext? context) {
    if (context != null) {
      // 如果传了context，则从其中获取最近主题
      final _TDInheritedTheme? inheritedTheme =
          context.dependOnInheritedWidgetOfExactType<_TDInheritedTheme>();
      return inheritedTheme?.theme.data ?? TDThemeData.defaultData();
    } else {
      // 如果context为null,则返回全局默认主题
      return TDThemeData.defaultData();
    }
  }
}

/// 存储主题数据的内部控件
class _TDInheritedTheme extends InheritedWidget {
  final TDTheme theme;

  const _TDInheritedTheme(
      {required this.theme, Key? key, required Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant _TDInheritedTheme oldWidget) {
    return theme.data != oldWidget.theme.data;
  }
}

/// 主题数据
class TDThemeData {
  static const String _defaultThemeName = 'default';
  static TDThemeData? _defaultThemeData;

  late String name;
  late Map<String, Color> colors;
  late Map<String, Font> fonts;
  late Map<String, double> corners;
  late Map<String, FontFamily> fontFamilies;
  late Map<String, List<BoxShadow>> shadows;
  late TDExtraThemeData? extraThemeData;

  TDThemeData(
      {required this.name,
      required this.colors,
      required this.fonts,
      required this.corners,
      required this.fontFamilies,
      required this.shadows,
      this.extraThemeData,
      bool recoverDefault = false});

  /// 获取默认Data，一个App里只有一个，用于没有context的地方
  static TDThemeData defaultData({TDExtraThemeData? extraThemeData}) {
    _defaultThemeData ??= fromJson(
            _defaultThemeName, TDDefaultTheme.defaultThemeConfig,
            extraThemeData: extraThemeData) ??
        _emptyData(_defaultThemeName, extraThemeData: extraThemeData);

    return _defaultThemeData!;
  }

  /// 从父类拷贝
  TDThemeData copyWith(
    String name, {
    Map<String, Color>? colors,
    Map<String, Font>? fonts,
    Map<String, double>? corners,
    Map<String, FontFamily>? fontFamilies,
    Map<String, List<BoxShadow>>? shadows,
    TDExtraThemeData? extraThemeData,
  }) {
    var result = TDThemeData(
        name: name,
        colors: _copyMap<Color>(this.colors, colors),
        fonts: _copyMap<Font>(this.fonts, fonts),
        corners: _copyMap<double>(this.corners, corners),
        fontFamilies: _copyMap<FontFamily>(this.fontFamilies, fontFamilies),
        shadows: _copyMap<List<BoxShadow>>(this.shadows, shadows),
        extraThemeData: extraThemeData ?? this.extraThemeData);

    return result;
  }

  /// 拷贝Map,防止内层
  Map<String, T> _copyMap<T>(Map<String, T> src, Map<String, T>? add) {
    Map<String, T> map = {};
    src.forEach((key, value) {
      map[key] = value;
    });
    if (add != null) {
      map.addAll(add);
    }
    return map;
  }

  /// 创建空对象
  static TDThemeData _emptyData(String name,
      {TDExtraThemeData? extraThemeData}) {
    return TDThemeData(
        name: name,
        colors: {},
        fonts: {},
        corners: {},
        fontFamilies: {},
        shadows: {});
  }

  /// 解析配置的json文件为主题数据
  static TDThemeData? fromJson(String name, String themeJson,
      {var recoverDefault = false, TDExtraThemeData? extraThemeData}) {
    if (themeJson.isEmpty) {
      Log.e('TTheme', 'parse themeJson is empty');
      return null;
    }
    try {
      /// 要求json配置必须正确
      final themeConfig = json.decode(themeJson);
      if (themeConfig.containsKey(name)) {
        var theme = _emptyData(name);
        Map<String, dynamic> curThemeMap = themeConfig['$name'];

        /// 设置颜色
        Map<String, dynamic>? colorsMap = curThemeMap['colors'];
        colorsMap?.forEach((key, value) {
          theme.colors[key] = toColor(value);
        });

        /// 设置字体尺寸
        Map<String, dynamic>? fontsMap = curThemeMap['fonts'];
        fontsMap?.forEach((key, value) {
          theme.fonts[key] =
              Font(size: value['size'], lineHeight: value['lineHeight']);
        });

        /// 设置圆角
        Map<String, dynamic>? cornersMap = curThemeMap['corners'];
        cornersMap?.forEach((key, value) {
          theme.corners[key] = value.toDouble();
        });

        /// 设置字体
        Map<String, dynamic>? fontFamilyMap = curThemeMap['fontFamily'];
        fontFamilyMap?.forEach((key, value) {
          theme.fontFamilies[key] = FontFamily(fontFamily: value['fontFamily']);
        });

        /// 设置阴影
        Map<String, dynamic>? shadowMap = curThemeMap['shadow'];
        shadowMap?.forEach((key, value) {
          var list = <BoxShadow>[];
          (value as List).forEach((element) {
            list.add(BoxShadow(
              color: toColor(element['color']),
              blurRadius: element['blurRadius'].toDouble(),
              spreadRadius: element['spreadRadius'].toDouble(),
              offset: Offset(element['offset']?['x'].toDouble() ?? 0,
                  element['offset']?['y'].toDouble() ?? 0),
            ));
          });

          theme.shadows[key] = list;
        });
        if (extraThemeData != null) {
          extraThemeData.parse(name, curThemeMap);
          theme.extraThemeData = extraThemeData;
        }
        if (recoverDefault) {
          _defaultThemeData = theme;
        }
        return theme;
      } else {
        Log.e('TTheme',
            'load theme error ,not found the theme with name:${name}');
        return null;
      }
    } catch (e) {
      Log.e('TTheme', 'parse theme data error:${e}');
      return null;
    }
  }

  Color? ofColor(
    String? key,
  ) {
    return colors[key];
  }

  Font? ofFont(String? key) {
    return fonts[key];
  }

  double? ofCorner(
    String? key,
  ) {
    return corners[key];
  }

  FontFamily? ofFontFamily(
    String? key,
  ) {
    return fontFamilies[key];
  }

  List<BoxShadow>? ofShadow(
    String? key,
  ) {
    return shadows[key];
  }

  T? ofExtra<T extends TDExtraThemeData>() {
    try {
      return extraThemeData as T;
    } catch (e) {
      Log.e('TDThemeData ofExtra error: $e');
    }
    return null;
  }
}

/// 扩展主题数据
abstract class TDExtraThemeData {
  /// 解析json
  void parse(String name, Map<String, dynamic> curThemeMap);
}