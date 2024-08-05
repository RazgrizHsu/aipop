
import SwiftUI
import Cocoa

import KeyboardShortcuts


extension KeyboardShortcuts.Name
{
	static let toggleApp = Self( "toggleApp" , default: .init( .three, modifiers: [ .command, .shift ] ) )
	static let reloadWeb = Self( "reloadWeb" , default: .init( .r, modifiers: [ .command, .shift ] ) )
	
	public static func resetAll()
	{
		KeyboardShortcuts.reset([ .toggleApp, .reloadWeb ])
	}
}

extension NSWindow
{
	public func checkShortcutMatch( _ name: KeyboardShortcuts.Name, _ event: NSEvent) -> Bool
	{
		guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else { return false }
		guard let key = shortcut.key?.rawValue else { return false }
		
		let eventModifierFlags = event.modifierFlags.intersection([.shift, .control, .option, .command])
		return event.keyCode == key && shortcut.modifiers.contains( eventModifierFlags )
	}
}




@main
struct iApp: App
{
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	//@StateObject private var appState = AppState()
	
	static let initSize = NSSize(width: 980, height: 860)
	
	var body: some Scene
	{
		Settings { SettingView() }
	}
}


//@MainActor
//final class AppState: ObservableObject
//{
//	init()
//	{
//	}
//	
//	deinit
//	{
//		log( "release!" )
//	}
//}

