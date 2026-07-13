// FCM 푸시 수신. 백엔드(notifications.py)는 data-only 메시지를 보내므로
// 알림 트레이 표시는 앱이 flutter_local_notifications 로 직접 렌더한다.
// 포그라운드(onMessage)·백그라운드/종료(onBackgroundMessage) 모두 처리한다.
//
// 안드로이드 실서버 모드에서만 초기화한다(main.dart 에서 가드). 웹 데모는 부르지 않는다.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';

const _channelId = 'memory_pager_default';
const _channelName = '메모리 페이저 알림';

final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: '찌르기·낙서·월간 리포트 알림',
  importance: Importance.high,
);

Future<void> _initLocalNotifs() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifs
      .initialize(const InitializationSettings(android: androidInit));
  await _localNotifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

/// data 페이로드 → (제목, 본문). widget_refresh 같은 조용한 타입은 null(알림 안 띄움).
(String, String)? _content(Map<String, dynamic> data) {
  switch ('${data['type']}') {
    case 'poke':
      return ('콕! 삐삐-', '${data['from_nickname'] ?? '상대'}님이 콕 찔렀어요');
    case 'doodle_received':
      final ephemeral = '${data['is_ephemeral']}' == 'true';
      return (
        '새 낙서 도착',
        '${data['sender_nickname'] ?? '상대'}님이 ${ephemeral ? '사라지는 ' : ''}낙서를 보냈어요',
      );
    case 'monthly_report':
      return ('이달의 리포트', '${data['report_month'] ?? ''} 리포트가 도착했어요');
    default:
      return null;
  }
}

/// widget_refresh 조용한 푸시 → 홈 위젯을 실제로 갱신한다(포그라운드·백그라운드 공통).
Future<void> _refreshWidget(Map<String, dynamic> data) async {
  try {
    if (data['pet_name'] != null) {
      await HomeWidget.saveWidgetData<String>('pet_name', '${data['pet_name']}');
    }
    if (data['pet_level'] != null) {
      await HomeWidget.saveWidgetData<String>('pet_level', '${data['pet_level']}');
    }
    await HomeWidget.updateWidget(androidName: 'PagerWidgetProvider');
  } catch (_) {
    // 위젯 미지원 환경에서는 조용히 넘어간다.
  }
}

Future<void> _display(Map<String, dynamic> data) async {
  if ('${data['type']}' == 'widget_refresh') {
    await _refreshWidget(data); // 알림은 띄우지 않고 위젯만 갱신
    return;
  }
  final content = _content(data);
  if (content == null) return;
  await _localNotifs.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    content.$1,
    content.$2,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

/// 백그라운드/종료 상태 핸들러. 별도 아이소레이트에서 실행되므로 Firebase·로컬알림을
/// 다시 초기화한다. 반드시 top-level + vm:entry-point 여야 한다.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _initLocalNotifs();
  await _display(message.data);
}

bool _ready = false;

/// FCM 초기화 + 토큰 등록. [onToken] 으로 받은 토큰을 서버(/v1/devices)에 올린다.
/// 실패해도 앱 부팅을 막지 않도록 호출부에서 try/catch 로 감싼다.
Future<void> initPush({
  required Future<void> Function(String token) onToken,
}) async {
  if (_ready) return;
  _ready = true;

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  await _initLocalNotifs();
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((m) => _display(m.data));

  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);
}
