import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:a1/styles/styles.dart';
import 'package:a1/widgets/toast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:home_widget/home_widget.dart';
import 'package:volume_controller/volume_controller.dart';

class Genius extends StatefulWidget {
  const Genius({super.key});

  @override
  State<Genius> createState() => _GeniusState();
}

class _GeniusState extends State<Genius> {
  final headsetDetector = HeadsetDetector();
  String idioma = 'pt';

  int score = 0;
  int nivel = 1;
  int segundos = 0;

  bool iniciado = false;
  bool habilitado = true;

  Timer? timer;

  List cores = [];
  List coresFaladas = [];
  List coresClicadas = [];

  selecionarCores() {
    cores = [
      {'id': 0, 'cor': Colors.red, 'click': false},
      {'id': 1, 'cor': Colors.blue, 'click': false},
      {'id': 2, 'cor': Colors.yellow, 'click': false},
      {'id': 3, 'cor': Colors.orange, 'click': false},
      {'id': 4, 'cor': Colors.green, 'click': false},
    ];

    setState(() {});
  }

  click(cor) async {
    if (habilitado & iniciado) {
      cor['click'] = true;
      setState(() {});

      final player = AudioPlayer();
      await player.play(AssetSource('genius/click.mp3'));

      coresClicadas.add(cor['id']);

      await Future.delayed(const Duration(milliseconds: 500));
      cor['click'] = false;
      setState(() {});

      if (coresClicadas.length == coresFaladas.length) {
        if (coresClicadas.toString() == coresFaladas.toString()) {
          score++;

          if (score % 2 == 0) {
            nivel++;
          }

          cor['click'] = false;
          setState(() {});

          coresFaladas = [];
          coresClicadas = [];

          await falar();
        } else {
          stop();
        }
      }
    }
  }

  falar() async {
    habilitado = false;
    setState(() {});

    for (int i = 0; i < nivel; i++) {
      int index = Random().nextInt(5);
      final player = AudioPlayer();
      await player.play(AssetSource('genius/$idioma/$index.mp3'));

      coresFaladas.add(index);
      await Future.delayed(const Duration(seconds: 1));
    }

    habilitado = true;
    setState(() {});
  }

  start() async {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      segundos++;
      setState(() {});
    });

    iniciado = true;
    await falar();
  }

  stop() {
    HomeWidget.saveWidgetData<int>('valueGenius', score);
    HomeWidget.updateWidget(name: 'HomeWidgetExampleProvider');

    MyToast.get(
      'Fim de jogo! Score: $score | Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
    );

    timer?.cancel();

    score = 0;
    nivel = 1;
    segundos = 0;

    iniciado = false;
    habilitado = true;

    coresFaladas = [];
    coresClicadas = [];

    iniciado = false;
    setState(() {});
  }

  startApp() async {
    if (window.locale.languageCode == 'es') {
      idioma = 'es';
    } else if (window.locale.languageCode == 'en') {
      idioma = 'en';
    }

    Map<HeadsetType, HeadsetState> headsetState = {
      HeadsetType.WIRED: HeadsetState.DISCONNECTED,
      HeadsetType.WIRELESS: HeadsetState.DISCONNECTED,
    };

    headsetDetector.getCurrentState.then((_val) {
      headsetState = _val;
      setState(() {});
    });

    headsetDetector.setListener((_val) async {
      switch (_val) {
        case HeadsetChangedEvent.WIRED_CONNECTED:
          headsetState[HeadsetType.WIRED] = HeadsetState.CONNECTED;

          MyToast.snack(
            'Fone de ouvido conectado, o volume do dispositivo doi diminuído em 70%',
            context,
          );
          double volume = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(volume * .3);
          break;
        case HeadsetChangedEvent.WIRED_DISCONNECTED:
          headsetState[HeadsetType.WIRED] = HeadsetState.DISCONNECTED;
          break;
        case HeadsetChangedEvent.WIRELESS_CONNECTED:
          headsetState[HeadsetType.WIRELESS] = HeadsetState.CONNECTED;

          MyToast.snack(
            'Fone de ouvido conectado, o volume do dispositivo doi diminuído em 70%',
            context,
          );
          double volume = await VolumeController.instance.getVolume();
          await VolumeController.instance.setVolume(volume * .3);
          break;
        case HeadsetChangedEvent.WIRELESS_DISCONNECTED:
          headsetState[HeadsetType.WIRELESS] = HeadsetState.DISCONNECTED;
          break;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    selecionarCores();
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    headsetDetector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Genius Play'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            if (iniciado) {
              stop();
            }
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              DropdownButtonFormField(
                value: idioma,
                items: [
                  DropdownMenuItem(value: 'pt', child: Text('Português')),
                  DropdownMenuItem(value: 'en', child: Text('Inglês')),
                  DropdownMenuItem(value: 'es', child: Text('Espanhol')),
                ],
                onChanged: (value) {
                  idioma = value.toString();
                  selecionarCores();
                },
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nivel: $nivel'),
                  Text('Score: $score'),
                  Text(
                    'Cronômetro: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                  ),
                ],
              ),
              Container(height: 16),
              Stack(
                children: [
                  Center(
                    child: Image.asset(
                      habilitado
                          ? 'assets/pentagono.png'
                          : 'assets/pentagono2.png',
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 100,
                      height: 180,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runAlignment: WrapAlignment.center,
                        children: [
                          for (var cor in cores)
                            GestureDetector(
                              onTap: () => click(cor),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  cor['cor'] == Colors.yellow
                                      ? 15
                                      : cor['cor'] == Colors.orange
                                      ? 15
                                      : 10,
                                ),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  color: !habilitado ? Colors.grey : cor['cor'],
                                  child: cor['click']
                                      ? Center(
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Cores.branco,
                                                  blurRadius: 20,
                                                  spreadRadius: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: () => (), child: Text('Restart')),
                  ElevatedButton(
                    onPressed: () => iniciado ? stop() : start(),
                    child: Text(iniciado ? 'Stop' : 'Start'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
