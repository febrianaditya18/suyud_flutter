const express = require('express');
const mysql = require('mysql');
const axios = require('axios');
const app = express();
app.use(express.json());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '', 
    database: 'toko_madura'
});

db.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        return;
    }
    console.log('Connected to MySQL');
});

// Modify sendOtp function to return more detailed response
const sendOtp = async (phoneNumber, otp, expiresAt) => {
    const message = `Kode OTP Anda adalah: ${otp}. Harap gunakan dalam waktu 5 menit.`;
    try {
        // Send OTP via Fonnte
        const response = await axios.post(
            'https://api.fonnte.com/send/',
            {
                target: phoneNumber,
                message: message
            },
            {   
                headers: {
                    Authorization: '2hCSwufzbZKyv5s59FXP'
                }
            }
        );

        // Save OTP to database
        return new Promise((resolve, reject) => {
            db.query(
                'INSERT INTO otp_codes (phoneNumber, otp, expiresAt) VALUES (?, ?, ?)',
                [phoneNumber, otp, expiresAt],
                (error) => {
                    if (error) {
                        console.error('Error saving OTP:', error);
                        reject(error);
                    }
                    resolve(true);
                }
            );
        });
    } catch (error) {
        console.error('Error sending OTP:', error.response ? error.response.data : error.message);
        return false;
    }
};

// Registration Endpoint
app.post('/register', async (req, res) => {
    const { username, password, phoneNumber } = req.body;

    // Input validation
    if (!username || !password || !phoneNumber) {
        return res.status(400).json({ message: 'All fields are required' });
    }

    try {
        // Check if username exists
        const [existingUser] = await new Promise((resolve, reject) => {
            db.query('SELECT * FROM users WHERE username = ?', [username], (error, results) => {
                if (error) reject(error);
                resolve(results);
            });
        });

        if (existingUser) {
            return res.status(400).json({ message: 'Username already exists' });
        }

        // Generate OTP
        const otp = Math.floor(1000 + Math.random() * 9000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes expiry

        // Insert user and send OTP
        db.query(
            'INSERT INTO users (username, password, phoneNumber) VALUES (?, ?, ?)',
            [username, password, phoneNumber],
            async (insertErr) => {
                if (insertErr) {
                    console.error('Error inserting user:', insertErr);
                    return res.status(500).json({ error: 'Error inserting user' });
                }

                // Send OTP
                const otpSent = await sendOtp(phoneNumber, otp, expiresAt);
                
                if (otpSent) {
                    return res.status(201).json({ 
                        message: 'User registered successfully. OTP sent.',
                        phoneNumber: phoneNumber 
                    });
                } else {
                    return res.status(500).json({ message: 'Failed to send OTP' });
                }
            }
        );
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Server error. Please try again later.' });
    }
});

// OTP Verification Endpoint
// OTP Verification Endpoint
app.post('/verify-otp', (req, res) => {
    // Log the entire incoming request body
    console.log('Full Request Body:', JSON.stringify(req.body, null, 2));
    console.log('Request Headers:', JSON.stringify(req.headers, null, 2));

    const { 
        phoneNumber = '', 
        otp = '',
        otpCode = '',  // Add this line to catch alternative key
    } = req.body;

    // Use either otp or otpCode
    const verificationCode = otp || otpCode;

    console.log('Extracted Values:', {
        phoneNumber,
        verificationCode: verificationCode ? 'Code Provided' : 'Code Missing',
    });

    // Comprehensive validation with detailed error responses
    const errors = [];
    if (!phoneNumber) errors.push('Phone number is missing');
    if (!verificationCode) errors.push('OTP is missing');

    if (errors.length > 0) {
        return res.status(400).json({
            message: 'Validation Failed',
            errors: errors,
            receivedBody: req.body
        });
    }

    // Database query to verify OTP
    db.query(
        'SELECT * FROM otp_codes WHERE phoneNumber = ? AND otp = ? AND expiresAt > NOW()', 
        [phoneNumber, verificationCode],
        (error, otpResults) => {
            if (error) {
                console.error('Database query error:', error);
                return res.status(500).json({ 
                    message: 'Database query failed',
                    error: error.toString()
                });
            }

            console.log('OTP Query Results:', otpResults);

            if (otpResults.length === 0) {
                return res.status(400).json({ 
                    message: 'Invalid or expired OTP',
                    details: {
                        phoneNumber,
                        otpProvided: verificationCode
                    }
                });
            }

            // Mark user as verified
            db.query(
                'UPDATE users SET verified = 1 WHERE phoneNumber = ?', 
                [phoneNumber],
                (updateError) => {
                    if (updateError) {
                        console.error('Error updating user verification:', updateError);
                        return res.status(500).json({ 
                            message: 'Failed to verify user',
                            error: updateError.toString()
                        });
                    }

                    // Delete used OTP
                    db.query(
                        'DELETE FROM otp_codes WHERE phoneNumber = ?', 
                        [phoneNumber],
                        (deleteError) => {
                            if (deleteError) {
                                console.error('Error deleting OTP:', deleteError);
                            }

                            res.status(200).json({ 
                                message: 'OTP verified successfully',
                                phoneNumber: phoneNumber 
                            });
                        }
                    );
                }
            );
        }
    );
});
// Login Endpoint (Add this)
app.post('/login', (req, res) => {
    const { username, password } = req.body;

    db.query(
        'SELECT * FROM users WHERE username = ? AND password = ? AND verified = 1',
        [username, password],
        (error, results) => {
            if (error) {
                return res.status(500).json({ message: 'Server error' });
            }

            if (results.length > 0) {
                res.status(200).json({ message: 'Login successful' });
            } else {
                res.status(401).json({ message: 'Invalid credentials or account not verified' });
            }
        }
    );
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});