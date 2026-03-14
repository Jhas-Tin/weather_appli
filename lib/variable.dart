import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';


final darkModeProvider = StateProvider((ref) => true);
final cityProvider = StateProvider<String>((ref) => "Arayat");
final isCelsiusProvider = StateProvider<bool>((ref) => true);
final useCurrentLocationProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);