import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://eowvprknwokacnmickgt.supabase.co/rest/v1/categories?select=*');
  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvd3Zwcmtud29rYWNubWlja2d0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNjEzNDMsImV4cCI6MjEwMjYzNzM0M30.R05NbGYQe0ZutTXIlOXAVVbs1jcEucNqu_ARfK6GvJI',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvd3Zwcmtud29rYWNubWlja2d0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNjEzNDMsImV4cCI6MjEwMjYzNzM0M30.R05NbGYQe0ZutTXIlOXAVVbs1jcEucNqu_ARfK6GvJI',
    'Prefer': 'return=representation'
  };

  // Try to insert a dummy category to see the schema response or just one valid one.
  final postUrl = Uri.parse('https://eowvprknwokacnmickgt.supabase.co/rest/v1/categories');
  final body = jsonEncode({
    'name': 'Test',
    'family_id': 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'
  });
  
  final res = await http.post(postUrl, headers: {...headers, 'Content-Type': 'application/json'}, body: body);
  print('Insert status: ' + res.statusCode.toString());
  print('Insert body: ' + res.body);
  
  if (res.statusCode == 400 && res.body.contains('family_id')) {
     print('No family_id column exists. Retrying without it.');
  }
}
