import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://eowvprknwokacnmickgt.supabase.co/rest/v1/categories?select=*');
  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvd3Zwcmtud29rYWNubWlja2d0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNjEzNDMsImV4cCI6MjEwMjYzNzM0M30.R05NbGYQe0ZutTXIlOXAVVbs1jcEucNqu_ARfK6GvJI',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvd3Zwcmtud29rYWNubWlja2d0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwNjEzNDMsImV4cCI6MjEwMjYzNzM0M30.R05NbGYQe0ZutTXIlOXAVVbs1jcEucNqu_ARfK6GvJI',
  };

  final response = await http.get(url, headers: headers);
  print('Categories status: ' + response.statusCode.toString());
  print('Categories body: ' + response.body);

  final expUrl = Uri.parse('https://eowvprknwokacnmickgt.supabase.co/rest/v1/expenses?select=*&limit=5');
  final expResponse = await http.get(expUrl, headers: headers);
  print('Expenses status: ' + expResponse.statusCode.toString());
  print('Expenses body: ' + expResponse.body);
}
