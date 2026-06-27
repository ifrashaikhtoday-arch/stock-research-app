import 'package:flutter/material.dart';

// A global navigator key lets us navigate to a specific screen (like
// opening a stock's detail page) from places that don't have a normal
// BuildContext available -- such as when the user taps a push
// notification. main.dart attaches this key to the MaterialApp, and
// auth_service.dart uses it to navigate when a notification is tapped.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();