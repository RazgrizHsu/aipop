import Defaults
import Foundation


struct SvcAi: Codable, Defaults.Serializable, Equatable {
	let host: String
	let name: String
	let ico: String
}

extension Defaults.Keys {

	static let aiServices = Key<[SvcAi]>("aiServices", default: [
		SvcAi(host: "claude.ai/new", name: "Claude.Ai", ico: "arrow.up.and.down.circle"),
		SvcAi(host: "chatgpt.com", name: "ChatGPT.com", ico: "arrow.down.right.circle"),
		SvcAi(host: "gemini.google.com/app", name: "Gemini", ico: "arrow.up.and.down.circle"),

	])

	static let nowHost = Key<String>( "host", default: "claude.ai" )
	static let dicPopFrame = Key<[Int: NSRect]>( "dicPopFrame", default: [:] )

	//private let fixNSRectBridge = NSRect.zero
	//static let bak = Key<NSRect>( "bak", default: fixNSRectBridge )
}


extension NSRect: Defaults.Serializable
{
	public static let bridge = DefaultsNSRectBridge()
}

public final class DefaultsNSRectBridge: Defaults.Bridge
{
	public typealias Value = NSRect
	public typealias Serializable = [String: CGFloat]

	public func serialize(_ value: Value?) -> Serializable? {
		guard let value else { return ["x": 0, "y": 0, "w": 0, "h": 0 ] }

		return ["x": value.origin.x, "y": value.origin.y, "w":value.width, "h":value.height ]
	}

	public func deserialize(_ object: Serializable?) -> Value? {
		guard
			let object,
			let x = object["x"],
			let y = object["y"],
			let w = object["w"],
			let h = object["h"]
		else { return NSRect.zero }

		return NSRect(x: x, y: y, width: w, height: h)
	}
}
