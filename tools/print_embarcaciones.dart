import 'dart:io';
import 'package:supabase/supabase.dart';

// Simple CLI to fetch and print first rows from `embarcacion` table.
// Usage (PowerShell):
// $env:SUPABASE_URL = "https://your-project.supabase.co"; $env:SUPABASE_KEY = "your-service-or-anon-key"; dart run tools/print_embarcaciones.dart

Future<void> main(List<String> args) async {
  final url = Platform.environment['SUPABASE_URL'] ?? '';
  final key = Platform.environment['SUPABASE_KEY'] ?? '';

  if (url.isEmpty || key.isEmpty) {
    print('ERROR: Set SUPABASE_URL and SUPABASE_KEY environment variables before running.');
    exit(1);
  }

  final client = SupabaseClient(url, key);

  try {
    print('Querying first 10 rows from "embarcacion"...');
    final data = await client
        .from('embarcacion')
        .select()
        .order('id_embarcacion')
        .limit(10);

    final rows = data is List ? data : [data];
    print('Got ${rows.length} rows.');
    for (var r in rows) {
      print('---');
      print(r);
    }
  } catch (e, st) {
    print('Exception while querying: $e\n$st');
    exit(1);
  } finally {
    client.dispose();
  }
}
