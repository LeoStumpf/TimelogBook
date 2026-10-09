// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Timelog Book – a simple time logbook.
// Copyright (C) 2026 Leo Stumpf
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details. You should have received a copy of the GNU Affero General Public
// License along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

import 'services/app_services.dart';
import 'ui/home_screen.dart';
import 'ui/logbook_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final LogbookModel model;
  final services = await AppServices.create(
    // Buttons pressed while the app runs still go through the background handler;
    // here only taps on the notification itself arrive, which just open the app.
    onResponse: (_) => model.reload(),
  );
  model = LogbookModel(services);
  await model.reload();
  runApp(TimelogBookApp(model: model));
  await services.notifications.requestPermission();
  await services.logging.restoreNotification();
}

class TimelogBookApp extends StatelessWidget {
  const TimelogBookApp({super.key, required this.model});

  final LogbookModel model;

  @override
  Widget build(BuildContext context) {
    const seed = Colors.teal;
    return MaterialApp(
      title: 'Timelog Book',
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: HomeScreen(model: model),
    );
  }
}
