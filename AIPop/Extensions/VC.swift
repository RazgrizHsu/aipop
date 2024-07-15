import Cocoa

public class VC
{
	public static func showAlert( _ title: String, _ message: String, _ completion: @escaping () -> Void)
	{
		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = message
		alert.alertStyle = .informational
		alert.addButton(withTitle: "OK")
		
		let response = alert.runModal()
		if response == .alertFirstButtonReturn { completion() }
	}
}
