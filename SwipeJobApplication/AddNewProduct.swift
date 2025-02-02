//
//  AddNewProduct.swift
//  SwipeJobApplication
//
//  Created by Anubhav Rawat on 1/31/25.

import SwiftUI
import SwiftData

struct AddNewProduct: View {
    
    @Environment(\.modelContext) var modelContext
    @ObservedObject var viewModel: ListingPageViewModel
    
    @State var showImagePicker: Bool = false
    
    var body: some View {
        VStack{
            if !viewModel.addProductsFeedback.isEmpty{
                Text(viewModel.addProductsFeedback)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                            self.viewModel.addProductsFeedback = ""
                        }
                    }
            }
            
            if !viewModel.addProductValidationError.isEmpty{
                Text("Validation Error: \(viewModel.addProductValidationError)")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                            self.viewModel.addProductValidationError = ""
                        }
                    }
            }
            
            Form{
                Section(header: Text("Product Details").font(.headline)) {
                    CustomTextField(label: "Product Name", text: $viewModel.name)
                    
                    Menu {
                        ForEach(viewModel.options, id: \.self) { type in
                            Button(action: { viewModel.type = type }) {
                                Text(type)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Product Type")
                            Spacer()
                            Text(viewModel.type)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)))
                    }
                    
                    CustomNumberField(label: "Selling Price ($)", value: $viewModel.sellingPrice)
                    CustomNumberField(label: "Tax (%)", value: $viewModel.taxRate)
                        .onChange(of: viewModel.taxRate) { _, newValue in
                            if newValue >= 100.0{
                                viewModel.taxRate = 100.0
                            }
                            
                            if newValue <= 0{
                                viewModel.taxRate = 0.0
                            }
                        }
                    
                    if let image = viewModel.pickedImage{
                        Image(uiImage: image)
                            .productImageSize()
                    }
                    
                    //            image picker
                    Button {
                        showImagePicker = true
                    } label: {
                        Text(viewModel.pickedImage == nil ? "Pick an image" : "Change Image")
                    }
                    Button {
                        viewModel.addButtonPressed(context: modelContext)
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10).fill(.orange).frame(width: 170, height: 40)
                            Text("Add Product")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.pickedImage, isImagePickerPresented: $showImagePicker)
        }
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField(label, text: $text)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)))
                .keyboardType(keyboardType)
        }
    }
}

struct CustomNumberField: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField(label, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)))
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isImagePickerPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isImagePickerPresented = false
        }
    }
    
    @Binding var selectedImage: UIImage?
    @Binding var isImagePickerPresented: Bool
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary // You can change to .camera for camera access
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update logic if needed
    }
}

