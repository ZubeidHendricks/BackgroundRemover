# BackgroundRemover

Generated from niche `background-remover` (AI Image, tier A, score 78).

**Utility:** Remove/replace photo backgrounds
**Primary ASO keyword:** `background remover`
**Also target:** `remove background`, `transparent background`, `cutout`, `change background`
**Paywall hook:** HD export, batch, brand backgrounds

> Easy build (one API). Sellers/marketplace users pay. Crowded — niche to a use case.

## Build it

```bash
brew install xcodegen        # once
cd BackgroundRemover
xcodegen generate
open BackgroundRemover.xcodeproj
```

The app runs immediately on a MockPurchaseProvider (real paywall UI, fake
purchases). To go live:

1. Replace `revenueCatKey` in `Sources/App.swift` with your RevenueCat key.
2. In App Store Connect create products `background-remover_yearly` and `background-remover_weekly`,
   map them into a RevenueCat offering, entitlement id `premium`.
3. Build the real feature in `Sources/ContentView.swift`.
4. **Guideline 4.3:** make the function, UI, screenshots and keywords genuinely
   distinct from any sibling app. Re-niche, never reskin.

Bundle id: `com.zubeid.backgroundremover`

## Ship to TestFlight

This app ships with a Fastlane lane + GitHub Actions workflow. One-time account
setup (API key, signing) is documented in the kit's `Tools/appgen/DEPLOYMENT.md`.
Once your GitHub secrets are set, trigger the **TestFlight** workflow (or push a
`v*` tag), or run locally:

```bash
bundle install
bundle exec fastlane beta
```
