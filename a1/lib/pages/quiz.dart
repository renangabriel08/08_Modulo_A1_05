import 'dart:async';
import 'dart:convert';

import 'package:a1/styles/styles.dart';
import 'package:a1/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> with SingleTickerProviderStateMixin {
  final headsetDetector = HeadsetDetector();
  late AnimationController controller;
  Animation? angle;

  List questoes = [];
  Map questao = {};
  int index = 0;
  int score = 0;

  String selecionada = '';
  List resRel = [[], [], []];

  bool click = false;
  late StreamSubscription subscription;

  encerrar() {
    HomeWidget.saveWidgetData<int>('valueQuiz', score);
    HomeWidget.updateWidget(name: 'HomeWidgetExampleProvider');

    MyToast.get('Fim de jogo! Score: $score');
    Navigator.pop(context);
  }

  proximo() async {
    if (questao['tipo'] == 'ME') {
      if (!click) {
        click = true;
        if (selecionada == questao['alternativas'][questao['resposta']]) {
          score += int.parse(questao['peso'].toString());
        }
      } else {
        index++;
        click = false;
      }
    }

    if (questao['tipo'] == 'VF') {
      if (selecionada == questao['alternativas'][questao['resposta']]) {
        score += int.parse(questao['peso'].toString());
      }
      index++;
    }

    if (questao['tipo'] == 'REL') {
      if (questao['resposta'].toString() == resRel.toString()) {
        score += int.parse(questao['peso'].toString());
      }

      if (questao['id'] == 502) {
        encerrar();
      } else {
        index++;
      }
    }

    questao = questoes[index];

    if (questao['tipo'] == 'VF') {
      angle = Tween<double>(
        begin: 0,
        end: 1.5,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));

      controller.addListener(() async {
        if (controller.isCompleted) {
          await controller.reverse();
          await controller.forward();
        }

        setState(() {});
      });
      await controller.forward();
    }

    selecionada = '';
    resRel = [[], [], []];
    setState(() {});
  }

  startApp() async {
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
    subscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        if (questoes.isNotEmpty && questao['tipo'] == 'VF') {
          if (event.x < -3) {
            selecionada = 'Verdadeiro';
          } else if (event.x > 3) {
            selecionada = 'Falso';
          }
        }

        setState(() {});
      },
      onError: (error) {},
      cancelOnError: true,
    );

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    String json = await rootBundle.loadString('assets/bancoQuestoes.json');
    Map dados = jsonDecode(json);
    questoes = dados['perguntas'];
    questao = questoes.first;

    setState(() {});
  }

  @override
  void initState() {
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();
    headsetDetector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    if (questoes.isNotEmpty && questao['tipo'] == 'REL') {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz My Brain'),
        automaticallyImplyLeading: true,
        actions: [Text('Score: $score'), Container(width: 16)],
      ),
      body: questoes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Container(
              width: width,
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(questao['enunciado']),
                    Container(height: 16),
                    if (questao['tipo'] == 'ME')
                      Column(
                        children: [
                          for (var alternativa in questao['alternativas'])
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  selecionada = alternativa;
                                  setState(() {});
                                },
                                child: Container(
                                  width: width,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 2,
                                      color:
                                          click &&
                                              questao['alternativas'].indexOf(
                                                    alternativa,
                                                  ) ==
                                                  questao['resposta']
                                          ? Colors.red
                                          : alternativa == selecionada
                                          ? Cores.azulClaro
                                          : Cores.preto,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      alternativa,
                                      style: TextStyle(
                                        color:
                                            click &&
                                                questao['alternativas'].indexOf(
                                                      alternativa,
                                                    ) ==
                                                    questao['resposta']
                                            ? Colors.red
                                            : alternativa == selecionada
                                            ? Cores.azulClaro
                                            : Cores.preto,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                    if (questao['tipo'] == 'VF')
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var alternativa in questao['alternativas'])
                                GestureDetector(
                                  onTap: () {
                                    selecionada = alternativa;
                                    setState(() {});
                                  },
                                  child: Container(
                                    width: width * .4,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: alternativa == selecionada
                                            ? Cores.azulClaro
                                            : Cores.preto,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        alternativa,
                                        style: TextStyle(
                                          color: alternativa == selecionada
                                              ? Cores.azulClaro
                                              : Cores.preto,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          Container(height: 16),
                          Transform.rotate(
                            angle: angle?.value ?? 0,
                            child: Icon(Icons.screen_rotation_sharp, size: 50),
                          ),
                        ],
                      ),

                    if (questao['tipo'] == 'REL')
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (
                                int i = 0;
                                i < questao['alternativas'][0].length;
                                i++
                              )
                                Draggable(
                                  data: {
                                    'index': i,
                                    'value': questao['alternativas'][0][i],
                                  },
                                  feedback: Container(
                                    width: width * .3,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: Cores.preto,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        questao['alternativas'][0][i],
                                        style: TextStyle(color: Cores.preto),
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    width: width * .3,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: Cores.preto,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        questao['alternativas'][0][i],
                                        style: TextStyle(color: Cores.preto),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Container(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (
                                int i = 0;
                                i < questao['alternativas'][1].length;
                                i++
                              )
                                DragTarget(
                                  builder:
                                      (context, candidateData, rejectedData) =>
                                          Container(
                                            width: width * .3,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: 2,
                                                color: Cores.preto,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                questao['alternativas'][1][i],
                                                style: TextStyle(
                                                  color: Cores.preto,
                                                ),
                                              ),
                                            ),
                                          ),
                                  onAccept: (Map data) {
                                    if (!questao['alternativas'][1][i]
                                        .toString()
                                        .contains(':')) {
                                      resRel[data['index']].add(data['index']);
                                      resRel[data['index']].add(i);

                                      questao['alternativas'][1][i] +=
                                          ': ${data['value']}';
                                    }

                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),

                    Container(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => encerrar(),
                          child: Text('Encerrar'),
                        ),
                        ElevatedButton(
                          onPressed: () => proximo(),
                          child: Text('Próximo'),
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
