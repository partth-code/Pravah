import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/state_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    if (_formKey.currentState?.validate() != true) return;
    setState(() { _verifying = true; _error = null; });
    final isOk = context.read<StateService>().verifyOtp(_otpController.text);
    setState(() => _verifying = false);
    if (isOk) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _error = 'Invalid OTP. Try 031006');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.watch<StateService>().pendingPhoneNumber;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OTP sent to: $phone',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter 6-digit OTP',
                    counterText: '',
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'OTP is required';
                    if (value.length != 6) return 'Enter 6 digits';
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    child: _verifying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Mock OTP is 031006', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


