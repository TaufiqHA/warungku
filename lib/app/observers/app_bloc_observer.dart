import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC Observer untuk logging transisi state dan error
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('BLoC Change [${bloc.runtimeType}]: currentState=${change.currentState} -> nextState=${change.nextState}', name: 'BLoC');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('BLoC Error [${bloc.runtimeType}]: $error', name: 'BLoC', error: error, stackTrace: stackTrace);
  }
}
