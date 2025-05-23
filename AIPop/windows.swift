import Foundation
import Cocoa
import WebKit

import SwiftUI
import Settings
import Defaults
import KeyboardShortcuts


class DragImgView: NSImageView
{
	var wpop: winPop?
	
	private var cursor: NSCursor = .openHand
	
	private var area: NSTrackingArea?
	
	override func viewWillMove(toWindow newWindow: NSWindow?)
	{
		super.viewWillMove(toWindow: newWindow)
		
		if let existArea = area { removeTrackingArea(existArea) }
		area = NSTrackingArea(
			rect: .zero,
			options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
			owner: self,
			userInfo: nil
		)
		addTrackingArea(area!)
		
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
	//override func mouseDown(with event: NSEvent) { isDrag = true }
	//override func mouseUp(with event: NSEvent) { isDrag = false }
	
	override func mouseDragged(with event: NSEvent)
	{
		//if !isDrag { return }
		
		let deltaX = event.deltaX
		let deltaY = event.deltaY
		
		if let mwin = self.window, let pop = wpop
		{
			let mf = mwin.frame
			let nX = mf.origin.x + deltaX
			let nY = mf.origin.y - deltaY
			
			let scr = NSScreen.main!.visibleFrame
			if nX >= scr.minX,      nX + mf.width <= scr.maxX,
			   nY >= scr.minY + 10, nY + mf.height <= scr.maxY
			{
				pop.changePosition( NSPoint(x:deltaX,y:deltaY) )
			}
		}
	}
}

class baseWin : NSWindow {
	
	public var offset: NSPoint = NSPoint.zero
	
	override var canBecomeKey: Bool { return false }

//	override func becomeKey() {
//		super.becomeKey()
//		if let win = NSApp.windows.first(where: { $0.level == .normal }) { win.makeKeyAndOrderFront(nil) }
//	}
}



class winBtns: baseWin {

	init() {

		let padding = 3.0;
		let vwBtn = SiteBtnsView()

		let vwHost = NSHostingView(rootView: vwBtn)

		let hoCtr = NSHostingController(rootView: vwBtn)

		hoCtr.view.setFrameSize(NSSize(width: 1, height: 1))
		let size = hoCtr.sizeThatFits(in: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))


		let sizeWin = NSSize(width: size.width + padding, height: size.height + padding)
		let rect = NSRect(origin: .zero, size: sizeWin)

		super.init(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
		self.isOpaque = false
		self.backgroundColor = .clear

		self.ignoresMouseEvents = false
		self.level = .floating + 1

		let vwCon = NSView(frame: rect)
		vwCon.wantsLayer = true
		vwCon.layer?.backgroundColor = .clear

		vwHost.translatesAutoresizingMaskIntoConstraints = false
		vwCon.addSubview(vwHost)

		self.contentView = vwCon

		NSLayoutConstraint.activate([
			vwHost.centerXAnchor.constraint(equalTo: vwCon.centerXAnchor),
			vwHost.centerYAnchor.constraint(equalTo: vwCon.centerYAnchor),
			vwHost.widthAnchor.constraint(equalTo: vwCon.widthAnchor, constant: -padding),
			vwHost.heightAnchor.constraint(equalTo: vwCon.heightAnchor, constant: -padding)
		])
	}
}



class winImage: baseWin
{
	convenience init(_ imgKey: String, _ wpop: winPop? = nil )
	{
		let img = NSImage(systemSymbolName: imgKey, accessibilityDescription: nil)!
		var rect = NSRect(x: 0, y: 0, width: img.size.width, height: img.size.height)

		if wpop == nil
		{
			let imageView = NSImageView(frame: rect)
			imageView.image = img

			self.init(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
			self.isOpaque = false
			self.backgroundColor = NSColor.clear

			self.contentView = imageView
		}
		else
		{
			rect.size.width += 10;
			rect.size.height += 10;

			self.init(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
			self.isOpaque = false
			self.backgroundColor = NSColor.clear

			let imageView = DragImgView(frame: rect)
			imageView.image = img
			imageView.translatesAutoresizingMaskIntoConstraints = false
			imageView.wpop = wpop

			let vwBg = NSView(frame: rect)
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

				vwBg.widthAnchor.constraint(equalToConstant: rect.width),
				vwBg.heightAnchor.constraint(equalToConstant: rect.height)
			])
		}
	}
}




class winPop: NSWindow, NSWindowDelegate
{
	var webView: WKWebView!
	var startLocation: NSPoint = NSPoint()

	var wins: [baseWin] = []

	convenience init()
	{
		self.init(contentRect: .zero, styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
		self.setupWindowProperties()
		self.setupVisualEffectView()
		self.initializeWebView()
	}

	private func setupWindowProperties()
	{
		self.titleVisibility = .hidden
		self.titlebarAppearsTransparent = true
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

		// Allow JavaScript to open new windows
		wvc.preferences.javaScriptCanOpenWindowsAutomatically = true

		webView = WKWebView(frame: .zero, configuration: wvc)
		webView.translatesAutoresizingMaskIntoConstraints = false
		webView.navigationDelegate = self
		webView.uiDelegate = self  // Set UIDelegate to handle window.open() calls
		self.contentView?.subviews.first?.addSubview(webView)

		NSLayoutConstraint.activate([
			webView.topAnchor.constraint(equalTo: self.contentView!.topAnchor),
			webView.bottomAnchor.constraint(equalTo: self.contentView!.bottomAnchor),
			webView.leadingAnchor.constraint(equalTo: self.contentView!.leadingAnchor),
			webView.trailingAnchor.constraint(equalTo: self.contentView!.trailingAnchor)
		])

		webView.load(URLRequest(url: URL(string: "https://\( Defaults[.nowHost] )")!))
	}

	func windowDidBecomeKey(_ notification: Notification)
	{
		//log( "[wpop] front!" )
		for win in wins { win.orderFront(nil) }
	}

	func windowDidResignKey(_ notification: Notification)
	{
		//log( "[wpop] out..." )
		for win in wins { win.orderOut(nil) }
	}

	func changePosition( _ delta: NSPoint )
	{
		var po = self.frame.origin

		po.x += delta.x
		po.y -= delta.y

		self.setFrameOrigin( po )
	}

	func resetRefPos()
	{
		let fr = self.frame

		var dic = Defaults[.dicPopFrame]
		dic[MBC.monId] = fr
		Defaults[.dicPopFrame] = dic

		for win in wins {
			win.setFrameOrigin( NSPoint( x: fr.minX + win.offset.x, y: fr.maxY + win.offset.y ) )
		}
	}

	override func setFrameOrigin(_ point: NSPoint)
	{
		super.setFrameOrigin( point )

		log( "[wpop:setFrameOrigin] \(point) monx[\(MBC.monId)]" )
		resetRefPos()
		saveNowPos()
	}
	override func setContentSize(_ size: NSSize) {
		super.setContentSize(size)
		log( "[wpop:setContentSize] \(size)" )
		saveNowPos()
	}


	private var lastMonId: Int = 0
	var isMonChange : Bool { get { return lastMonId != MBC.monId } }

	let debSavePos = Debouncer( delay: 0.3 )
	func saveNowPos()
	{
		debSavePos.debounce {

			let monX = MBC.monId
			var dic = Defaults[.dicPopFrame]

			log( "[wpop] save: monX[\(monX)] new: \( self.frame )" )
			dic[monX] = self.frame
			Defaults[.dicPopFrame] = dic
		}
	}


	func resetPositions( _ isReset: Bool = false )
	{
		guard let btn = MBC.shared.statusItem?.button else { return }
		guard let btnFm = btn.window?.convertToScreen( btn.frame ) else { return }


		//let isFirst = winPop.last == NSRect.zero

		let po = self.frame


		var dic = Defaults[.dicPopFrame]
		if isReset {
			dic = [:]
			Defaults[.dicPopFrame] = dic
		}

		let isMonCh = lastMonId != MBC.monId

		lastMonId = MBC.monId

		let monX = btnFm.origin.x + (btnFm.width / 2)
		let npt = NSPoint(x: monX - ( po.width / 2), y: ( btnFm.origin.y - po.height ) - 25 )

		log( "[wpop] monId[\(lastMonId)] isReset[ \(isReset) ] isMonCh[ \(isMonCh) ] npt: \(npt)" )

		if var ofm = dic[lastMonId] {

			if( ofm.origin.y > npt.y ) { ofm.origin.y = npt.y }

			log( "[wpop] pos: exist ofm: \( ofm )" )
			if( ofm.size.width > 100 && ofm.size.height > 100 ) {
				self.setContentSize( ofm.size )
				self.setFrameOrigin( ofm.origin )
			}
			else {
				log( "[wpop] set new by iApp[\(iApp.initSize)]" )
				self.setContentSize( iApp.initSize )
				self.setFrameOrigin( ofm.origin )

				dic[lastMonId] = self.frame
				Defaults[.dicPopFrame] = dic
			}
		}
		else {

			log( "[wpop] pos: new npt: \( npt )" )
			self.setFrameOrigin( npt )
			self.setContentSize( iApp.initSize )

			dic[MBC.monId] = self.frame
			Defaults[.dicPopFrame] = dic
		}

		MBC.shared.warr?.setFrameOrigin( NSPoint(x: btnFm.midX-((MBC.shared.warr?.frame.size.width)!/2), y: btnFm.minY) )
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




	func windowWillResize(_ sender: NSWindow, to news: NSSize) -> NSSize
	{
		log( "[wpop:reisze] \(news)" )

		self.resetRefPos()
		self.saveNowPos()

		//let fm = sender.frame
		//if fm.maxY < winPop.last.maxY {}
		return news
	}
}
