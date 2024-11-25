
import Cocoa
import WebKit
import Defaults

extension winPop : WKNavigationDelegate
{
	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
	{
		if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated, url.host != Defaults[.nowHost]
		{
			NSWorkspace.shared.open(url)
			decisionHandler(.cancel)
		}
		else { decisionHandler(.allow) }
	}
}
