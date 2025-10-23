
import Cocoa
import WebKit
import Defaults
import UniformTypeIdentifiers

fileprivate let dbg = false

extension winPop : WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate
{
	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!)
	{
		if dbg { log("[WebView] Start loading: \(webView.url?.absoluteString ?? "")") }

		if let host = webView.url?.host {
			Task { @MainActor in
				let svcs = Defaults[.aiServices]
				let nm = svcs.first(where: { $0.host == host })?.name ?? host
				if let wp = self as? winPop {
					Notifier.shared.show( "Loading \(nm)...", duration: 0, refWin: wp )
				}
			}
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
	{
		if dbg { log("[WebView] Loaded: \(webView.url?.absoluteString ?? "")") }

		if let wp = self as? winPop {
			wp.hideLoadingView()

			if let host = webView.url?.host {
				Task { @MainActor in
					let svcs = Defaults[.aiServices]
					let nm = svcs.first(where: { $0.host == host })?.name ?? host
					Notifier.shared.show( "\(nm) loaded", refWin: wp )
				}
			}
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
	{
		if dbg { log("[WebView] Failed: \(error.localizedDescription)") }
		if let wp = self as? winPop {
			wp.hideLoadingView()
			Task { @MainActor in
				Notifier.shared.show( "Load failed: \(error.localizedDescription)", refWin: wp )
			}
		}
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error)
	{
		if dbg { log("[WebView] Failed provisional: \(error.localizedDescription)") }
		if let wp = self as? winPop {
			wp.hideLoadingView()
			Task { @MainActor in
				Notifier.shared.show( "Connection failed: \(error.localizedDescription)", refWin: wp )
			}
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
	{
		if let url = navigationAction.request.url
		{
			if url.scheme == "about" || url.absoluteString == "about:blank"
			{
				decisionHandler(.allow)
				return
			}

			if url.scheme == "blob"
			{
				if dbg { log("[WebView] Blob download: \(url.absoluteString)") }
				decisionHandler(.download)
				return
			}

			if navigationAction.navigationType == .linkActivated
			{
				if url.host != Defaults[.nowHost] && url.host != nil
				{
					if dbg { log("[WebView] External link: \(url.absoluteString)") }
					NSWorkspace.shared.open(url)
					decisionHandler(.cancel)
					return
				}
			}
			else if url.host != Defaults[.nowHost] && url.host != nil && url.scheme != "about"
			{
				decisionHandler(.allow)
				return
			}

			decisionHandler(.allow)
		}
		else
		{
			decisionHandler(.allow)
		}
	}

	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView?
	{
		if let url = navigationAction.request.url
		{
			if url.scheme == "about" || url.absoluteString == "about:blank"
			{
				return nil
			}

			if url.host != Defaults[.nowHost] && url.host != nil
			{
				if dbg { log("[WebView] External window: \(url.absoluteString)") }
				NSWorkspace.shared.open(url)
			}
			else
			{
				webView.load(navigationAction.request)
			}
		}

		return nil
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
	{
		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void)
	{
		if let urlRange = message.range(of: "https?://[^\\s]+", options: .regularExpression)
		{
			let urlString = String(message[urlRange])
			if let url = URL(string: urlString)
			{
				if url.scheme != "about" && url.absoluteString != "about:blank" && url.host != Defaults[.nowHost] && url.host != nil
				{
					NSWorkspace.shared.open(url)
				}
			}
		}

		completionHandler()
	}

	func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void)
	{
		completionHandler(true)
	}

	func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void)
	{
		completionHandler(defaultText)
	}

	func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload)
	{
		download.delegate = self
	}

	func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload)
	{
		download.delegate = self
	}

	func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void)
	{
		var filename = suggestedFilename

		if (filename as NSString).pathExtension.isEmpty {
			if let mimeType = response.mimeType {
				var ext = ""
				switch mimeType {
				case "text/plain": ext = "txt"
				case "text/html": ext = "html"
				case "application/pdf": ext = "pdf"
				case "application/zip": ext = "zip"
				case "image/png": ext = "png"
				case "image/jpeg", "image/jpg": ext = "jpg"
				case "application/json": ext = "json"
				default:
					if let uti = UTType(mimeType: mimeType) {
						ext = uti.preferredFilenameExtension ?? ""
					}
				}
				if !ext.isEmpty {
					filename = filename + "." + ext
				}
			}
		}

		let panel = NSSavePanel()
		panel.nameFieldStringValue = filename

		panel.begin { result in
			if result == .OK {
				completionHandler(panel.url)
			} else {
				completionHandler(nil)
			}
		}
	}

	func downloadDidFinish(_ download: WKDownload)
	{
		if dbg { log("[WebView] Download finished") }
	}

	func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?)
	{
		if dbg { log("[WebView] Download failed: \(error.localizedDescription)") }
	}
}
