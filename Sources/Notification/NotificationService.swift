//
//  NotificationService.swift
//
//
//  Created by Ifeanyi Onuoha on 12/09/2024.
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit


public class NotificationService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static public let shared = NotificationService()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    public func configureNotifications() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token: \(tokenString)")
        // Convert the device token to a string and set it in Firebase
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Called when a notification is received while the app is in the foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("USER INFO FOR FOREGROUND \(userInfo)")
        if let messageId = userInfo[Constants.messageId] as? String {
            print("Identifier: \(messageId)")
            NotificationHandler.shared.trackMessageDelivered(id: messageId)
        }
        completionHandler([.alert, .sound])
    }
    
    // Called when a notification is received while the app is in the background (content-available: 1)
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("USER INFO FOR BACKGROUND \(userInfo)")
        if let messageId = userInfo[Constants.messageId] as? String {
            print("Identifier: \(messageId)")
            NotificationHandler.shared.trackMessageDelivered(id: messageId)
        }
        completionHandler(.newData)
    }

    // Called when a notification is opened (foreground, background, or terminated)
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("USER INFO FOR CLICK ACTION \(userInfo)")
        if let messageId = userInfo[Constants.messageId] as? String {
            print("Identifier: \(messageId)")
            NotificationHandler.shared.trackMessageOpened(id: messageId)
        }
        completionHandler()
    }
    
    // Called when APNs registration fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    
}

extension NotificationService {
    func messaging(_ messaging: Any, didReceiveRegistrationToken fcmToken: String?) {
        guard let deviceToken = fcmToken else {
            return
        }
        print("New FCM token: \(deviceToken)")
        if UserDefaults.standard.value(forKey: "uid") is String {
            Engage.shared.setDeviceToken(deviceToken: deviceToken)
        }
    }
}
