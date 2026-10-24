# CampusHub

Learn, earn and sell for free. CampusHub is a mobile-first app for students with little or no money, built to run on a phone and cost nothing to start.

## What it does
- **Explore:** a searchable list of free scholarships, tools, courses and contests. Save the ones you want.
- **Market:** list notes, designs, tutoring or typing with a photo or video. Buyers message you on WhatsApp, with no fees.
- **Data:** paste rows and clean them (blanks, bad emails and phones, duplicates) before handing work to a client.
- **Promote:** turn what you sell into WhatsApp, Instagram or TikTok posts and a flyer headline.
- **Study:** summaries, flashcards, quizzes, a mind map, read-aloud, a focus timer, and exports (Markdown, Anki CSV, slide outline).
- **Jeevanom-IQ:** a chat guide for scholarships, earning with no capital, selling and studying.
- **Accounts:** email sign-up with verification, sign-in, and password reset.

## Built with
Plain HTML, CSS and JavaScript, GSAP for motion, Supabase (login, database, file storage, server function), Capacitor (Android app), GitHub Pages (website) and GitHub Actions (builds the APK).

## Files
| File | Purpose |
|---|---|
| `index.html` | The whole app |
| `config.js` | Your Supabase URL, publishable key and site address |
| `supabase/schema.sql` | Database tables, security rules and media storage |
| `supabase/functions/iq/index.ts` | Server for Jeevanom-IQ (keeps the AI key private) |
| `package.json`, `capacitor.config.json`, `prepare.js` | Android app setup |
| `.github/workflows/android.yml` | Builds the APK on GitHub |

## Setup
1. **Supabase:** create a free project. In SQL Editor, run `supabase/schema.sql`.
2. **Config:** open `config.js` and add the Project URL, the publishable key, and your site address. Never put a secret key or the database password in this file.
3. **Website:** make the repository public, then Settings > Pages > deploy from `main` and `/ (root)`.
4. **Auth links:** in Supabase > Authentication > URL Configuration, set Site URL to your Pages address and add it to Redirect URLs.
5. **Email:** Supabase's built-in sender allows only a few emails an hour. Before launch, add a free SMTP provider (Authentication > Emails > SMTP Settings).
6. **Jeevanom-IQ:** deploy the `iq` function and add secrets `IQ_PROVIDER`, `GEMINI_API_KEY` and `IQ_GEMINI_MODEL` (check the model name in Google AI Studio).

## Build the Android app
1. Actions tab > "Build Android APK" > Run workflow.
2. When it finishes, download `campushub-apk`, unzip it, and install `app-debug.apk` on your Android phone.
3. Verify and reset links open in the phone browser. Return to the app and sign in afterwards.

## Before real users
- Replace `Access-Control-Allow-Origin: *` in the `iq` function with your site address.
- Add a daily limit per user for Jeevanom-IQ so free quotas last.
- Tell students not to type private information into Jeevanom-IQ. Free-tier AI requests may be used by the provider to improve its products.
- A Play Store release needs a signed build and a Google Play developer account.

## Status
Early prototype. The Supabase, email and Android build steps have not been tested end to end yet. Report problems as GitHub issues.

## Earning, tasks and security (new)
- Run `supabase/update_tasks_and_limits.sql` once in the SQL Editor. It adds the tasks board and the Jeevanom-IQ daily limit.
- Redeploy the `iq` function and add `ALLOWED_ORIGIN` (your site address, no path) and `IQ_DAILY_LIMIT` (default 30) to the secrets.
- Supabase > Authentication > Attack Protection: turn on CAPTCHA (Cloudflare Turnstile is free) and leaked-password protection if your plan allows it.
- Layers: app (input checks, escaped output, strict content policy) > Supabase login (signed tokens) > database row-level security > server function (signed-in check, daily limit, input caps) > AI provider (key kept on the server).
- Payments between students and clients are agreed directly for now. Add escrow (for example Paystack or Flutterwave) only after you have registered as a business in your country.

## Sponsored slots (new)
1. Run `supabase/monetization.sql` once in the SQL Editor.
2. Table Editor > opportunities > Insert row: name, kind, a short blurb, an https link, `sponsored` on, and `sponsor_name`. Set `starts_on` and `ends_on` for a paid period.
3. Sponsored items appear first with a "Sponsored" label. Counts are one view and one click per device per day.
4. Your report for a sponsor: run `select * from public.sponsor_report;` in the SQL Editor.
5. Put your contact email in `CONTACT_EMAIL` in `config.js` to show the "Partner with us" card.
6. Counts come from devices and can be gamed, so treat them as an estimate and also give sponsors a link with a UTM tag they can check in their own analytics.

## iPhone and iPad
- **Install now, free:** open your site in Safari, tap Share, then Add to Home Screen. It opens full screen like an app, with its own icon, and works offline for the screens already visited. Upload `manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png` and `apple-touch-icon.png` to the top level of the repo first.
- **iPhone differences:** the home-screen app keeps its own login, separate from Safari. After you verify your email or reset a password in Safari, open the home-screen app and sign in. Voice dictation in Study is not reliable on iPhone. Read-aloud, photos and videos work.
- **Real App Store app (later):** this needs an Apple Developer account (a paid yearly fee) and a Mac or a cloud Mac build. Capacitor can wrap the same code for iOS, and GitHub Actions has Mac machines for the build. Do this once sponsors or tasks cover the fee.
