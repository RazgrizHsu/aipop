import Cocoa
import SwiftUI

class Notifier
{
	private var win: NSWindow?
	private var fadeTimer: Timer?
	private var autoHideTask: Task<Void, Never>?

	static let shared = Notifier()

	private init() {}

	@MainActor
	func show( _ msg: String, duration: TimeInterval = 5.0, refWin: NSWindow? = nil )
	{
		autoHideTask?.cancel()
		fadeTimer?.invalidate()

		let vw = NotifierView( msg: msg )
		let ho = NSHostingController( rootView: vw )
		ho.view.setFrameSize( NSSize( width: 1, height: 1 ) )
		let sz = ho.sizeThatFits( in: NSSize( width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude ) )

		let padding = 3.0
		let winSize = NSSize( width: sz.width + padding, height: sz.height + padding )

		var rect: NSRect
		if let ref = refWin {
			let rfm = ref.frame
			let yOffset: CGFloat = -12

			let x = rfm.maxX - winSize.width
			let y = rfm.maxY + yOffset
			rect = NSRect( origin: NSPoint( x: x, y: y ), size: winSize )
		} else {
			guard let scr = NSScreen.main else { return }
			let x = scr.visibleFrame.maxX - winSize.width - 20
			let y = scr.visibleFrame.maxY - winSize.height - 20
			rect = NSRect( origin: NSPoint( x: x, y: y ), size: winSize )
		}

		if win == nil {
			win = NSWindow( contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false )
			win?.isOpaque = false
			win?.backgroundColor = .clear
			win?.level = .statusBar
			win?.ignoresMouseEvents = true
			win?.isReleasedWhenClosed = false
			win?.contentView = NSHostingView( rootView: vw )
			win?.alphaValue = 0
		} else {
			win?.setFrame( rect, display: false )
			if let cv = win?.contentView as? NSHostingView<NotifierView> {
				cv.rootView = NotifierView( msg: msg )
			}
		}

		if win?.isVisible == false || win?.alphaValue == 0 {
			win?.orderFront( nil )
			NSAnimationContext.runAnimationGroup { ctx in
				ctx.duration = 0.3
				win?.animator().alphaValue = 1
			}
		}

		if duration > 0 {
			autoHideTask = Task { @MainActor in
				try? await Task.sleep( nanoseconds: UInt64( duration * 1_000_000_000 ) )
				guard !Task.isCancelled else { return }
				hide()
			}
		}
	}

	@MainActor
	func hide()
	{
		autoHideTask?.cancel()
		fadeTimer?.invalidate()

		guard let w = win else { return }

		NSAnimationContext.runAnimationGroup(
			{ ctx in
				ctx.duration = 0.5
				w.animator().alphaValue = 0
			},
			completionHandler: {
				w.orderOut( nil )
			}
		)
	}
}

struct NotifierView: View
{
	let msg: String

	var body: some View {
		Text( msg )
			.font( .system( size: 11 ) )
			.foregroundColor( .white )
			.padding( EdgeInsets( top: 3, leading: 6, bottom: 3, trailing: 6 ) )
			.background(
				RoundedRectangle( cornerRadius: 6 )
					.fill( LinearGradient(
						gradient: Gradient( colors: [ .blue, .green ] ),
						startPoint: .bottom,
						endPoint: .topTrailing
					))
					.shadow( color: .white, radius: 2 )
			)
	}
}
