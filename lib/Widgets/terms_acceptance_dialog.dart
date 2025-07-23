import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';  // Keep only this import
import '../terms_conditions.dart';

class TermsAcceptanceDialog extends StatefulWidget {
  @override
  _TermsAcceptanceDialogState createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<TermsAcceptanceDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Terms and Conditions'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please read and accept our Terms and Conditions to continue.'),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsConditionsPage()),
              );
            },
            child: Text('Read Terms and Conditions'),
          ),
          Row(
            children: [
              Checkbox(
                value: _accepted,
                onChanged: (bool? value) {
                  setState(() {
                    _accepted = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text('I accept the Terms and Conditions'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text('Decline'),
        ),
        ElevatedButton(
          onPressed: _accepted
              ? () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('terms_accepted', true);
                  Navigator.of(context).pop(true);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen,
          ),
          child: Text('Accept'),
        ),
      ],
    );
  }
} 