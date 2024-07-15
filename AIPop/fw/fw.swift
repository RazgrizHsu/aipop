import Foundation
import SwiftUI

class fw
{
	
	
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	class help
	{
		
	}
	
	
	//------------------------------------------------------------------------
	//------------------------------------------------------------------------
	class ui
	{
		static func makeMenuItemBy( _ title:String, _ act:Selector?, _ key:String = "" ) -> NSMenuItem
		{
			return makeMenuItemBy( title, act, key, nil )
		}
		static func makeMenuItemBy( _ title:String, _ act:Selector?, _ target:AnyObject? ) -> NSMenuItem
		{
			return makeMenuItemBy( title, act, "", target )
		}
		
		static func makeMenuItemBy( _ title:String, _ act:Selector?, _ key:String = "", _ target: AnyObject? ) -> NSMenuItem
		{
			let menu = NSMenuItem(title: title, action:act, keyEquivalent: key )
			
			if let target { menu.target = target }
			
			return menu
		}
	}
	
}
