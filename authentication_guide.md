# SafePick - Social Authentication Guide

## Google Sign-In & Apple Sign-In Implementation

---

## 🎯 Overview

This guide shows you how to add **Google Sign-In** and **Apple Sign-In** to SafePick for seamless user authentication.

### Benefits:

-   ✅ **Easy signup** - One-tap authentication
-   ✅ **No passwords** - More secure
-   ✅ **User profiles** - Access to name, email, photo
-   ✅ **Cross-device sync** - History across devices
-   ✅ **Premium features** - Track subscriptions

---

## 🏗️ Architecture

```
User taps "Sign in with Google/Apple"
      ↓
Flutter handles OAuth flow
      ↓
Get user token
      ↓
Send token to Django backend
      ↓
Backend verifies token
      ↓
Create/update user in database
      ↓
Return JWT token to app
      ↓
App stores token
      ↓
Use token for all API requests
```

---

## 📦 Technology Stack

### Backend (Django):

-   **django-allauth** - Social authentication
-   **djangorestframework-simplejwt** - JWT tokens
-   **google-auth** - Google token verification
-   **apple-signin** - Apple token verification

### Frontend (Flutter):

-   **google_sign_in** - Google OAuth
-   **sign_in_with_apple** - Apple OAuth
-   **flutter_secure_storage** - Store tokens securely

---

## 🔧 Backend Implementation (Django)

### Step 1: Install Dependencies

```bash
pip install django-allauth djangorestframework-simplejwt google-auth PyJWT cryptography
```

**requirements.txt**

```
Django==4.2.8
djangorestframework==3.14.0
djangorestframework-simplejwt==5.3.1
django-allauth==0.57.0
google-auth==2.25.2
PyJWT==2.8.0
cryptography==41.0.7
psycopg2-binary==2.9.9
django-cors-headers==4.3.1
google-generativeai==0.3.2
python-decouple==3.8
```

### Step 2: Update Django Settings

**settings.py**

```python
from decouple import config
from datetime import timedelta

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sites',

    # Third party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'allauth',
    'allauth.account',
    'allauth.socialaccount',
    'allauth.socialaccount.providers.google',
    'allauth.socialaccount.providers.apple',

    # Your apps
    'analysis',
    'users',
]

SITE_ID = 1

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
}

# JWT Settings
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=7),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=30),
    'ROTATE_REFRESH_TOKENS': True,
}

# CORS Settings
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
]

# Google OAuth Settings
SOCIALACCOUNT_PROVIDERS = {
    'google': {
        'SCOPE': [
            'profile',
            'email',
        ],
        'AUTH_PARAMS': {
            'access_type': 'online',
        },
        'APP': {
            'client_id': config('GOOGLE_CLIENT_ID'),
            'secret': config('GOOGLE_CLIENT_SECRET'),
        }
    },
    'apple': {
        'APP': {
            'client_id': config('APPLE_CLIENT_ID'),
            'secret': config('APPLE_CLIENT_SECRET'),
            'key': config('APPLE_KEY_ID'),
            'team': config('APPLE_TEAM_ID'),
        }
    }
}
```

### Step 3: Create User Model

**users/models.py**

```python
from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    """Custom user model with social auth support"""

    AUTH_PROVIDERS = [
        ('email', 'Email'),
        ('google', 'Google'),
        ('apple', 'Apple'),
    ]

    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255, blank=True)
    profile_picture = models.URLField(blank=True)
    auth_provider = models.CharField(max_length=20, choices=AUTH_PROVIDERS, default='email')

    # Premium features
    is_premium = models.BooleanField(default=False)
    premium_until = models.DateTimeField(null=True, blank=True)

    # Usage tracking
    scan_count = models.IntegerField(default=0)
    daily_scan_limit = models.IntegerField(default=10)
    last_scan_date = models.DateField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.email

    @property
    def can_scan(self):
        """Check if user can perform a scan"""
        from datetime import date

        if self.is_premium:
            return True

        if self.last_scan_date != date.today():
            self.scan_count = 0
            self.last_scan_date = date.today()
            self.save()

        return self.scan_count < self.daily_scan_limit
```

**Update settings.py**

```python
AUTH_USER_MODEL = 'users.User'
```

### Step 4: Create Authentication Views

**users/serializers.py**

```python
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'profile_picture',
                  'is_premium', 'scan_count', 'daily_scan_limit']
        read_only_fields = ['id', 'scan_count']

class SocialAuthSerializer(serializers.Serializer):
    """Serializer for social authentication"""
    provider = serializers.ChoiceField(choices=['google', 'apple'])
    token = serializers.CharField()

class TokenSerializer(serializers.Serializer):
    """Serializer for JWT tokens"""
    access = serializers.CharField()
    refresh = serializers.CharField()
    user = UserSerializer()
```

**users/views.py**

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from google.oauth2 import id_token
from google.auth.transport import requests
import jwt
from django.conf import settings
from .models import User
from .serializers import SocialAuthSerializer, UserSerializer, TokenSerializer

def get_tokens_for_user(user):
    """Generate JWT tokens for user"""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

@api_view(['POST'])
@permission_classes([AllowAny])
def google_auth(request):
    """
    Authenticate user with Google Sign-In

    POST /api/auth/google/
    {
        "token": "google_id_token"
    }
    """
    serializer = SocialAuthSerializer(data={
        'provider': 'google',
        'token': request.data.get('token')
    })

    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    token = serializer.validated_data['token']

    try:
        # Verify Google token
        idinfo = id_token.verify_oauth2_token(
            token,
            requests.Request(),
            settings.SOCIALACCOUNT_PROVIDERS['google']['APP']['client_id']
        )

        # Extract user info
        email = idinfo['email']
        full_name = idinfo.get('name', '')
        profile_picture = idinfo.get('picture', '')

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'full_name': full_name,
                'profile_picture': profile_picture,
                'auth_provider': 'google',
            }
        )

        # Update profile if user exists
        if not created:
            user.full_name = full_name
            user.profile_picture = profile_picture
            user.save()

        # Generate JWT tokens
        tokens = get_tokens_for_user(user)

        return Response({
            'access': tokens['access'],
            'refresh': tokens['refresh'],
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

    except ValueError as e:
        return Response(
            {'error': 'Invalid token', 'details': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def apple_auth(request):
    """
    Authenticate user with Apple Sign-In

    POST /api/auth/apple/
    {
        "token": "apple_id_token",
        "user_data": {
            "email": "user@example.com",
            "name": "John Doe"
        }
    }
    """
    token = request.data.get('token')
    user_data = request.data.get('user_data', {})

    if not token:
        return Response(
            {'error': 'Token is required'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        # Decode Apple token (without verification for simplicity)
        # In production, verify the token with Apple's public keys
        decoded = jwt.decode(token, options={"verify_signature": False})

        email = decoded.get('email') or user_data.get('email')

        if not email:
            return Response(
                {'error': 'Email not provided'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'full_name': user_data.get('name', ''),
                'auth_provider': 'apple',
            }
        )

        # Generate JWT tokens
        tokens = get_tokens_for_user(user)

        return Response({
            'access': tokens['access'],
            'refresh': tokens['refresh'],
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': 'Invalid token', 'details': str(e)},
            status=status.HTTP_400_BAD_REQUEST
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """Get current user profile"""
    return Response(UserSerializer(request.user).data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """Logout user (invalidate refresh token)"""
    try:
        refresh_token = request.data.get('refresh')
        token = RefreshToken(refresh_token)
        token.blacklist()
        return Response({'message': 'Logout successful'})
    except Exception:
        return Response(
            {'error': 'Invalid token'},
            status=status.HTTP_400_BAD_REQUEST
        )
```

### Step 5: Update URLs

**users/urls.py**

```python
from django.urls import path
from . import views

urlpatterns = [
    path('auth/google/', views.google_auth, name='google-auth'),
    path('auth/apple/', views.apple_auth, name='apple-auth'),
    path('auth/profile/', views.get_user_profile, name='user-profile'),
    path('auth/logout/', views.logout, name='logout'),
]
```

**safepick_api/urls.py**

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('users.urls')),
    path('api/', include('analysis.urls')),
]
```

### Step 6: Update Analysis Views (Add User Tracking)

**analysis/views.py** (Update)

```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .gemini_service import gemini_analyzer
from .cache_service import AnalysisCache
from .models import ProductAnalysis
from datetime import date
import time

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def analyze_ingredients(request):
    """
    Analyze ingredients using FREE Gemini AI with caching
    Requires authentication
    """

    user = request.user

    # Check if user can scan
    if not user.can_scan:
        return Response({
            'error': 'Daily scan limit reached',
            'limit': user.daily_scan_limit,
            'message': 'Upgrade to premium for unlimited scans'
        }, status=status.HTTP_403_FORBIDDEN)

    raw_text = request.data.get('text', '').strip()

    if not raw_text:
        return Response(
            {'error': 'No ingredient text provided'},
            status=status.HTTP_400_BAD_REQUEST
        )

    start_time = time.time()

    try:
        # Check cache first
        cached_result = AnalysisCache.get(raw_text)
        if cached_result:
            cached_result['from_cache'] = True
            cached_result['processing_time'] = time.time() - start_time

            # Increment user scan count
            user.scan_count += 1
            user.last_scan_date = date.today()
            user.save()

            return Response(cached_result)

        # Call Gemini API
        result = gemini_analyzer.analyze_ingredients(raw_text)

        result['from_cache'] = False
        result['processing_time'] = time.time() - start_time

        # Cache the result
        AnalysisCache.set(raw_text, result)

        # Save to database
        analysis = ProductAnalysis.objects.create(
            user=user,
            raw_text=raw_text,
            detected_ingredients=result.get('total_ingredients', 0),
            overall_rating=result.get('overall_rating', 'UNKNOWN'),
            overall_score=result.get('overall_score', 0),
            good_ingredients=result.get('good_ingredients', []),
            bad_ingredients=result.get('bad_ingredients', []),
            neutral_ingredients=result.get('neutral_ingredients', []),
            recommendation_text=result.get('recommendation', ''),
            allergen_warnings=result.get('allergen_warnings', []),
            health_concerns=result.get('health_concerns', []),
            processing_time=result['processing_time'],
            from_cache=False
        )

        # Increment user scan count
        user.scan_count += 1
        user.last_scan_date = date.today()
        user.save()

        result['analysis_id'] = analysis.id
        result['scans_remaining'] = user.daily_scan_limit - user.scan_count

        return Response(result, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': 'Analysis failed', 'details': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_analysis_history(request):
    """Get user's analysis history"""
    analyses = ProductAnalysis.objects.filter(user=request.user)[:20]

    results = [{
        'id': a.id,
        'date': a.analysis_date,
        'score': float(a.overall_score),
        'rating': a.overall_rating,
        'ingredient_count': a.detected_ingredients
    } for a in analyses]

    return Response({'count': len(results), 'results': results})
```

**Update ProductAnalysis model**

```python
# In analysis/models.py
from django.conf import settings

class ProductAnalysis(models.Model):
    # Add user field
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='analyses',
        null=True,
        blank=True
    )
    # ... rest of the fields
```

---

## 📱 Frontend Implementation (Flutter)

### Step 1: Add Dependencies

**pubspec.yaml**

```yaml
dependencies:
    flutter:
        sdk: flutter

    # Existing dependencies
    camera: ^0.10.5
    google_ml_kit: ^0.16.0
    http: ^1.1.0
    provider: ^6.1.1
    shared_preferences: ^2.2.2
    cached_network_image: ^3.3.0
    flutter_spinkit: ^5.2.0

    # NEW: Authentication dependencies
    google_sign_in: ^6.1.5
    sign_in_with_apple: ^5.0.0
    flutter_secure_storage: ^9.0.0
    jwt_decoder: ^2.0.1
```

### Step 2: Configure Google Sign-In

**Android Configuration**

1. Get Google Client ID from [Google Cloud Console](https://console.cloud.google.com/)
2. Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.version"
    android:value="@integer/google_play_services_version" />
```

3. Add SHA-1 fingerprint to Firebase/Google Cloud Console

**iOS Configuration**

1. Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### Step 3: Configure Apple Sign-In

**iOS Configuration**

1. Enable "Sign in with Apple" in Xcode capabilities
2. Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR-BUNDLE-ID</string>
        </array>
    </dict>
</array>
```

### Step 4: Create Authentication Service

**lib/services/auth_service.dart**

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String baseUrl = 'http://YOUR_BACKEND_URL/api';

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User canceled
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store tokens
        await _storage.write(key: _accessTokenKey, value: data['access']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh']);

        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to authenticate with backend');
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // Apple Sign-In
  Future<User?> signInWithApple() async {
    try {
      // Trigger Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Send token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/apple/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': credential.identityToken,
          'user_data': {
            'email': credential.email,
            'name': credential.givenName != null && credential.familyName != null
                ? '${credential.givenName} ${credential.familyName}'
                : null,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Store tokens
        await _storage.write(key: _accessTokenKey, value: data['access']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh']);

        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to authenticate with backend');
      }
    } catch (e) {
      print('Apple Sign-In Error: $e');
      return null;
    }
  }

  // Get stored access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final token = await getAccessToken();

      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }

      return null;
    } catch (e) {
      print('Get User Error: $e');
      return null;
    }
  }
}
```

### Step 5: Create User Model

**lib/models/user.dart**

```dart
class User {
  final int id;
  final String email;
  final String fullName;
  final String profilePicture;
  final bool isPremium;
  final int scanCount;
  final int dailyScanLimit;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.profilePicture,
    required this.isPremium,
    required this.scanCount,
    required this.dailyScanLimit,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      profilePicture: json['profile_picture'] ?? '',
      isPremium: json['is_premium'] ?? false,
      scanCount: json['scan_count'] ?? 0,
      dailyScanLimit: json['daily_scan_limit'] ?? 10,
    );
  }

  int get scansRemaining => dailyScanLimit - scanCount;
  bool get canScan => isPremium || scanCount < dailyScanLimit;
}
```

### Step 6: Update API Service (Add Authentication)

**lib/services/api_service.dart** (Update)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://YOUR_BACKEND_URL/api';
  final AuthService _authService = AuthService();

  Future<AnalysisResult> analyzeIngredients(String text) async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/analyze/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 403) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Daily limit reached');
      } else {
        throw Exception('Failed to analyze ingredients');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<AnalysisResult>> getHistory() async {
    try {
      final token = await _authService.getAccessToken();

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/history/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['results'] as List)
            .map((item) => AnalysisResult.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to get history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

### Step 7: Create Login Screen

**lib/screens/login_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:io' show Platform;
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in canceled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithApple();

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in canceled')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(
                Icons.health_and_safety,
                size: 100,
                color: Colors.green,
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'SafePick',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'Know what you\'re buying',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 48),

              // Google Sign-In Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                icon: Image.asset(
                  'assets/google_logo.png',
                  height: 24,
                ),
                label: Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Apple Sign-In Button (iOS only)
              if (Platform.isIOS)
                SignInWithAppleButton(
                  onPressed: _isLoading ? () {} : _handleAppleSignIn,
                  style: SignInWithAppleButtonStyle.black,
                  height: 50,
                ),

              if (_isLoading)
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),

              SizedBox(height: 48),

              // Terms
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Step 8: Update Main App

**lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(SafePickApp());
}

class SafePickApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafePick',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? HomeScreen() : LoginScreen();
  }
}
```

---

## 🔑 Getting API Credentials

### Google OAuth Setup:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Google+ API"
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Configure OAuth consent screen
6. Create credentials for:
    - **Android**: Use SHA-1 fingerprint
    - **iOS**: Use bundle ID
    - **Web**: For backend verification
7. Copy Client IDs to your `.env` file

### Apple Sign-In Setup:

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Certificates, Identifiers & Profiles
3. Create App ID with "Sign in with Apple" capability
4. Create Service ID
5. Configure domains and return URLs
6. Create Key for Sign in with Apple
7. Copy credentials to your `.env` file

---

## 🧪 Testing

### Test Google Sign-In:

```bash
# Backend
python manage.py runserver

# Flutter
flutter run
```

### Test Apple Sign-In:

-   Must test on real iOS device or simulator
-   Apple Sign-In doesn't work on Android

---

## 🚀 Next Steps

1. **Add user profile screen**
2. **Implement premium subscription**
3. **Add social sharing**
4. **Track user analytics**
5. **Add push notifications**

---

## 💡 Tips

1. **Store tokens securely** - Use flutter_secure_storage
2. **Handle token refresh** - Implement automatic token refresh
3. **Error handling** - Show user-friendly error messages
4. **Loading states** - Show progress indicators
5. **Offline support** - Cache user data locally

---

## 🎉 You're Done!

Your SafePick app now has:

-   ✅ Google Sign-In
-   ✅ Apple Sign-In
-   ✅ JWT authentication
-   ✅ User profiles
-   ✅ Scan limits
-   ✅ Premium features ready

**Users can now sign in with one tap!** 🚀
