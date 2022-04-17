//
//  FirestoreClient.swift
//  Fairytales
//
//  Created by Danyl Timofeyev on 10.02.2022.
//

import FirebaseAuthCombineSwift
import FirebaseStorageCombineSwift
import FirebaseFirestoreCombineSwift
import Firebase
import Combine
import Foundation

enum CategoryPath: String {
    case educational
    case healing
    case silent
}


final class FirebaseClient: ImageDownloaderProvidable {
    
    static let shared = FirebaseClient()
    
    lazy var db: Firestore = {
        let fs = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = 1000 * 1024 * 1024
        fs.settings = settings
        return fs
    }()
    
    let storage = Firebase.Storage.storage()
    let userSubject = CurrentValueSubject<User?, Never>(nil)
    let categoriesInternalType = CurrentValueSubject<Set<CategorySection>?, Never>(nil)
    let categoriesSubject = CurrentValueSubject<[CategoryDTO]?, Never>(nil)
    let educationalSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
    let healingSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
    let silentSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
    
    private init() {
        
    }
    private var bag = Set<AnyCancellable>()
    
    
    func signInAnonim() {
        var cancellable: AnyCancellable?
        cancellable = Auth.auth().signInAnonymously()
            .sink { completion in
                switch completion {
                case .finished: break
                case let .failure(error): Logger.logError(error)
                }
                cancellable?.cancel()
                cancellable = nil
            } receiveValue: { [weak self] authDataResult in
                self?.userSubject.send(authDataResult.user)
            }
    }
    
    // for copy existing story, or extracting fields, or updating storie's inner fields structure
    func copyFields() {
        let db = Firestore.firestore()
        var cancellable: AnyCancellable?
        cancellable = db.collection("categories").document("healing").collection("fairytales").getDocuments()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): Logger.logError(error)
                case .finished: break
                }
                cancellable?.cancel()
                cancellable = nil
            }, receiveValue: { snapshot in
                for document in snapshot.documents {
                    db.collection("categories").document("healing").collection("fairytales").document("copy-2").setData(document.data()) { error in
                        guard let error = error else { return }
                        Logger.logError(error)
                    }
                }
            })
    }
    
    func requestAllFairytalesAndMakeCategories(isForBoy: Bool) {
        requestFairytales(by: .educational)
        requestFairytales(by: .healing)
        requestFairytales(by: .silent)
        
        var educationalTotal: Int = 0
        var healingTotal: Int = 0
        var silentTotal: Int = 0
        
        let totalStoriesCountByCategories = Publishers.CombineLatest3(
            FirebaseClient.shared.educationalSubject.compactMap { $0 },
            FirebaseClient.shared.healingSubject.compactMap { $0 },
            FirebaseClient.shared.silentSubject.compactMap { $0 })
            .map { ($0.0, $0.1, $0.2) }
        
        Publishers.CombineLatest(Just(()).eraseToAnyPublisher(), totalStoriesCountByCategories)
            .map { $0.1 }.sink(receiveValue: { categoriesCount in
                educationalTotal = categoriesCount.0.count
                healingTotal = categoriesCount.1.count
                silentTotal = categoriesCount.2.count
                
                let educationalCategory = FirebaseClient.shared.educationalSubject
                    .compactMap { $0 }
                    .handleEvents(receiveOutput: { items in
                        educationalTotal = items.count
                        print(educationalTotal)
                    })
                    .flatMap ({ fairytales -> AnyPublisher<FairytaleDTO, Never> in
                        Publishers.Sequence(sequence: fairytales).eraseToAnyPublisher()
                    })
                    //.filter { !$0.storage_path.contains("great_happiness") }
                    .flatMap({ fairytaleDTO -> AnyPublisher<StoryModel, Never> in
                        Future<StoryModel, Never> ({ [weak self] promise in
                            guard let self = self else { return }
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? (isForBoy ? fairytaleDTO.cover.ipadBoy : fairytaleDTO.cover.ipadGirl) : (isForBoy ? fairytaleDTO.cover.iphoneBoy : fairytaleDTO.cover.iphoneGirl))
                            var c: AnyCancellable?
                            c = self.imageDownloader.fetchFromCache(path).sink(receiveCompletion: { completion in
                                c?.cancel()
                                c = nil
                            }, receiveValue: { image in
                                if let img = image {
                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                    fairytale.imageThumbnail = img
                                    promise(.success(fairytale))
                                } else {
                                    FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                        if let u = url { print(u) }
                                        if let error = error { Logger.logError(error) }
                                        let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                        fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                        guard let url = url else { return promise(.success(fairytale)) }
                                        var cancellable: AnyCancellable?
                                        cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                            .sink(receiveCompletion: { completion in
                                                switch completion {
                                                case .finished: break
                                                case .failure(let error):
                                                    Logger.logError(error)
                                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                    fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                                    promise(.success(fairytale))
                                                }
                                                cancellable?.cancel()
                                                cancellable = nil
                                            }, receiveValue: { image in
                                                let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                fairytale.imageThumbnail = image
                                                self.imageDownloader.cache.store(image, forKey: path)
                                                promise(.success(fairytale))
                                            })
                                    })
                                }
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(educationalTotal)
                    .eraseToAnyPublisher()
                    .map { fairytales -> CategorySection in
                        CategorySection(title: "Обучающая", description: "Учит дружить, делиться и работать в команде", color: ColorPalette.categoryDarkGreen,
                                        thumbnail: UIImage(named: "categorie-thumbnail-1")!, items: fairytales.sorted(), category: .educational)
                    }.receive(on: Scheduler.main, options: nil)
                
                let healingCategory = FirebaseClient.shared.healingSubject
                    .compactMap { $0 }
                    .handleEvents(receiveOutput: { items in
                        healingTotal = items.count
                        Logger.log("Updated count" + items.count.description, type: .token)
                    })
                    .flatMap ({ fairytales -> AnyPublisher<FairytaleDTO, Never> in
                        Publishers.Sequence(sequence: fairytales).eraseToAnyPublisher()
                    })
                    .flatMap({ fairytaleDTO -> AnyPublisher<StoryModel, Never> in
                        return Future<StoryModel, Never> ({ [weak self] promise in
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? (isForBoy ? fairytaleDTO.cover.ipadBoy : fairytaleDTO.cover.ipadGirl) : (isForBoy ? fairytaleDTO.cover.iphoneBoy : fairytaleDTO.cover.iphoneGirl))
                            guard let self = self else { return }
                            var c: AnyCancellable?
                            c = self.imageDownloader.fetchFromCache(path).sink(receiveCompletion: { completion in
                                c?.cancel()
                                c = nil
                            }, receiveValue: { image in
                                if let img = image {
                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                    fairytale.imageThumbnail = img
                                    promise(.success(fairytale))
                                } else {
                                    FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                        if let u = url { print(u) }
                                        if let error = error { Logger.logError(error) }
                                        let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                        fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                        guard let url = url else { return promise(.success(fairytale)) }
                                        var cancellable: AnyCancellable?
                                        cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                            .sink(receiveCompletion: { completion in
                                                switch completion {
                                                case .finished: break
                                                case .failure(let error):
                                                    Logger.logError(error)
                                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                    fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                                    promise(.success(fairytale))
                                                }
                                                cancellable?.cancel()
                                                cancellable = nil
                                            }, receiveValue: { image in
                                                let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                fairytale.imageThumbnail = image
                                                self.imageDownloader.cache.store(image, forKey: path)
                                                promise(.success(fairytale))
                                            })
                                    })
                                }
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(healingTotal)
                    .map ({ fairytales -> CategorySection in
                        CategorySection(title: "Терапевтическая", description: "Поможет справиться со страхами и стать увереннее", color: ColorPalette.categoryDarkRed,
                                        thumbnail: UIImage(named: "categorie-thumbnail-2")!, items: fairytales.compactMap { $0 }.sorted(), category: .healing)
                    })
                    .receive(on: Scheduler.main, options: nil)
                
                let silentCategory = FirebaseClient.shared.silentSubject
                    .compactMap { $0 }
                    .handleEvents(receiveOutput: { items in
                        silentTotal = items.count
                    })
                    .flatMap ({ fairytales -> AnyPublisher<FairytaleDTO, Never> in
                        Publishers.Sequence(sequence: fairytales).eraseToAnyPublisher()
                    })
                    .flatMap({ fairytaleDTO -> AnyPublisher<StoryModel, Never> in
                        Future<StoryModel, Never> ({ [weak self] promise in
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? (isForBoy ? fairytaleDTO.cover.ipadBoy : fairytaleDTO.cover.ipadGirl) : (isForBoy ? fairytaleDTO.cover.iphoneBoy : fairytaleDTO.cover.iphoneGirl))
                            guard let self = self else { return }
                            var c: AnyCancellable?
                            c = self.imageDownloader.fetchFromCache(path).sink(receiveCompletion: { completion in
                                c?.cancel()
                                c = nil
                            }, receiveValue: { image in
                                if let img = image {
                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                    fairytale.imageThumbnail = img
                                    promise(.success(fairytale))
                                } else {
                                    FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                        if let u = url { print(u) }
                                        if let error = error { Logger.logError(error) }
                                        let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                        fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                        guard let url = url else { return promise(.success(fairytale)) }
                                        var cancellable: AnyCancellable?
                                        cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                            .sink(receiveCompletion: { completion in
                                                switch completion {
                                                case .finished: break
                                                case .failure(let error):
                                                    Logger.logError(error)
                                                    let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                    fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                                    promise(.success(fairytale))
                                                }
                                                cancellable?.cancel()
                                                cancellable = nil
                                            }, receiveValue: { image in
                                                let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                                fairytale.imageThumbnail = image
                                                self.imageDownloader.cache.store(image, forKey: path)
                                                promise(.success(fairytale))
                                            })
                                    })
                                }
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(silentTotal)
                    .map ({ fairytales -> CategorySection in
                        CategorySection(title: "Тихая", description: "Успокоит малыша перед сном", color: ColorPalette.categoryDarkBlue,
                                        thumbnail: UIImage(named: "categorie-thumbnail-3")!, items: fairytales.compactMap { $0 }.sorted(), category: .silent)
                    })
                    .receive(on: Scheduler.main, options: nil)
                
                var cancellable: AnyCancellable?
                cancellable = Publishers.CombineLatest3(educationalCategory, healingCategory, silentCategory)
                    .map { Set<CategorySection>(arrayLiteral: $0.0, $0.1, $0.2) }
                    .eraseToAnyPublisher()
                    .sink(receiveCompletion: { _ in
                        cancellable?.cancel()
                        cancellable = nil
                    }, receiveValue: { [weak self] categories in
                        self?.categoriesInternalType.value = categories
                    })
            })
            .store(in: &bag)
    }
    
    func requestFairytales(by category: CategoryPath) {
        var cancellable: AnyCancellable?
        cancellable = db.collection("categories").document(category.rawValue).collection("fairytales").getDocuments()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): Logger.logError(error)
                case .finished: break
                }
                cancellable?.cancel()
                cancellable = nil
            }, receiveValue: { [weak self] snapshot in
                var fairytales = [FairytaleDTO]()
                for document in snapshot.documents {
                    //print("\(document.documentID) => \(document.data())")
                    do {
                        let obj = try document.data(as: FairytaleDTO.self)
                        guard let fairytale = obj else { return }
                        fairytales.append(fairytale)
                    } catch {
                        Logger.logError(error)
                    }
                }
                switch category {
                case .educational: self?.educationalSubject.value = fairytales
                case .healing: self?.healingSubject.value = fairytales
                case .silent: self?.silentSubject.value = fairytales
                }
            })
    }
}


 
 final class FirebaseClient1: ImageDownloaderProvidable {
     
     static let shared = FirebaseClient1()
     
     lazy var db: Firestore = {
         let fs = Firestore.firestore()
         let settings = FirestoreSettings()
         settings.isPersistenceEnabled = true
         settings.cacheSizeBytes = 1000 * 1024 * 1024
         fs.settings = settings
         return fs
     }()
     
     let storage = Firebase.Storage.storage()
     let userSubject = CurrentValueSubject<User?, Never>(nil)
     let categoriesInternalType = CurrentValueSubject<Set<CategorySection>?, Never>(nil)
     let categoriesSubject = CurrentValueSubject<[CategoryDTO]?, Never>(nil)
     let educationalSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
     let healingSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
     let silentSubject = CurrentValueSubject<[FairytaleDTO]?, Never>(nil)
     
     private init() {
         
     }
     private var bag = Set<AnyCancellable>()
     
     
     func signInAnonim() {
         var cancellable: AnyCancellable?
         cancellable = Auth.auth().signInAnonymously()
             .sink { completion in
                 switch completion {
                 case .finished: break
                 case let .failure(error): Logger.logError(error)
                 }
                 cancellable?.cancel()
                 cancellable = nil
             } receiveValue: { [weak self] authDataResult in
                 self?.userSubject.send(authDataResult.user)
             }
     }
     
     // for copy existing story, or extracting fields, or updating storie's inner fields structure
     func copyFields() {
         let db = Firestore.firestore()
         var cancellable: AnyCancellable?
         cancellable = db.collection("categories").document("healing").collection("fairytales").getDocuments()
             .sink(receiveCompletion: { completion in
                 switch completion {
                 case .failure(let error): Logger.logError(error)
                 case .finished: break
                 }
                 cancellable?.cancel()
                 cancellable = nil
             }, receiveValue: { snapshot in
                 for document in snapshot.documents {
                     db.collection("categories").document("healing").collection("fairytales").document("copy-2").setData(document.data()) { error in
                         guard let error = error else { return }
                         Logger.logError(error)
                     }
                 }
             })
     }
     
     func requestAllFairytalesAndMakeCategories(isForBoy: Bool) {
         requestFairytales(by: .educational)
         requestFairytales(by: .healing)
         requestFairytales(by: .silent)
         
 //        var educationalTotal: Int = 0
 //        var healingTotal: Int = 0
 //        var silentTotal: Int = 0
         
         let totalStoriesCountByCategories = Publishers.CombineLatest3(
             FirebaseClient.shared.educationalSubject.compactMap { $0 },
             FirebaseClient.shared.healingSubject.compactMap { $0 },
             FirebaseClient.shared.silentSubject.compactMap { $0 })
             .map { ($0.0, $0.1, $0.2) }
         
         Publishers.CombineLatest(Just(()).eraseToAnyPublisher(), totalStoriesCountByCategories)
             .map { $0.1 }.sink(receiveValue: { categoriesCount in
 //                educationalTotal = categoriesCount.0.count
 //                healingTotal = categoriesCount.1.count
 //                silentTotal = categoriesCount.2.count
                 
                 let educationalCategory = self.makeCategoryPublisher(subject: self.educationalSubject, catPath: .educational, isForBoy: isForBoy, catTitle: "Обучающая", catDescription: "Учит дружить, делиться и работать в команде", catColor: ColorPalette.categoryDarkGreen)
                 let healingCategory = self.makeCategoryPublisher(subject: self.healingSubject, catPath: .healing, isForBoy: isForBoy, catTitle: "Терапевтическая", catDescription: "Поможет справиться со страхами и стать увереннее", catColor: ColorPalette.categoryDarkRed)
                 let silentCategory = self.makeCategoryPublisher(subject: self.silentSubject, catPath: .silent, isForBoy: isForBoy, catTitle: "Тихая", catDescription: "Успокоит малыша перед сном", catColor: ColorPalette.categoryDarkBlue)
                 
                 var cancellable: AnyCancellable?
                 cancellable = Publishers.CombineLatest3(educationalCategory, healingCategory, silentCategory)
                     .map { Set<CategorySection>(arrayLiteral: $0.0, $0.1, $0.2) }
                     .eraseToAnyPublisher()
                     .sink(receiveCompletion: { _ in
                         cancellable?.cancel()
                         cancellable = nil
                     }, receiveValue: { [weak self] categories in
                         self?.categoriesInternalType.value = categories
                     })
             }).store(in: &bag)
     }
     
     func makeCategoryPublisher(subject: CurrentValueSubject<[FairytaleDTO]?, Never>, catPath: CategoryPath, isForBoy: Bool,
                                catTitle: String, catDescription: String, catColor: UIColor
     ) -> AnyPublisher<CategorySection, Never> {
         var total: Int = 0
         let category = subject.compactMap { $0 }
             .handleEvents(receiveOutput: { items in
                 total = items.count
                 print(total)
             }).flatMap ({ fairytales -> AnyPublisher<FairytaleDTO, Never> in
                 Publishers.Sequence(sequence: fairytales).eraseToAnyPublisher()
             }).flatMap({ fairytaleDTO -> AnyPublisher<StoryModel, Never> in
                 Future<StoryModel, Never> ({ [weak self] promise in
                     guard let self = self else { return }
                     let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? (isForBoy ? fairytaleDTO.cover.ipadBoy : fairytaleDTO.cover.ipadGirl) : (isForBoy ? fairytaleDTO.cover.iphoneBoy : fairytaleDTO.cover.iphoneGirl))
                     var c: AnyCancellable?
                     c = self.imageDownloader.fetchFromCache(path).sink(receiveCompletion: { completion in
                         c?.cancel()
                         c = nil
                     }, receiveValue: { image in
                         if let img = image {
                             let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                             fairytale.imageThumbnail = img
                             promise(.success(fairytale))
                         } else {
                             FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                 if let u = url { print(u) }
                                 if let error = error { Logger.logError(error) }
                                 let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                 fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                 guard let url = url else { return promise(.success(fairytale)) }
                                 var cancellable: AnyCancellable?
                                 cancellable = self.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                     .sink(receiveCompletion: { completion in
                                         switch completion {
                                         case .finished: break
                                         case .failure(let error):
                                             Logger.logError(error)
                                             let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                             fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                             promise(.success(fairytale))
                                         }
                                         cancellable?.cancel()
                                         cancellable = nil
                                     }, receiveValue: { image in
                                         let fairytale = StoryModel(dto: fairytaleDTO, isBoy: isForBoy)
                                         fairytale.imageThumbnail = image
                                         promise(.success(fairytale))
                                     })
                             })
                         }
                     })
                 }).eraseToAnyPublisher()
             })
             .collect(total)
             .eraseToAnyPublisher()
             .map { fairytales -> CategorySection in
                 CategorySection(title: catTitle, description: catDescription, color: catColor,
                                 thumbnail: UIImage(named: "categorie-thumbnail-1")!, items: fairytales, category: catPath)
             }.receive(on: Scheduler.main, options: nil)
             .eraseToAnyPublisher()
         return category
     }
     
     func requestFairytales(by category: CategoryPath) {
         var cancellable: AnyCancellable?
         cancellable = db.collection("categories").document(category.rawValue).collection("fairytales").getDocuments()
             .sink(receiveCompletion: { completion in
                 switch completion {
                 case .failure(let error): Logger.logError(error)
                 case .finished: break
                 }
                 cancellable?.cancel()
                 cancellable = nil
             }, receiveValue: { [weak self] snapshot in
                 var fairytales = [FairytaleDTO]()
                 for document in snapshot.documents {
                     //print("\(document.documentID) => \(document.data())")
                     do {
                         let obj = try document.data(as: FairytaleDTO.self)
                         guard let fairytale = obj else { return }
                         fairytales.append(fairytale)
                     } catch {
                         Logger.logError(error)
                     }
                 }
                 switch category {
                 case .educational: self?.educationalSubject.value = fairytales
                 case .healing: self?.healingSubject.value = fairytales
                 case .silent: self?.silentSubject.value = fairytales
                 }
             })
     }
 }
