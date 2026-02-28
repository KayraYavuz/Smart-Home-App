import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yavuz_lock/blocs/passcode/passcode_cubit.dart';
import 'package:yavuz_lock/repositories/ttlock_repository.dart';
import 'package:yavuz_lock/create_passcode_page.dart';
import 'package:yavuz_lock/services/passcode_model.dart';
import 'package:yavuz_lock/l10n/app_localizations.dart';

class PasscodePage extends StatelessWidget {
  final int lockId;
  final String clientId;
  final String accessToken;
  final Map<String, dynamic> lock; // Added lock object

  const PasscodePage({
    super.key,
    required this.lockId,
    required this.clientId,
    required this.accessToken,
    required this.lock, // Added lock object
  });

  String _getPasscodeType(int type, AppLocalizations l10n) {
    switch (type) {
      case 1:
        return l10n.tabOneTime;
      case 2:
        return l10n.tabPermanent;
      case 3:
        return l10n.tabTimed;
      case 4:
        return l10n.tabRecurring;
      default:
        return l10n.unknownType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocProvider(
      create: (context) => PasscodeCubit(context.read<TTLockRepository>())
        ..fetchPasscodes(lockId, clientId, accessToken),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: Text(l10n.passcodesTitle),
        ),
        body: BlocBuilder<PasscodeCubit, PasscodeState>(
          builder: (context, state) {
            if (state is PasscodeLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PasscodeLoadFailure) {
              return Center(
                  child: Text(state.error,
                      style: const TextStyle(color: Colors.redAccent)));
            }
            if (state is PasscodeLoadSuccess) {
              if (state.passcodes.isEmpty) {
                return Center(
                    child: Text(l10n.noPasscodesFound,
                        style: const TextStyle(color: Colors.white)));
              }
              return ListView.builder(
                itemCount: state.passcodes.length,
                itemBuilder: (context, index) {
                  final Passcode passcode = state.passcodes[index];
                  return ListTile(
                    leading: const Icon(Icons.password, color: Color(0xFF1E90FF)),
                    title: Text(passcode.keyboardPwd,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${passcode.keyboardPwdName} | ${l10n.typePrefix}: ${_getPasscodeType(passcode.keyboardPwdType, l10n)}',
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        // TODO: Implement delete passcode functionality using Cubit
                        debugPrint('Deleting ${passcode.keyboardPwd}');
                      },
                    ),
                  );
                },
              );
            }
            return Center(child: Text(l10n.startingMessage));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePasscodePage(lock: lock)),
            );
          },
          backgroundColor: const Color(0xFF1E90FF),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
