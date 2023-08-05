import AcknowList
import ComposableArchitecture
import Helpers
import L10n
import Styleguide
import SwiftUI
import SwiftUIHelpers

/// A view to render the app settings.
public struct SettingsView: View {
  public typealias State = SettingsFeature.State
  public typealias Action = SettingsFeature.Action
  
  @Environment(\.colorSchemeContrast) var colorSchemeContrast
  
  let store: Store<State, Action>
  @ObservedObject var viewStore: ViewStore<State, Action>
  
  public init(store: Store<State, Action>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }
  
  public var body: some View {
    SettingsForm {
      Spacer(minLength: 28)
      VStack {
        SettingsRow {
          observationModeRow
            .accessibilityValue(
              viewStore.isObservationModeEnabled
                ? Text(L10n.A11y.General.on)
                : Text(L10n.A11y.General.off)
            )
            .accessibilityAction {
              viewStore.send(
                .set(\.$isObservationModeEnabled, !viewStore.isObservationModeEnabled)
              )
            }
        }
        
        SettingsRow {
          infoRow
            .accessibilityValue(
              viewStore.infoViewEnabled
                ? Text(L10n.A11y.General.on)
                : Text(L10n.A11y.General.off)
            )
            .accessibilityAction {
              viewStore.send(
                .set(\.$infoViewEnabled, !viewStore.infoViewEnabled)
              )
            }
        }
        
        SettingsSection(title: "") {
          SettingsNavigationLink(
            destination: RideEventSettingsView(
              store: store.scope(
                state: \.rideEventSettings,
                action: SettingsFeature.Action.rideevent
              )
            ),
            title: L10n.Settings.eventSettings
          )
          
          SettingsNavigationLink(
            destination: AppearanceSettingsView(
              store: store.scope(
                state: \.appearanceSettings,
                action: SettingsFeature.Action.appearance
              )
            ),
            title: L10n.Settings.Theme.appearance
          )
        }
                
        supportSection
        
        infoSection
      }
    }
    .navigationTitle(L10n.Settings.title)
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .onAppear { viewStore.send(.onAppear) }
  }
  
  var observationModeRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: .grid(1)) {
        Text(L10n.Settings.Observationmode.title)
          .font(.titleOne)
        Text(L10n.Settings.Observationmode.detail)
          .foregroundColor(colorSchemeContrast.isIncreased ? Color(.textPrimary) : Color(.textSilent))
          .font(.bodyOne)
      }
      Spacer()
      Toggle(
        isOn: viewStore.$isObservationModeEnabled,
        label: { EmptyView() }
      )
      .labelsHidden()
    }
    .accessibilityElement(children: .combine)
  }
  
  var infoRow: some View {
    HStack {
      VStack(alignment: .leading, spacing: .grid(1)) {
        Text("Show info view")
          .font(.titleOne)
        Text("Show info toogle over the map")
          .foregroundColor(colorSchemeContrast.isIncreased ? Color(.textPrimary) : Color(.textSilent))
          .font(.bodyOne)
      }
      Spacer()
      Toggle(
        isOn: viewStore.$infoViewEnabled,
        label: { EmptyView() }
      )
      .labelsHidden()
    }
    .accessibilityElement(children: .combine)
  }
  
  var supportSection: some View {
    SettingsSection(title: L10n.Settings.support) {
      VStack(alignment: .leading, spacing: .grid(4)) {
        Button(
          action: { viewStore.send(.supportSectionRowTapped(.github)) },
          label: {
            SupportSettingsRow(
              title: L10n.Settings.programming,
              subTitle: L10n.Settings.Opensource.detail,
              link: L10n.Settings.Opensource.action,
              textStackForegroundColor: Color(.textPrimaryLight),
              backgroundColor: Color(.brand500),
              bottomImage: Image(uiImage: Asset.ghLogo.image)
            )
          }
        )
        .accessibilityAddTraits(.isLink)
        
        Button(
          action: { viewStore.send(.supportSectionRowTapped(.crowdin)) },
          label: {
            SupportSettingsRow(
              title: L10n.Settings.Translate.title,
              subTitle: L10n.Settings.Translate.subtitle,
              link: L10n.Settings.Translate.link,
              textStackForegroundColor: .white,
              backgroundColor: Color(.translateRowBackground),
              bottomImage: Image(uiImage: Asset.translate.image)
            )
          }
        )
        .accessibilityAddTraits(.isLink)
        
        Button(
          action: { viewStore.send(.supportSectionRowTapped(.criticalMassDotIn)) },
          label: {
            SupportSettingsRow(
              title: L10n.Settings.CriticalMassDotIn.title,
              subTitle: L10n.Settings.CriticalMassDotIn.detail,
              link: L10n.Settings.CriticalMassDotIn.action,
              textStackForegroundColor: Color(.textPrimaryLight),
              backgroundColor: Color(.cmInRowBackground),
              bottomImage: Image(uiImage: Asset.cmDotInLogo.image)
            )
          }
        )
        .accessibilityAddTraits(.isLink)
      }
      .padding(.horizontal, .grid(4))
    }
  }
  
  var infoSection: some View {
    SettingsSection(title: L10n.Settings.Section.info) {
      SettingsRow {
        Button(
          action: { viewStore.send(.infoSectionRowTapped(.website)) },
          label: {
            SettingsInfoLink(title: L10n.Settings.website)
          }
        )
        .accessibilityAddTraits(.isLink)
      }
      
      SettingsRow {
        Button(
          action: { viewStore.send(.infoSectionRowTapped(.twitter)) },
          label: {
            SettingsInfoLink(title: L10n.Settings.twitter)
          }
        )
        .accessibilityAddTraits(.isLink)
      }
      
      SettingsRow {
        Button(
          action: { viewStore.send(.infoSectionRowTapped(.privacy)) },
          label: {
            SettingsInfoLink(title: L10n.Settings.privacyPolicy)
          }
        )
        .accessibilityAddTraits(.isLink)
      }
      
      if let acknowledgementsPlistPath = viewStore.acknowledgementsPlistPath {
        SettingsNavigationLink(
          destination: AcknowListSwiftUIView(plistPath: acknowledgementsPlistPath),
          title: "Acknowledgements"
        )
      }
      
      appVersionAndBuildView
    }
  }
  
  var appVersionAndBuildView: some View {
    HStack(spacing: .grid(4)) {
      ZStack {
        RoundedRectangle(cornerRadius: 12.5)
          .foregroundColor(.white)
          .frame(width: 56, height: 56, alignment: .center)
          .overlay(
            RoundedRectangle(cornerRadius: 12.5)
              .strokeBorder(Color(.border), lineWidth: 1)
          )
        Image(uiImage: Asset.cmLogoC.image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 48, height: 48, alignment: .center)
      }
      .accessibilityHidden(true)
      
      VStack(alignment: .leading) {
        Text(viewStore.versionNumber)
          .font(.titleTwo)
          .foregroundColor(Color(.textPrimary))
        Text(viewStore.buildNumber)
          .font(.bodyTwo)
          .foregroundColor(colorSchemeContrast.isIncreased ? Color(.textPrimary) : Color(.textSilent))
      }
      .accessibilityElement(children: .combine)
    }
    .padding(.grid(4))
  }
}

struct SettingsInfoLink: View {
  let title: String
  
  var body: some View {
    HStack {
      Text(title)
        .font(.titleOne)
      Spacer()
      Image(systemName: "arrow.up.right")
        .font(.titleOne)
        .accessibilityHidden(true)
    }
  }
}

 struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    Preview {
      NavigationView {
        SettingsView(
          store: .init(
            initialState: .init(userSettings: .init())
          ) { SettingsFeature()._printChanges() }
        )
      }
    }
  }
 }
