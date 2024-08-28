import Foundation

class Debouncer {
	private var workItem: DispatchWorkItem?
	private let queue: DispatchQueue
	private let delay: TimeInterval

	init(delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
		self.delay = delay
		self.queue = queue
	}

	func debounce(_ block: @escaping () -> Void) {
		workItem?.cancel()
		
		let newWorkItem = DispatchWorkItem(block: block)
		workItem = newWorkItem
		
		queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
	}
}
