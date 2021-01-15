// By Tom Meagher on 1/14/21 at 22:06

import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: AppStore
    
    var body: some View {
        if (store.authUser != nil) {
            ComposeView()
        } else {
            LoginView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}