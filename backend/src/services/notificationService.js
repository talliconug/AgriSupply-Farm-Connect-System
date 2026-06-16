const axios = require('axios');
const { supabase } = require('../config/supabase');
const logger = require('../utils/logger');
const { sendSms } = require('./smsProviderService');

function getFirebaseAdmin() {
  try {
    const admin = require('firebase-admin');
    return admin;
  } catch (error) {
    return null;
  }
}

class NotificationService {
  /**
   * Send push notification via Firebase Cloud Messaging
   * @param {string} deviceToken - FCM device token
   * @param {Object} notification - Notification data
   * @returns {Promise<boolean>}
   */
  async sendPushNotification(deviceToken, notification) {
    try {
      const admin = getFirebaseAdmin();
      if (admin?.messaging) {
        const message = {
          token: deviceToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            type: notification.type || 'general',
            referenceId: notification.referenceId || '',
            ...notification.data,
          },
        };

        await admin.messaging().send(message);
        return true;
      }

      const fcmApiKey = process.env.FIREBASE_SERVER_KEY;
      if (!fcmApiKey) {
        logger.warn('Firebase server key not configured');
        return false;
      }

      const response = await axios.post(
        'https://fcm.googleapis.com/fcm/send',
        {
          to: deviceToken,
          notification: {
            title: notification.title,
            body: notification.body,
            sound: 'default',
          },
          data: {
            type: notification.type || 'general',
            referenceId: notification.referenceId || '',
            ...notification.data,
          },
          priority: 'high',
        },
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${fcmApiKey}`,
          },
        }
      );

      if (response.status === 200) {
        return true;
      }

      logger.error('FCM API error:', response.data);
      return false;
    } catch (error) {
      logger.error('Send push notification error:', error.message || error);
      return false;
    }
  }

  /**
   * Send email notification
   * @param {string} email - Recipient email
   * @param {Object} emailData - Email content
   * @returns {Promise<boolean>}
   */
  async sendEmailNotification(email, emailData) {
    try {
      const emailService = process.env.EMAIL_SERVICE;

      if (emailService === 'sendgrid') {
        const sgMail = require('@sendgrid/mail');
        sgMail.setApiKey(process.env.SENDGRID_API_KEY);

        const msg = {
          to: email,
          from: process.env.FROM_EMAIL || 'noreply@agrisupply.com',
          subject: emailData.subject,
          text: emailData.text,
          html: emailData.html,
        };

        await sgMail.send(msg);
        return true;
      }

      if (emailService === 'mailgun') {
        const mailgun = require('mailgun-js')({
          apiKey: process.env.MAILGUN_API_KEY,
          domain: process.env.MAILGUN_DOMAIN,
        });

        const data = {
          from: process.env.FROM_EMAIL || 'AgriSupply <noreply@agrisupply.com>',
          to: email,
          subject: emailData.subject,
          text: emailData.text,
          html: emailData.html,
        };

        await mailgun.messages().send(data);
        return true;
      }

      logger.warn('No email service configured');
      return false;
    } catch (error) {
      logger.error('Send email notification error:', error.message || error);
      return false;
    }
  }

  /**
   * Send SMS notification
   * @param {string} phone - Phone number in E.164 format
   * @param {string} message - SMS message
   * @returns {Promise<boolean>}
   */
  async sendSMSNotification(phone, message) {
    try {
      const result = await sendSms({ phone, message });
      return Boolean(result?.ok);
    } catch (error) {
      logger.error('Send SMS notification error:', error.message || error);
      return false;
    }
  }

  /**
   * Send notification to user based on their preferences
   * @param {string} userId - User ID
   * @param {Object} notification - Notification content
   * @returns {Promise<void>}
   */
  async sendNotificationToUser(userId, notification) {
    try {
      const { data: preferences } = await supabase
        .from('notification_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: user } = await supabase
        .from('users')
        .select('email, phone')
        .eq('id', userId)
        .single();

      if (preferences?.push_enabled) {
        const { data: devices } = await supabase
          .from('user_devices')
          .select('device_token')
          .eq('user_id', userId);

        for (const device of devices || []) {
          await this.sendPushNotification(device.device_token, notification);
        }
      }

      if (preferences?.email_enabled && user?.email) {
        await this.sendEmailNotification(user.email, {
          subject: notification.title,
          text: notification.body,
          html: `<h2>${notification.title}</h2><p>${notification.body}</p>`,
        });
      }

      if (preferences?.sms_enabled && user?.phone) {
        await this.sendSMSNotification(
          user.phone,
          `${notification.title}: ${notification.body}`
        );
      }
    } catch (error) {
      logger.error('Send notification to user error:', error.message || error);
    }
  }
}

module.exports = new NotificationService();
