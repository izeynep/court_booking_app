import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kort Rezervasyon')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'KortSaha',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dakikalar içinde kortunu ayırt.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AppRouter.goLogin(context),
              child: const Text('Giriş Yap'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => AppRouter.goRegister(context),
              child: const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
