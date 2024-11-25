//
//  Created by raz on 2024/3/31.
//

import SwiftUI
import Settings
import Defaults
import KeyboardShortcuts


struct SettingView: View
{
	@Default(.nowHost) private var selected
	
	var body: some View 
	{
		
		Form
		{
			VStack
			{
				LabeledContent("Toggle App") { KeyboardShortcuts.Recorder(for: .toggleApp).frame( width:200 ) }
					.frame(width: 300)
					.padding(5)
					.overlay(
						RoundedRectangle(cornerRadius: 10)
							.stroke(Color.gray, lineWidth: 2)
					)
				
				
				LabeledContent("Reload Web") { KeyboardShortcuts.Recorder(for: .reloadWeb).frame( width:200 ) }
					.frame(width: 300)
					.padding(5)
					.overlay(
						RoundedRectangle(cornerRadius: 10)
							.stroke(Color.gray, lineWidth: 2)
					)
				
				LabeledContent("Target") {
					Menu {
						ForEach(Defaults[.aiServices], id: \.host) { svc in
							Button {
								selected = svc.host
								MBC.shared.clicked_Reload()
							} label: {
								Text(svc.name)
								Image(systemName: svc.ico)
							}
						}
					} label: {
						Text(selected.isEmpty ? "select.." : selected)
						Image(systemName: "tag.circle")
					}
					.frame(width: 240)
				}
				.frame(width: 300)
				.padding(5)
				.overlay(
					RoundedRectangle(cornerRadius: 10)
						.stroke(Color.gray, lineWidth: 2)
				)
			}
			
		}
		.padding(20)
		.frame(width: 380, height: 140)
		
	}
}


let BaseSettingsViewController: () -> SettingsPane = {
	/**
	Wrap your custom view into `Settings.Pane`, while providing necessary toolbar info.
	*/
	let paneView = Settings.Pane(
		identifier: .general,
		title: "general",
		toolbarIcon: NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Accounts settings")!
	) {
		SettingView()
	}

	return Settings.PaneHostingController(pane: paneView)
}


#Preview {
	SettingView()
}
