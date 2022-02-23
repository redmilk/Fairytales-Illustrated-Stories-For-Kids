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
    
    let db = Firestore.firestore()
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
    
    func requestAllFairytalesAndMakeCategories() {
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
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? fairytaleDTO.image_ipad : fairytaleDTO.image_iphone)
                            FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                if let u = url {
                                    print(u)
                                }
                                if let error = error { Logger.logError(error) }
                                let fairytale = StoryModel(dto: fairytaleDTO)
                                fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                guard let url = url else { return promise(.success(fairytale)) }
                                var cancellable: AnyCancellable?
                                cancellable = self?.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                //.subscribe(on: Scheduler.backgroundWorkScheduler)
                                    .sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished:
                                            break
                                        case .failure(let error):
                                            Logger.logError(error)
                                            let fairytale = StoryModel(dto: fairytaleDTO)
                                            fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                            promise(.success(fairytale))
                                        }
                                        cancellable?.cancel()
                                        cancellable = nil
                                    }, receiveValue: { image in
                                        let fairytale = StoryModel(dto: fairytaleDTO)
                                        fairytale.imageThumbnail = image
                                        promise(.success(fairytale))
                                    })
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(educationalTotal)
                    .eraseToAnyPublisher()
                    .map { fairytales -> CategorySection in
                        CategorySection(title: "Обучающая", color: ColorPalette.categoryDarkGreen,
                                        thumbnail: UIImage(named: "categorie-thumbnail-1")!, items: fairytales, category: .educational)
                    }
                    .receive(on: Scheduler.main, options: nil)
                
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
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? fairytaleDTO.image_ipad : fairytaleDTO.image_iphone)
                            FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                if let error = error { Logger.logError(error) }
                                let fairytale = StoryModel(dto: fairytaleDTO)
                                fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                guard let url = url else { return promise(.success(fairytale)) }
                                var cancellable: AnyCancellable?
                                cancellable = self?.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                    .subscribe(on: Scheduler.backgroundWorkScheduler)
                                    .sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished: break
                                        case .failure(let error):
                                            Logger.logError(error)
                                            let fairytale = StoryModel(dto: fairytaleDTO)
                                            fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                            promise(.success(fairytale))
                                        }
                                        cancellable?.cancel()
                                        cancellable = nil
                                    }, receiveValue: { image in
                                        let fairytale = StoryModel(dto: fairytaleDTO)
                                        fairytale.imageThumbnail = image
                                        promise(.success(fairytale))
                                    })
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(healingTotal)
                    .map ({ fairytales -> CategorySection in
                        //Logger.log("Healing: " + fairytales.count.description, type: .all)
                        CategorySection(title: "Терапевтическая", color: ColorPalette.categoryDarkRed,
                                        thumbnail: UIImage(named: "categorie-thumbnail-2")!, items: fairytales.compactMap { $0 }, category: .healing)
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
                            let path = fairytaleDTO.storage_path + (UIDevice.current.isIPad ? fairytaleDTO.image_ipad : fairytaleDTO.image_iphone)
                            FirebaseClient.shared.storage.reference(withPath: path).downloadURL(completion: { url, error in
                                if let error = error { Logger.logError(error) }
                                let fairytale = StoryModel(dto: fairytaleDTO)
                                fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                guard let url = url else { return promise(.success(fairytale)) }
                                var cancellable: AnyCancellable?
                                cancellable = self?.imageDownloader.loadImage(withURL: url, cacheKey: path)
                                    .subscribe(on: Scheduler.backgroundWorkScheduler)
                                    .sink(receiveCompletion: { completion in
                                        switch completion {
                                        case .finished: break
                                        case .failure(let error):
                                            Logger.logError(error)
                                            let fairytale = StoryModel(dto: fairytaleDTO)
                                            fairytale.imageThumbnail = Constants.storyThumbnailPlaceholder
                                            promise(.success(fairytale))
                                        }
                                        cancellable?.cancel()
                                        cancellable = nil
                                    }, receiveValue: { image in
                                        let fairytale = StoryModel(dto: fairytaleDTO)
                                        fairytale.imageThumbnail = image
                                        promise(.success(fairytale))
                                    })
                            })
                        }).eraseToAnyPublisher()
                    })
                    .collect(silentTotal)
                    .map ({ fairytales -> CategorySection in
                        CategorySection(title: "Тихая", color: ColorPalette.categoryDarkBlue,
                                        thumbnail: UIImage(named: "categorie-thumbnail-3")!, items: fairytales.compactMap { $0 }, category: .silent)
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
    
    func requestCategories() {
        var cancellable: AnyCancellable?
        cancellable = db.collection("categories").getDocuments()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): Logger.logError(error)
                case .finished: break
                }
                cancellable?.cancel()
                cancellable = nil
            }, receiveValue: { [weak self] snapshot in
                var categories = [CategoryDTO]()
                for document in snapshot.documents {
                    //print("\(document.documentID) => \(document.data())")
                    do {
                        let obj = try document.data(as: CategoryDTO.self)
                        guard let category = obj else { return }
                        categories.append(category)
                    } catch {
                        Logger.logError(error)
                    }
                }
                self?.categoriesSubject.value = categories
            })
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
    
    func signInWithGoogle() {
        /*
         func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
         // ...
         if let error = error {
         // ...
         return
         }
         
         guard let authentication = user.authentication else { return }
         let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
         accessToken: authentication.accessToken)
         Auth.auth()
         .signIn(withCredential: credential)
         .mapError { $0 as NSError }
         .tryCatch(handleError)
         .sink { /* ... */ } receiveValue: {  /* ... */  }
         .store(in: &bag)
         }
         
         private func handleError(_ error: NSError) throws -> AnyPublisher<AuthDataResult, Error> {
         guard isMFAEnabled && error.code == AuthErrorCode.secondFactorRequired.rawValue
         else { throw error }
         
         // The user is a multi-factor user. Second factor challenge is required.
         let resolver = error.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
         let displayNameString = resolver.hints.compactMap(\.displayName).joined(separator: " ")
         
         return showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)")
         .compactMap { displayName in
         resolver.hints.first(where: { displayName == $0.displayName }) as? PhoneMultiFactorInfo
         }
         .flatMap { [unowned self] factorInfo in
         PhoneAuthProvider.provider()
         .verifyPhoneNumber(withMultiFactorInfo: factorInfo, multiFactorSession: resolver.session)
         .zip(self.showTextInputPrompt(withMessage: "Verification code for \(factorInfo.displayName ?? "")"))
         .map { (verificationID, verificationCode) in
         let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID,
         verificationCode: verificationCode)
         return PhoneMultiFactorGenerator.assertion(with: credential)
         }
         }
         .flatMap { assertion in
         resolver.resolveSignIn(withAssertion: assertion)
         }
         .eraseToAnyPublisher()
         }
         */
    }
    
    func addFairytaleToCategory(_ category: CategoryPath, name: String) {
        let page1Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 1 для мальчика, русская локализация", "en" : "Page 1 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 1 для девочки, русская локализация", "en" : "Page 1 text for girl, example with english localization"])
        
        let page1Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/01/boy/Vmeste_veselee_ipad1.jpeg",
                                     boy_iphone: "/Categories/Educational/Cinderella/01/boy/Vmeste_veselee_iphone1.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/01/girl/Vmeste_veselee_ipad1.jpeg",
                                     girl_iphone: "/Categories/Educational/Cinderella/01/girl/Vmeste_veselee_iphone1.png")
        let page1 = PageModel(images: page1Images, text: page1Text, page: 1)
        
        let page2Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 2 для мальчика, русская локализация", "en" : "Page  2 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы  2 для девочки, русская локализация", "en" : "Page 2  text for girl, example with english localization"])
        let page2Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/02/boy/Vmeste_veselee_ipad2.jpeg",
                                     boy_iphone: "/Categories/Educational/Cinderella/02/boy/Vmeste_veselee_iphone2.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/02/girl/Vmeste_veselee_ipad2.jpeg",
                                     girl_iphone: "/Categories/Educational/Cinderella/02/girl/Vmeste_veselee_iphone2.png")
        let page2 = PageModel(images: page2Images, text: page2Text, page: 2)
        
        
        let page3Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 3 для мальчика, русская локализация", "en" : "Page  3 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 3 для девочки, русская локализация", "en" : "Page 3  text for girl, example with english localization"])
        let page3Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/03/boy/Vmeste_veselee_ipad3.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/03/boy/Vmeste_veselee_iphone3.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/03/girl/Vmeste_veselee_ipad3.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/03/girl/Vmeste_veselee_iphone3.png")
        let page3 = PageModel(images: page3Images, text: page3Text, page: 3)
        
        let page4Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 4  для мальчика, русская локализация", "en" : "Page 4 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 4 для девочки, русская локализация", "en" : "Page 4 text for girl, example with english localization"])
        
        let page4Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/04/boy/Vmeste_veselee_ipad4.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/04/boy/Vmeste_veselee_iphone4.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/04/girl/Vmeste_veselee_ipad4.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/04/girl/Vmeste_veselee_iphone4.png")
        let page4 = PageModel(images: page4Images, text: page4Text, page: 4)
        
        let page5Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 5 для мальчика, русская локализация", "en" : "Page 5 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 5 для девочки, русская локализация", "en" : "Page 5 text for girl, example with english localization"])
        let page5Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/05/boy/Vmeste_veselee_ipad5.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/05/boy/Vmeste_veselee_iphone5.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/05/girl/Vmeste_veselee_ipad5.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/05/girl/Vmeste_veselee_iphone5.png")
        let page5 = PageModel(images: page5Images, text: page5Text, page: 5)
        
        let page6Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 6 для мальчика, русская локализация", "en" : "Page 6  text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 6 для девочки, русская локализация", "en" : "Page 6 text for girl, example with english localization"])
        let page6Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/06/boy/Vmeste_veselee_ipad6.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/06/boy/Vmeste_veselee_iphone6.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/06/girl/Vmeste_veselee_ipad6.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/06/girl/Vmeste_veselee_iphone6.png")
        let page6 = PageModel(images: page6Images, text: page6Text, page: 6)
        
        let page7Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 7 для мальчика, русская локализация", "en" : "Page 7 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы 7  для девочки, русская локализация", "en" : "Page  7 text for girl, example with english localization"])
        
        let page7Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/07/boy/Vmeste_veselee_ipad7.jpeg",
                                     boy_iphone: "/Categories/Educational/Cinderella/07/boy/Vmeste_veselee_iphone9.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/07/girl/Vmeste_veselee_ipad7.jpeg",
                                     girl_iphone: "/Categories/Educational/Cinderella/07/girl/Vmeste_veselee_iphone9.png")
        let page7 = PageModel(images: page7Images, text: page7Text, page: 7)
        
        let page8Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы 8 для мальчика, русская локализация", "en" : "Page 8 text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы  8 для девочки, русская локализация", "en" : "Page 8 text for girl, example with english localization"])
        
        let page8Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/08/boy/Vmeste_veselee_ipad8.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/08/boy/Vmeste_veselee_iphone8.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/08/girl/Vmeste_veselee_ipad8.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/08/girl/Vmeste_veselee_iphone8.png")
        let page8 = PageModel(images: page8Images, text: page8Text, page: 8)
        
        
        let page9Text = PageText(default_text: "Page text by default example",
                                 boy: ["ru" : "Пример текста страницы  9 для мальчика, русская локализация", "en" : "Page 9  text for boy, example with english localization"],
                                 girl: ["ru" : "Пример текста страницы  9 для девочки, русская локализация", "en" : "Page 9 text for girl, example with english localization"])
        
        let page9Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/09/boy/Vmeste_veselee_ipad8.png",
                                     boy_iphone: "/Categories/Educational/Cinderella/09/boy/Vmeste_veselee_iphone10.png",
                                     girl_ipad: "/Categories/Educational/Cinderella/09/girl/Vmeste_veselee_ipad8.png",
                                     girl_iphone: "/Categories/Educational/Cinderella/09/girl/Vmeste_veselee_iphone10.png")
        let page9 = PageModel(images: page9Images, text: page9Text, page: 9)
        
        let page10Text = PageText(default_text: "Page text by default example",
                                  boy: ["ru" : "Пример текста страницы 10 для мальчика, русская локализация", "en" : "Page 10  text for boy, example with english localization"],
                                  girl: ["ru" : "Пример текста страницы 10 для девочки, русская локализация", "en" : "Page 10 text for girl, example with english localization"])
        
        let page10Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/10/boy/Vmeste_veselee_ipad9.png",
                                      boy_iphone: "/Categories/Educational/Cinderella/10/boy/Vmeste_veselee_iphone11.png",
                                      girl_ipad: "/Categories/Educational/Cinderella/10/girl/Vmeste_veselee_ipad9.png",
                                      girl_iphone: "/Categories/Educational/Cinderella/10/girl/Vmeste_veselee_iphone11.png")
        let page10 = PageModel(images: page10Images, text: page10Text, page: 10)
        
        let page11Text = PageText(default_text: "Page text by default example",
                                  boy: ["ru" : "Пример текста страницы 11 для мальчика, русская локализация", "en" : "Page 11 text for boy, example with english localization"],
                                  girl: ["ru" : "Пример текста страницы 11 для девочки, русская локализация", "en" : "Page 11 text for girl, example with english localization"])
        
        let page11Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/11/boy/Vmeste_veselee_ipad10.png",
                                      boy_iphone: "/Categories/Educational/Cinderella/11/boy/Vmeste_veselee_iphone12.png",
                                      girl_ipad: "/Categories/Educational/Cinderella/11/girl/Vmeste_veselee_ipad10.png",
                                      girl_iphone: "/Categories/Educational/Cinderella/11/girl/Vmeste_veselee_iphone12.png")
        let page11 = PageModel(images: page11Images, text: page11Text, page: 11)
        
        let page12Text = PageText(default_text: "Page text by default example",
                                  boy: ["ru" : "Пример текста страницы  12 для мальчика, русская локализация", "en" : "Page 12 text for boy, example with english localization"],
                                  girl: ["ru" : "Пример текста страницы 12 для девочки, русская локализация", "en" : "Page 12 text for girl, example with english localization"])
        
        let page12Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/12/boy/Vmeste_veselee_ipad11.png",
                                      boy_iphone: "/Categories/Educational/Cinderella/12/boy/Vmeste_veselee_iphone13.png",
                                      girl_ipad: "/Categories/Educational/Cinderella/12/girl/Vmeste_veselee_ipad11.png",
                                      girl_iphone: "/Categories/Educational/Cinderella/12/girl/Vmeste_veselee_iphone13.png")
        let page12 = PageModel(images: page12Images, text: page12Text, page: 12)
        
        let page13Text = PageText(default_text: "Page text by default example",
                                  boy: ["ru" : "Пример текста страницы 13 для мальчика, русская локализация", "en" : "Page 13 text for boy, example with english localization"],
                                  girl: ["ru" : "Пример текста страницы 13  для девочки, русская локализация", "en" : "Page 13 text for girl, example with english localization"])
        
        let page13Images = PageImages(boy_ipad: "/Categories/Educational/Cinderella/13/boy/Vmeste_veselee_ipad12.png",
                                      boy_iphone: "/Categories/Educational/Cinderella/13/boy/Vmeste_veselee_iphone14.png",
                                      girl_ipad: "/Categories/Educational/Cinderella/13/girl/Vmeste_veselee_ipad12.png",
                                      girl_iphone: "/Categories/Educational/Cinderella/13/girl/Vmeste_veselee_iphone14.png")
        let page13 = PageModel(images: page13Images, text: page13Text, page: 13)
        
        let titles: [String: String] = ["en": "Fairytale title english sample", "ru" : "Пример-название сказки рус. локализация"]
        
        let fairytale = FairytaleDTO(titles: titles, annotation: ["ru" : ["boy": "sample annotation"]], description: ["ru": "Example description"],
                                     default_title: "example_default_title", id_internal: "fairytale-sample-id",
                                     pages: [page1, page2, page3, page4, page5, page6, page7, page8, page9, page10, page11, page12, page13],
                                     image_ipad: "/00_thumbnail/Vmeste_veselee_ipad6.png",
                                     image_iphone: "/00_thumbnail/Vmeste_veselee_iphone6.png",
                                     storage_path: "/Categories/Educational/Cinderella")
        
        var cancellable: AnyCancellable?
        cancellable = db.collection("categories").document(category.rawValue).collection("fairytales").document(name).setData(from: fairytale)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error): Logger.logError(error)
                }
                cancellable?.cancel()
                cancellable = nil
            }, receiveValue: { ref in })
    }
}

