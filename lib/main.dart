import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// الدالة التي تعمل في الخلفية فور وصول SMS
@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  String sender = message.address ?? "";
  String body = message.body ?? "";

  // التأكد من أن المرسل يحتوي على كلمة jiab
  if (sender.toLowerCase().contains("jiab")) {
    try {
      // 1. إرسال نص الرسالة إلى السيرفر الخاص بك
      var response = await http.post(
        Uri.parse('https://mohammedalmual.com/api/process-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': sender,
          'text': body,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        
        // 2. إذا أعاد السيرفر الكرت ورقم العميل، يتم الإرسال فورا
        if (data['status'] == 'success') {
          String clientPhone = data['phone'];
          String cardCode = data['card'];
          
          final Telephony telephony = Telephony.instance;
          await telephony.sendSms(
            to: clientPhone,
            message: "تم شحن رصيدك بنجاح. الكرت: $cardCode",
          );
        }
      }
    } catch (e) {
      print("Error processing SMS: $e");
    }
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Telephony telephony = Telephony.instance;
  String statusMessage = "جاري إعداد الخدمة...";

  @override
  void initState() {
    super.initState();
    initSmsListener();
  }

  // طلب الصلاحيات وتفعيل المستمع
  void initSmsListener() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          backgroundMessageHandler(message);
        },
        onBackgroundMessage: backgroundMessageHandler,
      );
      setState(() {
        statusMessage = "النظام يعمل بنجاح ومربوط بـ\nmohammedalmual.com";
      });
    } else {
      setState(() {
        statusMessage = "تم رفض الصلاحيات! التطبيق لن يعمل.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("SMS Bridge Gateway")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
