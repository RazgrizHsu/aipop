import Cocoa
import WebKit

import Settings
import Defaults
import KeyboardShortcuts

func log( _ message: String )
{
#if DEBUG
	print( message )
#endif
}

@MainActor class AppDelegate: NSObject, NSApplicationDelegate
{
	//var state: AppState!
	
	static var panes: [SettingsPane] = [ BaseSettingsViewController() ]
	static var settingsWindowController = SettingsWindowController(
		panes: panes,
		style: .toolbarItems,
		animated: true,
		hidesToolbarForSingleItem: true
	)
	
	func applicationDidFinishLaunching(_ notification: Notification)
	{
		MBC.shared = MBC()
		
		if KeyboardShortcuts.getShortcut(for: .toggleApp) == nil
		{
			KeyboardShortcuts.Name.resetAll()
		}
		else
		{
			_ = KeyboardShortcuts.getShortcut(for: .toggleApp)
		}
		
		KeyboardShortcuts.onKeyDown( for: .toggleApp )
		{
			MBC.shared.togglePopover()
		}
	}
}



class MBC
{
	static var shared:MBC!
	
	var wpop: winPop?
	var warr: winImage?
	private var wmov: winImage?
	private var wbtn: winBtns?
	
	var statusItem: NSStatusItem?
	var menu = NSMenu()
	
	var monX : Double
	{
		get
		{
			guard let btn = MBC.shared.statusItem?.button else { return 0.0 }
			guard let btnFm = btn.window?.convertToScreen( btn.frame ) else { return 0.0 }
			return btnFm.origin.x + (btnFm.width / 2)
		}
	}

	
	init()
	{
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		if let btn = statusItem?.button
		{
			btn.action = #selector(statusItemClicked(sender:))
			btn.sendAction(on: [.leftMouseUp, .rightMouseUp]) // 設置對左鍵和右鍵單擊的響應
			btn.target = self
			
			if let img = NSImage( named: NSImage.Name( "AppIcon" ) )
			{
				img.size = NSSize(width: 20, height: 20)
				btn.image = img
			}
		}
		
		menu.addItem( fw.ui.makeMenuItemBy( "Toggle", #selector(self.togglePopover), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Settings", #selector(clicked_Settings), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Reload", #selector(clicked_Reload), self ) )
		menu.addItem( NSMenuItem.separator() )
		menu.addItem( fw.ui.makeMenuItemBy( "Reset Position", #selector(clicked_ResetPosition), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Clear Data", #selector(clicked_Clear), self ))
		menu.addItem( NSMenuItem.separator() )
		menu.addItem( fw.ui.makeMenuItemBy( "Quit", #selector(quitApp), "q", self ) )
		
		//NotificationCenter.default.addObserver(self, selector: #selector(windowBecameKey), name: NSWindow.didBecomeKeyNotification, object: nil)
	}
	

//	@objc func windowBecameKey(notification: Notification) {
//		guard let window = notification.object as? NSWindow else { return }
//		log("Key Window title[ \(window.title) ] frame[ \(window.frame) ]")
//	}
	
	
	@objc func statusItemClicked(sender: NSStatusBarButton)
	{
		let event = NSApp.currentEvent!
		if event.type == NSEvent.EventType.rightMouseUp
		{
			statusItem?.menu = menu
			statusItem?.button?.performClick(nil)
			statusItem?.menu = nil
		}
		else
		{
			togglePopover()
		}
	}
	
	@MainActor @objc func clicked_Settings()
	{
		if !AppDelegate.settingsWindowController.window!.isVisible
		{
			AppDelegate.settingsWindowController.show(pane: .general)
		}
		else
		{
			AppDelegate.settingsWindowController.close()
		}
	}
	
	@MainActor @objc func clicked_Reload() { wpop?.reloadWebView() }
	
	@MainActor @objc func clicked_ResetPosition() { wpop?.resetPositions(true) }
	
	@MainActor @objc func clicked_Clear()
	{
		let dataStore = WKWebsiteDataStore.default()
		let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
		let sinceDate = Date(timeIntervalSince1970: 0)
		dataStore.removeData(ofTypes: dataTypes, modifiedSince: sinceDate)
		{
			VC.showAlert( "clear", "all data has been cleared." )
			{
				log("All website data has been removed.")
				self.wpop?.reloadWebView()
			}
		}
	}
	
	@objc func quitApp()
	{
		NSApplication.shared.terminate(self)
	}
	
	@objc func togglePopover()
	{
		if let pop = wpop, pop.isVisible
		{
			if pop.isKeyWindow
			{
				pop.resetPositions()
				warr?.orderOut(nil)
				pop.orderOut(nil)
			}
			else
			{
				if( pop.isMonChange ) { pop.resetPositions() }
				
				NSApp.activate(ignoringOtherApps: true)
				warr?.orderFront(nil)
				pop.makeKeyAndOrderFront(nil)
			}
			pop.resetRefPos()
		}
		else
		{
			if( wpop == nil )
			{
				wpop = winPop()
				wpop!.title = "pop"
				warr = winImage( "arrow.up.circle.fill" )
				
				wmov = winImage( "arrow.up.and.down.and.arrow.left.and.right", wpop )
				wmov?.offset = NSPoint( x: 12, y: -3.8 )
				wmov?.level = .popUpMenu
				wmov?.parent = wpop
				wmov?.title = "mov"
				
				wbtn = winBtns( )
				wbtn?.offset = NSPoint( x: 39, y: -12 )
				wbtn?.level = .popUpMenu
				wbtn?.parent = wpop
				wbtn?.title = "btns"
				
				wpop?.wins.append( wbtn! )
				wpop?.wins.append( wmov! )
			}
			
			guard let pop = wpop else { return }
			
			pop.resetPositions()
			pop.resetRefPos()
			
			NSApp.activate(ignoringOtherApps: true)
			
			warr?.orderFront(nil)
			wmov?.makeKeyAndOrderFront(nil)
			wbtn?.makeKeyAndOrderFront(nil)
			
			pop.makeKeyAndOrderFront(nil)
		}
	}
}

