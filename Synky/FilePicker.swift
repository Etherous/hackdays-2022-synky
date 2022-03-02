//
//  FilePicker.swift
//  Synky
//
//  Created by Brandon Lyon on 3/1/22.
//

import SwiftUI

struct FilePicker : UIViewControllerRepresentable {
    class FilePickerCoordinator: NSObject,UIDocumentPickerDelegate,UINavigationControllerDelegate {
        @Binding var selection: [URL]
        
        init(selection: Binding<[URL]>) {
            _selection = selection
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            selection = urls
        }
    }
    
    @Binding var selection: [URL]
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        controller.delegate = context.coordinator
        controller.directoryURL = URL(string: "/")
        return controller
    }
    
    func makeCoordinator() -> FilePickerCoordinator {
        return FilePickerCoordinator(selection: $selection)
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<FilePicker>) {
    }
}
