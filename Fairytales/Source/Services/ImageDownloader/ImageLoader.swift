
import Combine
import UIKit.UIImage
import Kingfisher

protocol ImageLoaderType {
    func loadImage(withURL url: URL, cacheKey: String) -> AnyPublisher<UIImage, Never>
    func fetchFromCache(_ cacheKey: String) -> AnyPublisher<UIImage?, Never>
}

class CacherError: Error {
    var msg: String?
    init(msg: String?) {
        self.msg = msg
    }
}

final class ImageLoader: ImageLoaderType {
    //private let cache: ImageCacher
    let cache = ImageCache.default
    init() {
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024
        cache.diskStorage.config.expiration = .never
    }
    // MARK: - API
    func loadImage(withURL url: URL, cacheKey: String) -> AnyPublisher<UIImage, Never> {
        let checkIfCached = fetchFromCache(cacheKey).eraseToAnyPublisher()
        let downloadImage = URLSession.shared
            .dataTaskPublisher(for: url)
            .compactMap { data, response in UIImage(data: data) }
            .catch({ error -> AnyPublisher<UIImage, Never> in
                Logger.logError(error)
                return Just(Constants.storyThumbnailPlaceholder).eraseToAnyPublisher()
            }).handleEvents(receiveOutput: { [weak self] image in
                if image === Constants.storyThumbnailPlaceholder { return }
                self?.cache.store(image, forKey: cacheKey)
            })
                    return checkIfCached
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
                    .tryMap({ image -> UIImage in
                        guard let img = image else { throw CacherError(msg: "") }
                        return img
                    }).catch({ error -> AnyPublisher<UIImage, Never> in
                        downloadImage.handleEvents(receiveOutput: { [weak self] image in
                            self?.cache.store(image, forKey: cacheKey)
                        }).eraseToAnyPublisher()
                    }).eraseToAnyPublisher()
    }
    
    func fetchFromCache(_ cacheKey: String) -> AnyPublisher<UIImage?, Never> {
        Deferred {
            Future<UIImage?, Never> { [weak self] promise in
                guard let isCached = self?.checkIfCached(cacheKey), isCached else { return promise(.success(nil)) }
                self?.cache.retrieveImage(forKey: cacheKey) { result in
                    switch result {
                    case .success(let value):
                        promise(.success(value.image))
                    case .failure(let error):
                        Logger.logError(error)
                        promise(.success(nil))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func checkIfCached(_ key: String) -> Bool { cache.isCached(forKey: key) }
}
