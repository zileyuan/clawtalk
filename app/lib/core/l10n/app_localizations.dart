import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('zh')];

  String get appName => _messages['appName'] ?? 'ClawTalk';

  String get connectionTitle => _messages['connectionTitle'] ?? 'Connections';
  String get addConnection => _messages['addConnection'] ?? 'Add Connection';
  String get editConnection => _messages['editConnection'] ?? 'Edit Connection';
  String get deleteConnection =>
      _messages['deleteConnection'] ?? 'Delete Connection';
  String get connectionName => _messages['connectionName'] ?? 'Name';
  String get host => _messages['host'] ?? 'Host';
  String get port => _messages['port'] ?? 'Port';
  String get token => _messages['token'] ?? 'Token';
  String get password => _messages['password'] ?? 'Password';
  String get useTLS => _messages['useTLS'] ?? 'Use TLS';
  String get save => _messages['save'] ?? 'Save';
  String get cancel => _messages['cancel'] ?? 'Cancel';
  String get delete => _messages['delete'] ?? 'Delete';
  String get connect => _messages['connect'] ?? 'Connect';
  String get disconnect => _messages['disconnect'] ?? 'Disconnect';
  String get connected => _messages['connected'] ?? 'Connected';
  String get connecting => _messages['connecting'] ?? 'Connecting...';
  String get disconnected => _messages['disconnected'] ?? 'Disconnected';
  String get connectionError =>
      _messages['connectionError'] ?? 'Connection Error';

  String get chatTitle => _messages['chatTitle'] ?? 'Chat';
  String get typeMessage => _messages['typeMessage'] ?? 'Type a message...';
  String get send => _messages['send'] ?? 'Send';
  String get typing => _messages['typing'] ?? 'Typing...';
  String get copy => _messages['copy'] ?? 'Copy';
  String get retry => _messages['retry'] ?? 'Retry';

  String get takePhoto => _messages['takePhoto'] ?? 'Take Photo';
  String get chooseFromGallery =>
      _messages['chooseFromGallery'] ?? 'Choose from Gallery';
  String get recordVoice => _messages['recordVoice'] ?? 'Record Voice';
  String get stopRecording => _messages['stopRecording'] ?? 'Stop Recording';
  String get holdToRecord => _messages['holdToRecord'] ?? 'Hold to Record';

  String get settings => _messages['settings'] ?? 'Settings';
  String get theme => _messages['theme'] ?? 'Theme';
  String get language => _messages['language'] ?? 'Language';
  String get lightTheme => _messages['lightTheme'] ?? 'Light';
  String get darkTheme => _messages['darkTheme'] ?? 'Dark';
  String get systemTheme => _messages['systemTheme'] ?? 'System';
  String get about => _messages['about'] ?? 'About';
  String get version => _messages['version'] ?? 'Version';
  String get clearData => _messages['clearData'] ?? 'Clear All Data';
  String get clearDataConfirm =>
      _messages['clearDataConfirm'] ??
      'Are you sure you want to clear all data?';

  String get agents => _messages['agents'] ?? 'Agents';
  String get availableAgents =>
      _messages['availableAgents'] ?? 'Available Agents';
  String get capabilities => _messages['capabilities'] ?? 'Capabilities';
  String get startTask => _messages['startTask'] ?? 'Start Task';
  String get cancelTask => _messages['cancelTask'] ?? 'Cancel Task';
  String get taskProgress => _messages['taskProgress'] ?? 'Task Progress';

  String get errorGeneric =>
      _messages['errorGeneric'] ?? 'Something went wrong';
  String get errorNetwork => _messages['errorNetwork'] ?? 'Network error';
  String get errorTimeout => _messages['errorTimeout'] ?? 'Request timed out';
  String get errorValidation =>
      _messages['errorValidation'] ?? 'Please check your input';
  String get errorPermission =>
      _messages['errorPermission'] ?? 'Permission denied';

  String get noConnections =>
      _messages['noConnections'] ?? 'No connections yet';
  String get noMessages => _messages['noMessages'] ?? 'No messages yet';
  String get noAgents => _messages['noAgents'] ?? 'No agents available';

  String get confirmDelete => _messages['confirmDelete'] ?? 'Are you sure?';
  String get yes => _messages['yes'] ?? 'Yes';
  String get no => _messages['no'] ?? 'No';
  String get ok => _messages['ok'] ?? 'OK';

  Map<String, String> get _messages =>
      _localizedMessages[locale.languageCode] ?? _localizedMessages['en'] ?? {};

  static const Map<String, Map<String, String>> _localizedMessages = {
    'en': {
      'appName': 'ClawTalk',
      'connectionTitle': 'Connections',
      'addConnection': 'Add Connection',
      'editConnection': 'Edit Connection',
      'deleteConnection': 'Delete Connection',
      'connectionName': 'Name',
      'host': 'Host',
      'port': 'Port',
      'token': 'Token',
      'password': 'Password',
      'useTLS': 'Use TLS',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'connect': 'Connect',
      'disconnect': 'Disconnect',
      'connected': 'Connected',
      'connecting': 'Connecting...',
      'disconnected': 'Disconnected',
      'connectionError': 'Connection Error',
      'chatTitle': 'Chat',
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'typing': 'Typing...',
      'copy': 'Copy',
      'retry': 'Retry',
      'takePhoto': 'Take Photo',
      'chooseFromGallery': 'Choose from Gallery',
      'recordVoice': 'Record Voice',
      'stopRecording': 'Stop Recording',
      'holdToRecord': 'Hold to Record',
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'lightTheme': 'Light',
      'darkTheme': 'Dark',
      'systemTheme': 'System',
      'about': 'About',
      'version': 'Version',
      'clearData': 'Clear All Data',
      'clearDataConfirm':
          'Are you sure you want to clear all data? This cannot be undone.',
      'agents': 'Agents',
      'availableAgents': 'Available Agents',
      'capabilities': 'Capabilities',
      'startTask': 'Start Task',
      'cancelTask': 'Cancel Task',
      'taskProgress': 'Task Progress',
      'errorGeneric': 'Something went wrong',
      'errorNetwork': 'Network error. Please check your connection.',
      'errorTimeout': 'Request timed out',
      'errorValidation': 'Please check your input',
      'errorPermission': 'Permission denied',
      'noConnections': 'No connections yet',
      'noMessages': 'No messages yet',
      'noAgents': 'No agents available',
      'confirmDelete': 'Are you sure you want to delete this?',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
    },
    'zh': {
      'appName': 'ClawTalk',
      'connectionTitle': '连接',
      'addConnection': '添加连接',
      'editConnection': '编辑连接',
      'deleteConnection': '删除连接',
      'connectionName': '名称',
      'host': '主机',
      'port': '端口',
      'token': '令牌',
      'password': '密码',
      'useTLS': '使用 TLS',
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'connect': '连接',
      'disconnect': '断开',
      'connected': '已连接',
      'connecting': '连接中...',
      'disconnected': '已断开',
      'connectionError': '连接错误',
      'chatTitle': '聊天',
      'typeMessage': '输入消息...',
      'send': '发送',
      'typing': '正在输入...',
      'copy': '复制',
      'retry': '重试',
      'takePhoto': '拍照',
      'chooseFromGallery': '从相册选择',
      'recordVoice': '录音',
      'stopRecording': '停止录音',
      'holdToRecord': '按住录音',
      'settings': '设置',
      'theme': '主题',
      'language': '语言',
      'lightTheme': '浅色',
      'darkTheme': '深色',
      'systemTheme': '跟随系统',
      'about': '关于',
      'version': '版本',
      'clearData': '清除所有数据',
      'clearDataConfirm': '确定要清除所有数据吗？此操作无法撤销。',
      'agents': '智能体',
      'availableAgents': '可用智能体',
      'capabilities': '能力',
      'startTask': '开始任务',
      'cancelTask': '取消任务',
      'taskProgress': '任务进度',
      'errorGeneric': '出错了',
      'errorNetwork': '网络错误，请检查网络连接',
      'errorTimeout': '请求超时',
      'errorValidation': '请检查输入',
      'errorPermission': '权限被拒绝',
      'noConnections': '暂无连接',
      'noMessages': '暂无消息',
      'noAgents': '暂无可用智能体',
      'confirmDelete': '确定要删除吗？',
      'yes': '是',
      'no': '否',
      'ok': '确定',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
