import 'dart:async';
import 'dart:io';

import 'package:a1/styles/styles.dart';
import 'package:a1/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_headset_detector/flutter_headset_detector.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:volume_controller/volume_controller.dart';

class Memo extends StatefulWidget {
  const Memo({super.key});

  @override
  State<Memo> createState() => _MemoState();
}

enum Estado { iniciado, timer, parado }

class _MemoState extends State<Memo> {
  final headsetDetector = HeadsetDetector();
  String tema = 'Animais da Amazonia';

  Estado estado = Estado.parado;

  int acertos = 0;
  int erros = 0;
  int segundos = 0;

  Timer? timer;

  List imagens = [];
  List imagensClicadas = [];

  late StreamSubscription subscription;

  start() {
    estado = Estado.timer;
    setState(() {});

    segundos = 3;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      segundos--;
      setState(() {});

      if (segundos == 0) {
        estado = Estado.iniciado;
        timer?.cancel();

        for (var img in imagens) {
          img['virada'] = false;
        }
        setState(() {});

        timer = Timer.periodic(Duration(seconds: 1), (_) {
          segundos++;
          setState(() {});
        });
      }
    });
  }

  stop() {
    HomeWidget.saveWidgetData<int>('valueMemo', acertos);
    HomeWidget.updateWidget(name: 'HomeWidgetExampleProvider');

    MyToast.get(
      'Fim de jogo! Acertos: $acertos | Erros: $erros | Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
    );
    estado = Estado.parado;

    acertos = 0;
    erros = 0;
    segundos = 0;

    timer?.cancel();

    imagensClicadas = [];

    for (var img in imagens) {
      img['virada'] = true;
    }
    setState(() {});
  }

  click(img) async {
    if (!img['virada'] && estado == Estado.iniciado) {
      imagensClicadas.add(img['path']);
      img['virada'] = true;

      if (imagensClicadas.length == 2) {
        if (imagensClicadas.first == imagensClicadas.last) {
          acertos++;

          if (acertos == 4) {
            stop();
          }
        } else {
          Vibration.vibrate();
          erros++;
          setState(() {});
          await Future.delayed(const Duration(seconds: 1));

          for (var img in imagens) {
            if (img['path'] == imagensClicadas.last ||
                img['path'] == imagensClicadas.first) {
              img['virada'] = false;
            }
          }
        }

        imagensClicadas.clear();
      }

      setState(() {});
    }
  }

  selecionarTemas() {
    imagens.clear();

    for (int i = 0; i < 4; i++) {
      imagens.add({
        'tipo': 'assets',
        'path': 'assets/memocheck/$tema/$i.jpg',
        'virada': true,
      });
    }

    for (int i = 0; i < 4; i++) {
      imagens.add({
        'tipo': 'assets',
        'path': 'assets/memocheck/$tema/$i.jpg',
        'virada': true,
      });
    }

    imagens.shuffle();
    setState(() {});
  }

  startApp() async {
    subscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        if (event.z > 3 || event.z < -3) {
          imagens.shuffle();
          setState(() {});
        }
      },
      onError: (error) {},
      cancelOnError: true,
    );

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
    selecionarTemas();
    startApp();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    subscription.cancel();
    headsetDetector.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: Text('MemoCheck'), automaticallyImplyLeading: true),
      body: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tema'),
                  SizedBox(
                    width: width * .78,
                    child: DropdownButtonFormField(
                      value: tema,
                      items: estado == Estado.parado
                          ? [
                              DropdownMenuItem(
                                value: 'Animais da Amazonia',
                                child: Text('Animais da Amazonia'),
                              ),
                              DropdownMenuItem(
                                value: 'Carros',
                                child: Text('Carros'),
                              ),
                            ]
                          : [],
                      onChanged: (value) {
                        tema = value.toString();
                        selecionarTemas();
                      },
                    ),
                  ),
                ],
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Acertos: ${acertos.toString().padLeft(2, '0')}'),
                  Text('Erros: ${erros.toString().padLeft(2, '0')}'),
                  Text(
                    'Tempo: ${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                  ),
                ],
              ),
              Container(height: 16),
              Wrap(
                children: [
                  for (var img in imagens)
                    if (img['tipo'] == 'file')
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () => click(img),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Cores.azulClaro,
                            child: img['virada']
                                ? Image.file(
                                    File(img['path']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () => click(img),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Cores.azulClaro,
                            child: img['virada']
                                ? Image.asset(img['path'], fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                      ),
                ],
              ),
              Container(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => estado == Estado.iniciado
                        ? stop()
                        : estado == Estado.parado
                        ? start()
                        : null,
                    child: Text(
                      estado == Estado.iniciado
                          ? 'STOP'
                          : estado == Estado.parado
                          ? 'START'
                          : '${(segundos ~/ 60).toString().padLeft(2, '0')}:${(segundos % 60).toString().padLeft(2, '0')}',
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final List<XFile> images = await picker.pickMultiImage();

                      if (images.length == 4) {
                        imagens.clear();

                        for (var img in images) {
                          imagens.add({
                            'tipo': 'file',
                            'path': img.path,
                            'virada': true,
                          });
                        }

                        for (var img in images) {
                          imagens.add({
                            'tipo': 'file',
                            'path': img.path,
                            'virada': true,
                          });
                        }

                        imagens.shuffle();
                        setState(() {});
                      } else {
                        MyToast.get('Selecione 4 imagens');
                      }
                    },
                    icon: Icon(Icons.settings),
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
