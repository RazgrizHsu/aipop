import SwiftUI
import Cocoa
import KeyboardShortcuts

//import Sauce

func shortcutToText(_ shortcut: KeyboardShortcuts.Shortcut) -> String {
    var description = ""
    let modifierFlags = shortcut.modifiers
    if modifierFlags.contains(.command) {
        description += "⌘ "
    }
    
    if modifierFlags.contains(.shift) {
        description += "⇧ "
    }
    
    if modifierFlags.contains(.option) {
        description += "⌥ "
    }
    
    if modifierFlags.contains(.control) {
        description += "⌃ "
    }
    
    if modifierFlags.contains(.capsLock) {
        description += "⇪ "
    }
    
    if modifierFlags.contains(.numericPad) {
        description += "⇒ "
    }
//    if let char = Sauce.shared.character(for: shortcut.carbonKeyCode, carbonModifiers: shortcut.carbonModifiers) {
//        description += char.uppercased()
//    }
    return description
}
