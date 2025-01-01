import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Madura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

// login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

Future<void> loginUser() async {
  final username = _usernameController.text;
  final password = _passwordController.text;

  // Input validation
  if (username.isEmpty || password.isEmpty) {
    _showErrorDialog('Username dan password harus diisi.');
    return;
  }

  final url = Uri.parse('http://10.0.2.2:3000/login');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    // Parse response body
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 1),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          pageBuilder: (context, animation, secondaryAnimation) {
            return DashboardPage(username: username);
          },
        ),
      );
    } else {
      // More detailed error handling
      _showErrorDialog(responseData['message'] ?? 'Login gagal.');
    }
  } catch (e) {
    _showErrorDialog('Tidak dapat terhubung ke server: $e');
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Toko Madura'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/madura.jpg',
                  height: 175,
                  width: 250,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: loginUser,
                  child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('Belum punya akun? Registrasi di sini'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// Halaman Registrasi
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

 Future<void> registerUser() async {
  final username = _usernameController.text;
  final password = _passwordController.text;
  final phone = _phoneNumberController.text;

  // Enhanced validation
  if (username.isEmpty || password.isEmpty || phone.isEmpty) {
    _showErrorDialog('Semua field harus diisi.');
    return;
  }

  // Validate phone number format (example)
  if (!RegExp(r'^[0-9]{10,12}$').hasMatch(phone)) {
    _showErrorDialog('Nomor telepon tidak valid. Gunakan 10-12 digit.');
    return;
  }

  // Validate password strength
  if (password.length < 6) {
    _showErrorDialog('Password harus minimal 6 karakter.');
    return;
  }

  final url = Uri.parse('http://10.0.2.2:3000/register');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'phoneNumber': phone,
      }),
    );

    // Parse response body
    final responseData = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      _showSuccessDialog('Registrasi berhasil! Silakan verifikasi OTP.');
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OTPVerificationPage(phoneNumber: phone)),
      );
    } else {
      // More detailed error handling
      _showErrorDialog(responseData['message'] ?? 'Registrasi gagal.');
    }
  } catch (e) {
    _showErrorDialog('Tidak dapat terhubung ke server: $e');
  }
}

  // Future<void> sendOtpVerification(String phoneNumber) async {
  //   // API Endpoint Fonnte
  //   final url = Uri.parse('https://api.fonnte.com/send');

  //   // OTP Code
  //   final otpCode = (1000 + (9999 - 1000) * (DateTime.now().millisecondsSinceEpoch % 1000)).toString();

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Authorization': '2hCSwufzbZKyv5s59FXP', // Ganti dengan token Fonnte Anda
  //         'Content-Type': 'application/json'
  //       },
  //       body: jsonEncode({
  //         'target': phoneNumber,
  //         'message': 'Kode OTP Anda adalah $otpCode',
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       print('OTP berhasil dikirim.');
  //     } else {
  //       print('Gagal mengirim OTP: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Error mengirim OTP: $e');
  //   }
  // }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrasi Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrasi Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Registrasi Akun'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: registerUser,
                  child: const Text('Register', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// Halaman Dashboard (Daftar Produk)
class DashboardPage extends StatelessWidget {
  final String username;

  DashboardPage({super.key, required this.username});

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Malboro merah',
      'price': 40000,
      'image': 'assets/images/image.jpg',
    },
    {
      'name': 'Sampoerna Mild',
      'price': 35000,
      'image': 'assets/images/image2.jpg',
    },
    {
      'name': 'Esse',
      'price': 50000,
      'image': 'assets/images/image3.jpg',
    },
    {
      'name': 'Malboro Hitam',
      'price': 32000,
      'image': 'assets/images/image4.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $username'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2 / 3,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.asset(
                      product['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Rp${product['price']}',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Tambahkan Halaman OTP
class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> verifyOTP() async {
    // Validate OTP input
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty || otp.length != 4) {
      _showErrorDialog('Masukkan kode OTP 4 digit yang valid.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:3000/verify-otp');
  
    try {
      // Detailed logging
      print('Verification Attempt Details:');
      print('Phone Number: ${widget.phoneNumber}');
      print('OTP: $otp');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'phoneNumber': widget.phoneNumber, 
          'otp': otp
        }),
      );

      // More comprehensive logging
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Parse response body safely
      final responseData = response.body.isNotEmpty 
        ? jsonDecode(response.body) 
        : {};

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showSuccessDialog('Verifikasi Berhasil');
      } else {
        // More detailed error handling
        final errorMessage = responseData['message'] ?? 
          responseData['errors']?.join(', ') ?? 
          'Verifikasi OTP gagal';
        
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Verification Error: $e');
      _showErrorDialog('Tidak dapat terhubung ke server: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Masukkan Kode OTP yang dikirim ke WhatsApp: ${widget.phoneNumber}'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 20),
            _isLoading 
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: verifyOTP,
                  child: const Text('Verifikasi'),
                ),
          ],
        ),
      ),
    );
  }
}

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Berhasil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Masukkan Kode OTP yang dikirim ke WhatsApp: ${widget.phoneNumber}'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4, // Limit to 4 digits
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOTP,
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Masukkan Kode OTP yang dikirim ke WhatsApp Anda'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Kode OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOTP,
              child: const Text('Verifikasi'),
            ),
          ],
        ),
      ),
    );
  }
}
