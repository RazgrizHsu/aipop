import Foundation

import UserNotifications

struct Notifier {
	static func requestAuthorization(completion: @escaping (Bool) -> Void) {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
			DispatchQueue.main.async {
				completion(granted)
			}
		}
	}
	
	static func Show(title: String, body: String, timeInterval: TimeInterval = 0) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = UNNotificationSound.default
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print("Error Notify: \(error)")
			}
		}
	}
}
