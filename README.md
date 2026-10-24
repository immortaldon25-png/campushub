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
