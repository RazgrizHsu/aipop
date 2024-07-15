//import SwiftUI
import Cocoa
import WebKit

import Settings
import Defaults
import KeyboardShortcuts


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
		MenuBarController.shared = MenuBarController()
		
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
			MenuBarController.shared.togglePopover()
		}
	}
}

class MenuBarController
{
	static var shared:MenuBarController!
	
	var wpop: winPop?
	private var warr: winImage?
	private var wmov: winImage?
	
	private var statusItem: NSStatusItem?
	var menu = NSMenu()
	
	private var lastCX: Double = 0.0
	
	init()
	{
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		if let btn = statusItem?.button
		{
			btn.action = #selector(statusItemClicked(sender:))
			btn.sendAction(on: [.leftMouseUp, .rightMouseUp]) // 設置對左鍵和右鍵單擊的響應
			btn.target = self
			
			if let img = NSImage(contentsOfFile: Bundle.main.path(forResource: "icon", ofType: "png", inDirectory: "imgs")!) {
				img.size = NSSize(width: 20, height: 20)
				btn.image = img
			}
			else
			{
				print( "not found image!!" )
			}
		}
		
		menu.addItem( fw.ui.makeMenuItemBy( "Toggle", #selector(self.togglePopover), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Settings", #selector(clicked_Settings), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Reload", #selector(clicked_Reload), self ) )
		menu.addItem( fw.ui.makeMenuItemBy( "Clear Data", #selector(clicked_Clear), self ))
		menu.addItem( NSMenuItem.separator() )
		menu.addItem( fw.ui.makeMenuItemBy( "Quit", #selector(quitApp), "q", self ) )
	}
	
	
	@objc func statusItemClicked(sender: NSStatusBarButton)
	{
		let event = NSApp.currentEvent!
		if event.type == NSEvent.EventType.rightMouseUp
		{
			statusItem?.menu = menu // 臨時設置選單以顯示
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
	
	@MainActor @objc func clicked_Reload()
	{
		wpop?.reloadWebView()
	}
	
	@MainActor @objc func clicked_Clear()
	{
		let dataStore = WKWebsiteDataStore.default()
		let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
		let sinceDate = Date(timeIntervalSince1970: 0)
		dataStore.removeData(ofTypes: dataTypes, modifiedSince: sinceDate)
		{
			VC.showAlert( "clear", "all data has been cleared." )
			{
				print("All website data has been removed.")
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
				winPop.last = pop.frame
				pop.orderOut(nil)
				warr?.orderOut(nil)
				wmov?.orderOut(nil)
			}
			else
			{
				NSApp.activate(ignoringOtherApps: true)
				pop.makeKeyAndOrderFront(nil)
			}
		}
		else
		{
			if( wpop == nil )
			{
				wpop = winPop()
				warr = winImage( "arrow.up.circle.fill" )
				wmov = winImage( "arrow.up.and.down.and.arrow.left.and.right", wpop )
				wmov?.level = NSWindow.Level.popUpMenu
				wpop?.winMove = wmov
			}
			
			guard let pop = wpop else { return }
			guard let btn = statusItem?.button else { return }
			
			let isFirst = winPop.last == NSRect.zero
			if isFirst
			{
				wmov?.setContentSize( NSSize( width: 30, height: 30 ) )
				
				let rect = Defaults[.popFrame]
				if rect.size.width != 0 && rect.size.height != 0
				{
					pop.setContentSize( rect.size )
				}
				else
				{
					pop.setContentSize( iApp.initSize )
				}
			}
			
			
			if let btnFm = btn.window?.convertToScreen( btn.frame )
			{
				let po = pop.frame
				let btnCX = btnFm.origin.x + (btnFm.width / 2)
				if( lastCX == 0 ) { lastCX = btnCX }
				
				if( isFirst || lastCX != btnCX )
				{
					lastCX = btnCX
					
					let npos = NSPoint(x: btnCX - ( po.width / 2), y: ( btnFm.origin.y - po.height ) - 20 )
					pop.setFrameOrigin(npos)
					
					wmov?.setFrameOrigin( NSPoint( x: pop.frame.minX + 15, y: pop.frame.maxY - 12 ) )
				}
				
				let auSz = warr?.frame.size ?? NSSize(width: 20, height: 10)
				warr?.setContentSize(auSz)
				warr?.setFrameOrigin( NSPoint(x: btnFm.midX - auSz.width / 2, y: btnFm.minY - auSz.height) )
				
			}
			
			NSApp.activate(ignoringOtherApps: true)
			
			warr?.makeKeyAndOrderFront(nil)
			pop.makeKeyAndOrderFront(nil)
			wmov?.makeKeyAndOrderFront(nil)
		}
	}
}

class DragImgView: NSImageView
{
	var lastLocation: NSPoint?
	var cursor: NSCursor = .openHand
	var relatedWindow: NSWindow?

	override func viewWillMove(toWindow newWindow: NSWindow?)
	{
		super.viewWillMove(toWindow: newWindow)

		let trackingArea = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
		self.addTrackingArea(trackingArea)
		self.window?.invalidateCursorRects(for: self)
	}

	override func resetCursorRects() {
		super.resetCursorRects()
		self.addCursorRect(self.bounds, cursor: cursor)
	}

	override func mouseEntered(with event: NSEvent) {
		super.mouseEntered(with: event)
		cursor.push()
	}

	override func mouseExited(with event: NSEvent) {
		super.mouseExited(with: event)
		cursor.pop()
	}
	override func mouseDown(with event: NSEvent) { lastLocation = event.locationInWindow }
	override func mouseUp(with event: NSEvent) { lastLocation = nil }

	override func mouseDragged(with event: NSEvent)
	{
		guard let lastLocation = lastLocation else { return }
		let currentLocation = event.locationInWindow
		let deltaX = currentLocation.x - lastLocation.x
		let deltaY = currentLocation.y - lastLocation.y

		if let win = self.window, let winRef = relatedWindow 
		{
			var me = win.frame
			let newOriginX = me.origin.x + deltaX
			let newOriginY = me.origin.y + deltaY

			let screen = NSScreen.main!.visibleFrame
			if newOriginX >= screen.minX,
			   newOriginX + me.width <= screen.maxX,
			   newOriginY >= screen.minY + 10,
			   newOriginY + me.height <= screen.maxY 
			{
				me.origin.x = newOriginX
				me.origin.y = newOriginY
				win.setFrame(me, display: true)

				var relatedFrame = winRef.frame
				relatedFrame.origin.x += deltaX
				relatedFrame.origin.y += deltaY
				winRef.setFrame(relatedFrame, display: true)
			}
		}
	}
}



class winImage: NSWindow 
{
	convenience init(_ imgKey: String, _ relateWin: NSWindow? = nil )
	{
		let img = NSImage(systemSymbolName: imgKey, accessibilityDescription: nil)!
		var w = img.size.width
		var h = img.size.height
		
		if relateWin != nil
		{
			w += 6
			h += 6
		}
		
		let rectC = NSRect(x: 0, y: 0, width: w, height: h)
		self.init(contentRect: rectC, styleMask: .borderless, backing: .buffered, defer: false)
		self.isOpaque = false
		self.backgroundColor = NSColor.clear

		if relateWin == nil
		{
			let imageView = NSImageView(frame: rectC)
			imageView.image = img
			self.contentView = imageView
		}
		else
		{
			let rect = NSRect(origin: rectC.origin, size: NSSize(width: rectC.width + 10, height: rectC.height + 10))

			let imageView = DragImgView(frame: rect)
			imageView.image = img
			imageView.translatesAutoresizingMaskIntoConstraints = false
			imageView.relatedWindow = relateWin

			let vwBg = NSView(frame: rectC)
			vwBg.wantsLayer = true
			vwBg.layer?.backgroundColor = NSColor.black.cgColor
			vwBg.layer?.cornerRadius = 6
			vwBg.layer?.masksToBounds = true
			vwBg.translatesAutoresizingMaskIntoConstraints = false

			vwBg.addSubview(imageView)
			self.contentView = vwBg

			NSLayoutConstraint.activate([
				imageView.centerXAnchor.constraint(equalTo: vwBg.centerXAnchor),
				imageView.centerYAnchor.constraint(equalTo: vwBg.centerYAnchor),
				imageView.widthAnchor.constraint(equalToConstant: img.size.width),
				imageView.heightAnchor.constraint(equalToConstant: img.size.height),

				vwBg.widthAnchor.constraint(equalToConstant: rectC.width + 10),
				vwBg.heightAnchor.constraint(equalToConstant: rectC.height + 10)
			])
		}
	}

	override var canBecomeKey: Bool { return true }
}




class winPop: NSWindow, NSWindowDelegate
{	
	var webView: WKWebView!
	var startLocation: NSPoint = NSPoint()
	var winMove: winImage?
	
	static var last: NSRect = NSRect.zero
	
	convenience init()
	{
		self.init(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
		self.setupWindowProperties()
		self.setupVisualEffectView()
		self.initializeWebView()
		self.makeKeyAndOrderFront(nil)
	}
	
	private func setupWindowProperties()
	{
		self.center()
		self.titleVisibility = .hidden
		self.titlebarAppearsTransparent = true
		self.isMovableByWindowBackground = true
		self.backgroundColor = .clear
		self.standardWindowButton(.closeButton)?.isHidden = true
		self.standardWindowButton(.miniaturizeButton)?.isHidden = true
		self.standardWindowButton(.zoomButton)?.isHidden = true
		self.delegate = self
	}
	
	private func setupVisualEffectView()
	{
		let view = NSVisualEffectView()
		view.blendingMode = .behindWindow
		view.state = .active
		view.material = .sidebar
		view.translatesAutoresizingMaskIntoConstraints = false
		self.contentView?.addSubview(view)
		
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
			view.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor),
			view.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
			view.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor)
		])
	}
	
	private func initializeWebView()
	{
		let wvc = WKWebViewConfiguration()
		wvc.websiteDataStore = .default()
		
		webView = WKWebView(frame: .zero, configuration: wvc)
		webView.translatesAutoresizingMaskIntoConstraints = false
		webView.navigationDelegate = self
		self.contentView?.subviews.first?.addSubview(webView)
		
		NSLayoutConstraint.activate([
			webView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
			webView.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor),
			webView.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
			webView.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor)
		])
		
		webView.load(URLRequest(url: URL(string: "https://\( Defaults[.host] )")!))
	}
	
	func windowDidBecomeKey(_ notification: Notification)
	{
		winMove?.orderFront(nil)
	}

	func windowDidResignKey(_ notification: Notification)
	{
		winMove?.orderOut(nil)
	}
	
	override func setFrame(_ frame: NSRect, display flag: Bool)
	{
		super.setFrame(frame, display: flag)
		updateWinMovePosition()
		
		Defaults[.popFrame] = frame
		
//		if let btn = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength).button
//		{
//			if let btnFm = btn.window?.convertToScreen( btn.frame )
//			{
//			}
//		}
	}
	
	func windowWillResize(_ sender: NSWindow, to news: NSSize) -> NSSize
	{
		let fm = sender.frame
		if fm.maxY < winPop.last.maxY {}
		return news
	}
	
	private func updateWinMovePosition()
	{
		guard let winMove = winMove else { return }
		let po = self.frame
		winMove.setContentSize(NSSize(width: 30, height: 30))
		winMove.setFrameOrigin(NSPoint(x: po.minX + 15, y: po.maxY - 12))
	}

	func reloadWebView()
	{
		self.webView.removeFromSuperview()
		self.webView = nil
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) 
		{
			objc_setAssociatedObject(self, "webView", nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2)
		{
			self.initializeWebView()
		}
	}
	
	
	override func keyDown(with event: NSEvent) 
	{
		if self.checkShortcutMatch( .reloadWeb, event )
		{
			self.reloadWebView()
			return
		}

		super.keyDown(with: event)
	}
}
