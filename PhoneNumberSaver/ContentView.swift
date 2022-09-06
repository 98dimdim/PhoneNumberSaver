//
//  ContentView.swift
//  PhoneNumberSaver
//
//  Created by dimas.prabowo on 06/09/22.
//

import SwiftUI
import Contacts

struct ContentView: View {
    @State private var name: String = ""
    @State private var number: String = ""
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Name")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.leading, 10)
                .padding(.bottom, 10)
            
            TextField("", text: $name)
                .font(.body)
                .textFieldStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(height: 40)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.black, lineWidth: 1)
                )
            
            Text("Number")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.leading, 10)
                .padding(.vertical, 10)
                .padding(.top, 10)
            
            TextField("", text: $number)
                .keyboardType(.decimalPad)
                .font(.body)
                .textFieldStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(height: 40)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.black, lineWidth: 1)
                )
            
            Button("+ Add to Contacts") {
                Task.init {
                    await saveContact()
                }
            }
            .foregroundColor(.white)
            .frame(width: 200, height: 40)
            .background(.blue)
            .cornerRadius(10)
            .buttonStyle(.borderless)
            .padding(.top, 30)
        }
        .padding()
    }
    
    func saveContact() async {
        /// Create access to contact store
        let store = CNContactStore()
        let status: CNAuthorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .denied, .restricted:
            guard let settingURL = await URL(string: UIApplication.openSettingsURLString) else {
                print("Unable to access contact")
                return
            }
            await UIApplication.shared.open(settingURL)
        case .notDetermined:
            do {
                /// Request access to user
                try await store.requestAccess(for: .contacts)
            } catch {
                print(error)
            }
        case .authorized:
            updateContact(store)
        @unknown default:
            break
        }
    }
    
    func updateContact(_ store: CNContactStore) {
        /// Create new phone number
        let phoneNumber = CNLabeledValue(
            label: CNLabelPhoneNumberMobile,
            value: CNPhoneNumber(stringValue: number)
        )
        
        /// Create request to mutate contact
        let saveRequest = CNSaveRequest()
        
        /// Create predicate to fetch specific contact based on given name
        let predicate = CNContact.predicateForContacts(matchingName: name)
        
        /// Contact will be fetched and we will access contact given name and phone number
        let keys = [CNContactGivenNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        
        /// Validate if contact already exist or not
        if let contacts = try? store.unifiedContacts(matching: predicate, keysToFetch: keys),
           let contact = contacts.first,
           let mutableContact = contact.mutableCopy() as? CNMutableContact {
            /// Validate if phone number already exist or not
            let existingNumbers = mutableContact.phoneNumbers.map { $0.value.stringValue }
            guard !existingNumbers.contains(number) else { return }
            /// Append new phone number in to existing phone numbers of contact
            mutableContact.phoneNumbers.append(phoneNumber)
            saveRequest.update(mutableContact)
        } else {
            /// Create a mutable object to add to the contact.
            /// Mutable object means an object state that can be modified after created.
            let contact = CNMutableContact()
            contact.contactType = .person
            contact.givenName = name
            contact.imageData = UIImage(named: "tokopedia")?.pngData()
            contact.phoneNumbers = [phoneNumber]
            saveRequest.add(contact, toContainerWithIdentifier: nil)
        }
           
        do {
            try store.execute(saveRequest)
            print("\(name) saved...")
        } catch {
            print(error)
        }    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
