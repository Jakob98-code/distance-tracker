import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> updateWidgetData({
    required String coupleId,
    required String person1Name,
    required String person2Name,
  }) async {
    await HomeWidget.saveWidgetData<String>('coupleId', coupleId);
    await HomeWidget.saveWidgetData<String>('person1Name', person1Name);
    await HomeWidget.saveWidgetData<String>('person2Name', person2Name);
    await HomeWidget.updateWidget(
      androidName: 'DistanceWidgetProvider',
    );
  }
}
