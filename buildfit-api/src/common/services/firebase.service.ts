import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private app: admin.app.App;

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const serviceAccount = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT');

    if (serviceAccount) {
      const parsed = JSON.parse(serviceAccount);
      this.app = admin.initializeApp({
        credential: admin.credential.cert(parsed),
      });
    } else {
      this.app = admin.initializeApp({
        projectId: this.config.get('FIREBASE_PROJECT_ID', 'appcalculotreino-51f23'),
      });
    }
  }

  get auth(): admin.auth.Auth {
    return this.app.auth();
  }

  get firestore(): admin.firestore.Firestore {
    return this.app.firestore();
  }

  get messaging(): admin.messaging.Messaging {
    return this.app.messaging();
  }

  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    return this.auth.verifyIdToken(token);
  }

  async sendPushNotification(token: string, title: string, body: string, data?: Record<string, string>) {
    return this.messaging.send({
      token,
      notification: { title, body },
      data,
      android: {
        notification: {
          channelId: 'general',
          priority: 'high',
        },
      },
    });
  }
}
