import 'package:flutter/material.dart';

import '../data.dart';
import '../state/app_services.dart';
import '../theme.dart';
import '../widgets.dart';

/// Bottom sheets for honest manual logging (used on devices without the
/// hardware step sensor, and for anything the sensor cannot see).

Future<void> showLogStepsSheet(BuildContext context) async {
  int hops = 500;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: ToadColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Log a walk', style: ToadText.h2),
                const SizedBox(height: 4),
                Text('every honest hop counts', style: ToadText.label),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final v in const [100, 250, 500, 1000, 2500])
                      SketchButton(
                        onTap: () => setSheet(() => hops = v),
                        background:
                            hops == v ? ToadColors.toadLight : ToadColors.paper,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Text(
                          '+$v',
                          style: TextStyle(
                            fontFamily: 'PatrickHand',
                            fontSize: 15,
                            color: ToadColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SketchButton(
                  onTap: () {
                    AppServices.controller.addSteps(hops, manual: true);
                    Navigator.of(context).pop();
                  },
                  background: ToadColors.toad,
                  borderColor: ToadColors.toadDeep,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Add ${fmtNumber(hops)} hops',
                      style: TextStyle(
                        fontFamily: 'PatrickHand',
                        fontSize: 16,
                        color: ToadColors.paper,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showLogSleepSheet(BuildContext context) async {
  int hours = 7;
  int minutes = 30;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: ToadColors.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheet) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Log last night', style: ToadText.h2),
                const SizedBox(height: 4),
                Text('rest is real data too', style: ToadText.label),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SketchButton(
                      onTap: () =>
                          setSheet(() => hours = (hours - 1).clamp(0, 16)),
                      padding: const EdgeInsets.all(10),
                      radius: 20,
                      child: Text(
                        '-',
                        style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: ToadColors.ink),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('$hours h', style: ToadText.h1),
                    const SizedBox(width: 14),
                    SketchButton(
                      onTap: () =>
                          setSheet(() => hours = (hours + 1).clamp(0, 16)),
                      padding: const EdgeInsets.all(10),
                      radius: 20,
                      child: Text(
                        '+',
                        style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: ToadColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SketchButton(
                      onTap: () => setSheet(
                          () => minutes = ((minutes - 15) % 60 + 60) % 60),
                      padding: const EdgeInsets.all(10),
                      radius: 20,
                      child: Text(
                        '-',
                        style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: ToadColors.ink),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('${minutes.toString().padLeft(2, '0')} m',
                        style: ToadText.h1),
                    const SizedBox(width: 14),
                    SketchButton(
                      onTap: () => setSheet(() => minutes = (minutes + 15) % 60),
                      padding: const EdgeInsets.all(10),
                      radius: 20,
                      child: Text(
                        '+',
                        style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: ToadColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SketchButton(
                  onTap: () {
                    AppServices.controller.logSleep(hours * 60 + minutes);
                    Navigator.of(context).pop();
                  },
                  background: ToadColors.moss,
                  borderColor: ToadColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'Save ${hours}h ${minutes.toString().padLeft(2, '0')}m',
                      style: TextStyle(
                        fontFamily: 'PatrickHand',
                        fontSize: 16,
                        color: ToadColors.cream,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      );
    },
  );
}
