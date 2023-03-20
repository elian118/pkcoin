import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class Buttons extends StatelessWidget {
  final String myAddress;
  final void Function(String target) getBalance;
  final void Function() sendCoin;
  final void Function() withdrawCoin;

  const Buttons({
    Key? key,
    required this.myAddress,
    required this.getBalance,
    required this.sendCoin,
    required this.withdrawCoin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> buttons = [
      {
        "name": '갱신',
        "icon": Icons.refresh,
        "color": Colors.blue,
        "fn": () => getBalance(myAddress)
      },
      {
        "name": '입금',
        "icon": Icons.call_made_outlined,
        "color": Colors.green,
        "fn": () => sendCoin()
      },
      {
        "name": '인출',
        "icon": Icons.call_received_outlined,
        "color": Colors.red,
        "fn": () => withdrawCoin()
      }
    ];

    return HStack(
      [
        for (var button in buttons)
          TextButton.icon(
            onPressed: button['fn'],
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(button['color']),
            ),
            icon: Icon(
              button['icon'],
              color: Colors.white,
            ),
            label: button['name'].toString().text.white.make(),
          ).h(50).w(90),
      ],
      alignment: MainAxisAlignment.spaceAround,
      axisSize: MainAxisSize.max,
    ).p16();
  }
}
