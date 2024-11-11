import SwiftUI
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {

    @Binding var selectedImages: [UIImage]
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePickerView
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.selectedImages.append(uiImage)
                            }
                        }
                    }
                }
            }
        }
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // 0 means no limit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

struct ContentView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var popUpShow = false
    
    init() {
        // Customize the navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.blue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
    }
    
    var body: some View {
        NavigationView{
            VStack {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .padding(4)
                        }
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePickerView(selectedImages: $selectedImages)
                }
                .alert("確認画面",isPresented: $popUpShow){
                    Button("OK"){
                        uploadImages()
                    }
                    Button("キャンセル", role: .cancel){}
                }message:{
                    Text("検索に行きますがいいですか？")
                }
                // ツールバー
                .toolbar {
                    // ボトムバー
                    ToolbarItemGroup(placement: .bottomBar){
                        Spacer()
                        
                        // カメラ
                        Button(action: {
                        }) {
                            VStack{
                                Image(systemName: "camera").foregroundColor(.gray)
                                Text("カメラ").font(.footnote).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        // アルバム
                        Button(action: {
                            showingImagePicker = true
                            selectedImages = []
                        }) {
                            VStack{
                                Image(systemName: "photo").foregroundColor(.gray)
                                Text("アルバム").font(.footnote).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        
                        // 実行
                        Button(action: {
                            popUpShow.toggle()
                        }) {
                            VStack{
                                Image(systemName: "icloud.and.arrow.up").foregroundColor(.gray)
                                Text("検索").font(.footnote).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Plisn2024")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func uploadImages() {
        guard !selectedImages.isEmpty else { return }
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 1.0)?.base64EncodedString() {
                let filename = "image\(index).jpg"
                uploadImage(base64String: imageData, filename: filename)
            }
        }
    }

    func uploadImage(base64String: String, filename: String) {
        let urlString = "https://xxx.xxx.com/upload/\(filename)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyString = "image_data=\(base64String)"
        request.httpBody = bodyString.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
        }.resume()
    }
    /*
    func uploadImages() {
        guard !selectedImages.isEmpty else { return }
        let url = URL(string: "http://example.com/api/upload")! // APIのURLを指定してください。
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        for (index, image) in selectedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\(index)\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // URLSessionを使用してリクエストを送信する
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error during request: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
            }
            
            if let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
        }.resume()
    }
    */
}
