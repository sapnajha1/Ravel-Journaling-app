import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of calling the delete-user Edge Function.
sealed class DeleteAccountOutcome {
  const DeleteAccountOutcome();
}

class DeleteAccountSuccess extends DeleteAccountOutcome {
  const DeleteAccountSuccess();
}

class DeleteAccountFailure extends DeleteAccountOutcome {
  const DeleteAccountFailure(this.message);
  final String message;
}

/// Calls the `delete-user` Supabase Edge Function to permanently delete the
/// authenticated user's account from Supabase Auth.
class DeleteAccountService {
  /// Deletes the current user's account. The Supabase client automatically
  /// sends the session token. Returns [DeleteAccountSuccess] on success,
  /// [DeleteAccountFailure] with an error message on failure.
  Future<DeleteAccountOutcome> deleteAccount() async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        return const DeleteAccountFailure('Not signed in');
      }

      if (kDebugMode) {
        debugPrint('[delete-user] Invoking Edge Function');
      }

      final response = await supabase.functions.invoke(
        'delete-user',
        body: <String, dynamic>{},
      );

      if (kDebugMode) {
        debugPrint('[delete-user] Status: ${response.status}');
      }

      if (response.status == 200) {
        return const DeleteAccountSuccess();
      }

      final data = response.data;
      String message = 'Account deletion failed';
      if (data is Map<String, dynamic> && data['error'] != null) {
        message = data['error'].toString();
      }
      return DeleteAccountFailure(message);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[delete-user] Error: $e\n$stack');
      }
      return DeleteAccountFailure(e.toString());
    }
  }
}
