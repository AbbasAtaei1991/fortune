import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:fortune/member.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();

  final isar = await Isar.open(
    schemas: [MemberSchema],
    directory: dir.path,
  );
  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({Key? key, required this.isar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        isar: isar,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Isar isar;
  const MyHomePage({Key? key, required this.isar}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamController<int> controller = StreamController<int>();
  final TextEditingController _numberController = TextEditingController();
  late ConfettiController _controllerCenter;
  late ConfettiController _controllerCenterRight;
  late ConfettiController _controllerCenterLeft;
  late ConfettiController _controllerTopCenter;
  late ConfettiController _controllerBottomCenter;
  List<Member> items = [];
  String selected = '';

  Future<void> _addMember(String memberName) async {
    final member = Member()..name = memberName;
    await widget.isar.writeTxn((isar) async {
      member.id = await widget.isar.members.put(member);
    });
  }

  @override
  void initState() {
    super.initState();
    generateList();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 1));
    _controllerCenterRight = ConfettiController(duration: const Duration(seconds: 1));
    _controllerCenterLeft = ConfettiController(duration: const Duration(seconds: 1));
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 1));
    _controllerBottomCenter = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    controller.close();
    _controllerCenter.dispose();
    _controllerCenterRight.dispose();
    _controllerCenterLeft.dispose();
    _controllerTopCenter.dispose();
    _controllerBottomCenter.dispose();
    super.dispose();
  }

  void generateList() async {
    var name = _numberController.text;
    if (name.isNotEmpty) {
      _addMember(name);
    }

    final allMembers = await widget.isar.members.where().findAll();

    List<String> nums = [];

    setState(() {
      items.clear();
      items = allMembers;
    });
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step), halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ZAFARAN'),
      ),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey),
                        child: MaterialButton(
                            minWidth: 60,
                            height: 60,
                            onPressed: (() async {
                              var name = _numberController.text;
                              if (name.isNotEmpty) {
                                final newMember = Member()..name = name;
                                await widget.isar.writeTxn((isar) async {
                                  newMember.id = await widget.isar.members.put(newMember);
                                });
                              }
                              final allMembers = await widget.isar.members.where().findAll();
                              setState(() {
                                items = allMembers;
                                _numberController.clear();
                              });
                            }),
                            child: const Icon(Icons.add)),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _numberController,
                          keyboardType: TextInputType.name,
                          style: const TextStyle(color: Colors.black, fontSize: 16, fontFamily: 'Yekan'),
                          textAlign: TextAlign.center,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            hintText: 'نام',
                            hintStyle: const TextStyle(fontFamily: 'Yekan'),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(color: Colors.blue),
                                gapPadding: 0.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                      itemCount: items.length,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Stack(children: [
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Center(
                                  child: Text(
                                items[index].name,
                                style: const TextStyle(fontFamily: 'Yekan'),
                              )),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final selected = await widget.isar.members.get(items[index].id!);
                              await widget.isar.writeTxn((isar) async {
                                await widget.isar.members.delete(selected!.id!);
                              });
                              final allMembers = await widget.isar.members.where().findAll();
                              setState(() {
                                items = allMembers;
                              });
                            },
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                        ]);
                      }),
                ),
                items.length > 1
                    ? Expanded(
                        child: FortuneWheel(
                          duration: const Duration(seconds: 14),
                          animateFirst: false,
                          onAnimationEnd: () {
                            _controllerTopCenter.play();
                            _controllerBottomCenter.play();
                            _controllerCenter.play();
                            _controllerCenterLeft.play();
                            _controllerCenterRight.play();
                          },
                          selected: controller.stream,
                          items: [
                            for (var it in items)
                              FortuneItem(
                                  style: FortuneItemStyle(
                                    color: Colors.primaries[
                                        Random().nextInt(Colors.primaries.length)], // <-- custom circle slice fill color
                                    borderColor: Colors.white, // <-- custom circle slice stroke color
                                    borderWidth: 3, // <-- custom circle slice stroke width
                                  ),
                                  onDoubleTap: (() async {
                                    final selected = await widget.isar.members.get(it.id!);
                                    await widget.isar.writeTxn((isar) async {
                                      await widget.isar.members.delete(selected!.id!);
                                    });
                                    final allMembers = await widget.isar.members.where().findAll();
                                    setState(() {
                                      items = allMembers;
                                    });
                                  }),
                                  child: Text(
                                    it.name,
                                    style: const TextStyle(fontSize: 18, fontFamily: 'Yekan'),
                                  )),
                          ],
                        ),
                      )
                    : const SizedBox(
                        height: 10,
                      )
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirectionality: BlastDirectionality.explosive, // don't specify a direction, blast randomly
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ], // manually specify the colors to be used
                createParticlePath: drawStar, // define a custom shape/path.
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(),
            ),

            //CENTER RIGHT -- Emit left
            Align(
              alignment: Alignment.centerRight,
              child: ConfettiWidget(
                confettiController: _controllerCenterRight,
                blastDirection: pi, // radial value - LEFT
                particleDrag: 0.05, // apply drag to the confetti
                emissionFrequency: 0.05, // how often it should emit
                numberOfParticles: 20, // number of particles to emit
                gravity: 0.05, // gravity - or fall speed
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink], // manually specify the colors to be used
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(),
            ),

            //CENTER LEFT - Emit right
            Align(
              alignment: Alignment.centerLeft,
              child: ConfettiWidget(
                confettiController: _controllerCenterLeft,
                blastDirection: 0, // radial value - RIGHT
                emissionFrequency: 0.6,
                minimumSize: const Size(10, 10), // set the minimum potential size for the confetti (width, height)
                maximumSize: const Size(50, 50), // set the maximum potential size for the confetti (width, height)
                numberOfParticles: 1,
                gravity: 0.1,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(),
            ),

            //TOP CENTER - shoot down
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controllerTopCenter,
                blastDirection: pi / 2,
                maxBlastForce: 5, // set a lower max blast force
                minBlastForce: 2, // set a lower min blast force
                emissionFrequency: 0.05,
                numberOfParticles: 50, // a lot of particles at once
                gravity: 1,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(),
            ),
            //BOTTOM CENTER
            Align(
              alignment: Alignment.bottomCenter,
              child: ConfettiWidget(
                confettiController: _controllerBottomCenter,
                blastDirection: -pi / 2,
                emissionFrequency: 0.01,
                numberOfParticles: 20,
                maxBlastForce: 100,
                minBlastForce: 80,
                gravity: 0.3,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 37, 2, 197),
        onPressed: (() {
          setState(() {
            controller.add(
              Fortune.randomInt(0, items.length),
            );
          });
        }),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
