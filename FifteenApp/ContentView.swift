//
//  ContentView.swift
//  FifteenApp
//
//  Created by sophie on 2025-12-24.
//

import SwiftUI
import CoreData

enum NavigationDestinationEnum: Hashable {
    // Main App Navigation
    case jupyterNotebook
    case richNote
    case savedNotes
    case importExport
    case deleteAll
    
    // Note Detail Navigation
    case noteDetail(RichNote)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .jupyterNotebook:
            hasher.combine("jupyterNotebook")
        case .richNote:
            hasher.combine("richNote")
        case .savedNotes:
            hasher.combine("savedNotes")
        case .importExport:
            hasher.combine("importExport")
        case .deleteAll:
            hasher.combine("deleteAll")
        case .noteDetail(let note):
            hasher.combine(note.id)
        }
    }
    
    static func == (lhs: NavigationDestinationEnum, rhs: NavigationDestinationEnum) -> Bool {
        switch (lhs, rhs) {
        case (.jupyterNotebook, .jupyterNotebook),
             (.richNote, .richNote),
             (.savedNotes, .savedNotes),
             (.importExport, .importExport),
             (.deleteAll, .deleteAll):
            return true
        case (.noteDetail(let note1), .noteDetail(let note2)):
            return note1.id == note2.id
        default:
            return false
        }
    }
}

struct ContentView: View {
    
    var body: some View {
        NavigationStack
        {
            VStack {
                //    Text("Learn")
                //Image("baby").imageScale(.medium)
                
                // 2. Use a NavigationLink to the destination view
                

                NavigationLink(value: NavigationDestinationEnum.jupyterNotebook) {
                    Text("View Jupyter Notebook")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                
                NavigationLink(value: NavigationDestinationEnum.richNote) {
                    Text("Add Rich Note")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                NavigationLink(value: NavigationDestinationEnum.savedNotes) {
                    Text("View Saved Note")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                NavigationLink(value: NavigationDestinationEnum.importExport) {
                    Text("Import/Export Note")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Spacer()
                
                NavigationLink(value: NavigationDestinationEnum.deleteAll) {
                    Text("Remove All")
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: NavigationDestinationEnum.self) { destination in
                            switch destination {
                            case .jupyterNotebook:
                                Text("B") //JupyterNotebookView()
                            case .richNote:
                                RichNoteView()
                            case .savedNotes:
                                SavedNotesView()
                            case .importExport:
                                RichNoteImportExportView()
                            case .deleteAll:
                                DeleteAll()
                            case .noteDetail(_):
                                VStack { }
                            }
                        }
        }
    }
}

struct ViewSubjects : View {
    
    @FetchRequest(sortDescriptors: []) var subjects: FetchedResults<MySubject>
    
    @State private var selectedTab = 0
    
    var body: some View {
        if subjects.count == 0
        {
            EmptyView()
        }
        else {
            TabView(selection: $selectedTab) {
                ForEach(subjects) { sub in
                    ViewSubject(name: sub.name! , id: sub.id!, detail: sub.detail ?? "<empty>")
                        .tabItem { Text(sub.name! ) }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        }
    }
}

struct AddSubjectView : View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    @State var text = ""
    @State var detail = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("Name")
                    .padding()
                TextField("Name", text: $text)
                    .padding()
            }
            
            HStack {
                Text("Detail")
                    .padding()
                TextEditor(text: $detail)
                    .padding()
            }
            
            Button("Save") {
                print("Saving.. " + text)
                let subject = MySubject(context: moc)
                subject.name = text
                subject.id = UUID()
                try? moc.save()
                dismiss()
            }
            .padding().navigationTitle("Add subject")
        }
        .padding()
    }
}

struct EditSubjectView : View {
    
    @FetchRequest var currentSub : FetchedResults<MySubject>
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    @State var text: String
    @State var detail: String
    var id: UUID //= UUID(uuidString: "")
    
    init(name: String, id: UUID, detail: String)
    {
        _text = State(initialValue: name)
        _detail = State(initialValue: detail)
        
        self.id = id
        
        //Here in my predicate I use self.type variable
        let predicate = NSPredicate(format: "id == %@", id as NSUUID)

        //Intialize the FetchRequest property wrapper
        self._currentSub = FetchRequest(entity: MySubject.entity(), sortDescriptors: [], predicate: predicate)
    }
    
    var body: some View {

        VStack {
            HStack {
                Text("Name")
                    .padding()
                TextField("Name", text: $text)
                    .padding()
            }
            
            HStack {
                Text("Detail")
                    .padding()
                TextEditor(text: $detail)
                    .padding()
            }
            
            Button("Save") {
                if currentSub.count != 0
                {
                    let sub = currentSub[0]
                    sub.name = text
                    sub.detail = detail
                    try? moc.save()
                    dismiss()
                }
            }
            .padding().navigationTitle("Edit subject")
        }
        
    }
}

struct ViewSubject : View {
    
    @FetchRequest var currentSub : FetchedResults<MySubject>
    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss
    
    init(name: String, id: UUID, detail: String) {
        self.name = name
        self.id = id
        self.detail = detail
        
        //Here in my predicate I use self.type variable
        let predicate = NSPredicate(format: "id == %@", id as NSUUID)

        //Intialize the FetchRequest property wrapper
        self._currentSub = FetchRequest(entity: MySubject.entity(), sortDescriptors: [], predicate: predicate)

    }
    
    var name: String
    var id: UUID
    var detail: String
    
    var body: some View {
        VStack {
            Text("\n")
            Text(name).padding(.vertical)
            Text(detail).padding(.vertical)
            Spacer()
            HStack {
                Button("Remove") {
                    if currentSub.count != 0
                    {
                        let sub = currentSub[0]
                        moc.delete(sub)
                        try? moc.save()
                        dismiss()
                    }
                }
                .padding(.horizontal)
                
                NavigationLink(destination: EditSubjectView(name: name, id: id, detail: detail)) {
                    Text("Edit")
                        .padding()
                }
                .padding(.horizontal)
            }
            Spacer()
        }
    }
}


struct DeleteAll : View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        VStack {
            Text("Are you sure you want to remove all? This action cannot be undone.")
                .padding(.horizontal)
            Spacer()
            Button("Remove all") {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "MySubject")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try moc.execute(deleteRequest)
                } catch _ as NSError {
                    // TODO: handle the error
                }
                dismiss()
            
            }
            Spacer()
        }
    }
    
}

struct iOSView: View {
    var body: some View {
        //NavigationView
        //{
            VStack
            {
                Text("iOS")
                    .navigationTitle("Learn")
                
                // 2. Use a NavigationLink to the destination view
//                NavigationLink(destination: ThirdView()) {
//                    Text("Go to Next View")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
            }
        //}
    }
}

struct JapaneseView : View {
    var body: some View {
        Text("Japanese")
    }
}



//#Preview {
 //   ViewSubject(name: "blah", id: UUID(), detail: "deets")
//}
