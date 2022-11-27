import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const WebsocketDHTSensor());
}

class WebsocketDHTSensor extends StatelessWidget {
  const WebsocketDHTSensor({super.key});

  // root widget of application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Websocket DHT Sensor',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MonitorDHTSensor(title: 'DTH Sensor Monitor'),
    );
  }
}

class MonitorDHTSensor extends StatefulWidget {
  const MonitorDHTSensor({super.key, required this.title});

  // This widget is the home page of the application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  @override
  State<StatefulWidget> createState() {
    return _MonitorDHTSensorState();
  }
}

class _MonitorDHTSensorState extends State<MonitorDHTSensor> {
  late IOWebSocketChannel channel;
  late String temp; //variable for temperature
  late String humidity; //variable for humidity
  late bool connected; //boolean value to track if WebSocket is connected

  late List<LiveData> chartData;
  late ChartSeriesController _chartSeriesController;

  @override
  void initState() {
    connected = false; //initially connection status is "NO" so its FALSE

    temp = "0"; //initial value of temperature
    humidity = "0"; //initial value of humidity

    Future.delayed(Duration.zero, () async {
      channelconnect(); //connect to WebSocket
    });

    super.initState();
  }

  channelconnect() {
    //function to connect
    try {
      channel = IOWebSocketChannel.connect(
          "ws://192.168.1.20:8766"); //channel IP : Port
      channel.stream.listen(
        (message) {
          //print(message);
          connected = true;
          // This call to setState tells the Flutter framework that something has
          // changed in this State, which causes it to rerun the build method below
          // so that the display can reflect the updated values. If we changed
          // _counter without calling setState(), then the build method would not be
          // called again, and so nothing would appear to happen.
          setState(() {
            var data = jsonDecode(message); //decode JSON data
            //print(data["sucess"]);
            if (data["sucess"]) {
              var lastMeassurement = data["info"].last;
              //print(lastMeassurement["temperature"]);
              //print(lastMeassurement["humidity"]);
              temp = lastMeassurement["temperature"].toString();
              humidity = lastMeassurement["humidity"].toString();
              chartData = getChartData(data["info"]);
            } else {
              temp = "NaN";
              humidity = "NaN";
            }
          });
        },
        onDone: () {
          setState(() {
            connected = false;
          });
        },
        onError: (error) {
          //print(error.toString());
        },
      );
    } catch (_) {
      //print("error on connecting to websocket.");
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Temperature',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              temp,
              style: TextStyle(fontSize: 40),
            ),
            const Text(
              'Humidity',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              humidity,
              style: TextStyle(fontSize: 40),
            ),
            Text(
              connected ? "Connected" : "Not Connected",
              style: TextStyle(fontSize: 20),
            ),
            SfCartesianChart(
              series: <ChartSeries>[
                LineSeries<LiveData, int>(
                    dataSource: chartData,
                    xValueMapper: (LiveData data, _) => data.time,
                    yValueMapper: (LiveData data, _) => data.temp,
                    name: 'Temperature',
                    color: Colors.red),
                LineSeries<LiveData, int>(
                    dataSource: chartData,
                    xValueMapper: (LiveData data, _) => data.time,
                    yValueMapper: (LiveData data, _) => data.hum,
                    name: 'Humidity',
                    color: Colors.blue)
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<LiveData> getChartData(data) {
    List<LiveData> chartData = [];
    for (var i = 0; i < data.length; i++) {
      chartData.add(LiveData(
        i,
        data[i]["temperature"],
        data[i]["humidity"],
      ));
    }
    return chartData;
  }
}

class LiveData {
  final int time;
  final int temp;
  final int hum;
  LiveData(this.time, this.temp, this.hum);
}
