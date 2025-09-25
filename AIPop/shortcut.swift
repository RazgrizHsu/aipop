import Foundation
import Cocoa
import KeyboardShortcuts
import Defaults

class Shortcut {

	static func triggerSwitchSite(for event: NSEvent) -> Bool {
		let modFlags = event.modifierFlags.intersection([.command, .shift, .control, .option])

		guard modFlags == .control else { return false }

		let siteIndex: Int?
		switch event.keyCode {
		case 18: siteIndex = 0
		case 19: siteIndex = 1
		case 20: siteIndex = 2
		default: siteIndex = nil
		}

		guard let idx = siteIndex else { return false }

		if let toggleShortcut = KeyboardShortcuts.getShortcut(for: .toggleApp),
		   toggleShortcut.modifiers == .control,
		   let toggleKeyCode = toggleShortcut.key?.rawValue,
		   toggleKeyCode == event.keyCode {

			Task { @MainActor in
				MBC.shared.switchToSite(index: idx)
			}
			return true
		}

		Task { @MainActor in
			MBC.shared.switchToSite(index: idx)
		}
		return true
	}

	static func shouldPreventToggle(for event: NSEvent, isWebViewFocused: Bool) -> Bool {
		guard isWebViewFocused else { return false }

		guard let toggleShortcut = KeyboardShortcuts.getShortcut(for: .toggleApp),
			  toggleShortcut.modifiers == .control,
			  let toggleKeyCode = toggleShortcut.key?.rawValue else { return false }

		return toggleKeyCode >= 18 && toggleKeyCode <= 20
	}
}
