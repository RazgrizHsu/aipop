import Defaults
import Foundation

extension Defaults.Keys
{
	static let host = Key<String>( "host", default: "chatgpt.com" )
	
	static let popFrame = Key<NSRect>( "popFrame", default: fixNSRectBridge )
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

private let fixNSRectBridge = NSRect.zero
