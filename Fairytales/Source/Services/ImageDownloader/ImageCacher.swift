
import Foundation
import UIKit.UIImage

final class ImageCacher {
    
    struct Config {
        let countLimit: Int
        let memoryLimit: Int
        static let defaultConfig = Config(
            countLimit: 1000,
            memoryLimit: 1024 * 1024 * 1000)
    }
    
    private lazy var imageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.countLimit = config.countLimit
        return cache
    }()
    
    private lazy var decodedImageCache: NSCache<AnyObject, AnyObject> = {
        let cache = NSCache<AnyObject, AnyObject>()
        cache.totalCostLimit = config.memoryLimit
        return cache
    }()
    
    private let lock = NSLock()
    private let config: Config
    
    init(config: Config = Config.defaultConfig) {
        self.config = config
    }
    
    // MARK: - API
    
    func image(for url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        if let decodedImage = decodedImageCache.object(forKey: url as AnyObject) as? UIImage {
            return decodedImage
        }
        if let image = imageCache.object(forKey: url as AnyObject) as? UIImage {
            let decodedImage = image.decodedImage
            decodedImageCache.setObject(image as AnyObject, forKey: url as AnyObject, cost: decodedImage.diskSize)
            return decodedImage
        }
        return nil
    }
    
    func insertImage(_ image: UIImage?, for url: URL) {
        guard let image = image else { return removeImage(for: url) }
        let decodedImage = image.decodedImage
        lock.lock(); defer { lock.unlock() }
        imageCache.setObject(decodedImage, forKey: url as AnyObject)
        decodedImageCache.setObject(
            image as AnyObject,
            forKey: url as AnyObject,
            cost: decodedImage.diskSize
        )
    }
    
    func removeImage(for url: URL) {
        lock.lock(); defer { lock.unlock() }
        imageCache.removeObject(forKey: url as AnyObject)
        decodedImageCache.removeObject(forKey: url as AnyObject)
    }
    
    subscript(_ key: URL) -> UIImage? {
        get { return image(for: key) }
        set { return insertImage(newValue, for: key) }
    }
}

// MARK: Fileprivate UIImage + Extension

fileprivate extension UIImage {
    var diskSize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }

    var decodedImage: UIImage {
        guard let cgImage = cgImage else { return self }
        let size = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: cgImage.bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        context?.draw(
            cgImage,
            in: CGRect(origin: .zero, size: size)
        )
        guard let decodedImage = context?.makeImage() else { return self }
        return UIImage(cgImage: decodedImage)
    }
}
