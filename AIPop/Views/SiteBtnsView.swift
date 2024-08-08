import SwiftUI
import Settings
import Defaults
import KeyboardShortcuts


struct styleBtn: ButtonStyle {
	var av: Bool
	var padding: [CGFloat]
	let activeColors: [Color] = [.blue, .green]
	let inactiveColor: Color = .gray
	let startPoint: UnitPoint = .bottom
	let endPoint: UnitPoint = .topTrailing
	let cornerRadius: CGFloat = 3
	let shadowRadius: CGFloat = 2
	let shadowColor: Color = .white
	let inactiveOpacity: Double = 0.75
	
	static let defPad: [CGFloat] = [ 3, 6, 3, 6 ]

	init(av: Bool, padding: [CGFloat] = defPad) {
		self.av = av
		self.padding = padding.count == 4 ? padding : styleBtn.defPad
	}

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding(EdgeInsets(top: padding[0], leading: padding[1], bottom: padding[2], trailing: padding[3]))
			.background(
				RoundedRectangle(cornerRadius: cornerRadius)
					.fill(LinearGradient(gradient: Gradient(colors: backgroundColors()),
										 startPoint: startPoint,
										 endPoint: endPoint))
					.shadow(color: shadowColor, radius: shadowRadius)
			)
			.foregroundColor(.white)
			.opacity(av ? 1 : inactiveOpacity)
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
			.animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
	}

	private func backgroundColors() -> [Color] {
		if av {
			return activeColors
		} else {
			return [inactiveColor, inactiveColor]
		}
	}
}

struct SiteBtnsView: View {
	@Default(.host) private var toHost

	var body: some View {
		Form {
			VStack {
				HStack {
					Button(action: {
						toHost = "chatgpt.com"
						MBC.shared.clicked_Reload()
					})
					{ Text("ChatGPT").font(.system(size: 11)) }
					.buttonStyle(styleBtn(av: toHost == "chatgpt.com"))
					.disabled(toHost == "host1")

					Button(action: {
						toHost = "claude.ai"
						MBC.shared.clicked_Reload()
					})
					{ Text("Claude").font(.system(size: 11)) }
					.buttonStyle(styleBtn(av: toHost == "claude.ai"))
					.disabled(toHost == "claude.ai")

					Button(action: {
						toHost = "gemini.google.com"
						MBC.shared.clicked_Reload()
					})
					{ Text("Gemini").font(.system(size: 11)) }
					.buttonStyle(styleBtn(av: toHost == "gemini.google.com"))
					.disabled(toHost == "gemini.google.com")
				}
			}
		}
		.padding(10)
	}
}



struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		SiteBtnsView()
			.previewDisplayName("FloatBtnsView")
			.previewLayout(.sizeThatFits)
			.background(WindowAccessor())
	}
}

struct WindowAccessor: NSViewRepresentable {
	func makeNSView(context: Context) -> NSView {
		let view = NSView()
		DispatchQueue.main.async {
			if let window = view.window {
				window.titlebarAppearsTransparent = true
				window.titleVisibility = .hidden
				window.styleMask = [ .fullSizeContentView ]
				window.isOpaque = false
				window.backgroundColor = .clear
			}
		}
		return view
	}
	
	func updateNSView(_ nsView: NSView, context: Context) {}
}
