import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const AuthController = () => import('./auth.controller.js');

// Public routes (no JWT)
router
  .group(() => {
    router.post('/login', [AuthController, 'login']);
    router.post('/register', [AuthController, 'register']);
  })
  .prefix('/api/auth');

// JWT-protected routes
router
  .group(() => {
    router.post('/logout', [AuthController, 'logout']);
    router.get('/me', [AuthController, 'me']);
    router.post('/email/verify', [AuthController, 'verifyEmail']);
    router.post('/email/resend', [AuthController, 'resendVerification']);
    router.post('/otp/setup', [AuthController, 'setupOtp']);
    router.post('/otp/verify', [AuthController, 'verifyOtp']);
    router.post('/keys/provision', [AuthController, 'provisionKey']);
  })
  .prefix('/api/auth')
  .use(middleware.auth({ guards: ['jwt'] }));
