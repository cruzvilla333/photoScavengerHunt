import SwiftUI
import MapKit
import Photos
import PhotosUI
import CoreLocation

struct Activity: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var selectedImage: UIImage?
}

struct TaskListView: View {
    @State private var activities = [Activity(title: "favorite hiking spot", description: "choose your favorite hiking spot"), Activity(title: "best ice cream", description: "tells us where the best ice cream you've had is"), Activity(title: "favorite concert", description: "tell us where the best concert you've been to was"), Activity(title: "coolest hike", description: "show where the best hike you have been on was")]
    @State private var newActivityTitle = ""
    @State private var newActivityDescription = ""
    @State private var editingTask: Activity?
    @State private var isAddingTask = false

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(self.$activities) { $activity in
                        NavigationLink(destination: TaskDetailView(activity: $activity, initialTitle: activity.title, initialDescription: activity.description, initialImage: activity.selectedImage, onDelete: { taskToDelete in
                            self.activities.removeAll(where: { $0.id == taskToDelete.id })
                        })) {
                            HStack {
                                Text(activity.title)
                                Image(systemName: activity.selectedImage != nil ? "checkmark.circle.fill" : "circle")
                            }
                            
                        }
                    }
                    .onDelete { indexSet in
                        self.activities.remove(atOffsets: indexSet)
                    }
                }
                
                HStack {
                    Button(action: {
                        self.isAddingTask = true // Show the modal when this button is tapped
                    }) {
                        Text("Create Activity")
                    }
                }
                .padding()
            }
            .navigationTitle("Activities")
            .sheet(isPresented: $isAddingTask) {
                // Add Task Modal
                AddTaskView(isPresented: self.$isAddingTask, tasks: self.$activities, newActivityTitle: self.$newActivityTitle, newActivityDescription: self.$newActivityDescription)
            }
        }
    }
}

struct AddTaskView: View {
    @Binding var isPresented: Bool
    @Binding var tasks: [Activity]
    @Binding var newActivityTitle: String
    @Binding var newActivityDescription: String

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter activity title", text: $newActivityTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Enter activity description", text: $newActivityDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: {
                    self.addTask()
                    self.isPresented = false
                }) {
                    Text("Create Activity")
                }
                .padding()
            }
            .navigationTitle("Create Activity")
        }
    }

    func addTask() {
        if !newActivityTitle.isEmpty && !newActivityDescription.isEmpty{
            let newTask = Activity(title: newActivityTitle, description: newActivityDescription)
            tasks.append(newTask)
            newActivityTitle = ""
            newActivityDescription = ""
        }
    }
}

struct TaskDetailView: View {
    @Binding var activity: Activity
    var onDelete: (Activity) -> Void

    @State private var selectedImage: UIImage?
    @State private var imageLocation: String = ""
    @State private var editedActivityTitle: String
    @State private var editedActivityDescription: String
    @State private var isShowingImagePicker = false
    @State private var photoLocation: CLLocationCoordinate2D?


    init(activity: Binding<Activity>, initialTitle: String, initialDescription: String, initialImage: UIImage?, onDelete: @escaping (Activity) -> Void) {
        _activity = activity
        self.onDelete = onDelete
        _editedActivityTitle = State(initialValue: initialTitle)
        _editedActivityDescription = State(initialValue: initialDescription)
        _selectedImage = State(initialValue: initialImage)
    }
    
    let location = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: activity.selectedImage != nil ? "checkmark.circle.fill" : "circle")
                    Text(activity.selectedImage != nil ? "completed" : "not completed")
                }
                TextField("Activity Title", text: $editedActivityTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Activity Description", text: $editedActivityDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                if(photoLocation != nil) {
                    MapView(coordinate: photoLocation!)
                        .edgesIgnoringSafeArea(.all)
                        .frame(height: 300)
                } else {
                    Image(systemName: "map").resizable()
                        .scaledToFit().frame(width: 250, height: 250)
                }
                if(selectedImage != nil && photoLocation == nil) {
                    Text("no image loacation found")
                }
                VStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    } else {
                        Spacer()
                        Button("Select Image") {
                            self.isShowingImagePicker = true
                        }
                    }
                }.sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
                    ImagePicker(image: self.$selectedImage, isPresented: self.$isShowingImagePicker)
                }
                Button(action: {
                    self.updateTask()
                }) {
                    Text("Update Activity")
                }
                .padding()
                Button(action: {
                    self.onDelete(activity)
                }) {
                    Text("Delete Activity")
                }
                .padding()
            }
            .navigationTitle("Edit Activity")
        }
    }
    
    func loadImage() {
        if selectedImage != nil {
            activity.selectedImage = selectedImage
            photoLocation = getLocation(from: selectedImage!)
        }
        
        }
    
    func updateTask() {
        if !editedActivityTitle.isEmpty {
            activity.title = editedActivityTitle
        }
        if !editedActivityDescription.isEmpty {
            activity.description = editedActivityDescription
        }
    }
    
    func getLocation(from image: UIImage) -> CLLocationCoordinate2D? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to get JPEG representation of image")
            return nil
        }

        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            print("Failed to create image source")
            return nil
        }

        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            print("Failed to extract image properties")
            return nil
        }
        let testInfo = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any]

        if let gpsInfo = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            print("GPS Info:", gpsInfo)
            
            if let latitude = gpsInfo[kCGImagePropertyGPSLatitude as String] as? CLLocationDegrees,
               let longitude = gpsInfo[kCGImagePropertyGPSLongitude as String] as? CLLocationDegrees {
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                print("Latitude and/or longitude information not found")
                return nil
            }
        } else {
            print("GPS information not found")
            return nil
        }
    }

    func extractLocation(from info: [UIImagePickerController.InfoKey : Any]) {
            if let assetURL = info[.imageURL] as? URL {
                let asset = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil).firstObject
                asset?.location.map { location in
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    self.imageLocation = "Latitude: \(latitude), Longitude: \(longitude)"
                }
            } else {
                self.imageLocation = "Location information not available"
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
            let parent: TaskDetailView

            init(parent: TaskDetailView) {
                self.parent = parent
            }

            func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                    parent.extractLocation(from: info)
                }

                picker.dismiss(animated: true, completion: nil)
            }

            func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
            }
        }
}

struct ContentView: View {
    var body: some View {
        TaskListView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No need to update the view controller
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }

            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No need to update the view controller
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedImage = nil // Reset selected image
            
            if let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { (image, error) in
                    if let image = image as? UIImage {
                        self.parent.selectedImage = image
                    }
                }
            }
            
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
