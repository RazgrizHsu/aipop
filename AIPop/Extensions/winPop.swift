
import Cocoa
import WebKit
import Defaults
import UniformTypeIdentifiers

extension winPop : WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate
{
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
	{
		if let url = navigationAction.request.url
		{
			// Check for special URL schemes
			if url.scheme == "about" || url.absoluteString == "about:blank"
			{
				log("[WebView] Special URL scheme detected: \(url.absoluteString)")
				decisionHandler(.allow)
				return
			}

			// Blob URLs - use download delegate
			if url.scheme == "blob"
			{
				log("[WebView] Blob URL detected, triggering download: \(url.absoluteString)")
				decisionHandler(.download)
				return
			}

			if navigationAction.navigationType == .linkActivated
			{
				log("[WebView] Link clicked: \(url.absoluteString)")

				if url.host != Defaults[.nowHost] && url.host != nil
				{
					log("[WebView] Opening in external browser: \(url.absoluteString)")
					NSWorkspace.shared.open(url)
					decisionHandler(.cancel)
					return
				}
			}
			// Handle other types of navigation, including links opened by JavaScript
			else if url.host != Defaults[.nowHost] && url.host != nil && url.scheme != "about"
			{
				log("[WebView] JS navigation detected to external URL: \(url)")

				// NSWorkspace.shared.open(url)
				// decisionHandler(.cancel)

				// ex: claude will open www.claudeusercontent.com
				decisionHandler(.allow)
				return
			}

			log("[WebView] Navigating internally to: \(url)")
			decisionHandler(.allow)
		}
		else
		{
			log("[WebView] Navigation with no URL")
			decisionHandler(.allow)
		}
	}

	// Handle window.open() calls and target="_blank" links
	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView?
	{
		if let url = navigationAction.request.url
		{
			if navigationAction.targetFrame == nil {
				log("[WebView] target=\"_blank\" link detected for URL: \(url.absoluteString)")
			} else {
				log("[WebView] window.open() called for URL: \(url.absoluteString)")
			}

			// Check for special URL schemes
			if url.scheme == "about" || url.absoluteString == "about:blank"
			{
				log("[WebView] Special URL scheme in new window request: \(url.absoluteString)")
				// For about:blank, we can either create a new WebView and return it, or load in the current WebView
				// Here we choose to load in the current WebView
				return nil
			}

			if url.host != Defaults[.nowHost] && url.host != nil
			{
				log("[WebView] Opening external URL in system browser: \(url.absoluteString)")
				NSWorkspace.shared.open(url)
			}
			else
			{
				// If it's the same domain, load in the current webView
				webView.load(navigationAction.request)
			}
		}

		return nil
	}

	// Handle navigation responses
	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
	{
		if let url = navigationResponse.response.url
		{
			log("[WebView] Navigation response for URL: \(url.absoluteString)")
		}

		decisionHandler(.allow)
	}

	// Handle new windows opened by JavaScript
	func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void)
	{
		log("[WebView] JavaScript alert: \(message)")

		if let urlRange = message.range(of: "https?://[^\\s]+", options: .regularExpression)
		{
			let urlString = String(message[urlRange])
			if let url = URL(string: urlString)
			{
				log("[WebView] Detected URL in JavaScript alert: \(url.absoluteString)")

				if url.scheme == "about" || url.absoluteString == "about:blank"
				{
					log("[WebView] Special URL scheme in JavaScript alert: \(url.absoluteString)")
				}
				else if url.host != Defaults[.nowHost] && url.host != nil
				{
					NSWorkspace.shared.open(url)
				}
			}
		}

		completionHandler()
	}

	// Handle JavaScript confirmation dialogs
	func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void)
	{
		log("[WebView] JavaScript confirm: \(message)")
		completionHandler(true)
	}

	// Handle JavaScript prompt dialogs
	func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void)
	{
		log("[WebView] JavaScript prompt: \(prompt)")
		completionHandler(defaultText)
	}

	// WKDownloadDelegate methods
	func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload)
	{
		log("[WebView] Download started")
		download.delegate = self
	}

	func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload)
	{
		log("[WebView] Download started from response")
		download.delegate = self
	}

	func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void)
	{
		log("[WebView] Download suggested filename: \(suggestedFilename), mimeType: \(response.mimeType ?? "unknown")")

		var filename = suggestedFilename

		// Add extension if missing
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
		log("[WebView] Download finished")
	}

	func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?)
	{
		log("[WebView] Download failed: \(error.localizedDescription)")
	}
}
