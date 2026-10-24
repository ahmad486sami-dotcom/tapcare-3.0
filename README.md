# TapCare for iPhone

TapCare packaged as an iPhone and iPad app. The whole TapCare page (patient page, doctor portal and admin console) is bundled inside the app, so it works offline. Fonts load from the internet when available and fall back to system fonts when not.

## Build the .ipa on GitHub (no Mac needed)

1. Create a new **private** repository on GitHub, for example `tapcare-ios`.
2. Upload everything in this folder, including the hidden `.github` folder. The easiest way is GitHub Desktop, or `git push` from your computer. The web uploader can skip hidden folders.
3. Open the **Actions** tab. The **Build IPA** workflow starts on every push to `main`. You can also run it with **Run workflow**.
4. When it finishes (about 5 minutes), open the run and download **TapCare-ipa**. Unzip it to get `TapCare.ipa`.

## Install it on your iPhone

The .ipa is unsigned. Sign it while installing with **Sideloadly** or **AltStore** and your Apple ID.

- With a free Apple ID, the app must be re-signed every 7 days.
- With a paid developer account, it lasts a year.

## Change the content

The page is `TapCare/web/index.html`. Replace it with a newer version, push, and a new .ipa is built.

## Good to know

- **Connected to your Supabase project.** Accounts, patient codes, readings and requests are shared between the app, the website and every phone. If the app can't reach Supabase (no internet), it opens in demo mode with sample data saved on the phone.
- **Supabase settings.** If you ever change the project, update `SB_URL` and `SB_KEY` near the top of the script in `TapCare/web/index.html`. The key there is the public anon key, which is meant to be in the app. Security comes from the database rules.
- **NFC tags** still open the web version. To have a tag open the app directly, you need Universal Links, which require a paid Apple developer account and your own domain.
- **App icon** is in `TapCare/Assets.xcassets/AppIcon.appiconset/icon.png` (1024×1024).
- **Bundle ID** is `com.ahmad486.tapcare`. Change it in `project.yml`.
