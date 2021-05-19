import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TestBackGroundFetch extends StatelessWidget {
  var _enabled = true.obs;
  var _status = 0.obs;
  var _events = [].obs;

  @override
  Widget build(BuildContext context) {
    initPlatformState();

    return new GetMaterialApp(
      home: new Scaffold(
        appBar: new AppBar(title: const Text('BackgroundFetch Example', style: TextStyle(color: Colors.black)), backgroundColor: Colors.amberAccent, brightness: Brightness.light, actions: <Widget>[
          Obx(() => Switch(value: _enabled.value, onChanged: _onClickEnable)),
        ]),
        body: Container(
          color: Colors.black,
          child: Obx(() => new ListView.builder(
              itemCount: _events.length,
              itemBuilder: (BuildContext context, int index) {
                DateTime timestamp = _events[index];
                return InputDecorator(
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 10.0, top: 10.0, bottom: 0.0), labelStyle: TextStyle(color: Colors.amberAccent, fontSize: 20.0), labelText: "[background fetch event]"),
                    child: new Text(timestamp.toString(), style: TextStyle(color: Colors.white, fontSize: 16.0)));
              })),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Row(children: <Widget>[RaisedButton(onPressed: _onClickStatus, child: Text('Status')), Container(child: Obx(() => Text(_status.toString())), margin: EdgeInsets.only(left: 20.0))])),
      ),
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      // <-- Event handler
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      _events.insert(0, new DateTime.now());
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.

      var c = 0;
      Timer.periodic(Duration(seconds: 1), (timer) {
        c++;
        print('tick $DateTime.now(), c=$c');

        if (c > 100) {
          print('cancle $DateTime.now()');
          timer.cancel();
          BackgroundFetch.finish(taskId);
        }
      });
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');

    _status.value = status;
  }

  void _onClickEnable(enabled) {
    _enabled.value = enabled;

    print(_events);

    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    print(_events);
    _status.value = status;
  }
}
