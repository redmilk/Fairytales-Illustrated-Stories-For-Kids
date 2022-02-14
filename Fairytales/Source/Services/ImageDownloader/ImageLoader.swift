
import Combine
import UIKit.UIImage

protocol ImageLoaderType {
    func loadImage(withURL url: URL) -> AnyPublisher<UIImage?, Never>
    func loadImage(withURLString urlString: String?) -> AnyPublisher<UIImage?, Never>
}

final class ImageLoader: ImageLoaderType {
    
    private let cache: ImageCacher
    
    init(cache: ImageCacher) {
        self.cache = cache
    }
    
    // MARK: - API
    
    func loadImage(withURL url: URL) -> AnyPublisher<UIImage?, Never> {
        if let image = cache[url] {
            return .just(output: image)
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response in UIImage(data: data) }
            .catch({ error -> AnyPublisher<UIImage?, Never> in
                Logger.logError(error)
                return Just(nil).eraseToAnyPublisher()
            })
            .handleEvents(receiveOutput: { [weak self] image in
                self?.cache[url] = image
            })
            .eraseToAnyPublisher()
    }
    
    func loadImage(withURLString urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
                  return .just(output: nil)
        }
        return loadImage(withURL: url)
    }
}
