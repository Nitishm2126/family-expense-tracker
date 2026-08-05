import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = Uri.parse(
    'https://script.google.com/macros/s/AKfycbzFjufgDACateagI5E0aWXdm6_8J4MUYtYb4mGefaZL_gGf6Um8xuUI6jot9aBo/exec',
  );

  Future<String> testPost(String label, Map<String, dynamic> payload) async {
    print('\n=== $label ===');
    try {
      final res = await http.post(
        baseUrl,
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode(payload),
      );
      if (res.statusCode == 302) {
        final res2 = await http.get(Uri.parse(res.headers['location']!));
        print('Response: ${res2.body}');
        return res2.body;
      }
      print('Response: ${res.body}');
      return res.body;
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  // First get the actual expense from the sheet to see the real ExpenseID
  final getRes = await http.get(
    baseUrl.replace(queryParameters: {'action': 'getExpenses'}),
  );
  print('GET EXPENSES:');
  print(getRes.body);
  
  // Add a fresh expense
  final addResult = await testPost('ADD EXPENSE', {
    'action': 'addExpense',
    'Member': 'Nithish',
    'Category': 'Food',
    'Description': 'Test for ID key format',
    'Amount': 100.0,
    'Payment Mode': 'Cash',
    'Date': '2026-08-05',
    'Time': '9:00 PM',
    'Remarks': '',
  });
  String? expId;
  try { expId = (jsonDecode(addResult)['data'] as Map)['Id'] as String?; } catch(_) {}
  print('Expense ID from add: $expId');
  
  // Wait a bit then get expenses to see if the Id in the GET response matches
  await Future.delayed(const Duration(seconds: 2));
  final getRes2 = await http.get(
    baseUrl.replace(queryParameters: {'action': 'getExpenses'}),
  );
  print('GET EXPENSES after add:');
  print(getRes2.body);
  
  if (expId != null) {
    // Try ExpenseID (exact field name from GET response)
    await testPost('UPDATE - ExpenseID', {
      'action': 'updateExpense',
      'ExpenseID': expId,
      'Member': 'Nithish',
      'Category': 'Transport',
      'Description': 'Updated',
      'Amount': 150.0,
      'Payment Mode': 'UPI',
      'Date': '2026-08-05',
      'Time': '10:00 PM',
      'Remarks': '',
    });
    
    await testPost('DELETE - ExpenseID', {
      'action': 'deleteExpense',
      'ExpenseID': expId,
    });
  }
  
  print('\n=== DONE ===');
}
